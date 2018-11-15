port module Nav exposing (main)

import Html exposing (Html, button, div, text, textarea)
import Html.Attributes exposing (cols, rows, style, value)
import Html.Events exposing (onClick, onInput)
import Plugin


port output : Plugin.Out Doc -> Cmd msg


port input : (Plugin.In Doc -> msg) -> Sub msg


type alias Doc =
    { src : String
    , id : String
    }


type alias State =
    { src : Maybe String
    , id : Maybe String
    }


type Msg
    = SetId String
    | SetSourceId String
    | Go


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
    ( { id = Nothing
      , src = Nothing
      }
    , { id = ""
      , src = ""
      }
    )


update : Msg -> Plugin.Model State Doc -> ( State, Doc )
update msg { state, doc } =
    case msg of
        SetId id ->
            if id |> String.contains "\n" then
                go state doc

            else
                ( { state | id = Just id }, doc )

        SetSourceId sId ->
            if sId |> String.contains "\n" then
                go state doc

            else
                ( { state | src = Just sId }, doc )

        Go ->
            go state doc


go : State -> Doc -> ( State, Doc )
go state doc =
    ( { id = Nothing, src = Nothing }
    , { doc
        | id = state.id |> Maybe.withDefault doc.id
        , src = state.src |> Maybe.withDefault doc.src
      }
    )


view : Plugin.Model State Doc -> Html Msg
view { state, doc, src, docUrl } =
    div []
        [ div
            [ style "padding" "10px"
            , style "box-shadow" "10px"
            ]
            [ text "src: "
            , viewInput SetSourceId
                (state.src
                    |> Maybe.withDefault doc.src
                )
            , text "docUrl: "
            , viewInput SetId
                (state.id
                    |> Maybe.withDefault doc.id
                )
            , button [ onClick Go ] [ text "Go" ]
            ]
        , div
            [ style "padding" "10px"
            ]
            [ if String.length doc.src > 0 && String.length doc.id > 0 then
                Plugin.render doc.src doc.id

              else
                text ""
            ]
        , Plugin.viewFlags { docUrl = docUrl, src = src }
        ]


viewInput : (String -> msg) -> String -> Html msg
viewInput mkMsg val =
    textarea
        [ rows 1
        , cols 80
        , onInput mkMsg
        , value val
        ]
        []
