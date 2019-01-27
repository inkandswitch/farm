module Tooltip exposing (Position(..), tooltip)

import Css exposing (..)

type Position
    = Top
    | TopLeft
    | TopRight
    | Right
    | Bottom
    | BottomLeft
    | BottomRight
    | Left
    
defaultStyle : List Style
defaultStyle =
    [ fontSize (Css.em 0.75)
    , color (hex "fff")
    , backgroundColor (hex "333")
    , borderRadius (px 5)
    , padding (px 5)
    ]


tooltip : Position -> String -> List Style
tooltip pos tip =
    [ position relative
    , after
        ([ display none
        , position absolute
        , opacity (num 1)
        , zIndex (int 999999)
        , property "content" (Debug.toString tip)
        , textAlign center
        , property "word-wrap" "break-word"
        , whiteSpace pre
        , pointerEvents none
        ]
        ++ styleForPosition pos
        ++ defaultStyle
        )
    , hover
        [ after
            [ display inlineBlock
            , textDecoration none
            ]
        ]
    ]

styleForPosition : Position -> List Style
styleForPosition position =
    case position of
        Top ->
            [ bottom (pct 100)
            ]
        TopRight ->
            [ bottom (pct 100)
            , left (pct 50)
            , right auto
            ]
        Right ->
            [ left (pct 100)
            ]
        BottomRight ->
            [ top (pct 100)
            , left (pct 50)
            , right auto
            ]
        Bottom ->
            [ top (pct 100)
            , left (px 0)
            ]
        BottomLeft ->
            [ top (pct 100)
            , right (pct 50)
            , left auto
            ]
        Left ->
            [ right (pct 100)
            ]
        TopLeft ->
            [ top (pct 100)
            , right (pct 50)
            , left auto
            ]
        
