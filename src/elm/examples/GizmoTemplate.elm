module GizmoTemplate exposing (Doc, Msg, State, gizmo)

import Config
import Css exposing (..)
import Gizmo exposing (Flags, Model)
import Html.Styled as Html exposing (..)
import Html.Styled.Attributes as Attr exposing (css)


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
    {}


init : Flags -> ( State, Doc, Cmd Msg )
init flags =
    ( {} {- initial State -}
    , {} {- initial Doc -}
    , Cmd.none {- initial Cmd -}
    )


subscriptions : Model State Doc -> Sub Msg
subscriptions model =
    Sub.none


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
view { flags, doc, state } =
    div
        []
        [ h1 [] [ Gizmo.render Config.editableTitle flags.data ]
        , h2 [] [ text "Authors" ]
        , div []
            [ Gizmo.render Config.authors flags.code ]
        ]
