module Workspace exposing (Doc, Msg, State, gizmo)

import Browser.Dom as Dom
import Clipboard
import Colors
import Config
import Css exposing (..)
import Dict
import FarmUrl
import Gizmo exposing (Flags, Model)
import History exposing (History)
import Html.Styled as Html exposing (..)
import Html.Styled.Attributes as Attributes exposing (autofocus, css, placeholder, selected, value)
import Html.Styled.Events exposing (..)
import IO
import Json.Decode as D
import Json.Encode as E
import Keyboard exposing (Combo(..))
import ListSet exposing (ListSet)
import Navigation
import Repo
import Task
import Tooltip


inputBackgroundColor =
    "#e9e9e9"


darkerInputBackgroundColor =
    "#e5e5e5"


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


type alias Error =
    ( String, String )


type Mode
    = DefaultMode (Maybe Error)
    | EditMode
    | SearchMode (Maybe String)


{-| Ephemeral state not saved to the doc
-}
type alias State =
    { mode : Mode
    }


type alias Pair =
    { code : String
    , data : String
    }


{-| Document state
-}
type alias Doc =
    { history : History String
    , codeDocs : ListSet String
    }


init : Flags -> ( State, Doc, Cmd Msg )
init flags =
    ( { mode = DefaultMode Nothing
      }
    , { history = History.empty
      , codeDocs = ListSet.empty
      }
    , Cmd.none
    )


{-| Message type for modifying State and Doc inside update
-}
type Msg
    = NoOp
    | ChangeCodeDoc String
    | NavigateTo String
    | NavigateBack
    | NavigateForward
    | CreateBoard
    | BoardCreated ( Repo.Ref, List String )
    | SetDefaultMode
    | SetEditMode
    | SetSearchMode
    | ToggleSearchMode
    | SetSearchTerm String
    | Search
    | CopyLink
    | Focus String
    | Blur String


update : Msg -> Model State Doc -> ( State, Doc, Cmd Msg )
update msg ({ state, doc } as model) =
    case msg of
        NoOp ->
            ( state
            , doc
            , Cmd.none
            )

        ChangeCodeDoc newCodeUrl ->
            case currentPair doc.history of
                Just { code, data } ->
                    if code /= newCodeUrl then
                        case FarmUrl.create { code = newCodeUrl, data = data } of
                            Ok newFarmUrl ->
                                update (NavigateTo newFarmUrl) model

                            Err err ->
                                update NoOp model

                    else
                        update NoOp model

                Nothing ->
                    update NoOp model

        NavigateTo url ->
            case FarmUrl.parse url of
                Ok pair ->
                    ( { state | mode = DefaultMode Nothing }
                    , { doc
                        | history = History.push url doc.history
                        , codeDocs = ListSet.insert pair.code doc.codeDocs
                      }
                    , IO.log <| "Navigating to " ++ url
                    )

                Err err ->
                    ( { state | mode = DefaultMode (Just ( url, err )) }
                    , doc
                    , IO.log <| "Could not navigate to " ++ url ++ ". " ++ err
                    )

        NavigateBack ->
            ( { state | mode = DefaultMode Nothing }
            , { doc | history = History.back doc.history }
            , IO.log <| "Navigating backwards"
            )

        NavigateForward ->
            ( { state | mode = DefaultMode Nothing }
            , { doc | history = History.forward doc.history }
            , IO.log <| "Navigating forwards"
            )

        CreateBoard ->
            ( state
            , doc
            , Repo.create "WorkspaceCreateBoardDataDoc" 1
            )

        BoardCreated ( ref, urls ) ->
            case List.head urls of
                Just url ->
                    case FarmUrl.create { code = Config.board, data = url } of
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

        SetDefaultMode ->
            ( { state | mode = DefaultMode Nothing }
            , doc
            , Cmd.none
            )

        SetEditMode ->
            ( { state | mode = EditMode }
            , doc
            , Cmd.none
            )

        SetSearchMode ->
            ( { state | mode = SearchMode Nothing }
            , doc
            , Cmd.none
            )

        ToggleSearchMode ->
            case Debug.log "toggle" state.mode of
                SearchMode term ->
                    update SetDefaultMode model

                _ ->
                    update SetSearchMode model

        SetSearchTerm term ->
            ( { state | mode = SearchMode (Just term) }
            , doc
            , Cmd.none
            )

        Search ->
            case modeSearchTerm state.mode of
                Just searchTerm ->
                    update (NavigateTo searchTerm) model

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

        Focus id ->
            ( state
            , doc
            , Task.attempt (\_ -> NoOp) <| Dom.focus id
            )

        Blur id ->
            ( state
            , doc
            , Task.attempt (\_ -> NoOp) <| Dom.blur id
            )


view : Model State Doc -> Html Msg
view ({ flags, doc, state } as model) =
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
        , case state.mode of
            SearchMode _ ->
                viewHistory flags.data

            _ ->
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
            , alignItems center
            , boxShadow5 zero (px 2) (px 8) zero (rgba 0 0 0 0.12)
            , borderBottom3 (px 1) solid (hex "ddd")
            , height (px 40)
            ]
        ]
        [ viewNavButtons doc.history
        , case currentCodeUrl doc.history of
            Just url ->
                viewCodeSelect url doc.codeDocs

            Nothing ->
                Html.text ""
        , viewSuperbox model
        , viewSecondaryButtons
        ]


viewNavButtons : History String -> Html Msg
viewNavButtons history =
    div
        [ css
            [ flex (num 1)
            , alignItems start
            , justifyContent start
            , marginLeft (px 10)
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


viewCodeSelect : String -> ListSet String -> Html Msg
viewCodeSelect currentUrl knownUrls =
    select
        [ onInput ChangeCodeDoc
        , value currentUrl
        ]
        (viewCodeSelectOption currentUrl
            :: (List.map viewCodeSelectOption <| ListSet.remove currentUrl knownUrls)
        )


viewCodeSelectOption : String -> Html Msg
viewCodeSelectOption url =
    option
        [ value url
        ]
        [ viewProperty "title" url
        ]


viewProperty : String -> String -> Html Msg
viewProperty prop url =
    Html.fromUnstyled <|
        Gizmo.renderWith [ Gizmo.attr "prop" prop ] Config.property url


viewButton : Bool -> Msg -> List (Html Msg) -> Html Msg
viewButton isActive msg children =
    let
        style =
            if isActive then
                activeButtonStyle

            else
                inactiveButtonStyle
    in
    span
        [ stopPropagationOn "click" (D.succeed ( msg, isActive ))
        , css
            ([ display inlineBlock
             , borderRadius (px 3)
             , padding2 (px 3) (px 5)
             , fontWeight bold
             , marginRight (px 5)
             ]
                ++ style
            )
        ]
        children


activeButtonStyle =
    [ cursor pointer
    , color (hex Colors.primary)
    , border3 (px 1) solid (hex Colors.primary)
    , hover
        [ color (hex Colors.darkerPrimary)
        , borderColor (hex Colors.darkerPrimary)
        ]
    ]


inactiveButtonStyle =
    [ cursor pointer
    , border3 (px 1) solid (hex "aaa")
    , color (hex "aaa")
    ]


viewSecondaryButtons : Html Msg
viewSecondaryButtons =
    div
        [ css
            [ flex (num 1)
            , alignItems end
            , justifyContent end
            , marginRight (px 10)
            , textAlign right
            ]
        ]
        [ viewLink
            True
            ToggleSearchMode
            (Tooltip.tooltip Tooltip.BottomLeft "Cmd+t")
            [ text "search"
            ]
        , viewLink
            True
            CopyLink
            (Tooltip.tooltip Tooltip.BottomLeft "Cmd+s")
            [ text "share"
            ]
        , viewLink
            True
            CreateBoard
            (Tooltip.tooltip Tooltip.BottomLeft "Cmd+n")
            [ text "create"
            ]
        ]


viewLink : Bool -> Msg -> List Style -> List (Html Msg) -> Html Msg
viewLink isActive msg tooltip children =
    let
        style =
            if isActive then
                activeLinkStyle

            else
                inactiveLinkStyle
    in
    span
        [ stopPropagationOn "click" (D.succeed ( msg, isActive ))
        , css
            ([ display inlineBlock
             , border zero
             , fontSize (Css.em 0.9)
             , padding (px 5)
             ]
                ++ tooltip
                ++ style
            )
        ]
        children


activeLinkStyle =
    [ cursor pointer
    , color (hex Colors.primary)
    , hover
        [ color (hex Colors.darkerPrimary)
        ]
    ]


inactiveLinkStyle =
    [ cursor pointer
    , border3 (px 1) solid (hex "aaa")
    , color (hex "aaa")
    ]


viewSuperbox : Model State Doc -> Html Msg
viewSuperbox { doc, state } =
    div
        [ onStopPropagationClick NoOp
        , Keyboard.onPress Enter (Blur "title-input")
        , css
            [ flex (num 1)
            , alignItems center
            , justifyContent center
            , padding (px 5)
            , borderRadius (px 5)
            , color (hex "333")
            , margin2 (px 5) (px 5)
            , position relative
            , fontSize (Css.em 1.1)
            , textAlign center
            , hover
                [ color (hex "555")
                ]
            , pseudoClass "focus-within"
                [ color (hex "555")
                ]
            ]
        ]
        [ case currentDataUrl doc.history of
            Just dataUrl ->
                viewLiveEdit "title" dataUrl

            Nothing ->
                div
                    [ css
                        [ margin2 (px 2) (px 0)
                        ]
                    ]
                    [ text <| String.fromChar '\u{00A0}'
                    ]
        ]


viewLiveEdit : String -> String -> Html Msg
viewLiveEdit prop url =
    let
        props =
            [ Gizmo.attr "prop" prop
            , Gizmo.attr "input-id" "title-input"
            , Gizmo.attr "default" "No title"
            ]
    in
    Html.fromUnstyled <| Gizmo.renderWith props Config.liveEdit url


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
        [ case modeError state.mode of
            Just ( url, err ) ->
                text <| "'" ++ url ++ "' could not be parsed: " ++ err

            Nothing ->
                case currentPair doc.history of
                    Just ({ code, data } as pair) ->
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
                        [ color (hex Colors.primary)
                        , cursor pointer
                        , hover
                            [ color (hex Colors.darkerPrimary)
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
    500


viewHistory : String -> Html Msg
viewHistory url =
    div
        [ css
            [ position absolute
            , top (px 75)
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
            [ ( Cmd O, ToggleSearchMode )
            , ( Cmd T, ToggleSearchMode )
            , ( Cmd S, CopyLink )
            , ( Cmd N, CreateBoard )
            , ( Cmd Left, NavigateBack )
            , ( Cmd Right, NavigateForward )
            , ( Ctrl O, ToggleSearchMode )
            , ( Ctrl T, ToggleSearchMode )
            , ( Ctrl S, CopyLink )
            , ( Ctrl N, CreateBoard )
            , ( Ctrl Left, NavigateBack )
            , ( Ctrl Right, NavigateForward )
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


currentCodeUrl : History String -> Maybe String
currentCodeUrl =
    currentPair >> Maybe.map .code


onStopPropagationClick : Msg -> Html.Attribute Msg
onStopPropagationClick msg =
    stopPropagationOn "click" (D.succeed ( msg, True ))


modeSearchTerm : Mode -> Maybe String
modeSearchTerm mode =
    case mode of
        SearchMode searchTerm ->
            searchTerm

        _ ->
            Nothing


modeError : Mode -> Maybe Error
modeError mode =
    case mode of
        DefaultMode error ->
            error

        _ ->
            Nothing
