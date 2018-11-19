port module Repo exposing (create, created)

import Json.Decode as D
import Json.Encode as E
import Result
import Task


create : Int -> Cmd msg
create n =
    Create n |> send


port created : (List String -> msg) -> Sub msg



-- type alias Model msg =
--     { createQ : List (List String -> msg)
--     }


type Msg
    = Created (List String)
    | Error String


port repoOut : E.Value -> Cmd msg



-- update : Msg -> Model msg -> ( Model msg, Cmd msg )
-- update msg model =
--     case msg of
--         Created ids ->
--             case model.createQ of
--                 mkMsg :: createQ ->
--                     ( { model | createQ = createQ }, mkMsg ids |> Task.succeed |> Task.perform identity )
-- Outgoing Messages


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
-- port repoIn : (D.Value -> msg) -> Sub msg
-- msgDecoder : D.Decoder Msg
-- msgDecoder =
--     D.field "t" D.string
--         |> D.andThen typeDecoder
-- typeDecoder : String -> D.Decoder Msg
-- typeDecoder t =
--     case t of
--         "Created" ->
--             D.map Created
--                 (D.field "ids" (D.list D.string))
--         _ ->
--             D.fail "Not a valid Repo.Msg type."
-- decodeMsg : D.Value -> Msg
-- decodeMsg val =
--     case D.decodeValue msgDecoder val of
--         Err err ->
--             Error (D.errorToString err)
--         Ok msg ->
--             msg
-- incoming : Sub Msg
-- incoming =
--     repoIn decodeMsg
