module Launcher exposing (Doc, Msg, State, gizmo)

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


type alias Gadget =
    { code : DocumentUrl
    , data : DocumentUrl
    }


type alias State =
    { launchedGadgets : List Gadget -- yikes
    , ownDoc : String
    , gadgetTypeToCreate : Maybe DocumentUrl
    , showingGadgetTypes : Bool
    , addGizmoUrl : Maybe String
    }


type alias Doc =
    { gadgets : List Gadget
    , gadgetTypes : List DocumentUrl
    }


{-| What are Flags?
-}
init : Flags -> ( State, Doc, Cmd Msg )
init flags =
    let
        noteSource =
            Maybe.withDefault "" (Dict.get "note" flags.config)

        imageGallerySource =
            Maybe.withDefault "" (Dict.get "imageGallery" flags.config)

        chatSource =
            Maybe.withDefault "" (Dict.get "chat" flags.config)
    in
    ( { launchedGadgets = []
      , ownDoc = flags.data
      , gadgetTypeToCreate = Nothing
      , showingGadgetTypes = False
      , addGizmoUrl = Nothing
      }
    , { gadgets = [], gadgetTypes = [ noteSource, imageGallerySource, chatSource ] }
    , Cmd.none
    )


{-| Message type for modifying State and Doc inside update
-}
type Msg
    = NoOp
    | Launch Gadget
    | ShowGadgetTypes
    | HideGadgetTypes
    | CreateGadget DocumentUrl
    | GadgetDataDocCreated ( Ref, List String )
    | Share Gadget
    | Navigate String
    | RemoveGizmo Gadget
    | SetAddGizmoUrl String
    | SubmitAddGizmo


update : Msg -> Model State Doc -> ( State, Doc, Cmd Msg )
update msg { state, doc } =
    case msg of
        NoOp ->
            ( state, doc, Cmd.none )

        Launch gadget ->
            ( { state | launchedGadgets = state.launchedGadgets ++ [ gadget ] }
            , doc
            , Cmd.none
            )

        ShowGadgetTypes ->
            ( { state | showingGadgetTypes = True }
            , doc
            , Cmd.none
            )

        HideGadgetTypes ->
            ( { state | showingGadgetTypes = False }
            , doc
            , Cmd.none
            )

        CreateGadget gadgetType ->
            ( { state | gadgetTypeToCreate = Just gadgetType }
            , doc
            , Repo.create "CreateOne" 1
            )

        GadgetDataDocCreated ( ref, urls ) ->
            case ( state.gadgetTypeToCreate, List.head urls ) of
                ( Just gadgetType, Just url ) ->
                    let
                        gadget =
                            { code = gadgetType, data = url }
                    in
                    ( { state | gadgetTypeToCreate = Nothing, showingGadgetTypes = False, launchedGadgets = state.launchedGadgets ++ [ gadget ] }
                    , { doc | gadgets = gadget :: doc.gadgets }
                    , Cmd.none
                    )

                _ ->
                    ( { state | showingGadgetTypes = False, gadgetTypeToCreate = Nothing }
                    , doc
                    , Cmd.none
                    )

        RemoveGizmo gadget ->
            ( state
            , { doc | gadgets = List.filter ((/=) gadget) doc.gadgets }
            , Cmd.none
            )

        Share gadget ->
            case RealmUrl.create gadget of
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
                Ok gadget ->
                    ( { state | launchedGadgets = state.launchedGadgets ++ [ gadget ] }
                    , { doc | gadgets = gadget :: doc.gadgets }
                    , Cmd.none
                    )

                Err _ ->
                    ( state, doc, Cmd.none )

        SetAddGizmoUrl url ->
            ( { state | addGizmoUrl = Just url }
            , doc
            , Cmd.none
            )

        SubmitAddGizmo ->
            case state.addGizmoUrl of
                Nothing ->
                    ( state, doc, Cmd.none )

                Just url ->
                    let
                        gadget =
                            RealmUrl.parse url
                    in
                    case gadget of
                        Err urlErr ->
                            ( state, doc, Cmd.none )

                        Ok newGadget ->
                            ( { state | addGizmoUrl = Nothing }
                            , { doc | gadgets = newGadget :: doc.gadgets }
                            , Cmd.none
                            )


view : Model State Doc -> Html Msg
view { flags, state, doc } =
    let
        iconSource =
            Maybe.withDefault "" (Dict.get "icon" flags.config)

        titleSource =
            Maybe.withDefault "" (Dict.get "title" flags.config)
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
                ]
            ]
            [ div
                [ css
                    [ property "display" "grid"
                    , property "grid-template-columns" "repeat(auto-fit, minmax(100px, 1fr))"
                    , property "grid-auto-rows" "1fr"
                    , justifyContent center
                    , property "gap" "1rem"
                    ]
                ]
                (viewCreateGizmoLauncher flags.code iconSource
                    :: List.map (viewGadgetLauncher titleSource iconSource) doc.gadgets
                )
            ]
        , div
            [ css
                [ displayFlex
                , borderTop3 (px 1) solid hotPink
                , width (pct 100)
                ]
            ]
            [ input
                [ value <| Maybe.withDefault "" state.addGizmoUrl
                , placeholder "Gizmo url (e.g. realm:/...)"
                , onInput SetAddGizmoUrl
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
                , onClick SubmitAddGizmo
                ]
                [ text "Add Gizmo" ]
            ]
        , if state.showingGadgetTypes then
            viewCreateGadget iconSource titleSource doc.gadgetTypes

          else
            Html.text ""
        , div [] (List.map viewGadget state.launchedGadgets)
        ]


viewCreateGizmoLauncher : DocumentUrl -> DocumentUrl -> Html Msg
viewCreateGizmoLauncher ownUrl iconSource =
    div
        [ onClick ShowGadgetTypes
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
            [ Html.fromUnstyled (Gizmo.render iconSource ownUrl)
            ]
        , span
            [ css
                [ fontSize (Css.em 0.8)
                , textAlign center
                , marginTop (px 5)
                ]
            ]
            [ text "Create Gizmo"
            ]
        ]


viewGadget : Gadget -> Html Msg
viewGadget gadget =
    Html.fromUnstyled <| Gizmo.renderWindow gadget.code gadget.data


viewGadgetLauncher : String -> String -> Gadget -> Html Msg
viewGadgetLauncher titleSource iconSource gadget =
    div
        []
        [ div
            [ onClick (Launch gadget)
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
                [ Html.fromUnstyled (Gizmo.render iconSource gadget.code)
                ]
            , span
                [ css
                    [ fontSize (Css.em 0.8)
                    , textAlign center
                    , marginTop (px 5)
                    ]
                ]
                [ Html.fromUnstyled (Gizmo.render titleSource gadget.data)
                ]
            ]
        , div
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
                , onClick (Share gadget)
                ]
                [ text "share"
                ]
            , div
                [ css
                    [ paddingTop (px 5)
                    , cursor pointer
                    ]
                ]
                [ pinkLink ( VsCode.link gadget.code, "edit source" ) ]
            , div
                [ css
                    [ paddingTop (px 5)
                    , cursor pointer
                    ]
                ]
                [ pinkLink ( VsCode.link gadget.data, "edit data" )
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
                , onClick (RemoveGizmo gadget)
                ]
                [ text "remove"
                ]
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


viewCreateGadget : String -> String -> List DocumentUrl -> Html Msg
viewCreateGadget iconSource titleSource gadgetTypes =
    viewWindow
        (viewWindowBar HideGadgetTypes [ text "Select Gizmo Type" ])
        [ div
            [ css [ padding2 zero (px 30) ]
            ]
            (List.map (viewGadgetType iconSource titleSource) gadgetTypes)
        ]


viewGadgetType : DocumentUrl -> DocumentUrl -> DocumentUrl -> Html Msg
viewGadgetType iconSource titleSource gadgetType =
    div
        [ onClick (CreateGadget gadgetType)
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
            [ Html.fromUnstyled <| Gizmo.render iconSource gadgetType
            ]
        , Html.fromUnstyled <| Gizmo.render titleSource gadgetType
        ]


viewWindowBar : Msg -> List (Html Msg) -> Html Msg
viewWindowBar onBackClick title =
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


viewWindow : Html Msg -> List (Html Msg) -> Html Msg
viewWindow bar contents =
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
        [ bar
        , div
            [ css
                [ displayFlex
                , flex (num 1)
                , flexDirection column
                ]
            ]
            contents
        ]


subscriptions : Model State Doc -> Sub Msg
subscriptions model =
    Sub.batch
        [ Repo.created GadgetDataDocCreated
        , Navigation.currentUrl Navigate
        ]
