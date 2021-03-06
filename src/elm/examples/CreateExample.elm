module CreateExample exposing (Doc, Msg, State, gizmo)

import Gizmo exposing (Flags, Model)
import Html exposing (Html, button, div, text)
import Html.Events exposing (onClick)
import Repo exposing (Ref, Url)


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
    {}


{-| Document state
-}
type alias Doc =
    { urls : List String
    }


init : Flags -> ( State, Doc, Cmd Msg )
init flags =
    ( {}
    , { urls = []
      }
    , Cmd.none
    )


{-| Message type for modifying State and Doc inside update
-}
type Msg
    = Created ( Ref, List String )
    | Create Int
    | Clone Url


update : Msg -> Model State Doc -> ( State, Doc, Cmd Msg )
update msg { state, doc } =
    case msg of
        Create n ->
            ( state, doc, Repo.create "CreateOne" n )

        Clone url ->
            ( state, doc, Repo.clone "Clone" url )

        Created ( ref, urls ) ->
            ( state, { doc | urls = doc.urls ++ urls }, Cmd.none )


view : Model State Doc -> Html Msg
view { doc } =
    div []
        [ button [ onClick <| Create 1 ] [ text "Create empty doc" ]
        , Html.ul []
            (doc.urls
                |> List.map
                    (\url ->
                        Html.li []
                            [ text url
                            , button [ onClick <| Clone url ] [ text "Clone" ]
                            ]
                    )
            )
        ]


subscriptions : Model State Doc -> Sub Msg
subscriptions model =
    Repo.created Created
