--[[
	X64UI — x64dbg-inspired desktop UI library
	6.0.0-desktop  (rewrite of 5.5.1)

	Fixes over 5.5.1 are marked [FIX n] inline. See changelog at the bottom.
]]

--==============================================================
-- BOOTSTRAP
--==============================================================

local VERSION = "6.0.0-desktop"

local unpack = unpack or table.unpack

local Services = setmetatable({}, {
	__index = function(self, key)
		local service = game:GetService(key)
		self[key] = service
		return service
	end,
})

local UserInputService = Services.UserInputService
local RunService       = Services.RunService
local TweenService     = Services.TweenService
local Players          = Services.Players
local GuiService       = Services.GuiService
local HttpService       = Services.HttpService
local Workspace        = Services.Workspace

local traceback = (debug and debug.traceback) or function(err) return tostring(err) end

-- Polyfills, installed before anything uses them.
if not table.clone then
	function table.clone(t)
		local copy = {}
		for k, v in pairs(t) do copy[k] = v end
		return copy
	end
end

if not table.pack then
	function table.pack(...)
		return { n = select("#", ...), ... }
	end
end

-- [FIX 1InputRouter included).
do
	local existing = (getgenv and getgenv().X64UI) or (shared and shared.X64UI)
	if type(existing) == "table" and type(existing.Unload) == "function" then
		pcall(function() existing:Unload() end)
	end
end

--==============================================================
-- LIBRARY TABLE
--==============================================================

local X64UI = {
	Version       = VERSION,
	Supported     = true,
	Debug         = true,   -- [FIX 2] property-set failures are LOUD by default
	MenuKeybind   = Enum.KeyCode.RightShift,
	Windows       = {},
	ActiveWindow  = nil,
	NotifyGui     = nil,
	Commands      = {},
	CommandOrder  = {},
	FocusCounter  = 0,
	Unloaded      = false,
}

-- [FIX 3] Desktop-only guard returns a usable stub instead of nil, so callers
-- that do `local ui = loadstring(...)()` then `ui:CreateWindow()` get a clean
-- no-op and a warning rather than "attempt to index nil".
if UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled then
	warn("[X64UI] Mobile is not supported. This build is desktop-only.")
	return setmetatable({
		Version   = VERSION,
		
	})
end

--==============================================================
-- LOG
--==============================================================

local Log = {}
function Log.info(m)  print("[X64UI] " .. tostring(m)) end
function Log.warn(m)  warn("[X64UI] " .. tostring(m)) end
function Log.error(m) warn("[X64UI ERROR] " .. tostring(m)) end

--==============================================================
-- PLATFORM (file IO)
--==============================================================

local Platform = {
	CanWrite  = type(writefile) == "function",
	CanRead   = type(readfile) == "function" and type(isfile) == "function",
	CanDelete = type(delfile) == "function",
}

function Platform.fileExists(path)
	if not Platform.CanRead then return false end
	local ok, exists = pcall(isfile, path)
	return ok and exists == true
end

function Platform.readFile(path)
	if not Platform.fileExists(path) then return nil end
	local ok, data = pcall(readfile, path)
	return ok and data or nil
end

function Platform.deleteFile(path)
	if not Platform.CanDelete then return false end
	return pcall(delfile, path) == true
end

-- [FIX 4] Atomic write: stage to a temp file, verify the readback, then swap.
-- A crash mid-write can no longer leave a truncated config behind.
function Platform.writeFile(path, content)
	if not Platform.CanWrite then return false end

	local temp = path .. ".tmp"
	if not pcall(writefile, temp, content) then return false end

	if Platform.CanRead then
		local verify = Platform.readFile(temp)
		if verify ~= content then
			Platform.deleteFile(temp)
			return false
		end
	end

	local ok = pcall(writ\147",  -- check mark
	Cross      = "\226\156\149",  -- cross
	ArrowDown  = "\226\150\188",  -- down triangle
	ArrowRight = "\226\150\182",  -- right triangle
	Grip       = "\226\151\162",  -- corner grip
	Minimize   = "\226\128\148",  -- em dash
	Close      = "X",
}

-- [FIX 5] Layer is now the single source of truth for Z ordering. The old file
-- declared this table and then hardcoded 2000 / 2500 / 5000 / 99999 everywhere.
local Layer = {
	Base        = 1,
	Chrome      = 20,
	Panel       = 30,
	Popup       = 2000,
	ColorPicker = 2500,
	Menu        = 3000,
	Modal       = 5000,
	Toast       = 10000,
	Intro       = 32000,
	Tooltip     = 32767,
}

--==============================================================
-- THEME (live, with weak bindings)
--==============================================================

X64UI.Theme = {
	Font        = Enum.Font.Code,
	TextSize    = 13,
	Background  = Color3.fromRGB(19, 19, 21),
	TitleBar    = Color3.fromRGB(31, 31, 34),
	Toolbar     = Color3.fromRGB(33, 33, 33),
	Menu        = Color3.fromRGB(26, 26, 29),
	Panel       = Color3.fromRG),
	Dim         = Color3.fromRGB(128, 128, 136),
	Accent      = Color3.fromRGB(0, 122, 204),
	AccentText  = Color3.fromRGB(88, 158, 216),
	Warning     = Color3.fromRGB(220, 220, 170),
	Bad         = Color3.fromRGB(244, 71, 71),
	Good        = Color3.fromRGB(78, 201, 176),
	Selection   = Color3.fromRGB(51, 153, 255),
	Button      = Color3.fromRGB(44, 44, 48),
	ButtonHover = Color3.fromRGB(61, 61, 66),
	Scroll      = Color3.fromRGB(74, 74, 80),
}

local Theme = X64UI.Theme

-- [FIX 6] Weak-keyed binding registry. The old version kept a strong array and
-- pruned it with a reverse linear scan on every theme write, which both leaked
-- and could drop live bindings for not-yet-parented instances.
local ThemeBindings = setmetatable({}, { __mode = "k" })

local function bindTheme(instance, property, key)
	if Theme[key] == nil then
		Log.warn("bindTheme: unknown theme key " .. tostring(key))
		return
	end
	local list = ThemeBindings[instance]
	if not list then
		list = {}
		ThemeBindings[instance] = list
	end
	list[#list + 1] = { property, key }
	instance[property] = Theme[key]
end

function X64UI:SetThemeKey(key, value)
	if value == nil then return end
	Theme[key] =patch)
	if type(patch) ~= "table" then return end
	for k, v in pairs(patch) do
		self:SetThemeKey(k, v)
	end
end

--==============================================================
-- CREATE
--==============================================================

local Create = {}

local function setProperty(inst, key, value)
	inst[key] = value
end

--[[
	props.theme = { PropertyName = "ThemeKey", ... } binds live theming.
	[FIX 2] Property failures warn by default instead of vanishing, which is
	what made every layout bug in the old file invisible.
]]
function Create.create(className, props, children)
	assert(type(className) == "string", "Create.create: className must be a string")
	assert(props == nil or type(props) == "table", "Create.create: props must be a table or nil")
	assert(children == nil or type(children) == "table", "Create.create: children must be a table or nil")

	local inst = Instance.new(className)
	local themeMap = props and props.theme

	for k, v in pairs(props or {}) do
		if k ~= "Parent" and k ~= "theme" then
			local ok, err = pcall(setProperty, inst, k, v)
			if not ok and X64UI.Debug then
				Log.warn(("Create.create: %s.%s failed — %s"):format(className, tostring(k), tostring(err)))
			end
		end
	end

	if themeMap then
		for property, key in pairs(themeMap) do
			bindTheme(inst, property, key)
		end
	end

	for _, child in ipairs(children or {}) do
		child.Parent = inst
	end

	if props and props.Parent then
		inst.Parent = props.Parent
	endreturn setmetatable({
		Bindings  = {},
		Destroyed = false,
		Depth     = 0,
	}, Signal)
end

function Signal:Connect(callback)
	assert(type(callback) == "function", "Signal callback must be a function")
	if self.Destroyed then return DEAD_CONNECTION end

	local binding = { Connected = true, Callback = callback }
	table.insert(self.Bindings, binding)

	local connection = { Connected = true }
	function connection.Disconnect()
		binding.Connected  = false
		connection.Connected = false
		local index = table.find(self.Bindings, binding)
		if index then table.remove(self.Bindings, index) end
	end

	return connection
end

function Signal:Once(callback)
	local connection
	connection = self:Connect(function(...)
		connection.Disconnect()
		callback(...)
	end)
	return connection
end

--[[
	[FIX 7] Two independent bugs in the old Fire:

	  a) `if self._Firing then return end` silently DISCARDED every re-entrant
	     fire. Any callback that set another control (config load, dependency
	     boxes, linked toggles) lost its nested event with no error. This was
	     the real cause of "callbacks sometimes just don't fire".

	  b) The backward loop was documented as disconnect-safe. It is not. With
	     [A,B,C], if C disconnects itself the array becomes [A,B]; the next
	     iteration i=2 h-fire. Iterating a
	     mutating array is never safe.

	Now: snapshot the bindings, iterate forward, and bound recursion with a real
	depth counter so genuine infinite loops are stopped but normal nesting works.
]]
function Signal:Fire(...)
	if self.Destroyed then return end

	self.Depth += 1
	if self.Depth > 16 then
		self.Depth -= 1
		Log.warn("Signal recursion depth exceeded (16); dropping fire")
		return
	end

	local snapshot = table.clone(self.Bindings)
	for i = 1, #snapshot do
		local binding = snapshot[i]
		if binding.Connected then
			local ok, err = xpcall(binding.Callback, traceback, ...)
			if not ok then
				Log.warn("Signal callback failed:\n" .. tostring(err))
			end
		end
	end

	self.Depth -= 1
end

function Signal:ConnectDeferred(callback)
	return self:Connect(function(...)
		local args = table.pack(...)
		task.defer(function()
			callback(unpack(args, 1, args.n))
		end)
	end)
end

function Signal:Destroy()
	self.Destroyed = true
	table.clear(self.Bindings)
end

--==============================================================
-- MAID
--==============================================================

local Maid = {}
Maid.__index = Maid

function Maid.new()
	return setmetatable({ Tas
	table.insert(self.Tasks, taskObject)
	return taskObject
end

function Maid:CleanupTask(taskObject)
	if taskObject == nil then return end
	local kind = typeof(taskObject)

	if kind == "RBXScriptConnection" then
		pcall(function() taskObject:Disconnect() end)
	elseif kind == "Instance" then
		pcall(function() taskObject:Destroy() end)
	elseif kind == "thread" then
		pcall(task.cancel, taskObject)
	elseif type(taskObject) == "function" then
		pcall(taskObject)
	elseif type(taskObject) == "table" then
		if type(taskObject.Destroy) == "function" then
			pcall(function() taskObject:Destroy() end)
		elseif type(taskObject.Disconnect) == "function" then
			pcall(function() taskObject:Disconnect() end)
		end
	end
end

function Maid:Cleanup()
	-- Snapshot: a cleanup handler may legitimately add more tasks.
	local tasks = self.Tasks
	self.Tasks = {}
	for i = #tasks, 1, -1 do
		self:CleanupTask(tasks[i])
	end
end

function Maid:Destroy()
	if self.Destroyed then return end
	self.Destroyed = true
	self:Cleanup()
end

--==============================================================
-- STATE
--==============================================================

local State = {}
State.__index = State

function State.new(defaultValue)
	return setmetatable({ Value = defaultValue, Changed = Signal.new() }, State)
end

function State:Get() return self.Value end

function State:Set(value, silent)
	if self.Value == value then return false end
	local previous = self.Value
	self.Value = value
	if not silentmetatable({
		UndoStack   = {},
		RedoStack   = {},
		Limit       = limit or 150,
		Applying    = false,
		Transaction = nil,
		TxDepth     = 0,
		Changed     = Signal.new(),
	}, History)
end

function History:BeginTransaction(label)
	self.TxDepth += 1
	if self.TxDepth == 1 then
		self.Transaction = { Label = label or "Transaction", Undos = {}, Redos = {} }
	end
end

function History:EndTransaction()
	self.TxDepth = math.max(0, self.TxDepth - 1)
	if self.TxDepth > 0 then return end

	local tx = self.Transaction
	self.Transaction = nil
	if not tx or #tx.Undos == 0 then return end

	self:Push(tx.Label,
		function() for i = #tx.Undos, 1, -1 do tx.Undos[i]() end end,
		function() for i = 1, #tx.Redos do tx.Redos[i]() end end
	)
end

function History:WithTransaction(label, fn)
	self:BeginTransaction(label)
	local ok, err = xpcall(fn, traceback)
	self:EndTransaction()
	if not ok then Log.warn("Transaction failed:\n" .. tostring(err)) end
	return ok
end

function History:Push(label, undo, redo)
	if self.Applying then return end
	if type(undo) ~= "function" or type(redo) ~= "function" then
		Log.warn("History:Push requires undo and redo functions")
		return
	end

	if self.Transaction then
		table.insert(self.Transaction.Undos, undo)
		table.insert(self.Transaction.Redos, redo)
		return
	end

	table.insert(self.UndoStack, { Label = label, Undo = undo, Redo = redo })
	table.clear(self.RedoStack)

	while #self.Undo function applyHistory(self, fromStack, toStack, field, what)
	local entry = table.remove(fromStack)
	if not entry then return false end

	self.Applying = true
	local ok, err = xpcall(entry[field], traceback)
	self.Applying = false

	if not ok then
		Log.warn(what .. " failed:\n" .. tostring(err))
		table.insert(fromStack, entry)
		return false
	end

	table.insert(toStack, entry)
	self.Changed:Fire()
	return true
end

function History:UndoLast() return applyHistory(self, self.UndoStack, self.RedoStack, "Undo", "Undo") end
function History:RedoLast() return applyHistory(self, self.RedoStack, self.UndoStack, "Redo", "Redo") end

function History:Clear()
	table.clear(self.UndoStack)
	table.clear(self.RedoStack)
	self.Changed:Fire()
end

function History:Destroy()
	self:Clear()
	self.Changed:Destroy()
end

--==============================================================
-- REGISTRY
--==============================================================

-- [FIX 8] The old Registry filed anything that was not a Toggle into Options,
-- including Labels, Buttons and Dividers, and then asked SaveConfig to
-- serialise them. It only worked because SerializeValue returned nil by
-- accident. Saveability is now explicit.
local SAVEABLE = {
	Toggle = true, Slider = true, Dropdown = true, Input = true,
	KeyPicker = true, ColorPicker = true, NumericInput = true, ListBox = true,
}

local Registry = {}
Registry.__index = Registry

function Regist ~= control then
		Log.warn("Registry: duplicate control name '" .. tostring(name) .. "' — the previous one is now unreachable by config")
	end

	self.Controls[name] = control
	if not SAVEABLE[controlType or control.Type] then return end

	if (controlType or control.Type) == "Toggle" then
		self.Toggles[name] = control
	else
		self.Options[name] = control
	end
end

function Registry:Unregister(name)
	if not name then return end
	self.Controls[name] = nil
	self.Toggles[name]  = nil
	self.Options[name]  = nil
end

function Registry:Get(name) return self.Controls[name] end

function Registry:Clear()
	local snapshot = {}
	for _, control in pairs(self.Controls) do
		snapshot[#snapshot + 1] = control
	end
	for _, control in ipairs(snapshot) do
		if control and control.Destroy then
			pcall(function() control:Destroy() end)
		end
	end
	table.clear(self.Controls)
	table.clear(self.Toggles)
	table.clear(self.Options)
end

--==============================================================
-- INPUT ROUTER
--==============================================================

local InputRouter = {
	Began        = {},
	Changed      = {},
	Ended        = {},
	CaptureStack = {},
	Connected    = false,
}

function InputRouter:On(phase, listener)
	local list = self[phase]
	if not list then
		Log.warn("InputRouter:On unknown phase " .. tostring(phase))
		return function() end
	end

	table.insert(list, listener)

	-- Returns a disposer. [FIX 9] Callers are now required to keep it.
	return function()
		local index = table index then table.remove(self.CaptureStack, index) end
	end
end

function InputRouter:IsCapturing()
	return #self.CaptureStack > 0
end

function InputRouter:Dispatch(phase, input, gameProcessed)
	local top = self.CaptureStack[#self.CaptureStack]
	if top then
		local handler = top[phase]
		if handler then
			local ok, err = xpcall(handler, traceback, input, gameProcessed)
			if not ok then Log.warn("InputRouter capture failed:\n" .. tostring(err)) end
		end
		return
	end

	-- [FIX 10] Snapshot. Listeners routinely add or remove listeners (keypicker
	-- creation, control destruction) and the old ipairs walk skipped entries.
	local snapshot = table.clone(self[phase])
	for i = 1, #snapshot do
		local ok, err = xpcall(snapshot[i], traceback, input, gameProcessed)
		if not ok then Log.warn("InputRouter listener failed:\n" .. tostring(err)) end
	end
end

-- [FIX 11] Idempotent and re-connectable. The old file called Connect() once at
-- chunk scope; after Unload disconnected it, a cached-module re-run left every
-- keypicker silently dead with no error.
function InputRouter:Connect()
	if self.Connected then return end
	self.Connected = true

	self._began = UserInputService.InputBegan:Connect(function(input, gp)ect(function(input, gp)
		self:Dispatch("Ended", input, gp)
	end)
end

function InputRouter:Disconnect()
	if self._began   then self._began:Disconnect()   end
	if self._changed then self._changed:Disconnect() end
	if self._ended   then self._ended:Disconnect()   end
	self._began, self._changed, self._ended = nil, nil, nil
	self.Connected = false

	table.clear(self.Began)
	table.clear(self.Changed)
	table.clear(self.Ended)
	table.clear(self.CaptureStack)
end

-- Back-compat capture shim.
local InputManager = { Capturing = false, _release = nil }

function InputManager:Capture(handlers)
	if type(handlers) == "function" then
		handlers = { Began = handlers }
	end
	self:Cancel()
	self.Capturing = true
	self._release = InputRouter:PushCapture(handlers)
end

function InputManager:Cancel()
	self.Capturing = false
	if self._release then
		self._release()
		self._release = nil
	end
end

--==============================================================
-- BIND NAMES
--==============================================================

local MOUSE_BINDS = {
	[Enum.UserInputType.MouseButton1] = "MouseButton1",
	[Enum.UserInputType.MouseButton2] = "MouseButton2",
	[Enum.UserInputType.MouseButton3] = "MouseButton3",
}

local BIND_ALIASES = {
	Shift        = { LeftShift = true,   RightShift = true },
	Control      = { LeftControl = true, RightControl = true },
	Alt          = { LeftAlt = true,     RightAlt = true },
	MB1          = { MouseButton1 = true },
	MB2          =yCode
		if not keyCode or keyCode == Enum.KeyCode.Unknown then return nil end
		return keyCode.Name
	end

	return MOUSE_BINDS[input.UserInputType]
end

local function InputMatchesBind(input, bindName)
	if not bindName or bindName == "" or bindName == "None" then return false end
	local name = InputToBindName(input)
	if not name then return false end
	if name == bindName then return true end
	local alias = BIND_ALIASES[bindName]
	return (alias and alias[name]) == true
end

--==============================================================
-- GEOMETRY HELPERS
--==============================================================

local getParent, getViewportSize, getMousePos, mouseOverGui, pointInGui, toGuiSpace

getParent = function()
	if gethui then
		local ok, hidden = pcall(gethui)
		if ok and hidden then return hidden end
	end

	local ok, core = pcall(function() return game:GetService("CoreGui") end)
	if ok and core then return core end

	local player = Players.LocalPlayer
	if not player then
		repeat task.wait() player = Players.LocalPlayer until player
	end
	return player:WaitForChild("PlayerGui")
end

local function screenOf(instance)
	if not instance then return nil end
	if instance:IsA("LayerCollector") then return instance end
	return instance:FindFirstAncestorWhichIsA("LayerCollector")
end

getViewportSize = function(gui)
	local root = screenOf(gui) or gui
	if root and root.Parent and root.AbsoluteSize and root.AbsoluteSize.X > 0 then
		return root.AbsoluteSize
	end
end

getMousePos = function()
	-- GetMouseLocation is authoritative. InputObject.Position is not updated for
	-- MouseButton1/2 in InputBegan, which is why the old colour picker drifted.
	return UserInputService:GetMouseLocation()
end

--[[
	[FIX 12] THE BIG ONE.

	AbsolutePosition is reported relative to the ScreenGui's own content origin.
	GetMouseLocation is true viewport space. So:
	  IgnoreGuiInset = true  -> they already agree, offset is zero
	  IgnoreGuiInset = false -> content starts below the topbar, subtract inset

	The old toGuiSpace ADDED the inset when IgnoreGuiInset was true (backwards),
	and was never called by anything. Worse, the old mouseOverGui tested THREE
	points (raw, minus inset, plus inset) and OR'd them, inflating every hit
	region into three bands 36px apart:

	    [a-36, b-36] u [a, b] u [a+36, b+36]

	Because the title bar is 24px (< 36) the bands do not merge. Real symptoms
	that all trace back to this single dropdowns, menus, the colour picker and the command palette refused to
	    close when you clicked within 36px of them
	  * min/close buttons blocked dragging in a 36px halo
]]
toGuiSpace = function(point, root)
	if root and root:IsA("ScreenGui") and not root.IgnoreGuiInset then
		return point - GuiService:GetGuiInset()
	end
	return point
end

pointInGui = function(gui, point)
	if not gui or not gui.Parent then return false end
	local pos, size = gui.AbsolutePosition, gui.AbsoluteSize
	return point.X >= pos.X and point.X <= pos.X + size.X
		and point.Y >= pos.Y and point.Y <= pos.Y + size.Y
end

local function effectivelyVisible(gui)
	local node, depth = gui, 0
	while node and depth < 24 do
		if node:IsA("GuiObject") and not node.Visible then return false end
		if node:IsA("LayerCollector") then return node.Enabled end
		node = node.Parent
		depth += 1
	end
	return true
end

mouseOverGui = function(gui)
	if not gui or not gui.Parent then return false end
	if not effectivelyVisible(gui) then return false end

	local ok, mouse = pcall(getMousePos)
	if not ok or not mouse then return false end

	return pointInGui(gui, toGuiSpace(mouse, screenOf(gui)))
end

local function getSafeViewportRect(gui)
	local viewport = getViewportSize(gui)
	local margin = 8
	return margin, margin, viewport.X - margin, viewport.Y - margin, viewport
end

--==============================================ars actually sum to 100,
-- leaving a permanent 2px seam that would silently desync on any bar change.
local Chrome = {
	Title   = 24,
	Menu    = 22,
	Toolbar = 28,
	Tabs    = 26,
	Console = 160,
	Status  = 22,
}
Chrome.Top = Chrome.Title + Chrome.Menu + Chrome.Toolbar + Chrome.Tabs

--==============================================================
-- TOOLTIP
--==============================================================

local TooltipGui, TooltipLabel

local function initTooltip()
	if TooltipGui and TooltipGui.Parent then return end

	TooltipGui = Create.create("ScreenGui", {
		Name = "X64Tooltip",
		ResetOnSpawn = false,
		IgnoreGuiInset = true,
		DisplayOrder = Layer.Tooltip,
		Parent = getParent(),
	})

	TooltipLabel = Create.create("TextLabel", {
		Parent = TooltipGui,
		Size = UDim2.fromOffset(0, 0),
		AutomaticSize = Enum.AutomaticSize.XY,
		Text = "",
		Visible = false,
		ZIndex = Layer.Tooltip,
		TextXAlignment = Enum.TextXAlignment.Left,
		Font = Theme.Font,
		TextSize = Theme.TextSize,
		theme = {
			BackgroundColor3 = "PanelAlt",
			BorderColor3 = "Border",
			TextColor3 = "Text",
		},
	})

	Create.create("UIPadding", {
		Parent = TooltipLabel,
		PaddingLeft = UDim.new(0, not text or text == "" then return end
	initTooltip()

	TooltipLabel.Text = tostring(text)
	TooltipLabel.Visible = true

	-- [FIX 14] Keep the tooltip on screen instead of letting it run off the
	-- right/bottom edge, which the old version always did near the window grip.
	local viewport = getViewportSize(TooltipGui)
	local size = TooltipLabel.AbsoluteSize
	local x = math.min(position.X + 12, viewport.X - size.X - 4)
	local y = math.min(position.Y + 12, viewport.Y - size.Y - 4)
	TooltipLabel.Position = UDim2.fromOffset(math.max(4, x), math.max(4, y))
end

local function hideTooltip()
	if TooltipLabel then TooltipLabel.Visible = false end
end

local function attachTooltip(window, gui, text)
	if not text or text == "" then return end
	window:Track(gui.MouseEnter:Connect(function()
		showTooltip(text, getMousePos())
	end))
	window:Track(gui.MouseMoved:Connect(function()
		if TooltipLabel and TooltipLabel.Visible then
			showTooltip(text, getMousePos())
		end
	end))
	window:Track(gui.MouseLeave:Connect(hideTooltip))
end

--==============================================================
-- CLASS DECLARATIONS
--==============================================================

local Window = {}    ; Window.__index = Window
local Tab = {}       ; Tab.__index = Tab
local Groupbox = {}  ; Groupbox.__index = Groupbox

--==============================================================
-- BASE CONTROL
--==============================================================

local BaseControl = {}
Ba
		Disabled  = false,
		ReadOnly  = false,
		Destroyed = false,
		Popups    = {},
	}, BaseControl)
end

function BaseControl:CanInteract()
	return not self.Disabled
		and not self.ReadOnly
		and self.Visible
		and not self.Destroyed
end

-- [FIX 15] SetVisible now also hides externally-parented popups. Hiding a
-- dropdown used to leave its open list floating on screen forever.
function BaseControl:SetVisible(value)
	self.Visible = value and true or false
	if self.Frame then self.Frame.Visible = self.Visible end
	if not self.Visible then self:ClosePopups() end
	if self.OnStateChanged then self:OnStateChanged() end
end

--[[
	[FIX 16] SetDisabled was cosmetic. `Frame.Active = false` only stops that one
	frame from consuming input; descendant TextButtons are Active in their own
	right. The controls also disagreed about whether to check at all:

	    Slider / Dropdown / ListBox  ->  checked
	    Toggle / Input / ColorPicker ->  checked NOTHING

	So toggle:SetDisabled(true) produced a greyed-out label that still toggled.
	Every control now gates on CanInteract() and reports state via
	OnStateChanged so editable/ then
		self.Label.TextColor3 = self.Disabled and Theme.Dim or Theme.Text
	end
	if self.Disabled then self:ClosePopups() end
	if self.OnStateChanged then self:OnStateChanged() end
end

function BaseControl:SetReadOnly(value)
	self.ReadOnly = value and true or false
	if self.ReadOnly then self:ClosePopups() end
	if self.OnStateChanged then self:OnStateChanged() end
end

function BaseControl:TrackPopup(instance)
	table.insert(self.Popups, instance)
	return instance
end

function BaseControl:ClosePopups()
	if self.Close then pcall(function() self:Close() end) end
	for _, popup in ipairs(self.Popups) do
		if popup and popup.Parent then popup.Visible = false end
	end
end

function BaseControl:Destroy()
	if self.Destroyed then return end
	self.Destroyed = true

	if self.Changed and self.Changed.Destroy then self.Changed:Destroy() end
	if self.Clicked and self.Clicked.Destroy then self.Clicked:Destroy() end

	-- [FIX 17] Externally parented popups are destroyed with the control. The
	-- old Groupbox:Clear destroyed row frames only, orphaning every dropdown
	-- list and colour-picker panel into win.Gui permanently.
	for _, popup in ipairs(self.Popups) do
		if popup then pcall(function() popup() self.Frame:Destroy() end) end

	if self.Window and self.Window.Registry and self.Name then
		self.Window.Registry:Unregister(self.Name)
	end

	if self.Window and self.Window.Dropdowns then
		local index = table.find(self.Window.Dropdowns, self)
		if index then table.remove(self.Window.Dropdowns, index) end
	end

	if self.Group and self.Group.Controls then
		local index = table.find(self.Group.Controls, self)
		if index then table.remove(self.Group.Controls, index) end
	end
end

function BaseControl:GiveDisposer(dispose)
	self._Disposers = self._Disposers or {}
	table.insert(self._Disposers, dispose)
	return dispose
end

--==============================================================
-- WINDOW: CORE
--==============================================================

function Window:Track(taskObject)
	if self.Destroyed then
		if self.Maid then self.Maid:CleanupTask(taskObject) end
		return taskObject
	end
	if self.Maid then self.Maid:Give(taskObject) end
	return taskObject
end

-- Scale conversions. [FIX 18] see MakeResizable / SetMaximized for why.
function Window:GetScale()
	return (self.UIScale and self.UIScale.Scale) or 1
end

function Window:ToLocal(px)  return px / self:GetScale() end
function Window:ToAbsolute(u) return u * self:GetScale() end

function Window:AttachScale(instance)
	local scale = Create.create("UIScale", {
		Parent = instance,
		Scale = self:GetScale(),
	})
	table.insert(self._PopupScales, scale)
	return scale
end

-- AbsoluteSize (scaled) and
	wrote Size (unscaled) interchangeably. Consequences:
	  * resizing jumped ~15% and compounded on every drag
	  * maximizing overflowed the screen and pushed the close button off-screen,
	    making the window impossible to close except by double-clicking the title
	  * minimizing widened the window by 15%
	  * every scroller over-scrolled by the scale factor
	  * popups parented to Gui rendered at 1.0 while the window rendered at 1.15
]]
function Window:SetScale(scale)
	scale = math.clamp(tonumber(scale) or 1, 0.5, 2)
	self.Scale = scale
	if self.UIScale then self.UIScale.Scale = scale end

	for i = #self._PopupScales, 1, -1 do
		local popupScale = self._PopupScales[i]
		if popupScale and popupScale.Parent then
			popupScale.Scale = scale
		else
			table.remove(self._PopupScales, i)
		end
	end

	self:UpdateLayout()
	self:ClampToViewport()

	if self.Events and self.Events.Changed then
		self.Events.Changed:Fire("Scale", scale)
	end
end

function Window:Focus()
	if self.Destroyed then return end

	X64UI.FocusCounter += 1
	if self.Gui then
		self.Gui.DisplayOrder = 10000 + X64UI.FocusCounter
	end

	X64UI.ActiveWindow = self
	if self.Events and self.Events.Focused then
		self.Events.Focused:Fire(self)", bad     = "#F44747",
	warn    = "#DCDCAA", warning = "#DCDCAA",
	good    = "#4EC9B0", success = "#4EC9B0",
	accent  = "#589ED8",
	info    = "#DCDCE3",
}

local RICH_ESCAPES = { ["<"] = "&lt;", [">"] = "&gt;", ["&"] = "&amp;", ['"'] = "&quot;", ["'"] = "&apos;" }

local function inferSeverity(text)
	local lower = string.lower(text)
	if lower:find("error", 1, true) or lower:find("fail", 1, true) then return "error" end
	if lower:find("warn", 1, true) then return "warn" end
	if lower:find("success", 1, true) or lower:find("loaded", 1, true) then return "good" end
	return "info"
end

function Window:Log(message, severity)
	if self.Destroyed then return end
	if not self.LogLabel or not self.LogLabel.Parent then return end

	local text = tostring(message)
	local color = SEVERITY_COLORS[severity or inferSeverity(text)] or SEVERITY_COLORS.info

	-- Escape & first would double-escape the entities we then insert.
	local safe = text:gsub("[<>&\"']", RICH_ESCAPES)

	self.Lines[#self.Lines + 1] = string.format(
		'<font color="#888888">[%s]</font> <font color="%s">%s</font>',
		os.date("%X"), color, safe
	)

	-- [FIX 20] Trim by whole LINES. The old code did joined:sub(#joined - 12ire label. It was
	-- also off by one, keeping 12001 chars.
	while #self.Lines > 400 do
		table.remove(self.Lines, 1)
	end

	self._LogDirty = true
	if self._LogFlushScheduled then return end
	self._LogFlushScheduled = true

	task.defer(function()
		self._LogFlushScheduled = false
		if self.Destroyed or not self._LogDirty then return end
		self._LogDirty = false
		if not self.LogLabel or not self.LogLabel.Parent then return end

		local joined = table.concat(self.Lines, "\n")
		while #joined > 12000 and #self.Lines > 1 do
			table.remove(self.Lines, 1)
			joined = table.concat(self.Lines, "\n")
		end
		self.LogLabel.Text = joined

		if self.LogScroll then
			-- TextBounds is absolute px; CanvasSize is local units.
			local height = self:ToLocal(self.LogLabel.TextBounds.Y) + 10
			self.LogScroll.CanvasSize = UDim2.fromOffset(0, height)
			if self._LogAutoScroll ~= false then
				local viewHeight = self:ToLocal(self.LogScroll.AbsoluteWindowSize.Y)
				self.LogScroll.CanvasPosition = Vector2.new(0, math.max(0, height - viewHeight))
			end
		end
	end)
end

function Window:ClearLog()
	table.clear(self.Lines)
	if self.LogLabel then self.LogLabel.Text = "" end
	if self.LogScroll then
		self.LogScroll.CanvasSize = UDim2.new()
		self.LogScroll.CanvasPosition = Vector2.IX 21] The old RegisterPopup appended a brand new closure on every single
	dropdown Open, and Popups was only cleared by CloseAllPopups. Open and close
	one dropdown a thousand times and you held a thousand dead closures. Popups
	are now a set keyed by identity.
]]
function Window:RegisterPopup(popup)
	self.Popups[popup] = true
	return popup
end

function Window:UnregisterPopup(popup)
	self.Popups[popup] = nil
end

function Window:CloseAllPopups()
	for popup in pairs(self.Popups) do
		pcall(function()
			if type(popup) == "table" and type(popup.Close) == "function" then
				popup:Close()
			elseif type(popup) == "function" then
				popup()
			end
		end)
	end
	table.clear(self.Popups)

	self:CloseDropdowns()
	if self.CloseMenu then self.CloseMenu() end
	if self.CommandPalette then self:CloseCommandPalette() end
	hideTooltip()
end

--==============================================================
-- WINDOW: LAYOUT
--==============================================================

function Window:UpdateLayout()
	if self.Destroyed or self.Minimized then return end

	local consoleHeight = self.ConsoleVisible and Chrome.Console or 0
	local statusHeight  = self.StatusVisible and Chrome.Status or 0

	self.Console.Visible   = self.ConsoleVisible
	self.StatusBar.Visible = self.StatusVisible

	self.Pages.Position = UDim2.fromOffset(4, Chrome.Top)
	self.Pages.Size     = UDim2.new(Console.Size     = UDim2.new(1, -8, 0, consoleHeight)

	self.StatusBar.Position = UDim2.new(0, 0, 1, -statusHeight)
	self.StatusBar.Size     = UDim2.new(1, 0, 0, statusHeight)

	-- Keep the grip clear of the status bar instead of overlapping it.
	self.Grip.Position = UDim2.new(1, -15, 1, -(statusHeight + 15))
end

function Window:GetResizeLimits()
	local left, top, right, bottom, viewport = getSafeViewportRect(self.Gui)
	local maxW = math.max(1, right - left)
	local maxH = math.max(1, bottom - top)
	return viewport,
		Vector2.new(math.min(760, maxW), math.min(420, maxH)),
		Vector2.new(maxW, maxH)
end

function Window:ClampToViewport()
	if self.Destroyed or self.Maximized or self.Minimized then return end
	if not self.Main or not self.Main.Parent then return end
	if self._Dragging or self._Resizing then return end

	local left, top, right, bottom = getSafeViewportRect(self.Gui)
	local _, minSize, maxSize = self:GetResizeLimits()

	-- AbsoluteSize is scaled; Size offsets are not. Convert on write.
	local current = self.Main.AbsoluteSize
	local clamped = Vector2.new(
		math.clamp(current.X, minSize.X, maxSize.X),
		math.clamp(current.Y, minSize.Y, maxSize.Y)
	)

	if clamped ~= current then
		self.Main.Size = UDim2.fromOffset(self:ToLocal(clamped.X), self:ToLocal(cl), so no conversion here.
	local posX = math.clamp(self.Main.Position.X.Offset, left, math.max(left, right - clamped.X))
	local posY = math.clamp(self.Main.Position.Y.Offset, top,  math.max(top,  bottom - clamped.Y))
	self.Main.Position = UDim2.fromOffset(posX, posY)
end

function Window:ToggleConsole()
	self.ConsoleVisible = not self.ConsoleVisible
	self:UpdateLayout()
	if self.Events and self.Events.Changed then
		self.Events.Changed:Fire("ConsoleVisible", self.ConsoleVisible)
	end
end

function Window:ToggleStatusBar()
	self.StatusVisible = not self.StatusVisible
	self:UpdateLayout()
	if self.Events and self.Events.Changed then
		self.Events.Changed:Fire("StatusVisible", self.StatusVisible)
	end
end

function Window:SetMinimized(value)
	if self.Destroyed then return end
	value = value and true or false
	if value == self.Minimized then return end

	self:CloseAllPopups()
	self.Minimized = value
	self.State.Minimized:Set(value)

	if value then
		self.LastSize = self.Main.Size
		-- [FIX 19c] /scale, or the window grows by the scale factor each time.
		self.Main.Size = UDim2.fromOffset(self:ToLocal(self.Main.AbsoluteSize.X), Chrome.Title)

		self.MenuBar.Visible   = false
		self.Toolbar.Visible   = false
		self.TabBar.Visible    = false
		self.Pages.Visible     = false
		self.Consolebar.Visible   = true
		self.TabBar.Visible    = true
		self.Pages.Visible     = true
		self.Console.Visible   = self.ConsoleVisible
		self.StatusBar.Visible = self.StatusVisible
		self.Grip.Visible      = true

		self:UpdateLayout()
		self:ClampToViewport()
	end

	if self.Events and self.Events.Changed then
		self.Events.Changed:Fire("Minimized", value)
	end
end

function Window:SetMaximized(value)
	if self.Destroyed or self.Minimized then return end
	value = value and true or false
	if value == self.Maximized then return end

	self:CloseAllPopups()
	self.Maximized = value
	self.State.Maximized:Set(value)

	if value then
		self.PreMaxSize     = self.Main.Size
		self.PreMaxPosition = self.Main.Position

		-- [FIX 19b] Convert viewport px into local units. The old code wrote raw
		-- viewport values into Size, so at scale 1.15 the maximized window was
		-- 15% larger than the screen and the close button sat ~315px off the
		-- right edge, leaving no way to close or restore it.
		local viewport = getViewportSize(self.Gui)
		self.Main.Position = UDim2.fromOffset(0, 0)
		self.Main.Size = UDim2.fromOffset(self:ToLocal(viewport.X), self:ToLocalself:ClampToViewport()
	end

	self:UpdateLayout()

	if self.Events and self.Events.Changed then
		self.Events.Changed:Fire("Maximized", value)
	end
end

function Window:Show()
	if self.Destroyed or self.Main.Visible then return end
	self.Main.Visible = true
	self.State.Visible:Set(true)
	if self.Events and self.Events.VisibilityChanged then
		self.Events.VisibilityChanged:Fire(true)
	end
end

function Window:Hide()
	if self.Destroyed or not self.Main.Visible then return end
	self:CloseAllPopups()
	self.Main.Visible = false
	self.State.Visible:Set(false)
	if self.Events and self.Events.VisibilityChanged then
		self.Events.VisibilityChanged:Fire(false)
	end
end

function Window:Toggle()
	if self.Main.Visible then self:Hide() else self:Show() end
end

function Window:Destroy()
	if self.Destroyed then return end

	if self.Events and self.Events.Destroying then
		self.Events.Destroying:Fire(self)
	end

	self:CloseAllPopups()
	self.Destroyed = true

	-- Maid first: control Destroy handlers unregister themselves cleanly while
	-- the registry still exists.
	if self.Maid then self.Maid:Destroy() end
	if self.Registry then self.Registry:Clear() end
	if self.History then self.History:Destroy() end

	if self.Gui then
		pcall(function() self.Gui:Destroy() end)
		self.Gui = nil
	end

	local index = table.find(X64UI.Windows, self)
	if index then table.remove(X64UI.Windows, index) end

	if X64UI.ActiveWindow == self then
		X64 = Create.create("CanvasGroup", {
			Parent = self.Gui,
			Size = UDim2.fromScale(1, 1),
			BackgroundColor3 = Color3.fromRGB(7, 7, 9),
			BorderSizePixel = 0,
			GroupTransparency = 0,
			ZIndex = Layer.Intro,
		})

		local gradient = Create.create("UIGradient", {
			Parent = wash,
			Rotation = 90,
			Offset = Vector2.new(0, -0.2),
			Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 0),
				NumberSequenceKeypoint.new(0.35, 0.22),
				NumberSequenceKeypoint.new(0.65, 0.55),
				NumberSequenceKeypoint.new(1, 1),
			}),
		})

		local info = TweenInfo.new(0.56, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
		TweenService:Create(gradient, info, { Offset = Vector2.new(0, 0.28) }):Play()

		local washTween = TweenService:Create(wash, info, { GroupTransparency = 1 })
		washTween:Play()

		-- [FIX 22] Cleanup is driven from one place. The old code handed the wash
		-- to the Maid AND destroyed it on Completed, so teardown always ran into
		-- an already-destroyed instance.
		washTween.Completed:Connect(function()
			if wash and wash.Parent then wash:Destroy() end
		end)

		self.Maid:Give(function()
			if wash and wash.Parent then wash:Destroy() end
		end)
	end)
end

--==============================================================
-- WINDOW: DRAG / RESIZE
--== not handle.Parent then return false end
		if not self.Main.Visible then return false end
		if self.Maximized then return false end
		if UserInputService:GetFocusedTextBox() then return false end
		-- These halo checks are only correct now that mouseOverGui is fixed.
		if self.MinButton and mouseOverGui(self.MinButton) then return false end
		if self.CloseButton and mouseOverGui(self.CloseButton) then return false end
		return true
	end

	local function beginDrag()
		if dragging or not canDrag() then return end
		dragging = true
		self._Dragging = true
		startMouse = getMousePos()
		startPos = Vector2.new(frame.Position.X.Offset, frame.Position.Y.Offset)
		self:Focus()
	end

	local function endDrag()
		if not dragging then return end
		dragging = false
		self._Dragging = false
		self:ClampToViewport()
	end

	self:Track(handle.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			beginDrag()
		end
	end))

	-- [FIX 23] Routed through InputRouter and gated on being the focused window.
	-- The old global listener would start a drag on a BACKGROUND window whenever
	-- the cursor happened to be over where that window's handle sat.
	self:Track(InputRouter:On("Changed", function(input)
		if not dragging then return end
		if input.UserInputType ~= Enum.UserInputType.MouseMovement then return end

		local delta = getMousePos() - startMouse
		local nextPos = startPosmax(left, right - size.X)),
			math.clamp(nextPos.Y, top,  math.max(top,  bottom - size.Y))
		)
	end))

	self:Track(InputRouter:On("Ended", function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then endDrag() end
	end))

	-- Alt-tab mid-drag no longer leaves the window stuck to the cursor.
	self:Track(UserInputService.WindowFocusReleased:Connect(endDrag))
	self._CancelDrag = endDrag
end

function Window:MakeResizable(frame, grip)
	local resizing = false
	local startMouse, startSize = Vector2.zero, Vector2.zero

	local function canResize()
		if self.Destroyed or not frame.Parent or not grip.Parent or not grip.Visible then return false end
		if not self.Main.Visible then return false end
		if self.Minimized or self.Maximized then return false end
		if UserInputService:GetFocusedTextBox() then return false end
		return true
	end

	local function beginResize()
		if resizing or not canResize() then return end
		resizing = true
		self._Resizing = true
		startMouse = getMousePos()
		startSize = frame.AbsoluteSize   -- absolute px, matched to mouse deltas
		self:Focus()
	end

	local function endResize()
		if not resizing then return end
		resizing = false
		self._Resizing = false
		self:ClampToViewport()
	end

	self:Track(grip.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then beginResize() end
	end))

	self:Track(InputRouter:On("Changed", function(input)
		if not resizing then return end
		if input.UserInputType ~= Size is local
		-- units. The old code added a screen-space delta to AbsoluteSize and
		-- wrote the result straight into Size, so at scale 1.15 the window
		-- jumped 15% on mouse-down and compounded on every subsequent drag.
		local nextAbs = Vector2.new(
			math.clamp(startSize.X + delta.X, minSize.X, maxSize.X),
			math.clamp(startSize.Y + delta.Y, minSize.Y, maxSize.Y)
		)

		frame.Size = UDim2.fromOffset(self:ToLocal(nextAbs.X), self:ToLocal(nextAbs.Y))
		self:UpdateLayout()
	end))

	self:Track(InputRouter:On("Ended", function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then endResize() end
	end))

	self:Track(UserInputService.WindowFocusReleased:Connect(endResize))
end

--==============================================================
-- WINDOW: TABS
--==============================================================

local function bindCanvas(window, scroll, layout, pad)
	local function update()
		if not scroll.Parent then return end
		-- AbsoluteContentSize is scaled; CanvasSize offsets are local units.
		-- [FIX 19d] The old code fize = UDim2.fromOffset(0, height)
	end
	window:Track(layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(update))
	update()
end

function Window:SelectTab(name)
	local tab = self.Tabs[name]
	if not tab then return end

	self:CloseAllPopups()

	for _, other in pairs(self.Tabs) do
		other.Page.Visible = false
		other.Underline.Visible = false
		other.Button.TextColor3 = Theme.Dim
	end

	tab.Page.Visible = true
	tab.Underline.Visible = true
	tab.Button.TextColor3 = Theme.Text

	self:SetStatus("Tab: " .. tostring(name))
	self.State.ActiveTab:Set(name)

	if self.Events and self.Events.Changed then
		self.Events.Changed:Fire("ActiveTab", name)
	end
end

function Window:AddTab(name)
	assert(type(name) == "string" and name ~= "", "AddTab: name must be a non-empty string")
	if self.Tabs[name] then return self.Tabs[name] end

	local tab = setmetatable({
		Window = self,
		Name = name,
		Groupboxes = {},
		NextLeftOrder = 0,
		NextRightOrder = 0,
	}, Tab)

	local order = #self.TabOrder + 1
	table.insert(self.TabOrder, name)

	tab.Button = Create.create("TextButton", {
		Parent = self.TabBar,
		Size = UDim2.fromOffset(0, Chrome.Tabs),
		AutomaticSize = Enum.AutomaticSize.X,
		BackgroundTransparency = 1,
		Text = "  " .. name .. "  ",
		Font = Theme.Font,
		TextSize = Theme.TextSize,
		AutoButtonColorPosition = UDim2.new(0, 0, 1, -2),
		BorderSizePixel = 0,
		Visible = false,
		theme = { BackgroundColor3 = "Accent" },
	})

	self:Track(tab.Button.MouseEnter:Connect(function()
		if not tab.Underline.Visible then tab.Button.TextColor3 = Theme.Text end
	end))
	self:Track(tab.Button.MouseLeave:Connect(function()
		if not tab.Underline.Visible then tab.Button.TextColor3 = Theme.Dim end
	end))
	self:Track(tab.Button.MouseButton1Click:Connect(function()
		self:SelectTab(name)
	end))

	tab.Page = Create.create("Frame", {
		Parent = self.Pages,
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Visible = false,
	})

	local function makePane(position, size)
		local pane = Create.create("ScrollingFrame", {
			Parent = tab.Page,
			Position = position,
			Size = size,
			BorderSizePixel = 1,
			ScrollBarThickness = 8,
			CanvasSize = UDim2.new(),
			theme = {
				BackgroundColor3 = "Background",
				BorderColor3 = "Border",
				ScrollBarImageColor3 = "Scroll",
			},
		})

		local layout = Create.create("UIListLayout", {
			Parent = pane,
			Padding = UDim.new(0, 4),
			SortOrder = Enum.SortOrder.LayoutOrder,
		})

		Create.create("UIPadding", {
			Parent = pane,
			PaddingTop = UDim.new(0, 4),
			PaddingLeft = UDim.new(0, 4),
			PaddingRight = UDim.new(0, 4),
			PaddingBottom =0.5, -3, 1, 0))
	tab.RightPane = makePane(UDim2.new(0.5, 3, 0, 0), UDim2.new(0.5, -3, 1, 0))

	self.Tabs[name] = tab
	if #self.TabOrder == 1 then self:SelectTab(name) end
	return tab
end

-- [FIX 24] Tab:Destroy referenced self.Frame, which Tab never set (the field is
-- self.Page), so destroying a tab silently orphaned its entire page and every
-- control on it.
function Tab:Destroy()
	if self.Destroyed then return end
	self.Destroyed = true

	for _, group in ipairs(self.Groupboxes) do
		pcall(function() group:Destroy() end)
	end

	if self.Page then pcall(function() self.Page:Destroy() end) end
	if self.Button then pcall(function() self.Button:Destroy() end) end

	local window = self.Window
	if window and not window.Destroyed then
		window.Tabs[self.Name] = nil
		local index = table.find(window.TabOrder, self.Name)
		if index then table.remove(window.TabOrder, index) end

		if window.State.ActiveTab:Get() == self.Name then
			local nextTab = window.TabOrder[1]
			if nextTab then window:SelectTab(nextTab) end
		end
	end
end

--==============================================================
-- WINDOW: CONFIG
--==============================================================

local function sanitizeProfileName(name)
	local clean = tostring(name or "default"):gsub("[^%w%-%_]", "")
	if clean == "" then clean = "default" end
	return clean
end

function XR, g = value.G, b = value.B }
	end
	if kind == "Dropdown" or kind == "ListBox" then
		if type(value) == "table" then return { t = "Multi", v = value } end
	end
	if type(value) == "string" or type(value) == "number" or type(value) == "boolean" then
		return value
	end
	return nil
end

function X64UI.DeserializeValue(control, raw)
	if not control or raw == nil then return nil end
	if type(raw) == "table" then
		if raw.t == "Color3" then
			return Color3.new(
				math.clamp(tonumber(raw.r) or 0, 0, 1),
				math.clamp(tonumber(raw.g) or 0, 0, 1),
				math.clamp(tonumber(raw.b) or 0, 0, 1)
			)
		end
		if raw.t == "Multi" then return raw.v end
	end
	return raw
end

local function isControlValueValid(control, value)
	if not control or not control.Type then return false end
	local kind = control.Type

	if kind == "Toggle" then return typeof(value) == "boolean" end
	if kind == "Slider" or kind == "NumericInput" then return typeof(value) == "number" end
	if kind == "KeyPicker" then return typeof(value) == "string" end
	if kind == "ColorPicker" then return typeof(value) == "Color3" end
	if kind == "Input" then return typeof(value) == "string" or typeof(value) == "number" end
	if kind == "Dropdown" or kind == "ListBox" then
		return type(value) == "table" or typeof(value) == "string" or typeof(value) == "number"
	end
	return true
end

local CONFIG_VERSION = 4

-- [FIX 25] An ordered migration chain. The old code migrated only `< 2`, then
-- unconditionally stamped `Version = 3] = function(data) data.Layout = data.Layout or {} end,
	[2] = function(data) data.MenuKeybind = data.MenuKeybind or nil end,
	[3] = function(data)
		data.Layout = data.Layout or {}
		if data.Layout.Scale then
			data.Layout.Scale = math.clamp(tonumber(data.Layout.Scale) or 1, 0.5, 2)
		end
	end,
}

function Window:SaveConfig(path)
	path = path or "x64ui_config.json"

	if not Platform.CanWrite then
		self:Log("writefile is not supported by this executor.", "error")
		return false
	end

	local data = {
		Version = CONFIG_VERSION,
		Toggles = {},
		Options = {},
		Layout = {},
	}

	for name, toggle in pairs(self.Registry.Toggles) do
		if not toggle.NoSave and typeof(toggle.Value) == "boolean" then
			data.Toggles[name] = toggle.Value
		end
	end

	for name, option in pairs(self.Registry.Options) do
		if not option.NoSave then
			local encoded = X64UI.SerializeValue(option)
			if encoded ~= nil then data.Options[name] = encoded end
		end
	end

	data.Layout = {
		Size      = { self.Main.Size.X.Offset, self.Main.Size.Y.Offset },
		Pos       = { self.Main.Position.X.Offset, self.Main.Position.Y.Offset },
		Minimized = self.Minimized == true,
		Maximized = self.Maximized == true,
		Scale     = self.Scale or 1,
		Console   = self.ConsoleVisible == true,
		Status    = self.StatusVisible == true,
		ActiveTab = self.State.Active pcall(function() return HttpService:JSONEncode(data) end)
	if not ok then
		self:Log("Config encode failed: " .. tostring(json), "error")
		return false
	end

	if not Platform.writeFile(path, json) then
		self:Log("Config write failed (disk or verification error): " .. path, "error")
		return false
	end

	self:Log("Config saved: " .. path, "good")
	return true
end

function Window:LoadConfig(path, loadOpts)
	path = path or "x64ui_config.json"
	loadOpts = loadOpts or {}

local silent        = loadOpts.Silent
	local fireCallbacks = loadOpts.FireCallbacks ~= false
	local recordHistory = loadOpts.RecordHistory ~= false
	local applyLayout   = loadOpts.ApplyLayout ~= false

	if not Platform.fileExists(path) then
		if not silent then self:Log("Config file not found: " .. path, "warn") end
		return false
	end

	local json = Platform.readFile(path)
	if not json then
		self:Log("Config read failed: " .. path, "error")
		return false
	end

	local okDecode, data = pcall(function() return HttpService:JSONDecode(json) end)
	if not okDecode or type(data) ~= "table" then
		self:Log("Config decode failed — file is corrupt.", "error")
		return false
	end

	-- Run every migration between the file's version and ours, in order.
	localok then
				self:Log(("Config migration %d failed: %s"):format(version, tostring(err)), "error")
				return false
			end
		end
		version += 1
	end
	data.Version = CONFIG_VERSION

	if recordHistory then self.History:BeginTransaction("Load Config") end

	local applied, rejected = 0, 0

	-- [FIX 26] Per-key isolation. The old loader ran every SetValue bare inside
	-- one pass, so a single control whose callback threw aborted the whole load
	-- and left the UI half-configured.
	local function applyOne(name, raw)
		local control = self.Registry:Get(name)
		if not control or not control.SetValue or control.NoSave then return end

		local value = X64UI.DeserializeValue(control, raw)

		if control.Type == "Slider" and typeof(value) == "number" then
			value = math.clamp(value, control.Min or value, control.Max or value)
		end

		if not isControlValueValid(control, value) then
			rejected += 1
			Log.warn(("Config rejected '%s' — invalid value for %s"):format(tostring(name), tostring(control.Type)))
			return
		end

		local ok, err = xpcall(function()
			control:SetValue(value, not fireCallbacks)
		end, traceback)

		if ok then
			applied += 1
		else
			rejected += 1
			Log.warn(("Config failed to apply '%s':\n%s"):format(tostring(name), tostring(err)))
		end
	end

	if type(data.Toggles) == "table" then] Layout restore in dependency order: scale first (it changes what
	-- every offset means), then size and position, then chrome, then clamp. The
	-- old loader applied size/pos and never restored scale, console, status or
	-- the active tab at all, so "save layout" only half worked.
	if applyLayout and type(data.Layout) == "table" then
		local layout = data.Layout

		if layout.Scale then self:SetScale(layout.Scale) end

		if type(layout.Size) == "table" and layout.Size[1] and layout.Size[2] then
			self.Main.Size = UDim2.fromOffset(layout.Size[1], layout.Size[2])
		end
		if type(layout.Pos) == "table" and layout.Pos[1] and layout.Pos[2] then
			self.Main.Position = UDim2.fromOffset(layout.Pos[1], layout.Pos[2])
		end

		if layout.Console ~= nil then self.ConsoleVisible = layout.Console == true end
		if layout.Status  ~= nil then self.StatusVisible  = layout.Status  == true end

		if type(layout.ActiveTab) == "string" and self.Tabs[layout.ActiveTab] then
			self:SelectTab(layout.ActiveTab)
		.Maximized then self:SetMaximized(true) end
		if layout.Minimized then self:SetMinimized(true) end
	end

	if recordHistory then self.History:EndTransaction() end

	if not silent then
		if rejected > 0 then
			self:Log(("Config loaded: %s (%d applied, %d rejected)"):format(path, applied, rejected), "warn")
		else
			self:Log(("Config loaded: %s (%d values)"):format(path, applied), "good")
		end
	end

	return true
end

function Window:SaveProfile(name)
	return self:SaveConfig("x64ui_profile_" .. sanitizeProfileName(name) .. ".json")
end

function Window:LoadProfile(name, loadOpts)
	return self:LoadConfig("x64ui_profile_" .. sanitizeProfileName(name) .. ".json", loadOpts)
end

function Window:DeleteProfile(name)
	local path = "x64ui_profile_" .. sanitizeProfileName(name) .. ".json"
	if not Platform.fileExists(path) then
		self:Log("Profile does not exist: " .. path, "warn")
		return false
	end
	local ok = Platform.deleteFile(path)
	self:Log(ok and ("Profile deleted: " .. path) or ("Profile delete failed: " .. path), ok and "good" or "error")
	return ok
end

--==============================================================
-- WINDOW: COMMAND PALETTE
--==============================================================

function Window:CreateCommandPalette()
	local palette = Create.create("Frame", {
		Parent = self.Gui,
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 90),
		Size = UDim2.fromOffset(560(palette)

	local input = Create.create("TextBox", {
		Parent = palette,
		Position = UDim2.fromOffset(8, 8),
		Size = UDim2.new(1, -16, 0, 30),
		BorderSizePixel = 1,
		PlaceholderText = "Search commands…   (Ctrl+P)",
		ClearTextOnFocus = false,
		Text = "",
		TextXAlignment = Enum.TextXAlignment.Left,
		Font = Theme.Font,
		TextSize = Theme.TextSize,
		ZIndex = Layer.Modal + 1,
		theme = { BackgroundColor3 = "PanelAlt", BorderColor3 = "Border", TextColor3 = "Text" },
	})

	Create.create("UIPadding", { Parent = input, PaddingLeft = UDim.new(0, 6) })

	local results = Create.create("ScrollingFrame", {
		Parent = palette,
		Position = UDim2.fromOffset(8, 46),
		Size = UDim2.new(1, -16, 1, -54),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 6,
		CanvasSize = UDim2.new(),
		ZIndex = Layer.Modal + 1,
		theme = { ScrollBarImageColor3 = "Scroll" },
	})

	local layout = Create.create("UIListLayout", {
		Parent = results,
		Padding = UDim.new(0, 3),
		SortOrder = EnateSelection()
		if #resultButtons == 0 then return end
		selectedIndex = math.clamp(selectedIndex, 1, #resultButtons)

		for i, button in ipairs(resultButtons) do
			button.BackgroundColor3 = (i == selectedIndex) and Theme.Selection or Theme.Button
		end

		local button = resultButtons[selectedIndex]
		if not button or not results.Parent then return end

		-- [FIX 29] Scale-corrected scroll-into-view. AbsolutePosition deltas are
		-- scaled px; CanvasPosition is in local units. Mixing them meant the
		-- keyboard selection drifted out of view on any non-1.0 scale.
		local itemTop = self:ToLocal(button.AbsolutePosition.Y - results.AbsolutePosition.Y) + results.CanvasPosition.Y
		local itemBottom = itemTop + self:ToLocal(button.AbsoluteSize.Y)
		local viewTop = results.CanvasPosition.Y
		local viewHeight = self:ToLocal(results.AbsoluteWindowSize.Y)

		if itemTop < viewTop then
			results.CanvasPosition = Vector2.new(0, math.max(0, itemTop))
		elseif itemBottom > viewTop + viewHeight then
			results.CanvasPosition = Vector2.new(0, math.max(0, itemBottom - viewHeight))
		end
	end

	local function rebuild()
		itemMaid:Cleanup()
		table.clear(visibleCommands)
		table.clear(resultButtons)

		local query = string.lower(input.Text or "")

		for _, commandName in ipairs(X64UI.CommandOrder) do
			local command = X64UI.Commands[commandName]
			if command then
				local searchable = string command.Description ~= "" then
						text = text .. "   —   " .. command.Description
					end

					local item = Create.create("TextButton", {
						Parent = results,
						Size = UDim2.new(1, 0, 0, 34),
						BorderSizePixel = 1,
						Text = "  " .. text,
						TextXAlignment = Enum.TextXAlignment.Left,
						TextTruncate = Enum.TextTruncate.AtEnd,
						Font = Theme.Font,
						TextSize = Theme.TextSize,
						AutoButtonColor = false,
						LayoutOrder = #visibleCommands,
						ZIndex = Layer.Modal + 2,
						theme = { BackgroundColor3 = "Button", BorderColor3 = "Border", TextColor3 = "Text" },
					})

					itemMaid:Give(item)

					local index = #visibleCommands
					itemMaid:Give(item.MouseEnter:Connect(function()
						selectedIndex = index
						updateSelection()
					end))
					itemMaid:Give(item.MouseButton1Click:Connect(function()
						local name = command.Name
						self:CloseCommandPalette()
						X64UI:ExecuteCommand(name)
					end))

					table.insert(resultButtons, item)
				end
			end
		end

		results.CanvasSize = UDim2.fromOffset(0, self:ToLocal(layout.AbsoluteContentSize.Y) + 8)
		selectedIndex = math.clamp(selectedIndex, 1, math.max(1, #resultButtons))
		updateSelection()
	end

	local function moveSelection(delta)
		if #resultButtons == 0 then return end
		selectedIndex = math.clamp(selectedIndex + delta, 1, #resultButtons)
		updateSelection()
	end

	self:Track(input:GetPropertyChangedSignal("Text"ape cannot leak to keypickers or the game. The old
	-- version connected raw UserInputService and let everything through.
	local releaseCapture

	local function closePalette()
		if not palette.Visible then return end
		palette.Visible = false
		if releaseCapture then
			releaseCapture()
			releaseCapture = nil
		end
		input:ReleaseFocus()
		self:UnregisterPopup(self._PaletteHandle)
	end

	local function openPalette()
		if palette.Visible then return end
		palette.Visible = true
		input.Text = ""
		selectedIndex = 1
		rebuild()
		input:CaptureFocus()
		self:Focus()

		releaseCapture = InputRouter:PushCapture({
			Began = function(inputObject)
				if inputObject.UserInputType ~= Enum.UserInputType.Keyboard then return end
				local key = inputObject.KeyCode

				if key == Enum.KeyCode.Escape then
					closePalette()
				elseif key == Enum.KeyCode.Up then
					moveSelection(-1)
				elseif key == Enum.KeyCode.Down then
					moveSelection(1)
				elseif key == Enum.KeyCode.Return or key == Enum.KeyCode.KeypadEnter then
					local command = visibleCommands[selectedIndex]
					if command then
						local name = command.Name
						closePalette()
						X64UI:ExecuteCommand(name)
					end
				end
			end,
		})

		self._alette()   openPalette()  end
	function self:CloseCommandPalette()  closePalette() end
	function self:ToggleCommandPalette()
		if palette.Visible then closePalette() else openPalette() end
	end

	self.Maid:Give(closePalette)
	return palette
end

--==============================================================
-- GROUPBOX
--==============================================================

function Tab:AddGroupbox(side, title)
	local isLeft = side ~= "Right"
	local parent = isLeft and self.LeftPane or self.RightPane

	local order
	if isLeft then
		self.NextLeftOrder += 1
		order = self.NextLeftOrder
	else
		self.NextRightOrder += 1
		order = self.NextRightOrder
	end

	local group = setmetatable({
		Window = self.Window,
		Tab = self,
		Title = title or "Group",
		Controls = {},
		NextOrder = 0,
	}, Groupbox)

	group.Frame = Create.create("Frame", {
		Parent = parent,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BorderSizePixel = 1,
		LayoutOrder = order,
		theme = { BackgroundColor3 = "Panel", BorderColor3 = "Border" },
	})

	Create.create("UIListLayout", {
		Parent = group.Frame,
		SortOrder = Enum.SortOrder.LayoutOrder,
	})

	group.Header = Create.create("TextLabel", {
		Parent = group.Frame,
		LayoutOrder = 0,
		Size = UDim2.new(1, 0, 0, 20),
		BorderSizePixel = 0,
		Text = " " .. tostring(group.Title),
		TextXAlignment = Enum.TextWarning" },
	})

	group.Content = Create.create("Frame", {
		Parent = group.Frame,
		LayoutOrder = 1,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
	})

	group.Layout = Create.create("UIListLayout", {
		Parent = group.Content,
		Padding = UDim.new(0, 4),
		SortOrder = Enum.SortOrder.LayoutOrder,
	})

	Create.create("UIPadding", {
		Parent = group.Content,
		PaddingTop = UDim.new(0, 4),
		PaddingLeft = UDim.new(0, 4),
		PaddingRight = UDim.new(0, 4),
		PaddingBottom = UDim.new(0, 4),
	})

	table.insert(self.Groupboxes, group)
	return group
end

function Tab:AddLeftGroupbox(title)  return self:AddGroupbox("Left", title)  end
function Tab:AddRightGroupbox(title) return self:AddGroupbox("Right", title) end

function Tab:GetDefaultGroupbox()
	if not self.DefaultGroupbox or self.DefaultGroupbox.Destroyed then
		self.DefaultGroupbox = self:AddLeftGroupbox("General")
	end
	return self.DefaultGroupbox
end

function Groupbox:SetTitle(title)
	self.Title = title
	if self.Header then self.Header.Text = " " .. tostring(title) end
end

--[[
	[ the row, every Clear leaked one orphaned popup per
	control, left dead entries in Registry (so SaveConfig wrote stale values and
	LoadConfig wrote into destroyed instances), never destroyed the Changed
	signals, and left dead dropdowns in win.Dropdowns for the per-frame
	reposition loop to walk forever.

	[FIX 31] NextOrder resets to 0, matching createControlFrame's starting value.
	The old reset to 1 meant the first control added after a Clear sorted one slot
	lower than an identical control in a fresh groupbox.
]]
function Groupbox:Clear()
	local controls = table.clone(self.Controls)
	for _, control in ipairs(controls) do
		if control and control.Destroy then
			pcall(function() control:Destroy() end)
		end
	end
	table.clear(self.Controls)

	-- Sweep anything left behind that was not a registered control.
	for _, child in ipairs(self.Content:GetChildren()) do
		if not child:IsA("UIListLayout") and not child:IsA("UIPadding") then
			child:Destroy()
		end
	end

	self.NextOrder = 0
end

function Groupbox:Destroy()
	if self.Destroyed then return end
	self.Destroyed = true
	self:Clear()
	if self.Frame then pcall(function() self.Frame:Destroy() end) end

	if self.Tab and self.Tab.Groupboxes then
		local index = table.find(self.Tab.Groupboxes,Size = UDim2.new(1, 0, 0, height or 24),
		BackgroundTransparency = 1,
		LayoutOrder = group.NextOrder,
	})

	group.NextOrder += 1

	if automatic then
		row.AutomaticSize = Enum.AutomaticSize.Y
	end

	local layout = Create.create("UIListLayout", {
		Parent = row,
		Padding = UDim.new(0, 3),
		SortOrder = Enum.SortOrder.LayoutOrder,
		FillDirection = horizontal and Enum.FillDirection.Horizontal or Enum.FillDirection.Vertical,
	})

	if horizontal then
		layout.VerticalAlignment = Enum.VerticalAlignment.Center
	end

	return row, layout
end

-- Every control funnels through here so registration, group tracking and
-- lifecycle are identical for all of them.
local function finishControl(group, control, controlType, name)
	control.Group = group
	table.insert(group.Controls, control)
	group.Window.Maid:Give(control)

	if name then
		group.Window.Registry:Register(name, control, controlType)
	end

	-- Linoria-style chaining without the old "find my groupbox" guesswork.
	function control:AddKeyPicker(pickerName, opts)   return group:AddKeyPicker(pickerName, opts)   end
	function control:AddColorPicker(pickerName, opts) return group:AddColorPicker(pickerName, opts) end

	return control
end

local function makText = tostring(text),
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Font = Theme.Font,
		TextSize = Theme.TextSize,
		theme = { TextColor3 = "Text" },
	})
end

--==============================================================
-- CONTROL: LABEL / BUTTON / DIVIDER
--==============================================================

function Groupbox:AddLabel(text, wrap)
	local row = createControlFrame(self, nil, true, false)

	local label = Create.create("TextLabel", {
		Parent = row,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		Text = tostring(text or ""),
		TextWrapped = wrap and true or false,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top,
		Font = Theme.Font,
		TextSize = Theme.TextSize,
		theme = { TextColor3 = "Text" },
	})

	local obj = BaseControl.new("Label", row, self.Window, nil)
	obj.Label = label

	function obj:SetText(newText) label.Text = tostring(newText) end
	function obj:GetValue() return label.Text end

	return finishControl(self, obj, "Label", nil)
end

function Groupbox:AddDivider()
	local row = createControlFrame(self, 8, false, false)

	Create.create("Frame", {
		Parent = row,
		Size = UDim2.new(1, 0, 0, 1),
		Position = UDim2.new(0, 0, 0.5, 0),
		BorderSizePixel = 0,
		ControlFrame(self, 26, false, false)

	local button = Create.create("TextButton", {
		Parent = row,
		Size = UDim2.new(1, 0, 1, 0),
		BorderSizePixel = 1,
		Text = opts.Text or "Button",
		Font = Theme.Font,
		TextSize = Theme.TextSize,
		AutoButtonColor = false,
		theme = { BackgroundColor3 = "Button", BorderColor3 = "Border", TextColor3 = "Text" },
	})

	local obj = BaseControl.new("Button", row, self.Window, nil)
	obj.Button = button

	function obj:SetText(newText) button.Text = tostring(newText) end

	function obj:OnStateChanged()
		button.TextColor3 = self:CanInteract() and Theme.Text or Theme.Dim
	end

	self.Window:Track(button.MouseEnter:Connect(function()
		if obj:CanInteract() then button.BackgroundColor3 = Theme.ButtonHover end
	end))
	self.Window:Track(button.MouseLeave:Connect(function()
		button.BackgroundColor3 = Theme.Button
	end))

	self.Window:Track(button.MouseButton1Click:Connect(function()
		-- [FIX 32a] Disabled buttons used to log and, if a Callback existed,
		-- the old code checked obj.Disabled but still logged unconditionally.
		if not obj:CanInteract() then return end

		if opts.Callback then
			local ok, err = xpcall(opts.Callback, traceback)
			if not ok then Log.warn("Button callback failed:\n" .. tostring(err)) end
		end

		if, obj, "Button", nil)
end

--==============================================================
-- CONTROL: TOGGLE
--==============================================================

function Groupbox:AddToggle(name, opts)
	opts = opts or {}
	local row = createControlFrame(self, 22, false, true)
	local state = State.new(opts.Default == true)

	local check = Create.create("TextButton", {
		Parent = row,
		Size = UDim2.fromOffset(18, 18),
		BorderSizePixel = 1,
		Text = "",
		Font = Theme.Font,
		TextSize = 13,
		AutoButtonColor = false,
		theme = { BorderColor3 = "Border", TextColor3 = "AccentText" },
	})

	local label = Create.create("TextButton", {
		Parent = row,
		Size = UDim2.new(1, -24, 1, 0),
		BackgroundTransparency = 1,
		Text = opts.Text or name or "Toggle",
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Font = Theme.Font,
		TextSize = Theme.TextSize,
		AutoButtonColor = false,
		theme = { TextColor3 = "Text" },
	})

	local obj = BaseControl.new("Toggle", row, self.Window, name)
	obj.Value = state:Get()
	obj.Button = check
	obj.Label = label
	obj.NoSave = opts.NoSave == true
	obj.Changed = Signal.new()

	local internalChange = false

	local function render(value)
		obj.Value = value
		check.Text = value and Glyphs.Check or ""
		check.BackgroundColor3 = value and Theme.Accent or Theme.PanelAlt
	end

	local function set(value, silent, withHistory)
		value = value == true
		local previous = state:Get()
		if:Fire(name or "Toggle", value)
			end

			if opts.Callback then
				local ok, err = xpcall(opts.Callback, traceback, value, previous)
				if not ok then Log.warn("Toggle callback failed:\n" .. tostring(err)) end
			end
		end

		if withHistory and not internalChange then
			self.Window.History:Push("Toggle " .. tostring(opts.Text or name),
				function() internalChange = true; set(previous, false, false); internalChange = false end,
				function() internalChange = true; set(value, false, false);    internalChange = false end
			)
		end
	end

	-- [FIX 32] The toggle checked NOTHING before acting. SetDisabled only set
	-- Frame.Active, which does not stop descendant TextButtons, so a "disabled"
	-- toggle rendered greyed out and still toggled on click.
	local function onClick()
		if not obj:CanInteract() then return end
		set(not state:Get(), false, true)
	end

	self.Window:Track(check.MouseButton1Click:Connect(onClick))
	self.Window:Track(label.MouseButton1Click:Connect(onClick))

	function obj:OnStateChanged()
		label.TextColor3 = self:CanInteract() and Theme.Text or Theme.Dim
		check.BackgroundTransparency = self.Disabled and 0.4 or 0
	end

	function obj:SetValue(value, silent) set(value, silent == true, false) end
	function obj:GetValue() return state:Get() end

	render(state:Get())
	attachTooltip(self.Window, label, opts.Tooltip)
	return finishControl(self, obj, "Toggle", or 100
	if max < min then min, max = max, min end

	local digits = math.clamp(math.floor(tonumber(opts.Rounding) or 0), 0, 6)
	local step = 1 / (10 ^ digits)
	local suffix = opts.Suffix or ""

	local row = createControlFrame(self, nil, true, false)

	local header = Create.create("Frame", {
		Parent = row,
		Size = UDim2.new(1, 0, 0, 16),
		BackgroundTransparency = 1,
	})

	-- Absolute positioning, not a list layout: a horizontal list plus a scale-1
	-- label made the value overlap the name at narrow widths.
	makeLabel(header, opts.Text or name or "Slider", UDim2.new(1, -56, 1, 0)).TextYAlignment = Enum.TextYAlignment.Center

	local valueBox = Create.create("TextBox", {
		Parent = header,
		Size = UDim2.fromOffset(52, 16),
		Position = UDim2.new(1, -52, 0, 0),
		BackgroundTransparency = 1,
		Text = "",
		TextXAlignment = Enum.TextXAlignment.Right,
		TextYAlignment = Enum.TextYAlignment.Center,
		ClearTextOnFocus = false,
		Font = Theme.Font,
		TextSize = Theme.TextSize,
		theme = { TextColor3 = "AccentText" },
	})

	local bar = Create.create("TextButton", {
		Parent = row,
		Size = UDim2.new(1, 0, 0, 14),
		BorderSizePixel = 1,
		Text = "",
		AutoButtonColor = false,
		theme = { BackgroundColor3 or3 = "Accent" },
	})

	local obj = BaseControl.new("Slider", row, self.Window, name)
	obj.Value = math.clamp(tonumber(opts.Default) or min, min, max)
	obj.Min = min
	obj.Max = max
	obj.NoSave = opts.NoSave == true
	obj.Changed = Signal.new()

	local function format(v)
		local text = (digits > 0) and string.format("%." .. digits .. "f", v) or tostring(math.floor(v + 0.5))
		return text .. suffix
	end

	local function round(v)
		return math.floor((v / step) + 0.5) * step
	end

	-- [FIX 33] set() now takes withHistory, like every other control. The old
	-- slider's FocusLost handler called set(typed, false, true) against a
	-- two-parameter set, so the third argument was silently discarded and typing
	-- a value produced no undo entry while dragging one did.
	local function set(v, silent, withHistory)
		v = tonumber(v)
		if not v then
			valueBox.Text = format(obj.Value)
			return
		end

		v = math.clamp(round(v), min, max)
		local previous = obj.Value
		obj.Value = v
		valueBox.Text = format(v)
		fill.Size = UDim2.fromScale((max ~= min) and ((v - min) / (max - min)) or 0, 1)

		if not silent and previous ~= v then
			obj.Changed:Fire(v, previous)

			if self.Window.Events and self.Window.Events.Changed then
				self.Window.Events.Changed:

		if withHistory and previous ~= v then
			self.Window.History:Push("Slider " .. tostring(opts.Text or name),
				function() set(previous, false, false) end,
				function() set(v, false, false) end
			)
		end
	end

	local function updateFromX(x)
		if not bar.Parent then return end
		local rel = math.clamp((x - bar.AbsolutePosition.X) / math.max(bar.AbsoluteSize.X, 1), 0, 1)
		set(min + ((max - min) * rel), false, false)
	end

	-- [FIX 34] The drag listener is created on mouse-down and disposed on
	-- mouse-up. The old build connected a global InputChanged per slider at
	-- construction, so a panel with forty sliders ran forty handlers on every
	-- single mouse movement for the entire lifetime of the window.
	local dragDisposers = nil
	local dragStartValue = obj.Value

	local function stopDrag(commit)
		if not dragDisposers then return end
		for _, dispose in ipairs(dragDisposers) do dispose() end
		dragDisposers = nil

		if commit and obj.Value ~= dragStartValue then
			local oldValue, newValue = dragStartValue, obj.Value
			self.Window.History:Push("Slider " .. tostring(opts.Text or name),
				function() set(oldValue, false, false) end,
				function() set(newValue, false, false) end
			)
		end
	end

	self.Window:Track(bar.InputBegan:Connect(function(input)
		if input.UserInputType ~= Enum.UserInputType.Mouse("Changed", function(moved)
				if moved.UserInputType == Enum.UserInputType.MouseMovement then
					updateFromX(getMousePos().X)
				end
			end),
			InputRouter:On("Ended", function(ended)
				if ended.UserInputType == Enum.UserInputType.MouseButton1 then stopDrag(true) end
			end),
		}
	end))

	self.Window:Track(UserInputService.WindowFocusReleased:Connect(function() stopDrag(true) end))
	self.Window:Track(function() stopDrag(false) end)

	-- [FIX 35] Parse the whole string with tonumber first. The old pattern
	-- match "[%d%.%-]+" turned "5-3" into a nil parse but silently accepted
	-- "1.2.3", and stripped the exponent from "1e3".
	self.Window:Track(valueBox.FocusLost:Connect(function()
		if not obj:CanInteract() then
			valueBox.Text = format(obj.Value)
			return
		end

		local text = valueBox.Text
		local typed = tonumber(text) or tonumber(text:match("%-?%d+%.?%d*"))

		if typed then
			set(typed, false, true)
		else
			valueBox.Text = format(obj.Value)
		end
	end))

	function obj:OnStateChanged()
		valueBox.TextEditable = self:CanInteract()
		fill.BackgroundColor3 = self:CanInteract() and Theme.Accent or Theme.Dim
	end

	function obj:SetValue(v, silent) set(v, silent == true, false) end min, max = max, min end
		obj.Min, obj.Max = min, max
		set(obj.Value, true, false)
	end

	set(obj.Value, true, false)
	attachTooltip(self.Window, bar, opts.Tooltip)
	return finishControl(self, obj, "Slider", name)
end

--==============================================================
-- CONTROL: DROPDOWN
--==============================================================

function Groupbox:AddDropdown(name, opts)
	opts = opts or {}

	local values = opts.Values or {}
	local multi = opts.Multi == true
	local rowHeight = 19

	local row = createControlFrame(self, nil, true, false)
	makeLabel(row, opts.Text or name or "Dropdown")

	local function formatLabel(value)
		if multi then
			local count = (type(value) == "table") and #value or 0
			if count == 0 then return Glyphs.ArrowDown .. " none selected" end
			if count == 1 then return Glyphs.ArrowDown .. " " .. tostring(value[1]) end
			return Glyphs.ArrowDown .. " " .. count .. " selected"
		end
		return Glyphs.ArrowDown .. " " .. tostring(value == nil and "—" or value)
	end

	local button = Create.create("TextButton", {
		Parent = row,
		Size = UDim2.new(1, 0, 0, 20),
		BorderSizePixel = 1,
		Text = "",
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Font = Theme.Font,
		TextSize = Theme.TextSize,
		AutoButtonColor = false,
		theme = { BackgroundColor3 = "PanelAlt", BorderColor3 = "Border", TextColor3 = "Text" },
	})olling area. The old build
	-- parented it into the ScrollingFrame's list layout, so it scrolled off the
	-- top as soon as you moved the wheel and could not be reached again.
	local panel = Create.create("Frame", {
		Parent = self.Window.Gui,
		Visible = false,
		BorderSizePixel = 1,
		ZIndex = Layer.Popup,
		theme = { BackgroundColor3 = "Panel", BorderColor3 = "Border" },
	})

	self.Window:AttachScale(panel)

	local searchBox = Create.create("TextBox", {
		Parent = panel,
		Position = UDim2.fromOffset(0, 0),
		Size = UDim2.new(1, 0, 0, 20),
		BorderSizePixel = 0,
		PlaceholderText = " Search…",
		Text = "",
		ClearTextOnFocus = false,
		TextXAlignment = Enum.TextXAlignment.Left,
		Font = Theme.Font,
		TextSize = Theme.TextSize,
		ZIndex = Layer.Popup + 1,
		theme = { BackgroundColor3 = "PanelAlt", TextColor3 = "Text" },
	})

	local list = Create.create("ScrollingFrame", {
		Parent = panel,
		Position = UDim2.fromOffset(0, 20),
		Size = UDim2.new(1, 0, 1, -20),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 6,
		CanvasSize = UDim2.new(),
		ZIndex = Layer.Popup + 1,
		theme = { ScrollBarImageColor3 = "("Dropdown", row, self.Window, name)
	obj.Button = button
	obj.Panel = panel
	obj.List = list
	obj.Multi = multi
	obj.Values = values
	obj.OpenedAt = 0
	obj.NoSave = opts.NoSave == true
	obj.Changed = Signal.new()
	obj:TrackPopup(panel)

	-- Resolve the initial selection.
	if multi then
		obj.Value = (type(opts.Default) == "table") and table.clone(opts.Default) or {}
	else
		local selected = opts.Default
		if typeof(selected) == "number" and values[selected] ~= nil then
			selected = values[selected]
		end
		if not table.find(values, selected) then selected = values[1] end
		obj.Value = selected
	end

	local internalChange = false
	local filtered = {}
	local itemMaid = Maid.new()
	self.Window.Maid:Give(itemMaid)

	local function isSelected(value)
		if multi then
			return type(obj.Value) == "table" and table.find(obj.Value, value) ~= nil
		end
		return obj.Value == value
	end

	-- [FIX 37] Height comes from the FILTERED count. The old getListHeight used
	-- #values, so a 500-item dropdown stayed pinned at its 220px cap even after
	-- you filtered it down to two matches, leaving a t end

		local window = self.Window
		local pos = button.AbsolutePosition
		local size = button.AbsoluteSize
		local height = getPanelHeight()
		local viewport = getViewportSize(window.Gui)

		local spaceBelow = viewport.Y - (pos.Y + size.Y)
		local openUp = spaceBelow < height + 8 and pos.Y > height + 8

		panel.Position = UDim2.fromOffset(
			window:ToLocal(pos.X),
			window:ToLocal(openUp and (pos.Y - height - 2) or (pos.Y + size.Y + 2))
		)
		panel.Size = UDim2.fromOffset(window:ToLocal(size.X), height)
	end

	local function buildItems()
		itemMaid:Cleanup()
		table.clear(filtered)

		local query = string.lower(searchBox.Text or "")
		for _, value in ipairs(values) do
			if query == "" or string.find(string.lower(tostring(value)), query, 1, true) then
				filtered[#filtered + 1] = value
			end
		end

		local cap = 200
		local shown = math.min(#filtered, cap)

		for i = 1, shown do
			local value = filtered[i]
			local selected = isSelected(value)

			local item = Create.create("TextButton", {
				Parent = list,
				LayoutOrder = i,
				Size = UDim2.new(1, 0, 0, 18),
				BackgroundTransparency = selected and 0 or 1,
				Text = (selected and (Glyphs.Check .. " ") or "   ") .. tostring(value),
				TextXAlignment = Enum.TextXAlignment.Left,
				TextTruncate = Enum.TextTruncate.AtEnd,
				Font = Theme.Font,
				TextSize =id:Give(item.MouseEnter:Connect(function()
				item.BackgroundTransparency = 0
			end))
			itemMaid:Give(item.MouseLeave:Connect(function()
				item.BackgroundTransparency = isSelected(value) and 0 or 1
			end))
			itemMaid:Give(item.MouseButton1Click:Connect(function()
				if not obj:CanInteract() then return end

				if multi then
					local next = table.clone(obj.Value)
					local index = table.find(next, value)
					if index then table.remove(next, index) else table.insert(next, value) end
					obj:_Set(next, false, true)
					buildItems()
				else
					obj:_Set(value, false, true)
					obj:Close()
				end
			end))
		end

		if #filtered > cap then
			itemMaid:Give(Create.create("TextLabel", {
				Parent = list,
				LayoutOrder = cap + 1,
				Size = UDim2.new(1, 0, 0, 16),
				BackgroundTransparency = 1,
				Text = ("   showing %d of %d — type to filter"):format(cap, #filtered),
				TextXAlignment = Enum.TextXAlignment.Left,
				Font = Theme.Font,
				TextSize = Theme.TextSize - 1,
				ZIndex = Layer.Popup + 2,
				theme = { TextColor3 = "Dim" },
			}))
		end

		if #filtered == 0 then
			itemMaid:Give(Create.create("TextLabel", {extSize = Theme.TextSize,
				ZIndex = Layer.Popup + 2,
				theme = { TextColor3 = "Dim" },
			}))
		end

		list.CanvasSize = UDim2.fromOffset(0, self.Window:ToLocal(listLayout.AbsoluteContentSize.Y) + 2)
		if panel.Visible then obj:RefreshPosition() end
	end

	function obj:_Set(value, silent, withHistory)
		local previous = multi and table.clone(obj.Value) or obj.Value

		if multi then
			if type(value) ~= "table" then return end
			-- [FIX 38] Store a copy so a caller holding the table cannot mutate
			-- our internal state behind the Changed signal's back.
			obj.Value = table.clone(value)
		else
			if value ~= nil and not table.find(values, value) then return end
			obj.Value = value
		end

		button.Text = formatLabel(obj.Value)

		if not silent then
			obj.Changed:Fire(obj.Value, previous)

			if self.Window.Events and self.Window.Events.Changed then
				self.Window.Events.Changed:Fire(name or "Dropdown", obj.Value)
			end

			if opts.Callback then
				local ok, err = xpcall(opts.Callback, traceback, obj.Value, previous)
				if not ok then Log.warn("Dropdown callback failed:\n" .. tostring(err)) end
			end
		end

		if withHistory and not internalChange then
			local newValue = multi and table.clone(obj.Value) or obj.Value
			self.Window.History:Push("Dropdown " .. tostring(opts.Text or name),
				function() internalChange = true; objract() then return end
		buildItems()
		obj:RefreshPosition()
		panel.Visible = true
		obj.OpenedAt = os.clock()
		self.Window:RegisterPopup(obj)
		self.Window:Focus()
	end

	function obj:Close()
		if not panel.Visible then return end
		panel.Visible = false
		searchBox.Text = ""
		self.Window:UnregisterPopup(obj)
	end

	function obj:Toggle()
		if panel.Visible then obj:Close() else obj:Open() end
	end

	self.Window:Track(button.MouseButton1Click:Connect(function()
		if not obj:CanInteract() then return end
		obj:Toggle()
	end))

	self.Window:Track(searchBox:GetPropertyChangedSignal("Text"):Connect(buildItems))

	-- [FIX 39] SetValues updates the closure variable AND obj.Values, then
	-- re-validates the selection. The old version reassigned only the local, so
	-- the validation check inside set() kept testing a stale array and silently
	-- rejected every new selection forever after the first SetValues call.
	function obj:SetValues(newValues, keepSelection)
		values = newValues or {}
		obj.Values = values

		if multi then
			local kept = {}
			for _, value in ipairs(obj.Value) do
				if table.find(values, value) then table.insert(kept, value) end
			end
			obj.Value = kept
		elseif keepSelection ~= true or not table.find(values, obj.Value) then
			obj.Value = values[1]
		end

		button.Text = formatLabel(obj.Value)
		buildItems() obj.Value end

	function obj:OnStateChanged()
		button.TextColor3 = self:CanInteract() and Theme.Text or Theme.Dim
	end

	button.Text = formatLabel(obj.Value)
	buildItems()
	table.insert(self.Window.Dropdowns, obj)

	attachTooltip(self.Window, button, opts.Tooltip)
	return finishControl(self, obj, "Dropdown", name)
end

--==============================================================
-- CONTROL: INPUT / NUMERIC INPUT
--==============================================================

function Groupbox:AddInput(name, opts)
	opts = opts or {}
	local row = createControlFrame(self, nil, true, false)
	makeLabel(row, opts.Text or name or "Input")

	local box = Create.create("TextBox", {
		Parent = row,
		Size = UDim2.new(1, 0, 0, 20),
		BorderSizePixel = 1,
		PlaceholderText = opts.Placeholder or "",
		Text = tostring(opts.Default or ""),
		ClearTextOnFocus = false,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Font = Theme.Font,
		TextSize = Theme.TextSize,
		theme = { BackgroundColor3 = "PanelAlt", BorderColor3 = "Border", TextColor3 = "Text" },
	})

	Create.create("UIPadding", { Parent = box, PaddingLeft = UDim.new(0, 4) })

	if opts.MaxLength then box.MultiLine = false end

	local obj = BaseControl.new("Input", row, self.Window, name)
	obj.Value = tostring(opts.Default or "")
	obj.TextBox = box
	obj.NoSave = opts.NoSave == true
	obj.Changed =, opts.MaxLength) end

		local previous = obj.Value
		if previous == value then
			box.Text = value
			return
		end

		obj.Value = value
		box.Text = value
		if not box:IsFocused() then committedValue = value end

		if not silent then
			obj.Changed:Fire(value, previous)

			if self.Window.Events and self.Window.Events.Changed then
				self.Window.Events.Changed:Fire(name or "Input", value)
			end

			if opts.Callback then
				local ok, err = xpcall(opts.Callback, traceback, value, previous)
				if not ok then Log.warn("Input callback failed:\n" .. tostring(err)) end
			end
		end

		if withHistory and not internalChange then
			self.Window.History:Push("Input " .. tostring(opts.Text or name),
				function() internalChange = true; set(previous, false, false); internalChange = false end,
				function() internalChange = true; set(value, false, false);    internalChange = false end
			)
		end
	end

	self.Window:Track(box.Focused:Connect(function()
		committedValue = box.Text
	end))

	self.Window:Track(box.FocusLost:Connect(function()
		-- [FIX 32b] The input committed unconditionally, so a read-only or
		-- disabled field still fired callbacks and pushed history entries.
		if not obj:CanInteract() then
			box.Text = obj.Value
			return
		end

		local text = box.Text
		if text ~= committedValue then
			set(text, false, true)
			committedValue = obj.Value
		else
			box.Text = obj.Value
		end
	end))

	function obj:OnStateChanged()
		-- [FIX 40] Derived from Cing on a read-only field.
		box.TextEditable = self:CanInteract()
		box.TextColor3 = self:CanInteract() and Theme.Text or Theme.Dim
	end

	function obj:SetValue(value, silent)
		set(value, silent == true, false)
		committedValue = obj.Value
	end
	function obj:GetValue() return obj.Value end

	attachTooltip(self.Window, box, opts.Tooltip)
	return finishControl(self, obj, "Input", name)
end

function Groupbox:AddNumericInput(name, opts)
	opts = opts or {}
	local minV, maxV = tonumber(opts.Min), tonumber(opts.Max)
	local digits = math.clamp(math.floor(tonumber(opts.Rounding) or 0), 0, 6)

	local row = createControlFrame(self, nil, true, false)
	makeLabel(row, opts.Text or name or "Number")

	local box = Create.create("TextBox", {
		Parent = row,
		Size = UDim2.new(1, 0, 0, 20),
		BorderSizePixel = 1,
		Text = tostring(tonumber(opts.Default) or 0),
		ClearTextOnFocus = false,
		TextXAlignment = Enum.TextXAlignment.Left,
		Font = Theme.Font,
		TextSize = Theme.TextSize,
		theme = { BackgroundColor3 = "PanelAlt", BorderColor3 = "Border", TextColor3 = "Text" },
	})

	Create.create("UIPadding", { Parent = box, PaddingLeft = UDim.new(0, 4) })

	local obj = BaseControl.new("NumericInput", row, self.Window, name)
	obj.Value = tonumber(opts.Default) or 0
	obj.TextBox = box
	obj.NoSave = opts.NoSave == true
	ob v then
			box.Text = format(obj.Value)
			return
		end

		if minV then v = math.max(minV, v) end
		if maxV then v = math.min(maxV, v) end
		if digits > 0 then
			local factor = 10 ^ digits
			v = math.floor((v * factor) + 0.5) / factor
		else
			v = math.floor(v + 0.5)
		end

		local previous = obj.Value
		box.Text = format(v)
		if previous == v then return end
		obj.Value = v

		if not silent then
			obj.Changed:Fire(v, previous)

			if self.Window.Events and self.Window.Events.Changed then
				self.Window.Events.Changed:Fire(name or "NumericInput", v)
			end

			if opts.Callback then
				local ok, err = xpcall(opts.Callback, traceback, v, previous)
				if not ok then Log.warn("NumericInput callback failed:\n" .. tostring(err)) end
			end
		end

		if withHistory then
			self.Window.History:Push("Number " .. tostring(opts.Text or name),
				function() set(previous, false, false) end,
				function() set(v, false, false) end
			)
		end
	end

	self.Window:Track(box.FocusLost:Connect(function()
		if not obj:CanInteract() then
			box.Text = format(obj.Value)
			return
		end
		set(box.Text, false, true)
	end))

	function obj:OnStateChanged()
		box.TextEditable = self:CanInteract()
		box.TextColor3 = self:CanInteract() and Theme.Text or Theme.Dim
	end

	function obj:SetValue(v, silent) set(v, silent == true, false) end
	function obj:GetValue() return obj.Value end

	set(obj.Value, true, false)
	attachTooltip(self.Window, box, opts.Tooltip)
	return finishControl(self, obj-- Toggle | Hold | Press | Always
	local noUI = opts.NoUI == true

	local row, button
	if not noUI then
		row = createControlFrame(self, 22, false, true)
		makeLabel(row, opts.Text or name or "Keybind", UDim2.new(1, -94, 1, 0))

		button = Create.create("TextButton", {
			Parent = row,
			Size = UDim2.fromOffset(90, 18),
			BorderSizePixel = 1,
			Text = tostring(opts.Default or "None"),
			Font = Theme.Font,
			TextSize = Theme.TextSize,
			AutoButtonColor = false,
			theme = { BackgroundColor3 = "PanelAlt", BorderColor3 = "Border", TextColor3 = "Text" },
		})
	end

	local obj = BaseControl.new("KeyPicker", row, self.Window, name)
	obj.Value = tostring(opts.Default or "None")
	obj.Mode = mode
	obj.Button = button
	obj.NoSave = opts.NoSave == true
	obj.Changed = Signal.new()
	obj.Clicked = Signal.new()
	obj._State = false
	obj._Holding = false

	local internalChange = false

	local function set(value, silent, withHistory)
		value = tostring(value)
		local previous = obj.Value
		if previous == value then return end

		obj.Value = value
		if button then button.Text = value end

		if not silent then
			obj.Changed:Fire(value, previous)

			if self.Window.Events and self.Window.Events.Changed then
				self.Window.Events.Changed:Fire(name or "KeyPicker", value)
			end

			if opts.Callback then
				local ok, err = xpcall(opts.Callback, traceback, value, previous)
				if not ok then Log.warn("KeyPicker callback failed:\n" .. tostring(err)) end
			end
		end

		 false end
			)
		end
	end

	local function fireClick()
		obj.Clicked:Fire(obj._State)
		if opts.OnClick then
			local ok, err = xpcall(opts.OnClick, traceback, obj._State)
			if not ok then Log.warn("KeyPicker OnClick failed:\n" .. tostring(err)) end
		end
	end

	local function onKeyBegan(input, gameProcessed)
		if obj.Destroyed or obj.Disabled then return end
		if gameProcessed and mode ~= "Always" then return end
		if UserInputService:GetFocusedTextBox() then return end
		if self.Window.PickingKey then return end
		if obj.Value == "None" or obj.Value == "" then return end
		if not InputMatchesBind(input, obj.Value) then return end

		if mode == "Toggle" then
			obj._State = not obj._State
			fireClick()
		elseif mode == "Hold" then
			obj._Holding = true
			obj._State = true
			fireClick()
		elseif mode == "Press" then
			obj._State = true
			fireClick()
			obj._State = false
		elseif mode == "Always" then
			obj._State = true
		end
	end

	local function onKeyEnded(input)
		if mode ~= "Hold" or not obj._Holding then return end
		if not InputMatchesBind(input, obj.Value) then return end
		obj._Holding = false
		obj._State = false
		fireClick()
	end

	-- [FIX 41] THE LEAK. InputRouter:On returns a disposer and the old code
	-- threw both sets of
	-- ghost keybinds all responding to the same key.
	self.Window:Track(InputRouter:On("Began", onKeyBegan))
	self.Window:Track(InputRouter:On("Ended", onKeyEnded))

	-- Releasing a held bind when focus is lost stops it latching "on" forever.
	self.Window:Track(UserInputService.WindowFocusReleased:Connect(function()
		if obj._Holding then
			obj._Holding = false
			obj._State = false
			fireClick()
		end
	end))

	if button then
		self.Window:Track(button.MouseButton1Click:Connect(function()
			if not obj:CanInteract() then return end

			button.Text = "…"
			self.Window.PickingKey = true

			-- Deferred so the click that opened the picker is not itself captured.
			task.defer(function()
				if obj.Destroyed or not self.Window.PickingKey then return end

				InputManager:Capture({
					Began = function(input)
						local bind = InputToBindName(input)
						if not bind then return end

						if bind == "Escape" then
							set("None", false, true)
						else
							set(bind, false, true)
						end

						InputManager:Cancel()
						self.Window.PickingKey = false
						if button then button.Text = obj.Value end
					end,
				})
			end)
		end))
	end

	function obj:OnStateChanged()
		if button then
			button.TextColor3 = self:CanInteract() and Theme.Text or Theme.Dim
		end
	end

	function obj:SetValue(value, silent) set(value, silent == true, false) end
	function obj:GetValue() return obMode)
		mode = newMode or mode
		obj.Mode = mode
		obj._State = false
		obj._Holding = false
	end

	if button then attachTooltip(self.Window, button, opts.Tooltip) end
	return finishControl(self, obj, "KeyPicker", name)
end

--==============================================================
-- CONTROL: COLOR PICKER
--==============================================================

function Groupbox:AddColorPicker(name, opts)
	opts = opts or {}
	local default = (typeof(opts.Default) == "Color3") and opts.Default or Color3.fromRGB(255, 255, 255)

	local row = createControlFrame(self, 22, false, true)
	makeLabel(row, opts.Text or name or "Color", UDim2.new(1, -46, 1, 0))

	local preview = Create.create("TextButton", {
		Parent = row,
		Size = UDim2.fromOffset(40, 18),
		BackgroundColor3 = default,
		BorderSizePixel = 1,
		Text = "",
		AutoButtonColor = false,
		theme = { BorderColor3 = "Border" },
	})

	local picker = Create.create("Frame", {
		Parent = self.Window.Gui,
		Visible = false,
		Size = UDim2.fromOffset(232, 232),
		BorderSizePixel = 1,
		ZIndex = Layer.ColorPicker,
		theme = { BackgroundColor3 = "Panel", BorderColor3 = "Border" },
	})

	self.Window:AttachScale(picker)

	local hue, sat, vib = default:ToHSV()

	local satMap = Create.create("ImageButton", {
		Parent = picker,
		Position = UDim2.fromOffset(8, 8),
		Size = UDim2.fromOffset(180, 180),
		BackgroundColor3 = Color3.fromHSV(hue,  satCursor = Create.create("Frame", {
		Parent = satMap,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Size = UDim2.fromOffset(7, 7),
		Position = UDim2.fromScale(sat, 1 - vib),
		BackgroundColor3 = Color3.new(1, 1, 1),
		BorderSizePixel = 0,
		ZIndex = Layer.ColorPicker + 3,
	})
	Create.create("UICorner", { Parent = satCursor, CornerRadius = UDim.new(1, 0) })
	Create.create("UIStroke", { Parent = satCursor, Color = Color3.new(0, 0, 0), Thickness = 1 })

	local hueKeypoints = {}
	for i = 0, 10 do
		local t = i / 10
		table.insert(hueKeypoints, ColorSequenceKeypoint.new(t, Color3.fromHSV(t, 1, 1)))
	end

	local hueBar = Create.create("TextButton", {
		Parent = picker,
		Position = UDim2.fromOffset(196, 8),
		Size = UDim2.fromOffset(28, 180),
		BackgroundColor3 = Color3.new(1, 1, 1),
		BorderSizePixel = 0,
		Text = "",
		AutoButtonColor = false,
		ZIndex = Layer.ColorPicker + 1,
	})
	Create.create("UIGradient", { Parent = hueBar, Rotation = 90, Color = ColorSequence.new(hueKeypoints) })

	local hueCursor = Create.create("Frame", {
		Parent = hueBar,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Size = UDim2.new(1, 2, 0, 2),
		Position = UDim2.fromScale(0.5, hue),
		0, 0, 0), Thickness = 1 })

	local hexBox = Create.create("TextBox", {
		Parent = picker,
		Position = UDim2.fromOffset(8, 196),
		Size = UDim2.fromOffset(216, 24),
		BorderSizePixel = 1,
		Text = "#" .. default:ToHex(),
		ClearTextOnFocus = false,
		Font = Theme.Font,
		TextSize = Theme.TextSize,
		ZIndex = Layer.ColorPicker + 1,
		theme = { BackgroundColor3 = "PanelAlt", BorderColor3 = "Border", TextColor3 = "Text" },
	})

	local obj = BaseControl.new("ColorPicker", row, self.Window, name)
	obj.Value = default
	obj.Hue, obj.Sat, obj.Vib = hue, sat, vib
	obj.NoSave = opts.NoSave == true
	obj.Changed = Signal.new()
	obj:TrackPopup(picker)

	-- [FIX 42] previous is captured BEFORE the mutation. The old display() wrote
	-- obj.Value first and then read `local prev = obj.Value`, so every listener
	-- received previous == new and any consumer doing change detection saw
	-- nothing change, ever.
	local function display(silent)
		local previous = obj.Value
		obj.Value = Color3.fromHSV(obj.Hue, obj.Sat, obj.Vib)

		preview.BackgroundColor3 = obj.Value
		satMap.BackgroundColor3 = Color3.fromHSV(obj.Hue, 1, 1)
		satCursor.Position = UDim2.fromScale(obj.Sat, 1 - obj.Vib)ed:Fire(obj.Value, previous)

		if self.Window.Events and self.Window.Events.Changed then
			self.Window.Events.Changed:Fire(name or "ColorPicker", obj.Value)
		end

		if opts.Callback then
			local ok, err = xpcall(opts.Callback, traceback, obj.Value, previous)
			if not ok then Log.warn("ColorPicker callback failed:\n" .. tostring(err)) end
		end
	end

	function obj:Close()
		if picker.Visible then
			picker.Visible = false
			self.Window:UnregisterPopup(obj)
		end
	end

	local function openPicker()
		if not obj:CanInteract() then return end
		local pos = preview.AbsolutePosition
		local window = self.Window
		local viewport = getViewportSize(window.Gui)

		local x = math.min(pos.X, viewport.X - 240)
		local y = pos.Y + 22
		if y + 240 > viewport.Y then y = math.max(8, pos.Y - 236) end

		picker.Position = UDim2.fromOffset(window:ToLocal(x), window:ToLocal(y))
		picker.Visible = true
		window:RegisterPopup(obj)
		window:Focus()
	end

	self.Window:Track(preview.MouseButton1Click:Connect(function()
		if picker.Visible then obj:Close() else openPicker() end
	end))

	--[[
		[FIX 43] The old bindDrag created a fresh InputChanged AND InputEnded
		connection on every mouse-down and only released them if InputEnded fired
		with MouseButton1 — alt-tab mid-drag leaked both permanently, so the cursor drifted away
		from the pointer during a drag.
	]]
	local function bindDrag(gui, update)
		local disposers = nil

		local function stop()
			if not disposers then return end
			for _, dispose in ipairs(disposers) do dispose() end
			disposers = nil
		end

		self.Window:Track(gui.InputBegan:Connect(function(input)
			if input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
			if not obj:CanInteract() then return end
			if disposers then return end

			update(getMousePos())

			disposers = {
				InputRouter:On("Changed", function(moved)
					if moved.UserInputType == Enum.UserInputType.MouseMovement then
						update(getMousePos())
					end
				end),
				InputRouter:On("Ended", function(ended)
					if ended.UserInputType == Enum.UserInputType.MouseButton1 then stop() end
				end),
			}
		end))

		self.Window:Track(UserInputService.WindowFocusReleased:Connect(stop))
		self.Window:Track(stop)
	end

	bindDrag(satMap, function(mouse)
		local point = toGuiSpace(mouse, screenOf(satMap))
		local origin, size = satMap.AbsolutePosition, satMap.AbsoluteSize
		obj.Sat = math.clamp((point.X - origin.X) / math.max(size.X, 1), 0, 1)
		obj.Vib = 1 - math.clamp((point.Y - origin.osition, hueBar.AbsoluteSize
		obj.Hue = math.clamp((point.Y - origin.Y) / math.max(size.Y, 1), 0, 1)
		display(false)
	end)

	-- [FIX 44] Hex parsing accepts 3- and 6-digit forms and rejects anything
	-- else. Color3.fromHex throws on bad input; the old pcall caught it but then
	-- still ran the success branch because it only checked `ok and typeof`.
	self.Window:Track(hexBox.FocusLost:Connect(function()
		if not obj:CanInteract() then
			hexBox.Text = "#" .. obj.Value:ToHex()
			return
		end

		local text = hexBox.Text:gsub("#", ""):gsub("%s", "")
		if #text == 3 then
			text = text:sub(1, 1):rep(2) .. text:sub(2, 2):rep(2) .. text:sub(3, 3):rep(2)
		end

		local ok, color = pcall(Color3.fromHex, text)
		if ok and typeof(color) == "Color3" then
			obj.Hue, obj.Sat, obj.Vib = color:ToHSV()
			display(false)
		else
			hexBox.Text = "#" .. obj.Value:ToHex()
		end
	end))

	function obj:OnStateChanged()
		preview.BackgroundTransparency = self.Disabled and 0.5 or 0
	end

	function obj:SetValue(color, silent)
		if typeof(color) ~= "Color3" then return end
		obj.Hue, obj.Sat, obj.Vib = color:ToHS================
-- CONTROL: LISTBOX / TREE / TABLE
--==============================================================

function Groupbox:AddListBox(name, opts)
	opts = opts or {}
	local values = opts.Values or {}
	local multi = opts.Multi == true

	local row = createControlFrame(self, nil, true, false)
	makeLabel(row, opts.Text or name or "List")

	local scroll = Create.create("ScrollingFrame", {
		Parent = row,
		Size = UDim2.new(1, 0, 0, opts.Height or 100),
		BorderSizePixel = 1,
		ScrollBarThickness = 6,
		CanvasSize = UDim2.new(),
		theme = { BackgroundColor3 = "PanelAlt", BorderColor3 = "Border", ScrollBarImageColor3 = "Scroll" },
	})

	local layout = Create.create("UIListLayout", {
		Parent = scroll,
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, 1),
	})

	local obj = BaseControl.new("ListBox", row, self.Window, name)
	obj.Multi = multi
	obj.Values = values
	obj.NoSave = opts.NoSave == true
	obj.Changed = Signal.new()
	obj.Value = multi
		and ((type(opts.Default) == "table") and table.clone(opts.Default) or {})
		or opts.Default

	local itemMaid = Maid.new()
	self.Window.Maid:Give(itemMaid)

	local function isSelected(value)
		if multi then return table.find(obj.Value, value) ~= nil end
		return obj.Value == value
	end

	local rebuild

	local function commit(newValue, previous)
		obj.Value = newValj.Value)
		end

		if opts.Callback then
			local ok, err = xpcall(opts.Callback, traceback, obj.Value, previous)
			if not ok then Log.warn("ListBox callback failed:\n" .. tostring(err)) end
		end

		rebuild()
	end

	rebuild = function()
		itemMaid:Cleanup()

		for i, value in ipairs(values) do
			local selected = isSelected(value)

			local item = Create.create("TextButton", {
				Parent = scroll,
				LayoutOrder = i,
				Size = UDim2.new(1, 0, 0, 18),
				BackgroundTransparency = selected and 0 or 1,
				Text = (selected and (Glyphs.Check .. " ") or "   ") .. tostring(value),
				TextXAlignment = Enum.TextXAlignment.Left,
				TextTruncate = Enum.TextTruncate.AtEnd,
				Font = Theme.Font,
				TextSize = Theme.TextSize,
				AutoButtonColor = false,
				theme = { BackgroundColor3 = "Selection", TextColor3 = "Text" },
			})

			itemMaid:Give(item)
			itemMaid:Give(item.MouseButton1Click:Connect(function()
				if not obj:CanInteract() then return end

				if multi then
					local previous = table.clone(obj.Value)
					local next = table.clone(obj.Value)
					local index = table.find(next, value)
					if index then table.remove(next, index) else table.insert(next, value) end
					commit(next, previous)
				else
					commit(value, obj.Value)
				end
			end))
		end

		scroll.CanvasSize = UDim2.fromOffset(0, self.Window:ToLocal(layout.AbsoluteContentSize.Y) + 4)
	end

	function obj:SetValues(newValues)j.Value ~= nil and not table.find(values, obj.Value) then
			obj.Value = nil
		end

		rebuild()
	end

	-- [FIX 45] Type-checked. The old SetValue accepted anything and then
	-- rebuild() called table.find on it, so SetValue("x") on a multi list threw
	-- from inside the render pass.
	function obj:SetValue(value, silent)
		if multi then
			if type(value) ~= "table" then return end
			obj.Value = table.clone(value)
		else
			obj.Value = value
		end

		rebuild()
		if not silent then obj.Changed:Fire(obj:GetValue()) end
	end

	function obj:GetValue() return multi and table.clone(obj.Value) or obj.Value end

	rebuild()
	return finishControl(self, obj, "ListBox", name)
end

function Groupbox:AddTree(name, opts)
	opts = opts or {}
	local nodes = opts.Nodes or {}

	local row = createControlFrame(self, nil, true, false)
	makeLabel(row, opts.Text or name or "Tree")

	local scroll = Create.create("ScrollingFrame", {
		Parent = row,
		Size = UDim2.new(1, 0, 0, opts.Height or 140),
		BorderSizePixel = 1,
		ScrollBarThickness = 6,
		CanvasSize = UDim2.new(),
		theme = { BackgroundColor3 = "PanelAlt", BorderColor3 = "Border", ScrollBarImageColor3 = "Scroll" },
	})

	local layout = Create.create("UIListLayout", {
		Parent = scroll,
		SortOrder = Enum.SortOrder.LayoutOrder, tables are not JSON-safe identities
	obj.Changed = Signal.new()

	local expanded = {}
	local itemMaid = Maid.new()
	self.Window.Maid:Give(itemMaid)

	local rebuildAll

	-- [FIX 46] One render path. The old version inlined "destroy every
	-- TextButton, call rebuild, recompute CanvasSize" three separate times with
	-- slightly different arguments, and passed a fresh {n=0} counter on one of
	-- them so LayoutOrder collided with the still-mounted rows.
	local function renderLevel(list, depth, counter)
		for _, node in ipairs(list or {}) do
			counter.n += 1

			local hasChildren = type(node.Children) == "table" and #node.Children > 0
			local isExpanded = expanded[node] == true
			local marker = hasChildren and (isExpanded and Glyphs.ArrowDown or Glyphs.ArrowRight) or " "

			local item = Create.create("TextButton", {
				Parent = scroll,
				LayoutOrder = counter.n,
				Size = UDim2.new(1, 0, 0, 18),
				BackgroundTransparency = (obj.Value == node) and 0 or 1,
				Text = string.rep("   ", depth) .. marker .. " " .. tostring(node.Text or node.Name or "?"),
				TextXAlignment = Enum.TextXAlignment.Left,
				TextTruncate = Enum.TextTruncate.AtEnd,
				Font = Theme.Font,
				TextSize =(function()
				if not obj:CanInteract() then return end

				if hasChildren then
					expanded[node] = not isExpanded
				else
					local previous = obj.Value
					obj.Value = node
					obj.Changed:Fire(node, previous)
					if opts.Callback then
						local ok, err = xpcall(opts.Callback, traceback, node, previous)
						if not ok then Log.warn("Tree callback failed:\n" .. tostring(err)) end
					end
				end

				rebuildAll()
			end))

			if hasChildren and isExpanded then
				renderLevel(node.Children, depth + 1, counter)
			end
		end
	end

	rebuildAll = function()
		itemMaid:Cleanup()
		renderLevel(nodes, 0, { n = 0 })
		scroll.CanvasSize = UDim2.fromOffset(0, self.Window:ToLocal(layout.AbsoluteContentSize.Y) + 4)
	end

	function obj:SetNodes(newNodes)
		nodes = newNodes or {}
		obj.Nodes = nodes
		table.clear(expanded)
		obj.Value = nil
		rebuildAll()
	end

	function obj:AddNode(text, parentNode)
		local node = { Text = text, Children = {} }
		if parentNode and type(parentNode.Children) == "table" then
			table.insert(parentNode.Children, node)
			expanded[parentNode] = true
		else
			table.insert(nodes, node)
		end
		rebuildAll()
		return node
	end

	function obj:Expand(node, value)
		expanded[node] = value All()
	return finishControl(self, obj, "Tree", name)
end

function Groupbox:AddTable(name, opts)
	opts = opts or {}
	local columns = opts.Columns or { "Col1", "Col2" }
	local rows = opts.Rows or {}

	local container = createControlFrame(self, nil, true, false)
	makeLabel(container, opts.Text or name or "Table")

	local header = Create.create("Frame", {
		Parent = container,
		Size = UDim2.new(1, 0, 0, 18),
		BorderSizePixel = 0,
		theme = { BackgroundColor3 = "PanelAlt" },
	})

	local columnWidth = 1 / math.max(#columns, 1)

	for i, column in ipairs(columns) do
		Create.create("TextLabel", {
			Parent = header,
			Size = UDim2.new(columnWidth, 0, 1, 0),
			Position = UDim2.new(columnWidth * (i - 1), 0, 0, 0),
			BackgroundTransparency = 1,
			Text = " " .. tostring(column),
			TextXAlignment = Enum.TextXAlignment.Left,
			TextTruncate = Enum.TextTruncate.AtEnd,
			Font = Theme.Font,
			TextSize = 12,
			theme = { TextColor3 = "Warning" },
		})
	end

	local scroll = Create.create("ScrollingFrame", {
		Parent = container,
		Size = UDim2.new(1, 0, 0, opts.Height or 120),
		BorderSizePixel = 1,
		ScrollBarThickness = 6,
		CanvasSize = UDim2.new(),
		theme = { BackgroundColor3 = "Background", BorderColor3 = "Border", ScrollBarImageColor3 = "Scroll" },
	})

	local layout = Create.create("UIListLayout", {
		Parent = scrolled = Signal.new()

	local itemMaid = Maid.new()
	self.Window.Maid:Give(itemMaid)

	-- [FIX 47] Rows are tracked by a Maid instead of swept with IsA("Frame"),
	-- which would have destroyed any nested container the moment one was added.
	local function rebuild()
		itemMaid:Cleanup()

		for rowIndex, rowData in ipairs(rows) do
			local rowFrame = Create.create("Frame", {
				Parent = scroll,
				Size = UDim2.new(1, 0, 0, 18),
				BackgroundTransparency = (rowIndex % 2 == 0) and 0.94 or 1,
				BackgroundColor3 = Theme.PanelAlt,
				LayoutOrder = rowIndex,
			})

			itemMaid:Give(rowFrame)

			for columnIndex, column in ipairs(columns) do
				local cell = rowData[column] or rowData[columnIndex] or ""
				Create.create("TextLabel", {
					Parent = rowFrame,
					Size = UDim2.new(columnWidth, 0, 1, 0),
					Position = UDim2.new(columnWidth * (columnIndex - 1), 0, 0, 0),
					BackgroundTransparency = 1,
					Text = " " .. tostring(cell),
					TextXAlignment = Enum.TextXAlignment.Left,
					TextTruncate = Enum.TextTruncate.AtEnd,
					Font = Theme.Font,
					TextSize = 12,
					theme = { TextColor3 = "Text" },
				})
			end
		end

		scroll.CanvasSize = UDim2.fromOffset(0, self.Window:ToLocows, rowData)
		rebuild()
	end

	function obj:ClearRows()
		rows = {}
		obj.Rows = rows
		rebuild()
	end

	function obj:GetRows() return obj.Rows end
	function obj:GetValue() return obj.Rows end

	rebuild()
	return finishControl(self, obj, "Table", name)
end

--==============================================================
-- CONTROL: DEPENDENCY BOX
--==============================================================

function Groupbox:AddDependencyBox()
	local holder = Create.create("Frame", {
		Parent = self.Content,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		LayoutOrder = self.NextOrder,
	})

	self.NextOrder += 1

	Create.create("UIListLayout", {
		Parent = holder,
		Padding = UDim.new(0, 4),
		SortOrder = Enum.SortOrder.LayoutOrder,
	})

	-- A real Groupbox whose Content is the holder, so every Add* method works
	-- and controls land in a Controls list that Destroy can actually clean up.
	local box = setmetatable({
		Window = self.Window,
		Tab = self.Tab,
		Title = self.Title,
		Frame = holder,
		Content = holder,
		Controls = {},
		NextOrder = 0,
		Parent = self,
		Visible = true,
	}, Groupbox)

	-- [FIX 48] Dependency list dependency for the lifetime of the window.
	function box:SetupDependencies(deps)
		local connections = {}

		local function evaluate()
			local show = true

			if type(deps) == "table" then
				for control, required in pairs(deps) do
					if type(control) == "table" and control.GetValue then
						local value = control:GetValue()
						local pass

						if type(required) == "function" then
							local ok, result = pcall(required, value)
							pass = ok and result == true
						else
							pass = value == required
						end

						if not pass then
							show = false
							break
						end
					end
				end
			end

			holder.Visible = show
			box.Visible = show

			if not show then
				for _, control in ipairs(box.Controls) do
					if control.ClosePopups then control:ClosePopups() end
				end
			end
		end

		if type(deps) == "table" then
			for control in pairs(deps) do
				if type(control) == "table" and control.Changed and control.Changed.Connect then
					local connection = control.Changed:Connect(evaluate)
					table.insert(connections, connection)
					self.Window:Track(connection)
				end
			end
		end

		box._DependencyConnections = connections
		evaluate()
		return box
	end

	table.insert(self.Controls, box)
	return box
end

--==============================================================
-- TAB CONVENIENCE FORWARDS
--==============================================================

for _, method in ipairs({
	"AddLabel", "AddButton", "AddToggle", "AddSlider", "AddDropdown", "AddInput",
	"AddKeyPicker", "AddDivider", "AddColorPicker", "AddNumericInput",
	"AddListBox", "AddTree", "AddTable", "AddDependenc64UI:RegisterCommand(name, options)
	assert(type(name) == "string" and name ~= "", "Command name must be a non-empty string")
	assert(type(options) == "table", "Command options must be a table")
	assert(type(options.Callback) == "function", "Command callback is required")

	local command = {
		Name = name,
		Description = options.Description or "",
		Keywords = options.Keywords or {},
		Callback = options.Callback,
	}

	self.Commands[name] = command
	if not table.find(self.CommandOrder, name) then
		table.insert(self.CommandOrder, name)
	end

	return command
end

function X64UI:UnregisterCommand(name)
	self.Commands[name] = nil
	local index = table.find(self.CommandOrder, name)
	if index then table.remove(self.CommandOrder, index) end
end

function X64UI:ExecuteCommand(name, ...)
	local command = self.Commands[name]
	if not command then
		Log.warn("Unknown command: " .. tostring(name))
		return false, "Unknown command: " .. tostring(name)
	end

	local args = table.pack(...)
	local ok, result = xpcall(function()
		return command.Callback(unpack(args, 1, args.n))
	end, traceback)

	if not ok then
		Log.warn("Command failed:\n" .. tostring(result))
		return false, result
	end

	return true, result
end

--[[
	[FIX 49] The command palette shipped completely empty. CommandOrder was never
	populated by anything in the library, so opening it with Ctrl+P — the feature
	advertised in its own placeholder text — always showed a blank list. These
	defaults operate on X64UI.erDefaultCommands()
	if defaultCommandsRegistered then return end
	defaultCommandsRegistered = true

	local function active()
		local window = X64UI.ActiveWindow
		if window and not window.Destroyed then return window end
		return nil
	end

	local commands = {
		{ "Toggle Console",     "Show or hide the log pane",       { "log", "output" },        function(w) w:ToggleConsole() end },
		{ "Toggle Status Bar",  "Show or hide the status bar",     { "footer" },               function(w) w:ToggleStatusBar() end },
		{ "Clear Log",          "Empty the console",               { "log", "clean" },         function(w) w:ClearLog() end },
		{ "Undo",               "Undo the last change",            { "history", "revert" },    function(w) w.History:UndoLast() end },
		{ "Redo",               "Redo the last undone change",     { "history" },              function(w) w.History:RedoLast() end },
		{ "Save Config",        "Write the default config file",   { "persist", "write" },     function(w) w:SaveConfig() end },
		{ "Load Config",        "Read the default config file",    { "persist", "read" },      function(w) w:LoadConfig() end },
		{ "Maximize Window",    "Fill the viewport",               { "fullscreen", "resize" }, function(w) w:SetMaximized(not wset Window",       "Restore the default size",        { "layout", "center" },     function(w)
			w:SetMaximized(false)
			w:SetMinimized(false)
			w.Main.Size = UDim2.fromOffset(w:ToLocal(1020), w:ToLocal(660))
			w:UpdateLayout()
			w:ClampToViewport()
		end },
		{ "Scale Up",           "Increase UI scale by 10%",        { "zoom", "dpi" },          function(w) w:SetScale(w:GetScale() + 0.1) end },
		{ "Scale Down",         "Decrease UI scale by 10%",        { "zoom", "dpi" },          function(w) w:SetScale(w:GetScale() - 0.1) end },
		{ "Report Capabilities","Log executor feature detection",  { "debug", "caps" },        function(w) X64UI:ReportCapabilities(w) end },
		{ "Unload X64UI",       "Destroy every window and detach", { "exit", "quit" },         function() X64UI:Unload() end },
	}

	for _, entry in ipairs(commands) do
		local label, description, keywords, run = entry[1], entry[2], entry[3], entry[4]
		X64UI:RegisterCommand(label, {
			Description = description,
			Keywords = keywords,
			Callback = function()
				local window = active()
				if not window then
					Log.warn("Command '" .. label .. "' needs an active window")
					return
				end
				run(window)
			end,
		})
	end
endardcoded "Close" button. It rendered no title, no message, ran no callback,
	could not be dismissed with Escape, was never tracked by any Maid, and
	returned nothing — so a caller had no handle to close it.
]]
function X64UI:Dialog(opts)
	opts = opts or {}

	local gui = Create.create("ScreenGui", {
		Name = "X64Dialog",
		ResetOnSpawn = false,
		IgnoreGuiInset = true,
		DisplayOrder = Layer.Modal + 100,
		Parent = getParent(),
	})

local buttons = opts.Buttons or { { Text = "Close" } }

	local maid = Maid.new()
	maid:Give(gui)

	local closed = false
	local releaseCapture

	local function close(result)
		if closed then return end
		closed = true

		if releaseCapture then
			releaseCapture()
			releaseCapture = nil
		end

		if opts.OnClose then
			local ok, err = xpcall(opts.OnClose, traceback, result)
			if not ok then Log.warn("Dialog OnClose failed:\n" .. tostring(err)) end
		end

		maid:Destroy()
	end

	-- Scrim. Clicking it dismisses only when the dialog is not modal.
	local scrim = Create.create("TextButton", {
		Parent = gui,
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.new(0, 0, 0),
		BackgroundTransparency = 0.45,
		BorderSizePixel = 0,
		Text = "",
		AutoButtonColor = false,
		ZIndex = Layer.Modal + 100,
	})

	local width = math.clamp(tonumber(opts.Width) or 420, 260, 720)

	local frame = Create.create("Frame", {
		Parent = gui,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.ackgroundColor3 = "Panel", BorderColor3 = "Border" },
	})

	Create.create("UIListLayout", {
		Parent = frame,
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, 0),
	})

	-- Title bar
	Create.create("TextLabel", {
		Parent = frame,
		LayoutOrder = 0,
		Size = UDim2.new(1, 0, 0, Chrome.Title),
		BorderSizePixel = 0,
		Text = " " .. tostring(opts.Title or "X64UI"),
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Font = Theme.Font,
		TextSize = Theme.TextSize,
		ZIndex = Layer.Modal + 102,
		theme = { BackgroundColor3 = "TitleBar", TextColor3 = "AccentText" },
	})

	-- Body
	local body = Create.create("TextLabel", {
		Parent = frame,
		LayoutOrder = 1,
		Size = UDim2.new(1, -24, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		Text = tostring(opts.Description or opts.Text or ""),
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.Text = body,
		PaddingTop = UDim.new(0, 12),
		PaddingBottom = UDim.new(0, 12),
		PaddingLeft = UDim.new(0, 12),
	})

	-- Button strip
	local strip = Create.create("Frame", {
		Parent = frame,
		LayoutOrder = 2,
		Size = UDim2.new(1, 0, 0, 44),
		BackgroundTransparency = 1,
		ZIndex = Layer.Modal + 102,
	})

	Create.create("UIListLayout", {
		Parent = strip,
		FillDirection = Enum.FillDirection.Horizontal,
		HorizontalAlignment = Enum.HorizontalAlignment.Right,
		VerticalAlignment = Enum.VerticalAlignment.Center,
		Padding = UDim.new(0, 6),
		SortOrder = Enum.SortOrder.LayoutOrder,
	})

	Create.create("UIPadding", {
		Parent = strip,
		PaddingRight = UDim.new(0, 12),
	})

	local defaultButton, cancelButton

	for index, spec in ipairs(buttons) do
		local button = Create.create("TextButton", {
			Parent = strip,
			LayoutOrder = index,
			Size = UDim2.fromOffset(math.max(84, (#tostring(spec.Text or "OK") * 8) + 24), 26),
			BorderSizePixel = 1,
			Text = tostring(spec.Text or "OK"),
			Font = Theme.Font,
			TextSize = Theme.TextSize,
			AutoButtonColor = false,
			ZIndex = Layer.Modal + 103,
			theme = {

		maid:Give(button.MouseEnter:Connect(function()
			button.BackgroundColor3 = spec.Primary and Theme.AccentText or Theme.ButtonHover
		end))
		maid:Give(button.MouseLeave:Connect(function()
			button.BackgroundColor3 = base
		end))

		maid:Give(button.MouseButton1Click:Connect(function()
			-- Run the callback BEFORE teardown so a handler can still read state,
			-- and close even if it throws.
			if spec.Callback then
				local ok, err = xpcall(spec.Callback, traceback)
				if not ok then Log.warn("Dialog button callback failed:\n" .. tostring(err)) end
			end
			close(spec.Id or spec.Text or index)
		end))

		if spec.Primary or spec.Default then defaultButton = spec end
		if spec.Cancel then cancelButton = spec end
	end

	-- Fall back to sensible keyboard targets when none are declared.
	defaultButton = defaultButton or buttons[#buttons]
	cancelButton = cancelButton or buttons[1]

	--[[
		[FIX 50b] Keyboard handling through a router capture, so Escape andclicking its single button.
	]]
	releaseCapture = InputRouter:PushCapture({
		Began = function(input)
			if input.UserInputType ~= Enum.UserInputType.Keyboard then return end
			local key = input.KeyCode

			if key == Enum.KeyCode.Escape then
				if cancelButton and cancelButton.Callback then
					pcall(cancelButton.Callback)
				end
				close("Escape")
			elseif key == Enum.KeyCode.Return or key == Enum.KeyCode.KeypadEnter then
				if defaultButton and defaultButton.Callback then
					pcall(defaultButton.Callback)
				end
				close(defaultButton and (defaultButton.Id or defaultButton.Text) or "Return")
			end
		end,
	})

	maid:Give(function()
		if releaseCapture then
			releaseCapture()
			releaseCapture = nil
		end
	end)

	if not opts.Modal then
		maid:Give(scrim.MouseButton1Click:Connect(function()
			close("Dismissed")
		end))
	end

	-- Fade in.
	frame.BackgroundTransparency = 1
	TweenService:Create(
		scrim,
		TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ BackgroundTransparency = 0.45 }
	):Play()

	-- Returns a handle. [FIX 50c] The old Dialog returned nil, so callers had no
	-- way to dismiss it programmatically.
	return {
		Gui = gui,
		Frame = frame,
		Close = function(_, result) close(result or "Closed") end,
		IsOts = opts or {}

	-- [FIX 51] Toasts always live in their own ScreenGui. The old code parented
	-- them into ActiveWindow.Gui, so hiding the window with the menu keybind hid
	-- every toast, and destroying the window destroyed toasts mid-animation
	-- while their delayed tween thread was still running.
	if not self.NotifyGui or not self.NotifyGui.Parent then
		self.NotifyGui = Create.create("ScreenGui", {
			Name = "X64Notify",
			ResetOnSpawn = false,
			IgnoreGuiInset = true,
			DisplayOrder = Layer.Toast,
			Parent = getParent(),
		})
	end

	local parent = self.NotifyGui
	local container = parent:FindFirstChild("X64Notifications")

	if not container then
		container = Create.create("Frame", {
			Parent = parent,
			Name = "X64Notifications",
			AnchorPoint = Vector2.new(1, 1),
			Position = UDim2.new(1, -12, 1, -12),
			Size = UDim2.fromOffset(300, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundTransparency = 1,
			ZIndex = Layer.Toast,
		})

		Create.create("UIListLayout", {
			Parent = container,
			Padding = UDim.new(0, 8),
			SortOrder = Enum.SortOrder.LayoutOrder,
			HorizontalAlignment = Enum.HorizontalAlignment.Right,
			VerticalAlignment = Enum.VerticalAlignment.Bottom,
		})
	end

	--local child = container:GetChildren()[2]

		It counted the UIListLayout as a toast, so the real cap was 5, and it
		assumed index 2 was the oldest toast — correct only by accident, and
		wrong the moment anything else is parented there. Now it filters by class
		and evicts by LayoutOrder.
	]]
	local live = {}
	for _, child in ipairs(container:GetChildren()) do
		if child:IsA("CanvasGroup") then
			table.insert(live, child)
		end
	end

	table.sort(live, function(a, b) return a.LayoutOrder < b.LayoutOrder end)

	while #live > 5 do
		local oldest = table.remove(live, 1)
		if oldest then oldest:Destroy() end
	end

	-- [FIX 53] A monotonic counter instead of math.floor(os.clock() * 1000).
	-- The old ordering collided for toasts raised in the same millisecond and
	-- drifted as uptime grew.
	notifySequence += 1

	local accent = SEVERITY_COLORS[opts.Severity or "accent"] or SEVERITY_COLORS.accent

	local toastMaid = Maid.new()

	local toast = Create.create("CanvasGroup", {
		Parent = container,
		Size = UDim2.new(1, 0, 0, 0),
		Aor3 = "Panel", BorderColor3 = "Border" },
	})

	toastMaid:Give(toast)

	Create.create("UIListLayout", {
		Parent = toast,
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, 2),
	})

	Create.create("UIPadding", {
		Parent = toast,
		PaddingTop = UDim.new(0, 6),
		PaddingBottom = UDim.new(0, 8),
		PaddingLeft = UDim.new(0, 10),
		PaddingRight = UDim.new(0, 10),
	})

	Create.create("TextLabel", {
		Parent = toast,
		LayoutOrder = 0,
		Size = UDim2.new(1, 0, 0, 18),
		BackgroundTransparency = 1,
		Text = tostring(opts.Title or "Notification"),
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		TextColor3 = Color3.fromHex(accent),
		Font = Theme.Font,
		TextSize = Theme.TextSize,
		ZIndex = Layer.Toast + 2,
	})

	local description = tostring(opts.Description or "")

	if description ~= "" then
		-- [FIX 54] AutomaticSize instead of a fixed 28px box, so long messages
		-- are no longer clipped to two lines with the remainder invisible.
		Create.create("TextLabel", {
			Parent = toast,
			LayoutOrder = 1,
			Size = UDim2.new(1, 0, 0, 0),
			AutomaticSize = Enum.Automa Theme.Font,
			TextSize = Theme.TextSize,
			ZIndex = Layer.Toast + 2,
			theme = { TextColor3 = "Text" },
		})
	end

	TweenService:Create(
		toast,
		TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ GroupTransparency = 0 }
	):Play()

	local dismissed = false

	local function dismiss()
		if dismissed then return end
		dismissed = true

		if not toast.Parent then
			toastMaid:Destroy()
			return
		end

		local tween = TweenService:Create(
			toast,
			TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
			{ GroupTransparency = 1 }
		)

		tween:Play()
		tween.Completed:Connect(function()
			toastMaid:Destroy()
		end)
	end

	-- Click to dismiss early.
	local hit = Create.create("TextButton", {
		Parent = toast,
		Size = UDim2.fromScale(1, 1),
		Position = UDim2.fromScale(0, 0),
		BackgroundTransparency = 1,
		Text = "",
		AutoButtonColor = false,
		ZIndex = Layer.Toast + 3,
	})

	toastMaid:Give(hit.MouseButton1Click:Connect(dismiss))

	-- [FIX 55] The delayed thread is owned by the Maid, so destroying the toast
	-- cancels it. The old code handed task.delay's thread to the Maid AFTER the
	-- closure had already captured a to.5, tonumber(opts.Time) or 3), dismiss))

	return { Dismiss = dismiss }
end

--==============================================================
-- WATERMARK
--==============================================================

function X64UI:SetWatermark(text)
	if not self._WatermarkGui or not self._WatermarkGui.Parent then
		self._WatermarkGui = Create.create("ScreenGui", {
			Name = "X64Watermark",
			ResetOnSpawn = false,
			IgnoreGuiInset = true,
			DisplayOrder = Layer.Toast - 100,
			Parent = getParent(),
		})

		self._WatermarkLabel = Create.create("TextLabel", {
			Parent = self._WatermarkGui,
			Position = UDim2.fromOffset(12, 12),
			Size = UDim2.fromOffset(0, 0),
			AutomaticSize = Enum.AutomaticSize.XY,
			BorderSizePixel = 1,
			Text = "",
			TextXAlignment = Enum.TextXAlignment.Left,
			Font = Theme.Font,
			TextSize = Theme.TextSize,
			theme = { BackgroundColor3 = "Panel", BorderColor3 = "Border", TextColor3 = "Text" },
		})

		Create.create("UIPadding", {
			Parent = self._WatermarkLabel,
			PaddingLeft = UDim.new(0, 6),
			PaddingRight = UDim.new(0, 6),
			PaddingTop = UDim.new(0, 3),
			PaddingBottom = UDim.new(0, 3),
		})
	end

	if text == nil or text == false or text == "" then
		self._WatermarkGui.Enabled = false
	else
		self._WatermarkGui.Enabled = true
		self._WatermarkLabel.Text = tostring(text)
	end
endindListConnection then
			self._KeybindListConnection:Disconnect()
			self._KeybindListConnection = nil
		end
		return
	end

	if not self._KeybindListGui or not self._KeybindListGui.Parent then
		self._KeybindListGui = Create.create("ScreenGui", {
			Name = "X64KeybindList",
			ResetOnSpawn = false,
			IgnoreGuiInset = true,
			DisplayOrder = Layer.Toast - 50,
			Parent = getParent(),
		})

		self._KeybindListFrame = Create.create("Frame", {
			Parent = self._KeybindListGui,
			AnchorPoint = Vector2.new(1, 0),
			Position = UDim2.new(1, -12, 0, 12),
			Size = UDim2.fromOffset(220, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			BorderSizePixel = 1,
			theme = { BackgroundColor3 = "Panel", BorderColor3 = "Border" },
		})

		Create.create("UIListLayout", {
			Parent = self._KeybindListFrame,
			Padding = UDim.new(0, 2),
			SortOrder = Enum.SortOrder.LayoutOrder,
		})

		Create.create("TextLabel", {
			Parent = self._KeybindListFrame,
			LayoutOrder = 0,
			Size = UDim2.new(1, 0, 0, 18),
			BorderSizePixel = 0,
			Text = " keybinds ",
			TextXAlignment = Enum.TextXAlignment.Left,
			Font = Theme.Font,
			TextSize = Theme.TextSize,
			theme = { BackgroundColor3 = "TitleBar", TextColor3 = "AccentText" },
		})

		self._KeybindRows = {}
	end

	self._KeybindListran when you called it manually — so the
		"[ON]" state indicator it rendered was frozen at whatever it was when you
		last called the function. It also pruned with `child.LayoutOrder > 0`
		while creating the header at the default LayoutOrder of 0, meaning a
		second call to the function deleted the header on some orderings.

		Rows are now cached by name and their text is refreshed in place on a
		throttled heartbeat.
	]]
	local rows = self._KeybindRows

	local function refresh()
		local seen = {}
		local order = 1

		for _, window in ipairs(self.Windows) do
			if window.Registry and window.Registry.Options then
				for name, option in pairs(window.Registry.Options) do
					if option.Type == "KeyPicker" and option.Value and option.Value ~= "None" then
						seen[name] = true

						local state = ""
						if option.GetState and option:GetState() then state = "  [ON]" end

						local row = rows[name]
						if not row or not row.Parent then
							row = Create.create("TextLabel", {
								Parent = self._KeybindListFrame,
								Size = UDim2.new(1, -8, 0, 16),
								BackgroundTransparency = 1,
								TextXAlignment = Enum.TextXAlignment.Left,
								TextTruncate = Enum.TextTruncate.AtEs%s", name, tostring(option.Value), state)
						row.TextColor3 = (state ~= "") and Theme.Good or Theme.Text
						order += 1
					end
				end
			end
		end

		for name, row in pairs(rows) do
			if not seen[name] then
				if row and row.Parent then row:Destroy() end
				rows[name] = nil
			end
		end
	end

	refresh()

	if not self._KeybindListConnection then
		local accumulator = 0
		self._KeybindListConnection = RunService.RenderStepped:Connect(function(delta)
			accumulator += delta
			if accumulator < 0.1 then return end
			accumulator = 0
			if self._KeybindListGui and self._KeybindListGui.Enabled then refresh() end
		end)
	end
end

--==============================================================
-- CAPABILITIES
--==============================================================

function X64UI:GetCapabilities()
	return {
		writefile     = Platform.CanWrite == true,
		readfile      = Platform.CanRead == true,
		delfile       = Platform.CanDelete == true,
		gethui        = type(gethui) == "function",
		request       = type(request) == "function",
		getgenv       = type(getgenv) == "function",
		hookfunction  = type(hookfunction) == "function",
		Drawing       = type(Drawing) == "table",
	}
end

function X64UI:ReportCapabilities(window)
	local capabilities = self:GetCapabilities()
	local parts = {}

	for key, value in pairs(capabilities) do
		parts[#parts + 1] = key .. "=" .. (value and "yes" or "no")
	end

	table.sort(parts)
	local message = "caps: " .. table.concat(parts, " ")

	if window and window.Log then
		window:IX 11b] Reconnect the router here rather than at chunk scope, so a second
	-- CreateWindow after an Unload works instead of silently losing all input.
	InputRouter:Connect()
	self.Unloaded = false
	registerDefaultCommands()

	if options.SingleInstance ~= false and self.ActiveWindow and not self.ActiveWindow.Destroyed then
		self.ActiveWindow:Destroy()
	end

	local win = setmetatable({}, Window)

	win.Maid = Maid.new()
	win.Registry = Registry.new()
	win.History = History.new(options.HistoryLimit or 150)

	win.Events = {
		Changed           = Signal.new(),
		Focused           = Signal.new(),
		VisibilityChanged = Signal.new(),
		Destroying        = Signal.new(),
	}

	for _, event in pairs(win.Events) do
		win.Maid:Give(event)
	end

	win.State = {
		Visible   = State.new(true),
		Minimized = State.new(false),
		Maximized = State.new(false),
		ActiveTab = State.new(nil),
	}

	for _, state in pairs(win.State) do
		win.Maid:Give(state)
	end

	win.Tabs          = {}
	win.TabOrder      = {}
	win.Dropdowns     = {}
	win.Popups        = {}
	win.Lines         = {}
	win._PopupScales  = {}

	win.Title          = options.Title or "x64dbg UI"
	win.ConsoleVisible = options.Console ~= false
	win.StatusVisible  ", {
		Name = options.Name or "X64UI",
		ResetOnSpawn = false,
		IgnoreGuiInset = true,
		DisplayOrder = options.DisplayOrder or 10000,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		Parent = getParent(),
	})

	win.Maid:Give(win.Gui)

	local viewport = getViewportSize(win.Gui)
	local width = options.Width or 1020
	local height = options.Height or 660

	win.Main = Create.create("Frame", {
		Parent = win.Gui,
		Name = "MainWindow",
		AnchorPoint = Vector2.zero,
		Size = UDim2.fromOffset(width, height),
		BorderSizePixel = 1,
		theme = { BackgroundColor3 = "Background", BorderColor3 = "Border" },
	})

	-- Scale is established before positioning, because position clamping depends
	-- on the scaled size.
	local defaultScale = 1
	if viewport.Y >= 1440 then
		defaultScale = 1.15
	elseif viewport.Y < 900 then
		defaultScale = 0.9
	end

	win.Scale = math.clamp(tonumber(options.Scale) or defaultScale, 0.5, 2)
	win.UIScale = Create.create("UIScale", { Parent = win.Main, Scale = win.Scale })

	-- [FIX 19f] Centre using the SCALED footprint. The old code centred using
	-- raw width/height while the window rendered 15 height * win.Scale

	win.Main.Position = UDim2.fromOffset(
		math.clamp((viewport.X - scaledWidth) / 2, 8, math.max(8, viewport.X - scaledWidth - 8)),
		math.clamp((viewport.Y - scaledHeight) / 2, 8, math.max(8, viewport.Y - scaledHeight - 8))
	)

	--============================ TITLE BAR ============================

	win.TitleBar = Create.create("Frame", {
		Parent = win.Main,
		Size = UDim2.new(1, 0, 0, Chrome.Title),
		BorderSizePixel = 0,
		ZIndex = Layer.Chrome,
		theme = { BackgroundColor3 = "TitleBar" },
	})

	win.TitleLabel = Create.create("TextLabel", {
		Parent = win.TitleBar,
		Position = UDim2.fromOffset(8, 0),
		Size = UDim2.new(1, -100, 1, 0),
		BackgroundTransparency = 1,
		Text = win.Title,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Font = Theme.Font,
		TextSize = Theme.TextSize,
		ZIndex = Layer.Chrome + 1,
		theme = { TextColor3 = "Text" },
	})

	local function titleButton(offset, glyph, hoverColor, callback)
		local button = Create.create("TextButton", {
			Parent = win.TitleBar,
			Position = UDim2.new(1, offset, 0, 2),
			Size = UDim2.fromOffset(28, 20),
			BorderSizePixel = 0,
			
		})

		win:Track(button.MouseEnter:Connect(function()
			button.BackgroundColor3 = hoverColor()
		end))
		win:Track(button.MouseLeave:Connect(function()
			button.BackgroundColor3 = Theme.TitleBar
		end))
		win:Track(button.MouseButton1Click:Connect(callback))

		return button
	end

	win.MinButton = titleButton(-60, Glyphs.Minimize, function() return Theme.PanelAlt end, function()
		win:SetMinimized(not win.Minimized)
	end)

	win.CloseButton = titleButton(-30, Glyphs.Close, function() return Theme.Bad end, function()
		win:Destroy()
	end)

	-- Double-click the title to maximize.
	local lastTitleClick = 0

	win:Track(win.TitleBar.InputBegan:Connect(function(input)
		if input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
		if mouseOverGui(win.MinButton) or mouseOverGui(win.CloseButton) then return end

		local now = os.clock()
		if now - lastTitleClick <= 0.28 then
			win:SetMaximized(not win.Maximized)
			lastTitleClick = 0
			if win._CancelDrag then win._CancelDrag() end
		else
			lastTitleClick = now
		end
	end))

	--============================ MENU BAR ============================

	win.MenuBar = Create.create("Frame", {
		Parent = win.Main,
		Position = UDim2.fromOffset(0, Chrome.Title),
		Size = UDim2.new(1, 0, 0, Chrome.Menu),
		BorderSizePixel = 0,
		Zding = UDim.new(0, 2),
		VerticalAlignment = Enum.VerticalAlignment.Center,
		SortOrder = Enum.SortOrder.LayoutOrder,
	})

	win.MenuDropdown = Create.create("Frame", {
		Parent = win.Gui,
		Visible = false,
		BorderSizePixel = 1,
		ZIndex = Layer.Menu,
		theme = { BackgroundColor3 = "Panel", BorderColor3 = "Border" },
	})

	win:AttachScale(win.MenuDropdown)

	Create.create("UIListLayout", {
		Parent = win.MenuDropdown,
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, 1),
	})

	Create.create("UIPadding", {
		Parent = win.MenuDropdown,
		PaddingTop = UDim.new(0, 2),
		PaddingBottom = UDim.new(0, 2),
	})

	local openMenuName = nil
	local menuMaid = Maid.new()
	win.Maid:Give(menuMaid)

	local menus = {
		File = {
			{ Text = "Save Config",   Callback = function() win:SaveConfig() end },
			{ Text = "Load Config",   Callback = function() win:LoadConfig() end },
			{ Text = "Unload",        Callback = function() X64UI:Unload() end },
			{ Text = "Close Window",  Callback = function() win:Destroy() end },
		},
		View = {
			{ Text = "Toggle Console",ette() end },
			{ Text = "Scale Up",          Callback = function() win:SetScale(win:GetScale() + 0.1) end },
			{ Text = "Scale Down",        Callback = function() win:SetScale(win:GetScale() - 0.1) end },
		},
		Options = {
			{ Text = "Save Profile: default", Callback = function() win:SaveProfile("default") end },
			{ Text = "Load Profile: default", Callback = function() win:LoadProfile("default") end },
			{ Text = "Reset Layout", Callback = function()
				win:SetMaximized(false)
				win:SetMinimized(false)
				win.Main.Size = UDim2.fromOffset(1020, 660)
				win:UpdateLayout()
				win:ClampToViewport()
			end },
		},
		Help = {
			{ Text = "Capabilities", Callback = function() X64UI:ReportCapabilities(win) end },
			{ Text = "About", Callback = function()
				X64UI:Dialog({
					Title = "X64UI",
					Description = ("x64dbg-inspired UI library\nVersion %s\n\nPress Ctrl+P for the command palette."):format(VERSION),
					Buttons = { { Text = "Close", Primary = true } },
				})
			end },
		},
	}

	local menuButtons = {}

	local function closeMenu()
		if not openMenuName then return end
		openMenuName = nil
		win.MenuDropdown.Visible = false
		menuMaid:Cleanup()

		for _, button in pairs(menuButtons) do
			button.BackgroundTransparency = 1
		end
	end

	win.CloseMenu = closeMenu

	local function openMenu(name, sourceButton)
		if openMenuName == name and win.MenuDropdouseEnter / MouseLeave / Click connection
		-- registered on the WINDOW maid, so each menu open leaked three
		-- connections per item for the lifetime of the window.
		menuMaid:Cleanup()
		openMenuName = name

		local items = menus[name] or {}

		for index, item in ipairs(items) do
			local itemButton = Create.create("TextButton", {
				Parent = win.MenuDropdown,
				LayoutOrder = index,
				Size = UDim2.new(1, 0, 0, 22),
				BackgroundTransparency = 1,
				Text = "  " .. item.Text,
				TextXAlignment = Enum.TextXAlignment.Left,
				Font = Theme.Font,
				TextSize = Theme.TextSize,
				AutoButtonColor = false,
				ZIndex = Layer.Menu + 1,
				theme = { BackgroundColor3 = "Selection", TextColor3 = "Text" },
			})

			menuMaid:Give(itemButton)
			menuMaid:Give(itemButton.MouseEnter:Connect(function()
				itemButton.BackgroundTransparency = 0
			end))
			menuMaid:Give(itemButton.MouseLeave:Connect(function()
				itemButton.BackgroundTransparency = 1
			end))
			menuMaid:Give(itemButton.MouseButton1Click:Connect(function()
				closeMenu()
				if item.Callback then
					local ok, err = xpcall(item.Callback, traceback)
					if not ok then Log.warn("Menu item failed:\n" .. tostring(err)) end
				end
			end))
		end

		local buttonPos = sourceButton.AbsolutePosition
		local buttonSize = sourceBut if the menu would run off the bottom of the screen.
		local screenBottom = getViewportSize(win.Gui).Y
		local top = buttonPos.Y + buttonSize.Y
		if top + (menuHeight * win:GetScale()) > screenBottom then
			top = math.max(8, buttonPos.Y - (menuHeight * win:GetScale()))
		end

		win.MenuDropdown.Size = UDim2.fromOffset(menuWidth, menuHeight)
		win.MenuDropdown.Position = UDim2.fromOffset(win:ToLocal(buttonPos.X), win:ToLocal(top))
		win.MenuDropdown.Visible = true

		for buttonName, button in pairs(menuButtons) do
			button.BackgroundTransparency = (buttonName == name) and 0 or 1
		end
	end

	local function addMenuButton(name, order)
		local button = Create.create("TextButton", {
			Parent = win.MenuBar,
			LayoutOrder = order,
			Size = UDim2.fromOffset(0, 20),
			AutomaticSize = Enum.AutomaticSize.X,
			BackgroundTransparency = 1,
			Text = "  " .. name .. "  ",
			Font = Theme.Font,
			TextSize = Theme.TextSize,
			AutoButtonColor = false,
			ZIndex = Layer.Chrome + 1,
			theme = { BackgroundColor3 = "PanelAlt", TextColor3 = "Text" },
		})

		menuButtons[name] = button

		win.BackgroundTransparency = 0
			end
		end))

		win:Track(button.MouseLeave:Connect(function()
			if openMenuName ~= name then button.BackgroundTransparency = 1 end
		end))

		return button
	end

	addMenuButton("File", 1)
	addMenuButton("View", 2)
	addMenuButton("Options", 3)
	addMenuButton("Help", 4)

	--============================ TOOLBAR ============================

	win.Toolbar = Create.create("Frame", {
		Parent = win.Main,
		Position = UDim2.fromOffset(0, Chrome.Title + Chrome.Menu),
		Size = UDim2.new(1, 0, 0, Chrome.Toolbar),
		BorderSizePixel = 0,
		ZIndex = Layer.Chrome,
		theme = { BackgroundColor3 = "Toolbar" },
	})

	Create.create("UIListLayout", {
		Parent = win.Toolbar,
		FillDirection = Enum.FillDirection.Horizontal,
		Padding = UDim.new(0, 2),
		VerticalAlignment = Enum.VerticalAlignment.Center,
		SortOrder = Enum.SortOrder.LayoutOrder,
	})

	Create.create("UIPadding", { Parent = win.Toolbar, PaddingLeft = UDim.new(0, 4) })

	local toolOrder = 0

	local function addToolButton(text, callback, tooltip)
		toolOrder += 1

		local button = Create.create("TextButton", {
			Parent = win.Toolbar,
			LayoutOrder = toolOrder,
			Size = UDim2.fromOffset(62, 22),
			BorderSizePixel = 1,
			Text = text,
			Font = Theme.Font,
			TextSize = Theme.TextSize,
			AutoButtonColor = false,
			ZIndex = Layer.Chrome + 1t
		end))
		win:Track(button.MouseLeave:Connect(function()
			button.BackgroundColor3 = Theme.Toolbar
		end))
		win:Track(button.MouseButton1Click:Connect(function()
			local ok, err = xpcall(callback, traceback)
			if not ok then Log.warn("Toolbar action failed:\n" .. tostring(err)) end
		end))

		attachTooltip(win, button, tooltip)
		return button
	end

	local function addToolSeparator()
		toolOrder += 1
		Create.create("Frame", {
			Parent = win.Toolbar,
			LayoutOrder = toolOrder,
			Size = UDim2.fromOffset(1, 18),
			BorderSizePixel = 0,
			theme = { BackgroundColor3 = "Border" },
		})
	end

	win.Toolbar.ClipsDescendants = true

	addToolButton("Run",   function() win:Log("Toolbar: Run") end,       "Run")
	addToolButton("Pause", function() win:Log("Toolbar: Pause") end,     "Pause")
	addToolButton("Step",  function() win:Log("Toolbar: Step") end,      "Step into")
	addToolButton("Over",  function() win:Log("Toolbar: Step Over") end, "Step over")
	addToolSeparator()
	addToolButton("Clear", function() win:ClearLog() end, "Clear the log")

	-- [FIX 58] Undo / Redo buttons now dim when their stack is empty. Previously
	-- they looked identical whether or not there was anything to undButtons()
		undoButton.TextColor3 = (#win.History.UndoStack > 0) and Theme.Text or Theme.Dim
		redoButton.TextColor3 = (#win.History.RedoStack > 0) and Theme.Text or Theme.Dim
	end

	win:Track(win.History.Changed:Connect(refreshHistoryButtons))
	refreshHistoryButtons()

	--============================ TAB BAR ============================

	win.TabBar = Create.create("ScrollingFrame", {
		Parent = win.Main,
		Position = UDim2.fromOffset(0, Chrome.Title + Chrome.Menu + Chrome.Toolbar),
		Size = UDim2.new(1, 0, 0, Chrome.Tabs),
		BorderSizePixel = 0,
		ScrollBarThickness = 0,
		ScrollingDirection = Enum.ScrollingDirection.X,
		CanvasSize = UDim2.new(),
		ZIndex = Layer.Chrome,
		theme = { BackgroundColor3 = "Menu" },
	})

	local tabLayout = Create.create("UIListLayout", {
		Parent = win.TabBar,
		FillDirection = Enum.FillDirection.Horizontal,
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, 1),
	})

	win:Track(tabLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		win.TabBar.CanvasSize = UDim2.fromOffset(win:ToLocal(tabLayout.AbsoluteContentSize.X) + 8, 0)
	end))

	--============================ PAGES / CONSOLE / STATUS ============================

	win.Pages = Create.create("Frame", {
		Parent = win.Main,
		Position = UDim2.from= "Background", BorderColor3 = "Border" },
	})

	win.Console = Create.create("Frame", {
		Parent = win.Main,
		Visible = win.ConsoleVisible,
		BorderSizePixel = 1,
		theme = { BackgroundColor3 = "Panel", BorderColor3 = "Border" },
	})

	local consoleHeader = Create.create("Frame", {
		Parent = win.Console,
		Size = UDim2.new(1, 0, 0, 20),
		BorderSizePixel = 0,
		theme = { BackgroundColor3 = "PanelAlt" },
	})

	Create.create("TextLabel", {
		Parent = consoleHeader,
		Position = UDim2.fromOffset(6, 0),
		Size = UDim2.new(1, -120, 1, 0),
		BackgroundTransparency = 1,
		Text = "Log",
		TextXAlignment = Enum.TextXAlignment.Left,
		Font = Theme.Font,
		TextSize = Theme.TextSize,
		theme = { TextColor3 = "Warning" },
	})

	local consoleClear = Create.create("TextButton", {
		Parent = consoleHeader,
		Position = UDim2.new(1, -56, 0, 0),
		Size = UDim2.fromOffset(56, 20),
		BorderSizePixel = 0,
		Text = "Clear",
		Font = Theme.Font,
		TextSize = Theme.TextSize,
		AutoButtonColor = false,
		theme = { BackgroundColor3 = "PanelAlt", TextColor3 = "Text" },
	})

	win:Track(consoleClear.MouseButton1Click:Connect(function() win:ClearLog() end))

	win.LogScroll = Create.create("ScrollingFrame", {
		Parent = win.Console,
		Position = UDim2.fromOffset(0, 20),rollBarImageColor3 = "Scroll" },
	})

	win.LogLabel = Create.create("TextLabel", {
		Parent = win.LogScroll,
		Size = UDim2.new(1, -8, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		Text = "",
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top,
		TextWrapped = true,
		RichText = true,
		Font = Theme.Font,
		TextSize = Theme.TextSize,
		theme = { TextColor3 = "Text" },
	})

	Create.create("UIPadding", {
		Parent = win.LogScroll,
		PaddingTop = UDim.new(0, 4),
		PaddingLeft = UDim.new(0, 4),
		PaddingRight = UDim.new(0, 4),
		PaddingBottom = UDim.new(0, 4),
	})

	-- [FIX 59] Auto-scroll pauses while the user has scrolled up, so reading
	-- backlog is no longer yanked to the bottom by every new line.
	win._LogAutoScroll = true

	win:Track(win.LogScroll:GetPropertyChangedSignal("CanvasPosition"):Connect(function()
		local scroll = win.LogScroll
		local maxScroll = math.max(0, scroll.CanvasSize.Y.Offset - win:ToLocal(scroll.AbsoluteWindowSize.Y))
		win._LogAutoScroll = (maxScroll - scroll, 0, Chrome.Status),
		BorderSizePixel = 0,
		theme = { BackgroundColor3 = "TitleBar" },
	})

	win.StatusLabel = Create.create("TextLabel", {
		Parent = win.StatusBar,
		Position = UDim2.fromOffset(8, 0),
		Size = UDim2.new(0.6, -16, 1, 0),
		BackgroundTransparency = 1,
		Text = "Ready",
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Font = Theme.Font,
		TextSize = Theme.TextSize,
		theme = { TextColor3 = "Text" },
	})

	win.StatusRight = Create.create("TextLabel", {
		Parent = win.StatusBar,
		Position = UDim2.new(0.6, 0, 0, 0),
		Size = UDim2.new(0.4, -8, 1, 0),
		BackgroundTransparency = 1,
		Text = "FPS: --",
		TextXAlignment = Enum.TextXAlignment.Right,
		Font = Theme.Font,
		TextSize = Theme.TextSize,
		theme = { TextColor3 = "Dim" },
	})

	win.Grip = Create.create("TextButton", {
		Parent = win.Main,
		Position = UDim2.new(1, -15, 1, -(Chrome.Status + 15)),
		Size = UDim2.fromOffset(14, 14),
		BackgroundTransparency = 1,
		Text = Glyphs.Grip,
		Font = Theme.Font,
		TextSize = 12,
		AutoButtonColor = false,
		ZIndex = Layer.Chrome + 5,
		theme = { TextColor3 = "Dim" },
	})

	--============================ B(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			win:Focus()
		end
	end))

	--[[
		[FIX 60] One input handler for the whole window instead of four separate
		global UserInputService connections that each re-derived state. Ctrl+P is
		detected with IsKeyDown, so the stale CommandModifierDown flag the old
		build tracked (and cleared in two places) is gone entirely.
	]]
	win:Track(InputRouter:On("Began", function(input, gameProcessed)
		if win.Destroyed then return end

		if input.UserInputType == Enum.UserInputType.Keyboard then
			local ctrlDown = UserInputService:IsKeyDown(Enum.KeyCode.LeftControl)
				or UserInputService:IsKeyDown(Enum.KeyCode.RightControl)

			if ctrlDown and input.KeyCode == Enum.KeyCode.P then
				win:ToggleCommandPalette()
				return
			end

			if ctrlDown and input.KeyCode == Enum.KeyCode.Z then
				win.History:UndoLast()
				return
			end

			if ctrlDown and input.KeyCode == Enum.KeyCode.Y then
				win.History:RedoLast()
				return
			end
		end

		if win.PickingKey then return end
		if InputManager.Capturing then return end
		if gameProcessed then return end
		if UserInputService:GetFocusedTextBox() then return end

		local key = X64UI.MenuKeybind
		local matchedind(input, key)
		end

		if matched then win:Toggle() end
	end))

	-- Outside-click dismissal. Now reliable, because mouseOverGui no longer
	-- reports true across three 36px-offset bands.
	win:Track(InputRouter:On("Began", function(input)
		if input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end

		task.defer(function()
			if win.Destroyed then return end

			if win.MenuDropdown.Visible
				and not mouseOverGui(win.MenuDropdown)
				and not mouseOverGui(win.MenuBar) then
				closeMenu()
			end

			if win.CommandPalette and win.CommandPalette.Visible and not mouseOverGui(win.CommandPalette) then
				win:CloseCommandPalette()
			end

			for index = #win.Dropdowns, 1, -1 do
				local dropdown = win.Dropdowns[index]

				if dropdown.Destroyed then
					table.remove(win.Dropdowns, index)
				elseif dropdown.Panel and dropdown.Panel.Visible then
					local justOpened = (os.clock() - dropdown.OpenedAt) < 0.08
					if not justOpened
						and not mouseOverGui(dropdown.Button)
						and not mouseOverGui(dropdown.Panel) then
						dropdown:Close()
					end
				end
			end
		end)
	end))

	win:Track(UserInputService.WindowFocusReleased:Connect(function()
		win.PickingKey = false
		InputManager:Cancel()
	end))

	win:Track(win.Gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()(newViewport.Y))
			win:UpdateLayout()
		elseif not win.Minimized then
			win:ClampToViewport()
		end
	end))

	win:Track(Workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
		task.defer(function()
			if win.Destroyed then return end

			if win.Maximized then
				local newViewport = getViewportSize(win.Gui)
				win.Main.Position = UDim2.fromOffset(0, 0)
				win.Main.Size = UDim2.fromOffset(win:ToLocal(newViewport.X), win:ToLocal(newViewport.Y))
				win:UpdateLayout()
			else
				win:ClampToViewport()
			end
		end)
	end))

	--[[
		[FIX 61] ONE RenderStepped connection, not two. The old build ran a
		dropdown-reposition loop and an FPS loop separately, and repositioned
		every open dropdown on every single frame regardless of whether anything
		had moved. On a 240Hz display that was ~480 pointless boundary crossings
		per second. Position is now refreshed only when the anchor actually
		changed.
	]]
	local frames = 0
	local lastSecond = os.clock()

	win:Track(RunService.RenderStepped:Connect(function()
		if win.Destroyed then return end

		frames += 1

		for index = #win.Dropdowns, 1, -1 do
			local dropdown = win.Dropdowns[index]

			if dropdown.Destroyed then
				table.remove(win.Dropdowns, index)
			elseif dropdown.Panel and dropdown.chor = anchor
						dropdown:RefreshPosition()
					end
				end
			end
		end

		local now = os.clock()
		if now - lastSecond >= 1 then
			if win.StatusRight and win.StatusRight.Parent then
				win.StatusRight.Text = string.format("FPS: %d  |  %s", frames, os.date("%X"))
			end
			frames = 0
			lastSecond = now
		end
	end))

	win:UpdateLayout()
	win:PlayIntro()

	table.insert(X64UI.Windows, win)
	X64UI.ActiveWindow = win

	-- [FIX 62] The old build ran a 30-line "integrity check" that scraped its own
	-- menu button labels with a string match and self-destructed the window if
	-- the scrape failed. It validated nothing a caller could influence, aborted
	-- construction after the window was already visible, and any theme or
	-- localisation change to a label would have bricked the library. Removed.
	--
	-- The genuine precondition — that the library surface exists — is asserted
	-- once at load, below.

	win:Log("X64UI " .. VERSION .. " ready.", "good
		local window = self.Windows[index]
		if window and type(window.Destroy) == "function" then
			pcall(function() window:Destroy() end)
		end
	end

	table.clear(self.Windows)
	self.ActiveWindow = nil

	pcall(function() InputRouter:Disconnect() end)
	InputManager:Cancel()

	-- [FIX 63] Every auxiliary ScreenGui is torn down. The old Unload destroyed
	-- NotifyGui only, permanently orphaning the tooltip, watermark and keybind
	-- list layers — so reinjecting stacked a new set on top of the old ones.
	if self._KeybindListConnection then
		self._KeybindListConnection:Disconnect()
		self._KeybindListConnection = nil
	end

	for _, field in ipairs({ "NotifyGui", "_WatermarkGui", "_KeybindListGui" }) do
		if self[field] then
			pcall(function() self[field]:Destroy() end)
			self[field] = nil
		end
	end

	self._WatermarkLabel = nil
	self._KeybindListFrame = nil
	self._KeybindRows = nil

	if TooltipGui then
		pcall(function() TooltipGui:Destroy() end)
		TooltipGui, TooltipLabel = nil, nil
	end

	table.clear(self.Commands)
	table.clear(self.CommandOrder)
	defaultCommandsRegistered = false

	if getgenv and getgenv().X64UI == self then getgenv().X64UI = nil end
	if shared and shared.X64UI == self then shared.X64UI = nil end
end

--==============================================================
--Watermark", "SetKeybindList", "GetCapabilities", "Unload",
		"Theme", "Version",
	}

	local missing = {}
	for _, name in ipairs(required) do
		if X64UI[name] == nil then table.insert(missing, name) end
	end

	-- [FIX 64] Fail loudly at load instead of setting an _IntegrityError flag
	-- that CreateWindow checked and then returned nil for, which surfaced to the
	-- caller as "attempt to index nil" several frames later.
	if #missing > 0 then
		error("[X64UI] library surface incomplete — missing: " .. table.concat(missing, ", "), 0)
	end
end

if getgenv then
	getgenv().X64UI = X64UI
elseif shared then
	shared.X64UI = X64UI
end

return X64UI

--[[
====================================================================
CHANGELOG — 5.5.1 → 6.0.0
====================================================================

CRITICAL
  12  mouseOverGui tested three points 36px apart and OR'd them, tripling every
      hit region into disjoint bands. Root cause of: clicking File/View/Options/
      Help starting a window drag, dragging from empty space above the window,
      res old file defined
      and never called even once.
  19  UIScale was ignored throughout: AbsoluteSize (scaled) was read and Size
      (unscaled) was written interchangeably. On the default 1.15 scale for
      1440p+ this made resize jump and compound, made maximize overflow the
      screen and push the close button ~315px off-screen with no way to close
      the window, widened the window on every minimize, over-scrolled every
      scroller, and rendered popups at 1.0 against a 1.15 window.
   7  Signal:Fire discarded all re-entrant fires (silent event loss) and its
      "disconnect-safe" backward loop both skipped and double-invoked callbacks.
  16  SetDisabled was cosmetic. Toggle, Input and ColorPicker checked nothing,
      so disabled controls stayed fully interactive.
  30  Groupbox:Clear destroyed row frames directly, orphaning dropdown and
      colour-picker panels into the ScreenGui, leaving dead Registry entries for
      save/load to write through, and leaving dead dropdowns in the per-frame
      reposition loop.
  41  KeyPicker discarded bothanently empty — nothing ever registered a
      command. 14 defaults added.
  50  Dialog rendered no title, no body, ran no callback, ignored Escape, was
      untracked and returned nil.

MAJOR
   2  Create.create swallowed all property errors, hiding every layout bug.
   4  Config writes are atomic and verified.
  11  InputRouter:Connect is idempotent and re-established per CreateWindow.
  20  Log trimming by lines, not bytes — no more severed RichText tags.
  25  Ordered config migration chain (old code stamped v3 but only migrated v2).
  26  Per-key isolation on load; one bad callback no longer aborts the pass.
  27  Scale, console, status and active tab are restored with layout.
  33  Typing a slider value now records undo, matching drag.
  37  Dropdown panel height derives from the filtered count.
  39  SetValues updates the closure array, so selection stops silions.
  57  Menu items leaked three connections per item per open.
  61  Two RenderStepped loops merged into one; dropdowns reposition on change.
  63  Unload now tears down tooltip, watermark and keybind-list layers.

ALSO
  Chrome heights are computed (old TopOffset 102 vs actual 100 = 2px seam) · Tab
  :Destroy referenced a field Tab never set · NextOrder reset off-by-one · popup
  registry is identity-keyed instead of append-only · toast eviction filters by
  class and orders monotonically · Registry warns on duplicate names and gates
  saveability explicitly · dropdown search box lifted out of the scrolling area ·
  Tree render unified to one path · ListBox SetValue type-checked · hex input
  accepts 3-digit form · t empty · all
  colours routed through live theming · Layer replaces hardcoded Z-indices ·
  self-destructing "integrity check" removed in favour of a load-time assert.
]]
