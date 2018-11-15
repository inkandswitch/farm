port module Counter exposing (main)

import Html exposing (Html, button, div, text)
import Html.Events exposing (onClick)
import Plugin


{-| Internal state not persisted to a document
-}
type alias State =
    {}


{-| Document state
-}
type alias Doc =
    { counter : Int
    }


port output : Plugin.Out Doc -> Cmd msg


port input : (Plugin.In Doc -> msg) -> Sub msg


{-| Message type for modifying State and Doc inside update
-}
type Msg
    = Inc


main : Plugin.Program State Doc Msg
main =
    Plugin.element
        { init = init
        , update = update
        , view = view
        , input = input
        , output = output
        }


init : ( State, Doc )
init =
    ( {}
    , { counter = 0
      }
    )


update : Msg -> Plugin.Model State Doc -> ( State, Doc )
update msg { state, doc } =
    case msg of
        Inc ->
            ( state, { doc | counter = doc.counter + 1 } )


view : Plugin.Model State Doc -> Html Msg
view { doc } =
    div []
        [ button [ onClick Inc ] [ text <| String.fromInt doc.counter ]
        ]
