module Main exposing (main)

import Browser
import Html exposing (Html, button, div, pre, text, textarea)
import Html.Attributes exposing (cols, rows, srcdoc, style)
import Html.Events exposing (onClick, onInput)
import Receive
import Send


type alias Model =
    { code : String
    , compiled : String
    , error : String
    }


type Msg
    = Code String
    | ServerMsg ( String, String )


main : Program () Model Msg
main =
    Browser.document
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }


init : () -> ( Model, Cmd Msg )
init () =
    { code = initialCode, compiled = "", error = "" }
        |> compile


subscriptions : Model -> Sub Msg
subscriptions model =
    Receive.fromServer ServerMsg


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        Code code ->
            { model | code = code }
                |> compile

        ServerMsg ( typ, content ) ->
            case typ of
                "Compiled" ->
                    { model | compiled = content, error = "" }
                        |> done

                "CompileError" ->
                    { model | error = content }
                        |> done

                _ ->
                    model
                        |> done


done : Model -> ( Model, Cmd msg )
done model =
    ( model, Cmd.none )


compile : Model -> ( Model, Cmd Msg )
compile model =
    ( model, Send.toServer ( "Compile", model.code ) )


view : Model -> Browser.Document Msg
view model =
    { title = "Realm"
    , body =
        [ div
            [ style "display" "grid"
            , style "grid-template-columns" "1fr 1fr"
            ]
            [ viewEditor model.code
            , viewResult model.compiled
            ]
        , pre [ style "color" "red" ] [ text model.error ]
        ]
    }


viewEditor : String -> Html Msg
viewEditor code =
    div []
        [ textarea
            [ cols 80
            , rows 30
            , onInput Code
            , style "font-family" "monospace"
            , style "font-size" "14px"
            ]
            [ text code ]
        ]


viewResult : String -> Html msg
viewResult result =
    div [] [ Html.iframe [ srcdoc result ] [] ]


initialCode : String
initialCode =
    """module Main exposing (main)

import Html exposing (Html, div, text)


main : Html msg
main =
  div []
        [ text "Hello, world!"
        , text " Change this program and see it update on the right."
        ]
    """
