module Board exposing (Doc, Msg, State, gizmo)

import Array exposing (Array)
import Browser.Dom as Dom exposing (Element, Viewport)
import Browser.Events
import Clipboard
import Config
import Css exposing (..)
import DataTransfer
import Dict
import Extra.Array as Array
import FarmUrl
import File exposing (File)
import Gizmo exposing (Flags, Model)
import Html.Styled as Html exposing (Html, button, div, input, text)
import Html.Styled.Attributes as Attr exposing (css, id, value)
import Html.Styled.Events as Events exposing (on, onClick, onDoubleClick, onInput, onMouseDown, onMouseUp)
import IO
import Json.Decode as D exposing (Decoder)
import Json.Encode as E
import Random
import Repo exposing (Ref, Url)
import Task exposing (Task)
import Tuple exposing (pair)
import Uri
import VsCode


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
    | Moving Int Point
    | Resizing Int Size


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


{-| Ephemeral state not saved to the doc
-}
type alias State =
    { action : Action
    , randomId : String -- TODO: Use proper UUID
    , createPosition : Point
    , menu : Menu
    , scroll : Point
    , scrolling : Bool
    }


{-| Document state
-}
type alias Doc =
    { cards : Array Card
    , maxZ : Int
    }


init : Flags -> ( State, Doc, Cmd Msg )
init flags =
    ( { action = None
      , randomId = ""
      , menu = NoMenu
      , createPosition = origin
      , scroll = { x = 0, y = 0 }
      , scrolling = False
      }
    , { cards = Array.empty
      , maxZ = 1
      }
    , Random.generate SetRandomId <| Random.int Random.minInt Random.maxInt
    )


{-| Message type for modifying State and Doc inside update
-}
type Msg
    = NoOp
    | SetRandomId Int
    | Stop
    | Move Int
    | Resize Int
    | MouseDelta Point
    | Mirror Int
    | Remove Int
    | Click Int
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
    | Scroll Point
    | ScrollEnd


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

        Stop ->
            ( { state | action = None }
            , doc |> applyAction (snapAction state.action)
            , Cmd.none
            )

        Move n ->
            case doc |> getCard n of
                Nothing ->
                    ( state, doc, Cmd.none )

                Just card ->
                    ( { state | action = Moving n { x = card.x, y = card.y } }
                        |> hideMenu
                    , doc
                    , Cmd.none
                    )

        Resize n ->
            case doc |> getCard n of
                Nothing ->
                    ( state, doc, Cmd.none )

                Just card ->
                    ( { state | action = Resizing n { w = card.w, h = card.h } }
                        |> hideMenu
                    , doc
                    , Cmd.none
                    )

        MouseDelta delta ->
            case state.action of
                Moving n pt ->
                    ( { state | action = Moving n (moveBy delta pt) }
                    , doc
                    , Cmd.none
                    )

                Resizing n size ->
                    ( { state | action = Resizing n (resizeBy delta size) }
                    , doc
                    , Cmd.none
                    )

                _ ->
                    ( state, doc, Cmd.none )

        Click n ->
            ( state, doc |> bumpZ n, Cmd.none )

        Mirror n ->
            ( { state | menu = NoMenu }
            , case doc.cards |> Array.get n of
                Just card ->
                    doc |> pushCard (card |> moveBy (Point 24 24))

                Nothing ->
                    doc
            , Cmd.none
            )

        Remove n ->
            ( state |> hideMenu
            , { doc | cards = doc.cards |> Array.remove n }
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

        Scroll delta ->
            ( { state
                | scrolling = True
                , scroll = state.scroll |> moveBy delta
              }
            , doc
            , Cmd.none
            )

        ScrollEnd ->
            ( { state | scrolling = False }, doc, Cmd.none )


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
            Task.perform (CreateNote position) <| File.toString file

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
        , case state.action of
            None ->
                Sub.none

            _ ->
                Sub.batch
                    [ Browser.Events.onMouseMove (movementDecoder |> D.map MouseDelta)
                    , Browser.Events.onMouseUp (D.succeed Stop)
                    ]
        ]


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


getCard : Int -> Doc -> Maybe Card
getCard n =
    .cards >> Array.get n


pushCard : Card -> Doc -> Doc
pushCard card doc =
    { doc | cards = doc.cards |> Array.push card }
        |> bumpZ (Array.length doc.cards)


updateCard : Int -> (Card -> Card) -> Doc -> Doc
updateCard n f doc =
    { doc | cards = doc.cards |> Array.update n f }


resolveCard : Card -> Pair
resolveCard { code, data } =
    Pair (resolveUrl code) (resolveUrl data)


resolveUrl : Url -> Url
resolveUrl url =
    case Uri.parse url of
        Ok _ ->
            url

        Err _ ->
            Config.getString url
                |> Maybe.withDefault url


hideMenu : State -> State
hideMenu state =
    { state | menu = NoMenu }


applyAction : Action -> Doc -> Doc
applyAction action doc =
    case action of
        Moving n pt ->
            doc
                |> updateCard n (moveTo pt)
                |> bumpZ n

        Resizing n size ->
            doc |> updateCard n (resizeTo size)

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
        Moving n pt ->
            Moving n (snapPoint pt)

        Resizing n size ->
            Resizing n (snapSize size)

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
                    , cards = doc.cards |> Array.set n { card | z = doc.maxZ + 1 }
                }


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
    { a | x = x, y = max 0 y }


resizeBy : Point -> Sized a -> Sized a
resizeBy { x, y } a =
    a |> resizeTo { w = a.w + x, h = a.h + y }


resizeTo : Size -> Sized a -> Sized a
resizeTo { w, h } a =
    { a | w = max 20 w, h = max 20 h }


view : Model State Doc -> Html Msg
view { doc, state } =
    div
        [ css
            [ property "user-select" "none"
            , fontSize (px 14)
            , fill
            , overflow hidden
            ]

        -- , onMouseWheel Scroll
        , onContextMenu (SetMenu << BoardMenu)
        , onDragOver NoOp
        , onDrop HandleDrop
        ]
        [ viewContextMenu doc state.menu
        , div
            [ id state.randomId
            , css
                [ -- TODO: turns out this is hard:
                  -- transform (translate2 (px <| negate state.scroll.x) (px <| negate state.scroll.y))
                  fill
                , backgroundColor (hex "f9f8f3")
                , backgroundImage (url Config.dotGrid)
                , backgroundAttachment local
                , overflow auto
                ]
            ]
            (viewClickShield
                :: (doc
                        |> applyAction state.action
                        |> .cards
                        |> Array.indexedMap viewCard
                        |> Array.toList
                   )
            )
        ]


viewClickShield : Html Msg
viewClickShield =
    div
        [ onMouseDown (SetMenu NoMenu)
        , Attr.tabindex 0
        , css
            [ fill
            , zIndex (int 1)
            ]
        ]
        []


viewCard : Int -> Card -> Html Msg
viewCard n card =
    div
        [ css
            [ property "display" "grid"
            , property "grid-template-rows" "auto 1fr"
            , bordered
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
        , onDoubleClick (NavigateToCard n)
        , onContextMenu (SetMenu << CardMenu n)
        , onMouseDown (Move n)
        , onMouseUp (Click n)
        ]
        []


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
        , onMouseDown (Resize n)
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
        , menuButton "Todo List" (CreateCard pt "todoList")
        ]


viewCardMenu : Int -> Card -> Html Msg
viewCardMenu n card =
    menu
        [ menuButton "Mirror" (Mirror n)
        , menuButton "Remove" (Remove n)
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
        , onClick msg
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


fill : Style
fill =
    batch
        [ position absolute
        , top zero
        , left zero
        , bottom zero
        , right zero
        ]


onPreventStop : String -> Decoder msg -> Html.Attribute msg
onPreventStop name =
    Events.custom name
        << D.map
            (\msg ->
                { message = msg
                , stopPropagation = True
                , preventDefault = True
                }
            )


onMouseWheel : (Point -> msg) -> Html.Attribute msg
onMouseWheel mkMsg =
    onPreventStop "wheel"
        (deltaDecoder |> D.map mkMsg)


onContextMenu : (Point -> msg) -> Html.Attribute msg
onContextMenu mkMsg =
    onPreventStop "contextmenu"
        (xyDecoder |> D.map mkMsg)


onDragOver : msg -> Html.Attribute msg
onDragOver =
    onPreventStop "dragover" << D.succeed


onDrop : (Point -> List File -> msg) -> Html.Attribute msg
onDrop mkMsg =
    onPreventStop "drop" <|
        D.map2 mkMsg
            xyDecoder
            dataTransferFileDecoder


clipboardDecoder : Decoder (List File)
clipboardDecoder =
    D.field "clipboardData" DataTransfer.elmFileDecoder


dataTransferFileDecoder : Decoder (List File)
dataTransferFileDecoder =
    D.field "dataTransfer" DataTransfer.elmFileDecoder


movementDecoder : Decoder Point
movementDecoder =
    D.map2 Point
        (D.field "movementX" D.float)
        (D.field "movementY" D.float)


deltaDecoder : Decoder Point
deltaDecoder =
    D.map2 Point
        (D.field "deltaX" D.float)
        (D.field "deltaY" D.float)


xyDecoder : Decoder Point
xyDecoder =
    D.map2 Point
        (D.field "x" D.float)
        (D.field "y" D.float)
