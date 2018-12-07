module CounterTutorial exposing (Doc, Msg, State, gizmo)

import Array exposing (Array)
import Css exposing (..)
import Doc
import Gizmo exposing (Flags, Model)
import Html.Styled as Html exposing (Html, a, br, button, div, h1, h2, p, pre, text)
import Html.Styled.Attributes as Attr exposing (css, href)
import Html.Styled.Events exposing (onClick)
import Json.Decode as D
import RealmUrl
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
            ( state, { doc | step = min maxStep (doc.step + 1) }, Cmd.none )

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
            , Cmd.none
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
view ({ doc, state } as model) =
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
            [ viewError state
            , viewStep model
            ]
        ]


viewStep : Model State Doc -> Html Msg
viewStep model =
    case steps |> Array.get model.doc.step of
        Just stepFn ->
            div [] <| stepFn model

        Nothing ->
            controls [ prev, next ]


maxStep : Int
maxStep =
    Array.length steps - 1


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
                , viewCounter state
                , text ". Click the counter until it reaches 10 to continue."
                ]
            , controls [ prev, nextIf (getCounter state.data >= 10) ]
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
        , \{ state } ->
            [ title "Edit your gizmo's data"
            , p []
                [ text "You can find your documents in VS Code's Explorer view, below your files. "
                , text "You may have to expand the section labeled 'HypermergeFS'. "
                , text "Select the document titled 'Counter data'. "
                , text "To continue, set the \"counter\" value to over 9000."
                ]
            , controls [ prev, nextIf (getCounter state.data >= 9000) ]
            ]
        , \{ doc } ->
            [ title "Open your gizmo's code document"
            , p []
                [ text "It's time to upgrade this counter. "
                , text "Open the URL below in VS Code. "
                , text "Or, click "
                , a [ href (VsCode.link doc.codeUrl) ]
                    [ text "here" ]
                , text " to open it automatically."
                ]
            , codeBlock [ a [ href doc.codeUrl ] [ text doc.codeUrl ] ]
            ]
        , \_ ->
            [ title "Get some Incsight"
            , p []
                [ text "Find the first line of the 'update' function: "
                , code "case msg of"
                , text ". Change that line to "
                , code "case Debug.log \"msg\" msg of"
                , text ". Open the console and bask in the glory of Inc."
                ]
            , controls [ prev, next ]
            ]
        , \_ ->
            [ title "Inc & Switch"
            , p []
                [ text "Let's add a way to decrement the counter. "
                , text "First, let's add a "
                , code "Dec"
                , text " variant to our "
                , code "Msg"
                , text " type: "
                , codeBlock
                    [ text "type Msg\n    = Inc\n    | Dec"
                    ]
                ]
            , controls [ prev, next ]
            ]
        , \_ ->
            [ title "Errors!"
            , p []
                [ text "We added a new variant, but we aren't handling it in our case expression. "
                , text "Duplicate the Inc branch, and update it for Dec. "
                , codeBlock
                    [ text "No sample code for you!"
                    ]
                ]
            , controls [ prev, next ]
            ]
        , \_ ->
            [ title "TODO: Add a decrement button"
            , p []
                []
            , controls [ prev, next ]
            ]
        , \{ doc } ->
            [ title "Done!"
            , p []
                [ text "Your counter gizmo is done! "
                , text "Copy this handy Realm url to link your friends and "
                , text "family pets directly to your gizmo."
                , case RealmUrl.create { data = doc.dataUrl, code = doc.codeUrl } of
                    Ok url ->
                        codeBlock
                            [ a [ href url ] [ text url ]
                            ]

                    Err err ->
                        text <| "Uh oh, something went wrong: " ++ err
                ]
            , controls [ prev ]
            ]
        ]


viewCounter : State -> Html Msg
viewCounter =
    code << String.fromInt << getCounter << .data


getCounter : Doc.RawDoc -> Int
getCounter data =
    data
        |> D.decodeValue (D.field "counter" D.int)
        |> Result.withDefault 0


viewError : State -> Html Msg
viewError state =
    if hasError state.code then
        div [ css [ color (hex "f00") ] ]
            [ text "Yikes! Looks like your gizmo has a syntax error. Check the source in VSCode."
            ]

    else
        text ""


hasError : Doc.RawDoc -> Bool
hasError codeDoc =
    codeDoc
        |> D.decodeValue (D.field "hypermergeFsDiagnostics" (D.succeed True))
        |> Result.withDefault False


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


nextIf : Bool -> Html Msg
nextIf b =
    if b then
        next

    else
        text ""


controls : List (Html msg) -> Html msg
controls =
    div
        [ css
            [ displayFlex
            , marginTop (px 10)
            ]
        ]
