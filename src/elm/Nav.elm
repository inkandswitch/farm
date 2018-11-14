port module Nav exposing (main)

import Html exposing (Html, button, div, text, textarea)
import Html.Attributes exposing (cols, rows, style, value)
import Html.Events exposing (onClick, onInput)
import Plugin


port output : Plugin.Out Doc -> Cmd msg


port input : (Plugin.In Doc -> msg) -> Sub msg


type alias Doc =
    { sourceId : String
    , id : String
    }


type alias State =
    { sourceId : Maybe String
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
      , sourceId = Nothing
      }
    , { id = ""
      , sourceId = ""
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
                ( { state | sourceId = Just sId }, doc )

        Go ->
            go state doc


go : State -> Doc -> ( State, Doc )
go state doc =
    ( { id = Nothing, sourceId = Nothing }
    , { doc
        | id = state.id |> Maybe.withDefault doc.id
        , sourceId = state.sourceId |> Maybe.withDefault doc.sourceId
      }
    )


view : Plugin.Model State Doc -> Html Msg
view { state, doc, sourceId, docId } =
    div []
        [ div
            [ style "padding" "10px"
            , style "box-shadow" "10px"
            ]
            [ text "Source id: "
            , viewInput SetSourceId
                (state.sourceId
                    |> Maybe.withDefault doc.sourceId
                )
            , text "Doc id: "
            , viewInput SetId
                (state.id
                    |> Maybe.withDefault doc.id
                )
            , button [ onClick Go ] [ text "Go" ]
            ]
        , div
            [ style "padding" "10px"
            ]
            [ if String.length doc.sourceId > 0 && String.length doc.id > 0 then
                Plugin.render doc.sourceId doc.id

              else
                text ""
            ]
        , Plugin.viewFlags { docId = docId, sourceId = sourceId }
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
