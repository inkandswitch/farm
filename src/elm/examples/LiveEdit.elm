module LiveEdit exposing (Doc, Msg, State, gizmo)

import Css exposing (..)
import Dict
import Doc
import Gizmo exposing (Flags, Model)
import Html.Styled as Html exposing (..)
import Html.Styled.Attributes exposing (css, id, placeholder, value)
import Html.Styled.Events exposing (onInput)
import Json.Decode as D
import Json.Encode as E
import Value exposing (Value)


propAttr : String
propAttr =
    "prop"


defaultAttr : String
defaultAttr =
    "default"


inputIdAttr : String
inputIdAttr =
    "input-id"


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
    E.Value


init : Flags -> ( State, Doc, Cmd Msg )
init flags =
    ( {}
    , E.null
    , Cmd.none
    )


{-| Message type for modifying State and Doc inside update
-}
type Msg
    = NoOp
    | SetValue String


update : Msg -> Model State Doc -> ( State, Doc, Cmd Msg )
update msg { flags, state, doc } =
    case msg of
        NoOp ->
            ( state
            , doc
            , Cmd.none
            )

        SetValue value ->
            case Dict.get propAttr flags.all of
                Just prop ->
                    ( state
                    , set prop (Value.String value) doc
                    , Cmd.none
                    )

                Nothing ->
                    ( state
                    , doc
                    , Cmd.none
                    )


set : String -> Value -> E.Value -> E.Value
set key value doc =
    doc
        |> Doc.decode
        |> Dict.insert key value
        |> Doc.encode


view : Model State Doc -> Html Msg
view { flags, doc } =
    let
        prop =
            Dict.get propAttr flags.all

        default =
            Maybe.withDefault "" <| Dict.get defaultAttr flags.all

        inputId =
            Maybe.withDefault flags.data <| Dict.get inputIdAttr flags.all
    in
    case prop of
        Just propName ->
            let
                val =
                    Value.toString <| getProp "" propName doc
            in
            input
                [ value val
                , onInput SetValue
                , placeholder default
                , id inputId
                , css
                    [ all inherit
                    , display initial
                    , width (pct 100)
                    , height (pct 100)
                    ]
                ]
                []

        Nothing ->
            Html.text <| "Must define a " ++ propAttr ++ " attribute."


getProp : String -> String -> Doc -> Value
getProp default prop doc =
    Result.withDefault (Value.String default) <|
        D.decodeValue (propDecoder prop) doc


propDecoder : String -> D.Decoder Value
propDecoder prop =
    D.field prop Value.decoder


subscriptions : Model State Doc -> Sub Msg
subscriptions model =
    Sub.none
