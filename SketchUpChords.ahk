#Requires AutoHotkey v2.0
#SingleInstance Force
SendMode "Input"

; ==============================================================================
; SketchUp Chords - type a short word in SketchUp to fire a keyboard shortcut.
; Chords live in shortcuts.csv next to this script (triggers,keys,description).
; ==============================================================================

; The SketchUp window the chords are active in. Find yours with Window Spy
; (right-click the AutoHotkey tray icon) if the chords don't fire.
SKETCHUP_WINDOW := "ahk_class Qt691QWindowToolSaveBits"

; Where Search opens, measured from the top-left corner of the SketchUp
; window. Set to "" to leave it where SketchUp puts it.
PALETTE_OFFSET := [20, 80]

CSV_PATH := A_ScriptDir "\shortcuts.csv"

; Every command, keyed by its first trigger, for a future WhichKey-style UI
global CommandRegistry := Map()

A_TrayMenu.Add()
A_TrayMenu.Add("Edit shortcuts", (*) => Run('notepad.exe "' CSV_PATH '"'))
A_TrayMenu.Add("Reload shortcuts", (*) => Reload())

; Hotstring() binds to whatever criterion is current, so the whole load
; has to run inside this scope
HotIfWinActive(SKETCHUP_WINDOW)
LoadChords(CSV_PATH)
HotIfWinActive()

; EVENT_SYSTEM_FOREGROUND fires as Search takes focus, before it is drawn
if PALETTE_OFFSET
    DllCall("SetWinEventHook", "uint", 0x3, "uint", 0x3, "ptr", 0
        , "ptr", CallbackCreate(MovePalette, "F", 7), "uint", 0, "uint", 0, "uint", 0)

; Panels such as Controller share Search's window class; only Search is
; titled plain "SketchUp", and it is owned by the main SketchUp window
MovePalette(hook, event, hwnd, *) {
    try {
        if !WinExist(SKETCHUP_WINDOW " ahk_id " hwnd) || WinGetTitle(hwnd) != "SketchUp"
            return
        owner := DllCall("GetWindow", "ptr", hwnd, "uint", 4, "ptr")  ; GW_OWNER
        if !owner
            return
        ; The visible frame, without the invisible resize border around it
        rect := Buffer(16)
        DllCall("dwmapi\DwmGetWindowAttribute", "ptr", owner, "uint", 9, "ptr", rect, "uint", 16)
        WinMove(NumGet(rect, 0, "int") + PALETTE_OFFSET[1]
            , NumGet(rect, 4, "int") + PALETTE_OFFSET[2], , , hwnd)
    }
}

Toast(msg, ms := 2000) {
    ToolTip msg
    SetTimer () => ToolTip(), -ms
}

LoadChords(path) {
    if !FileExist(path) {
        Toast("Chords not loaded: " path " missing", 4000)
        return
    }
    Loop Read, path {
        line := Trim(A_LoopReadLine)
        if (line = "" || SubStr(line, 1, 1) = ";")
            continue

        ; Parsing as CSV honours quoted fields, so descriptions can hold commas
        col := []
        Loop Parse, line, "CSV"
            col.Push(Trim(A_LoopField))
        if (col.Length < 2 || col[1] = "" || col[2] = "")
            continue

        map_cmd(StrSplit(col[1], "|", " "), col[2], col.Length >= 3 ? col[3] : "")
    }
}

map_cmd(triggers, keys, description := "") {
    ; Send() types a bare "F4" as two letters; a function key needs braces
    keys := RegExReplace(keys, "i)^([\^+!#]*)(F\d{1,2})$", "$1{$2}")

    ; A bare trigger fires instantly; one written with its own hotstring
    ; options (::rect waits for Space or Enter) is passed through as-is
    aliases := []
    for trigger in triggers {
        if RegExMatch(trigger, "^\{(\w+)\}$", &m) {
            DoubleTap(m[1], keys)
            aliases.Push(trigger)
            continue
        }
        if (SubStr(trigger, 1, 1) != ":")
            trigger := ":*:" trigger
        Hotstring(trigger, (*) => Fire(keys))
        aliases.Push(RegExReplace(trigger, "^:[^:]*:"))
    }
    CommandRegistry[aliases[1]] := {aliases: aliases, keys: keys, desc: description}
}

; A {Key} trigger fires on a double-tap. Only a press that directly follows
; another press of the same key is caught, so the first tap still reaches
; SketchUp (e.g. Space opens Search) and so do keys typed in between.
DoubleTap(key, keys) {
    HotIf((*) => WinActive(SKETCHUP_WINDOW) && A_PriorKey = key)
    Hotkey(key, (*) => Fire(keys))
    HotIfWinActive(SKETCHUP_WINDOW)
}

Fire(shortcut) {
    Send("{Esc}")
    Sleep(50)
    Send(AltUpFirst(shortcut))
}

; Releasing Alt after Ctrl or Shift leaves SketchUp's menu bar holding the
; keyboard focus until the window is clicked; releasing Alt first does not
AltUpFirst(keys) {
    if !RegExMatch(keys, "^([\^+!#]*!)([\^+!#]*)(\{[^}]+\}|[^{])$", &m)
        return keys
    names := Map("^", "Ctrl", "+", "Shift", "!", "Alt", "#", "LWin")
    down := "", up := "{Alt up}"
    for mod in StrSplit(m[1] m[2]) {
        down .= "{" names[mod] " down}"
        if (mod != "!")
            up .= "{" names[mod] " up}"
    }
    return down m[3] up
}
