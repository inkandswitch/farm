module Bot exposing (Flags, InputFlags, Model, Msg(..), Program, create, decodeFlags)

import Dict exposing (Dict)
import Json.Decode as Json
import Repo


type alias Attrs =
    Dict String String


type alias Flags =
    { code : String
    , data : String
    , all : Attrs
    }


type alias InputFlags =
    { code : String
    , data : String
    , all : Json.Value
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
    , onDoc : Model state doc -> ( state, Cmd msg )
    , subscriptions : Model state doc -> Sub msg
    }


sandbox :
    { init : ( state, doc )
    , onDoc : Model state doc -> state
    , update : msg -> Model state doc -> ( state, doc )
    }
    -> Program state doc msg
sandbox { init, onDoc, update } =
    { init = always (init |> withThird Cmd.none)
    , update = \msg model -> update msg model |> withThird Cmd.none
    , onDoc = \model -> ( onDoc model, Cmd.none )
    , subscriptions = always Sub.none
    }


create : Program state doc msg -> Program state doc msg
create =
    identity


withThird : c -> ( a, b ) -> ( a, b, c )
withThird c ( a, b ) =
    ( a, b, c )


decodeFlags : InputFlags -> Flags
decodeFlags fl =
    { code = fl.code
    , data = fl.data
    , all =
        fl.all
            |> Json.decodeValue attrsDecoder
            |> Result.withDefault Dict.empty
    }


attrsDecoder : Json.Decoder Attrs
attrsDecoder =
    Json.dict <|
        Json.oneOf
            [ Json.string
            , Json.succeed ""
            ]
