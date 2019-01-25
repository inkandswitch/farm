module Extra.List exposing (consTo, init, last)

import List exposing (..)


{-| Extract the last element of a list.
last [ 1, 2, 3 ]
--> Just 3
last []
--> Nothing
-}
last : List a -> Maybe a
last items =
    case items of
        [] ->
            Nothing

        [ x ] ->
            Just x

        _ :: rest ->
            last rest


{-| Return all elements of the list except the last one.
init [ 1, 2, 3 ]
--> Just [ 1, 2 ]
init []
--> Nothing
-}
init : List a -> Maybe (List a)
init items =
    case items of
        [] ->
            Nothing

        nonEmptyList ->
            nonEmptyList
                |> List.reverse
                |> List.tail
                |> Maybe.map List.reverse


consTo : List a -> a -> List a
consTo items item =
    item :: items
