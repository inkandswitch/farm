module Avatar exposing (Doc, Msg, State, gizmo)

import Css exposing (..)
import File exposing (File)
import File.Select as Select
import Gizmo
import Html
import Html.Styled exposing (..)
import Html.Styled.Attributes as Attr exposing (autofocus, css, href, placeholder, src, value)
import Html.Styled.Events exposing (keyCode, on, onBlur, onClick, onInput)
import Json.Decode as Json
import Task


gizmo : Gizmo.Program State Doc Msg
gizmo =
    Gizmo.element
        { init = init
        , update = update
        , view = view >> toUnstyled
        , subscriptions = subscriptions
        }


{-| Internal state not persisted to a document
-}
type alias State =
    { editing : Bool
    , input : Maybe String
    }


{-| Document state
-}
type alias Doc =
    { title : Maybe String
    , imageData : Maybe String
    }


{-| Message type for modifying State and Doc inside update
-}
type Msg
    = PickImage
    | GotFiles File (List File)
    | GotPreviews (List String)
    | Edit
    | Typing String
    | KeyDown Int
    | Blur
    | NoOp


init : Gizmo.Flags -> ( State, Doc, Cmd Msg )
init =
    always
        ( { editing = False
          , input = Nothing
          }
        , { title = Nothing
          , imageData = Nothing
          }
        , Cmd.none
        )


update : Msg -> Gizmo.Model State Doc -> ( State, Doc, Cmd Msg )
update msg { state, doc } =
    case Debug.log "update" msg of
        PickImage ->
            ( state, doc, Select.files [ "image/*" ] GotFiles )

        GotFiles file files ->
            ( state
            , doc
            , Task.perform GotPreviews <|
                Task.sequence <|
                    List.map File.toUrl (file :: files)
            )

        GotPreviews urls ->
            ( state
            , { doc | imageData = List.head urls }
            , Cmd.none
            )

        Edit ->
            ( { state | editing = True, input = doc.title }, doc, Cmd.none )

        KeyDown key ->
            if key == 13 then
                ( { state | editing = False, input = Nothing }
                , { doc | title = state.input }
                , Cmd.none
                )

            else if key == 27 then
                ( { state | editing = False, input = Nothing }
                , doc
                , Cmd.none
                )

            else
                ( state, doc, Cmd.none )

        Blur ->
            ( { state | editing = False, input = Nothing }
            , doc
            , Cmd.none
            )

        Typing typing ->
            ( { state | input = Just typing }, doc, Cmd.none )

        NoOp ->
            ( state, doc, Cmd.none )


subscriptions : Gizmo.Model State Doc -> Sub Msg
subscriptions { state, doc } =
    Sub.none


onKeyDown : (Int -> msg) -> Attribute msg
onKeyDown tagger =
    on "keydown" (Json.map tagger keyCode)


view : Gizmo.Model State Doc -> Html Msg
view { state, doc } =
    let
        _ =
            Debug.log "view" ( state, doc )
    in
    div []
        [ viewImage doc.imageData
        , viewEditableText doc.title state.input state.editing
        ]


viewImage : Maybe String -> Html Msg
viewImage imageData =
    div []
        [ case imageData of
            Just data ->
                img
                    [ css
                        [ width (px 48)
                        , borderRadius (px 24)
                        ]
                    , src data
                    ]
                    []

            Nothing ->
                button [ onClick PickImage ] [ text "Import Image" ]
        ]


viewEditableText : Maybe String -> Maybe String -> Bool -> Html Msg
viewEditableText contents typing editing =
    case editing of
        False ->
            div [ onClick Edit ]
                [ case contents of
                    Nothing ->
                        text "[Mysterious Stranger]"

                    Just thevalue ->
                        text thevalue
                ]

        True ->
            div []
                [ input
                    [ onKeyDown KeyDown
                    , onBlur Blur
                    , onInput Typing
                    , autofocus True
                    , case typing of
                        Just v ->
                            value v

                        Nothing ->
                            placeholder "Set a name..."
                    ]
                    []
                ]
