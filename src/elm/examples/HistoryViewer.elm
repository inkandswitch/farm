module HistoryViewer exposing (Doc, Msg, State, gizmo)

import Clipboard
import Colors
import Config
import Css exposing (..)
import FarmUrl
import Gizmo exposing (Flags, Model)
import History exposing (History)
import Html.Styled as Html exposing (..)
import Html.Styled.Attributes exposing (css, value)
import Html.Styled.Events exposing (..)
import IO
import Json.Decode as D
import Json.Encode as E
import Link
import Navigation


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
    { history : History String
    }


init : Flags -> ( State, Doc, Cmd Msg )
init flags =
    ( {}
    , { history = History.empty
      }
    , Cmd.none
    )


{-| Message type for modifying State and Doc inside update
-}
type Msg
    = NavigateTo String


update : Msg -> Model State Doc -> ( State, Doc, Cmd Msg )
update msg ({ flags, state, doc } as model) =
    case msg of
        NavigateTo url ->
            ( state
            , doc
            , Debug.log "navigate" Gizmo.emit "navigate" (E.string url)
            )


view : Model State Doc -> Html Msg
view ({ doc, state } as model) =
    div
        [ css
            [ boxShadow5 zero (px 2) (px 8) zero (rgba 0 0 0 0.12)
            , border3 (px 1) solid (hex "ddd")
            , borderRadius (px 5)
            , maxHeight (px 400)
            , width (pct 100)
            , backgroundColor (hex "#fff")
            , overflowX hidden
            , overflowY auto
            , fontFamilies [ "system-ui" ]
            ]
        ]
        [ div
            []
            (List.map viewHistoryItem doc.history.seen)
        ]


viewHistoryItem : String -> Html Msg
viewHistoryItem url =
    div
        [ onStopPropagationClick (NavigateTo url)
        , css
            [ padding (px 15)
            , fontSize (Css.em 0.8)
            , textOverflow ellipsis
            , property "white-space" "nowrap"
            , overflow hidden
            , cursor pointer
            , textAlign center
            , borderBottom3 (px 1) solid (hex "ddd")
            , hover
                [ backgroundColor (hex "#f0f0f0")
                ]
            , lastChild
                [ borderBottom zero
                ]
            ]
        ]
        [ case FarmUrl.parse url of
            Ok { code, data } ->
                viewProperty "title" data

            Err err ->
                Html.text err
        ]


viewProperty : String -> String -> Html Msg
viewProperty prop url =
    Html.fromUnstyled <|
        Gizmo.renderWith [ Gizmo.attr "data-prop" prop ] Config.property url


onStopPropagationClick : Msg -> Html.Attribute Msg
onStopPropagationClick msg =
    stopPropagationOn "click" (D.succeed ( msg, True ))


subscriptions : Model State Doc -> Sub Msg
subscriptions model =
    Sub.none
