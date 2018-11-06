module Automerge exposing (Doc(..))


type Doc schema
    = Doc String schema


create : schema -> Doc schema
create defaults =
    Doc String defaults
