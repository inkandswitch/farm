module Counter exposing (Doc, Msg, State, gizmo)

import Gizmo exposing (Model)
import Html exposing (Html, button, div, text)
import Html.Events exposing (onClick)


{-| Ephemeral state not saved to the doc
-}
type alias State =
    {}


{-| Document state
-}
type alias Doc =
    { counter : Int
    }


{-| Message type for modifying State and Doc inside update
-}
type Msg
    = Inc


init : ( State, Doc )
init =
    ( {}
    , { counter = 0
      }
    )


update : Msg -> Model State Doc -> ( State, Doc )
update msg { doc } =
    case msg of
        Inc ->
            ( {}, { doc | counter = doc.counter + 1 } )


view : Model State Doc -> Html Msg
view { doc } =
    div []
        [ button [ onClick Inc ] [ text <| String.fromInt doc.counter ]
        ]


gizmo : Gizmo.Program State Doc Msg
gizmo =
    Gizmo.sandbox
        { init = init
        , update = update
        , view = view
        }

Gizmo.create Created
