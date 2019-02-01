module VsCode exposing (link, open)

import Gizmo


link : String -> String
link url =
    "vscode://inkandswitch.hypermerge/" ++ url


open : String -> Cmd msg
open url =
    Gizmo.command ( "OpenExternal", link url )
