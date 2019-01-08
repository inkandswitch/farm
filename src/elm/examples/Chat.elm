module Chat exposing (Doc, Msg, State, gizmo)

import Css exposing (..)
import Dict
import Gizmo exposing (Flags, Model)
import Html.Styled as Html exposing (..)
import Html.Styled.Attributes as Attr exposing (autofocus, css, href, placeholder, src, value)
import Html.Styled.Events exposing (keyCode, on, onBlur, onClick, onInput)
import Json.Decode as Json
import List.Extra exposing (groupWhile)
import Task
import Time


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
    { input : String
    , zone : Time.Zone
    }


type alias Message =
    { author : String
    , message : String
    , time : Int
    }


{-| Document state
-}
type alias Doc =
    { counter : Int
    , messages : List Message
    , title : String
    }


init : Flags -> ( State, Doc, Cmd Msg )
init flags =
    ( { input = ""
      , zone = Time.utc
      }
    , { counter = 0
      , messages = []
      , title = "Untitled Chat"
      }
    , Time.here |> Task.perform SetZone
    )


{-| Message type for modifying State and Doc inside update
-}
type Msg
    = Change String
    | Submit
    | OnTime Time.Posix
    | KeyDown Int
    | SetZone Time.Zone


onKeyDown : (Int -> msg) -> Attribute msg
onKeyDown tagger =
    on "keydown" (Json.map tagger keyCode)


update : Msg -> Model State Doc -> ( State, Doc, Cmd Msg )
update msg { flags, state, doc } =
    case msg of
        Change typing ->
            ( { state | input = typing }, doc, Cmd.none )

        Submit ->
            ( state
            , doc
            , Task.perform OnTime Time.now
            )

        SetZone zone ->
            ( { state | zone = zone }, doc, Cmd.none )

        OnTime time ->
            ( { state | input = "" }
            , { doc
                | messages =
                    { author = flags.self
                    , message = state.input
                    , time = Time.posixToMillis time
                    }
                        :: doc.messages
              }
            , Cmd.none
            )

        KeyDown key ->
            if key == 13 then
                ( state
                , doc
                , Task.perform OnTime Time.now
                )

            else
                ( state, doc, Cmd.none )


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
                , flexDirection columnReverse
                , overflow auto
                ]
            ]
            (doc.messages
                |> groupWhile (\a b -> a.author == b.author)
                |> List.map (viewGroup state ( avatarGizmo, titleGizmo ))
            )
        , inputBar state
        ]


titleBar : List (Html Msg) -> Html Msg
titleBar content =
    div
        [ css
            [ borderBottom3 (px 1) solid (hex "#ddd")
            , padding2 (px 10) (px 20)
            , fontSize (Css.em 1.1)
            , fontWeight bold
            , boxShadow4 (px 0) (px 0) (px 5) (rgba 0 0 0 0.2)
            ]
        ]
        ([ span
            [ css
                [ color (hex "#ff69b4")
                , marginRight (px 1)
                ]
            ]
            [ text "#"
            ]
         ]
            ++ content
        )


inputBar : State -> Html Msg
inputBar state =
    div
        [ css
            [ displayFlex
            , margin (px 10)
            , border3 (px 2) solid (hex "#ccc")
            , borderRadius (px 3)
            , padding (px 10)
            , flexShrink (int 0)
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


viewGroup : State -> ( String, String ) -> ( Message, List Message ) -> Html Msg
viewGroup state ( avatarGizmo, titleGizmo ) ( authorMessage, messages ) =
    div
        [ css
            [ displayFlex
            , flexDirection row
            , paddingBottom (px 10)
            , flexShrink (int 0)
            ]
        ]
        [ fromUnstyled <| Gizmo.render avatarGizmo authorMessage.author
        , div
            [ css
                [ displayFlex
                , flexDirection column
                , marginLeft (px 10)
                ]
            ]
            [ div
                [ css
                    [ fontWeight bold
                    , marginBottom (px 5)
                    , displayFlex
                    , alignItems center
                    ]
                ]
                [ fromUnstyled <| Gizmo.render titleGizmo authorMessage.author
                , viewTime state.zone authorMessage.time
                ]
            , div
                [ css
                    [ displayFlex
                    , flexDirection columnReverse
                    ]
                ]
                ((authorMessage :: messages) |> List.map viewMessage)
            ]
        ]


viewTime : Time.Zone -> Int -> Html Msg
viewTime zone time =
    span
        [ css
            [ color (hex "#777")
            , fontSize (Css.em 0.9)
            , marginLeft (px 5)
            , fontWeight lighter
            ]
        ]
        [ text (displayTime zone time) ]


viewMessage : Message -> Html Msg
viewMessage { message, author } =
    div
        [ css
            [ marginBottom (px 5)
            , flexShrink (int 0)
            ]
        ]
        [ text message ]


displayTime : Time.Zone -> Int -> String
displayTime zone time =
    let
        posix =
            Time.millisToPosix time
    in
    String.fromInt (Time.toHour zone posix) ++ ":" ++ String.fromInt (Time.toMinute zone posix)


subscriptions : Model State Doc -> Sub Msg
subscriptions model =
    Sub.none
