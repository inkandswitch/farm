module Plugin exposing (Program, element, render)

import Browser
import Html exposing (Attribute, Html)
import Html.Attributes as Attr


type alias Program doc msg =
    Platform.Program (Maybe doc) (Model doc) (Msg doc msg)


type alias Spec doc msg =
    { init : doc
    , update : msg -> doc -> doc
    , view : doc -> Html msg
    , output : doc -> Cmd (Msg doc msg)
    , input : (doc -> Msg doc msg) -> Sub (Msg doc msg)
    }


type Msg doc msg
    = UpdatedDoc doc
    | Custom msg


type Model doc
    = Ready doc



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


init : Spec doc msg -> Maybe doc -> ( Model doc, Cmd (Msg doc msg) )
init spec mDoc =
    case mDoc of
        Just doc ->
            ( Ready doc, Cmd.none )

        Nothing ->
            ( Ready spec.init, Cmd.none )


update : Spec doc msg -> Msg doc msg -> Model doc -> ( Model doc, Cmd (Msg doc msg) )
update spec msg model =
    case msg of
        UpdatedDoc doc ->
            ( Ready doc, Cmd.none )

        Custom submsg ->
            case model of
                Ready doc ->
                    let
                        newDoc =
                            spec.update submsg doc
                    in
                    ( Ready newDoc, spec.output newDoc )


view : Spec doc msg -> Model doc -> Html (Msg doc msg)
view spec model =
    case model of
        Ready doc ->
            spec.view doc
                |> Html.map Custom
