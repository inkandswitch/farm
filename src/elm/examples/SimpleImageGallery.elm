module SimpleImageGallery exposing (Doc, Msg, State, gizmo)

import File exposing (File)
import File.Select as Select
import Gizmo exposing (Flags, Model)
import Html exposing (..)
import Html.Attributes exposing (autofocus, placeholder, src, style, value)
import Html.Events exposing (..)
import Json.Decode as D
import Maybe
import Task


titleGizmo : String
titleGizmo =
    "hypermerge:/DS7HfFUVj2UP8wit1iQDjKtc2MB4NnQxm7uvfDaLA373"


gizmo : Gizmo.Program State Doc Msg
gizmo =
    Gizmo.element
        { init = init
        , update = update
        , view = view
        , subscriptions = subscriptions
        }


{-| Ephemeral state not saved to the doc
-}
type alias State =
    { hover : Bool
    , zoomTarget : Maybe String
    , editingTitle : Bool
    }


{-| Persisted state
-}
type alias Doc =
    { images : List String
    , title : String
    }


{-| What are Flags?
-}
init : Flags -> ( State, Doc, Cmd Msg )
init flags =
    ( { hover = False, zoomTarget = Nothing, editingTitle = False }
    , { images = [], title = "Image Gallery" }
    , Cmd.none
    )


{-| Message type for modifying State and Doc inside update
-}
type Msg
    = Zoom String
    | ZoomOut
    | OnClick
    | DragEnter
    | DragLeave
    | StartTitleEdit
    | ChangeTitle String
    | EndTitleEdit
    | KeyDown Int
    | GotFiles File (List File)
    | GotPreviews (List String)


update : Msg -> Model State Doc -> ( State, Doc, Cmd Msg )
update msg { state, doc } =
    case msg of
        OnClick ->
            ( state
            , doc
            , Cmd.none
            )

        Zoom image ->
            ( { state | zoomTarget = Just image }
            , doc
            , Cmd.none
            )

        ZoomOut ->
            ( { state | zoomTarget = Nothing }
            , doc
            , Cmd.none
            )

        DragEnter ->
            ( { state | hover = True }
            , doc
            , Cmd.none
            )

        DragLeave ->
            ( { state | hover = False }
            , doc
            , Cmd.none
            )

        GotFiles file files ->
            ( { state | hover = False }
            , doc
            , Task.perform GotPreviews <|
                Task.sequence <|
                    List.map File.toUrl (file :: files)
            )

        GotPreviews url ->
            ( state
            , case List.head url of
                Nothing ->
                    doc

                Just data ->
                    { doc | images = doc.images ++ [ data ] }
            , Cmd.none
            )

        StartTitleEdit ->
            ( { state | editingTitle = True }
            , doc
            , Cmd.none
            )

        ChangeTitle title ->
            ( state
            , { doc | title = title }
            , Cmd.none
            )

        EndTitleEdit ->
            ( { state | editingTitle = False }
            , doc
            , Cmd.none
            )

        KeyDown keyCode ->
            case keyCode of
                13 ->
                    ( { state | editingTitle = False }
                    , doc
                    , Cmd.none
                    )

                27 ->
                    ( { state | editingTitle = False }
                    , doc
                    , Cmd.none
                    )

                _ ->
                    ( state
                    , doc
                    , Cmd.none
                    )


view : Model State Doc -> Html Msg
view { flags, state, doc } =
    div
        [ style "height" "100%"
        , style "width" "100%"
        , style "minHeight" "200px"
        , onClick OnClick
        , hijackOn "dragenter" (D.succeed DragEnter)
        , hijackOn "dragover" (D.succeed DragEnter)
        , hijackOn "dragleave" (D.succeed DragLeave)
        , hijackOn "drop" dropDecoder
        ]
        [ div
            [ style "borderBottom" "1px solid #ddd"
            , style "padding" "20px"
            , style "marginBottom" "20"
            , style "textAlign" "center"
            , style "fontFamily" "system-ui"
            ]
            [ viewTitle doc.title state.editingTitle ]
        , div
            [ style "display" "grid"
            , style "gridTemplateColumns" "repeat(auto-fit, 200px)"
            , style "gap" "1rem"
            , style "height" "100%"
            , style "width" "100%"
            ]
            (doc.images |> List.map (viewImage False))
        , case state.zoomTarget of
            Nothing ->
                if state.hover then
                    viewDropOverlay

                else
                    Html.text ""

            Just url ->
                viewZoomTarget url
        ]


viewTitle : String -> Bool -> Html Msg
viewTitle title isEditing =
    case isEditing of
        True ->
            input
                [ onBlur EndTitleEdit
                , onInput ChangeTitle
                , onKeyDown KeyDown
                , value title
                , autofocus True
                , placeholder "Untitled"
                , style "border" "none"
                , style "margin" "0"
                , style "padding" "0"
                , style "fontSize" "1em"
                , style "outline" "none"
                , style "textAlign" "center"
                ]
                []

        False ->
            div
                [ onClick StartTitleEdit
                , style "display" "inline-block"
                , style "padding" "1px 0"
                , style "minHeight" "10px"
                ]
                [ text
                    (if String.isEmpty title then
                        "Untitled"

                     else
                        title
                    )
                ]


viewDropOverlay : Html Msg
viewDropOverlay =
    div
        [ style "position" "absolute"
        , style "top" "0"
        , style "left" "0"
        , style "right" "0"
        , style "bottom" "0"
        , style "opacity" "0.75"
        , style "backgroundColor" "#aaa"
        ]
        []


viewZoomTarget : String -> Html Msg
viewZoomTarget url =
    div
        [ onClick ZoomOut
        , style "position" "absolute"
        , style "top" "0"
        , style "left" "0"
        , style "right" "0"
        , style "bottom" "0"
        ]
        [ div
            [ style "position" "absolute"
            , style "top" "0"
            , style "right" "0"
            , style "bottom" "0"
            , style "left" "0"
            , style "opacity" "0.75"
            , style "backgroundColor" "#333"
            ]
            []
        , div
            [ style "position" "absolute"
            , style "top" "0"
            , style "left" "0"
            , style "right" "0"
            , style "bottom" "0"
            , style "background-image" ("url('" ++ url ++ "')")
            , style "background-position" "center"
            , style "background-repeat" "no-repeat"
            , style "background-size" "contain"
            ]
            []
        ]


viewImage : Bool -> String -> Html Msg
viewImage zoomed url =
    div []
        [ img [ src url, style "width" "100%", onClick (Zoom url) ] []
        ]


dropDecoder : D.Decoder Msg
dropDecoder =
    D.at [ "dataTransfer", "files" ] (D.oneOrMore GotFiles File.decoder)


hijackOn : String -> D.Decoder msg -> Attribute msg
hijackOn event decoder =
    preventDefaultOn event (D.map hijack decoder)


hijack : msg -> ( msg, Bool )
hijack msg =
    ( msg, True )


onKeyDown : (Int -> msg) -> Attribute msg
onKeyDown tagger =
    on "keydown" (D.map tagger keyCode)


subscriptions : Model State Doc -> Sub Msg
subscriptions model =
    Sub.none
