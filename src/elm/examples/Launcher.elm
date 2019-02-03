module Launcher exposing (Doc, Msg, State, gizmo)

import Browser.Navigation as BrowserNav
import Clipboard
import Css exposing (..)
import Dict
import FarmUrl
import Gizmo exposing (Flags, Model)
import Html.Styled as Html exposing (..)
import Html.Styled.Attributes exposing (css, href, placeholder, src, value)
import Html.Styled.Events exposing (..)
import Json.Decode as D
import Json.Encode as E
import Navigation
import Repo exposing (Props, Ref, Url, create, createWithProps)
import Set
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
        , view = view
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


type Tab
    = Gizmo
    | Data
    | Source


type alias State =
    { gizmoTypeToCreate : Maybe SourceUrl
    , gizmoDataForFork : Maybe DataUrl
    , showingGizmoTypes : Bool
    , addGizmoUrl : Maybe String
    , activeTab : Tab
    }


type alias Doc =
    { gizmos : List GizmoConfig
    , sources : List SourceUrl
    , data : List DataUrl
    , activeGizmos : List String
    }


sourceProps : Repo.Props
sourceProps =
    -- Template properties for Source docs
    [ ( "title", E.string "New Source Doc" )
    , ( "Source.elm", E.string "" )
    ]


init : Flags -> ( State, Doc, Cmd Msg )
init flags =
    ( { gizmoTypeToCreate = Nothing
      , showingGizmoTypes = False
      , addGizmoUrl = Nothing
      , gizmoDataForFork = Nothing
      , activeTab = Gizmo
      }
    , { gizmos = []
      , sources = []
      , data = []
      , activeGizmos = []
      }
    , Cmd.none
    )


{-| Message type for modifying State and Doc inside update
-}
type Msg
    = NoOp
    | LaunchGizmo GizmoConfig
    | CloseGizmo String
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
    | ForkSource SourceUrl
    | ForkedGizmoSourceDocCreated ( Ref, List String )
    | SetTab Tab


update : Msg -> Model State Doc -> ( State, Doc, Cmd Msg )
update msg model =
    let
        state =
            model.state

        doc =
            model.doc

        activeGizmos =
            Set.fromList doc.activeGizmos
    in
    case msg of
        NoOp ->
            ( state, doc, Cmd.none )

        SetTab tab ->
            ( { state | activeTab = tab }
            , doc
            , Cmd.none
            )

        LaunchGizmo gizmoConfig ->
            case FarmUrl.create gizmoConfig of
                Ok farmUrl ->
                    ( state
                    , { doc | activeGizmos = Set.toList (Set.insert farmUrl activeGizmos) }
                    , Cmd.none
                    )

                _ ->
                    ( state
                    , doc
                    , Cmd.none
                    )

        CloseGizmo gizmoUrl ->
            ( state
            , { doc | activeGizmos = Set.toList (Set.remove gizmoUrl activeGizmos) }
            , Cmd.none
            )

        DocCreated ( ref, urls ) ->
            case ref of
                "GizmoSourceDoc" ->
                    update (GizmoTypeSourceDocCreated ( ref, urls )) model

                "GizmoDataDoc" ->
                    update (GizmoDataDocCreated ( ref, urls )) model

                "ForkSource" ->
                    update (ForkedGizmoSourceDocCreated ( ref, urls )) model

                _ ->
                    Debug.log ref
                        ( state, doc, Cmd.none )

        CreateGizmoTypeSourceDoc ->
            ( state
            , doc
            , Repo.createWithProps "GizmoSourceDoc" 1 sourceProps
            )

        GizmoTypeSourceDocCreated ( ref, urls ) ->
            case List.head urls of
                Just url ->
                    ( state
                    , { doc | sources = url :: doc.sources }
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
                    case FarmUrl.create gizmoConfig of
                        Ok farmUrl ->
                            ( { state | gizmoTypeToCreate = Nothing, showingGizmoTypes = False }
                            , { doc | gizmos = gizmoConfig :: doc.gizmos, data = url :: doc.data, activeGizmos = Set.toList (Set.insert farmUrl activeGizmos) }
                            , Cmd.none
                            )

                        _ ->
                            ( { state | showingGizmoTypes = False, gizmoTypeToCreate = Nothing }
                            , doc
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
            case FarmUrl.create gizmoConfig of
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

        ForkSource source ->
            ( state
            , doc
            , Repo.fork "ForkSource" source
            )

        ForkedGizmoSourceDocCreated ( ref, urls ) ->
            case List.head urls of
                Just forkedSourceUrl ->
                    ( state
                    , { doc | sources = forkedSourceUrl :: doc.sources }
                    , Cmd.none
                    )

                _ ->
                    ( state
                    , doc
                    , Cmd.none
                    )

        Navigate url ->
            case FarmUrl.parse url of
                Ok gizmoConfig ->
                    ( state
                    , { doc | gizmos = gizmoConfig :: doc.gizmos, activeGizmos = Set.toList (Set.insert url activeGizmos) }
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
                    case FarmUrl.parse url of
                        Err urlErr ->
                            ( state, doc, Cmd.none )

                        Ok gizmoConfig ->
                            ( { state | addGizmoUrl = Nothing }
                            , { doc
                                | gizmos = gizmoConfig :: doc.gizmos
                                , data = gizmoConfig.data :: doc.data
                                , sources = gizmoConfig.code :: doc.sources
                              }
                            , Cmd.none
                            )


view : Model State Doc -> Html Msg
view model =
    -- TODO: Clean up this let block
    let
        flags =
            model.flags

        doc =
            model.doc

        state =
            model.state

        viewAvatar =
            viewGizmo <| Maybe.withDefault "" (Dict.get "avatar" flags.config)

        viewEditableTitle =
            viewGizmo <| Maybe.withDefault "" (Dict.get "editableTitle" flags.config)
    in
    div
        [ css
            [ width (vw 100)
            , height (vh 100)
            , fontFamilies [ "system-ui" ]
            , displayFlex
            , flexDirection column
            , justifyContent center
            , alignItems center
            ]
        ]
        [ avatarHeader (viewAvatar flags.self) (viewEditableTitle flags.self)
        , viewTabs
            [ viewTab (SetTab Gizmo) (state.activeTab == Gizmo) "Gizmos"
            , viewTab (SetTab Source) (state.activeTab == Source) "Source"
            , viewTab (SetTab Data) (state.activeTab == Data) "Data"
            ]
        , tabContent
            [ case state.activeTab of
                Gizmo ->
                    viewGizmos model

                Source ->
                    viewSources model

                Data ->
                    viewData model
            ]
        , div [] (List.map viewGizmoWindow doc.activeGizmos)
        ]


viewTabs : List (Html Msg) -> Html Msg
viewTabs tabs =
    div
        [ css
            [ displayFlex
            , flexDirection row
            , flexShrink (int 0)
            , width (pct 100)
            , backgroundColor (hex "#fff")
            , borderBottom3 (px 1) solid hotPink
            ]
        ]
        tabs


activeTabStyle =
    [ padding (px 15)
    , fontWeight bold
    , color hotPink
    ]


inactiveTabStyle =
    [ padding (px 15)
    , cursor pointer
    , hover
        [ color hotPink
        ]
    ]


viewTab : Msg -> Bool -> String -> Html Msg
viewTab msg isActive title =
    div
        [ onClick msg
        , css
            (if isActive then
                activeTabStyle

             else
                inactiveTabStyle
            )
        ]
        [ text title
        ]


tabContent : List (Html Msg) -> Html Msg
tabContent content =
    div
        [ css
            [ width (pct 100)
            , flexGrow (int 1)
            , displayFlex
            , flexDirection row
            , overflowY auto
            ]
        ]
        content


viewGizmos : Model State Doc -> Html Msg
viewGizmos { flags, state, doc } =
    let
        viewTitle =
            viewGizmo <| Maybe.withDefault "" (Dict.get "title" flags.config)

        viewIcon =
            viewGizmo <| Maybe.withDefault "" (Dict.get "icon" flags.config)
    in
    div
        [ css
            [ width (vw 100)
            , backgroundColor (hex "#fff")
            , flexGrow (int 1)
            , displayFlex
            , flexDirection column
            ]
        ]
        [ div
            [ css
                [ flexGrow (int 1)
                , overflowY auto
                , padding (px 20)
                ]
            ]
            [ grid
                (List.map
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
        ]


viewSources : Model State Doc -> Html Msg
viewSources { flags, state, doc } =
    let
        viewTitle =
            viewGizmo <| Maybe.withDefault "" (Dict.get "title" flags.config)

        viewIcon =
            viewGizmo <| Maybe.withDefault "" (Dict.get "icon" flags.config)

        createIcon =
            Maybe.withDefault "" (Dict.get "createIcon" flags.config)
    in
    list
        (viewCreateNewGizmoTypeItem createIcon
            :: List.map
                (\s -> sourceListItem s (viewIcon s) (viewTitle s))
                doc.sources
        )


sourceListItem : String -> Html Msg -> Html Msg -> Html Msg
sourceListItem source icon title =
    item
        icon
        (div
            []
            [ title
            , div
                [ css
                    [ displayFlex
                    , flexDirection row
                    , fontSize (Css.em 0.8)
                    , marginTop (px 5)
                    ]
                ]
                [ span [ css [ marginRight (px 7) ] ] [ pinkText (CreateGizmo source) "create" ]
                , span [ css [ marginRight (px 7) ] ] [ pinkLink ( VsCode.link source, "edit" ) ]
                , span [ css [ marginRight (px 7) ] ] [ pinkText (ForkSource source) "fork" ]
                , span [ css [ color (hex "#777"), marginRight (px 7) ] ] [ text "share" ]
                , span [ css [ color (hex "#777") ] ] [ text "remove" ]
                ]
            ]
        )


viewData : Model State Doc -> Html Msg
viewData { flags, state, doc } =
    let
        viewTitle =
            viewGizmo <| Maybe.withDefault "" (Dict.get "title" flags.config)

        viewIcon =
            viewGizmo <| Maybe.withDefault "" (Dict.get "icon" flags.config)
    in
    list
        (List.map
            (\d -> dataListItem d (viewIcon d) (viewTitle d))
            doc.data
        )


dataListItem : String -> Html Msg -> Html Msg -> Html Msg
dataListItem source icon title =
    item
        icon
        (div
            []
            [ title
            , div
                [ css
                    [ displayFlex
                    , flexDirection row
                    , fontSize (Css.em 0.8)
                    , marginTop (px 5)
                    ]
                ]
                [ span [ css [ color (hex "#777"), marginRight (px 7) ] ] [ text "openWith" ]
                , span [ css [ marginRight (px 7) ] ] [ pinkLink ( VsCode.link source, "edit" ) ]
                , span [ css [ color (hex "#777"), marginRight (px 7) ] ] [ text "share" ]
                , span [ css [ color (hex "#777") ] ] [ text "remove" ]
                ]
            ]
        )


viewGizmo : SourceUrl -> DataUrl -> Html Msg
viewGizmo source data =
    Gizmo.render source data


avatarHeader : Html Msg -> Html Msg -> Html Msg
avatarHeader avatar name =
    titleBar
        [ div
            [ css
                [ displayFlex
                , flexDirection row
                , alignItems center
                , justifyContent flexStart
                ]
            ]
            [ div
                [ css
                    [ height (px 36)
                    , width (px 36)
                    ]
                ]
                [ avatar
                ]
            , div
                [ css
                    [ marginLeft (px 10)
                    ]
                ]
                [ name
                ]
            ]
        ]


titleBar : List (Html Msg) -> Html Msg
titleBar content =
    div
        [ css
            [ width (pct 100)
            , backgroundColor (hex "#fff")
            , zIndex (int 1)
            , padding (px 10)
            , paddingBottom (px 0)
            ]
        ]
        content


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
            , placeholder "Gizmo url (e.g. farm:/...)"
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


viewGizmoWindow : String -> Html Msg
viewGizmoWindow farmUrl =
    case FarmUrl.parse farmUrl of
        Ok gizmoConfig ->
            Gizmo.renderWindow gizmoConfig.code gizmoConfig.data (CloseGizmo farmUrl)

        _ ->
            Html.text ""


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


pinkText : Msg -> String -> Html Msg
pinkText msg txt =
    span
        [ css
            [ cursor pointer
            , color hotPink
            , hover
                [ textDecoration underline
                ]
            ]
        , onClick msg
        ]
        [ text txt
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


viewCreateNewGizmoTypeItem : String -> Html Msg
viewCreateNewGizmoTypeItem iconSrc =
    div
        [ onClick CreateGizmoTypeSourceDoc
        , css
            [ padding2 (px 15) zero
            , borderBottom3 (px 1) solid (hex "#ddd")
            , displayFlex
            , flexDirection row
            , alignItems center
            , color hotPink
            , cursor pointer
            ]
        ]
        [ div
            [ css
                [ height (px 25)
                , width (px 25)
                , marginRight (px 10)
                ]
            ]
            [ div
                [ css
                    [ width (pct 100)
                    , height (pct 100)
                    , backgroundImage (url iconSrc)
                    , backgroundPosition center
                    , backgroundSize cover
                    ]
                ]
                []
            ]
        , text "Create New Gizmo"
        ]


list : List (Html Msg) -> Html Msg
list items =
    div
        [ css
            [ padding2 zero (px 15)
            , width (pct 100)
            ]
        ]
        items


item : Html Msg -> Html Msg -> Html Msg
item icon content =
    div
        [ css
            [ padding2 (px 15) zero
            , borderBottom3 (px 1) solid (hex "#ddd")
            , displayFlex
            , flexDirection row
            , alignItems center
            , fontSize (Css.em 1)
            ]
        ]
        [ div
            [ css
                [ height (px 25)
                , width (px 25)
                , marginRight (px 10)
                ]
            ]
            [ icon
            ]
        , content
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
