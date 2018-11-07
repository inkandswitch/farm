port module Example exposing (main)

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
