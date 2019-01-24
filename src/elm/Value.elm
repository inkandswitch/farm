module Value exposing (Value(..), toString, encode, decoder)

import Dict exposing (Dict)
import Json.Encode as E
import Json.Decode as D

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


toString : Value -> String
toString val =
    case val of
        String x ->
            x

        Float x ->
            x |> String.fromFloat

        Bool x ->
            if x then "True" else "False"

        Dict x ->
            x |> Debug.toString

        List x ->
            x |> Debug.toString

        Text x ->
            x |> String.join ""

        Null ->
            "Null"

encode : Value -> E.Value
encode val =
    case val of
        String x ->
            x |> E.string

        Float x ->
            x |> E.float

        Bool x ->
            x |> E.bool

        Dict x ->
            x |> E.dict identity encode

        List x ->
            x |> E.list encode

        Text x ->
            x |> E.list E.string

        Null ->
            E.null


decoder : D.Decoder Value
decoder =
    D.oneOf
        [ D.string |> D.map String
        , D.float |> D.map Float
        , D.bool |> D.map Bool
        , D.lazy (\_ -> D.dict decoder |> D.map Dict)
        , D.lazy (\_ -> D.list decoder |> D.map List)
        , D.list D.string |> D.map Text
        , D.succeed Null
        ]