module ShareUrl exposing (create, fromIds)

import Link.Parser exposing (getId)


create : { code : String, data : String } -> Maybe String
create { code, data } =
    Maybe.map2 fromIds
        (getId code)
        (getId data)


fromIds : String -> String -> String
fromIds codeId dataId =
    "realm://" ++ codeId ++ "/" ++ dataId
