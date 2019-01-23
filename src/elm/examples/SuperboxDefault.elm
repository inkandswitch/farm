module SuperboxDefault exposing (Doc, Msg, State, gizmo)

import Gizmo exposing (Flags, Model)
import Html.Styled as Html exposing (..)
import Html.Styled.Attributes exposing (css)
import Html.Styled.Events exposing (..)
import Css exposing (..)
import Json.Encode as E


gizmo : Gizmo.Program State Doc Msg
gizmo =
    Gizmo.element
        { init = init
        , update = update
        , view = Html.toUnstyled << view
        , subscriptions = subscriptions
        }


{-| Ephemeral state not saved to the doc
-}
type alias State =
    {}


{-| Document state
-}
type alias Doc =
    { title : String }


init : Flags -> ( State, Doc, Cmd Msg )
init flags =
    ( {}
    , { title = "No title" }
    , Cmd.none
    )


{-| Message type for modifying State and Doc inside update
-}
type Msg
    = NoOp
    | RequestEditMode
    | RequestSearchMode


update : Msg -> Model State Doc -> ( State, Doc, Cmd Msg )
update msg { state, doc } =
    case msg of
        NoOp ->
            ( state
            , doc
            , Cmd.none
            )
        
        RequestEditMode ->
            ( state
            , doc
            , Gizmo.emit "editmode" E.null
            )

        RequestSearchMode ->
            ( state
            , doc
            , Gizmo.emit "searchmode" E.null
            )


view : Model State Doc -> Html Msg
view { doc } =
    div
        [ css
            [ width (pct 100)
            , position relative
            , alignItems center
            ]
        ]
        [ div
            [ onClick RequestSearchMode
            , css 
                [ width (pct 100)
                , cursor pointer
                , flexGrow (num 1)
                ]
            ]
            [ text <| emptyWithDefault "No title" doc.title
            ]
        , div
            [ onClick RequestEditMode
            , css
                [ cursor pointer
                , position absolute
                , right (px 0)
                , top (px 0)
                ]
            ]
            [ text "📝"
            ]
        ]

emptyWithDefault : String -> String -> String
emptyWithDefault default str =
    if str == "" then default else str


subscriptions : Model State Doc -> Sub Msg
subscriptions model =
    Sub.none