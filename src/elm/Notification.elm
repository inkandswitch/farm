port module Notification exposing (Notification, onClick, send)


type alias Notification =
    { ref : String
    , title : String
    , body : String
    }


port sentNotifications : Notification -> Cmd msg


port notificationClicked : (String -> msg) -> Sub msg


send : Notification -> Cmd msg
send =
    sentNotifications


onClick : (String -> msg) -> Sub msg
onClick =
    notificationClicked
