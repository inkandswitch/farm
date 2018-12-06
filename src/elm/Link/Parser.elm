module Link.Parser exposing (getId, id, key, link, parse, path, pathHelp)

import Link exposing (Link)
import Parser exposing (..)



-- hypermerge:/abc123/Source.elm


getId : String -> Maybe String
getId =
    parse
        >> Result.toMaybe
        >> Maybe.map .id


parse : String -> Result (List DeadEnd) Link
parse =
    run link


link : Parser Link
link =
    succeed Link
        |= getChompedString (keyword "hypermerge")
        |. symbol ":"
        |. symbol "/"
        |= id
        |= path


id : Parser String
id =
    succeed ()
        |. chompUntilEndOr "/"
        |> getChompedString
        |> andThen checkId


checkId : String -> Parser String
checkId str =
    if String.length str < 10 then
        problem "not a valid ID"

    else
        succeed str


path : Parser (List String)
path =
    loop [] pathHelp


pathHelp : List String -> Parser (Step (List String) (List String))
pathHelp revPath =
    oneOf
        [ succeed (\k -> Loop (k :: revPath))
            |. symbol "/"
            |= key
        , succeed ()
            |> map (\_ -> Done (List.reverse revPath))
        ]


key : Parser String
key =
    getChompedString <|
        succeed ()
            |. chompUntilEndOr "/"
