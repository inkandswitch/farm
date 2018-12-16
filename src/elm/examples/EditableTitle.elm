module EditableTitle exposing (Doc, Msg, State, gizmo)

import Css exposing (..)
import Gizmo exposing (Flags, Model)
import Html.Styled as Html exposing (..)
import Html.Styled.Attributes exposing (autofocus, css, placeholder, value)
import Html.Styled.Events exposing (..)
import Json.Decode as D


gizmo : Gizmo.Program State Doc Msg
gizmo =
    Gizmo.element
        { init = init
        , update = update
        , view = Html.toUnstyled << view
        , subscriptions = subscriptions
        }


{-| Ephemeral state not saved to the doc
-}
type alias State =
    { isEditing : Bool
    }


{-| Persisted state
-}
type alias Doc =
    { title : String
    }


{-| What are Flags?
-}
init : Flags -> ( State, Doc, Cmd Msg )
init flags =
    ( { isEditing = False }
    , { title = "" }
    , Cmd.none
    )


type Msg
    = NoOp
    | StartTitleEdit
    | ChangeTitle String
    | EndTitleEdit
    | KeyDown Int


update : Msg -> Model State Doc -> ( State, Doc, Cmd Msg )
update msg { state, doc } =
    case msg of
        NoOp ->
            ( state
            , doc
            , Cmd.none
            )

        StartTitleEdit ->
            ( { state | isEditing = True }
            , doc
            , Cmd.none
            )

        EndTitleEdit ->
            ( { state | isEditing = False }
            , doc
            , Cmd.none
            )

        ChangeTitle title ->
            ( state
            , { doc | title = title }
            , Cmd.none
            )

        KeyDown code ->
            case code of
                27 ->
                    ( { state | isEditing = False }
                    , doc
                    , Cmd.none
                    )

                13 ->
                    ( { state | isEditing = False }
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
    case state.isEditing of
        True ->
            input
                [ onBlur EndTitleEdit
                , onInput ChangeTitle
                , onKeyDown KeyDown
                , value doc.title
                , autofocus True
                , placeholder "Untitled"
                , css
                    [ border zero
                    , borderBottom3 (px 1) solid (hex "#aaa")
                    , padding zero
                    , paddingBottom (px 1)
                    , fontSize inherit
                    , fontWeight inherit
                    , lineHeight inherit
                    , outline none
                    , marginBottom (px -2)
                    ]
                ]
                []

        False ->
            div
                [ onClick StartTitleEdit
                , css
                    [ display inlineBlock
                    , padding2 (px 1) (px 0)
                    , fontSize inherit
                    , fontWeight inherit
                    ]
                ]
                [ text
                    (if String.isEmpty doc.title then
                        "Untitled"

                     else
                        doc.title
                    )
                ]


onKeyDown : (Int -> msg) -> Attribute msg
onKeyDown tagger =
    on "keydown" (D.map tagger keyCode)


subscriptions : Model State Doc -> Sub Msg
subscriptions model =
    Sub.none
