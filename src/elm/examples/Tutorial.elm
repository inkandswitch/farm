module Tutorial exposing (Doc, Msg, State, gizmo)

import Css exposing (..)
import Gizmo exposing (Model)
import Html.Styled as Html exposing (Html, a, br, button, div, h1, h2, p, pre, text)
import Html.Styled.Attributes as Attr exposing (css, href)
import Html.Styled.Events exposing (onClick)
import VsCode


gizmo : Gizmo.Program State Doc Msg
gizmo =
    Gizmo.sandbox
        { init = init
        , update = update
        , view = Html.toUnstyled << view
        }


{-| Ephemeral state not saved to the doc
-}
type alias State =
    {}


{-| Document state
-}
type alias Doc =
    { step : Int
    , codeUrl : String
    , dataUrl : String
    }


init : ( State, Doc )
init =
    ( {}
    , { step = 1
      , codeUrl = ""
      , dataUrl = ""
      }
    )


{-| Message type for modifying State and Doc inside update
-}
type Msg
    = Next
    | Prev


update : Msg -> Model State Doc -> ( State, Doc )
update msg { doc } =
    case msg of
        Next ->
            ( {}, { doc | step = min 11 (doc.step + 1) } )

        Prev ->
            ( {}, { doc | step = max 1 (doc.step - 1) } )


view : Model State Doc -> Html Msg
view ({ doc } as model) =
    div
        [ css
            [ property "display" "grid"
            , property "grid-template-rows" "1fr auto"
            , alignItems center
            , fontFamilies [ "system-ui" ]
            , fontSize (px 15)
            , lineHeight (num 1.5)
            , property "justify-items" "center"
            , property "transition" "all 500ms"
            , height (vh 100)
            ]
        ]
        [ div
            [ css
                [ border3 (px 1) dotted (hex "ddd")
                , padding (px 10)
                ]
            ]
            [ Html.fromUnstyled <| Gizmo.render doc.codeUrl doc.dataUrl
            ]
        , div
            [ css
                [ padding (px 20)
                , property "transition" "all 500ms"
                ]
            ]
            (viewStep model)
        ]


viewStep : Model State Doc -> List (Html Msg)
viewStep { doc } =
    case doc.step of
        1 ->
            [ title "Welcome to Realm"
            , p [] [ text "This tutorial will guide you through the creation of your first Realm gizmo." ]
            , controls [ next ]
            ]

        2 ->
            [ title "Download the Hypermerge VS Code extension"
            , p []
                [ text "We'll install with a .vsix package. "
                , text "The latest release can be found on the "
                , a
                    [ href "https://github.com/inkandswitch/hypermergefs-vscode/releases"
                    , onClick Next
                    ]
                    [ text "Releases page" ]
                , text "."
                ]
            , controls [ prev, next ]
            ]

        3 ->
            [ title "Install the .vsix package"
            , p []
                [ text "In VS Code, open the Command Palette (Cmd-Shift-P) and type "
                , code "vsix"
                , text ". "
                , br [] []
                , text "Select "
                , code "Extensions: Install from VSIX..."
                , text " and open the vscode-hypermergefs.vsix package from the file picker."
                ]
            , controls [ prev, next ]
            ]

        4 ->
            [ title "Open your gizmo's data document"
            , p []
                [ text "Copy the URL below and open it with vscode -fixme."
                ]
            , codeBlock [ a [ href doc.dataUrl ] [ text doc.dataUrl ] ]
            , controls [ prev, next ]
            ]

        5 ->
            [ title "TODO: Duplicate an image in the gallery's images"
            , p []
                [ text "Would be cool to auto-advance if the subDoc.images.length changes"
                ]
            , controls [ prev, next ]
            ]

        6 ->
            [ title "TODO: Add an onClick to each image"
            , p []
                [ text "add "
                , code "| Clicked String"
                , text " to the Msg type."
                , text "add no-op `Clicked url ->` to `update`"
                , text "perhaps Debug.log 'msg' msg"
                ]
            , controls [ prev, next ]
            ]

        7 ->
            [ title "TODO: Store a `selected` image"
            , p []
                [ text "Add `selected : Maybe String` to `State`. "
                , text "set `selected` in `update`. "
                , text "Display the `selected` url in `view`"
                ]
            , controls [ prev, next ]
            ]

        8 ->
            [ title "TODO: Display actual image using Gizmo.render"
            , p []
                []
            , controls [ prev, next ]
            ]

        9 ->
            [ title "TODO: Add 'esc' keyboard handling to deselect"
            , p []
                []
            , controls [ prev, next ]
            ]

        10 ->
            [ title "TODO: Add lightbox css styles"
            , p []
                []
            , controls [ prev, next ]
            ]

        11 ->
            [ title "TODO: Add a 'shield' div to hide lightbox on click"
            , p []
                []
            , controls [ prev, next ]
            ]

        12 ->
            [ title "TODO: Add your gizmo to launcher"
            , p []
                []
            , controls [ prev, next ]
            ]

        _ ->
            [ controls [ prev ]
            ]


codeBlock : List (Html msg) -> Html msg
codeBlock =
    pre
        [ css
            [ backgroundColor (hex "eee")
            , borderRadius (px 3)
            , fontFamily monospace
            , padding (px 10)
            , margin2 (px 10) zero
            ]
        ]


code : String -> Html msg
code str =
    Html.code
        [ css
            [ backgroundColor (hex "eee")
            , whiteSpace preWrap
            , color (hex "f33")
            , borderRadius (px 2)
            , fontFamily monospace
            , padding2 zero (px 5)
            ]
        ]
        [ text str ]


title : String -> Html Msg
title str =
    h2
        [ css
            [ fontSize (em 1.3)
            , marginBottom (px 20)
            ]
        ]
        [ text str ]


prev : Html Msg
prev =
    button
        [ onClick Prev
        , css
            [ marginRight auto
            ]
        ]
        [ text "Back" ]


next : Html Msg
next =
    button
        [ onClick Next
        , css
            [ marginLeft auto
            ]
        ]
        [ text "Continue" ]


controls : List (Html msg) -> Html msg
controls =
    div
        [ css
            [ displayFlex
            , marginTop (px 10)
            ]
        ]
