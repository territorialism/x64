--[[
	x64ui/example.luau

	A complete tour of the library. Every control, plus commands, keybinds,
	dependency boxes, config profiles, theming and teardown.

	Run this after the loader:
		loadstring(game:HttpGet("<base>/example.luau"))()
]]

local X64UI = loadstring(game:HttpGet("https://raw.githubusercontent.com/iris/x64ui/main/loader.luau"))()

-- Local development instead of the network:
-- local X64UI = loadstring(readfile("x64ui/src/init.luau"))()

if not X64UI or X64UI.Supported == false then
	warn("x64ui is not sup
	Accent     = Color3.fromRGB(0, 122, 204),
	AccentText = Color3.fromRGB(102, 170, 224),
})

--==============================================================
-- WINDOW
--==============================================================

local window = X64UI:CreateWindow({
	Title   = "x64ui demo  ·  v" .. tostring(X64UI.Version),
	Name    = "X64UIDemo",
	Width   = 1020,
	Height  = 660,
	Console = true,
	Status  = true,
	-- Scale = 1,          -- omit to auto-pick from viewport height
	-- SingleInstance = false,
})

if not window then return end

X64UI.MenuKeybind = Enum.KeyCode.RightShift
X64UI:SetWatermark("x64ui demo  |  RightShift to toggle  |  Ctrl+P for commands")
X64UI:SetKeybindList(true)

--==============================================================
-- TAB: MAIN
--==============================================================

local main = window:AddTab("Main")

local playerGroup = main:AddLeftGroupbox("Player")

playerGroup:AddLabel("Movement and character options.", true)

local flyToggle = playerGroup:AddToggle("Fly_Enabled", {
	Text    = "Fly",
	Default = false,
	Tooltip = "Hold the bind or toggle it from the keybind list",
	Callback = function(value, does not
-- render inline on the toggle's row.
flyToggle:AddKeyPicker("Fly_Bind", {
	Text    = "Fly bind",
	Default = "F",
	Mode    = "Toggle",           -- Toggle | Hold | Press | Always
	OnClick = function(state)
		flyToggle:SetValue(state)
	end,
})

local speedSlider = playerGroup:AddSlider("Fly_Speed", {
	Text     = "Fly speed",
	Min      = 10,
	Max      = 250,
	Default  = 60,
	Rounding = 0,
	Suffix   = " u/s",
	Callback = function(value)
		window:SetStatus("Speed: " .. value)
	end,
})

playerGroup:AddDivider()

local modeDropdown = playerGroup:AddDropdown("Fly_Mode", {
	Text    = "Fly mode",
	Values  = { "Velocity", "CFrame", "Tween" },
	Default = "Velocity",
	Callback = function(value)
		window:Log("Fly mode set to " .. tostring(value))
	end,
})

local targetsDropdown = playerGroup:AddDropdown("Aim_Targets", {
	Text    = "Target parts",
	Values  = { "Head", "UpperTorso", "LowerTorso", "HumanoidRootPart" },
	Default = { "Head", "UpperTorso" },
	Multi   = true,
	Callback = function(values)
		window:Log(("%d target part(s) selected"):format(#values))
	end,
})

playerGroup:AddNumericInput("Aim_FOV", {= "Note",
	Placeholder = "anything you want to remember",
	Default     = "",
	MaxLength   = 120,
})

playerGroup:AddButton({
	Text    = "Reset movement",
	Tooltip = "Restore every movement value to its default",
	Callback = function()
		window.History:WithTransaction("Reset movement", function()
			flyToggle:SetValue(false)
			speedSlider:SetValue(60)
			modeDropdown:SetValue("Velocity")
		end)
		X64UI:Notify({ Title = "Reset", Description = "Movement restored.", Severity = "good" })
	end,
})

--==============================================================
-- TAB: MAIN — right side
--==============================================================

local diagnostics = main:AddRightGroupbox("Diagnostics")

local statsTable = diagnostics:AddTable("Stats_Table", {
	Text    = "Session",
	Columns = { "Metric", "Value" },
	Rows    = {
		{ Metric = "Loaded",  Value = os.date("%X") },
		{ Metric = "Version", Value = tostring(X64UI.Version) },
	},
	Height  = 90,
})

diagnostics:AddButton({
	Text = "Append a row",
	Callback = function()
		statsTable:AddRow({ Metric = "Ping", Value = tostring(math.random(20, 90)) .. " ms" })
	end,
})

diagnostics:AddListBox("Log_Filters", {
	Text    = "Log filters",
	Values  = { "info", "warn", "error", "good" },
	
		{
			Text = "Workspace",
			Children = {
				{ Text = "Baseplate" },
				{ Text = "Spawn", Children = { { Text = "SpawnLocation" } } },
			},
		},
		{ Text = "Lighting" },
	},
	Callback = function(node)
		window:Log("Selected node: " .. tostring(node.Text))
	end,
})

diagnostics:AddButton({
	Text = "Add tree node",
	Callback = function()
		tree:AddNode("Node " .. tostring(math.random(100, 999)))
	end,
})

--==============================================================
-- TAB: VISUALS — dependency box
--==============================================================

local visuals = window:AddTab("Visuals")
local espGroup = visuals:AddLeftGroupbox("ESP")

local espToggle = espGroup:AddToggle("ESP_Enabled", {
	Text    = "Enable ESP",
	Default = false,
})

-- Everything inside the box hides when the dependency is not satisfied.
local espBox = espGroup:AddDependencyBox():SetupDependencies({ [espToggle] = true })

espBox:AddToggle("ESP_Boxes",  { Text = "Boxes",  Default = true })
espBox:AddToggle("ESP_Names",  { Text = "Names",  Default = true })
espBox:AddToggle("ESP_Health", { Text = "Health", Default = false })

espBox:AddColorPicker("ESP_Color", {
	Text    = "Box colour",
	Default = Color3.fromRGB(0, 255, 140),
	Callback = function(color)
		window:Log("2000,
	Default   = 600,
	Rounding = 0,
	Suffix   = " studs",
})

-- A predicate dependency instead of an equality check.
local advancedGroup = visuals:AddRightGroupbox("Advanced")
local qualitySlider = advancedGroup:AddSlider("Render_Quality", {
	Text    = "Quality",
	Min     = 0,
	Max     = 10,
	Default = 5,
})

local highQualityBox = advancedGroup:AddDependencyBox():SetupDependencies({
	[qualitySlider] = function(value) return value >= 7 end,
})

highQualityBox:AddLabel("Shown only when quality is 7 or higher.", true)
highQualityBox:AddToggle("Render_Shadows", { Text = "Soft shadows", Default = false })

--==============================================================
-- TAB: SETTINGS
--==============================================================

local settings = window:AddTab("Settings")
local configGroup = settings:AddLeftGroupbox("Configuration")

local profileInput = configGroup:AddInput("Profile_Name", {
	Text        = "Profile name",
	Placeholder = "default",
	Default     = "default",
	NoSave      = true,          -- excluded from saved configs
})

configGroup:AddButton({
	Text = "Save profile",
	Callback = function()
		window:SaveProfile(profileInput:GetValue())
	end,
})

configGroup:AddButton({
	Text = "Load profile",
	Callback = function()
		window:LoadProfile(profileInput:GetValue())
	end,
})

configGroup:AddButton({
	Text = "Delete profile",
	Callback = function()
		local name = profileInput:GetValue()

		X64UI:Dancel", Cancel = true },
				{
					Text = "Delete",
					Primary = true,
					Callback = function()
						window:DeleteProfile(name)
					end,
				},
			},
		})
	end,
})

local uiGroup = settings:AddRightGroupbox("Interface")

uiGroup:AddSlider("UI_Scale", {
	Text     = "UI scale",
	Min      = 0.5,
	Max      = 2,
	Default  = window:GetScale(),
	Rounding = 2,
	Callback = function(value)
		window:SetScale(value)
	end,
})

uiGroup:AddToggle("UI_Console", {
	Text    = "Show log pane",
	Default = true,
	Callback = function(value)
		if value ~= window.ConsoleVisible then window:ToggleConsole() end
	end,
})

uiGroup:AddKeyPicker("UI_MenuBind", {
	Text    = "Menu bind",
	Default = "RightShift",
	Mode    = "Press",
	Callback = function(value)
		X64UI.MenuKeybind = value
		window:Log("Menu bind set to " .. tostring(value))
	end,
})

-- Demonstrates that disabled and read-only controls are genuinely inert.
local lockedToggle = uiGroup:AddToggle("UI_Locked", { Text = "This toggle is disabled", Default = true })
lockedToggle:SetDisabled(true)

local readOnlyInput = uiGroup:AddInput("UI_ReadOnly", { Text = "Read-only field", Default = "cannot edit" })
readOnlyInput:SetReadOnly(true)

--ify", "toast", "test" },
	Callback = function()
		local severities = { "info", "good", "warn", "error" }
		local pick = severities[math.random(#severities)]

		X64UI:Notify({
			Title       = "Severity: " .. pick,
			Description = "Raised from the command palette.",
			Severity    = pick,
			Time        = 4,
		})
	end,
})

X64UI:RegisterCommand("Demo: Toggle ESP", {
	Description = "Flip the ESP master switch",
	Keywords    = { "esp", "visuals" },
	Callback = function()
		espToggle:SetValue(not espToggle:GetValue())
	end,
})

--==============================================================
-- EVENTS
--==============================================================

window.Events.Changed:Connect(function(key, value)
	if key == "ActiveTab" then
		window:Log("Switched to tab: " .. tostring(value))
	end
end)

window.Events.VisibilityChanged:Connect(function(visible)
	if visible then window:Log("Window shown") end
end)

window.Events.Destroying:Connect(function()
	X64UI:SetWatermark(nil)
	X64UI:SetKeybindList(false)
end)

--==============================================================
-- FINISH
--==============================================================

window:SelectTab("Main")
X64UI:ReportCapabilities(window)

-- Restore the previous session if one exists, without firing every callback.
window:LoadConfig("x64ui_configUI.Version),
	Description = "Demo loaded. RightShift toggles the window.",
	Severity    = "good",
	Time        = 5,
})

return window
