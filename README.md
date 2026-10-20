# SketchUp Chords

Type a short word in SketchUp and get the tool, without hunting for the
shortcut. For example, `pla` opens Section Planes, `mv` is Move and `iso`
switches to the Iso view. Chords are plain text, so you can type them with
one hand while the other stays on the mouse.

Windows only. Free to use, share and modify under the MIT license.

## Install

1. Install [AutoHotkey v2](https://www.autohotkey.com/).
2. Download this folder: `SketchUpChords.ahk` and `shortcuts.csv` must stay
   together.
3. Double-click `SketchUpChords.ahk`. A green **H** icon appears in the tray.

To start it with Windows, put a shortcut to `SketchUpChords.ahk` in the
Startup folder (press `Win+R`, type `shell:startup`).

## Use

With SketchUp focused, type a chord such as `pla`. It fires as soon as the
last letter is typed. Nothing else is needed. The chords only work in the
SketchUp window, so typing elsewhere is unaffected.

Each chord presses `Esc` first to cancel the current tool, then sends the
shortcut.

## Make it yours

Every chord is one line in `shortcuts.csv`:

```
pla|plan,{F4},View/Section Planes
```

| Column | Meaning |
| --- | --- |
| triggers | What you type. Separate aliases with `\|`. Fires as soon as it's typed; start it with `::` (e.g. `::rect`) to wait for Space or Enter instead. Write a key in braces (e.g. `{Space}`) to fire on a double-tap of that key; the first tap still does what SketchUp has it bound to. |
| keys | The SketchUp shortcut it presses: `^` Ctrl, `+` Shift, `!` Alt. Put named keys in braces: `{F4}`, `{Space}`, `{Delete}`. |
| description | Optional note. Put it in quotes if it contains a comma. |

The included file matches **my** SketchUp shortcuts, including some for the
Curic, OpenCutList and 5D+ extensions. Change the keys to match your own
(`Window > Preferences > Shortcuts`), and delete any lines you don't need.

After editing, right-click the tray icon and choose **Reload shortcuts**.
**Edit shortcuts** in the same menu opens the file in Notepad.

### Avoiding clashes

A chord fires the instant it's typed, so a short chord can block a longer one
that starts the same way. If `re` exists, `rect` can never be reached. Keep
chords distinct at the start, or make the shorter one wait for an ending key:
`::re` lets `rect` through, and fires `re` when you press Space or Enter.

## Troubleshooting

**Nothing happens in SketchUp.** The script finds SketchUp by its window
class, and that can change between SketchUp versions. Right-click the tray
icon, open **Window Spy**, click into SketchUp's drawing area and copy the
`ahk_class` line. Paste it into `SKETCHUP_WINDOW` near the top of
`SketchUpChords.ahk`, then reload.

**A chord types letters instead of pressing a key.** The key name needs
braces: `{F4}`, not `F4`.
