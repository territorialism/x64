  end

  local container = parent:FindFirstChild("X64Notifications")

  if not container then
    container = Create.create("Frame", {
      Parent = parent,
      Name = "X64Notifications",
      AnchorPoint = Vector2.new(1, 1),
      Position = UDim2.new(1, -12, 1, -12),
      Size = UDim2.fromOffset(280, 0),
      AutomaticSize = Enum.AutomaticSize.Y,
      BackgroundTransparency = 1,
      ZIndex = 10000,
    })

    Create.create("UIListLayout", {
      Parent = container,
      Padding = UDim.new(0, 8),
      SortOrder = Enum.SortOrder.LayoutOrder,
      HorizontalAlignment = Enum.HorizontalAlignment.Right,
      VerticalAlignment = Enum.VerticalAlignment.Bottom,
    })
  end

  while #container:GetChildren() > 6 do
    local child = container:GetChildren()[2]
    if child then child:Destroy() end
  end

  local toastMaid = Maid.new()
  local toast = Create.create("CanvasGroup", {
    Parent = container,
    Size = UDim2.new(1, 0, 0, 58),
    BackgroundColor3 = Theme.Panel,
    BorderColor3 = Theme.Border,
    GroupTransparency = 1,
    LayoutOrder = math.floor(os.clock() * 1000),
    ZIndex = 10001,
  })

  toastMaid:Give(toast)

  Create.create("TextLabel", {
    Parent = toast,
    Position = UDim2.fromOffset(8, 4),
    Size = UDim2.new(1, -16, 0, 18),
    BackgroundTransparency = 1,
    Text = opts.Title or "Notification",
    TextXAlignment = Enum.TextXAlignment.Left,
    Font = Theme.Font,
    TextSize = Theme.TextSize,
    TextColor3 = Theme.AccentText,
    ZIndex = 10002,
  })

  Create.create("TextLabel", {
    Parent = toast,
    Position = UDim2.fromOffset(8, 24),
    Size = UDim2.new(1, -16, 0, 28),
    BackgroundTransparency = 1,
    Text = opts.Description or "",
    TextWrapped = true,
    TextXAlignment = Enum.TextXAlignment.Left,
    TextYAlignment = Enum.TextYAlignment.Top,
    Font = Theme.Font,
    TextSize = Theme.TextSize,
    TextColor3 = Theme.Text,
    ZIndex = 10002,
  })

  TweenService:Create(
    toast,
    TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
    { GroupTransparency = 0 }
  ):Play()

  local hideThread = task.delay(opts.Time or 3, function()
    if toast and toast.Parent then
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
  end)
  
  toastMaid:Give(hideThread)
end

-- library surface integrity (api surface must be complete)
do
  local requiredApi = {
    "CreateWindow",
    "Notify",
    "RegisterCommand",
    "Theme",
    "Version",
  }
  local missing = {}
  for _, name in ipairs(requiredApi) do
    if X64UI[name] == nil then
      table.insert(missing, name)
    end
  end
  if #missing > 0 then
    local msg = "x64ui api incomplete — missing: " .. table.concat(missing, ", ")
    warn("[X64UI] " .. msg)
    X64UI._IntegrityError = msg
  end
end



function X64UI.SerializeValue(control)
  if not control then return nil end
  local t = control.Type
  local v = control.Value
  if t == "ColorPicker" and typeof(v) == "Color3" then
    return { t = "Color3", r = v.R, g = v.G, b = v.B }
  end
  if t == "Dropdown" and type(v) == "table" then
    return { t = "Multi", v = v }
  end
  if t == "Toggle" or t == "Slider" or t == "NumericInput" or t == "KeyPicker" or t == "Input" then
    return v
  end
  if type(v) == "string" or type(v) == "number" or type(v) == "boolean" then
    return v
  end
  return nil
end

function X64UI.DeserializeValue(control, raw)
  if not control or raw == nil then return nil end
  if type(raw) == "table" and raw.t == "Color3" then
    return Color3.new(raw.r or 0, raw.g or 0, raw.b or 0)
  end
  if type(raw) == "table" and raw.t == "Multi" then
    return raw.v
  end
  return raw
end


function X64UI:SetWatermark(text)
  if not self._WatermarkGui or not self._WatermarkGui.Parent then
    self._WatermarkGui = Create.create("ScreenGui", {
      Name = "X64Watermark",
      ResetOnSpawn = false,
      IgnoreGuiInset = true,
      DisplayOrder = 100,
      Parent = getParent(),
    })
    self._WatermarkLabel = Create.create("TextLabel", {
      Parent = self._WatermarkGui,
      Position = UDim2.fromOffset(12, 12),
      Size = UDim2.fromOffset(0, 0),
      AutomaticSize = Enum.AutomaticSize.XY,
      BackgroundColor3 = Theme.Panel,
      BorderColor3 = Theme.Border,
      Text = "",
      Font = Theme.Font,
      TextSize = Theme.TextSize,
      TextColor3 = Theme.Text,
      TextXAlignment = Enum.TextXAlignment.Left,
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
end


function X64UI:SetKeybindList(enabled)
  if enabled == false then
    if self._KeybindListGui then
      self._KeybindListGui.Enabled = false
    end
    return
  end

  if not self._KeybindListGui or not self._KeybindListGui.Parent then
    self._KeybindListGui = Create.create("ScreenGui", {
      Name = "X64KeybindList",
      ResetOnSpawn = false,
      IgnoreGuiInset = true,
      DisplayOrder = 150,
      Parent = getParent(),
    })
    self._KeybindListFrame = Create.create("Frame", {
      Parent = self._KeybindListGui,
      AnchorPoint = Vector2.new(1, 0),
      Position = UDim2.new(1, -12, 0, 12),
      Size = UDim2.fromOffset(200, 0),
      AutomaticSize = Enum.AutomaticSize.Y,
      BackgroundColor3 = Theme.Panel,
      BorderColor3 = Theme.Border,
    })
    Create.create("UIListLayout", {
      Parent = self._KeybindListFrame,
      Padding = UDim.new(0, 2),
      SortOrder = Enum.SortOrder.LayoutOrder,
    })
    Create.create("TextLabel", {
      Parent = self._KeybindListFrame,
      Size = UDim2.new(1, 0, 0, 18),
      BackgroundColor3 = Theme.TitleBar,
      BorderSizePixel = 0,
      Text = " keybinds ",
      Font = Theme.Font,
      TextSize = Theme.TextSize,
      TextColor3 = Theme.AccentText,
      TextXAlignment = Enum.TextXAlignment.Left,
    })
  end

  self._KeybindListGui.Enabled = true

  for _, child in ipairs(self._KeybindListFrame:GetChildren()) do
    if child:IsA("TextLabel") and child.LayoutOrder > 0 then
      child:Destroy()
    end
  end

  local order = 1
  for _, win in ipairs(self.Windows or {}) do
    if win.Registry and win.Registry.Options then
      for name, opt in pairs(win.Registry.Options) do
        if opt.Type == "KeyPicker" and opt.Value and opt.Value ~= "None" then
          local state = ""
          if opt.GetState then
            state = opt:GetState() and " [ON]" or ""
          end
          Create.create("TextLabel", {
            Parent = self._KeybindListFrame,
            LayoutOrder = order,
            Size = UDim2.new(1, -8, 0, 16),
            BackgroundTransparency = 1,
            Text = string.format(" %s: %s%s", name, tostring(opt.Value), state),
            Font = Theme.Font,
            TextSize = Theme.TextSize - 1,
            TextColor3 = Theme.Text,
            TextXAlignment = Enum.TextXAlignment.Left,
          })
          order += 1
        end
      end
    end
  end
end


function X64UI:GetCapabilities()
  return {
    writefile = Platform.CanWrite == true,
    readfile = Platform.CanRead == true,
    delfile = Platform.CanDelete == true,
    gethui = type(gethui) == "function",
    request = type(request) == "function",
    getgenv = type(getgenv) == "function",
    hookfunction = type(hookfunction) == "function",
    Drawing = type(Drawing) == "table",
  }
end

function X64UI:ReportCapabilities(window)
  local c = self:GetCapabilities()
  local parts = {}
  for k, v in pairs(c) do
    parts[#parts + 1] = k .. "=" .. (v and "yes" or "no")
  end
  table.sort(parts)
  local msg = "caps: " .. table.concat(parts, " ")
  if window and window.Log then
    window:Log(msg, "accent")
  else
    Log.info(msg)
  end
  return c
end

function X64UI:Unload()
  if self.Unloaded then return end
  self.Unloaded = true

  if InputRouter and InputRouter.Disconnect then
    pcall(function() InputRouter:Disconnect() end)
  end

  for i = #self.Windows, 1, -1 do
    local win = self.Windows[i]
    if win and type(win.Destroy) == "function" then
      pcall(function() win:Destroy() end)
    end
  end
  table.clear(self.Windows)
  self.ActiveWindow = nil

  if self.NotifyGui then
    pcall(function() self.NotifyGui:Destroy() end)
    self.NotifyGui = nil
  end

  if getgenv then getgenv().X64UI = nil end
  if shared then shared.X64UI = nil end
end

if getgenv then
  getgenv().X64UI = X64UI
elseif shared then
  shared.X64UI = X64UI
end

return X64UI
