module Workspace exposing (Doc, Msg, State, gizmo)

import Clipboard
import Colors
import Config
import Css exposing (..)
import Dict
import FarmUrl
import Gizmo exposing (Flags, Model)
import History exposing (History)
import Html.Styled as Html exposing (..)
import Html.Styled.Attributes exposing (autofocus, css, placeholder, value)
import Html.Styled.Events exposing (..)
import IO
import Json.Decode as D
import Keyboard exposing (Combo(..))
import Navigation
import Repo


superboxBackgroundColor =
    "e9edf0"


editTitleIcon =
    "📝"


gizmo : Gizmo.Program State Doc Msg
gizmo =
    Gizmo.element
        { init = init
        , update = update
        , view = Html.toUnstyled << view
        , subscriptions = subscriptions
        }


type Mode
    = DefaultMode
    | EditMode
    | SearchMode


{-| Ephemeral state not saved to the doc
-}
type alias State =
    { error : Maybe ( String, String )
    , mode : Mode
    , searchTerm : Maybe String
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
      , mode = DefaultMode
      , searchTerm = Nothing
      }
    , { history = History.empty
      }
    , Cmd.none
    )


{-| Message type for modifying State and Doc inside update
-}
type Msg
    = NoOp
    | NavigateTo String
    | NavigateBack
    | NavigateForward
    | CreateBoard
    | BoardCreated ( Repo.Ref, List String )
    | SetDefaultMode
    | SetEditMode
    | SetSearchMode
    | SetSearchTerm String
    | Search
    | CopyLink


update : Msg -> Model State Doc -> ( State, Doc, Cmd Msg )
update msg ({ state, doc } as model) =
    case msg of
        NoOp ->
            ( state
            , doc
            , Cmd.none
            )

        NavigateTo url ->
            case FarmUrl.parse url of
                Ok pair ->
                    ( { state | mode = DefaultMode, searchTerm = Nothing, error = Nothing }
                    , { doc | history = History.push url doc.history }
                    , IO.log <| "Navigating to " ++ url
                    )

                Err err ->
                    ( { state | error = Just ( url, err ), mode = DefaultMode }
                    , doc
                    , IO.log <| "Could not navigate to " ++ url ++ ". " ++ err
                    )

        NavigateBack ->
            ( { state | mode = DefaultMode, searchTerm = Nothing, error = Nothing }
            , { doc | history = History.back doc.history }
            , IO.log <| "Navigating backwards"
            )

        NavigateForward ->
            ( { state | mode = DefaultMode, searchTerm = Nothing, error = Nothing }
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
                    case FarmUrl.create { code = Config.board, data = url } of
                        Ok farmUrl ->
                            update (NavigateTo farmUrl) model

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

        SetDefaultMode ->
            ( { state | mode = DefaultMode, searchTerm = Nothing }
            , doc
            , Cmd.none
            )

        SetEditMode ->
            ( { state | mode = EditMode, searchTerm = Nothing }
            , doc
            , Cmd.none
            )

        SetSearchMode ->
            ( { state | mode = SearchMode }
            , doc
            , Cmd.none
            )

        SetSearchTerm term ->
            ( { state | searchTerm = Just term }
            , doc
            , Cmd.none
            )

        Search ->
            case state.searchTerm of
                Just term ->
                    update (NavigateTo term) model

                Nothing ->
                    ( state
                    , doc
                    , Cmd.none
                    )

        CopyLink ->
            case History.current doc.history of
                Just url ->
                    ( state
                    , doc
                    , Clipboard.copy url
                    )

                Nothing ->
                    ( state
                    , doc
                    , IO.log <| "Nothing to copy"
                    )


view : Model State Doc -> Html Msg
view ({ flags, doc, state } as model) =
    let
        navigationBar =
            Maybe.withDefault "" <| Dict.get "navigationBar" flags.config
    in
    div
        [ onClick SetDefaultMode
        , on "navigateback" (D.succeed NavigateBack)
        , on "navigateforward" (D.succeed NavigateForward)
        , on "navigate" (D.map NavigateTo detail)
        , on "defaultmode" (D.succeed SetDefaultMode)
        , on "editmode" (D.succeed SetEditMode)
        , on "searchmode" (D.succeed SetSearchMode)
        , css
            [ displayFlex
            , flexDirection column
            , height (vh 100)
            , width (vw 100)
            , position relative
            ]
        ]
        [ div
            [ css
                [ flexShrink (num 0)
                ]
            ]
            [ viewNavigationBar model
            ]
        , viewContent model
        , if state.mode == SearchMode then
            viewHistory flags.data

          else
            Html.text ""
        ]


detail : D.Decoder String
detail =
    D.at [ "detail", "value" ] D.string


viewNavigationBar : Model State Doc -> Html Msg
viewNavigationBar ({ doc, state } as model) =
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
        , viewSuperbox model
        , viewSecondaryButtons
        ]


viewNavButtons : History String -> Html Msg
viewNavButtons history =
    div
        [ css
            [ marginRight (px 10)
            ]
        ]
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


viewSecondaryButtons : Html Msg
viewSecondaryButtons =
    div
        [ css
            [ marginLeft (px 10)
            ]
        ]
        [ viewButton
            True
            CopyLink
            [ text "📋"
            ]
        , viewButton
            True
            CreateBoard
            [ text "➕"
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
        [ stopPropagationOn "click" (D.succeed ( msg, isActive ))
        , css
            ([ flexShrink (num 0)
             , border zero
             , fontSize (Css.em 1)
             , padding (px 5)
             , fontWeight bold
             ]
                ++ style
            )
        ]
        children


viewSuperbox : Model State Doc -> Html Msg
viewSuperbox { doc, state } =
    div
        [ onStopPropagationClick NoOp
        , css
            [ flexGrow (num 1)
            , fontSize (Css.em 0.8)
            , padding (px 5)
            , borderRadius (px 5)
            , backgroundColor (hex superboxBackgroundColor)
            , color (hex "777")
            , margin2 (px 0) auto
            , border zero
            , textAlign center
            , maxWidth (px 400)
            , position relative
            , focus
                [ color (hex Colors.blueBlack)
                ]
            , hover
                [ color (hex Colors.blueBlack)
                ]
            ]
        ]
        [ case state.mode of
            DefaultMode ->
                case currentDataUrl doc.history of
                    Just dataUrl ->
                        Html.fromUnstyled <| Gizmo.render Config.superboxDefault dataUrl

                    Nothing ->
                        div [ onClick SetSearchMode ] [ text " Empty Title" ]

            EditMode ->
                case currentDataUrl doc.history of
                    Just dataUrl ->
                        Html.fromUnstyled <| Gizmo.render Config.superboxEdit dataUrl

                    Nothing ->
                        text ""

            SearchMode ->
                input
                    [ css
                        [ width (pct 100)
                        , margin zero
                        , border zero
                        , padding zero
                        , cursor pointer
                        , backgroundColor transparent
                        , textAlign center
                        , fontSize (Css.em 1)
                        , color (hex Colors.blueBlack)
                        ]
                    , autofocus True
                    , placeholder "History"
                    , value <| Maybe.withDefault "" state.searchTerm
                    , onInput SetSearchTerm
                    , Keyboard.onPress Enter Search
                    ]
                    []
        ]


viewContent : Model State Doc -> Html Msg
viewContent { doc, state } =
    div
        [ css
            [ flex (num 1)
            , position relative
            , overflow auto
            , property "isolation" "isolate"
            ]
        ]
        [ case state.error of
            Just ( url, err ) ->
                text <| "'" ++ url ++ "' could not be parsed: " ++ err

            Nothing ->
                case currentPair doc.history of
                    Just ({ code, data } as pair) ->
                        let
                            url =
                                Debug.log "Viewing " <| FarmUrl.create pair
                        in
                        Html.fromUnstyled <| Gizmo.render code data

                    Nothing ->
                        viewEmptyContent
        ]


viewEmptyContent : Html Msg
viewEmptyContent =
    div
        [ css
            [ lineHeight (num 1.2)
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
                [ text "Welcome to FarmPin!"
                ]
            , p
                [ css
                    [ margin2 (px 10) (px 0)
                    ]
                ]
                [ text "Enter a farm url into the navigation bar and press enter to begin. Alternatively, you can "
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


historyWidth : Float
historyWidth =
    400


viewHistory : String -> Html Msg
viewHistory url =
    div
        [ css
            [ position absolute
            , top (px 50)
            , left (pct 50)
            , width (px historyWidth)
            , marginLeft (px -(historyWidth / 2))
            ]
        ]
        [ Html.fromUnstyled <| Gizmo.render Config.historyViewer url
        ]


subscriptions : Model State Doc -> Sub Msg
subscriptions { state } =
    Sub.batch
        [ Navigation.currentUrl NavigateTo
        , Repo.created BoardCreated
        , Keyboard.shortcuts
            [ ( Cmd T
              , if state.mode /= SearchMode then
                    SetSearchMode

                else
                    SetDefaultMode
              )
            , ( Cmd Left, NavigateBack )
            , ( Cmd Right, NavigateForward )
            , ( Cmd B, CreateBoard )
            , ( Esc, SetDefaultMode )
            ]
        ]


currentPair : History String -> Maybe Pair
currentPair =
    History.current
        >> Result.fromMaybe "No current url"
        >> Result.andThen FarmUrl.parse
        >> Result.toMaybe


currentDataUrl : History String -> Maybe String
currentDataUrl =
    currentPair >> Maybe.map .data


onStopPropagationClick : Msg -> Html.Attribute Msg
onStopPropagationClick msg =
    stopPropagationOn "click" (D.succeed ( msg, True ))
