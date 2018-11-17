port module Harness exposing (main)

import Browser
import Counter as S exposing (Doc, State)
import Gizmo exposing (Flags)
import Html exposing (Html)


port initDoc : { x : Dict String String } -> Cmd msg


port saveDoc : { doc : Doc, prevDoc : Doc } -> Cmd msg


port loadDoc : (Doc -> msg) -> Sub msg


type alias InputMsg =
    { doc : Maybe Doc
    }


type alias Model =
    Gizmo.Model State Doc


init : Flags -> ( Model, Cmd Msg )
init flags =
    let
        ( state, doc, cmd ) =
            S.init flags
    in
    ( { doc = doc
      , state = state
      , flags = flags
      }
    , Cmd.batch
        [ cmd
        , initDoc doc
        ]
    )


type Msg
    = Custom S.Msg
    | LoadDoc Doc


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        Custom sMsg ->
            let
                ( state, doc, cmd ) =
                    S.update sMsg model
            in
            ( { model | state = state, doc = doc }
            , Cmd.batch
                [ cmd |> Cmd.map Custom
                , saveIfChanged model.doc doc
                ]
            )

        LoadDoc doc ->
            ( { model | doc = doc }, Cmd.none )


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ loadDoc LoadDoc
        , S.subscriptions model
        ]


view : Model -> Html Msg
view model =
    S.view model
        |> Html.map Custom


main : Platform.Program Flags Model Msg
main =
    Browser.element
        { init = init
        , update = update
        , view = view
        , subscriptions = subscriptions
        }


saveIfChanged : Doc -> Doc -> Cmd Msg
saveIfChanged prevDoc doc =
    if doc /= prevDoc then
        saveDoc { doc = doc, prevDoc = prevDoc }

    else
        Cmd.none
