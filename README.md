# x64ui

An x64dbg-inspired UI library for desktop Roblox executors.

**Version:** `6.0.0-desktop` (loads full build from the published entry) · **Platform:** desktop only

---

## Install

Always cache-bust the loader URL:

```lua
local url = "https://raw.githubusercontent.com/territorialism/x64/main/loader.luau"
local X64UI = loadstring(game:HttpGet(url .. "?cb=" .. os.time(), true))()
```

Optional config (set before running the loader):

```lua
getgenv().X64UILoaderConfig = {
  ForceRefresh = true,
  Verbose = true,
  Pin = "6.0.0-desktop",
}
```

---

## Layout

```text
x64/
├── version       # 6.0.0-desktop
├── loader.luau   # fetch + validate + execute
├── main.luau     # library entry (or thin re-export)
├── example.luau  # demo
└── README.md
```

No chunk assembly. One library file.

---

## Quick start

```lua
local window = X64UI:CreateWindow({ Title = "My Script" })
local tab = window:AddTab("Main")
local group = tab:AddLeftGroupbox("Options")
group:AddToggle("Enabled", {
  Text = "Enable",
  Default = false,
  Callback = function(value) print(value) end,
})
```

See `example.luau` for a full tour of controls, config, and commands.
