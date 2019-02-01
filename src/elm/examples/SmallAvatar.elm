module SmallAvatar exposing (Doc, Msg, State, gizmo)

import Colors
import Css exposing (..)
import File exposing (File)
import File.Select as Select
import Gizmo
import Html
import Html.Styled exposing (..)
import Html.Styled.Attributes as Attr exposing (autofocus, css, href, placeholder, src, title, value)
import Json.Decode as Json
import Task


defaultName : String
defaultName =
    "Mysterious Stranger"


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
    {}


{-| Document state
-}
type alias Doc =
    { title : Maybe String
    , imageData : Maybe String
    }


{-| Message type for modifying State and Doc inside update
-}
type Msg
    = NoOp


init : Gizmo.Flags -> ( State, Doc, Cmd Msg )
init =
    always
        ( {}
        , { title = Nothing
          , imageData = Nothing
          }
        , Cmd.none
        )


update : Msg -> Gizmo.Model State Doc -> ( State, Doc, Cmd Msg )
update msg { state, doc } =
    case msg of
        NoOp ->
            ( state, doc, Cmd.none )


subscriptions : Gizmo.Model State Doc -> Sub Msg
subscriptions { state, doc } =
    Sub.none


view : Gizmo.Model State Doc -> Html Msg
view { state, doc } =
    let
        name =
            Maybe.withDefault "Mysterious Stranger" doc.title
    in
    case doc.imageData of
        Just data ->
            imageAvatar name data

        Nothing ->
            textAvatar <| defaultIfEmpty "Mysterious Stanger" name


imageAvatar : String -> String -> Html Msg
imageAvatar name imageSrc =
    div
        [ title name
        , css
            [ width (px 15)
            , height (px 15)
            , backgroundImage (url imageSrc)
            , backgroundPosition center
            , backgroundRepeat noRepeat
            , backgroundSize contain
            ]
        ]
        []


textAvatar : String -> Html Msg
textAvatar name =
    div
        [ title name
        , css
            [ width (px 15)
            , height (px 15)
            , borderRadius (pct 50)
            , border3 (px 1) solid (hex Colors.primary)
            , color (hex Colors.primary)
            , padding (px 0)
            , displayFlex
            , alignItems center
            , justifyContent center
            , fontSize (Css.em 0.5)
            , overflow hidden
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
