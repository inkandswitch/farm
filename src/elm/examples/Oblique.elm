module ObliqueStrategiesViewer exposing (Doc, Msg, State, gizmo)

import Css exposing (..)
import Gizmo exposing (Flags, Model)
import Html.Styled as Html exposing (..)
import Html.Styled.Attributes exposing (css)
import Html.Styled.Events exposing (..)
import Random


gizmo : Gizmo.Program State Doc Msg
gizmo =
    Gizmo.element
        { init = init
        , update = update
        , view = view
        , subscriptions = subscriptions
        }


{-| Ephemeral state not saved to the doc
-}
type alias State =
    { currentStrategy : Maybe String }


{-| Document state
-}
type alias Doc =
    { strategies : List String }


init : Flags -> ( State, Doc, Cmd Msg )
init flags =
    ( { currentStrategy = Nothing }
    , { strategies = [] }
    , Cmd.none
    )


{-| Message type for modifying State and Doc inside update
-}
type Msg
    = PickAgain
    | StrategyPicked String


update : Msg -> Model State Doc -> ( State, Doc, Cmd Msg )
update msg { state, doc } =
    case msg of
        PickAgain ->
            ( state
            , doc
            , Random.generate StrategyPicked (Random.uniform "" doc.strategies)
            )

        StrategyPicked strat ->
            ( { state | currentStrategy = Just strat }, doc, Cmd.none )


view : Model State Doc -> Html Msg
view { doc, state } =
    div
        [ css
            [ justifyContent center
            , fontSize (px 48)
            , displayFlex
            , alignItems center
            , height (pct 100)
            ]
        ]
        [ h1 [] [ text (Maybe.withDefault "pick one" state.currentStrategy) ]
        , button
            [ onClick PickAgain
            , css
                [ position absolute
                , right (px 5)
                , bottom (px 5)
                ]
            ]
            [ text "again" ]
        ]


subscriptions : Model State Doc -> Sub Msg
subscriptions model =
    Sub.none
