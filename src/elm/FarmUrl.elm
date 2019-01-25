module FarmUrl exposing (create, fromIds, parse, parseIds)

import Extra.List as List
import Link
import UriParser exposing (Uri)


create : { a | code : String, data : String } -> Result String String
create { code, data } =
    Result.map2 fromIds
        (Link.getId code)
        (Link.getId data)


parse : String -> Result String { code : String, data : String }
parse url =
    parseIds url
        |> Result.map
            (\{ codeId, dataId } ->
                { code = Link.create codeId
                , data = Link.create dataId
                }
            )


parseIds : String -> Result String { codeId : String, dataId : String }
parseIds url =
    UriParser.parse url
        |> Result.andThen checkScheme
        |> Result.andThen extractIds


extractIds : Uri -> Result String { codeId : String, dataId : String }
extractIds uri =
    Maybe.map2 idPair
        (extractCode uri)
        (List.last uri.path)
        |> Result.fromMaybe "An id is missing"


extractCode : Uri -> Maybe String
extractCode uri =
    uri.authority
        |> Maybe.map
            (List.consTo (List.init uri.path |> Maybe.withDefault []))
        |> Maybe.map (String.join "/")


idPair : String -> String -> { codeId : String, dataId : String }
idPair codeId dataId =
    { codeId = codeId, dataId = dataId }


fromIds : String -> String -> String
fromIds codeId dataId =
    "farm://" ++ codeId ++ "/" ++ dataId


checkScheme : Uri -> Result String Uri
checkScheme uri =
    case uri.scheme of
        "farm" ->
            Ok uri

        "realm" ->
            Ok uri

        _ ->
            Err "scheme must be 'farm'"
