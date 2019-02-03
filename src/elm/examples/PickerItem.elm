module PickerItem exposing (Doc, Msg, State, gizmo)

import Config
import Css exposing (..)
import DateFormat.Relative exposing (relativeTime)
import Gizmo exposing (Flags, Model)
import Html.Styled as Html exposing (..)
import Html.Styled.Attributes exposing (css, placeholder, value)
import Html.Styled.Events exposing (..)
import String
import Task
import Time exposing (Posix)


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
    { currentTime : Maybe Posix }


{-| Document state
-}
type alias Doc =
    { title : Maybe String
    , authors : List String
    , lastEditTimestamp : Maybe Int
    }


init : Flags -> ( State, Doc, Cmd Msg )
init flags =
    ( { currentTime = Nothing
      }
    , { title = Nothing
      , authors = []
      , lastEditTimestamp = Nothing
      }
    , Task.perform ReceiveCurrentTime Time.now
    )


{-| Message type for modifying State and Doc inside update
-}
type Msg
    = NoOp
    | ReceiveCurrentTime Posix


update : Msg -> Model State Doc -> ( State, Doc, Cmd Msg )
update msg { state, doc } =
    case msg of
        NoOp ->
            ( state
            , doc
            , Cmd.none
            )

        ReceiveCurrentTime now ->
            ( { state | currentTime = Just now }
            , doc
            , Cmd.none
            )


view : Model State Doc -> Html Msg
view { flags, doc, state } =
    div
        [ css
            [ displayFlex
            , flexDirection column
            , padding (px 15)
            , fontSize (Css.em 0.9)
            , textOverflow ellipsis
            , property "white-space" "nowrap"
            , overflow hidden
            , cursor pointer
            , borderTop3 (px 1) solid (hex "ddd")
            , backgroundColor (hex "fff")
            , hover
                [ backgroundColor (hex "f5f5f5")
                ]
            ]
        ]
        [ div
            [ css
                [ flexGrow (int 1)
                , marginBottom (px 5)
                ]
            ]
            [ text <| Maybe.withDefault "No title" doc.title
            ]
        , div
            [ css
                [ displayFlex
                , flexDirection row
                , alignItems center
                ]
            ]
            [ div
                [ css
                    [ flexGrow (int 1)
                    ]
                ]
                [ Gizmo.render Config.authors flags.data
                ]
            , viewLastEdit state.currentTime doc.lastEditTimestamp
            ]
        ]


viewLastEdit : Maybe Posix -> Maybe Int -> Html Msg
viewLastEdit currentTime lastEditTimestamp =
    span
        [ css
            [ color (hex "aaa")
            , fontSize (Css.em 0.8)
            ]
        ]
        [ case ( currentTime, lastEditTimestamp ) of
            ( Just now, Just timestamp ) ->
                text <| relativeTime now <| Time.millisToPosix timestamp

            _ ->
                text ""
        ]


subscriptions : Model State Doc -> Sub Msg
subscriptions model =
    Sub.none
