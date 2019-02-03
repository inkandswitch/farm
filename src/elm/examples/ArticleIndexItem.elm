module ArticleIndexItem exposing (Doc, Msg, State, gizmo)

import Css exposing (..)
import Gizmo exposing (Flags, Model)
import Html.Styled as Html exposing (..)
import Html.Styled.Attributes exposing (css, placeholder, value)
import Html.Styled.Events as Events


hotPink =
    hex "#ff69b4"


darkerHotPink =
    hex "#ff1a8c"


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
    { title : String
    }


type alias GizmoUrl =
    String


init : Flags -> ( State, Doc, Cmd Msg )
init flags =
    ( {}
    , { title = "" }
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
            [ padding2 (px 2) (px 0)
            , color hotPink
            , cursor pointer
            , hover
                [ color darkerHotPink
                ]
            ]
        ]
        [ text doc.title
        ]


subscriptions : Model State Doc -> Sub Msg
subscriptions model =
    Sub.none
