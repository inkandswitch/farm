module Wiki exposing (Doc, Msg, State, gizmo)

import Gizmo exposing (Flags, Model)
import Html.Styled as Html exposing (..)
import Html.Styled.Events as Events
import Dict exposing (Dict)
import Repo exposing (Props, Ref, Url, create, createWithProps)
import Json.Encode as E
import Json.Decode as D


gizmo : Gizmo.Program State Doc Msg
gizmo =
    Gizmo.element
        { init = init
        , update = update
        , view = Html.toUnstyled << view
        , subscriptions = subscriptions
        }

-- When gizmo docs are supported, this will represent the url of
-- a gizmo doc. For now, it represents the data doc (we assume the
-- Article source is the code doc).
type alias GizmoUrl =
    String

type alias ArticleTitle =
    String


type alias State =
    { currentArticle : Maybe ArticleTitle
    }


type alias Doc =
    { index : E.Value --Dict ArticleTitle GizmoUrl
    }


defaultArticleTitle : ArticleTitle
defaultArticleTitle =
    "New Article"

newArticleProps : Repo.Props
newArticleProps =
    [ ( "title", E.string defaultArticleTitle )
    , ( "body", E.string "")
    ]

gizmoProps : String -> String -> Repo.Props
gizmoProps codeUrl dataUrl =
    [ ( "code", E.string codeUrl )
    , ( "data", E.string dataUrl )
    ]


init : Flags -> ( State, Doc, Cmd Msg )
init flags =
    ( { currentArticle = Nothing}
    , { index = E.object [] }
    , Cmd.none
    )

decodeIndex : E.Value -> Dict ArticleTitle GizmoUrl
decodeIndex val =
    case D.decodeValue (D.keyValuePairs D.string) val of
        Ok index ->
            Dict.fromList index
        Err msg ->
            Dict.empty

encodeIndex : Dict ArticleTitle GizmoUrl -> E.Value
encodeIndex index =
    index
        |> Dict.map (\k v -> E.string v)
        |> Dict.toList
        |> E.object

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
        index =
            decodeIndex doc.index
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
                    update (GizmoDocCreated (ref, urls)) model
                "CreateArticleGizmoDoc" ->
                    update (GizmoDocCreated (ref, urls)) model
                _ ->
                    ( state, doc, Cmd.none )

        DataDocCreated ( ref, urls ) ->
            case urls of
                [dataUrl] ->
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
                [gizmoUrl] ->
                    ( { state | currentArticle = Just defaultArticleTitle }
                    , { doc | index = encodeIndex (Dict.insert defaultArticleTitle gizmoUrl index) }
                    , Cmd.none
                    )
                _ ->
                    ( state
                    , doc
                    , Cmd.none
                    )

        NavigateToArticle articleTitle ->
            ( { state | currentArticle = Just articleTitle }
            , doc
            , Cmd.none
            )

        UpdateArticleTitle old new ->
            case state.currentArticle of
                Just currentArticle ->
                    ( { state | currentArticle = if currentArticle == old then Just new else Just currentArticle }
                    , { doc | index = encodeIndex (rekey old new index) }
                    , Cmd.none
                    )
                Nothing ->
                    ( state
                    , { doc | index = encodeIndex (rekey old new index) }
                    , Cmd.none
                    )

        RemoveArticle title ->
            let
                updatedDoc = { doc | index = encodeIndex (Dict.remove title index) }
            in
            case state.currentArticle of
                Just currentArticle ->
                    ( { state | currentArticle = if currentArticle == title then Nothing else Just currentArticle }
                    , updatedDoc
                    , Cmd.none
                    )
                Nothing ->
                    ( state
                    , updatedDoc
                    , Cmd.none
                    )
                

rekey : comparable -> comparable -> Dict comparable v -> Dict comparable v
rekey old new dict =
    case (Dict.get old dict) of
        Just val ->
            dict
                |> Dict.insert new val
                |> Dict.remove old
        Nothing ->
            dict


view : Model State Doc -> Html Msg
view { flags, state, doc } =
    let
        viewArticle =
            viewGizmo <| Maybe.withDefault "" (Dict.get "article" flags.config)

        viewIndex =
            viewGizmo <| Maybe.withDefault "" (Dict.get "articleIndex" flags.config)
    in
    div
        [ onNavigate NavigateToArticle
        , onCreate CreateArticle
        , onRemove RemoveArticle
        , onTitleUpdate UpdateArticleTitle
        ]
        [ viewIndex flags.data
        , div
            [ Events.onClick CreateArticle
            ]
            [ text "New Article"
            ]
        , case maybeCurrentArticle state.currentArticle (decodeIndex doc.index) of
            Just article ->
                viewArticle article
            Nothing ->
                Html.text ""
        ]

onNavigate : (ArticleTitle -> msg) -> Html.Attribute msg
onNavigate tagger =
    Events.on "navigate" (D.map tagger detailString)

onCreate : msg -> Html.Attribute msg
onCreate msg =
    Events.on "create" (D.succeed msg)

onRemove : (ArticleTitle -> msg) -> Html.Attribute msg
onRemove tagger =
    Events.on "remove" (D.map tagger detailString)

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
    D.at ["detail", "value"] decoder

detailString : D.Decoder String
detailString =
    detail D.string

detailField : String -> D.Decoder a -> D.Decoder a
detailField field decoder =
    detail (D.field field decoder)


maybeCurrentArticle : Maybe ArticleTitle -> Dict ArticleTitle GizmoUrl -> Maybe String
maybeCurrentArticle maybe index =
    case maybe of
        Just articleTitle ->
            Dict.get articleTitle index
        Nothing ->
            Nothing


viewGizmo : String -> String -> Html Msg
viewGizmo source data =
    Html.fromUnstyled (Gizmo.render source data)


subscriptions : Model State Doc -> Sub Msg
subscriptions model =
    Repo.created DocCreated