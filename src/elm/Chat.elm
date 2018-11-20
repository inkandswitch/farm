module Chat exposing (Doc, Msg, State, gizmo)

import Gizmo exposing (Model)
import Html exposing (Html, button, div, text, textarea)
import Html.Attributes exposing (cols, placeholder, rows, style, value)
import Html.Events exposing (onClick, onInput)


gizmo : Gizmo.Program State Doc Msg
gizmo =
    Gizmo.sandbox
        { init = init
        , update = update
        , view = view
        }


type alias Message =
    { author : String
    , content : String
    }


type alias State =
    { typing : String
    , name : String
    }


type alias Doc =
    { messages : List Message
    }


init : ( State, Doc )
init =
    ( { typing = ""
      , name = "Anonymous"
      }
    , { messages = []
      }
    )


type Msg
    = SetMessage String
    | SetName String
    | Send


update : Msg -> Model State Doc -> ( State, Doc )
update msg { state, doc } =
    case msg of
        SetMessage str ->
            if str |> String.contains "\n" then
                send state doc

            else
                ( { state | typing = str }, doc )

        SetName str ->
            ( { state | name = str }, doc )

        Send ->
            send state doc


send : State -> Doc -> ( State, Doc )
send state doc =
    if String.trim state.typing == "" then
        ( state, doc )

    else
        ( { state | typing = "" }
        , { doc
            | messages =
                { author = state.name
                , content = state.typing
                }
                    :: doc.messages
          }
        )


view : Model State Doc -> Html Msg
view { state, doc } =
    div []
        [ text "Your name: "
        , Html.input [ onInput SetName, value state.name ] []
        , viewMessages doc.messages
        , Html.hr [] []
        , textarea [ onInput SetMessage, value state.typing, rows 1, cols 50 ] []
        , button [ onClick Send ] [ text "Send" ]
        ]


viewMessages : List Message -> Html msg
viewMessages msgs =
    case msgs of
        [] ->
            div [] [ text "No messages yet..." ]

        _ ->
            div
                [ style "display" "flex"
                , style "flex-direction" "column-reverse"
                , style "max-height" "400px"
                , style "overflow" "auto"
                ]
                (msgs |> List.map viewMessage)


viewMessage : Message -> Html msg
viewMessage { author, content } =
    div []
        [ Html.b [] [ text author ]
        , div [] [ text content ]
        ]
