module TodoList exposing (Doc, Msg, State, gizmo)

import Array exposing (Array)
import Css exposing (..)
import Extra.Array as Array
import Gizmo exposing (Model)
import Html.Styled as Html exposing (Html, button, div, input, text)
import Html.Styled.Attributes as Attr exposing (checked, css, value)
import Html.Styled.Events as Events exposing (onCheck, onClick, onInput)


gizmo : Gizmo.Program State Doc Msg
gizmo =
    Gizmo.sandbox
        { init = init
        , update = update
        , view = Html.toUnstyled << view
        }


{-| Ephemeral state not saved to the doc
-}
type alias State =
    {}


type alias Todo =
    { done : Bool
    , title : String
    }


{-| Document state
-}
type alias Doc =
    { todos : Array Todo
    }


init : ( State, Doc )
init =
    ( {}
    , { todos = Array.empty
      }
    )


{-| Message type for modifying State and Doc inside update
-}
type Msg
    = SetDone Int Bool
    | SetTitle Int String
    | NewTodo


update : Msg -> Model State Doc -> ( State, Doc )
update msg { state, doc } =
    case msg of
        SetDone n done ->
            ( state, doc |> updateTodo n (setDone done) )

        SetTitle n title ->
            ( state, doc |> updateTodo n (setTitle title) )

        NewTodo ->
            ( state, doc |> pushTodo emptyTodo )


setDone : Bool -> Todo -> Todo
setDone done todo =
    { todo | done = done }


setTitle : String -> Todo -> Todo
setTitle title todo =
    { todo | title = title }


emptyTodo : Todo
emptyTodo =
    { title = ""
    , done = False
    }


updateTodo : Int -> (Todo -> Todo) -> Doc -> Doc
updateTodo n fn doc =
    { doc | todos = doc.todos |> Array.update n fn }


pushTodo : Todo -> Doc -> Doc
pushTodo todo doc =
    { doc | todos = doc.todos |> Array.push todo }


view : Model State Doc -> Html Msg
view { doc } =
    div
        [ css
            [ property "display" "grid"
            , property "grid-template-rows" "1fr auto"
            , height (pct 100)
            ]
        ]
        [ div
            [ css
                [ padding2 (px 10) (px 5)
                , borderRadius (px 3)
                ]
            ]
            (doc.todos |> Array.indexedMap viewTodo |> Array.toList)
        , viewNewButton
        ]


viewTodo : Int -> Todo -> Html Msg
viewTodo n { title, done } =
    div
        [ css
            [ property "display" "grid"
            , property "grid-template-columns" "auto 1fr"
            ]
        ]
        [ input [ Attr.type_ "checkbox", checked done, onCheck (SetDone n) ] []
        , input
            [ onInput (SetTitle n)
            , value title
            , css
                [ property "-webkit-appearance" "none"
                , border (px 0)
                , fontFamily inherit
                , fontSize inherit
                , if done then
                    textDecoration lineThrough

                  else
                    textDecoration none
                , focus
                    [ borderBottom3 (px 1) solid (hex "ddd")
                    ]
                ]
            ]
            []
        ]


viewNewButton : Html Msg
viewNewButton =
    div
        [ onClick NewTodo
        , css
            [ cursor pointer
            , textAlign center
            , padding (px 10)
            ]
        ]
        [ text "+ New Todo" ]
