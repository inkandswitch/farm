port module Receive exposing (fromServer)

import Json.Decode as Json


port fromServer : (( String, String ) -> msg) -> Sub msg


port fromRepo : (Json.Value -> msg) -> Sub msg
