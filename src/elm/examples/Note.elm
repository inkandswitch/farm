module Note exposing (Doc, Msg, State, gizmo)

import Css exposing (..)
import Gizmo exposing (Flags, Model)
import Html.Styled as Html exposing (..)
import Html.Styled.Attributes exposing (css, placeholder, value)
import Html.Styled.Events exposing (..)


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
    { title : String
    , body : String
    }


init : Flags -> ( State, Doc, Cmd Msg )
init flags =
    ( {}
    , { title = "", body = "" }
    , Cmd.none
    )


{-| Message type for modifying State and Doc inside update
-}
type Msg
    = NoOp
    | SetTitle String
    | SetBody String


update : Msg -> Model State Doc -> ( State, Doc, Cmd Msg )
update msg { state, doc } =
    case msg of
        NoOp ->
            ( state
            , doc
            , Cmd.none
            )

        SetTitle title ->
            ( state
            , { doc | title = title }
            , Cmd.none
            )

        SetBody body ->
            ( state
            , { doc | body = body }
            , Cmd.none
            )


textColor =
    hex "#333"


view : Model State Doc -> Html Msg
view { doc } =
    div
        [ css
            [ padding (px 5)
            , displayFlex
            , flexDirection column
            , height (pct 100)
            ]
        ]
        [ textarea
            [ css
                [ flexGrow (num 1)
                , border zero
                , width (pct 100)
                , fontSize (Css.em 1)
                , color textColor
                , resize none

                ]
            , onInput SetBody
            , value doc.body
            , placeholder "Your note here..."
            ]
            []
        ]


subscriptions : Model State Doc -> Sub Msg
subscriptions model =
    Sub.none
