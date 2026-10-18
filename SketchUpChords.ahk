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
        if (SubStr(trigger, 1, 1) != ":")
            trigger := ":*:" trigger
        Hotstring(trigger, (*) => Fire(keys))
        aliases.Push(RegExReplace(trigger, "^:[^:]*:"))
    }
    CommandRegistry[aliases[1]] := {aliases: aliases, keys: keys, desc: description}
}

Fire(shortcut) {
    Send("{Esc}")
    Sleep(50)
    Send(shortcut)
}
