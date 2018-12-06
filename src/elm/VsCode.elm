module VsCode exposing (link)


link : String -> String
link url =
    "vscode://inkandswitch.hypermergefs-vscode/" ++ url
