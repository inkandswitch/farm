port module IO exposing (log, output)


port output : List String -> Cmd msg


port input : (List String -> msg) -> Sub msg


log : String -> Cmd msg
log str =
    output [ str ]
