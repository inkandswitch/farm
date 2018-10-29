port module Receive exposing (fromServer)


port fromServer : (( String, String ) -> msg) -> Sub msg
