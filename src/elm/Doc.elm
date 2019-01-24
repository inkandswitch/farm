module Doc exposing (Doc, RawDoc, asString, debug, decode, decoder, empty, encode, get, rawEmpty)

import Dict exposing (Dict)
import Json.Decode as D
import Json.Encode as E
import Value exposing (Value)


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
    Dict.get k >> Maybe.withDefault Value.Null
    

rawGet : String -> RawDoc -> Value
rawGet k =
    decode >> get k



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
    Value.Dict doc |> Value.toString


encode : Doc -> RawDoc
encode doc =
    Value.Dict doc |> Value.encode


decode : RawDoc -> Doc
decode =
    D.decodeValue decoder >> Result.withDefault empty


decoder : D.Decoder Doc
decoder =
    D.dict Value.decoder