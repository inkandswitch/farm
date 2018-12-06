module ShareUrl exposing (create, fromIds, parse, parseIds)

import Link
import UriParser exposing (Uri)


create : { code : String, data : String } -> Result String String
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
        |> Result.mapError (always "parsing failed")
        |> Result.andThen extractIds


extractIds : Uri -> Result String { codeId : String, dataId : String }
extractIds uri =
    Maybe.map2 idPair
        uri.authority
        (List.head uri.path)
        |> Result.fromMaybe "An id is missing"


idPair : String -> String -> { codeId : String, dataId : String }
idPair codeId dataId =
    { codeId = codeId, dataId = dataId }


fromIds : String -> String -> String
fromIds codeId dataId =
    "realm://" ++ codeId ++ "/" ++ dataId
