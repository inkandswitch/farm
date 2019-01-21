module GizmoTemplate exposing (Doc, Msg, State, gizmo)

import Css exposing (..)
import Gizmo exposing (Flags, Model)
import Html.Styled as Html exposing (..)
import Html.Styled.Attributes exposing (css, src)


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
    {}


{-| Document state
-}
type alias Doc =
    { src : String
    }


init : Flags -> ( State, Doc, Cmd Msg )
init flags =
    ( {}
    , { src = ""
      }
    , Cmd.none
    )


{-| Message type for modifying State and Doc inside update
-}
type Msg
    = NoOp


update : Msg -> Model State Doc -> ( State, Doc, Cmd Msg )
update msg { state, doc } =
    case msg of
        NoOp ->
            ( state
            , doc
            , Cmd.none
            )


view : Model State Doc -> Html Msg
view { doc } =
    img
        [ src doc.src
        , css
            [ property "object-fit" "cover"
            , position absolute
            , top zero
            , left zero
            , width (pct 100)
            , height (pct 100)
            , pointerEvents none
            ]
        ]
        []


subscriptions : Model State Doc -> Sub Msg
subscriptions model =
    Sub.none
