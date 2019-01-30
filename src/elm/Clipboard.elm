module Clipboard exposing (copy)

{-| This module allows the copying of a <String> to the user's
clipboard.


# Writing to clipboard

@docs copy

-}

import Gizmo


{-| Copy the given String to the user's clipboard.
-}
copy : String -> Cmd msg
copy str =
    Gizmo.command ( "Copy", str )
