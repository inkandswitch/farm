module Extra.Array exposing (remove, update)

import Array exposing (..)


update : Int -> (a -> a) -> Array a -> Array a
update i fn arr =
    case get i arr of
        Nothing ->
            arr

        Just a ->
            set i (fn a) arr


remove : Int -> Array a -> Array a
remove n arr =
    append
        (slice 0 n arr)
        (slice (n + 1) (Array.length arr) arr)
