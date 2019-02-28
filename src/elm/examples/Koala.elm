module Koala exposing (Doc, Msg, State, gizmo)

import Config
import Colors
import Css exposing (..)
import Gizmo exposing (Flags, Model)
import Html.Styled as Html exposing (..)
import Html.Styled.Attributes as Attr exposing (css)
import Html.Styled.Events exposing (onClick)
import Repo
import List


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
    { activeNote : Maybe String
    }


{-| Document state
-}
type alias Doc =
    { notes : List String }


init : Flags -> ( State, Doc, Cmd Msg )
init flags =
    ( { activeNote = Nothing
      } {- initial State -}
    , { notes = [] 
      } {- initial Doc -}
    , Cmd.none {- initial Cmd -}
    )


subscriptions : Model State Doc -> Sub Msg
subscriptions model =
    Repo.created Created 


{-| Message type for modifying State and Doc inside update
-}
type Msg
    = NoOp
    | Create
    | Created ( Repo.Ref, List String )
    | SelectItem String


update : Msg -> Model State Doc -> ( State, Doc, Cmd Msg )
update msg { state, doc } =
    case msg of
        NoOp ->
            ( state
            , doc
            , Cmd.none
            )
        Create ->
            ( state
            , doc
            , Repo.create "KoalaCreate" 1
            )
        Created (ref, newNotes) ->
            ( { state | activeNote = List.head newNotes }
            , { doc | notes = doc.notes ++ newNotes}
            , Cmd.none
            )
        SelectItem item ->
            ( { state | activeNote = Just item }
            , doc
            , Cmd.none
            )



view : Model State Doc -> Html Msg
view ({ flags, doc, state } as model) =
    div
        [ css
            [ property "grid-template-columns" "20% 80%"
            , property "grid-template-areas" "'sidebar content'"
            , property "display" "grid"
            , height (pct 100)
            ]
        ]
        [ sidebar model
        , content state.activeNote
        ]


paddingVal : Float
paddingVal =
    20

sidebar : Model State Doc -> Html Msg
sidebar { state, doc } =
    div
        [ css
            [ property "grid-area" "sidebar"
            , overflow auto
            , position relative
            , borderRight3 (px 1) solid borderColor
            ]
        ]
        [ div
            [ onClick Create
            , css
                [ padding (px 10)
                , cursor pointer
                , marginTop (px 5)
                , color (hex Colors.primary)
                , textAlign center
                , hover
                    [ color (hex Colors.darkerPrimary)
                    ]
                ]
            ]
            [ text "New note +"
            ]
        , ul
            [ css
                [ property "display" "grid"
                , property "grid-auto-rows" "1fr"
                , property "grid-template-columns" "100%"
                ]
            ]
            (List.map (listItem (isActiveNote state.activeNote)) doc.notes)
        ]

isActiveNote : Maybe String -> String -> Bool
isActiveNote activeNote n =
    case activeNote of
        Just active ->
            active == n
        Nothing ->
            False

borderColor =
    (hex "#e5e5e5")


listItem : (String -> Bool) -> String -> Html Msg
listItem isActive item =
    li
        [ css
            [ padding (px 15)
            , borderBottom3 (px 1) solid borderColor
            , borderLeft3 (px 5) solid (if isActive item then (hex Colors.primary) else (hex "fff"))
            , cursor pointer
            , firstChild
                [ borderTop3 (px 1) solid borderColor
                ]
            ]
        , onClick <| SelectItem item
        ]
        [ div
            [ css
                [ color (hex Colors.darkerGrey)
                , marginBottom (px 5)
                , textOverflow ellipsis
                , whiteSpace noWrap
                , overflow hidden
                ]
            ]
            [ docProperty "title" item
            ]
        , div
            [ css
                [ property "display" "-webkit-box"
                , property "-webkit-line-clamp" "2"
                , property "-webkit-box-orient" "vertical"
                , overflow hidden
                , color (hex Colors.darkGrey)
                , fontSize (Css.em 0.9)
                ]
            ]
            [ docProperty "body" item
            ]
        ]
                
docProperty : String -> String -> Html Msg
docProperty prop url =
        Gizmo.renderWith [ Gizmo.attr "prop" prop, Gizmo.attr "default" "Untitled" ] Config.property url


content : Maybe String -> Html Msg
content activeNote =
    div
        [ css
            [ property "grid-area" "content"
            , overflow auto
            , paddingTop (px 10)
            , width (ch 80)
            , margin2 (px 0) auto
            ]
        ]
        ( case activeNote of
            Just url ->
                [ note url
                ]
            Nothing ->
                [ div
                    [ css 
                        [ textAlign center
                        , color (hex Colors.darkGrey)
                        , position relative
                        , top (pct 25)
                        ]
                    ]
                    [ p 
                        [ css
                            [ marginBottom (px 15)
                            ]
                        ]
                        [ text "Welcome to Koala!"
                        ]
                    , p
                        []
                        [ text "Koala is a Bear-like note-taking tool. Feel free to contribute!"
                        ]
                    ]
                ]
        )

note : String -> Html Msg
note url =
    Gizmo.render Config.note url