module Launcher exposing (Doc, Msg, State, gizmo)

import Clipboard
import Css exposing (..)
import Dict
import Gizmo exposing (Flags, Model)
import Html.Styled as Html exposing (..)
import Html.Styled.Attributes exposing (css, placeholder, src, value)
import Html.Styled.Events exposing (..)
import Json.Decode as D
import RealmUrl
import Repo exposing (Ref, Url, create)
import Task


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

        -- todoSource =
        --     Maybe.withDefault "" (Dict.get "todo" flags.config)
        chatSource =
            Maybe.withDefault "" (Dict.get "chat" flags.config)
    in
    ( { launchedGadgets = []
      , ownDoc = flags.data
      , gadgetTypeToCreate = Nothing
      , showingGadgetTypes = False
      }
    , { gadgets = [], gadgetTypes = [ noteSource, imageGallerySource, chatSource ] }
      --, todoSource, chatSource ] }
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
            , justifyContent center
            , alignItems center
            ]
        ]
        [ div
            [ css
                [ width (vw 100)
                , height (vh 100)
                , backgroundColor (hex "#fff")
                , padding (px 20)
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
        , div
            [ css
                [ fontSize (Css.em 0.7)
                , paddingTop (px 5)
                , cursor pointer
                , color (hex "#ff69b4")
                ]
            , onClickNoPropagation (Share gadget)
            ]
            [ text "share" ]
        ]


onClickNoPropagation : msg -> Attribute msg
onClickNoPropagation msg =
    stopPropagationOn "click" (D.map alwaysTrue (D.succeed msg))


alwaysTrue : msg -> ( msg, Bool )
alwaysTrue msg =
    ( msg, True )


viewLauncherIcon : Msg -> Html Msg -> Html Msg -> Html Msg
viewLauncherIcon onClickMsg icon title =
    div
        [ onClick onClickMsg
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
            [ title ]
        , div
            [ css
                [ fontSize (Css.em 0.6)
                , paddingTop (px 5)
                , cursor pointer
                ]
            ]
            [ text "share" ]
        ]


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
    Repo.created GadgetDataDocCreated
