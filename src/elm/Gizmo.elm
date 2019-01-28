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
    , decodedMsgs
    , element
    , emit
    , onEmit
    , render
    , renderWindow
    , renderWith
    , portal
    , portalTo
    , sandbox
    , send
    )

import Dict exposing (Dict)
import Doc
import Html exposing (Html)
import Html.Attributes as Attr
import Html.Events as Events
import Json.Decode as Json
import Json.Encode as E
import Repo exposing (Url)
import Task


port command : ( String, String ) -> Cmd msg


port msgs : (Json.Value -> msg) -> Sub msg


port emitted : ( String, E.Value ) -> Cmd msg


decodedMsgs : (String -> Msg doc msg) -> Sub (Msg doc msg)
decodedMsgs errMsg =
    msgs (Json.decodeValue msgDecoder)
        |> Sub.map
            (\res ->
                case res of
                    Ok v ->
                        v

                    Err x ->
                        errMsg (Json.errorToString x)
            )


emit : String -> E.Value -> Cmd msg
emit name value =
    emitted ( name, value )


type alias EmitDetail =
    { name : String
    , value : E.Value
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
        (Json.at [ "detail", "value" ] Json.value)
        (Json.at [ "detail", "code" ] Json.string)
        (Json.at [ "detail", "data" ] Json.string)


type alias Attrs =
    Dict String String


type alias InputFlags =
    { code : Url
    , data : Url
    , self : Url
    , config : Json.Value
    , doc : Doc.RawDoc
    , all : Json.Value
    }


type alias Flags =
    { code : Url
    , data : Url
    , self : Url
    , config : Dict String String
    , doc : Doc.Doc
    , rawDoc : Doc.RawDoc
    , all : Attrs
    }


type alias Model state doc =
    { isMounted : Bool
    , doc : doc
    , state : state
    , flags : Flags
    }


type Msg doc msg
    = NoOp
    | Custom msg
    | Unmount
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
    Html.node "farm-ui"
        (attr "code" code
            :: attr "data" data
            :: attrs
        )
        []


renderWindow : Url -> Url -> msg -> Html msg
renderWindow code data closeMsg =
    Html.node "farm-window"
        [ attr "code" code
        , attr "data" data
        , Events.on "windowclose" (Json.succeed closeMsg)
        ]
        []


portal : Html.Attribute msg
portal =
    portalTo "body"


{-| Render a gizmo as a child of an element specified by a CSS selector.
    Note: Uses `document.querySelector` under the hood.
-}
portalTo : String -> Html.Attribute msg
portalTo =
    attr "portaltarget"


attr : String -> String -> Html.Attribute msg
attr =
    Attr.attribute


decodeFlags : InputFlags -> Flags
decodeFlags fl =
    { code = fl.code
    , data = fl.data
    , self = fl.self
    , config =
        fl.config
            |> Json.decodeValue (Json.dict Json.string)
            |> Result.withDefault Dict.empty
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


msgDecoder : Json.Decoder (Msg doc msg)
msgDecoder =
    Json.field "t" Json.string
        |> Json.andThen
            (\t ->
                case t of
                    "Unmount" ->
                        Json.succeed Unmount

                    _ ->
                        Json.fail "Not a valid incoming Msg."
            )


send : msg -> Cmd msg
send =
    Task.succeed >> Task.perform identity
