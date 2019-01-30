module Draggable exposing (draggable)

import Html.Styled as Html exposing (..)
import Html.Styled.Attributes as Attrs


draggable : (String, String) -> List (Html msg) -> Html msg
draggable (datatype, data) children =
    Html.node "farm-draggable"
        [ Attrs.draggable "true"
        , Attrs.attribute "dragdata" data
        , Attrs.attribute "dragtype" datatype
        ]
        children