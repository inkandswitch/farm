module UriParser exposing (Uri, parse)

import Parser exposing (..)



-- hypermerge:/abc123/Source.elm


type alias Uri =
    { scheme : String
    , authority : Maybe String
    , path : List String
    }


parse : String -> Result String Uri
parse =
    run uri >> Result.mapError deadEndsToString


uri : Parser Uri
uri =
    succeed Uri
        |= getChompedString (chompUntil ":")
        |. symbol ":"
        |= authority
        |= path


authority : Parser (Maybe String)
authority =
    oneOf
        [ succeed Just
            |. symbol "//"
            |= getChompedString (chompUntilEndOr "/")
        , succeed Nothing
        ]


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


deadEndsToString : List DeadEnd -> String
deadEndsToString =
    deadEndsToStrings >> String.join "\n"


deadEndsToStrings : List DeadEnd -> List String
deadEndsToStrings =
    List.map deadEndToString


deadEndToString : DeadEnd -> String
deadEndToString dead =
    case dead.problem of
        Expecting str ->
            "Expecting '" ++ str ++ "'"

        ExpectingSymbol str ->
            "Expecting symbol: " ++ str

        ExpectingKeyword str ->
            "Expecting a keyword: " ++ str

        ExpectingEnd ->
            "Expecting the end of input"

        UnexpectedChar ->
            "Unexpected character in input"

        Problem str ->
            str

        _ ->
            "Parsing error"
