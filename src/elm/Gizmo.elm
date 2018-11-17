module Gizmo exposing (Flags, Model, Program)


type alias Flags =
    { code : String
    , data : String
    }


type alias Model state doc =
    { doc : doc
    , state : state
    , flags : Flags
    }


type alias Program state doc msg =
    { init : ( state, doc, Cmd msg )
    , update : msg -> Model state doc -> ( state, doc, Cmd msg )
    , view : Model state doc -> Html msg
    , subscriptions : Sub msg
    }


sandbox :
    { init : doc
    , view : doc -> Html msg
    , update : msg -> doc -> doc
    }
    -> Spec () doc msg
sandbox {init, view, update} =
    { init = ((), init, Cmd.none)
    , update = }
