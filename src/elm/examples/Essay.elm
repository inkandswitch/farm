module Article exposing (Doc, Msg, State, gizmo)

import Colors exposing (..)
import Css exposing (..)
import Css.Global as G
import Gizmo exposing (Flags, Model)
import Html.Styled as Html exposing (..)
import Html.Styled.Attributes exposing (class, css, placeholder, value)
import Html.Styled.Events exposing (..)
import Json.Encode as Json
import Markdown


markdownStyles =
    [ G.class "MarkdownContainer"
        [ G.descendants
            [ G.everything
                [ fontFamilies [ "system-ui" ]
                ]
            , G.each
                [ G.typeSelector "h1"
                , G.typeSelector "h2"
                , G.typeSelector "h3"
                ]
                [ marginTop (px 24)
                , marginBottom (px 16)
                , lineHeight (num 1.25)
                ]
            , G.typeSelector "h1"
                [ fontSize (Css.em 2)
                , fontWeight bold
                ]
            , G.typeSelector "h2"
                [ fontSize (Css.em 1.5)
                , fontWeight bold
                ]
            , G.typeSelector "h2"
                [ fontSize (Css.em 1.25)
                , fontWeight bold
                ]
            , G.typeSelector "p"
                [ marginTop (px 0)
                , marginBottom (px 16)
                ]
            , G.each
                [ G.typeSelector "ul"
                , G.typeSelector "ol"
                ]
                [ paddingLeft (Css.em 2)
                , marginTop (px 0)
                , marginBottom (px 0)
                ]
            , G.typeSelector "ul"
                [ listStyle disc
                ]
            , G.typeSelector "li"
                [ property "word-wrap" "break-all"
                ]
            , G.selector "li+li"
                [ marginTop (Css.em 0.25)
                ]
            , G.typeSelector "em"
                [ fontStyle italic
                ]
            , G.typeSelector "bold"
                [ fontWeight bold
                ]
            ]
        ]
    ]


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
    { isEditing : Bool
    }


{-| Document state
-}
type alias Doc =
    { title : String
    , body : String
    }


init : Flags -> ( State, Doc, Cmd Msg )
init flags =
    ( { isEditing = False }
    , { title = "", body = "" }
    , Cmd.none
    )


{-| Message type for modifying State and Doc inside update
-}
type Msg
    = NoOp
    | SetBody String
    | ToggleEdit


update : Msg -> Model State Doc -> ( State, Doc, Cmd Msg )
update msg { state, doc } =
    case msg of
        NoOp ->
            ( state
            , doc
            , Cmd.none
            )

        SetBody body ->
            ( state
            , { doc | body = body }
            , Cmd.none
            )

        ToggleEdit ->
            ( { state | isEditing = not state.isEditing }
            , doc
            , Cmd.none
            )


updateTitleEmitValue : String -> String -> Json.Value
updateTitleEmitValue old new =
    Json.object
        [ ( "old", Json.string old )
        , ( "new", Json.string new )
        ]


textColor =
    hex "#333"


view : Model State Doc -> Html Msg
view { state, doc } =
    div
        [ css
            [ displayFlex
            , flexDirection column
            , padding (px 10)
            , margin (px 10)
            , backgroundColor (hex "fff")
            , fontFamilies [ "system-ui" ]
            ]
        ]
        [ div
            [ css
                [ display block
                , position absolute
                , right (px 10)
                , top (px 10)
                ]
            ]
            [ span
                [ onClick ToggleEdit
                , css
                    [ color (hex hotPink)
                    , cursor pointer
                    , padding (px 2)
                    , hover
                        [ color (hex darkerHotPink)
                        ]
                    ]
                ]
                [ text
                    (if state.isEditing then
                        "View"

                     else
                        "Edit"
                    )
                ]
            ]
        , if state.isEditing then
            textarea
                [ css
                    [ flexGrow (num 1)
                    , border zero
                    , width (pct 100)
                    , height (vh 80)
                    , fontSize (Css.em 1)
                    , fontFamilies ["Lucida Console"]
                    , color textColor
                    ]
                , onInput SetBody
                , value doc.body
                , placeholder "Your note here..."
                ]
                []

          else
            div
                [ class "MarkdownContainer"
                ]
                [ G.global markdownStyles
                , Html.fromUnstyled <| Markdown.toHtml [] doc.body
                ]
        ]


subscriptions : Model State Doc -> Sub Msg
subscriptions model =
    Sub.none
