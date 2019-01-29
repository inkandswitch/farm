module Property exposing (Doc, Msg, State, gizmo)

import Css exposing (..)
import Dict
import Gizmo exposing (Flags, Model)
import Html.Styled as Html exposing (..)
import Html.Styled.Attributes exposing (css)
import Json.Decode as D
import Json.Encode as E
import Value exposing (Value)


attr : String
attr =
    "prop"


defaultAttr : String
defaultAttr =
    "default"


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
    let
        prop =
            Dict.get attr flags.all

        default =
            Maybe.withDefault "" <| Dict.get defaultAttr flags.all
    in
    case prop of
        Just propName ->
            Html.text <| Value.toString <| getProp default propName doc

        Nothing ->
            Html.text <| "Must define a " ++ attr ++ " attribute."


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
