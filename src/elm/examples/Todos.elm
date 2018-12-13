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


update : Msg -> Model State Doc -> ( State, Doc )
update msg { state, doc } =
    case msg of
        SetDone n done ->
            ( state, doc |> updateTodo n (setDone done) )

        SetTitle n title ->
            ( state, doc |> updateTodo n (setTitle title) )


setDone : Bool -> Todo -> Todo
setDone done todo =
    { todo | done = done }


setTitle : String -> Todo -> Todo
setTitle title todo =
    { todo | title = title }


updateTodo : Int -> (Todo -> Todo) -> Doc -> Doc
updateTodo n fn doc =
    { doc | todos = doc.todos |> Array.update n fn }


view : Model State Doc -> Html Msg
view { doc } =
    div
        [ css
            [ property "display" "grid"
            , alignItems center
            , property "justify-items" "center"
            , height (vh 100)
            , width (vw 100)
            ]
        ]
        [ div
            [ css
                [ boxShadow4 (px 1) (px 2) (px 5) (rgba 0 0 0 0.2)
                , padding (px 5)
                , borderRadius (px 3)
                ]
            ]
            (doc.todos |> Array.indexedMap viewTodo |> Array.toList)
        ]


viewTodo : Int -> Todo -> Html Msg
viewTodo n { title, done } =
    div
        []
        [ input [ Attr.type_ "checkbox", checked done, onCheck (SetDone n) ] []
        , input
            [ onInput (SetTitle n)
            , value title
            , css
                [ property "-webkit-appearance" "none"
                , border (px 0)
                , fontFamily inherit
                , fontSize inherit
                , focus
                    [ borderBottom3 (px 1) solid (hex "ddd")
                    ]
                ]
            ]
            []
        ]
