module Wiki exposing (Doc, Msg, State, gizmo)

import Css exposing (..)
import Dict exposing (Dict)
import Gizmo exposing (Flags, Model)
import Html.Styled as Html exposing (..)
import Html.Styled.Attributes exposing (css)
import Html.Styled.Events as Events
import Json.Decode as D
import Json.Encode as E
import Repo exposing (Props, Ref, Url, create, createWithProps)


gizmo : Gizmo.Program State Doc Msg
gizmo =
    Gizmo.element
        { init = init
        , update = update
        , view = view
        , subscriptions = subscriptions
        }



-- When gizmo docs are supported, this will represent the url of
-- a gizmo doc. For now, it represents the data doc (we assume the
-- Article source is the code doc).


type alias GizmoUrl =
    String


type alias ArticleTitle =
    String


type alias TitleIndex =
    Dict ArticleTitle (List GizmoUrl)


type alias State =
    { currentArticle : Maybe GizmoUrl
    }


type alias Doc =
    { articles : List GizmoUrl

    --, titleIndex : E.Value --Dict ArticleTitle (List GizmoUrl)
    }


defaultArticleTitle : ArticleTitle
defaultArticleTitle =
    "New Article"


newArticleProps : Repo.Props
newArticleProps =
    [ ( "title", E.string defaultArticleTitle )
    , ( "body", E.string "" )
    ]


gizmoProps : String -> String -> Repo.Props
gizmoProps codeUrl dataUrl =
    [ ( "code", E.string codeUrl )
    , ( "data", E.string dataUrl )
    ]


init : Flags -> ( State, Doc, Cmd Msg )
init flags =
    ( { currentArticle = Nothing }
    , { articles = [] }
      --, titleIndex = E.object [] }
    , Cmd.none
    )



-- decodeIndex : E.Value -> TitleIndex
-- decodeIndex val =
--     case D.decodeValue (D.keyValuePairs D.string) val of
--         Ok index ->
--             Dict.fromList index
--         Err msg ->
--             Dict.empty
-- encodeIndex : TitleIndex -> E.Value
-- encodeIndex index =
--     index
--         |> Dict.map (\k v -> List.map (\e -> E.string e) v)
--         |> Dict.toList
--         |> E.object


{-| Message type for modifying State and Doc inside update
-}
type Msg
    = NoOp
    | CreateArticle
    | DocCreated ( Ref, List String )
    | DataDocCreated ( Ref, List String )
    | GizmoDocCreated ( Ref, List String )
    | NavigateToArticle ArticleTitle
    | UpdateArticleTitle ArticleTitle ArticleTitle
    | RemoveArticle ArticleTitle


update : Msg -> Model State Doc -> ( State, Doc, Cmd Msg )
update msg model =
    let
        flags =
            model.flags

        state =
            model.state

        doc =
            model.doc

        articleCode =
            Maybe.withDefault "" (Dict.get "article" flags.config)
    in
    case msg of
        NoOp ->
            ( state
            , doc
            , Cmd.none
            )

        CreateArticle ->
            ( state
            , doc
            , Repo.createWithProps "CreateArticleDataDoc" 1 newArticleProps
            )

        DocCreated ( ref, urls ) ->
            case ref of
                "CreateArticleDataDoc" ->
                    -- Uncomment when gizmo docs are supported.
                    -- update (DataDocCreated (ref, urls)) model
                    update (GizmoDocCreated ( ref, urls )) model

                "CreateArticleGizmoDoc" ->
                    update (GizmoDocCreated ( ref, urls )) model

                _ ->
                    ( state, doc, Cmd.none )

        DataDocCreated ( ref, urls ) ->
            case urls of
                [ dataUrl ] ->
                    ( state
                    , doc
                    , Repo.createWithProps "CreateArticleGizmoDoc" 1 (gizmoProps articleCode dataUrl)
                    )

                _ ->
                    ( state
                    , doc
                    , Cmd.none
                    )

        GizmoDocCreated ( ref, urls ) ->
            case urls of
                [ gizmoUrl ] ->
                    ( { state | currentArticle = Just gizmoUrl }
                    , { doc | articles = gizmoUrl :: doc.articles }
                    , Cmd.none
                    )

                _ ->
                    ( state
                    , doc
                    , Cmd.none
                    )

        NavigateToArticle url ->
            ( { state | currentArticle = Just url }
            , doc
            , Cmd.none
            )

        UpdateArticleTitle old new ->
            -- TODO: Update titleIndex.
            ( state
            , doc
            , Cmd.none
            )

        RemoveArticle url ->
            let
                updatedDoc =
                    { doc | articles = List.filter (\v -> v /= url) doc.articles }
            in
            case state.currentArticle of
                Just currentArticle ->
                    ( { state
                        | currentArticle =
                            if currentArticle == url then
                                Nothing

                            else
                                Just currentArticle
                      }
                    , updatedDoc
                    , Cmd.none
                    )

                Nothing ->
                    ( state
                    , updatedDoc
                    , Cmd.none
                    )


view : Model State Doc -> Html Msg
view { flags, state, doc } =
    let
        viewArticle =
            Gizmo.render <| Maybe.withDefault "" (Dict.get "article" flags.config)

        viewIndex =
            Gizmo.render <| Maybe.withDefault "" (Dict.get "articleIndex" flags.config)
    in
    div
        [ onNavigate NavigateToArticle
        , onCreate CreateArticle
        , onRemove RemoveArticle
        , onTitleUpdate UpdateArticleTitle
        , css
            [ width (vw 100)
            , height (vh 100)
            , property "display" "grid"
            , property "grid-template-columns" "20% 80%"
            , backgroundColor (hex "f5f5f5")
            ]
        ]
        [ viewIndex flags.data
        , case state.currentArticle of
            Just articleUrl ->
                viewArticle articleUrl

            Nothing ->
                Html.text ""
        ]


onNavigate : (ArticleTitle -> msg) -> Html.Attribute msg
onNavigate tagger =
    Events.on "navigate" (D.map tagger detailString)


onCreate : msg -> Html.Attribute msg
onCreate msg =
    Events.on "createarticle" (D.succeed msg)


onRemove : (ArticleTitle -> msg) -> Html.Attribute msg
onRemove tagger =
    Events.on "removearticle" (D.map tagger detailString)


onTitleUpdate : (ArticleTitle -> ArticleTitle -> msg) -> Html.Attribute msg
onTitleUpdate tagger =
    Events.on
        "updatetitle"
        (D.map2 tagger
            (detailField "old" D.string)
            (detailField "new" D.string)
        )


detail : D.Decoder a -> D.Decoder a
detail decoder =
    D.at [ "detail", "value" ] decoder


detailString : D.Decoder String
detailString =
    detail D.string


detailField : String -> D.Decoder a -> D.Decoder a
detailField field decoder =
    detail (D.field field decoder)


subscriptions : Model State Doc -> Sub Msg
subscriptions model =
    Repo.created DocCreated
