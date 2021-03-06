module CounterTutorial exposing (Doc, Msg, State, gizmo)

import Array exposing (Array)
import Css exposing (..)
import Doc
import FarmUrl
import Gizmo exposing (Flags, Model)
import Html.Styled as Html exposing (Html, a, br, button, div, h1, h2, p, pre, text)
import Html.Styled.Attributes as Attr exposing (css, disabled, href)
import Html.Styled.Events exposing (onClick)
import Json.Decode as D
import Repo
import VsCode


gizmo : Gizmo.Program State Doc Msg
gizmo =
    Gizmo.element
        { init = init
        , update = update
        , view = view
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
            , height (pct 100)
            ]
        ]
        [ div
            [ css
                [ border3 (px 1) dotted (hex "ddd")
                , padding (px 10)
                ]
            ]
            [ Gizmo.render doc.codeUrl doc.dataUrl
            ]
        , div
            [ css
                [ width (pct 80)
                , padding (px 20)
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
            [ title "Welcome to the Farm"
            , p [] [ text "This tutorial will guide you through the creation of your first Farm gizmo." ]
            , p [] [ text "A gizmo is a pairing of a program with data that lives on your computer and can be reused and shared with anyone." ]
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
                [ text "We'll install from the extensions registry. "
                , text "Select the nested squares icon and search for Hypermerge."
                ]
            , controls [ prev, next ]
            ]
        , \{ doc } ->
            [ title "Open your gizmo's data document"
            , p []
                [ text "Click the URL below to open it in VS Code. "
                ]
            , codeBlock
                [ a
                    [ href (VsCode.link doc.dataUrl)
                    ]
                    [ text (VsCode.link doc.dataUrl)
                    ]
                ]
            , p []
                [ text "In VS Code, confirm you want to open the document "
                , text "by clicking \"Open\". "
                , text "You'll see the file arrive in your VSCode install as "
                , text "an editable block of JSON. "
                , text "In fact, you could open that URL from any computer in the world."
                ]
            , controls [ prev, next ]
            ]
        , \{ state } ->
            [ title "Edit your gizmo's data"
            , p []
                [ text "If you clicked the link in the last step, your"
                , text "Gizmo's data should be the active window in VS Code. "
                , text "You can always find your documents in VS Code's Explorer view, below your files. "
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
                , text "Click the URL below to open in VS Code. "
                , text "If the code doesn't have syntax highlighting, "
                , text "you should install the VSCode Elm plugin."
                ]
            , codeBlock
                [ a
                    [ href (VsCode.link <| doc.codeUrl ++ "/Source.elm")
                    ]
                    [ text (VsCode.link doc.codeUrl ++ "/Source.elm")
                    ]
                ]
            , p []
                [ text "Once it opens, unfold the document and click on the "
                , code "Source.elm"
                , text " field to view the code behind your counter."
                ]
            , controls [ prev, next ]
            ]
        , \_ ->
            [ title "Get some Inc-sight"
            , p []
                [ text "Find the first line of the 'update' function: "
                , code "case msg of"
                , text ". Change that line to "
                , code "case Debug.log \"msg\" msg of"
                , text ". Open the Developer Tools console here in Farm, "
                , text "then click the button a few times. You'll see the Inc "
                , text "message arriving to the update function each time you click."
                ]
            , controls [ prev, next ]
            ]
        , \_ ->
            [ title "What just happened?"
            , p []
                [ text "Every Gizmo is a little Elm language program which "
                , text "lives on your computer and gets re-compiled when you make changes."
                ]
            , p []
                [ text "Everytime the data document changes or you modify your local "
                , code "state"
                , text " variable, Elm will run your "
                , code "view"
                , text " function and produce new HTML for you to look at. When you "
                , text "send a message ("
                , code "Msg"
                , text ") from somewhere like a button, Elm will pass that to your "
                , code "update"
                , text " function... which will probably trigger a new view! So easy!"
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
                , text "Duplicate the Inc branch, and update it for Dec. I think you'll be able to "
                , text "figure this one out on your own, but if you have trouble, Elm has great "
                , text "compiler errors to guide you."
                ]
            , controls [ prev, next ]
            ]
        , \_ ->
            [ title "Pushbutton problems"
            , p []
                [ text "We've added support for sending Decrement messages, "
                , text "but we don't have any way of sending them yet. Whoops!"
                ]
            , p []
                [ text "Your next task is to add a button that sends the Dec message. "
                , text "(You should be fine with this, right?)"
                ]
            , controls [ prev, next ]
            ]
        , \_ ->
            [ title "Congratulations!"
            , p []
                [ text "The gizmo you've created can count up and down now, "
                , text "and you should be proud of your work."
                ]
            , p []
                [ text "From here, you can build anything. Take a look at how "
                , text "the other gizmos are built. You can inspect anything in Farm "
                , text "since all the code lives on your computer! We've "
                , text "tried to keep your starting gizmos simple and easy to learn from."
                ]
            , controls [ prev, next ]
            ]
        , \{ doc } ->
            [ title "Sharing is Caring"
            , p []
                [ text "Your counter gizmo deserves to see the world! "
                , text "You can share this handy Farm url to link your friends and "
                , text "family pets directly to your gizmo."
                , case FarmUrl.create { data = doc.dataUrl, code = doc.codeUrl } of
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
            , overflowX auto
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


disabledNext : Html Msg
disabledNext =
    button
        [ disabled True
        , css
            [ marginLeft auto
            ]
        ]
        [ text "Not yet!" ]


nextIf : Bool -> Html Msg
nextIf b =
    if b then
        next

    else
        disabledNext


controls : List (Html msg) -> Html msg
controls =
    div
        [ css
            [ displayFlex
            , marginTop (px 10)
            ]
        ]
