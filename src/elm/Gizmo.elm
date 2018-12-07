port module Gizmo exposing
    ( Attrs
    , EmitDetail
    , Flags
    , InputFlags
    , Model
    , Msg(..)
    , Program
    , attr
    , command
    , decodeFlags
    , element
    , emit
    , onEmit
    , render
    , renderWindow
    , renderWith
    , sandbox
    , send
    )

import Dict exposing (Dict)
import Doc
import Html exposing (Html)
import Html.Attributes as Attr
import Html.Events as Events
import Json.Decode as Json
import Repo exposing (Url)
import Task


port command : ( String, String ) -> Cmd msg


port emitted : ( String, String ) -> Cmd msg


emit : String -> String -> Cmd msg
emit name value =
    emitted ( name, value )


type alias EmitDetail =
    { name : String
    , value : Url
    , code : Url
    , data : Url
    }


onEmit : String -> (EmitDetail -> msg) -> Html.Attribute msg
onEmit name mkMsg =
    Events.stopPropagationOn name
        (emitDecoder
            |> Json.map mkMsg
            |> Json.map (\msg -> ( msg, True ))
        )


emitDecoder : Json.Decoder EmitDetail
emitDecoder =
    Json.map4 EmitDetail
        (Json.at [ "detail", "name" ] Json.string)
        (Json.at [ "detail", "value" ] Json.string)
        (Json.at [ "detail", "code" ] Json.string)
        (Json.at [ "detail", "data" ] Json.string)


type alias Attrs =
    Dict String String


type alias InputFlags =
    { code : Url
    , data : Url
    , self : Url
    , doc : Doc.RawDoc
    , all : Json.Value
    }


type alias Flags =
    { code : Url
    , data : Url
    , self : Url
    , doc : Doc.Doc
    , rawDoc : Doc.RawDoc
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


renderWindow : Url -> Url -> Html msg
renderWindow code data =
    Html.node "realm-window"
        [ attr "code" code
        , attr "data" data
        ]
        []


attr : String -> String -> Html.Attribute msg
attr =
    Attr.attribute


decodeFlags : InputFlags -> Flags
decodeFlags fl =
    { code = fl.code
    , data = fl.data
    , self = fl.self
    , doc = fl.doc |> Doc.decode
    , rawDoc = fl.doc
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


send : msg -> Cmd msg
send =
    Task.succeed >> Task.perform identity
