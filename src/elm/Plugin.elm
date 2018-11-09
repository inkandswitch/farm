module Plugin exposing (Model, Program, element, render)

import Browser
import Html exposing (Attribute, Html)
import Html.Attributes as Attr


type alias Flags =
    { docId : String
    , sourceId : String
    }


type alias Program state doc msg =
    Platform.Program Flags (Model state doc) (Msg doc msg)


type alias Spec state doc msg =
    { init : ( state, doc )
    , update : msg -> Model state doc -> ( state, doc )
    , view : Model state doc -> Html msg
    , output : doc -> Cmd (Msg doc msg)
    , input : (doc -> Msg doc msg) -> Sub (Msg doc msg)
    }


type Msg doc msg
    = UpdatedDoc doc
    | Custom msg


type alias Model state doc =
    { doc : doc
    , state : state
    , docId : String
    , sourceId : String
    }



-- type alias Output doc =
--     { doc : Maybe doc
--     , open : Maybe String
--     , }


render : String -> String -> List (Attribute msg) -> List (Html msg) -> Html msg
render name url attrs children =
    Html.node ("realm-" ++ name) (Attr.attribute "url" url :: attrs) children


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
    spec.input UpdatedDoc


init : Spec state doc msg -> Flags -> ( Model state doc, Cmd (Msg doc msg) )
init spec flags =
    let
        ( state, doc ) =
            spec.init
    in
    ( { state = state
      , doc = doc
      , docId = flags.docId
      , sourceId = flags.sourceId
      }
    , Cmd.none
    )


update : Spec state doc msg -> Msg doc msg -> Model state doc -> ( Model state doc, Cmd (Msg doc msg) )
update spec msg model =
    case msg of
        UpdatedDoc doc ->
            ( { model | doc = doc }, Cmd.none )

        Custom submsg ->
            let
                ( state, doc ) =
                    spec.update submsg model

                newModel =
                    { model | state = state, doc = doc }
            in
            ( newModel, spec.output doc )


view : Spec state doc msg -> Model state doc -> Html (Msg doc msg)
view spec model =
    spec.view model
        |> Html.map Custom
