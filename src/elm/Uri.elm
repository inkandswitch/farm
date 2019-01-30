module Uri exposing (create, parse, resolve)

import UriParser exposing (Uri)


parse : String -> Result String Uri
parse =
    UriParser.parse


{-| Not quite accurate. We should be parsing both arguments
and returning a Result.
-}
resolve : String -> String -> String
resolve base other =
    case parse other of
        Ok _ ->
            other

        Err _ ->
            base ++ "/" ++ other


create : Uri -> String
create uri =
    case uri.authority of
        Just authority ->
            uri.scheme ++ "//" ++ authority ++ "/" ++ (uri.path |> String.join "/")

        Nothing ->
            uri.scheme ++ "/" ++ (uri.path |> String.join "/")
