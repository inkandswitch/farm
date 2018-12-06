module Example exposing (Doc, Msg, State, gizmo)

import Gizmo exposing (Model)
import Html exposing (Html, text)
import Html.Attributes as Attr exposing (style)
import Html.Events exposing (onClick)


gizmo : Gizmo.Program State Doc Msg
gizmo =
    Gizmo.sandbox
        { init = init
        , update = update
        , view = view
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


update : Msg -> Model State Doc -> ( State, Doc )
update msg { state, doc } =
    case msg of
        NoOp ->
            ( state, doc )


view : Model State Doc -> Html Msg
view { state, doc } =
    Html.div []
        [ Html.div [ style "color" "red" ]
            [ text "This is an example widget. Change me!"
            ]
        ]
