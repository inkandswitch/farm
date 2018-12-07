port module IO exposing (log, logValue, output)

import Json.Encode as Json exposing (Value)


port output : List Value -> Cmd msg


port input : (List String -> msg) -> Sub msg


log : String -> Cmd msg
log =
    Json.string >> logValue


logValue : Value -> Cmd msg
logValue val =
    output [ val ]
