module Workspace exposing (Doc, Msg, State, gizmo)

import Gizmo exposing (Flags, Model)
import Html.Styled as Html exposing (..)
import Html.Styled.Attributes exposing (css)
import Html.Styled.Events exposing (..)
import Css exposing (..)
import Config
import IO
import Colors
import Navigation
import RealmUrl
import Dict
import Repo
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
    | CreateBoard
    | BoardCreated ( Repo.Ref, List String )


update : Msg -> Model State Doc -> ( State, Doc, Cmd Msg )
update msg ({ state, doc } as model) =
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

        CreateBoard ->
            ( state
            , doc
            , Repo.create "WorkspaceCreateBoardDataDoc" 2
            )

        BoardCreated ( ref, urls ) ->
            case List.head urls of
                Just url ->
                    case RealmUrl.create { code = Config.board, data = url } of
                        Ok realmUrl ->
                            update (NavigateTo realmUrl) model
                        _ ->
                            ( state
                            , doc
                            , IO.log <| "Failed to create a new board"
                            )
                _ ->
                    ( state
                    , doc
                    , IO.log <| "Failed to create a new board"
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
        , onCreateBoard CreateBoard
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


onCreateBoard : msg -> Html.Attribute msg
onCreateBoard msg =
    on "createboard" (D.succeed msg)


detail : D.Decoder String
detail =
    D.at ["detail", "value"] D.string


viewContent : Model State Doc -> Html Msg
viewContent { doc, state } =
    div
        [ css
            [ flex (num 1)
            , position relative
            , overflow auto
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
                        viewEmptyContent
        ]

viewEmptyContent : Html Msg
viewEmptyContent =
    div
        [ css
            [ fontFamilies ["system-ui"]
            , lineHeight (num 1.2)
            , displayFlex
            , flexDirection column
            , alignItems center
            , color (hex "444")
            ]
        ]
        [ div
            [ css
                [ maxWidth (px 450)
                , padding (px 20)
                ]
            ]
            [ h1
                [ css
                    [ fontWeight bold
                    , fontSize (Css.em 1.3)
                    , marginBottom (px 15)
                    ]
                ]
                [ text "Welcome to Realm!"
                ]
            , p
                [ css
                    [ margin2 (px 10) (px 0)
                    ]
                ]
                [ text "Enter a realm url into the navigation bar and press enter to begin. Alternatively, you can "
                , span
                    [ onClick CreateBoard
                    , css
                        [ color (hex Colors.hotPink)
                        , cursor pointer
                        , hover
                            [ color (hex Colors.darkerHotPink)
                            ]
                        ]
                    ]
                    [ text "click here"
                    ]
                , text " to create a brand new board of your own!"
                ]
            ]
        ]



subscriptions : Model State Doc -> Sub Msg
subscriptions model =
    Sub.batch
        [ Navigation.currentUrl NavigateTo
        , Repo.created BoardCreated
        ]


currentPair : History String -> Result String Pair
currentPair =
    History.current
    >> Result.fromMaybe "No current url"
    >> Result.andThen RealmUrl.parse