port module Repo exposing (Ref, Url, clone, create, created)

import Json.Decode as D
import Json.Encode as E
import Result
import Task


type alias Url =
    String


type alias Ref =
    String


create : Ref -> Int -> Cmd msg
create ref n =
    send <| Create ref n


clone : Ref -> Url -> Cmd msg
clone ref url =
    send <| Clone ref url


port created : (( Ref, List Url ) -> msg) -> Sub msg



-- type alias Model msg =
--     { createQ : List (List String -> msg)
--     }
-- type Msg
--     = Created (List String)
--     | Error String


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
    = Create Ref Int -- String ref and number of docs to create
    | Clone Ref Url -- String ref and url to


encodeOut : OutMsg -> E.Value
encodeOut msg =
    case msg of
        Create ref n ->
            E.object
                [ ( "t", E.string "Create" )
                , ( "ref", E.string ref )
                , ( "n", E.int n )
                ]

        Clone ref url ->
            E.object
                [ ( "t", E.string "Clone" )
                , ( "ref", E.string ref )
                , ( "url", E.string url )
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
