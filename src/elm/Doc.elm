module Doc exposing (Doc, RawDoc, Text, Value(..), asString, debug, decode, decoder, empty, encode, encodeValue, get, rawEmpty, valueAsString, valueDecoder)

import Dict exposing (Dict)
import Json.Decode as D
import Json.Encode as E


type alias Text =
    List String


type Value
    = String String
    | Float Float
    | Bool Bool
    | Dict (Dict String Value)
    | List (List Value)
    | Text Text
    | Null


type alias Doc =
    Dict String Value


type alias RawDoc =
    D.Value


empty : Doc
empty =
    Dict.empty


rawEmpty : RawDoc
rawEmpty =
    E.null


get : String -> Doc -> Value
get k =
    Dict.get k >> Maybe.withDefault Null



-- at : List String -> Doc -> Value
-- at keys doc =
--     Dict.get k >> Maybe.withDefault Null
-- atV : List String -> Value -> Value
-- atV path val =
--     case path of
--         [] ->
--             val
--         k :: rest ->
--     case val of
--         Dict dict ->
-- Debug


debug : Doc -> Doc
debug doc =
    Debug.log (asString doc) doc


asString : Doc -> String
asString doc =
    Dict doc |> valueAsString


valueAsString : Value -> String
valueAsString val =
    case val of
        String x ->
            x |> Debug.toString

        Float x ->
            x |> Debug.toString

        Bool x ->
            x |> Debug.toString

        Dict x ->
            x |> Debug.toString

        List x ->
            x |> Debug.toString

        Text x ->
            x |> Debug.toString

        Null ->
            "Null"



-- Encoders


encode : Doc -> RawDoc
encode doc =
    Dict doc |> encodeValue


encodeValue : Value -> E.Value
encodeValue val =
    case val of
        String x ->
            x |> E.string

        Float x ->
            x |> E.float

        Bool x ->
            x |> E.bool

        Dict x ->
            x |> E.dict identity encodeValue

        List x ->
            x |> E.list encodeValue

        Text x ->
            x |> E.list E.string

        Null ->
            E.null



-- Decoders


decode : RawDoc -> Doc
decode =
    D.decodeValue decoder >> Result.withDefault empty


decoder : D.Decoder Doc
decoder =
    D.dict valueDecoder


valueDecoder : D.Decoder Value
valueDecoder =
    D.oneOf
        [ D.string |> D.map String
        , D.float |> D.map Float
        , D.bool |> D.map Bool
        , D.lazy (\_ -> D.dict valueDecoder |> D.map Dict)
        , D.lazy (\_ -> D.list valueDecoder |> D.map List)
        , D.list D.string |> D.map Text
        , D.succeed Null
        ]
