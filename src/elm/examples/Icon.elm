module Icon exposing (Doc, Msg, State, gizmo)

import Css exposing (..)
import Dict
import Gizmo exposing (Flags, Model)
import Html.Styled as Html exposing (..)
import Html.Styled.Attributes exposing (css, placeholder, value)
import Html.Styled.Events exposing (..)
import Maybe


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
    { icon : Maybe String
    }


init : Flags -> ( State, Doc, Cmd Msg )
init flags =
    ( {}
    , { icon = Nothing }
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
view { flags, doc } =
    let
        defaultIconSrc =
            Maybe.withDefault "" (Dict.get "defaultIcon" flags.config)
    in
    div
        [ css
            [ width (pct 100)
            , height (pct 100)
            , backgroundImage (url <| Maybe.withDefault defaultIconSrc doc.icon)
            , backgroundPosition center
            , backgroundSize cover
            ]
        ]
        []


subscriptions : Model State Doc -> Sub Msg
subscriptions model =
    Sub.none
