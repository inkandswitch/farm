module Keyboard exposing (Combo(..), shortcuts, shortcut, onPress, onDown, onUp)

import Browser.Events as BrowserEvents exposing (onKeyDown)
import Json.Decode as D exposing (Decoder)
import List exposing (map)
import Html.Styled as Html
import Html.Styled.Events as HtmlEvents
-- TODO: Can we easily support Html and Styled.Html?

-- Note: All KeyboardEvent.key values are passed through `String.toLower`

type Combo
    = Alone
    | Key Char -- Catch-all, e.g. Combo '{'
    -- Modifiers
    | Ctrl Combo
    | Shift Combo
    | Alt Combo
    | Option Combo -- Alt alias for Mac, represents option/⌥
    | Meta Combo
    | Cmd Combo -- Meta alias for Mac, represents command
    -- Letters (match to lowercase)
    | A
    | B
    | C
    | D
    | E
    | F
    | G
    | H
    | I
    | J
    | K
    | L
    | M
    | N
    | O
    | P
    | Q
    | R
    | S
    | T
    | U
    | V
    | W
    | X
    | Y
    | Z
    -- Digits
    | Zero
    | One
    | Two
    | Three
    | Four
    | Five
    | Six
    | Seven
    | Eight
    | Nine
    -- Arrow keys
    | Left
    | Right
    | Up
    | Down
    -- Control & Misc
    | Spacebar
    | Esc
    | Escape
    | Enter
    | Backspace
    | Delete
    | PageUp
    | PageDown
    | End
    | Home
    | Insert
    | PrintScreen
    | NumLock
    | ScrollLock


onPress : Combo -> msg -> Html.Attribute msg
onPress combo msg =
    HtmlEvents.on "keypress" (D.map (\_ -> msg) <| comboDecoder combo)


onDown : Combo -> msg -> Html.Attribute msg
onDown combo msg =
    HtmlEvents.on "keydown" (D.map (\_ -> msg) <| comboDecoder combo)


onUp : Combo -> msg -> Html.Attribute msg
onUp combo msg =
    HtmlEvents.on "keyup" (D.map (\_ -> msg) <| comboDecoder combo)


shortcuts : List (Combo, msg) -> Sub msg
shortcuts combos =
    BrowserEvents.onKeyDown
        <| D.oneOf
        <| map (uncurry shortcutDecoder) combos


uncurry : (a -> b -> c) -> (a,  b) -> c
uncurry fn (a, b) =
    fn a b


shortcut : Combo -> msg -> Sub msg
shortcut combo msg =
    BrowserEvents.onKeyDown <| shortcutDecoder combo msg


shortcutDecoder : Combo -> msg -> Decoder msg
shortcutDecoder combo msg =
    case combo of
        Alone ->
            D.fail "A keyboard shortcut for just `Alone` makes no sense!"
        _ ->
            D.map (\_ -> msg) <| comboDecoder combo


comboDecoder : Combo -> Decoder ()
comboDecoder combo =
    case combo of
        Alone ->
            D.succeed ()

        Ctrl remainder ->
            comboModifierDecoder "ctrlCombo" (comboDecoder remainder)

        Alt remainder ->
            comboModifierDecoder "altCombo" (comboDecoder remainder)

        Cmd remainder ->
            comboModifierDecoder "metaCombo" (comboDecoder remainder)

        Shift remainder ->
            comboModifierDecoder "shiftCombo" (comboDecoder remainder)

        Key key ->
            keyDecoder <| String.toLower <| keyForComboCombo combo

        _ ->
            keyDecoder <| String.toLower <| keyForComboCombo combo


comboModifierDecoder : String -> Decoder () -> Decoder ()
comboModifierDecoder combo remainderDecoder =
    D.andThen (\_ -> remainderDecoder) <| modifierDecoder combo


modifierDecoder : String -> Decoder ()
modifierDecoder modifier =
    D.andThen (requireValue True)
        <| D.field modifier D.bool


keyDecoder : String -> Decoder ()
keyDecoder key =
    D.andThen (requireValue key << String.toLower)
        <| D.field "key" D.string


requireValue : a -> a -> Decoder ()
requireValue required actual =
    if required == actual then
        D.succeed ()
    else
        D.fail "Missing required value"


-- Note: In usage, all of these values are passed through `String.toLower`
keyForComboCombo : Combo -> String
keyForComboCombo combo =
    case combo of
        Key key ->
            String.fromChar key
        A ->
            "a"
        B ->
            "b"
        C ->
            "c"
        D ->
            "d"
        E ->
            "e"
        F ->
            "f"
        G ->
            "g"
        H ->
            "h"
        I ->
            "i"
        J ->
            "j"
        K ->
            "k"
        L ->
            "l"
        M ->
            "m"
        N ->
            "n"
        O ->
            "o"
        P ->
            "p"
        Q ->
            "q"
        R ->
            "r"
        S ->
            "s"
        T ->
            "t"
        U ->
            "u"
        V ->
            "v"
        W ->
            "w"
        X ->
            "x"
        Y ->
            "y"
        Z ->
            "z"
        -- Arrow keys
        Left ->
            "ArrowLeft"
        Right ->
            "ArrowRight"
        Up ->
            "ArrowUp"
        Down ->
            "ArrowDown"
        -- Control
        Spacebar ->
            " "
        Escape ->
            "Escape"
        Esc ->
            "Escape"
        Enter ->
            "Enter"
        Backspace ->
            "Backspace" 
        Delete ->
            "Delete"
        PageUp ->
            "PageUp"
        PageDown ->
            "PageDown"
        End ->
            "End"
        Home ->
            "Home"
        -- Digits row
        Zero ->
            "0"
        One ->
            "1"
        Two ->
            "2"
        Three ->
            "3"
        Four ->
            "4"
        Five ->
            "5"
        Six ->
            "6"
        Seven ->
            "7"
        Eight ->
            "8"
        Nine ->
            "9"
        Insert ->
            "Insert"
        NumLock ->
            "NumLock"
        ScrollLock ->
            "ScrollLock"
        _ ->
            "Unsupported"