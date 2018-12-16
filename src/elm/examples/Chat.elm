module Chat exposing (Doc, Msg, State, gizmo)

import Css exposing (..)
import Dict
import Gizmo exposing (Model)
import Html
import Html.Styled exposing (..)
import Html.Styled.Attributes as Attr exposing (autofocus, css, href, placeholder, src, value)
import Html.Styled.Events exposing (keyCode, on, onBlur, onClick, onInput)
import Json.Decode as Json
import List.Extra exposing (groupWhile)


gizmo : Gizmo.Program State Doc Msg
gizmo =
    Gizmo.sandbox
        { init = init
        , update = update
        , view = toUnstyled << view
        }


{-| Ephemeral state not saved to the doc
-}
type alias State =
    { input : String
    }


type alias Message =
    { author : String
    , message : String
    }


{-| Document state
-}
type alias Doc =
    { counter : Int
    , messages : List Message
    , title : String
    }


init : ( State, Doc )
init =
    ( { input = "" }
    , { counter = 0
      , messages = []
      , title = "Untitled Chat"
      }
    )


{-| Message type for modifying State and Doc inside update
-}
type Msg
    = Change String
    | Submit
    | KeyDown Int


onKeyDown : (Int -> msg) -> Attribute msg
onKeyDown tagger =
    on "keydown" (Json.map tagger keyCode)


update : Msg -> Model State Doc -> ( State, Doc )
update msg { flags, state, doc } =
    case msg of
        Change typing ->
            ( { state | input = typing }, doc )

        Submit ->
            ( { state | input = "" }
            , { doc
                | messages =
                    { author = flags.self
                    , message = state.input
                    }
                        :: doc.messages
              }
            )

        KeyDown key ->
            if key == 13 then
                ( { state | input = "" }
                , { doc | messages = { author = flags.self, message = state.input } :: doc.messages }
                )

            else
                ( state, doc )


view : Model State Doc -> Html Msg
view { flags, state, doc } =
    let
        avatarGizmo =
            Maybe.withDefault "" (Dict.get "avatar" flags.config)

        titleGizmo =
            Maybe.withDefault "" (Dict.get "editableTitle" flags.config)
    in
    div
        [ css
            [ displayFlex
            , flexDirection column
            , fontFamilies [ "system-ui" ]
            , height (pct 100)
            , width (pct 100)
            ]
        ]
        [ titleBar
            [ fromUnstyled <| Gizmo.render titleGizmo flags.data
            ]
        , div
            [ css
                [ flexGrow (int 1)
                , padding (px 20)
                , displayFlex
                , fontSize (Css.em 0.9)
                , flexDirection column
                , overflowY scroll
                ]
            ]
            (groupWhile (\a b -> a.author == b.author)
                (List.reverse doc.messages)
                |> List.map (viewGroup ( avatarGizmo, titleGizmo ))
            )
        , inputBar state
        ]


titleBar : List (Html Msg) -> Html Msg
titleBar =
    div
        [ css
            [ borderBottom3 (px 1) solid (hex "#ddd")
            , padding (px 20)
            , fontSize (Css.em 1.1)
            , fontWeight bold
            , boxShadow4 (px 0) (px 0) (px 5) (rgba 0 0 0 0.2)
            ]
        ]


inputBar : State -> Html Msg
inputBar state =
    div
        [ css
            [ displayFlex
            , margin (px 10)
            , border3 (px 2) solid (hex "#ccc")
            , borderRadius (px 3)
            , padding (px 10)
            ]
        ]
        [ input
            [ onKeyDown KeyDown
            , onInput Change
            , value state.input
            , css
                [ flexGrow (int 1)
                , border zero
                , fontSize (Css.em 1)
                ]
            ]
            []
        , button
            [ onClick Submit
            , css
                [ border zero
                , margin (px -10)
                , padding (px 10)
                , fontSize (Css.em 0.9)
                , fontWeight (int 600)
                , borderLeft3 (px 2) solid (hex "#ccc")
                , color (hex "#777")
                ]
            ]
            [ text "Send"
            ]
        ]


viewGroup : ( String, String ) -> ( Message, List Message ) -> Html Msg
viewGroup ( avatarGizmo, titleGizmo ) ( authorMessage, messages ) =
    div
        [ css
            [ displayFlex
            , flexDirection row
            , paddingBottom (px 10)
            ]
        ]
        [ div
            [ css
                [ displayFlex
                , flexDirection column
                ]
            ]
            [ div
                [ css
                    [ fontWeight bold
                    , marginBottom (px 5)
                    ]
                ]
                [ fromUnstyled <| Gizmo.render titleGizmo authorMessage.author
                ]
            , div
                []
                ((authorMessage :: messages) |> List.map viewMessage)
            ]
        ]


viewMessage : Message -> Html Msg
viewMessage { message, author } =
    div
        [ css
            [ marginBottom (px 5)
            ]
        ]
        [ text message ]
