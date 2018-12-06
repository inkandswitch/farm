module Link exposing (Link)


type alias Link =
    { scheme : String
    , id : String
    , path : List String
    }
