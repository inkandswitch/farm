module Launcher exposing (Doc, Msg, State, gizmo)

import Browser.Navigation as BrowserNav
import Clipboard
import Css exposing (..)
import Dict
import Gizmo exposing (Flags, Model)
import Html.Styled as Html exposing (..)
import Html.Styled.Attributes exposing (css, href, placeholder, src, value)
import Html.Styled.Events exposing (..)
import Json.Decode as D
import Navigation
import RealmUrl
import Repo exposing (Ref, Url, create)
import Task
import VsCode


hotPink =
    hex "#ff69b4"


darkerHotPink =
    hex "#ff1a8c"


gizmo : Gizmo.Program State Doc Msg
gizmo =
    Gizmo.element
        { init = init
        , update = update
        , view = Html.toUnstyled << view
        , subscriptions = subscriptions
        }


type alias DocumentUrl =
    String


type alias SourceUrl =
    DocumentUrl


type alias DataUrl =
    DocumentUrl


type alias GizmoConfig =
    { code : SourceUrl
    , data : DataUrl
    }


type alias State =
    { launchedGizmos : List GizmoConfig -- yikes
    , gizmoTypeToCreate : Maybe SourceUrl
    , showingGizmoTypes : Bool
    , addGizmoUrl : Maybe String
    }


type alias Doc =
    { gizmos : List GizmoConfig
    , gizmoTypes : List SourceUrl
    }


init : Flags -> ( State, Doc, Cmd Msg )
init flags =
    ( { launchedGizmos = []
      , gizmoTypeToCreate = Nothing
      , showingGizmoTypes = False
      , addGizmoUrl = Nothing
      }
    , { gizmos = []
      , gizmoTypes =
            List.filter
                (not << String.isEmpty)
                [ Maybe.withDefault "" (Dict.get "note" flags.config)
                , Maybe.withDefault "" (Dict.get "imageGallery" flags.config)
                , Maybe.withDefault "" (Dict.get "chat" flags.config)
                ]
      }
    , Cmd.none
    )


{-| Message type for modifying State and Doc inside update
-}
type Msg
    = NoOp
    | LaunchGizmo GizmoConfig
    | ShowGizmoTypeSelector
    | HideGizmoTypeSelector
    | CreateGizmo SourceUrl
    | GizmoDataDocCreated ( Ref, List String )
    | CopyShareLink GizmoConfig
    | Navigate String
    | RemoveGizmo GizmoConfig
    | SetAddGizmoInputUrl String
    | SubmitAddGizmoInput
    | OnAddGizmoInputKeyDown Int
    | CreateGizmoTypeSourceDoc
    | GizmoTypeSourceDocCreated ( Ref, List String )
    | DocCreated ( Ref, List String )


update : Msg -> Model State Doc -> ( State, Doc, Cmd Msg )
update msg model =
    let
        state =
            model.state

        doc =
            model.doc
    in
    case msg of
        NoOp ->
            ( state, doc, Cmd.none )

        LaunchGizmo gizmoConfig ->
            ( { state | launchedGizmos = state.launchedGizmos ++ [ gizmoConfig ] }
            , doc
            , Cmd.none
            )

        ShowGizmoTypeSelector ->
            ( { state | showingGizmoTypes = True }
            , doc
            , Cmd.none
            )

        HideGizmoTypeSelector ->
            ( { state | showingGizmoTypes = False }
            , doc
            , Cmd.none
            )

        DocCreated ( ref, urls ) ->
            case ref of
                "GizmoSourceDoc" ->
                    update (GizmoTypeSourceDocCreated ( ref, urls )) model

                "GizmoDataDoc" ->
                    update (GizmoDataDocCreated ( ref, urls )) model

                _ ->
                    ( state, doc, Cmd.none )

        CreateGizmoTypeSourceDoc ->
            ( state
            , doc
            , Repo.createSource "GizmoSourceDoc"
            )

        GizmoTypeSourceDocCreated ( ref, urls ) ->
            case List.head urls of
                Just url ->
                    ( state
                    , { doc | gizmoTypes = url :: doc.gizmoTypes }
                    , BrowserNav.load (VsCode.link url)
                    )

                _ ->
                    ( state, doc, Cmd.none )

        CreateGizmo gizmoType ->
            ( { state | gizmoTypeToCreate = Just gizmoType }
            , doc
            , Repo.create "GizmoDataDoc" 1
            )

        GizmoDataDocCreated ( ref, urls ) ->
            case ( state.gizmoTypeToCreate, List.head urls ) of
                ( Just gizmoType, Just url ) ->
                    let
                        gizmoConfig =
                            { code = gizmoType, data = url }
                    in
                    ( { state | gizmoTypeToCreate = Nothing, showingGizmoTypes = False, launchedGizmos = state.launchedGizmos ++ [ gizmoConfig ] }
                    , { doc | gizmos = gizmoConfig :: doc.gizmos }
                    , Cmd.none
                    )

                _ ->
                    ( { state | showingGizmoTypes = False, gizmoTypeToCreate = Nothing }
                    , doc
                    , Cmd.none
                    )

        RemoveGizmo gizmoConfig ->
            ( state
            , { doc | gizmos = List.filter ((/=) gizmoConfig) doc.gizmos }
            , Cmd.none
            )

        CopyShareLink gizmoConfig ->
            case RealmUrl.create gizmoConfig of
                Ok url ->
                    ( state
                    , doc
                    , Clipboard.copy url
                    )

                Err err ->
                    ( state
                    , doc
                    , Cmd.none
                    )

        Navigate url ->
            case RealmUrl.parse url of
                Ok gizmoConfig ->
                    ( { state | launchedGizmos = state.launchedGizmos ++ [ gizmoConfig ] }
                    , { doc | gizmos = gizmoConfig :: doc.gizmos }
                    , Cmd.none
                    )

                Err _ ->
                    ( state, doc, Cmd.none )

        SetAddGizmoInputUrl url ->
            ( { state | addGizmoUrl = Just url }
            , doc
            , Cmd.none
            )

        OnAddGizmoInputKeyDown key ->
            case key of
                13 ->
                    update SubmitAddGizmoInput model

                _ ->
                    ( state
                    , doc
                    , Cmd.none
                    )

        SubmitAddGizmoInput ->
            case state.addGizmoUrl of
                Nothing ->
                    ( state, doc, Cmd.none )

                Just url ->
                    case RealmUrl.parse url of
                        Err urlErr ->
                            ( state, doc, Cmd.none )

                        Ok gizmoConfig ->
                            ( { state | addGizmoUrl = Nothing }
                            , { doc | gizmos = gizmoConfig :: doc.gizmos }
                            , Cmd.none
                            )


viewGizmo : SourceUrl -> DataUrl -> Html Msg
viewGizmo source data =
    Html.fromUnstyled (Gizmo.render source data)


view : Model State Doc -> Html Msg
view { flags, state, doc } =
    -- TODO: Clean up this let block
    let
        iconSource =
            Maybe.withDefault "" (Dict.get "icon" flags.config)

        titleSource =
            Maybe.withDefault "" (Dict.get "title" flags.config)

        createIcon =
            Maybe.withDefault "" (Dict.get "createIcon" flags.config)

        viewIcon =
            viewGizmo iconSource

        viewTitle =
            viewGizmo titleSource
    in
    div
        [ css
            [ width (vw 100)
            , height (vh 100)
            , backgroundColor (hex "#f5f5f5")
            , fontFamilies [ "system-ui" ]
            , displayFlex
            , flexDirection column
            , justifyContent center
            , alignItems center
            ]
        ]
        [ div
            [ css
                [ width (vw 100)
                , backgroundColor (hex "#fff")
                , padding (px 20)
                , flexGrow (int 1)
                , overflowY auto
                ]
            ]
            [ grid
                (cell
                    [ gizmoLauncher (text "Create Gizmo") (viewIcon flags.code) ShowGizmoTypeSelector
                    ]
                    :: List.map
                        (\gc ->
                            cell
                                [ gizmoLauncher (viewTitle gc.data) (viewIcon gc.code) (LaunchGizmo gc)
                                , viewPinkLinks gc
                                ]
                        )
                        doc.gizmos
                )
            ]
        , viewAddGizmoInput (Maybe.withDefault "" state.addGizmoUrl)
        , if state.showingGizmoTypes then
            viewGizmoTypeSelector createIcon viewIcon viewTitle doc.gizmoTypes

          else
            Html.text ""
        , div [] (List.map viewGizmoWindow state.launchedGizmos)
        ]


grid : List (Html Msg) -> Html Msg
grid cells =
    div
        [ css
            [ property "display" "grid"
            , property "grid-template-columns" "repeat(auto-fit, minmax(100px, 1fr))"
            , property "grid-auto-rows" "1fr"
            , justifyContent center
            , property "gap" "1rem"
            ]
        ]
        cells


cell : List (Html Msg) -> Html Msg
cell content =
    div [] content


viewAddGizmoInput : String -> Html Msg
viewAddGizmoInput inputValue =
    div
        [ css
            [ displayFlex
            , borderTop3 (px 1) solid hotPink
            , width (pct 100)
            ]
        ]
        [ input
            [ value inputValue
            , placeholder "Gizmo url (e.g. realm:/...)"
            , onInput SetAddGizmoInputUrl
            , onKeyDown OnAddGizmoInputKeyDown
            , css
                [ border zero
                , padding (px 10)
                , width (pct 100)
                , color hotPink
                ]
            ]
            []
        , button
            [ css
                [ backgroundColor hotPink
                , color (hex "#fff")
                , border zero
                , borderLeft3 (px 1) solid hotPink
                , whiteSpace noWrap
                , cursor pointer
                , hover
                    [ backgroundColor darkerHotPink
                    ]
                ]
            , onClick SubmitAddGizmoInput
            ]
            [ text "Add Gizmo" ]
        ]


viewGizmoWindow : GizmoConfig -> Html Msg
viewGizmoWindow gizmoConfig =
    Html.fromUnstyled <| Gizmo.renderWindow gizmoConfig.code gizmoConfig.data


gizmoLauncher : Html Msg -> Html Msg -> Msg -> Html Msg
gizmoLauncher title icon msg =
    div
        [ onClick msg
        , css
            [ displayFlex
            , flexDirection column
            , alignItems center
            ]
        ]
        [ div
            [ css
                [ height (px 50)
                , width (px 50)
                ]
            ]
            [ icon
            ]
        , span
            [ css
                [ fontSize (Css.em 0.8)
                , textAlign center
                , marginTop (px 5)
                ]
            ]
            [ title
            ]
        ]


viewPinkLinks : GizmoConfig -> Html Msg
viewPinkLinks gizmoConfig =
    div
        [ css
            [ fontSize (Css.em 0.7)
            , textAlign center
            ]
        ]
        [ div
            [ css
                [ paddingTop (px 5)
                , cursor pointer
                , color hotPink
                , hover
                    [ textDecoration underline
                    ]
                ]
            , onClick (CopyShareLink gizmoConfig)
            ]
            [ text "share"
            ]
        , div
            [ css
                [ paddingTop (px 5)
                , cursor pointer
                ]
            ]
            [ pinkLink ( VsCode.link gizmoConfig.code, "edit source" ) ]
        , div
            [ css
                [ paddingTop (px 5)
                , cursor pointer
                ]
            ]
            [ pinkLink ( VsCode.link gizmoConfig.data, "edit data" )
            ]
        , div
            [ css
                [ paddingTop (px 5)
                , cursor pointer
                , color hotPink
                , hover
                    [ textDecoration underline
                    ]
                ]
            , onClick (RemoveGizmo gizmoConfig)
            ]
            [ text "remove"
            ]
        ]


pinkLink : ( String, String ) -> Html Msg
pinkLink ( hrefVal, textVal ) =
    a
        [ css
            [ color hotPink
            , textDecoration none
            , hover
                [ textDecoration underline
                ]
            ]
        , href hrefVal
        ]
        [ text textVal
        ]


onClickNoPropagation : msg -> Attribute msg
onClickNoPropagation msg =
    stopPropagationOn "click" (D.map alwaysTrue (D.succeed msg))


alwaysTrue : msg -> ( msg, Bool )
alwaysTrue msg =
    ( msg, True )


viewGizmoTypeSelector : String -> (String -> Html Msg) -> (String -> Html Msg) -> List SourceUrl -> Html Msg
viewGizmoTypeSelector createIcon viewIcon viewTitle gizmoTypes =
    window
        "Select Gizmo Type"
        HideGizmoTypeSelector
        [ list
            (viewCreateNewGizmoTypeItem createIcon
                :: List.map
                    (\g -> item (CreateGizmo g) (viewIcon g) (viewTitle g))
                    gizmoTypes
            )
        ]


viewCreateNewGizmoTypeItem : String -> Html Msg
viewCreateNewGizmoTypeItem iconSrc =
    item
        CreateGizmoTypeSourceDoc
        (div
            [ css
                [ width (pct 100)
                , height (pct 100)
                , backgroundImage (url iconSrc)
                , backgroundPosition center
                , backgroundSize cover
                ]
            ]
            []
        )
        (div
            [ css
                [ fontSize (Css.em 1.2)
                , color hotPink
                ]
            ]
            [ text "Create New Gizmo"
            ]
        )


window : String -> Msg -> List (Html Msg) -> Html Msg
window title onClose content =
    div
        [ css
            [ position fixed
            , top zero
            , left zero
            , width (pct 100)
            , height (pct 100)
            , displayFlex
            , flexDirection column
            , backgroundColor (hex "#fff")
            ]
        ]
        [ windowTitleBar onClose [ text title ]
        , div
            [ css
                [ displayFlex
                , flex (num 1)
                , flexDirection column
                , overflowY auto
                ]
            ]
            content
        ]


windowTitleBar : Msg -> List (Html Msg) -> Html Msg
windowTitleBar onBackClick title =
    div
        [ css
            [ displayFlex
            , flexDirection row
            , padding (px 10)
            , backgroundColor (hex "#fff")
            , zIndex (int 1)
            , boxShadow4 (rgba 0 0 0 0.2) (px 0) (px 2) (px 5)
            , borderBottom3 (px 1) solid (hex "#ddd")
            ]
        ]
        [ div
            [ onClick onBackClick
            , css
                [ padding2 (px 2) (px 5)
                , cursor pointer
                ]
            ]
            [ text "X" ]
        , div
            [ css
                [ flex (num 1)
                , textAlign center
                ]
            ]
            title
        , div [] []
        ]


list : List (Html Msg) -> Html Msg
list items =
    div
        [ css [ padding2 zero (px 30) ]
        ]
        items


item : Msg -> Html Msg -> Html Msg -> Html Msg
item onClickMsg icon title =
    div
        [ onClick onClickMsg
        , css
            [ padding2 (px 20) zero
            , borderBottom3 (px 1) solid (hex "#ddd")
            , cursor pointer
            , displayFlex
            , flexDirection row
            , alignItems center
            , fontSize (Css.em 1.2)
            ]
        ]
        [ div
            [ css
                [ height (px 50)
                , width (px 50)
                , marginRight (px 15)
                ]
            ]
            [ icon
            ]
        , title
        ]


subscriptions : Model State Doc -> Sub Msg
subscriptions model =
    Sub.batch
        [ Repo.created DocCreated
        , Navigation.currentUrl Navigate
        ]


onKeyDown : (Int -> msg) -> Attribute msg
onKeyDown tagger =
    on "keydown" (D.map tagger keyCode)
