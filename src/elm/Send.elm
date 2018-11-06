port module Send exposing (toRepo, toServer)

import Json.Encode as Json


port toServer : ( String, String ) -> Cmd msg


port toRepo : Json.Value -> Cmd msg
