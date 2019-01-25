module Navigator exposing (Doc, Msg, State, gizmo)

import FarmUrl
import Gizmo exposing (Flags, Model)
import Html exposing (Html, text)
import IO
import Navigation


gizmo : Gizmo.Program State Doc Msg
gizmo =
    Gizmo.element
        { init = init
        , update = update
        , view = view
        , subscriptions = subscriptions
        }


{-| Ephemeral state not saved to the doc
-}
type alias State =
    { error : Maybe ( String, String )
    }


type alias Pair =
    { code : String
    , data : String
    }


{-| Document state
-}
type alias Doc =
    { history : List Pair
    }


init : Flags -> ( State, Doc, Cmd Msg )
init flags =
    ( { error = Nothing
      }
    , { history = []
      }
    , Cmd.none
    )


{-| Message type for modifying State and Doc inside update
-}
type Msg
    = NavigateTo String


update : Msg -> Model State Doc -> ( State, Doc, Cmd Msg )
update msg { state, doc } =
    case msg of
        NavigateTo url ->
            case FarmUrl.parse url of
                Ok pair ->
                    ( state
                    , { doc | history = pair :: doc.history }
                    , IO.log <| "Navigating to " ++ url
                    )

                Err err ->
                    ( { state | error = Just ( url, err ) }
                    , doc
                    , IO.log <| "Could not navigate to " ++ url ++ ". " ++ err
                    )


view : Model State Doc -> Html Msg
view { doc, state } =
    case state.error of
        Just ( url, err ) ->
            text <| "'" ++ url ++ "' could not be parsed: " ++ err

        Nothing ->
            case current doc of
                Just ({ code, data } as pair) ->
                    let
                        url =
                            Debug.log "Viewing " <| FarmUrl.create pair
                    in
                    Gizmo.render code data

                Nothing ->
                    text "You haven't navigated to anything. Click a farm link."


subscriptions : Model State Doc -> Sub Msg
subscriptions model =
    Navigation.currentUrl NavigateTo


current : Doc -> Maybe Pair
current =
    .history >> List.head
