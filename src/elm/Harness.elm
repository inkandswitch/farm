port module Harness exposing (main)

import Browser
import Gizmo exposing (Flags, InputFlags, Msg(..), decodeFlags)
import Html.Styled as Html exposing (Html)
import Repo
import Source as S exposing (Doc, State, gizmo)


port initDoc : Doc -> Cmd msg


port saveDoc : { doc : Doc, prevDoc : Doc } -> Cmd msg


port loadDoc : (Doc -> msg) -> Sub msg


type alias InputMsg =
    { doc : Maybe Doc
    }


type alias Model =
    Gizmo.Model State Doc


init : InputFlags -> ( Model, Cmd Msg )
init iFlags =
    let
        flags =
            decodeFlags iFlags

        ( state, doc, cmd ) =
            gizmo.init flags
    in
    ( { isMounted = True
      , doc = doc
      , state = state
      , flags = flags
      }
    , Cmd.batch
        [ cmd |> Cmd.map Custom
        , initDoc doc
        ]
    )


type alias Msg =
    Gizmo.Msg Doc S.Msg


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        NoOp ->
            ( model, Cmd.none )

        Custom sMsg ->
            let
                ( state, doc, cmd ) =
                    gizmo.update sMsg model
            in
            ( { model | state = state, doc = doc }
            , Cmd.batch
                [ cmd |> Cmd.map Custom
                , saveIfChanged model.doc doc
                ]
            )

        LoadDoc doc ->
            ( { model | doc = doc }, Cmd.none )

        Unmount ->
            ( { model | isMounted = False }, Cmd.none )


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ Gizmo.decodedMsgs (Debug.log "Invalid msg" >> always NoOp)
        , if model.isMounted then
            Sub.batch
                [ loadDoc LoadDoc
                , gizmo.subscriptions model |> Sub.map Custom
                ]

          else
            Sub.none
        ]


view : Model -> Html Msg
view model =
    if model.isMounted then
        gizmo.view model
            |> Html.map Custom

    else
        Html.text ""


main : Platform.Program InputFlags Model Msg
main =
    Browser.element
        { init = init
        , update = update
        , view = Html.toUnstyled << view
        , subscriptions = subscriptions
        }


saveIfChanged : Doc -> Doc -> Cmd Msg
saveIfChanged prevDoc doc =
    if doc /= prevDoc then
        saveDoc { doc = doc, prevDoc = prevDoc }

    else
        Cmd.none
