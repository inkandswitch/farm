module Link exposing (create, getId)

import UriParser exposing (Uri, parse)


create : String -> String
create id =
    "hypermerge:/" ++ id


getId : String -> Result String String
getId str =
    parse str
        |> Result.mapError (always "Parsing failed")
        |> Result.andThen checkScheme
        |> Result.andThen extractId
        |> Result.andThen checkId


extractId : Uri -> Result String String
extractId =
    .path
        >> List.head
        >> Result.fromMaybe "link has no id"


checkScheme : Uri -> Result String Uri
checkScheme uri =
    case uri.scheme of
        "hypermerge" ->
            Ok uri

        _ ->
            Err "scheme must be 'hypermerge'"


checkId : String -> Result String String
checkId str =
    if String.length str < 10 then
        Err "not a valid ID"

    else
        Ok str
