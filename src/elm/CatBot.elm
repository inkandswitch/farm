module CatBot exposing (Doc, Msg, State, bot)

import Bot exposing (Flags, Model)
import Doc
import IO


bot : Bot.Program State Doc Msg
bot =
    Bot.create
        { init = init
        , update = update
        , onDoc = onDoc
        , subscriptions = subscriptions
        }


{-| Ephemeral state not saved to the doc
-}
type alias State =
    {}


{-| Document state
-}
type alias Doc =
    Doc.RawDoc


init : Flags -> ( State, Doc, Cmd Msg )
init _ =
    ( {}
    , Doc.encode Doc.empty
    , Cmd.none
    )


{-| Message type for modifying State and Doc inside update
-}
type Msg
    = NoOp


update : Msg -> Model State Doc -> ( State, Doc, Cmd Msg )
update msg { state, doc } =
    case msg of
        NoOp ->
            ( state, doc, Cmd.none )


subscriptions : Model State Doc -> Sub Msg
subscriptions { state, doc } =
    Sub.none


onDoc : Model State Doc -> ( State, Cmd Msg )
onDoc { state, doc } =
    ( state, IO.log (Doc.asString (Doc.decode doc)) )
