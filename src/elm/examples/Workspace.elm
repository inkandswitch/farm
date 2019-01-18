module Workspace exposing (Doc, Msg, State, gizmo)

import Gizmo exposing (Flags, Model)
import Html.Styled as Html exposing (..)
import Html.Styled.Attributes exposing (css)
import Html.Styled.Events exposing (..)
import Css exposing (..)
import IO
import Navigation
import RealmUrl
import Dict
import Json.Decode as D
import History exposing (History)


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
    { error : Maybe ( String, String )
    }


type alias Pair =
    { code : String
    , data : String
    }


{-| Document state
-}
type alias Doc =
    { history : History String
    }


init : Flags -> ( State, Doc, Cmd Msg )
init flags =
    ( { error = Nothing
      }
    , { history = History.empty
      }
    , Cmd.none
    )


{-| Message type for modifying State and Doc inside update
-}
type Msg
    = NavigateTo String
    | NavigateBack
    | NavigateForward


update : Msg -> Model State Doc -> ( State, Doc, Cmd Msg )
update msg { state, doc } =
    case msg of
        NavigateTo url ->
            case RealmUrl.parse url of
                Ok pair ->
                    ( state
                    , { doc | history = History.push url doc.history }
                    , IO.log <| "Navigating to " ++ url
                    )

                Err err ->
                    ( { state | error = Just ( url, err ) }
                    , doc
                    , IO.log <| "Could not navigate to " ++ url ++ ". " ++ err
                    )

        NavigateBack ->
            ( state
            , { doc | history = History.back doc.history }
            , IO.log <| "Navigating backwards"
            )

        NavigateForward ->
            ( state
            , { doc | history = History.forward doc.history }
            , IO.log <| "Navigating forwards"
            )


view : Model State Doc -> Html Msg
view ({ flags, doc, state } as model) =
    let
        navigationBar =
            Maybe.withDefault "" <| Dict.get "navigationBar" flags.config

        viewNavigationBar =
            Gizmo.render navigationBar >> Html.fromUnstyled
    in
    div
        [ onNavigateBack NavigateBack
        , onNavigateForward NavigateForward
        , onNavigateTo NavigateTo
        , css
            [ displayFlex
            , flexDirection column
            , height (vh 100)
            , width (vw 100)
            ]
        ]
        [ div
            [ css
                [ flexShrink (num 0)
                ]
            ]
            [ viewNavigationBar flags.data
            ]
        , viewContent model
        ]


onNavigateBack : msg -> Html.Attribute msg
onNavigateBack msg =
    on "navigateback" (D.succeed msg)


onNavigateForward : msg -> Html.Attribute msg
onNavigateForward msg =
    on "navigateforward" (D.succeed msg)


onNavigateTo : (String -> msg) -> Html.Attribute msg
onNavigateTo tagger =
    on "navigate" (D.map tagger detail)


detail : D.Decoder String
detail =
    D.at ["detail", "value"] D.string


viewContent : Model State Doc -> Html Msg
viewContent { doc, state } =
    div
        [ css
            [ flex (num 1)
            , position relative
            ]
        ]
        [ case state.error of
            Just ( url, err ) ->
                text <| "'" ++ url ++ "' could not be parsed: " ++ err

            Nothing ->
                case currentPair doc.history of
                    Ok ({ code, data } as pair) ->
                        let
                            url =
                                Debug.log "Viewing " <| RealmUrl.create pair
                        in
                        Html.fromUnstyled <| Gizmo.render code data

                    Err err ->
                        text "You haven't navigated to anything. Click a realm link."
        ]


subscriptions : Model State Doc -> Sub Msg
subscriptions model =
    Navigation.currentUrl NavigateTo


currentPair : History String -> Result String Pair
currentPair =
    History.current
    >> Result.fromMaybe "No current url"
    >> Result.andThen RealmUrl.parse