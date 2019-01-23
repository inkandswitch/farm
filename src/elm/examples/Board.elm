module Board exposing (Doc, Msg, State, gizmo)

import Array exposing (Array)
import Browser.Events
import Clipboard
import Config
import Css exposing (..)
import Dict
import Extra.Array as Array
import File exposing (File)
import Gizmo exposing (Flags, Model)
import Html.Styled as Html exposing (Html, button, div, fromUnstyled, input, text, toUnstyled)
import Html.Styled.Attributes as Attr exposing (css, value)
import Html.Styled.Events as Events exposing (on, onClick, onDoubleClick, onInput, onMouseDown, onMouseUp)
import Json.Decode as Json exposing (Decoder)
import Json.Encode as E
import RealmUrl
import Repo exposing (Ref, Url)
import Task
import Tuple exposing (pair)
import VsCode


gizmo : Gizmo.Program State Doc Msg
gizmo =
    Gizmo.element
        { init = init
        , update = update
        , view = view >> toUnstyled
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


{-| Ephemeral state not saved to the doc
-}
type alias State =
    { action : Action
    , menu : Menu
    }


type alias Card =
    { code : Url
    , data : Url
    , x : Float
    , y : Float
    , w : Float
    , h : Float
    , z : Int
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
      , menu = NoMenu
      }
    , { cards = Array.empty
      , maxZ = 1
      }
    , Cmd.none
    )


{-| Message type for modifying State and Doc inside update
-}
type Msg
    = NoOp
    | Stop
    | Move Int
    | Resize Int
    | MouseDelta Point
    | Mirror Int
    | Remove Int
    | Click Int
    | SetMenu Menu
    | CreateCard Url
    | DroppedImages (List File)
    | CreateImages (List String)
    | Created ( Ref, List Url )
    | NavigateToCard Int


update : Msg -> Model State Doc -> ( State, Doc, Cmd Msg )
update msg { state, doc } =
    case msg of
        NoOp ->
            ( state, doc, Cmd.none )

        Stop ->
            ( { state | action = None }
            , doc |> applyAction state.action
            , Cmd.none
            )

        Move n ->
            case doc |> getCard n of
                Nothing ->
                    ( state, doc, Cmd.none )

                Just card ->
                    ( { state | action = Moving n { x = card.x, y = card.y } }
                    , doc
                    , Cmd.none
                    )

        Resize n ->
            case doc |> getCard n of
                Nothing ->
                    ( state, doc, Cmd.none )

                Just card ->
                    ( { state | action = Resizing n { w = card.w, h = card.h } }
                    , doc
                    , Cmd.none
                    )

        MouseDelta delta ->
            case state.action of
                None ->
                    ( state, doc, Cmd.none )

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
            ( state
            , { doc | cards = doc.cards |> Array.remove n }
            , Cmd.none
            )

        SetMenu m ->
            ( { state | menu = m }, doc, Cmd.none )

        CreateCard code ->
            ( state, doc, Repo.create code 1 )

        Created ( code, urls ) ->
            case urls of
                [ data ] ->
                    let
                        card =
                            newCard code data
                                |> moveTo (menuPosition state.menu)
                    in
                    ( { state | menu = NoMenu }, doc |> pushCard card, Cmd.none )

                _ ->
                    ( state, doc, Cmd.none )

        DroppedImages files ->
            ( state
            , doc
            , files
                |> List.map File.toUrl
                |> Task.sequence
                |> Task.perform CreateImages
            )

        CreateImages srcs ->
            ( state
            , doc
            , srcs
                |> List.map (\src -> [ ( "src", E.string src ) ])
                |> List.map (Repo.createWithProps Config.image 1)
                |> Cmd.batch
            )

        NavigateToCard n ->
            ( state
            , doc
            , doc
                |> getCard n
                |> Result.fromMaybe "Could not find this card"
                |> Result.andThen RealmUrl.create
                |> Result.map (E.string >> Gizmo.emit "navigate")
                |> Result.withDefault Cmd.none
            )


subscriptions : Model State Doc -> Sub Msg
subscriptions { state, doc } =
    Sub.batch
        [ Repo.created Created
        , case state.action of
            None ->
                Sub.none

            _ ->
                Sub.batch
                    [ Browser.Events.onMouseMove (deltaDecoder |> Json.map MouseDelta)
                    , Browser.Events.onMouseUp (Json.succeed Stop)
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


menuPosition : Menu -> Point
menuPosition mnu =
    case mnu of
        BoardMenu pt ->
            pt

        _ ->
            { x = 0, y = 0 }


applyAction : Action -> Doc -> Doc
applyAction action doc =
    case action of
        None ->
            doc

        Moving n pt ->
            doc
                |> updateCard n (moveTo pt)
                |> bumpZ n

        Resizing n size ->
            doc |> updateCard n (resizeTo size)


snap : Float -> Float
snap fl =
    let
        n =
            Basics.round fl

        offset =
            modBy 24 n
    in
    toFloat (n - offset)


snapPoint : Point -> Point
snapPoint { x, y } =
    { x = snap x, y = snap y }


snapSize : Size -> Size
snapSize { w, h } =
    { w = snap w, h = snap h }


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
            ]
        , onDragOver NoOp
        , onDrop DroppedImages
        , onPaste DroppedImages
        ]
        [ viewBackground
        , viewContextMenu doc state.menu
        , div []
            (doc
                |> applyAction state.action
                |> .cards
                |> Array.indexedMap viewCard
                |> Array.toList
            )
        ]


viewBackground : Html Msg
viewBackground =
    div
        [ onContextMenu (SetMenu << BoardMenu)
        , onMouseDown (SetMenu NoMenu)
        , Attr.tabindex 0
        , css
            [ fill
            , backgroundColor (hex "f9f8f3")
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
            [ fromUnstyled <| Gizmo.render card.code card.data
            ]
        , viewResize n
        ]


openDocumentValue : E.Value -> Url
openDocumentValue value =
    case Json.decodeValue Json.string value of
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
        [ menuButton "Chat" (CreateCard Config.chat)
        , menuButton "Board" (CreateCard Config.board)
        , menuButton "Note" (CreateCard Config.note)
        , menuButton "Todo List" (CreateCard Config.todoList)
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
        << Json.map
            (\msg ->
                { message = msg
                , stopPropagation = True
                , preventDefault = True
                }
            )


onContextMenu : (Point -> msg) -> Html.Attribute msg
onContextMenu mkMsg =
    onPreventStop "contextmenu"
        (xyDecoder |> Json.map mkMsg)


onDragOver : msg -> Html.Attribute msg
onDragOver =
    onPreventStop "dragover" << Json.succeed


onDrop : (List File -> msg) -> Html.Attribute msg
onDrop mkMsg =
    onPreventStop "drop"
        (dataTransferDecoder |> Json.map mkMsg)


onPaste : (List File -> msg) -> Html.Attribute msg
onPaste mkMsg =
    onPreventStop "paste"
        (clipboardDecoder |> Json.map mkMsg)


clipboardDecoder : Decoder (List File)
clipboardDecoder =
    Json.at [ "clipboardData", "files" ] (Json.list File.decoder)


dataTransferDecoder : Decoder (List File)
dataTransferDecoder =
    Json.at [ "dataTransfer", "files" ] (Json.list File.decoder)


deltaDecoder : Decoder Point
deltaDecoder =
    Json.map2 Point
        (Json.field "movementX" Json.float)
        (Json.field "movementY" Json.float)


xyDecoder : Decoder Point
xyDecoder =
    Json.map2 Point
        (Json.field "x" Json.float)
        (Json.field "y" Json.float)
