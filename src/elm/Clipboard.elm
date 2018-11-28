module Clipboard exposing (copy)

import Gizmo


copy : String -> Cmd msg
copy str =
    Gizmo.command ( "Copy", str )
