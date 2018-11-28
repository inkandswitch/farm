port module BotHarness exposing (main)

import Bot exposing (Flags, InputFlags, Msg(..), decodeFlags)
import Repo
import Source as S exposing (Doc, State, bot)


port initDoc : Doc -> Cmd msg


port saveDoc : { doc : Doc, prevDoc : Doc } -> Cmd msg


port loadDoc : (Doc -> msg) -> Sub msg


type alias InputMsg =
    { doc : Maybe Doc
    }


type alias Model =
    Bot.Model State Doc


init : InputFlags -> ( Model, Cmd Msg )
init iFlags =
    let
        flags =
            decodeFlags iFlags

        ( state, doc, cmd ) =
            bot.init flags
    in
    ( { doc = doc
      , state = state
      , flags = flags
      }
    , Cmd.batch
        [ cmd |> Cmd.map Custom
        , initDoc doc
        ]
    )


type alias Msg =
    Bot.Msg Doc S.Msg


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        Custom sMsg ->
            let
                ( state, doc, cmd ) =
                    bot.update sMsg model
            in
            ( { model | state = state, doc = doc }
            , Cmd.batch
                [ cmd |> Cmd.map Custom
                , saveIfChanged model.doc doc
                ]
            )

        LoadDoc doc ->
            let
                newModel =
                    { model | doc = doc }

                ( state, cmd ) =
                    bot.onDoc newModel
            in
            ( newModel, cmd |> Cmd.map Custom )


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ loadDoc LoadDoc
        , bot.subscriptions model |> Sub.map Custom
        ]


main : Platform.Program InputFlags Model Msg
main =
    Platform.worker
        { init = init
        , update = update
        , subscriptions = subscriptions
        }


saveIfChanged : Doc -> Doc -> Cmd Msg
saveIfChanged prevDoc doc =
    if doc /= prevDoc then
        saveDoc { doc = doc, prevDoc = prevDoc }

    else
        Cmd.none
