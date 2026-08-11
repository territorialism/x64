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

  -- refresh rows from registered keypickers across windows
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

-- Global export for other scripts to pick up.
if getgenv then
  getgenv().X64UI = X64UI
elseif shared then
  shared.X64UI = X64UI
end

return X64UI
