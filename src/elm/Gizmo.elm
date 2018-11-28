port module Gizmo exposing
    ( Attrs
    , Flags
    , InputFlags
    , Model
    , Msg(..)
    , Program
    , attr
    , command
    , decodeFlags
    , element
    , render
    , renderWith
    , sandbox
    )

import Dict exposing (Dict)
import Html exposing (Html)
import Html.Attributes as Attr
import Json.Decode as Json
import Repo exposing (Url)


port command : ( String, String ) -> Cmd msg


type alias Attrs =
    Dict String String


type alias InputFlags =
    { code : Url
    , data : Url
    , self : Url
    , all : Json.Value
    }


type alias Flags =
    { code : Url
    , data : Url
    , self : Url
    , all : Attrs
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


render : Url -> Url -> Html msg
render =
    renderWith []


renderWith : List (Html.Attribute msg) -> Url -> Url -> Html msg
renderWith attrs code data =
    Html.node "realm-ui"
        (attr "code" code
            :: attr "data" data
            :: attrs
        )
        []


attr : String -> String -> Html.Attribute msg
attr =
    Attr.attribute


decodeFlags : InputFlags -> Flags
decodeFlags fl =
    { code = fl.code
    , data = fl.data
    , self = fl.self
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
