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
    { history : List Pair
    }


init : Flags -> ( State, Doc, Cmd Msg )
init flags =
    ( { error = Nothing
      }
    , { history = []
      }
    , Cmd.none
    )


{-| Message type for modifying State and Doc inside update
-}
type Msg
    = NavigateTo String
    | NavigateBack


update : Msg -> Model State Doc -> ( State, Doc, Cmd Msg )
update msg { state, doc } =
    case msg of
        NavigateTo url ->
            case Debug.log "navigateToUrl" RealmUrl.parse url of
                Ok pair ->
                    ( state
                    , { doc | history = pair :: doc.history }
                    , IO.log <| "Navigating to " ++ url
                    )

                Err err ->
                    ( { state | error = Just ( url, err ) }
                    , doc
                    , IO.log <| "Could not navigate to " ++ url ++ ". " ++ err
                    )

        NavigateBack ->
            ( state
            , { doc | history = List.tail doc.history |> Maybe.withDefault [] }
            , IO.log <| "Navigating backwards"
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
            ]
        ]
        [ case state.error of
            Just ( url, err ) ->
                text <| "'" ++ url ++ "' could not be parsed: " ++ err

            Nothing ->
                case current doc of
                    Just ({ code, data } as pair) ->
                        let
                            url =
                                Debug.log "Viewing " <| RealmUrl.create pair
                        in
                        Html.fromUnstyled <| Gizmo.render code data

                    Nothing ->
                        text "You haven't navigated to anything. Click a realm link."
        ]


subscriptions : Model State Doc -> Sub Msg
subscriptions model =
    Navigation.currentUrl NavigateTo


current : Doc -> Maybe Pair
current =
    .history >> List.head