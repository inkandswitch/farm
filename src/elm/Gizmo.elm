module Gizmo exposing (Flags, Model, Msg(..), Program, element, render, sandbox)

import Html exposing (Html)
import Html.Attributes as Attr
import Repo


type alias Flags =
    { code : String
    , data : String
    , self : String
    }


type alias Model state doc =
    { doc : doc
    , state : state
    , flags : Flags
    }


type Msg doc msg
    = Custom msg
    | LoadDoc doc


type alias Program state doc msg =
    { init : Flags -> ( state, doc, Cmd msg )
    , update : msg -> Model state doc -> ( state, doc, Cmd msg )
    , view : Model state doc -> Html msg
    , subscriptions : Model state doc -> Sub msg
    }


sandbox :
    { init : ( state, doc )
    , view : Model state doc -> Html msg
    , update : msg -> Model state doc -> ( state, doc )
    }
    -> Program state doc msg
sandbox { init, view, update } =
    { init = always (init |> withThird Cmd.none)
    , update = \msg model -> update msg model |> withThird Cmd.none
    , view = view
    , subscriptions = always Sub.none
    }


element : Program state doc msg -> Program state doc msg
element =
    identity


withThird : c -> ( a, b ) -> ( a, b, c )
withThird c ( a, b ) =
    ( a, b, c )


render : String -> String -> Html msg
render code data =
    Html.node "realm-ui" 
    [ Attr.attribute "code" code
    , Attr.attribute "data" data
    ] []
