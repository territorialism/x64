````markdown
# x64ui

An x64dbg-inspired UI library for desktop Roblox executors. Menu bar, toolbar,
tabbed panes, a log console, a status bar, undo/redo history, a command palette,
and a config system with profiles.

**Version:** `6.0.0-desktop` · **Platform:** desktop only · keyboard and mouse required

---

## Requirements

| Requirement | Needed for |
|---|---|
| `loadstring` | Loading the library at all |
| `game:HttpGet` or a `request`-style function | The loader |
| `gethui` | Preferred GUI parent; falls back to `CoreGui`, then `PlayerGui` |
| `writefile` / `readfile` / `isfile` | Config saving and the loader cache |
| `delfile` | Deleting profiles, cleaning the cache |

Only `loadstring` is mandatory. Everything else degrades: without file IO the
library runs but reports that configs are unavailable, and the loader runua
local X64UI = loadstring(game:HttpGet("https://raw.githubusercontent.com/iris/x64ui/main/loader.luau"))()
```

Configured:

```lua
getgenv().X64UILoaderConfig = {
    Branch       = "dev",
    Pin          = "6.0.0-desktop",  -- exact version, ignores the branch head
    ForceRefresh = true,             -- bypass the cache
    Offline      = true,             -- cache only, never hit the network
    Verbose      = false,
}

local X64UI = loadstring(game:HttpGet(".../loader.luau"))()
```

The loader also exposes itself at `getgenv().X64UILoader`, with
`X64UILoader.Clean()` to wipe the cache.

---

## Quick start

```lua
local window = X64UI:CreateWindow({ Title = "My Script" })
local tab    = window:AddTab("Main")
local group  = tab:AddLeftGroupbox("Options")

group:AddToggle("Enabled", {
    Text     = "Enable",
    Default  = false,
    Callback = function(value) print("enabled:", value) end,
})

group:AddSlider("Speed", { Text = "Speed", Min = 0, Max = 100, Default = 50 })
```ScreenGui`, a `Maid`, a `Registry` and a `History` stack.
- **Tab** holds a left and a right scrolling pane.
- **Groupbox** is a titled container in one of those panes.
- **Control** is a toggle, slider, dropdown and so on. Named controls are
  registered and participate in config save and load.

Every control created under a window is destroyed with it. You never need to
clean up manually.

---

## Library API

| Member | Notes |
|---|---|
| `X64UI.Version` | Version string |
| `X64UI.Supported` | `false` on unsupported devices |
| `X64UI.Debug` | `true` logs failed property assignments. Leave it on |
| `X64UI.MenuKeybind` | `Enum.KeyCode` or a bind name string |
| `X64UI.Windows`, `X64UI.ActiveWindow` | Live window list |
| `X64UI:CreateWindow(options)` | Returns a `Window` |
| `X64UI:Notify(options)` | Returns `{ Dismiss }` |
| `X64UI:Dialog(options)` | Returns `{ Gui, Frame, Close, IsOpen }` |
| `X64UI:RegisterCommand(name, options)` | Adds to the command palette |
| `X64UI:U(patch)` | Live update, many keys at once |
| `X64UI:SetWatermark(text)` | Pass `nil` or `""` to hide |
| `X64UI:SetKeybindList(enabled)` | Live bind list, refreshed on a heartbeat |
| `X64UI:GetCapabilities()` | Feature-detection table |
| `X64UI:ReportCapabilities(window)` | Logs the above |
| `X64UI:Unload()` | Destroys every window and auxiliary layer |

### `CreateWindow` options

| Option | Default | Meaning |
|---|---|---|
| `Title` | `"x64dbg UI"` | Title bar text |
| `Name` | `"X64UI"` | `ScreenGui` name |
| `Width`, `Height` | `1020`, `660` | Initial size in local units |
| `Scale` | auto | `0.5`–`2`. Auto-picks `1.15` above 1440p, `0.9` below 900p |
| `Console` | `true` | Show the log pane |
| `Status` | `true` | Show the status bar |
| `DisplayOrder` | `10000` | Base display order |
| `SingleInstance` | `true` | Destroy the previous active window first |
| `HistoryLimit` | `150` | Undo stack depth |

### `Notify` options

`Title`, `Description`, `Time` (seconds, minimum `0.5`), `Severity`
(`info` · `good` · `warn` · `error` · `accent`). Click a toast to dismiss it `260`–`720`, default `420` |
| `Modal` | `true` blocks dismissal by clicking the backdrop |
| `Buttons` | Array of `{ Text, Primary, Cancel, Callback, Id }` |
| `OnClose` | Receives the result id of whichever button closed it |

Enter activates the `Primary` button, Escape activates the `Cancel` button. Both
are captured, so neither leaks to keybinds or the game.

---

## Window API

| Method | Notes |
|---|---|
| `AddTab(name)` | Returns a `Tab`. Idempotent per name |
| `SelectTab(name)` | |
| `Show()` · `Hide()` · `Toggle()` | |
| `SetMinimized(v)` · `SetMaximized(v)` | |
| `SetScale(v)` · `GetScale()` | `0.5`–`2`. Popups follow the window scale |
| `ToggleConsole()` · `ToggleStatusBar()` | |
| `Log(message, severity)` | Batched and rendered on the next frame |
| `ClearLog()` | |
| `SetStatus(text)` | Left-hand status bar text |
| `SaveConfig(path)` · `LoadConfig(path, opts)` | |
| `SaveProfile(name)` · `LoadProfile(name, opts)` · `DeleteProfile(name)` | |
| `OpenCommandPalette()` · `CloseCommandPalette()`ection, instance, thread or function to the maid |
| `Destroy()` | |

### Window fields

`Main`, `Gui`, `Registry`, `History`, `State`, `Events`, `Tabs`, `Dropdowns`,
`ConsoleVisible`, `StatusVisible`, `Minimized`, `Maximized`, `Destroyed`.

### Window events

| Signal | Payload |
|---|---|
| `Events.Changed` | `key, value` — `ActiveTab`, `Minimized`, `Maximized`, `Scale`, `ConsoleVisible`, `StatusVisible`, and every named control change |
| `Events.Focused` | `window` |
| `Events.VisibilityChanged` | `visible` |
| `Events.Destroying` | `window`, fired before teardown |

### History

```lua
window.History:UndoLast()
window.History:RedoLast()

-- Group several changes into one undo step.
window.History:WithTransaction("Reset", function()
    toggle:SetValue(false)
    slider:SetValue(60)
end)
```

`History.Changed` fires after any undo, redo or clear.

---

## Tab and Groupbox

```lua
local tab = window:AddTab("Main")

tab:AddLeftGroupbox(title)
tab:AddRightGroupbox(      -- destroys its controls properly, popups included
group:Destroy()
```

---

## Controls

Common options for every named control: `Text` (label, defaults to the name),
`Default`, `Tooltip`, `Callback(value, previous)`, `NoSave`.

| Method | Extra options | Value type |
|---|---|---|
| `AddLabel(text, wrap)` | — | string |
| `AddButton{ Text, Callback, Tooltip }` | — | — |
| `AddDivider()` | — | — |
| `AddToggle(name, opts)` | — | boolean |
| `AddSlider(name, opts)` | `Min`, `Max`, `Rounding`, `Suffix` | number |
| `AddDropdown(name, opts)` | `Values`, `Multi` | value, or array when `Multi` |
| `AddInput(name, opts)` | `Placeholder`, `MaxLength` | string |
| `AddNumericInput(name, opts)` | `Min`, `Max`, `Rounding` | number |
| `AddKeyPicker(name, opts)` | `Mode`, `NoUI`, `OnClick` | bind name string |
| `AddColorPicker(name, opts)` | `Default` must be a `Color3` | `Color3` |
| `AddListBox(name, opts)` | `Values`, `Multi`, `Height` | value, or array when `Multi` |
| `AddTree(name, opts)` | `Nodes`, `Height` | selected node table |
| `AddTable(name, opts)` | `Columns`, `Rows`, `Height` | rows |
| `AddDependencyBox()` | `:SetupDependencies(mapVisible(v)` | Also closes any open popup the control owns |
| `SetDisabled(v)` | Genuinely inert, not just greyed out |
| `SetReadOnly(v)` | |
| `CanInteract()` | |
| `Destroy()` | |
| `Changed` | Signal, `(value, previous)` |
| `AddKeyPicker` · `AddColorPicker` | Chaining. Adds to the same groupbox on a new row |

### Per-control extras

| Control | Methods |
|---|---|
| Label, Button | `SetText(text)` |
| Slider | `SetLimits(min, max)` |
| Dropdown | `SetValues(values, keepSelection)`, `Open()`, `Close()`, `Toggle()`, `RefreshPosition()` |
| KeyPicker | `GetState()`, `SetMode(mode)`, `Clicked` signal |
| ListBox | `SetValues(values)` |
| Tree | `SetNodes(nodes)`, `AddNode(text, parent)`, `Expand(node, bool)` |
| Table | `SetRows(rows)`, `AddRow(row)`, `ClearRows()`, `GetRows()` |

### Keybind modes

| Mode | Behaviour |
|---|---|
| `Toggle` | Each press flips the state |
| `Hold` | Active only while held. Released automatically on focus loss |
| `Press` | Fires once per press, state retur`/`2`/`3`. The aliases
`Shift`, `Control`, `Alt`, `MB1`, `MB2` and `MB3` match either side.

### Dependency boxes

```lua
local box = group:AddDependencyBox():SetupDependencies({
    [enabledToggle] = true,                             -- equality
    [qualitySlider] = function(v) return v >= 7 end,     -- predicate
})

box:AddToggle("Sub_Option", { Text = "Sub-option" })
```

---

## Keyboard shortcuts

| Shortcut | Action |
|---|---|
| `X64UI.MenuKeybind` (default RightShift) | Show or hide the window |
| `Ctrl+P` | Command palette |
| `Ctrl+Z` / `Ctrl+Y` | Undo / redo |
| `Up` / `Down` / `Enter` / `Escape` | Palette navigation |
| Double-click title bar | Maximize or restore |

---

## Theming

```lua
X64UI:ApplyTheme({ Accent = Color3.fromRGB(255, 90, 90) })
X64UI:SetThemeKey("Background", Color3.fromRGB(12, 12, 14))
```

Keys: `Font`, `TextSize`, `Background`, `TitleBar`, `Toolbar`, `Menu`, `Panel`,
`PanelAlt`, `Border`, `Text`, `Dim`, `Accent`, `AccentText`, `Warning`, `Bad`,
`Good`, `Selection`, `Button`, `ButtonHover`, `Scroll`.

Colours applied through the library are bound weakly, so changesly_Enabled": false },
  "Options": {
    "Fly_Speed": 60,
    "Fly_Mode": "Velocity",
    "Aim_Targets":  { "t": "Multi",  "v": ["Head"] },
    "ESP_Color":    { "t": "Color3", "r": 0, "g": 1, "b": 0.55 }
  },
  "Layout": {
    "Size": [1020, 660], "Pos": [100, 80],
    "Scale": 1, "Console": true, "Status": true,
    "Minimized": false, "Maximized": false,
    "ActiveTab": "Main"
  }
}
```

`LoadConfig(path, opts)` accepts:

| Option | Default | Meaning |
|---|---|---|
| `Silent` | `false` | Suppress log output |
| `FireCallbacks` | `true` | Run control callbacks while applying |
| `RecordHistory` | `true` | Wrap the load in one undo step |
| `ApplyLayout` | `true` | Restore size, position, scale, chrome and active tab |

Writes are staged to a temp file and verified before replacing the target, so an
interrupted save cannot corrupt an existing config. Each key is applied in
isolation: one bad value is rejected and logged rather than aborting the load.
Controls marked `NoSave` are skipped in both directions.

---

## Commands

```lua
X64UI:RegisterCommand("Toggle ESP", {
    Description = "Flip the ESP master switch",
    Keywords    = { "esp", "vis, window sizing, scale, capability reporting and unload. They
act on `X64UI.ActiveWindow`.

---

## Behaviour notes

- **Scale.** `AbsoluteSize` is scaled by `UIScale`; `Size` offsets are not. The
  library converts at every boundary via `Window:ToLocal` and `Window:ToAbsolute`.
  If you position your own instances against window geometry, do the same.
- **Popups.** Dropdown panels, colour pickers and the menu are parented to the
  `ScreenGui` rather than to the window, so they are never clipped by a scrolling
  pane. Each gets a `UIScale` mirroring the window's.
- **Input.** All library input flows through a single router with a capture
  stack. Nothing connects `UserInputService` directly per control, so a panel
  with fifty sliders still runs one mouse-move handler.
- **Log.** Lines are capped at 400 entries and 12 000 characters, trimmed by
  whole lines so rich-text tags are never severed. Auto-scroll pauses whileed download leaves your working copy running.

---

## Limitations

- Desktop only. No touch input, no gamepad navigation.
- Dropdowns and list boxes render at most 200 filtered rows at a time; use the
  search field for larger sets. There is no true windowed virtualization yet.
- The loader validates downloads by length, sentinel and compilation only. That
  catches truncation and error pages, not tampering.
- No screen-reader or accessibility support.

---

## What changed in 6.0.0

A correctness release. The headline fixes:

| Area | Problem |
|---|---|
| Hit testing | Mouse-over tested three points 36px apart and OR'd them, tripling every hit region. Clicking the menu bar started a window drag, and no popup reliably dismissed on an outside click |
| Scrant fires were silently discarded, and the "disconnect-safe" iteration both skipped and double-invoked callbacks |
| Disabled state | `SetDisabled` was cosmetic. Toggles, inputs and colour pickers stayed fully interactive |
| Leaks | Keypickers discarded their router disposers, so every destroyed control kept responding to input. Colour-picker drags, menu items and the popup registry leaked too |
| Command palette | Shipped empty; nothing ever registered a command |
| Dialog | Rendered no title, no body, ran no callback, ignored Escape and returned nothing |
| Config | Version stamping did not match the migration chain, and one throwing callback aborted the whole load |

Full detail is in the changelog at the bottom of `src/init.luau`.
````

---

## One correction to `src/init.luau`

Two `Window` methods are called by the library and by `example.luau` but were never defined in the code I gave you. Add them to the **WINDOW: CORE** section, right after `Window:Focus`:

```lua
function Window:SetStatus(text)
	if self.StatusLabel and self.StatusLabel.Parent then
		self.StatusLabel.Text = tostring(text)
	end
end

function Window:CloseDropdowns()
	for index = #self.Dropdowns, 1, -1

`SetStatus` is called by `SelectTab`, and `CloseDropdowns` by `CloseAllPopups` — without them, switching tabs throws. My fault for not catching it while writing; it is exactly the class of error a test harness would have flagged immediately, which is why I keep suggesting one.

Two things to change before publishing: the `BaseUrl` in `loader.luau` and the `HttpGet` URL in `example.luau` both point at a placeholder repository path.
