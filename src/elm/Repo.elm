port module Repo exposing (Model, Msg(..), OutMsg(..), create, repoIn, repoOut)

import Json.Decode as D
import Json.Encode as E
import Result
import Task


type alias Model msg =
    { createQ : List (List String -> msg)
    }


create : Int -> (List String -> msg) -> Cmd msg
create n mkMsg =
    Create n |> send


type Msg
    = Created (List String)
    | Error String


update : Msg -> Model msg -> ( Model msg, Cmd msg )
update msg model =
    case msg of
        Created ids ->
            case model.createQ of
                mkMsg :: createQ ->
                    ( { model | createQ = createQ }, mkMsg ids |> Task.succeed |> Task.perform identity )



-- Outgoing Messages


port repoOut : E.Value -> Cmd msg


type OutMsg
    = Create Int -- Number of docs to create


encodeOut : OutMsg -> E.Value
encodeOut msg =
    case msg of
        Create n ->
            E.object
                [ ( "t", E.string "Create" )
                , ( "n", E.int n )
                ]


send : OutMsg -> Cmd msg
send =
    encodeOut >> repoOut



-- Incoming Messages


port repoIn : (D.Value -> msg) -> Sub msg


msgDecoder : D.Decoder Msg
msgDecoder =
    D.field "t" D.string
        |> D.andThen
            (\t ->
                case t of
                    "Created" ->
                        D.map Created
                            (D.field "ids" (D.list D.string))

                    _ ->
                        D.fail ("'" ++ t ++ "' is not a valid Repo.Msg type.")
            )


decodeMsg : D.Value -> Msg
decodeMsg val =
    case D.decodeValue msgDecoder val of
        Err err ->
            Error (D.errorToString err)

        Ok msg ->
            msg


incoming : Sub Msg
incoming =
    repoIn decodeMsg
