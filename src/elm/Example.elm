port module Example exposing (main)

import Html exposing (Html, text)
import Html.Attributes as Attr exposing (style)
import Html.Events exposing (onClick)
import Plugin


port output : Plugin.Out Doc -> Cmd msg


port input : (Plugin.In Doc -> msg) -> Sub msg


main : Plugin.Program State Doc Msg
main =
    Plugin.element
        { init = init
        , update = update
        , view = view
        , input = input
        , output = output
        }


{-| Internal state not persisted to a document
-}
type alias State =
    {}


{-| Document state
-}
type alias Doc =
    {}


init : ( State, Doc )
init =
    ( {}
    , {}
    )


{-| Message type for modifying State and Doc inside update
-}
type Msg
    = NoOp


update : Msg -> Plugin.Model State Doc -> ( State, Doc )
update msg { state, doc } =
    case msg of
        NoOp ->
            ( state, doc )


view : Plugin.Model State Doc -> Html Msg
view { state, doc } =
    Html.div []
        [ Html.div [ style "color" "red" ]
            [ text "This is an example widget. Change me!"
            ]
        ]
