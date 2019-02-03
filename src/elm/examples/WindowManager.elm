module WindowManager exposing (Doc, Msg, State, gizmo)

import Array exposing (Array)
import Browser.Events
import Clipboard
import Css exposing (..)
import Dict
import Extra.Array as Array
import Gizmo exposing (Flags, Model)
import Html.Styled as Html exposing (Html, button, div, input, text)
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
        , view = view
        , subscriptions = subscriptions
        }


type Action
    = None
    | Moving Int Point
    | Resizing Int Size


type Menu
    = NoMenu
    | GlobalMenu Point
    | WinMenu Int Point


type Modal
    = NoModal
    | OpenModal Point String


type alias Deps =
    { title : String -> Html Msg
    , empty : String -> Html Msg
    }


{-| Ephemeral state not saved to the doc
-}
type alias State =
    { action : Action
    , menu : Menu
    , modal : Modal
    , deps : Deps
    }


type alias Window =
    { data : Maybe Url
    , code : Url
    , x : Float
    , y : Float
    , w : Float
    , h : Float
    , z : Int
    }


{-| Document state
-}
type alias Doc =
    { windows : Array Window
    , maxZ : Int
    }


init : Flags -> ( State, Doc, Cmd Msg )
init flags =
    ( { action = None
      , menu = NoMenu
      , modal = NoModal
      , deps = makeDeps flags
      }
    , { windows = Array.empty
      , maxZ = 0
      }
    , Cmd.none
    )


makeDeps : Flags -> Deps
makeDeps { config } =
    let
        make =
            \name ->
                config
                    |> Dict.get name
                    |> Maybe.map Gizmo.render
                    |> Maybe.withDefault (always <| text (name ++ " gizmo missing"))
    in
    { title = make "title"
    , empty = make "empty"
    }


{-| Message type for modifying State and Doc inside update
-}
type Msg
    = NoOp
    | Stop
    | Move Int
    | Resize Int
    | MouseDelta Point
    | Mirror Int
    | Close Int
    | Click Int
    | SetMenu Menu
    | SetModal Modal
    | CopyText String
    | NewDocument Url
    | SetWindowData Int Url
    | Created ( Ref, List Url )
    | EmptyWindow Url Point


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
            , case doc.windows |> Array.get n of
                Just win ->
                    doc |> pushWindow (win |> moveBy (Point 10 10))

                Nothing ->
                    doc
            , Cmd.none
            )

        Close n ->
            ( state
            , { doc | windows = doc.windows |> Array.remove n }
            , Cmd.none
            )

        SetMenu m ->
            ( { state | menu = m }, doc, Cmd.none )

        SetModal m ->
            ( { state | modal = m }, doc, Cmd.none )

        CopyText str ->
            ( state, doc, Clipboard.copy str )

        NewDocument codeUrl ->
            ( state, doc, Repo.create codeUrl 1 )

        Created ( code, urls ) ->
            case urls of
                data :: _ ->
                    ( state
                    , doc
                        |> pushWindow (newWindow code (Just data))
                    , Cmd.none
                    )

                _ ->
                    ( state, doc, Cmd.none )

        EmptyWindow code pt ->
            ( { state | modal = NoModal }
            , doc
                |> pushWindow (newWindow code Nothing |> moveTo pt)
            , Cmd.none
            )

        SetWindowData n data ->
            ( state
            , doc |> updateWindow n (\w -> { w | data = Just data })
            , Cmd.none
            )


newWindow : Url -> Maybe Url -> Window
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
    .windows >> Array.get n


pushWindow : Window -> Doc -> Doc
pushWindow win doc =
    { doc | windows = doc.windows |> Array.push win }
        |> bumpZ (Array.length doc.windows)


updateWindow : Int -> (Window -> Window) -> Doc -> Doc
updateWindow n f doc =
    { doc | windows = doc.windows |> Array.update n f }


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
                    , windows = doc.windows |> Array.set n { win | z = doc.maxZ + 1 }
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
        [ viewContextMenu doc state.menu
        , div
            [ css
                [ fill
                , backgroundColor (hex "f9f8f3")
                ]
            , onContextMenu (SetMenu << GlobalMenu)
            ]
            []
        , div []
            (doc
                |> applyAction state.action
                |> .windows
                |> Array.indexedMap (viewWindow state.deps)
                |> Array.toList
            )
        , viewModal state.modal
        ]


viewWindow : Deps -> Int -> Window -> Html Msg
viewWindow deps n win =
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
            ]
        , onMouseUp (Click n)
        ]
        [ viewTitleBar deps n win
        , div
            [ css
                [ overflow hidden
                ]
            ]
            [ case win.data of
                Just data ->
                    Gizmo.render win.code data

                Nothing ->
                    viewEmptyWindow deps n win
            ]
        , viewResize n
        ]


viewEmptyWindow : Deps -> Int -> Window -> Html Msg
viewEmptyWindow deps n win =
    div
        [ Gizmo.onEmit "OpenDocument" (.value >> openDocumentValue >> SetWindowData n)
        ]
        [ deps.empty win.code
        ]


openDocumentValue : E.Value -> Url
openDocumentValue value =
    case Json.decodeValue Json.string value of
        Ok url ->
            url

        Err msg ->
            ""



--TODO: handle this case


viewTitleBar : Deps -> Int -> Window -> Html Msg
viewTitleBar deps n win =
    div
        [ css
            [ padding (px 2)
            , borderBottom3 (px 1) solid (hex "ddd")
            , textAlign center
            , alignItems center
            , displayFlex
            ]
        , onContextMenu (SetMenu << WinMenu n)
        , onMouseDown (Move n)
        ]
        [ button "✕"
            (Close n)
        , div [ css [ flexGrow (int 1) ] ]
            [ win.data
                |> Maybe.withDefault win.code
                |> viewTitle
            ]
        ]


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


viewTitle : String -> Html Msg
viewTitle =
    Gizmo.render "hypermerge:/E19jZZNm4QceSWwwiZGLtrduFVDwmdtM3PGFAfMMS55S"


viewEmptyGizmo : String -> Html Msg
viewEmptyGizmo =
    Gizmo.render "hypermerge:/yCNgQ8kE3v3xkqdembXjzk2knXfEaoHwe5iK3jPXy1K"


viewContextMenu : Doc -> Menu -> Html Msg
viewContextMenu doc menuType =
    case menuType of
        NoMenu ->
            null

        GlobalMenu pt ->
            positioned pt
                [ viewGlobalMenu pt ]

        WinMenu n pt ->
            case doc |> getWindow n of
                Just win ->
                    positioned pt
                        [ viewDocMenu n win ]

                Nothing ->
                    null


viewDocMenu : Int -> Window -> Html Msg
viewDocMenu n win =
    menu
        ([ menuButton "Mirror" (Mirror n)
         , menuButton "Open document..." (EmptyWindow win.code { x = win.x + 20, y = win.y + 20 })
         , menuButton "New document" (NewDocument win.code)
         , menuButton "Copy code url" (CopyText win.code)
         , menuLink "Edit code in VSCode" (VsCode.link win.code)
         ]
            ++ (case win.data of
                    Just data ->
                        [ menuButton "Copy data url" (CopyText data)
                        , menuLink "Edit data in VSCode" (VsCode.link data)
                        ]

                    Nothing ->
                        []
               )
        )


viewGlobalMenu : Point -> Html Msg
viewGlobalMenu pt =
    menu
        [ menuButton "Open gizmo..." (SetModal (OpenModal pt ""))
        ]


viewModal : Modal -> Html Msg
viewModal mod =
    case mod of
        NoModal ->
            null

        OpenModal pt str ->
            modal
                [ viewOpenModal pt str ]


viewOpenModal : Point -> String -> Html Msg
viewOpenModal pt str =
    div []
        [ text "Code url:"
        , Html.form [ Events.onSubmit (EmptyWindow str pt) ]
            [ input
                [ Attr.autofocus True
                , Attr.placeholder "hypermergefs:/abc123"
                , Attr.size 80
                , value str
                , onInput (SetModal << OpenModal pt)
                ]
                []
            , button "Open" NoOp
            ]
        ]


menu : List (Html msg) -> Html msg
menu =
    div
        [ css
            [ border3 (px 1) solid (hex "ddd")
            , borderBottomWidth (px 0)
            , borderRadius (px 3)
            , backgroundColor (hex "#fff")
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


modal : List (Html Msg) -> Html Msg
modal children =
    div
        [ css
            [ fill
            , displayFlex
            , alignItems center
            , justifyContent center
            , zIndex (int 99999999)
            ]
        ]
        [ div
            [ css
                [ fill
                , backgroundColor (rgba 0 0 0 0.2)
                , zIndex (int -1)
                ]
            , onClick (SetModal NoModal)
            ]
            []
        , div
            [ css
                [ bordered
                , padding (px 10)
                ]
            ]
            children
        ]


positioned : Point -> List (Html msg) -> Html msg
positioned { x, y } =
    div
        [ css
            [ position absolute
            , zIndex (int 999999999)
            , transform <| translate2 (px x) (px y)
            ]
        ]


button : String -> msg -> Html msg
button label msg =
    Html.button
        [ onClick msg
        , css
            [ property "appearance" "none"
            , bordered
            , borderRadius (px 2)
            , cursor pointer
            ]
        ]
        [ text label ]


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
        [ Repo.created Created
        , case state.menu of
            NoMenu ->
                Sub.none

            _ ->
                Browser.Events.onClick (Json.succeed (SetMenu NoMenu))
        , case state.action of
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
