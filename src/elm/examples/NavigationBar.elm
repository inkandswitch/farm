module Workspace exposing (Doc, Msg, State, gizmo)

import Gizmo exposing (Flags, Model)
import Html.Styled as Html exposing (..)
import Html.Styled.Attributes exposing (css, value)
import Html.Styled.Events exposing (..)
import Css exposing (..)
import IO
import Navigation
import RealmUrl
import Json.Encode as E
import Json.Decode as D
import Colors
import Clipboard

inputBackgroundColor =
    "e9edf0"

blueBlackFontColor =
    "102542"


gizmo : Gizmo.Program State Doc Msg
gizmo =
    Gizmo.element
        { init = init
        , update = update
        , view = Html.toUnstyled << view
        , subscriptions = subscriptions
        }

type alias Pair =
    { code : String
    , data : String
    }

{-| Ephemeral state not saved to the doc
-}
type alias State =
    { url: String }


{-| Document state
-}
type alias Doc =
    { history : List Pair
    }


init : Flags -> ( State, Doc, Cmd Msg )
init flags =
    ( { url = ""
      }
    , { history = []
      }
    , Cmd.none
    )


{-| Message type for modifying State and Doc inside update
-}
type Msg
    = NavigateToUrl
    | NavigateBack
    | SetUrl String
    | OnKeyPress Int
    | CopyLink


update : Msg -> Model State Doc -> ( State, Doc, Cmd Msg )
update msg ({ flags, state, doc } as model) =
    case msg of
        NavigateToUrl ->
            case RealmUrl.parse state.url of
                Ok _ ->
                    ( { state | url = "" }
                    , doc
                    , Gizmo.emit "navigate" (E.string state.url)
                    )

                Err err ->
                    ( { state | url = "" }
                    , doc
                    , IO.log <| "Could not navigate to " ++ state.url ++ ". " ++ err
                    )

        NavigateBack ->
            ( { state | url = "" }
            , doc
            , Gizmo.emit "navigateback" (E.null)
            )

        SetUrl url ->
            ( { state | url = url }
            , doc
            , Cmd.none
            )


        OnKeyPress key ->
            case Debug.log "OnKeyPress" key of
                13 ->
                    update NavigateToUrl model

                _ ->
                    ( state
                    , doc
                    , Cmd.none
                    )

        CopyLink ->
            case RealmUrl.create { code = flags.code, data = flags.data } of
                Ok url ->
                    ( state
                    , doc
                    , Clipboard.copy url
                    )
                Err err ->
                    ( state
                    , doc
                    , IO.log <| "Could not copy current url: " ++ err
                    )


view : Model State Doc -> Html Msg
view ({ doc, state } as model) =
    div
        [ css
            [ displayFlex
            , padding (px 10)
            , alignItems center
            , boxShadow5 zero (px 2) (px 8) zero (rgba 0 0 0 0.12)
            , borderBottom3 (px 1) solid (hex "ddd")
            , height (px 40)
            ]
        ]
        [ viewNavButton
            NavigateBack
            [ text "<"
            ]
        , viewNavInput state.url
        , viewNavButton
            CopyLink
            [ text "[]"
            ]
        ]

viewNavButton : Msg -> List (Html Msg) -> Html Msg
viewNavButton msg children = 
    button
        [ onClick msg
        , css
            [ flexShrink (num 0)
            , border zero
            , cursor pointer
            , fontSize (Css.em 1)
            , marginRight (px 10)
            , padding (px 5)
            , color (hex Colors.hotPink)
            , fontWeight bold
            , hover
                [ color (hex Colors.darkerHotPink)
                ]
            ]
        ]
        children

viewNavInput : String -> Html Msg
viewNavInput url =
    input
        [ value <| url
        , onKeyDown OnKeyPress
        , onInput SetUrl
        , css
            [ flexGrow (num 1)
            , fontSize (Css.em 0.8)
            , padding (px 5)
            , borderRadius (px 5)
            , backgroundColor (hex inputBackgroundColor)
            , color (hex "777")
            , margin2 (px 0) auto
            , border zero
            , focus
                [ color (hex blueBlackFontColor)
                ]
            ]
        ]
        []
        
viewCurrent : Doc -> String
viewCurrent doc =
    doc
        |> currentPair
        |> Maybe.map RealmUrl.create
        |> Maybe.withDefault (Result.Ok "")
        |> Result.withDefault ""

currentPair : Doc -> Maybe Pair
currentPair =
    .history >> List.head


subscriptions : Model State Doc -> Sub Msg
subscriptions model =
    Sub.none


onKeyDown : (Int -> msg) -> Attribute msg
onKeyDown tagger =
    on "keydown" (D.map tagger keyCode)