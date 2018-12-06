module UriParser exposing (Uri, parse)

import Parser exposing (..)



-- hypermerge:/abc123/Source.elm


type alias Uri =
    { scheme : String
    , authority : Maybe String
    , path : List String
    }


parse : String -> Result (List DeadEnd) Uri
parse =
    run uri


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
