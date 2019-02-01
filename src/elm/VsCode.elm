module VsCode exposing (link)

import Gizmo


link : String -> String
link url =
    "vscode-insiders://inkandswitch.hypermerge/" ++ url


open : String -> Cmd msg
open url =
    Gizmo.command ( "OpenExternal", link url )
