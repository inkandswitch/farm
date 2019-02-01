port module Clipboard exposing
    ( copy
    , pasted
    )

{-| This module allows the copying of a <String> to the user's
clipboard.


# Writing to clipboard

@docs copy

-}

import Gizmo
import Json.Decode as D


port pasted : (D.Value -> msg) -> Sub msg


{-| Copy the given String to the user's clipboard.
-}
copy : String -> Cmd msg
copy str =
    Gizmo.command ( "Copy", str )
