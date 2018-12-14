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
    }


init : ( State, Doc )
init =
    ( { input = "" }
    , { counter = 0
      , messages = []
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
            Maybe.withDefault "" (Dict.get "title" flags.config)
    in
    div [ css [ padding (px 24) ] ]
        [ div []
            (groupWhile (\a b -> a.author == b.author)
                (List.reverse doc.messages)
                |> List.map (viewGroup ( avatarGizmo, titleGizmo ))
            )
        , viewInput state
        ]


viewInput : State -> Html Msg
viewInput state =
    div []
        [ input [ onKeyDown KeyDown, onInput Change, value state.input ] []
        , button [ onClick Submit ] [ text "Send" ]
        ]


viewGroup : ( String, String ) -> ( Message, List Message ) -> Html Msg
viewGroup ( avatarGizmo, titleGizmo ) ( authorMessage, messages ) =
    div
        [ css
            [ displayFlex
            , flexDirection row
            , paddingLeft (px 12)
            , paddingBottom (px 10)
            ]
        ]
        [ div [] [ fromUnstyled (Gizmo.render avatarGizmo authorMessage.author) ]
        , div [ css [ displayFlex, flexDirection column, paddingLeft (px 12) ] ]
            [ div [ css [ fontWeight bold, marginBottom (px 5) ] ] [ fromUnstyled (Gizmo.render titleGizmo authorMessage.author) ]
            , div [] ((authorMessage :: messages) |> List.map viewMessage)
            ]
        ]


viewMessage : Message -> Html Msg
viewMessage { message, author } =
    div
        [ css
            [ backgroundColor (hex "")
            , marginBottom (px 5)
            ]
        ]
        [ text message ]
