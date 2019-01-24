module Property exposing (Doc, Msg, State, gizmo)

import Gizmo exposing (Flags, Model)
import Html.Styled as Html exposing (..)
import Html.Styled.Attributes exposing (css)
import Css exposing (..)
import Json.Encode as E
import Json.Decode as D
import Dict
import Value exposing (Value)


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
    case Dict.get attr flags.all of
        Just prop ->
            Html.text <| Value.toString <| getProp prop doc
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