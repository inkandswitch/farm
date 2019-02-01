module Authors exposing (Doc, Msg, State, gizmo)

import Colors
import Config
import Css exposing (..)
import Gizmo
import Html.Styled as Html exposing (..)


maxDisplayAttr =
    "max"


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
    { authors : Maybe (List String)
    }


{-| Message type for modifying State and Doc inside update
-}
type Msg
    = NoOp


init : Gizmo.Flags -> ( State, Doc, Cmd Msg )
init =
    always
        ( {}
        , { authors = Nothing
          }
        , Cmd.none
        )


update : Msg -> Gizmo.Model State Doc -> ( State, Doc, Cmd Msg )
update msg { state, doc } =
    case msg of
        NoOp ->
            ( state
            , doc
            , Cmd.none
            )


subscriptions : Gizmo.Model State Doc -> Sub Msg
subscriptions { state, doc } =
    Sub.none


view : Gizmo.Model State Doc -> Html Msg
view { flags, state, doc } =
    case doc.authors of
        Just authors ->
            viewAuthors authors

        Nothing ->
            viewEmpty


viewAuthors : List String -> Html Msg
viewAuthors authors =
    if List.length authors > 3 then
        div
            []
            [ viewAuthorList <| List.take 3 authors
            , viewRemaining 3 authors
            ]

    else
        viewAuthorList authors


viewAuthorList : List String -> Html Msg
viewAuthorList authors =
    div
        []
        (List.map viewAuthor authors)


viewAuthor : String -> Html Msg
viewAuthor author =
    Html.fromUnstyled <| Gizmo.render Config.smallAvatar author


viewRemaining : Int -> List String -> Html Msg
viewRemaining max authors =
    let
        remaining =
            List.length authors - max
    in
    text <| "& " ++ String.fromInt remaining ++ " more"


viewEmpty : Html Msg
viewEmpty =
    Html.text "Unknown author"
