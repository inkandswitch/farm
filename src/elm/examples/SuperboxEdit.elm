module SuperboxEdit exposing (Doc, Msg, State, gizmo)

import Colors
import Css exposing (..)
import Gizmo exposing (Flags, Model)
import Html.Styled as Html exposing (..)
import Html.Styled.Attributes exposing (autofocus, css, value)
import Html.Styled.Events exposing (..)
import Json.Decode as D
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
    { title : Maybe String }


{-| Document state
-}
type alias Doc =
    { title : String }


init : Flags -> ( State, Doc, Cmd Msg )
init flags =
    ( { title = Nothing }
    , { title = "No title" }
    , Cmd.none
    )


{-| Message type for modifying State and Doc inside update
-}
type Msg
    = NoOp
    | SetTitle String
    | SaveTitle


update : Msg -> Model State Doc -> ( State, Doc, Cmd Msg )
update msg { state, doc } =
    case msg of
        NoOp ->
            ( state
            , doc
            , Cmd.none
            )

        SetTitle title ->
            ( { state | title = Just title }
            , doc
            , Cmd.none
            )

        SaveTitle ->
            case state.title of
                Just title ->
                    ( state
                    , { doc | title = title }
                    , Debug.log "Saving new title" Gizmo.emit "defaultmode" E.null
                    )

                Nothing ->
                    ( state
                    , doc
                    , Gizmo.emit "defaultmode" E.null
                    )


view : Model State Doc -> Html Msg
view { state, doc } =
    input
        [ autofocus True
        , onInput SetTitle
        , onEnter SaveTitle
        , value <| Maybe.withDefault doc.title state.title
        , css
            [ width (pct 100)
            , margin zero
            , border zero
            , padding zero
            , backgroundColor transparent
            , textAlign center
            , fontSize (Css.em 1)
            , color (hex Colors.blueBlack)
            ]
        ]
        []


onEnter : Msg -> Attribute Msg
onEnter msg =
    on "keypress" (D.andThen (enter msg) keyCode)


enter : msg -> Int -> D.Decoder msg
enter msg keycode =
    if keycode == 13 then
        D.succeed msg

    else
        D.fail "Not the enter key"


subscriptions : Model State Doc -> Sub Msg
subscriptions model =
    Sub.none
