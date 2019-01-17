module Board exposing (Doc, Msg, State, gizmo)

import Array exposing (Array)
import Browser.Events
import Clipboard
import Css exposing (..)
import Dict
import Extra.Array as Array
import Gizmo exposing (Flags, Model)
import Html.Styled as Html exposing (Html, button, div, fromUnstyled, input, text, toUnstyled)
import Html.Styled.Attributes as Attr exposing (css, value)
import Html.Styled.Events as Events exposing (on, onClick, onInput, onMouseDown, onMouseUp)
import Json.Decode as Json exposing (Decoder)
import Json.Encode as E
import Repo exposing (Ref, Url)
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


{-| Ephemeral state not saved to the doc
-}
type alias State =
    { action : Action
    }


type alias Window =
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
    { cards : Array Window
    , maxZ : Int
    }


init : Flags -> ( State, Doc, Cmd Msg )
init flags =
    ( { action = None
      }
    , { cards = Array.empty
      , maxZ = 0
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
            case doc |> getWindow n of
                Nothing ->
                    ( state, doc, Cmd.none )

                Just win ->
                    ( { state | action = Moving n { x = win.x, y = win.y } }
                    , doc
                    , Cmd.none
                    )

        Resize n ->
            case doc |> getWindow n of
                Nothing ->
                    ( state, doc, Cmd.none )

                Just win ->
                    ( { state | action = Resizing n { w = win.w, h = win.h } }
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
            ( state
            , case doc.cards |> Array.get n of
                Just win ->
                    doc |> pushWindow (win |> moveBy (Point 10 10))

                Nothing ->
                    doc
            , Cmd.none
            )

        Remove n ->
            ( state
            , { doc | cards = doc.cards |> Array.remove n }
            , Cmd.none
            )


newWindow : Url -> Url -> Window
newWindow code data =
    { data = data
    , code = code
    , x = 20
    , y = 20
    , w = 300
    , h = 400
    , z = 0
    }


getWindow : Int -> Doc -> Maybe Window
getWindow n =
    .cards >> Array.get n


pushWindow : Window -> Doc -> Doc
pushWindow win doc =
    { doc | cards = doc.cards |> Array.push win }
        |> bumpZ (Array.length doc.cards)


updateWindow : Int -> (Window -> Window) -> Doc -> Doc
updateWindow n f doc =
    { doc | cards = doc.cards |> Array.update n f }


applyAction : Action -> Doc -> Doc
applyAction action doc =
    case action of
        None ->
            doc

        Moving n pt ->
            doc
                |> updateWindow n (moveTo pt)
                |> bumpZ n

        Resizing n size ->
            doc |> updateWindow n (resizeTo size)


bumpZ : Int -> Doc -> Doc
bumpZ n doc =
    case doc |> getWindow n of
        Nothing ->
            doc

        Just win ->
            if win.z == doc.maxZ then
                doc

            else
                { doc
                    | maxZ = doc.maxZ + 1
                    , cards = doc.cards |> Array.set n { win | z = doc.maxZ + 1 }
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
    { a | x = max 0 x, y = max 0 y }


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
            , fontFamilies [ "system-ui" ]
            , fontSize (px 14)
            , position absolute
            , top zero
            , left zero
            , bottom zero
            , right zero
            ]
        ]
        [ div
            [ css
                [ fill
                , backgroundColor (hex "f9f8f3")
                ]
            ]
            []
        , div []
            (doc
                |> applyAction state.action
                |> .cards
                |> Array.indexedMap viewWindow
                |> Array.toList
            )
        ]


viewWindow : Int -> Window -> Html Msg
viewWindow n win =
    div
        [ css
            [ property "display" "grid"
            , property "grid-template-rows" "auto 1fr"
            , bordered
            , position absolute
            , transform <| translate2 (px win.x) (px win.y)
            , width (px win.w)
            , height (px win.h)
            , zIndex (int win.z)
            , overflow hidden
            ]
        , onMouseDown (Move n)
        , onMouseUp (Click n)
        ]
        [ fromUnstyled <| Gizmo.render win.code win.data
        , viewResize n
        ]


openDocumentValue : E.Value -> Url
openDocumentValue value =
    case Json.decodeValue Json.string value of
        Ok url ->
            url

        Err msg ->
            ""


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
            ]
        , onMouseDown (Resize n)
        ]
        []


positioned : Point -> List (Html msg) -> Html msg
positioned { x, y } =
    div
        [ css
            [ position absolute
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


onContextMenu : (Point -> msg) -> Html.Attribute msg
onContextMenu mkMsg =
    Events.custom "contextmenu"
        (xyDecoder
            |> Json.map mkMsg
            |> Json.map
                (\msg ->
                    { message = msg
                    , stopPropagation = True
                    , preventDefault = True
                    }
                )
        )


subscriptions : Model State Doc -> Sub Msg
subscriptions { state, doc } =
    Sub.batch
        [ case state.action of
            None ->
                Sub.none

            _ ->
                Sub.batch
                    [ Browser.Events.onMouseMove (deltaDecoder |> Json.map MouseDelta)
                    , Browser.Events.onMouseUp (Json.succeed Stop)
                    ]
        ]


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
