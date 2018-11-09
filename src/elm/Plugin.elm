module Plugin exposing (Model, Program, element, render)

import Browser
import Html exposing (Attribute, Html)
import Html.Attributes as Attr


type alias Flags =
    { docId : String
    , sourceId : String
    }


type alias Program doc msg =
    Platform.Program Flags (Model doc) (Msg doc msg)


type alias Spec doc msg =
    { init : doc
    , update : msg -> Model doc -> doc
    , view : Model doc -> Html msg
    , output : doc -> Cmd (Msg doc msg)
    , input : (doc -> Msg doc msg) -> Sub (Msg doc msg)
    }


type Msg doc msg
    = UpdatedDoc doc
    | Custom msg


type alias Model doc =
    { doc : doc
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


element : Spec doc msg -> Program doc msg
element spec =
    Browser.element
        { init = init spec
        , view = view spec
        , update = update spec
        , subscriptions = subscriptions spec
        }


subscriptions : Spec doc msg -> Model doc -> Sub (Msg doc msg)
subscriptions spec model =
    spec.input UpdatedDoc


init : Spec doc msg -> Flags -> ( Model doc, Cmd (Msg doc msg) )
init spec flags =
    ( { docId = flags.docId
      , sourceId = flags.sourceId
      , doc = spec.init
      }
    , Cmd.none
    )


update : Spec doc msg -> Msg doc msg -> Model doc -> ( Model doc, Cmd (Msg doc msg) )
update spec msg model =
    case msg of
        UpdatedDoc doc ->
            ( { model | doc = doc }, Cmd.none )

        Custom submsg ->
            let
                newDoc =
                    spec.update submsg model
            in
            ( { model | doc = newDoc }, spec.output newDoc )


view : Spec doc msg -> Model doc -> Html (Msg doc msg)
view spec model =
    spec.view model
        |> Html.map Custom
