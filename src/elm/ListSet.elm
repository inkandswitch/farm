module ListSet exposing (ListSet, empty, insert, remove, member)

import List


type alias ListSet a =
    List a


empty : ListSet a
empty =
    []


insert : a -> ListSet a -> ListSet a
insert val list =
    if List.member val list then list else (val :: list)


remove : a -> ListSet a -> ListSet a
remove val =
    (/=) val |> List.filter


member : a -> ListSet a -> Bool
member =
    List.member