port module Example exposing (main)

import Html exposing (Html, button, div, text, textarea)
import Html.Attributes exposing (cols, placeholder, rows, style, value)
import Html.Events exposing (onClick, onInput)
import Plugin


type alias State =
    { typing : String
    , name : String
    }


type alias Message =
    { author : String
    , content : String
    }


type alias Doc =
    { messages : List Message
    }


port output : Doc -> Cmd msg


port input : (Doc -> msg) -> Sub msg


type Msg
    = SetMessage String
    | SetName String
    | Send


main : Plugin.Program State Doc Msg
main =
    Plugin.element
        { init = init
        , update = update
        , view = view
        , input = input
        , output = output
        }


init : ( State, Doc )
init =
    ( { typing = ""
      , name = "Anonymous"
      }
    , { messages = []
      }
    )


update : Msg -> Plugin.Model State Doc -> ( State, Doc )
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
    ( { state | typing = "" }
    , { doc
        | messages =
            { author = state.name
            , content = state.typing
            }
                :: doc.messages
      }
    )


view : Plugin.Model State Doc -> Html Msg
view { docId, sourceId, state, doc } =
    div []
        [ text "Your name: "
        , Html.input [ onInput SetName, value state.name ] []
        , viewMessages doc.messages
        , Html.hr [] []
        , textarea [ onInput SetMessage, value state.typing, rows 1, cols 50 ] []
        , button [ onClick Send ] [ text "Send" ]
        , Html.hr [] []
        , Html.pre []
            [ Html.b [] [ text "docId: " ]
            , text docId
            ]
        , Html.pre []
            [ Html.b [] [ text "sourceId: " ]
            , text sourceId
            ]
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
