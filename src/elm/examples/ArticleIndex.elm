module ArticleIndex exposing (Doc, Msg, State, gizmo)

import Gizmo exposing (Flags, Model)
import Html.Styled as Html exposing (..)
import Html.Styled.Events as Events
import Dict exposing (Dict)
import Json.Encode as E
import Json.Decode as D
import Css exposing (..)
import Html.Styled.Attributes exposing (css, placeholder, value)


hotPink =
    hex "#ff69b4"


darkerHotPink =
    hex "#ff1a8c"


gizmo : Gizmo.Program State Doc Msg
gizmo =
    Gizmo.element
        { init = init
        , update = update
        , view = Html.toUnstyled << view
        , subscriptions = subscriptions
        }


{-| Ephemeral state not saved to the doc
-}
type alias State =
    {}


{-| Document state
-}
type alias Doc =
    { index : E.Value --Dict ArticleTitle GizmoUrl
    }

type alias GizmoUrl =
    String

type alias ArticleTitle =
    String

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


init : Flags -> ( State, Doc, Cmd Msg )
init flags =
    ( {}
    , { index = E.object [] }
    , Cmd.none
    )


{-| Message type for modifying State and Doc inside update
-}
type Msg
    = NoOp
    | NavigateToArticle ArticleTitle
    | CreateArticle


update : Msg -> Model State Doc -> ( State, Doc, Cmd Msg )
update msg { state, doc } =
    case msg of
        NoOp ->
            ( state
            , doc
            , Cmd.none
            )

        NavigateToArticle title ->
            ( state
            , doc
            , Gizmo.emit "navigate" (E.string title)
            )

        CreateArticle ->
            ( state
            , doc
            , Gizmo.emit "createarticle" E.null
            )


view : Model State Doc -> Html Msg
view { doc } =
    let
        index = decodeIndex doc.index
    in
    div
        [ css
            [ padding (px 20)
            , fontFamilies [ "system-ui" ]
            ]
        ]
        [ h1
            [ css
                [ fontSize (Css.em 1.3)
                ]
            ]
            [ text "RealmWiki"
            ]
        , button
            [ Events.onClick CreateArticle
            , css
                [ border3 (px 1) solid hotPink
                , borderRadius (px 3)
                , backgroundColor (hex "fff")
                , margin2 (px 10) (px 0)
                , color hotPink
                , cursor pointer
                , hover
                    [ color darkerHotPink
                    ]
                ]
            ]
            [ text "+"
            ]
        , div
            []
            (List.map viewArticle <| Dict.keys index)
        ]


viewArticle : ArticleTitle -> Html Msg
viewArticle title =
    div
        [ Events.onClick (NavigateToArticle title)
        , css
            [ padding2 (px 5) (px 0)
            , color hotPink
            , cursor pointer
            , hover
                [ color darkerHotPink
                ]
            ]
        ]
        [ text title
        ]

subscriptions : Model State Doc -> Sub Msg
subscriptions model =
    Sub.none