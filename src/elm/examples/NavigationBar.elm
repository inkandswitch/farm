module Workspace exposing (Doc, Msg, State, gizmo)

import Clipboard
import Colors
import Css exposing (..)
import Gizmo exposing (Flags, Model)
import History exposing (History)
import Html.Styled as Html exposing (..)
import Html.Styled.Attributes exposing (css, value)
import Html.Styled.Events exposing (..)
import IO
import Json.Decode as D
import Json.Encode as E
import Navigation
import RealmUrl


inputBackgroundColor =
    "e9edf0"


gizmo : Gizmo.Program State Doc Msg
gizmo =
    Gizmo.element
        { init = init
        , update = update
        , view = Html.toUnstyled << view
        , subscriptions = subscriptions
        }


type alias Pair =
    { code : String
    , data : String
    }


{-| Ephemeral state not saved to the doc
-}
type alias State =
    { url : Maybe String }


{-| Document state
-}
type alias Doc =
    { history : History String
    }


init : Flags -> ( State, Doc, Cmd Msg )
init flags =
    ( { url = Nothing
      }
    , { history = History.empty
      }
    , Cmd.none
    )


{-| Message type for modifying State and Doc inside update
-}
type Msg
    = NavigateTo
    | NavigateBack
    | NavigateForward
    | SetUrl String
    | OnKeyPress Int
    | CopyLink


update : Msg -> Model State Doc -> ( State, Doc, Cmd Msg )
update msg ({ flags, state, doc } as model) =
    case msg of
        NavigateTo ->
            case stateUrlPair state.url of
                Ok url ->
                    ( { state | url = Nothing }
                    , doc
                    , Gizmo.emit "navigate" (E.string url)
                    )

                Err err ->
                    ( state
                    , doc
                    , IO.log <| "Could not navigate to " ++ err
                    )

        NavigateBack ->
            ( { state | url = Nothing }
            , doc
            , Gizmo.emit "navigateback" E.null
            )

        NavigateForward ->
            ( { state | url = Nothing }
            , doc
            , Gizmo.emit "navigateforward" E.null
            )

        SetUrl url ->
            ( { state | url = Just url }
            , doc
            , Cmd.none
            )

        OnKeyPress key ->
            case Debug.log "OnKeyPress" key of
                13 ->
                    update NavigateTo model

                _ ->
                    ( state
                    , doc
                    , Cmd.none
                    )

        CopyLink ->
            case RealmUrl.create { code = flags.code, data = flags.data } of
                Ok url ->
                    ( state
                    , doc
                    , Clipboard.copy url
                    )

                Err err ->
                    ( state
                    , doc
                    , IO.log <| "Could not copy current url: " ++ err
                    )


view : Model State Doc -> Html Msg
view ({ doc, state } as model) =
    div
        [ css
            [ displayFlex
            , padding (px 10)
            , alignItems center
            , boxShadow5 zero (px 2) (px 8) zero (rgba 0 0 0 0.12)
            , borderBottom3 (px 1) solid (hex "ddd")
            , height (px 40)
            ]
        ]
        [ viewNavButtons doc.history
        , viewInput (viewUrl state.url (History.current doc.history))
        , viewButton
            True
            CopyLink
            [ text "📋"
            ]
        ]


viewNavButtons : History String -> Html Msg
viewNavButtons history =
    div
        []
        [ viewButton
            (History.hasBack history)
            NavigateBack
            [ text "<"
            ]
        , viewButton
            (History.hasForward history)
            NavigateForward
            [ text ">"
            ]
        ]


activeButtonStyle =
    [ cursor pointer
    , color (hex Colors.hotPink)
    , hover
        [ color (hex Colors.darkerHotPink)
        ]
    ]


inactiveButtonStyle =
    [ cursor pointer
    , color (hex "aaa")
    ]


viewButton : Bool -> Msg -> List (Html Msg) -> Html Msg
viewButton isActive msg children =
    let
        style =
            if isActive then
                activeButtonStyle

            else
                inactiveButtonStyle
    in
    button
        [ onClick msg
        , css
            ([ flexShrink (num 0)
             , border zero
             , fontSize (Css.em 1)
             , marginRight (px 10)
             , padding (px 5)
             , fontWeight bold
             ]
                ++ style
            )
        ]
        children


viewInput : String -> Html Msg
viewInput url =
    input
        [ value <| url
        , onKeyDown OnKeyPress
        , onInput SetUrl
        , css
            [ flexGrow (num 1)
            , fontSize (Css.em 0.8)
            , padding (px 5)
            , borderRadius (px 5)
            , backgroundColor (hex inputBackgroundColor)
            , color (hex "777")
            , margin2 (px 0) auto
            , border zero
            , focus
                [ color (hex Colors.blueBlack)
                ]
            ]
        ]
        []

viewUrl : Maybe String -> Maybe String -> String
viewUrl stateUrl navUrl =
    case (stateUrl, navUrl) of
        (Nothing, Just url) ->
            url
        (Just url, _) ->
            url
        (_, _ ) ->
            ""

subscriptions : Model State Doc -> Sub Msg
subscriptions model =
    Sub.none


onKeyDown : (Int -> msg) -> Attribute msg
onKeyDown tagger =
    on "keydown" (D.map tagger keyCode)


stateUrlPair : Maybe String -> Result String String
stateUrlPair =
    Result.fromMaybe "No current url" >> Result.andThen RealmUrl.parse >> Result.andThen RealmUrl.create