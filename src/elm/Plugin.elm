module Plugin exposing (In, Model, Out, Program, element, render, viewFlags)

import Browser
import Html exposing (Attribute, Html)
import Html.Attributes as Attr



-- import Json.Decode as D
-- import Json.Encode as E


type alias Flags =
    { docUrl : String
    , src : String
    }


type alias Program state doc msg =
    Platform.Program Flags (Model state doc) (Msg doc msg)


type alias Spec state doc msg =
    { init : ( state, doc )
    , update : msg -> Model state doc -> ( state, doc )
    , view : Model state doc -> Html msg
    , output : Out doc -> Cmd (Msg doc msg)
    , input : (In doc -> Msg doc msg) -> Sub (Msg doc msg)
    }


type Msg doc msg
    = InMsg (In doc)
    | Custom msg


type alias Model state doc =
    { doc : doc
    , state : state
    , docUrl : String
    , src : String
    }


type alias In doc =
    { doc : Maybe doc
    }


type alias Out doc =
    { doc : Maybe doc
    , init : Maybe doc
    , create : Bool
    }


render : String -> String -> Html msg
render src docUrl =
    Html.node "realm-ui" [ Attr.attribute "src" src, Attr.attribute "docUrl" docUrl ] []


element : Spec state doc msg -> Program state doc msg
element spec =
    Browser.element
        { init = init spec
        , view = view spec
        , update = update spec
        , subscriptions = subscriptions spec
        }


subscriptions : Spec state doc msg -> Model state doc -> Sub (Msg doc msg)
subscriptions spec model =
    spec.input InMsg


init : Spec state doc msg -> Flags -> ( Model state doc, Cmd (Msg doc msg) )
init spec flags =
    let
        ( state, doc ) =
            spec.init
    in
    ( { state = state
      , doc = doc
      , docUrl = flags.docUrl
      , src = flags.src
      }
    , spec.output { doc = Nothing, init = Just doc, create = False }
    )


update : Spec state doc msg -> Msg doc msg -> Model state doc -> ( Model state doc, Cmd (Msg doc msg) )
update spec msg model =
    case msg of
        InMsg inMsg ->
            let
                doc =
                    inMsg.doc |> Maybe.withDefault model.doc
            in
            ( { model | doc = doc }, Cmd.none )

        Custom submsg ->
            let
                ( state, doc ) =
                    spec.update submsg model

                newModel =
                    { model | state = state, doc = doc }
            in
            ( newModel, spec.output { doc = Just doc, init = Nothing, create = False } )


view : Spec state doc msg -> Model state doc -> Html (Msg doc msg)
view spec model =
    Html.div []
        [ spec.view model
            |> Html.map Custom
        ]


viewFlags : Flags -> Html msg
viewFlags flags =
    Html.div
        [ Attr.style "background-color" "#eee"
        , Attr.style "padding" "2px 10px"
        ]
        [ Html.pre []
            [ Html.b [] [ Html.text "src: " ]
            , Html.text flags.src
            ]
        , Html.pre []
            [ Html.b [] [ Html.text "docUrl: " ]
            , Html.text flags.docUrl
            ]
        ]



-- ENCODERS and DECODERS
-- incomingDecoder : D.Decoder InMsg
-- incomingDecoder =
--     D.field "type" D.string
--         |> D.andThen
--             (\t ->
--                 case t of
--                     "Created" ->
--                         D.field "id" D.string
--                             |> D.map CreatedDoc
--                     _ ->
--                         D.fail "Not a valid message"
--             )
