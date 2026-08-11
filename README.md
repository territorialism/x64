# x64ui

An x64dbg-inspired UI library for desktop Roblox executors. Menu bar, toolbar, tabbed panes, a log console, a status bar, undo/redo history, a command palette, and a config system with profiles.

**Version:** `6.0.0-desktop` · **Platform:** desktop only · keyboard and mouse required

---

## Requirements

| Requirement | Needed for |
|---|---|
| `loadstring` | Loading the library at all |
| `game:HttpGet` or a `request`-style function | The loader |
| `gethui` | Preferred GUI parent; falls back to CoreGui, then PlayerGui |
| `writefile` / `readfile` / `isfile` | Config saving and the loader cache |
| `delfile` | Deleting profiles, cleaning the cache |

Only `loadstring` is mandatory. Everything else degrades.

---

## Install

```lua
local X64UI = loadstring(game:HttpGet(
  "https://raw.githubusercontent.com/territorialism/x64/main/loader.luau"
))()
```

Configured:

```lua
getgenv().X64UILoaderConfig = {
  Branch = "main",
  Pin = "6.0.0-desktop",
  ForceRefresh = true,
  Offline = false,
  Verbose = false,
}
local X64UI = loadstring(game:HttpGet(
  "https://raw.githubusercontent.com/territorialism/x64/main/loader.luau"
))()
```

The loader is also at `getgenv().X64UILoader` with `X64UILoader.Clean()` to wipe the cache.

---

## Quick start

```lua
local window = X64UI:CreateWindow({ Title = "My Script" })
local tab = window:AddTab("Main")
local group = tab:AddLeftGroupbox("Options")

group:AddToggle("Enabled", {
  Text = "Enable",
  Default = false,
  Callback = function(value) print("enabled:", value) end,
})

group:AddSlider("Speed", {
  Text = "Speed",
  Min = 0,
  Max = 100,
  Default = 50,
})
```

---

## Layout

```text
x64/
├── version          # 6.0.0-desktop (tiny, checked first by loader)
├── loader.luau      # fetch + cache + execute
├── example.luau     # full demo
├── main.luau        # same as src/init.luau (compat)
└── src/
    └── init.luau    # library entry
```

---

## Notes

- Desktop only. No touch / gamepad navigation.
- Keybinds support keyboard modifiers and mouse buttons (`RightShift`, `MouseButton2`, aliases like `Shift` / `MB1`).
- Full chrome is always on: menu bar, toolbar, tabs, log, status.
- See `example.luau` for controls, dependency boxes, profiles, and commands.
