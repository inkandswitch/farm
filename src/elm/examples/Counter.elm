module Counter exposing (Doc, Msg, State, gizmo)

import Css exposing (..)
import Gizmo exposing (Model)
import Html.Styled exposing (..)
import Html.Styled.Attributes exposing (..)
import Html.Styled.Events exposing (..)


gizmo : Gizmo.Program State Doc Msg
gizmo =
    Gizmo.sandbox
        { init = init
        , update = update
        , view = view
        }


{-| Ephemeral state not saved to the doc
-}
type alias State =
    {}


{-| Document state
-}
type alias Doc =
    { counter : Int
    }


init : ( State, Doc )
init =
    ( {}
    , { counter = 0
      }
    )


{-| Message type for modifying State and Doc inside update
-}
type Msg
    = Inc


update : Msg -> Model State Doc -> ( State, Doc )
update msg { state, doc } =
    case msg of
        Inc ->
            ( state, { doc | counter = doc.counter + 1 } )


view : Model State Doc -> Html Msg
view { state, doc } =
    div []
        [ button [ onClick Inc ] [ text (String.fromInt doc.counter) ]
        ]
