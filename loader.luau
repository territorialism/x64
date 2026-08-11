--[[
  x64ui/loader.luau
  Fetches, caches and executes the x64ui library.

  Usage:
    local X64UI = loadstring(game:HttpGet("https://raw.githubusercontent.com/territorialism/x64/main/loader.luau"))()

  Optional config (set BEFORE running the loader):
    getgenv().X64UILoaderConfig = {
      Branch = "main",
      ForceRefresh = true,
      Pin = "6.0.0-desktop",
      Verbose = false,
    }
]]

local Loader = {
  Config = {
    BaseUrl = "https://raw.githubusercontent.com/territorialism/x64/",
    Branch = "main",
    Entry = "src/init.luau",
    VersionFile = "version",
    Folder = "x64ui",
    Pin = nil,
    Offline = false,
    ForceRefresh = false,
    Verbose = true,
    Sentinel = "X64UI",
    MinBytes = 4096,
  },
}

local function info(message)
  if Loader.Config.Verbose then
    print("[x64ui-loader] " .. tostring(message))
  end
end

local function warnOut(message)
  warn("[x64ui-loader] " .. tostring(message))
end

local FS = {
  CanRead = type(readfile) == "function" and type(isfile) == "function",
  CanWrite = type(writefile) == "function",
  CanDelete = type(delfile) == "function",
  CanFolder = type(makefolder) == "function" and type(isfolder) == "function",
}

local function readFile(path)
  if not FS.CanRead then return nil end
  local ok, exists = pcall(isfile, path)
  if not ok or not exists then return nil end
  local ok2, data = pcall(readfile, path)
  if ok2 and type(data) == "string" then return data end
  return nil
end

local function writeFile(path, contents)
  if not FS.CanWrite then return false end
  local temp = path .. ".tmp"
  if not pcall(writefile, temp, contents) then return false end
  if FS.CanRead then
    local back = readFile(temp)
    if back ~= contents then
      if FS.CanDelete then pcall(delfile, temp) end
      return false
    end
  end
  local ok = pcall(writefile, path, contents)
  if FS.CanDelete then pcall(delfile, temp) end
  return ok == true
end

local function ensureFolder(path)
  if not FS.CanFolder then return end
  local ok, exists = pcall(isfolder, path)
  if ok and not exists then
    pcall(makefolder, path)
  end
end

local function resolveRequestFunction()
  if type(syn) == "table" and type(syn.request) == "function" then return syn.request end
  if type(http) == "table" and type(http.request) == "function" then return http.request end
  if type(http_request) == "function" then return http_request end
  if type(request) == "function" then return request end
  return nil
end

local function httpGet(url)
  local requestFn = resolveRequestFunction()
  if requestFn then
    local ok, response = pcall(requestFn, {
      Url = url,
      Method = "GET",
      Headers = { ["Cache-Control"] = "no-cache" },
    })
    if ok and type(response) == "table" then
      local status = tonumber(response.StatusCode or response.Status) or 0
      local body = response.Body or response.body
      if status >= 200 and status < 300 and type(body) == "string" and #body > 0 then
        return body
      end
      return nil, ("HTTP %s for %s"):format(tostring(status), url)
    end
  end
  if type(game) == "userdata" or type(game) == "table" then
    local ok, body = pcall(function()
      return game:HttpGet(url, true)
    end)
    if ok and type(body) == "string" and #body > 0 then
      return body
    end
    return nil, ("HttpGet failed for %s (%s)"):format(url, tostring(body))
  end
  return nil, "no HTTP client available"
end

local function sanitize(value)
  return (tostring(value):gsub("[^%w%.%-_]", ""))
end

local function baseUrl()
  local config = Loader.Config
  local root = config.BaseUrl
  if root:sub(-1) ~= "/" then
    root = root .. "/"
  end
  if config.Branch and config.Branch ~= "" then
    root = root .. config.Branch .. "/"
  end
  return root
end

local function cachePath(version)
  return ("%s/lib-%s.luau"):format(Loader.Config.Folder, sanitize(version))
end

local function stampPath()
  return ("%s/version.txt"):format(Loader.Config.Folder)
end

local function validate(source)
  local config = Loader.Config
  if type(source) ~= "string" then
    return false, "source is not a string"
  end
  if #source < config.MinBytes then
    return false, ("source is only %d bytes — expected at least %d"):format(#source, config.MinBytes)
  end
  if not source:find(config.Sentinel, 1, true) then
    return false, "source does not contain the expected sentinel"
  end
  if type(loadstring) ~= "function" then
    return false, "loadstring is unavailable in this environment"
  end
  local chunk, compileError = loadstring(source)
  if not chunk then
    return false, "source failed to compile: " .. tostring(compileError)
  end
  return true, chunk
end

local function resolveSource()
  local config = Loader.Config
  local cachedVersion = readFile(stampPath())
  if cachedVersion then
    cachedVersion = cachedVersion:gsub("%s+", "")
  end

  local remoteVersion
  if not config.Offline then
    local body, err = httpGet(baseUrl() .. config.VersionFile)
    if body then
      remoteVersion = body:gsub("%s+", "")
    else
      info("version check skipped: " .. tostring(err))
    end
  end

  local target = config.Pin or remoteVersion or cachedVersion
  if not target then
    return nil, nil, nil, "no version available — offline with an empty cache"
  end

  if not config.ForceRefresh then
    local cached = readFile(cachePath(target))
    if cached then
      local ok = validate(cached)
      if ok then
        return cached, target, "cache"
      end
      info("cached copy of " .. target .. " failed validation — refetching")
    end
  end

  if config.Offline then
    return nil, nil, nil, "offline and no valid cached copy of " .. tostring(target)
  end

  info("downloading x64ui " .. target)
  local source, err = httpGet(baseUrl() .. config.Entry)
  if not source then
    if cachedVersion then
      local fallback = readFile(cachePath(cachedVersion))
      if fallback and select(1, validate(fallback)) then
        warnOut("download failed (" .. tostring(err) .. ") — using cached " .. cachedVersion)
        return fallback, cachedVersion, "cache"
      end
    end
    return nil, nil, nil, tostring(err)
  end

  local ok, reason = validate(source)
  if not ok then
    if cachedVersion then
      local fallback = readFile(cachePath(cachedVersion))
      if fallback and select(1, validate(fallback)) then
        warnOut("download invalid (" .. tostring(reason) .. ") — using cached " .. cachedVersion)
        return fallback, cachedVersion, "cache"
      end
    end
    return nil, nil, nil, tostring(reason)
  end

  if FS.CanWrite then
    ensureFolder(config.Folder)
    if writeFile(cachePath(target), source) then
      writeFile(stampPath(), target)
    else
      info("cache write failed — running from memory this session")
    end
  end

  return source, target, "network"
end

function Loader.Clean()
  if not FS.CanDelete then
    warnOut("delfile is unavailable — cannot clean the cache")
    return false
  end
  local stamp = readFile(stampPath())
  if stamp then
    pcall(delfile, cachePath(stamp:gsub("%s+", "")))
  end
  pcall(delfile, stampPath())
  info("cache cleaned")
  return true
end

function Loader.Load(overrides)
  if type(overrides) == "table" then
    for key, value in pairs(overrides) do
      Loader.Config[key] = value
    end
  end

  local source, version, origin, err = resolveSource()
  if not source then
    error("[x64ui-loader] " .. tostring(err), 0)
  end

  local chunk = loadstring(source, "@x64ui")
  if not chunk then
    chunk = loadstring(source)
  end
  if not chunk then
    error("[x64ui-loader] failed to compile x64ui " .. tostring(version), 0)
  end

  local ok, library = pcall(chunk)
  if not ok then
    error("[x64ui-loader] runtime error: " .. tostring(library), 0)
  end
  if type(library) ~= "table" or type(library.CreateWindow) ~= "function" then
    error("[x64ui-loader] x64ui " .. tostring(version) .. " did not return a usable library", 0)
  end

  if library.Supported == false then
    warnOut("this build is desktop-only and the current device is not supported")
    return library
  end

  info(("loaded x64ui %s from %s"):format(tostring(library.Version or version), origin))
  return library
end

if getgenv then
  getgenv().X64UILoader = Loader
  local supplied = getgenv().X64UILoaderConfig
  if type(supplied) == "table" then
    for key, value in pairs(supplied) do
      Loader.Config[key] = value
    end
  end
end

return Loader.Load()
