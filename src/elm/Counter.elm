module Counter exposing (main)

import Gizmo
import Html exposing (Html, button, div, text)
import Html.Events exposing (onClick)


{-| Document state
-}
type alias Doc =
    { counter : Int
    }


{-| Message type for modifying State and Doc inside update
-}
type Msg
    = Inc


init : Doc
init =
    { counter = 0
    }


update : Msg -> Doc -> Doc
update msg doc =
    case msg of
        Inc ->
            { doc | counter = doc.counter + 1 }


subscriptions : Model State Doc -> Sub Msg
subscriptions model =
    Sub.none


view : Doc -> Html Msg
view doc =
    div []
        [ button [ onClick Inc ] [ text <| String.fromInt doc.counter ]
        ]


main : Gizmo.Program () doc msg
main =
    Gizmo.sandbox
        { init = init
        , update = update
        , view = view
        }
