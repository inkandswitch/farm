module CounterTutorial exposing (Doc, Msg, State, gizmo)

import Array exposing (Array)
import Css exposing (..)
import Doc
import Gizmo exposing (Flags, Model)
import Html.Styled as Html exposing (Html, a, br, button, div, h1, h2, p, pre, text)
import Html.Styled.Attributes as Attr exposing (css, href)
import Html.Styled.Events exposing (onClick)
import Json.Decode as D
import Repo
import VsCode


gizmo : Gizmo.Program State Doc Msg
gizmo =
    Gizmo.element
        { init = init
        , update = update
        , view = Html.toUnstyled << view
        , subscriptions = subscriptions
        }


{-| Ephemeral state not saved to the doc
-}
type alias State =
    { code : Doc.RawDoc
    , data : Doc.RawDoc
    }


{-| Document state
-}
type alias Doc =
    { step : Int
    , codeUrl : String
    , dataUrl : String
    }


init : Flags -> ( State, Doc, Cmd Msg )
init flags =
    let
        doc =
            flags.rawDoc
                |> D.decodeValue docDecoder
                |> Result.withDefault
                    { step = 0
                    , codeUrl = ""
                    , dataUrl = ""
                    }
    in
    ( { code = Doc.rawEmpty
      , data = Doc.rawEmpty
      }
    , doc
    , Cmd.batch
        [ Repo.open doc.codeUrl
        , Repo.open doc.dataUrl
        ]
    )


docDecoder : D.Decoder Doc
docDecoder =
    D.map3 Doc
        (D.field "step" D.int)
        (D.field "codeUrl" D.string)
        (D.field "dataUrl" D.string)


{-| Message type for modifying State and Doc inside update
-}
type Msg
    = NoOp
    | Next
    | Prev
    | CodeChanged Doc.RawDoc
    | DataChanged Doc.RawDoc


update : Msg -> Model State Doc -> ( State, Doc, Cmd Msg )
update msg { state, doc } =
    case msg of
        NoOp ->
            ( state, doc, Cmd.none )

        Next ->
            ( state, { doc | step = min stepCount (doc.step + 1) }, Cmd.none )

        Prev ->
            ( state, { doc | step = max 0 (doc.step - 1) }, Cmd.none )

        CodeChanged d ->
            ( { state | code = d }
            , doc
            , Cmd.none
            )

        DataChanged d ->
            ( { state | data = d }
            , doc
            , if doc.step == 1 && getCounter d >= 10 then
                Gizmo.send Next

              else
                Cmd.none
            )


subscriptions : Model State Doc -> Sub Msg
subscriptions { doc } =
    Repo.rawDocs
        (\( url, rDoc ) ->
            if url == doc.codeUrl then
                CodeChanged rDoc

            else if url == doc.dataUrl then
                DataChanged rDoc

            else
                NoOp
        )


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
viewStep model =
    case steps |> Array.get model.doc.step of
        Just stepFn ->
            stepFn model

        Nothing ->
            [ controls [ prev ]
            ]


stepCount : Int
stepCount =
    Array.length steps


steps : Array (Model State Doc -> List (Html Msg))
steps =
    Array.fromList
        [ \_ ->
            [ title "Welcome to Realm"
            , p [] [ text "This tutorial will guide you through the creation of your first Realm gizmo." ]
            , controls [ next ]
            ]
        , \{ state } ->
            [ title "A simple counter"
            , p []
                [ text "Your gizmo's journey begins above."
                , text "Your counter is currently at "
                , code <| String.fromInt <| getCounter state.data
                , text ". Click the counter until it reaches 10 to continue."
                ]
            , controls [ prev ]
            ]
        , \{ doc } ->
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
        , \_ ->
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
        , \{ doc } ->
            [ title "Open your gizmo's data document"
            , p []
                [ text "Copy the URL below. "
                ]
            , codeBlock [ a [ href doc.dataUrl ] [ text doc.dataUrl ] ]
            , p []
                [ text "Use the Command Palette to select the "
                , code "Open document"
                , text " command. Paste the copied URL into the input box, "
                , text "and confirm with Enter. "
                ]
            , controls [ prev, next ]
            ]
        , \_ ->
            [ title "Edit your gizmo's data"
            , p []
                [ text "You can find your documents in VS Code's Explorer view, below your files. "
                , text "You may have to expand the section labeled 'HypermergeFS'. "
                , text "Select the document titled 'Counter data'. "
                ]
            , controls [ prev, next ]
            ]
        , \_ ->
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
        , \_ ->
            [ title "TODO: Store a `selected` image"
            , p []
                [ text "Add `selected : Maybe String` to `State`. "
                , text "set `selected` in `update`. "
                , text "Display the `selected` url in `view`"
                ]
            , controls [ prev, next ]
            ]
        , \_ ->
            [ title "TODO: Display actual image using Gizmo.render"
            , p []
                []
            , controls [ prev, next ]
            ]
        , \_ ->
            [ title "TODO: Add 'esc' keyboard handling to deselect"
            , p []
                []
            , controls [ prev, next ]
            ]
        , \_ ->
            [ title "TODO: Add lightbox css styles"
            , p []
                []
            , controls [ prev, next ]
            ]
        , \_ ->
            [ title "TODO: Add a 'shield' div to hide lightbox on click"
            , p []
                []
            , controls [ prev, next ]
            ]
        , \_ ->
            [ title "TODO: Add your gizmo to launcher"
            , p []
                []
            , controls [ prev, next ]
            ]
        ]


getCounter : Doc.RawDoc -> Int
getCounter data =
    data
        |> D.decodeValue (D.field "counter" D.int)
        |> Result.withDefault 0


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
