module EmptyGizmo exposing (Doc, Msg, State, gizmo)

import Gizmo exposing (Flags, Model)
import Html exposing (Html, button, div, form, input, text)
import Html.Attributes exposing (style, value)
import Html.Events exposing (onInput, onSubmit)
import Repo exposing (Ref, Url)
import Json.Encode as E


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
    { dataUrl : String
    }


{-| Document state
-}
type alias Doc =
    {}


init : Flags -> ( State, Doc, Cmd Msg )
init flags =
    ( { dataUrl = "" }
    , {}
    , Cmd.none
    )


{-| Message type for modifying State and Doc inside update
-}
type Msg
    = Change String
    | Open


update : Msg -> Model State Doc -> ( State, Doc, Cmd Msg )
update msg { state, doc } =
    case Debug.log "msg" msg of
        Open ->
            ( state, doc, Gizmo.emit "OpenDocument" (E.string state.dataUrl) )

        Change str ->
            ( { state | dataUrl = str }, doc, Cmd.none )


view : Model State Doc -> Html Msg
view { doc, state } =
    div [ style "padding" "10px" ]
        [ text "This window has no data url."
        , form [ onSubmit Open ]
            [ div [] [ text "Enter a data url to open it:" ]
            , input [ onInput Change, value state.dataUrl ] []
            , button [] [ text "Open" ]
            ]
        ]


subscriptions : Model State Doc -> Sub Msg
subscriptions model =
    Sub.none
