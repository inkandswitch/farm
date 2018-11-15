port module Nav exposing (main)

import Html exposing (Html, button, div, text, textarea)
import Html.Attributes exposing (cols, rows, style, value)
import Html.Events exposing (onClick, onInput)
import Plugin


port output : Plugin.Out Doc -> Cmd msg


port input : (Plugin.In Doc -> msg) -> Sub msg


type alias Doc =
    { code : String
    , data : String
    }


type alias State =
    { code : Maybe String
    , data : Maybe String
    }


type Msg
    = SetData String
    | SetCode String
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
    ( { data = Nothing
      , code = Nothing
      }
    , { data = ""
      , code = ""
      }
    )


update : Msg -> Plugin.Model State Doc -> ( State, Doc )
update msg { state, doc } =
    case msg of
        SetData data ->
            if data |> String.contains "\n" then
                go state doc

            else
                ( { state | data = Just data }, doc )

        SetCode sId ->
            if sId |> String.contains "\n" then
                go state doc

            else
                ( { state | code = Just sId }, doc )

        Go ->
            go state doc


go : State -> Doc -> ( State, Doc )
go state doc =
    ( { data = Nothing, code = Nothing }
    , { doc
        | data = state.data |> Maybe.withDefault doc.data
        , code = state.code |> Maybe.withDefault doc.code
      }
    )


view : Plugin.Model State Doc -> Html Msg
view { state, doc, code, data } =
    div []
        [ div
            [ style "padding" "10px"
            , style "box-shadow" "10px"
            ]
            [ text "code: "
            , viewInput SetCode
                (state.code
                    |> Maybe.withDefault doc.code
                )
            , text "data: "
            , viewInput SetData
                (state.data
                    |> Maybe.withDefault doc.data
                )
            , button [ onClick Go ] [ text "Go" ]
            ]
        , div
            [ style "padding" "10px"
            ]
            [ if String.length doc.code > 0 && String.length doc.data > 0 then
                Plugin.render doc.code doc.data

              else
                text ""
            ]
        , Plugin.viewFlags { data = data, code = code }
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
