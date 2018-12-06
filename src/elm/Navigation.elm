port module Navigation exposing (currentUrl)


port navigateToUrl : String -> Cmd msg


port navigatedUrls : (String -> msg) -> Sub msg


currentUrl : (String -> msg) -> Sub msg
currentUrl =
    navigatedUrls
