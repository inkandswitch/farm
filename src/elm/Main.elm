module Main exposing (main)

import Browser
import Html exposing (Html, button, div, pre, text, textarea)
import Html.Attributes exposing (cols, id, rows, srcdoc, style)
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
    div [ id "preview" ]
        [--  Html.iframe [ srcdoc result ] []
        ]


initialCode : String
initialCode =
    """port module Example exposing (main)

import Html exposing (Html, button, div, text)
import Html.Events exposing (onClick)
import Plugin


type alias Doc =
    { counter : Int
    }


port output : Doc -> Cmd msg


port input : (Doc -> msg) -> Sub msg


type Msg
    = Inc
    | Dec


main : Plugin.Program Doc Msg
main =
    Plugin.element
        { init = init
        , update = update
        , view = view
        , input = input
        , output = output
        }


init : Doc
init =
    { counter = 0
    }


update : Msg -> Doc -> Doc
update msg doc =
    case msg of
        Inc ->
            { doc | counter = doc.counter + 1 }

        Dec ->
            { doc | counter = doc.counter - 1 }


view : Doc -> Html Msg
view doc =
    div []
        [ button [ onClick Inc ] [ text "+" ]
        , text <| String.fromInt doc.counter
        , button [ onClick Dec ] [ text "-" ]
        ]
    """
