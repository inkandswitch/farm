module TodoList exposing (Doc, Msg, State, gizmo)

import Array exposing (Array)
import Extra.Array exposing (remove)
import Css exposing (..)
import Extra.Array as Array
import Gizmo exposing (Flags, Model)
import Html.Styled as Html exposing (Html, button, div, input, text)
import Html.Styled.Attributes as Attr exposing (checked, css, value, id)
import Html.Styled.Events as Events exposing (onCheck, onClick, onInput)
import Keyboard exposing (Combo(..))
import Browser.Dom as Dom
import Task exposing (Task)


import Random exposing (Generator, list, int)

randomString : Int -> Generator String
randomString stringLength =
  Random.map String.fromList <| Random.list stringLength randomChar

randomChar : Generator Char
randomChar =
    Random.map (\n -> Char.fromCode (n + 65)) (int 0 51)

gizmo : Gizmo.Program State Doc Msg
gizmo =
    Gizmo.element
        { init = init
        , update = update
        , view = view
        , subscriptions = subscriptions
        }

subscriptions : Model State Doc -> Sub Msg
subscriptions { state } =
    Sub.none

{-| Ephemeral state not saved to the doc
-}
type alias State =
    {}

type alias Todo =
    { done : Bool
    , id : String
    , title : String
    }


{-| Document state
-}
type alias Doc =
    { todos : Array Todo
    }


init : Flags -> ( State, Doc, Cmd Msg )
init flags =
    ( {}
    , { todos = Array.empty
      }
    , Cmd.none
    )

{-| Message type for modifying State and Doc inside update
-}
type Msg
    = SetDone String Bool
    | SetTitle String String
    | CreateTodo
    | NewTodo String
    | DeleteTodo String
    | NoOp


update : Msg -> Model State Doc -> ( State, Doc, Cmd Msg )
update msg { state, doc } =
    case msg of
        SetDone id done ->
            ( state, doc |> updateTodo id (setDone done), Cmd.none )

        SetTitle id title ->
            ( state, doc |> updateTodo id (setTitle title), Cmd.none )


        CreateTodo -> 
            ( state, doc, Random.generate NewTodo (randomString 7))

        NewTodo id ->
            let newTodo = emptyTodo id
            in
            ( state
            , doc |> pushTodo newTodo 
            , Task.attempt (\_ -> NoOp) (focusTodo newTodo.id)
            )

        DeleteTodo id ->
            ( state
            , doc |> Debug.log "delete" (deleteTodo id)
            , Task.attempt (\_ -> NoOp) (focusTodo id)
            )

        NoOp -> ( state, doc, Cmd.none )



setDone : Bool -> Todo -> Todo
setDone done todo =
    { todo | done = done }


setTitle : String -> Todo -> Todo
setTitle title todo =
    { todo | title = title }


emptyTodo : String -> Todo
emptyTodo id =
    { title = ""
    , id = id
    , done = False
    }

updateElement : String -> (Todo -> Todo) -> Array Todo -> Array Todo
updateElement id fn list =
  let
    toggle todo =
      if todo.id == id then
        fn todo
      else
        todo
  in
    Array.map toggle list

updateTodo : String -> (Todo -> Todo) -> Doc -> Doc
updateTodo id fn doc =
    { doc | todos = doc.todos |> updateElement id fn }


deleteTodo : String -> Doc -> Doc
deleteTodo id doc =
    { doc | todos = doc.todos |> Array.filter (\e -> e.id /= id) }

pushTodo : Todo -> Doc -> Doc
pushTodo todo doc =
    { doc | todos = doc.todos |> Array.push todo }

focusTodo id =
    Dom.focus ("task-" ++ id)


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
            (doc.todos |> Array.map viewTodo |> Array.toList)
        , viewNewButton
        ]


viewTodo : Todo -> Html Msg
viewTodo { title, id, done } =
    let todoId = randomString 7
    in 
    div
        [ css
            [ property "display" "grid"
            , property "grid-template-columns" "auto 1fr"
            ]
        ]
        [ input [ Attr.type_ "checkbox", checked done, onCheck (SetDone id) ] []
        , input
            [ Attr.id ("task-" ++ id)
            , onInput (SetTitle id)
            , if String.length title == 0 then
                Keyboard.onUp Backspace (DeleteTodo id)
              else
                Keyboard.onPress Enter CreateTodo
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
        [ onClick CreateTodo
        , css
            [ cursor pointer
            , textAlign center
            , padding (px 10)
            ]
        ]
        [ text "+ Create Todo" ]
