module GizmoDirectory exposing (Doc, Msg, State, gizmo)

import Browser.Dom
import Css exposing (..)
import Css.Animations as Anim exposing (keyframes)
import Css.Global exposing (global)
import Gizmo
import Html
import Html.Attributes as Attr exposing (cols, rows, style, value)
import Html.Events exposing (onClick, onInput)
import Html.Styled exposing (..)
import Html.Styled.Attributes exposing (css, href, id, src)
import Html.Styled.Events exposing (on, onClick)
import Json.Decode as Decode
import Repo
import Task


gizmo : Gizmo.Program State Doc Msg
gizmo =
    Gizmo.element
        { init = init
        , update = update
        , view = view
        , subscriptions = subscriptions
        }


titleGizmo =
    "hypermerge://E19jZZNm4QceSWwwiZGLtrduFVDwmdtM3PGFAfMMS55S/"


avatarGizmo =
    "hypermerge://9DJcvkXLyRU8KmqvyzhNY3zCpkKXVkHVJ8vBNr6iizGQ/"


type alias Gizmo =
    { gizmo : String
    , documents : List String
    }


type alias Doc =
    { currentGizmo : Maybe String
    , currentDocument : Maybe Document
    , gizmos : List Gizmo
    }


type alias Document =
    String


type alias State =
    { gizmoTransition : GizmoTransition
    , elementPosition : Maybe Browser.Dom.Element
    , cloningUrl : Maybe String
    }


type GizmoTransition
    = NoGizmo
    | GizmoCreating String String
    | GizmoArriving String String
    | GizmoDeparting String String


init : Gizmo.Flags -> ( State, Doc, Cmd Msg )
init =
    always
        ( { gizmoTransition = NoGizmo
          , elementPosition = Nothing
          , cloningUrl = Nothing
          }
        , { currentGizmo = Nothing
          , currentDocument = Nothing
          , gizmos = []
          }
        , Cmd.none
        )


type Msg
    = Navigate String String
    | PositionGizmo Browser.Dom.Element
    | Close String String
    | CreateGizmoDocument String
    | CloneGizmo String
    | DocumentCreated ( Repo.Ref, List Repo.Url )
    | RemoveGizmo String
    | EndCloseGizmo


subscriptions : Gizmo.Model State Doc -> Sub Msg
subscriptions { state, doc } =
    Repo.created DocumentCreated


processGetElement : Result Browser.Dom.Error Browser.Dom.Element -> Msg
processGetElement result =
    case result of
        Err err ->
            EndCloseGizmo

        Ok element ->
            PositionGizmo element


update : Msg -> Gizmo.Model State Doc -> ( State, Doc, Cmd Msg )
update msg { state, doc } =
    case msg of
        Navigate newGizmo newDocument ->
            ( { state | gizmoTransition = GizmoCreating newGizmo newDocument }
            , { doc | currentDocument = Just newDocument, currentGizmo = Just newGizmo }
            , Task.attempt processGetElement (Browser.Dom.getElement newGizmo)
            )

        PositionGizmo element ->
            ( { state | elementPosition = Just element }
            , doc
            , Cmd.none
            )

        Close newGizmo newDocument ->
            ( { state | gizmoTransition = GizmoDeparting newGizmo newDocument }
            , { doc | currentGizmo = Nothing, currentDocument = Nothing }
            , Cmd.none
            )

        EndCloseGizmo ->
            ( { state | gizmoTransition = NoGizmo, elementPosition = Nothing }
            , { doc | currentGizmo = Nothing }
            , Cmd.none
            )

        CreateGizmoDocument hostGizmo ->
            ( state, doc, Repo.create hostGizmo 1 )

        RemoveGizmo url ->
            ( state, { doc | gizmos = removeGizmo url doc.gizmos }, Cmd.none )

        CloneGizmo url ->
            case state.cloningUrl of
                Nothing ->
                    ( { state | cloningUrl = Just url }, doc, Repo.clone "CloneGizmo" url )

                _ ->
                    Debug.log "tried to clone a second time before the first finished" ( state, doc, Cmd.none )

        DocumentCreated ( "CloneGizmo", urls ) ->
            ( { state | cloningUrl = Nothing }
            , { doc
                | gizmos =
                    doc.gizmos
                        ++ (urls |> List.map (\url -> { gizmo = url, documents = [] }))
              }
            , Cmd.none
            )

        DocumentCreated ( ref, urls ) ->
            ( state
            , { doc | gizmos = addNewDocsToGizmo ref urls doc.gizmos }
            , Cmd.none
            )


updateGizmo : String -> (Gizmo -> Gizmo) -> List Gizmo -> List Gizmo
updateGizmo url fn =
    List.map
        (\gmo ->
            if gmo.gizmo == url then
                fn gmo

            else
                gmo
        )


removeGizmo : String -> List Gizmo -> List Gizmo
removeGizmo url gizmos =
    List.filter (\gmo -> gmo.gizmo /= url) gizmos


addNewDocsToGizmo : Repo.Ref -> List Repo.Url -> List Gizmo -> List Gizmo
addNewDocsToGizmo url newUrls =
    updateGizmo url
        (\gmo -> { gmo | documents = gmo.documents ++ newUrls })


palette =
    { background = hex "#083D77"
    , panel = hex "#EBEBD3"
    , bright = hex "#F4D35E"
    , highlight = hex "#DA4167"
    , five = hex "#F78764"
    }


view : Gizmo.Model State Doc -> Html Msg
view { flags, state, doc } =
    let
        _ =
            Debug.log "view" state
    in
    div
        [ css
            [ fontFamilies [ "helvetica" ]
            , backgroundColor palette.background
            , width (pct 100)
            , height (vh 100)
            , margin zero
            ]
        ]
        [ h1
            [ css
                [ fontSize (px 36)
                , fontWeight bold
                , padding (px 8)
                , color palette.highlight
                ]
            ]
            [ text "Hola "
            , Gizmo.render titleGizmo flags.self
            , text "! What would you like to work on today?"
            ]
        , div [] [ viewGizmos doc.gizmos ]
        , case state.gizmoTransition of
            NoGizmo ->
                viewNoGizmo

            GizmoCreating giz document ->
                case state.elementPosition of
                    Nothing ->
                        viewNoGizmo

                    Just element ->
                        viewArrivingGizmo giz document element

            GizmoArriving giz document ->
                viewCurrentGizmo giz document

            GizmoDeparting giz document ->
                case state.elementPosition of
                    Nothing ->
                        viewNoGizmo

                    Just element ->
                        viewDepartingGizmo giz document element
        ]


viewNoGizmo : Html Msg
viewNoGizmo =
    div [ css gizmoStyles ] []


gizmoStyles =
    [ position absolute
    , backgroundColor (hex "#fff")
    , property "transition" "all 0.3s ease"
    ]


viewArrivingGizmo : String -> String -> Browser.Dom.Element -> Html Msg
viewArrivingGizmo currentGizmo currentDocument element =
    div
        [ css
            ([ left zero
             , top zero
             , width (pct 100)
             , height (pct 100)
             , animationDuration (ms 500)
             , animationIterationCount (int 1)
             , animationName
                (keyframes
                    [ ( 0
                      , [ Anim.property "left" (asPx element.element.x)
                        , Anim.property "top" (asPx element.element.y)
                        , Anim.property "width" (asPx element.element.width)
                        , Anim.property "height" (asPx element.element.height)
                        , Anim.property "opacity" "0"
                        ]
                      )
                    ]
                )
             ]
                ++ gizmoStyles
            )
        ]
        [ viewGizmoTitleBar currentGizmo currentDocument
        , Gizmo.render currentGizmo currentDocument
        ]


viewDepartingGizmo : String -> String -> Browser.Dom.Element -> Html Msg
viewDepartingGizmo currentGizmo currentDocument element =
    div
        [ onTransitionEnd EndCloseGizmo
        , css
            ([ left (px element.element.x)
             , top (px element.element.y)
             , width (px element.element.width)
             , height (px element.element.height)
             , opacity zero
             ]
                ++ gizmoStyles
            )
        ]
        [ viewGizmoTitleBar currentGizmo currentDocument
        , Gizmo.render currentGizmo currentDocument
        ]


viewCurrentGizmo : String -> String -> Html Msg
viewCurrentGizmo currentGizmo currentDocument =
    div
        [ css
            ([ left zero
             , top zero
             , width (pct 100)
             , height (pct 100)
             ]
                ++ gizmoStyles
            )
        ]
        [ viewGizmoTitleBar currentGizmo currentDocument
        , Gizmo.render currentGizmo currentDocument
        ]


onTransitionEnd : msg -> Attribute msg
onTransitionEnd message =
    on "transitionend" (Decode.succeed message)


viewGizmoTitleBar : String -> String -> Html Msg
viewGizmoTitleBar currentGizmo currentDocument =
    div
        [ css
            [ width (pct 100)
            , height (px 48)
            , paddingLeft (px 8)
            , backgroundColor palette.panel
            , color (hex "#000")
            , property "display" "grid"
            , alignItems center
            , property "grid-template-columns" "1fr 1fr 48px"
            ]
        ]
        [ viewGizmoIconAndTitle currentGizmo
        , div [ css [ fontSize (px 24) ] ] [ Gizmo.render titleGizmo currentDocument ]
        , div [ onClick <| Close currentGizmo currentDocument ] [ text "back" ]
        ]


viewFakeGizmoIcon : Html Msg
viewFakeGizmoIcon =
    div
        [ css
            [ width (px 32)
            , height (px 32)
            , backgroundColor palette.highlight
            ]
        ]
        []


viewGizmos : List Gizmo -> Html Msg
viewGizmos gizmos =
    case gizmos of
        [] ->
            div [] [ text "No gizmos yet..." ]

        _ ->
            div
                [ css
                    [ property "display" "grid"
                    , property "grid-template-columns" "1fr 1fr"
                    , property "grid-gap" "8px"
                    , padding (px 8)
                    ]
                ]
                ((gizmos |> List.map viewGizmoTile) ++ [ viewOpenGizmoTile ])


viewGizmoTile : Gizmo -> Html Msg
viewGizmoTile gizmoRecord =
    div
        [ css
            [ padding (px 8)
            , backgroundColor palette.panel
            ]
        , id gizmoRecord.gizmo
        ]
        [ viewGizmoTileTitleBar gizmoRecord.gizmo
        , viewGizmoTileDocuments gizmoRecord.gizmo gizmoRecord.documents
        , viewGizmoTileCreateDocument gizmoRecord.gizmo
        ]


viewGizmoTileTitleBar : String -> Html Msg
viewGizmoTileTitleBar gizmoDoc =
    div
        [ css
            [ displayFlex
            , alignItems center
            ]
        ]
        [ viewGizmoIconAndTitle gizmoDoc
        , div [ css [ marginLeft auto ] ]
            [ viewGizmoCloneButton gizmoDoc
            , viewGizmoRemoveButton gizmoDoc
            ]
        ]


viewGizmoIconAndTitle : String -> Html Msg
viewGizmoIconAndTitle gizmoUrl =
    div
        [ css
            [ displayFlex
            , alignItems center
            ]
        ]
        [ viewFakeGizmoIcon
        , div [ css [ marginLeft (px 10), fontSize (px 24) ] ]
            [ Gizmo.render titleGizmo gizmoUrl
            ]
        ]


viewGizmoCloneButton : String -> Html Msg
viewGizmoCloneButton clonedGizmo =
    div [ onClick <| CloneGizmo clonedGizmo ] [ text "clone" ]


viewGizmoRemoveButton : String -> Html Msg
viewGizmoRemoveButton removedGizmo =
    div [ onClick <| RemoveGizmo removedGizmo ] [ text "remove" ]


viewGizmoTileDocuments : String -> List String -> Html Msg
viewGizmoTileDocuments tiledGizmo documents =
    ul
        [ css
            [ backgroundColor (hex "#fff")
            , listStyleType none
            , height (px 100)
            , overflowY scroll
            , marginTop (px 8)
            , marginBottom (px 8)
            ]
        ]
        (case documents of
            [] ->
                [ li [] [ text "No documents" ] ]

            _ ->
                documents |> List.map (viewGizmoTileDocument tiledGizmo)
        )


viewGizmoTileDocument : String -> String -> Html Msg
viewGizmoTileDocument tiledGizmo document =
    li [ onClick <| Navigate tiledGizmo document ] [ Gizmo.render titleGizmo document ]


viewGizmoTileCreateDocument : String -> Html Msg
viewGizmoTileCreateDocument gizmoDoc =
    button [ onClick <| CreateGizmoDocument gizmoDoc ] [ text "create document" ]


viewOpenGizmoTile : Html Msg
viewOpenGizmoTile =
    div
        [ css
            [ padding (px 20)
            , backgroundColor palette.panel
            ]
        ]
        [ viewFakeGizmoIcon
        , text "Add another Gizmo"
        ]


asPx : Float -> String
asPx n =
    String.fromFloat n ++ "px"
