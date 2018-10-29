port module Send exposing (toServer)


port toServer : ( String, String ) -> Cmd msg
