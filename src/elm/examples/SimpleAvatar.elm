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


defaultName : String
defaultName =
    "Mysterious Strange"


hotPink =
    hex "#ff69b4"


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

        NoOp ->
            ( state, doc, Cmd.none )


subscriptions : Gizmo.Model State Doc -> Sub Msg
subscriptions { state, doc } =
    Sub.none


view : Gizmo.Model State Doc -> Html Msg
view { state, doc } =
    div []
        [ case doc.imageData of
            Just data ->
                imageAvatar data

            Nothing ->
                case doc.title of
                    Just name ->
                        textAvatar <| defaultIfEmpty "Mysterious Stanger" name

                    Nothing ->
                        textAvatar "Mysterious Stranger"
        ]


imageAvatar : String -> Html Msg
imageAvatar imageSrc =
    img
        [ css
            [ width (px 36)
            , borderRadius (pct 50)
            ]
        , src imageSrc
        ]
        []


textAvatar : String -> Html Msg
textAvatar name =
    button
        [ onClick PickImage
        , css
            [ border zero
            , width (px 36)
            , height (px 36)
            , borderRadius (pct 50)
            , border3 (px 1) solid hotPink
            , color hotPink
            ]
        ]
        [ text <| initials name
        ]


initials : String -> String
initials name =
    name
        |> String.words
        |> List.map (String.left 1)
        |> String.join ""


defaultIfEmpty : String -> String -> String
defaultIfEmpty default str =
    if String.isEmpty str then
        default

    else
        str
