module HistoryViewer exposing (Doc, Msg, State, gizmo)

import Browser.Dom as Dom
import Clipboard
import Colors
import Config
import Css exposing (..)
import Gizmo exposing (Flags, Model)
import History exposing (History)
import Html.Styled as Html exposing (..)
import Html.Styled.Attributes exposing (css, id, placeholder, value)
import Html.Styled.Events exposing (..)
import IO
import Json.Decode as D
import Json.Encode as E
import Keyboard exposing (Combo(..))
import Link
import Navigation
import RealmUrl
import Task


focusColor =
    "#f0f0f0"


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
    { focus : Int
    , inputVal : Maybe String
    }


{-| Document state
-}
type alias Doc =
    { history : History String
    }


init : Flags -> ( State, Doc, Cmd Msg )
init flags =
    ( { focus = 0
      , inputVal = Nothing
      }
    , { history = History.empty
      }
    , Task.attempt (\_ -> NoOp) (Dom.focus "url-input")
    )


{-| Message type for modifying State and Doc inside update
-}
type Msg
    = NoOp
    | NavigateTo String
    | NavigateToFocused
    | SetFocus Int
    | SetVal String


update : Msg -> Model State Doc -> ( State, Doc, Cmd Msg )
update msg ({ flags, state, doc } as model) =
    case msg of
        NoOp ->
            ( state
            , doc
            , Cmd.none
            )

        NavigateTo url ->
            ( state
            , doc
            , Debug.log "navigate" Gizmo.emit "navigate" (E.string url)
            )

        NavigateToFocused ->
            case state.focus of
                0 ->
                    case state.inputVal of
                        Just url ->
                            update (NavigateTo url) model

                        Nothing ->
                            ( state
                            , doc
                            , Cmd.none
                            )

                _ ->
                    case atPosition (state.focus - 1) doc.history.seen of
                        Just url ->
                            update (NavigateTo url) model

                        Nothing ->
                            ( state
                            , doc
                            , Cmd.none
                            )

        SetFocus focus ->
            let
                clampedFocus =
                    clamp 0 (List.length doc.history.seen) focus
            in
            ( { state | focus = clampedFocus }
            , doc
            , case ( clampedFocus, state.focus ) of
                ( 0, 0 ) ->
                    Cmd.none

                ( _, 0 ) ->
                    Task.attempt (\_ -> NoOp) (Dom.blur "url-input")

                ( 0, _ ) ->
                    Task.attempt (\_ -> NoOp) (Dom.focus "url-input")

                _ ->
                    Cmd.none
            )

        SetVal val ->
            ( { state | inputVal = Just val }
            , doc
            , Cmd.none
            )


clamp : Int -> Int -> Int -> Int
clamp minimum maximum =
    min maximum >> max minimum


atPosition : Int -> List String -> Maybe String
atPosition pos list =
    list
        |> List.drop pos
        |> List.head


view : Model State Doc -> Html Msg
view ({ doc, state } as model) =
    div
        [ css
            [ boxShadow5 zero (px 2) (px 8) zero (rgba 0 0 0 0.12)
            , border3 (px 1) solid (hex "ddd")
            , borderRadius (px 5)
            , maxHeight (px 400)
            , width (pct 100)
            , backgroundColor (hex "#fff")
            , overflowX hidden
            , overflowY auto
            , fontFamilies [ "system-ui" ]
            ]
        ]
        [ div
            []
            (viewInput (state.focus == 0) state.inputVal :: List.indexedMap (viewHistoryItem state.focus) doc.history.seen)
        ]


focusedStyle =
    [ backgroundColor (hex "e5e5e5")
    ]


unfocusedStyle =
    [ backgroundColor (hex "fff")
    ]


viewInput : Bool -> Maybe String -> Html Msg
viewInput isFocused val =
    let
        url =
            Maybe.withDefault "" val

        style =
            if isFocused then
                focusedStyle

            else
                unfocusedStyle
    in
    input
        [ css
            [ all inherit
            , width (pct 100)
            , height (px 40)
            , fontSize (Css.em 1.1)
            , padding (px 15)
            ]
        , id "url-input"
        , placeholder "Enter a farm url"
        , value url
        , onInput SetVal
        , onFocus <| SetFocus 0
        , Keyboard.onPress Enter (NavigateTo url)
        , onStopPropagationClick NoOp
        ]
        []


viewHistoryItem : Int -> Int -> String -> Html Msg
viewHistoryItem focused index url =
    let
        style =
            if focused - 1 == index then
                focusedStyle

            else
                unfocusedStyle
    in
    div
        [ onStopPropagationClick (NavigateTo url)
        , css
            [ padding (px 15)
            , fontSize (Css.em 0.8)
            , textOverflow ellipsis
            , property "white-space" "nowrap"
            , overflow hidden
            , cursor pointer
            , borderTop3 (px 1) solid (hex "ddd")
            , hover
                [ backgroundColor (hex "f5f5f5")
                ]
            ]
        ]
        (case RealmUrl.parse url of
            Ok { code, data } ->
                [ viewDataTitle data
                , viewCodeTitle code
                ]

            Err err ->
                [ Html.text err
                ]
        )


viewDataTitle : String -> Html Msg
viewDataTitle url =
    viewProperty "title" url


viewCodeTitle : String -> Html Msg
viewCodeTitle url =
    span
        [ css
            [ color (hex "aaa")
            , marginLeft (px 5)
            ]
        ]
        [ viewProperty "title" url
        ]


viewProperty : String -> String -> Html Msg
viewProperty prop url =
    Html.fromUnstyled <|
        Gizmo.renderWith [ Gizmo.attr "data-prop" prop ] Config.property url


onStopPropagationClick : Msg -> Html.Attribute Msg
onStopPropagationClick msg =
    stopPropagationOn "click" (D.succeed ( msg, True ))


subscriptions : Model State Doc -> Sub Msg
subscriptions { state } =
    Sub.none



-- Keyboard.shortcuts
--     [ ( Enter,  NavigateToFocused )
--     , ( Down, SetFocus <| state.focus + 1 )
--     , ( Up, SetFocus <| state.focus - 1 )
--     ]
