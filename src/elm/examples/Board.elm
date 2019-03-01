module Board exposing (Doc, Msg, State, gizmo)

import Browser.Dom as Dom exposing (Element, Viewport)
import Browser.Events
import Clipboard
import Config
import Css exposing (..)
import DataTransfer
import Dict
import FarmUrl
import File exposing (File)
import Gizmo exposing (Flags, Model)
import Html.Styled as Html exposing (Html, button, div, input, text)
import Html.Styled.Attributes as Attr exposing (css, id, value)
import Html.Events as Events
import Html.Events.Extra.Pointer as Pointer
import Html.Events.Extra.Mouse as Mouse
import Html.Events.Extra.Drag as Drag

import IO
import Json.Decode as D exposing (Decoder)
import Json.Encode as E
import Random
import Repo exposing (Ref, Url)
import Task exposing (Task)
import Tuple exposing (pair)
import Uri
import VsCode
import Set exposing (Set)
import List.Extra


gizmo : Gizmo.Program State Doc Msg
gizmo =
    Gizmo.element
        { init = init
        , update = update
        , view = view
        , subscriptions = subscriptions
        }


type Action
    = None
    | Moving Point
    | Resizing Size


type Menu
    = NoMenu
    | BoardMenu Point
    | CardMenu Int Point


type alias Card =
    { code : Url
    , data : Url
    , x : Float
    , y : Float
    , w : Float
    , h : Float
    , z : Int
    }


type alias Pair =
    { code : Url
    , data : Url
    }

{- the ints here are indices into the local view of the cards array
   this is incorrect! other users could insert new cards and this would
   make your selection change weirdly. we should use more durable selection
   references. theoretically we could generate them locally, but if they're
   shared we can share references.
   this probably means migrating all boards to UUID-indexed cards. oof. -}
type alias Selection =
    List Int

{-| Ephemeral state not saved to the doc
-}
type alias State =
    { action : Action
    , randomId : String -- TODO: Use proper UUID --
    , createPosition : Point
    , menu : Menu
    , selection : Selection
    }

{- the randomId above is a hack that lets us get mouse coordinates relative to
   the origin of the board's background element. this is yucky.
   we have similar problems with the current TODO implementation. this string could
   be shared between users but should be per-instance, because you may have the same
   board several times on one canvas. (even if that's not useful.)
-}

{-| Document state
-}
type alias Doc =
    { cards : List Card
    , maxZ : Int
    }


init : Flags -> ( State, Doc, Cmd Msg )
init flags =
    ( { action = None
      , randomId = ""
      , menu = NoMenu
      , createPosition = origin
      , selection = []
      }
    , { cards = []
      , maxZ = 1
      }
    , Random.generate SetRandomId <| Random.int Random.minInt Random.maxInt
    )


{-| Message type for modifying State and Doc inside update
-}
type Msg
    = NoOp
    | SetRandomId Int
    | FinishAction
    | Resize Int
    | MouseDelta Point
    | Mirror Int
    | Remove
    | Select Int Mouse.Keys
    | BackgroundClicked
    | SetMenu Menu
    | HandleDrop Point (List File)
    | HandlePaste D.Value
    | CreateCard Point String
    | CreateCardInScene String (Result Dom.Error Point)
    | CreateImage Point String
    | CreateImageInScene String (Result Dom.Error Point)
    | CreateNote Point String
    | CreateNoteInScene String (Result Dom.Error Point)
    | Created ( Ref, List Url )
    | EmbedGizmo Point String
    | EmbedGizmoInScene String (Result Dom.Error Point)
    | NavigateToCard Int
    | KeyUp String


update : Msg -> Model State Doc -> ( State, Doc, Cmd Msg )
update msg { state, doc, flags } =
    case msg of
        NoOp ->
            ( state, doc, Cmd.none )

        SetRandomId rid ->
            ( { state | randomId = "board" ++ String.fromInt rid }
            , doc
            , Cmd.none
            )

        FinishAction ->
            ( { state | action = None }
            , doc |> applyAction state.selection (snapAction state.action)
            , Cmd.none
            )
 
        Select n keys ->
                ( state
                    |> updateSelection n keys
                    |> beginMoving
                    |> hideMenu
                , doc 
                    |> bumpZ n
                , Cmd.none
                )

        BackgroundClicked ->
            ( { state  | selection = clearSelection } |> hideMenu
            , doc
            , Cmd.none
            )

        Resize n ->
            case doc |> getCard n of
                Nothing ->
                    ( state, doc, Cmd.none )

                Just card ->
                    ( state
                        |> \x -> { x | selection = setSelection n x.selection }
                        |> beginResizing card
                        |> hideMenu
                    , doc
                    , Cmd.none
                    )

        MouseDelta delta ->
            case state.action of
                Moving pt ->
                    ( { state | action = Moving (moveBy delta pt) }
                    , doc
                    , Cmd.none
                    )

                Resizing size ->
                    ( { state | action = Resizing (resizeBy delta size) }
                    , doc
                    , Cmd.none
                    )

                _ ->
                    ( state, doc, Cmd.none )

        KeyUp key ->
            case key of
                "Backspace" -> 
                    let newCards = doc.cards
                            |> List.indexedMap Tuple.pair
                            |> List.filter (\pair -> not (List.member (Tuple.first pair) state.selection))
                            |> List.map Tuple.second 
                    in
                        ( { state | selection = clearSelection } |> hideMenu
                        , { doc | cards = newCards }
                        , Cmd.none
                        )
                _ -> ( state, doc, Cmd.none )


        Mirror n ->
            ( { state | menu = NoMenu }
            , case doc.cards |> List.Extra.getAt n of
                Just card ->
                    doc |> pushCard (card |> moveBy (Point 24 24))

                Nothing ->
                    doc
            , Cmd.none
            )

        Remove ->
            let 
                newCards = List.foldl
                    (\n cards -> List.Extra.removeAt n cards)
                    doc.cards
                    state.selection
            in
            ( state |> hideMenu
            , { doc | cards = newCards }
            , Cmd.none
            )

        SetMenu m ->
            ( { state | menu = m }, doc, Cmd.none )

        HandleDrop position files ->
            ( state
            , doc
            , files
                |> List.map (fileToCmd position)
                |> Cmd.batch
            )

        HandlePaste value ->
            ( state
            , doc
            , case D.decodeValue clipboardDecoder value of
                Ok files ->
                    files
                        |> List.map (fileToCmd { x = 20, y = 20 })
                        |> Cmd.batch

                Err _ ->
                    Cmd.none
            )

        CreateCard position code ->
            ( state
            , doc
            , Task.attempt
                (CreateCardInScene code)
                (getLocalCoordinates state.randomId position)
            )

        CreateCardInScene code localCoordinates ->
            case localCoordinates of
                Ok pos ->
                    ( { state | createPosition = pos }
                    , doc
                    , Repo.create code 1
                    )

                Err err ->
                    ( state
                    , doc
                    , IO.log "error creating card"
                    )

        CreateImage position src ->
            ( state
            , doc
            , Task.attempt
                (CreateImageInScene src)
                (getLocalCoordinates state.randomId position)
            )

        CreateImageInScene src localCoordinates ->
            case localCoordinates of
                Ok pos ->
                    ( { state | createPosition = pos }
                    , doc
                    , Repo.createWithProps Config.image 1 [ ( "src", E.string src ) ]
                    )

                Err err ->
                    ( state
                    , doc
                    , IO.log "error creating card"
                    )

        CreateNote position str ->
            ( state
            , doc
            , Task.attempt
                (CreateNoteInScene str)
                (getLocalCoordinates state.randomId position)
            )

        CreateNoteInScene str localCoordinates ->
            case localCoordinates of
                Ok pos ->
                    ( { state | createPosition = pos }
                    , doc
                    , Repo.createWithProps Config.note 1 [ ( "body", E.string str ) ]
                    )

                Err err ->
                    ( state
                    , doc
                    , IO.log "error creating card"
                    )

        Created ( code, urls ) ->
            case urls of
                [ data ] ->
                    let
                        card =
                            newCard code data |> moveTo (snapPoint state.createPosition)
                    in
                    ( { state | menu = NoMenu, createPosition = origin }, doc |> pushCard card, Cmd.none )

                _ ->
                    ( state, doc, Cmd.none )

        EmbedGizmo position url ->
            ( state
            , doc
            , Task.attempt
                (EmbedGizmoInScene url)
                (getLocalCoordinates state.randomId position)
            )

        EmbedGizmoInScene url localCoordinates ->
            case ( FarmUrl.parse url, localCoordinates ) of
                ( Ok { code, data }, Ok pos ) ->
                    let
                        card =
                            newCard code data |> moveTo (snapPoint pos)
                    in
                    ( state
                    , doc |> pushCard card
                    , Cmd.none
                    )

                _ ->
                    ( state
                    , doc
                    , IO.log "Error embedding gizmo"
                    )

        NavigateToCard n ->
            ( state
            , doc
            , doc
                |> getCard n
                |> Result.fromMaybe "Could not find this card"
                |> Result.map resolveCard
                |> Result.andThen FarmUrl.create
                |> Result.map (E.string >> Gizmo.emit "navigate")
                |> Result.withDefault Cmd.none
            )


origin : Point
origin =
    { x = 0, y = 0 }


getLocalCoordinates : String -> Point -> Task Dom.Error Point
getLocalCoordinates boardId pos =
    -- subtract the board element offset for the global scene
    -- add the board viewport offset for the board scene
    Task.sequence
        [ Task.map (\el -> el.element) <| Dom.getElement boardId
        , Task.map (\vp -> vp.viewport) <| Dom.getViewportOf boardId
        ]
        |> Task.map
            (\coordinates ->
                case coordinates of
                    [ globalOffset, localScrollOffset ] ->
                        pos
                            |> withOffset localScrollOffset
                            |> withoutOffset globalOffset

                    _ ->
                        -- TODO: how can we preserve the Dom.Error? The compiler forces this case
                        Debug.log
                            "Unknown error translating to local coordinates, using origin"
                            origin
            )


type alias Offset a =
    { a | x : Float, y : Float }


withOffset : Offset a -> Point -> Point
withOffset offset pos =
    { x = pos.x + offset.x
    , y = pos.y + offset.y
    }


withoutOffset : Offset a -> Point -> Point
withoutOffset offset pos =
    { x = pos.x - offset.x
    , y = pos.y - offset.y
    }


fileToCmd : Point -> File -> Cmd Msg
fileToCmd position file =
    case String.split "/" (File.mime file) of
        [ "image", _ ] ->
            Task.perform (CreateImage position) <| File.toUrl file

        [ "text", "plain" ] ->
            {- Task.perform (CreateNote position) (File.toUrl file) -}
            File.toString file
                |> Task.perform (\string ->
                    let
                        first_five = String.left 5 string
                    in
                    case first_five of
                        "farm:" -> {- this doesn't work -}
                            (EmbedGizmo position) string
                        _ -> 
                            (CreateNote position) string
                    )

        [ "application", "farm-url" ] ->
            Task.perform (EmbedGizmo position) <| File.toString file

        [ "application", "hypermerge-url" ] ->
            Task.perform (CreateCard position) <| File.toString file

        _ ->
            IO.log <| "Unknown file type: " ++ File.mime file


subscriptions : Model State Doc -> Sub Msg
subscriptions { state, doc } =
    Sub.batch
        [ Repo.created Created
        , Clipboard.pasted HandlePaste
        , Browser.Events.onKeyUp (D.map KeyUp keyDecoder)
        ]

keyDecoder : D.Decoder String
keyDecoder =
  D.field "key" D.string

newCard : Url -> Url -> Card
newCard code data =
    { data = data
    , code = code
    , x = 24
    , y = 24
    , w = 312
    , h = 408
    , z = 0
    }

{- card collection functions -}
getCard : Int -> Doc -> Maybe Card
getCard n =
    .cards >> List.Extra.getAt n


pushCard : Card -> Doc -> Doc
pushCard card doc =
    { doc | cards = doc.cards |> List.append [card] }
        |> bumpZ (List.length doc.cards)


updateCard : Int -> (Card -> Card) -> Doc -> Doc
updateCard n f doc =
    { doc | cards = doc.cards |> List.Extra.updateAt n f }


resolveCard : Card -> Pair
resolveCard { code, data } =
    Pair (resolveUrl code) (resolveUrl data)

{- selection management functions -}
isSelected : Int -> Selection -> Bool
isSelected n selection =
    List.member n selection
clearSelection : Selection
clearSelection =
    []
setSelection : Int -> Selection -> Selection
setSelection n _ =
    [n]
toggleSelection : Int -> Selection -> Selection
toggleSelection n selection =
    if List.member n selection then
        List.Extra.remove n selection
    else   
        n :: selection 

resolveUrl : Url -> Url
resolveUrl url =
    case Uri.parse url of
        Ok _ ->
            url

        Err _ ->
            Config.getString url
                |> Maybe.withDefault url

updateSelection : Int -> Mouse.Keys -> State -> State
updateSelection n keys state =
    let selectionCommand = case keys.shift of 
                    True -> toggleSelection
                    False -> setSelection
    in
        { state | selection = selectionCommand n state.selection }

beginMoving : State -> State
beginMoving state =
    { state | action = Moving { x = 0, y = 0 } }

beginResizing : Card -> State -> State
beginResizing card state =
    { state | action = Resizing { w = card.w, h = card.h } }
    
hideMenu : State -> State
hideMenu state =
    { state | menu = NoMenu }

applyAction : Selection -> Action -> Doc -> Doc
applyAction selection action doc =
    case action of
        Moving pt ->
            List.foldl (\n iteratedDoc ->  
                iteratedDoc 
                |> updateCard n ((moveBy pt) >> boundsSnap)
                |> bumpZ n )
            doc selection
                
        Resizing size ->
            List.foldl (\n iteratedDoc ->  
                iteratedDoc 
                |> updateCard n (resizeTo size) 
                |> bumpZ n )
            doc selection

        _ ->
            doc


snap : Float -> Float
snap fl =
    (fl / 24)
        |> Basics.round
        |> (*) 24
        |> toFloat


snapPoint : Point -> Point
snapPoint { x, y } =
    { x = snap x, y = snap y }


snapSize : Size -> Size
snapSize { w, h } =
    { w = snap w, h = snap h }


snapAction : Action -> Action
snapAction action =
    case action of
        Moving delta ->
            Moving (snapPoint delta)

        Resizing size ->
            Resizing (snapSize size)

        _ ->
            action


bumpZ : Int -> Doc -> Doc
bumpZ n doc =
    case doc |> getCard n of
        Nothing ->
            doc

        Just card ->
            if card.z == doc.maxZ then
                doc

            else
                { doc
                    | maxZ = doc.maxZ + 1
                    , cards = doc.cards |> List.Extra.setAt n { card | z = doc.maxZ + 1 }
                }

{- dimension management code -}
type alias Positioned a =
    { a | x : Float, y : Float }


type alias Point =
    { x : Float, y : Float }


type alias Sized a =
    { a | w : Float, h : Float }


type alias Size =
    { w : Float, h : Float }


moveBy : Point -> Positioned a -> Positioned a
moveBy { x, y } a =
    a |> moveTo { x = a.x + x, y = a.y + y }


moveTo : Point -> Positioned a -> Positioned a
moveTo { x, y } a =
    { a | x = x, y = y }

boundsSnap : Positioned a -> Positioned a
boundsSnap a =
    { a | x = max 0 a.x, y = max 0 a.y }

resizeBy : Point -> Sized a -> Sized a
resizeBy { x, y } a =
    a |> resizeTo { w = a.w + x, h = a.h + y }


resizeTo : Size -> Sized a -> Sized a
resizeTo { w, h } a =
    { a | w = max 20 w, h = max 20 h }

{-

    View Functions

 -}
view : Model State Doc -> Html Msg
view { doc, state } =
    div
        [ css
            [ property "user-select" "none"
            , fontSize (px 14)
            , fill
            , overflow hidden
            ]
        , Mouse.onContextMenu (\event -> 
            let (x, y) = event.clientPos
                pt = Point x y 
            in SetMenu (BoardMenu pt)
            ) |> Attr.fromUnstyled
        , Mouse.onDoubleClick (\event -> 
            let (x, y) = event.clientPos 
                pt = Point x y
            in CreateCard pt "note")
             |> Attr.fromUnstyled
        , onMove (\event -> 
                let (dx, dy) = event.movement
                    pt = Point dx dy
                in MouseDelta pt) 
        , Pointer.onUp (\_ -> FinishAction) |> Attr.fromUnstyled
        ]
        -- FIXME , onDrop HandleDrop
        [ viewContextMenu doc state.menu
        , div
            [ id state.randomId
            , css
                [ fill
                , backgroundColor (hex "f9f8f3")
                , backgroundImage (url Config.dotGrid)
                , backgroundAttachment local
                , overflow auto
                ]
            ]
            (viewClickShield
                :: (doc
                        |> applyAction state.selection state.action
                        |> .cards
                        |> List.indexedMap (viewCard state.selection)
                   )
            )
        ]


viewClickShield : Html Msg
viewClickShield =
    div
        [ Pointer.onDown (\event -> BackgroundClicked) |> Attr.fromUnstyled
        , Attr.tabindex 0
        , css
            [ fill
            , zIndex (int 0)
            ]
        ]
        []


viewCard : Selection -> Int -> Card ->  Html Msg
viewCard selection n card =
    div
        [ css
            [ property "display" "grid"
            , property "grid-template-rows" "auto 1fr"
            , if isSelected n selection then
                selectionBordered
              else
                bordered
            , position absolute
            , transform <| translate2 (px card.x) (px card.y)
            , width (px card.w)
            , height (px card.h)
            , zIndex (int card.z)
            , overflow hidden
            ]
        ]
        [ viewTitleBar n card
        , div
            [ css
                [ overflow hidden
                ]
            ]
            [ Gizmo.render (resolveUrl card.code) (resolveUrl card.data)
            ]
        , viewResize n
        ]


openDocumentValue : E.Value -> Url
openDocumentValue value =
    case D.decodeValue D.string value of
        Ok url ->
            url

        Err msg ->
            ""


viewTitleBar : Int -> Card -> Html Msg
viewTitleBar n card =
    div
        [ css
            [ height (px 20)
            , cursor move
            , position relative
            , zIndex (int 999999999)
            ]
        , Mouse.onDoubleClick (\_ -> NavigateToCard n) |> Attr.fromUnstyled
        , Mouse.onContextMenu (\event -> 
            let (x, y) = event.clientPos
                pt = Point x y 
            in SetMenu (CardMenu n pt)
            ) |> Attr.fromUnstyled
        , Mouse.onDown (.keys >> Select n)  |> Attr.fromUnstyled
        , Pointer.onUp (\_ -> FinishAction)  |> Attr.fromUnstyled
        ]
        [ Gizmo.renderWith [ Gizmo.attr "prop" "title" ] Config.property (resolveUrl card.data) ]


viewResize : Int -> Html Msg
viewResize n =
    div
        [ css
            [ position absolute
            , bottom (px 0)
            , right (px 0)
            , width (px 10)
            , height (px 10)
            , cursor seResize
            , zIndex (int 999999999)
            ]
        , Mouse.onDown (\e -> Resize n) |> Attr.fromUnstyled
        ]
        []


viewContextMenu : Doc -> Menu -> Html Msg
viewContextMenu doc menuType =
    case menuType of
        NoMenu ->
            null

        BoardMenu pt ->
            positioned pt
                [ viewBoardMenu pt ]

        CardMenu n pt ->
            case getCard n doc of
                Just card ->
                    positioned pt
                        [ viewCardMenu n card ]

                Nothing ->
                    null


viewBoardMenu : Point -> Html Msg
viewBoardMenu pt =
    menu
        [ menuButton "Chat" (CreateCard pt "chat")
        , menuButton "Board" (CreateCard pt "board")
        , menuButton "Note" (CreateCard pt "note")
        , menuButton "Essay" (CreateCard pt "essay")
        , menuButton "Koala" (CreateCard pt "koala")
        , menuButton "Todo List" (CreateCard pt "todoList")
        ]


viewCardMenu : Int -> Card -> Html Msg
viewCardMenu n card =
    menu
        [ menuButton "Remove" (Remove)
        ]


menu : List (Html msg) -> Html msg
menu =
    div
        [ css
            [ border3 (px 1) solid (hex "ddd")
            , borderBottomWidth (px 0)
            , borderRadius (px 3)
            , backgroundColor (rgba 255 255 255 0.8)
            , property "backdrop-filter" "blur(2px)"
            ]
        ]


menuLink : String -> String -> Html msg
menuLink label url =
    Html.a
        [ css
            [ menuItemStyle
            , textDecoration none
            , display block
            , color inherit
            ]
        , Attr.href url
        ]
        [ text label ]


menuButton : String -> msg -> Html msg
menuButton label msg =
    div
        [ css
            [ menuItemStyle
            ]
        , Attr.fromUnstyled <| Mouse.onClick (\x -> msg) 
        ]
        [ text label
        ]


menuItemStyle : Style
menuItemStyle =
    batch
        [ borderBottom3 (px 1) solid (hex "ddd")
        , padding2 (px 5) (px 20)
        , cursor pointer
        , hover
            [ backgroundColor (hex "eee")
            ]
        ]


positioned : Point -> List (Html msg) -> Html msg
positioned { x, y } =
    div
        [ css
            [ position fixed
            , top zero
            , left zero
            , zIndex (int 999999999)
            , transform <| translate2 (px x) (px y)
            ]
        ]


null : Html msg
null =
    text ""


bordered : Style
bordered =
    batch
        [ border3 (px 1) solid (hex "ddd")
        , borderRadius (px 3)
        , backgroundColor (hex "#fff")
        ]

selectionBordered : Style
selectionBordered = 
    batch 
        [ outline3 (px 2) solid (hex "000")
        , borderRadius (px 3)
        , outlineOffset (px -1)
        , backgroundColor (hex "#fff")
        , boxShadow5 (px 4) (px 4) (px 24) (px 0) (rgba 0 0 0 0.25)
        , zIndex (int 2)
        ] 


fill : Style
fill =
    batch
        [ position absolute
        , top zero
        , left zero
        , bottom zero
        , right zero
        ]


clipboardDecoder : Decoder (List File)
clipboardDecoder =
    D.field "clipboardData" DataTransfer.elmFileDecoder


dataTransferFileDecoder : Decoder (List File)
dataTransferFileDecoder =
    D.field "dataTransfer" DataTransfer.elmFileDecoder


{- 
    we implement our own onMove function here because some browsers
    don't support the movement{X/Y} properties in the onMove event.
    that said, Chrome does, and this is (currently) an electron app. 
-}
onMove : (EventWithMovement -> msg) -> Html.Attribute msg
onMove tag =
    let
        options =
            { stopPropagation = True, preventDefault = True }
    in
    D.map tag decodeWithMovement
        |> Events.on "mousemove"
        |> Attr.fromUnstyled

type alias EventWithMovement =
    { mouseEvent : Mouse.Event
    , movement : ( Float, Float )
    }

decodeWithMovement : Decoder EventWithMovement
decodeWithMovement =
    D.map2 EventWithMovement
        Mouse.eventDecoder
        movementDecoder

movementDecoder : Decoder ( Float, Float )
movementDecoder =
    D.map2 Tuple.pair
        (D.field "movementX" D.float)
        (D.field "movementY" D.float)

