module ArticleIndex exposing (Doc, Msg, State, gizmo)

import Css exposing (..)
import Dict exposing (Dict)
import Gizmo exposing (Flags, Model)
import Html.Styled as Html exposing (..)
import Html.Styled.Attributes exposing (css, placeholder, value)
import Html.Styled.Events as Events
import Json.Decode as D
import Json.Encode as E


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
    { articles : List GizmoUrl
    }


type alias GizmoUrl =
    String


init : Flags -> ( State, Doc, Cmd Msg )
init flags =
    ( {}
    , { articles = [] }
    , Cmd.none
    )


{-| Message type for modifying State and Doc inside update
-}
type Msg
    = NoOp
    | NavigateToArticle GizmoUrl
    | CreateArticle


update : Msg -> Model State Doc -> ( State, Doc, Cmd Msg )
update msg { state, doc } =
    case msg of
        NoOp ->
            ( state
            , doc
            , Cmd.none
            )

        NavigateToArticle url ->
            ( state
            , doc
            , Gizmo.emit "navigate" (E.string url)
            )

        CreateArticle ->
            ( state
            , doc
            , Gizmo.emit "createarticle" E.null
            )


view : Model State Doc -> Html Msg
view { flags, doc } =
    let
        viewArticleItem =
            viewGizmo <| Maybe.withDefault "missing" (Dict.get "articleIndexItem" flags.config)
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
            [ text "FarmWiki"
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
            (List.map (viewArticle viewArticleItem) doc.articles)
        ]


viewArticle : (String -> Html Msg) -> GizmoUrl -> Html Msg
viewArticle viewArticleItem url =
    div
        [ Events.onClick (NavigateToArticle url)
        , css
            [ padding2 (px 5) (px 0)
            , color hotPink
            , cursor pointer
            , hover
                [ color darkerHotPink
                ]
            ]
        ]
        [ viewArticleItem url
        ]


subscriptions : Model State Doc -> Sub Msg
subscriptions model =
    Sub.none


viewGizmo : String -> String -> Html Msg
viewGizmo source data =
    Html.fromUnstyled (Gizmo.render source data)
