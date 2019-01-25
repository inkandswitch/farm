module LiveEdit exposing (Doc, Msg, State, gizmo)

import Gizmo exposing (Flags, Model)
import Html.Styled as Html exposing (..)
import Html.Styled.Attributes exposing (css, value, id)
import Html.Styled.Events exposing (onInput)
import Css exposing (..)
import Json.Encode as E
import Json.Decode as D
import Dict
import Value exposing (Value)
import Doc


attr : String
attr =
    "data-prop"


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
    {
    }


{-| Document state
-}
type alias Doc =
    E.Value


init : Flags -> ( State, Doc, Cmd Msg )
init flags =
    ( { }
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
            case Dict.get attr flags.all of
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
    case Dict.get attr flags.all of
        Just prop ->
            let
                val = Value.toString <| getProp prop doc
                idVal = Maybe.withDefault flags.data <| Dict.get "data-id" flags.all
            in
                input
                    [ value val
                    , onInput SetValue
                    , id idVal
                    , css
                        [ all inherit
                        , display initial
                        ]
                    ]
                    []
        Nothing ->
            Html.text <| "Must define a " ++ attr ++ " attribute."

getProp : String -> Doc -> Value
getProp prop doc =
    Result.withDefault Value.Null
        <| D.decodeValue (propDecoder prop) doc


propDecoder : String -> D.Decoder Value
propDecoder prop =
    D.field prop Value.decoder


subscriptions : Model State Doc -> Sub Msg
subscriptions model =
    Sub.none