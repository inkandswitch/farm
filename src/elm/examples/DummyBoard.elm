module DummyBoard exposing (Doc, Msg, State, gizmo)

import Css exposing (..)
import Gizmo exposing (Flags, Model)
import Html.Styled as Html exposing (..)
import Html.Styled.Attributes exposing (css)


gizmo : Gizmo.Program State Doc Msg
gizmo =
    Gizmo.element
        { init = init
        , update = update
        , view = view
        , subscriptions = subscriptions
        }


{-| Ephemeral state not saved to the doc
-}
type alias State =
    {}


{-| Document state
-}
type alias Doc =
    { content : String
    }


init : Flags -> ( State, Doc, Cmd Msg )
init flags =
    ( {}
    , { content = "" }
    , Cmd.none
    )


{-| Message type for modifying State and Doc inside update
-}
type Msg
    = NoOp


update : Msg -> Model State Doc -> ( State, Doc, Cmd Msg )
update msg { state, doc } =
    case msg of
        NoOp ->
            ( state
            , doc
            , Cmd.none
            )


view : Model State Doc -> Html Msg
view { doc } =
    div
        [ css
            [ backgroundColor (hex "aaa")
            , height (pct 100)
            , width (pct 100)
            , displayFlex
            , alignItems center
            , justifyContent center
            ]
        ]
        [ h1
            []
            [ text doc.content
            ]
        ]


subscriptions : Model State Doc -> Sub Msg
subscriptions model =
    Sub.none
