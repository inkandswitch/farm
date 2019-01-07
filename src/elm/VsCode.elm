module VsCode exposing (link)


link : String -> String
link url =
    "vscode-insiders://inkandswitch.hypermerge/" ++ url
