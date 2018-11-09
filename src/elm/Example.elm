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


main : Plugin.Program () Doc Msg
main =
    Plugin.element
        { init = init
        , update = update
        , view = view
        , input = input
        , output = output
        }


init : ( (), Doc )
init =
    ( ()
    , { counter = 0
      }
    )


update : Msg -> Plugin.Model () Doc -> ( (), Doc )
update msg { state, doc } =
    case msg of
        Inc ->
            ( state, { doc | counter = doc.counter + 1 } )

        Dec ->
            ( state, { doc | counter = doc.counter - 1 } )


view : Plugin.Model () Doc -> Html Msg
view { docId, sourceId, doc } =
    div []
        [ button [ onClick Inc ] [ text "+" ]
        , text <| String.fromInt doc.counter
        , button [ onClick Dec ] [ text "-" ]
        , Html.hr [] []
        , Html.pre []
            [ Html.b [] [ text "docId: " ]
            , text docId
            ]
        , Html.pre []
            [ Html.b [] [ text "sourceId: " ]
            , text sourceId
            ]
        ]
