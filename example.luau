--[[
  x64ui/example.luau
  Tour of the library: controls, commands, config, theming.
]]

local X64UI = loadstring(game:HttpGet(
  "https://raw.githubusercontent.com/territorialism/x64/main/loader.luau?" .. tostring(os.clock())
))()

if not X64UI or X64UI.Supported == false then
  warn("[example] x64ui is not available on this device")
  return
end

X64UI:ApplyTheme({
  Accent = Color3.fromRGB(0, 122, 204),
  AccentText = Color3.fromRGB(102, 170, 224),
})

local window = X64UI:CreateWindow({
  Title = "x64ui demo · v" .. tostring(X64UI.Version),
  Name = "X64UIDemo",
  Width = 1020,
  Height = 660,
  Console = true,
  Status = true,
})

if not window then
  warn("[example] CreateWindow failed")
  return
end

X64UI.MenuKeybind = Enum.KeyCode.RightShift
if X64UI.SetWatermark then
  X64UI:SetWatermark("x64ui demo | RightShift to toggle | Ctrl+P for commands")
end
if X64UI.SetKeybindList then
  X64UI:SetKeybindList(true)
end

local main = window:AddTab("Main")
local playerGroup = main:AddLeftGroupbox("Player")
playerGroup:AddLabel("Movement and character options.", true)

local flyToggle = playerGroup:AddToggle("Fly_Enabled", {
  Text = "Fly",
  Default = false,
  Callback = function(value)
    window:Log("Fly: " .. tostring(value))
  end,
})

if flyToggle.AddKeyPicker then
  flyToggle:AddKeyPicker("Fly_Bind", {
    Text = "Fly bind",
    Default = "F",
    Mode = "Toggle",
    OnClick = function(state)
      flyToggle:SetValue(state)
    end,
  })
else
  playerGroup:AddKeyPicker("Fly_Bind", {
    Text = "Fly bind",
    Default = "F",
    Mode = "Toggle",
  })
end

local speedSlider = playerGroup:AddSlider("Fly_Speed", {
  Text = "Fly speed",
  Min = 10,
  Max = 250,
  Default = 60,
  Rounding = 0,
  Suffix = " u/s",
  Callback = function(value)
    window:SetStatus("Speed: " .. tostring(value))
  end,
})

playerGroup:AddDivider()

local modeDropdown = playerGroup:AddDropdown("Fly_Mode", {
  Text = "Fly mode",
  Values = { "Velocity", "CFrame", "Tween" },
  Default = "Velocity",
})

playerGroup:AddDropdown("Aim_Targets", {
  Text = "Target parts",
  Values = { "Head", "UpperTorso", "LowerTorso", "HumanoidRootPart" },
  Default = { "Head", "UpperTorso" },
  Multi = true,
})

playerGroup:AddNumericInput("Aim_FOV", {
  Text = "Aim FOV",
  Min = 10,
  Max = 500,
  Default = 120,
})

playerGroup:AddInput("Note", {
  Text = "Note",
  Placeholder = "anything you want to remember",
  Default = "",
})

playerGroup:AddButton({
  Text = "Reset movement",
  Callback = function()
    if window.History and window.History.WithTransaction then
      window.History:WithTransaction("Reset movement", function()
        flyToggle:SetValue(false)
        speedSlider:SetValue(60)
        modeDropdown:SetValue("Velocity")
      end)
    else
      flyToggle:SetValue(false)
      speedSlider:SetValue(60)
      modeDropdown:SetValue("Velocity")
    end
    X64UI:Notify({ Title = "Reset", Description = "Movement restored.", Time = 3 })
  end,
})

local diagnostics = main:AddRightGroupbox("Diagnostics")
if diagnostics.AddTable then
  local statsTable = diagnostics:AddTable("Stats_Table", {
    Text = "Session",
    Columns = { "Metric", "Value" },
    Rows = {
      { Metric = "Loaded", Value = os.date("%X") },
      { Metric = "Version", Value = tostring(X64UI.Version) },
    },
    Height = 90,
  })
  diagnostics:AddButton({
    Text = "Append a row",
    Callback = function()
      if statsTable.AddRow then
        statsTable:AddRow({ Metric = "Ping", Value = tostring(math.random(20, 90)) .. " ms" })
      elseif statsTable.SetRows then
        local rows = statsTable:GetRows() or {}
        table.insert(rows, { Metric = "Ping", Value = tostring(math.random(20, 90)) .. " ms" })
        statsTable:SetRows(rows)
      end
    end,
  })
end

local visuals = window:AddTab("Visuals")
local espGroup = visuals:AddLeftGroupbox("ESP")
local espToggle = espGroup:AddToggle("ESP_Enabled", {
  Text = "Enable ESP",
  Default = false,
})

if espGroup.AddDependencyBox then
  local espBox = espGroup:AddDependencyBox()
  if espBox.SetupDependencies then
    espBox:SetupDependencies({ [espToggle] = true })
  end
  espBox:AddToggle("ESP_Boxes", { Text = "Boxes", Default = true })
  espBox:AddToggle("ESP_Names", { Text = "Names", Default = true })
  if espBox.AddColorPicker then
    espBox:AddColorPicker("ESP_Color", {
      Text = "Box colour",
      Default = Color3.fromRGB(0, 255, 140),
    })
  end
  espBox:AddSlider("ESP_MaxDist", {
    Text = "Max distance",
    Min = 50,
    Max = 2000,
    Default = 600,
    Rounding = 0,
    Suffix = " studs",
  })
end

local settings = window:AddTab("Settings")
local configGroup = settings:AddLeftGroupbox("Configuration")
local profileInput = configGroup:AddInput("Profile_Name", {
  Text = "Profile name",
  Placeholder = "default",
  Default = "default",
  NoSave = true,
})

configGroup:AddButton({
  Text = "Save profile",
  Callback = function()
    if window.SaveProfile then
      window:SaveProfile(profileInput:GetValue())
    else
      window:SaveConfig("x64ui_config.json")
    end
  end,
})

configGroup:AddButton({
  Text = "Load profile",
  Callback = function()
    if window.LoadProfile then
      window:LoadProfile(profileInput:GetValue())
    else
      window:LoadConfig("x64ui_config.json", { FireCallbacks = false })
    end
  end,
})

local uiGroup = settings:AddRightGroupbox("Interface")
if window.GetScale and window.SetScale then
  uiGroup:AddSlider("UI_Scale", {
    Text = "UI scale",
    Min = 0.5,
    Max = 2,
    Default = window:GetScale(),
    Rounding = 2,
    Callback = function(value)
      window:SetScale(value)
    end,
  })
end

uiGroup:AddKeyPicker("UI_MenuBind", {
  Text = "Menu bind",
  Default = "RightShift",
  Mode = "Press",
  Callback = function(value)
    X64UI.MenuKeybind = value
    window:Log("Menu bind set to " .. tostring(value))
  end,
})

local lockedToggle = uiGroup:AddToggle("UI_Locked", { Text = "This toggle is disabled", Default = true })
if lockedToggle.SetDisabled then lockedToggle:SetDisabled(true) end

if X64UI.RegisterCommand then
  X64UI:RegisterCommand("Notify Demo", {
    Description = "Show a random severity toast",
    Keywords = { "notify", "toast", "test" },
    Callback = function()
      X64UI:Notify({
        Title = "Command palette",
        Description = "Raised from Ctrl+P.",
        Time = 3,
      })
    end,
  })
  X64UI:RegisterCommand("Toggle ESP", {
    Description = "Flip the ESP master switch",
    Keywords = { "esp", "visuals" },
    Callback = function()
      espToggle:SetValue(not espToggle:GetValue())
    end,
  })
end

window:SelectTab("Main")
if X64UI.ReportCapabilities then
  X64UI:ReportCapabilities(window)
end

window:LoadConfig("x64ui_config.json", {
  Silent = true,
  FireCallbacks = false,
  RecordHistory = false,
  ApplyLayout = true,
})

window:Log("x64ui example loaded · v" .. tostring(X64UI.Version))
X64UI:Notify({
  Title = "x64ui " .. tostring(X64UI.Version),
  Description = "Demo loaded. RightShift toggles the window.",
  Time = 5,
})

return window
