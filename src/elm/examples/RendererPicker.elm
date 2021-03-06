module RendererPicker exposing (Doc, Msg, State, gizmo)

import Browser.Dom as Dom
import Clipboard
import Colors
import Config
import Css exposing (..)
import Gizmo exposing (Flags, Model)
import History exposing (History)
import Html.Styled as Html exposing (..)
import Html.Styled.Attributes exposing (css, id, placeholder, value)
import Html.Styled.Events exposing (..)
import IO
import Json.Decode as D
import Json.Encode as E
import Keyboard exposing (Combo(..))
import Link
import ListSet exposing (ListSet)
import Navigation
import RealmUrl
import Task


focusColor =
    "#f0f0f0"


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
    {}


{-| Document state
-}
type alias Doc =
    { codeDocs : ListSet String
    }


init : Flags -> ( State, Doc, Cmd Msg )
init flags =
    ( {}
    , { codeDocs = ListSet.empty
      }
    , Cmd.none
    )


{-| Message type for modifying State and Doc inside update
-}
type Msg
    = NoOp
    | Select String


update : Msg -> Model State Doc -> ( State, Doc, Cmd Msg )
update msg ({ flags, state, doc } as model) =
    case msg of
        NoOp ->
            ( state
            , doc
            , Cmd.none
            )

        Select val ->
            ( state
            , doc
            , Gizmo.emit "select" (E.string val)
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
            (List.map viewItem doc.codeDocs)
        ]


viewItem : String -> Html Msg
viewItem url =
    div
        [ onStopPropagationClick (Select url)
        ]
        [ Gizmo.render Config.pickerItem url
        ]


viewProperty : String -> String -> String -> Html Msg
viewProperty prop default url =
    let
        attrs =
            [ Gizmo.attr "prop" prop
            , Gizmo.attr "default" default
            ]
    in
    Gizmo.renderWith attrs Config.property url


onStopPropagationClick : Msg -> Html.Attribute Msg
onStopPropagationClick msg =
    stopPropagationOn "click" (D.succeed ( msg, True ))


subscriptions : Model State Doc -> Sub Msg
subscriptions { state } =
    Sub.none
