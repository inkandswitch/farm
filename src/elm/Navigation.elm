port module Navigation exposing (navigateToUrl, currentUrl)


port navigateToUrl : String -> Cmd msg


port navigatedUrls : (String -> msg) -> Sub msg


currentUrl : (String -> msg) -> Sub msg
currentUrl =
    navigatedUrls