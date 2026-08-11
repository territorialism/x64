--[[
  x64ui/loader.luau
  Fetches, caches and executes the x64ui library.

  Usage:
    local X64UI = loadstring(game:HttpGet(
      "https://raw.githubusercontent.com/territorialism/x64/main/loader.luau"
    ))()

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
    -- Preferred full-source URLs (tried in order).
    Entries = {
      "https://raw.githubusercontent.com/territorialism/x64/main/src/init.luau",
      "https://raw.githubusercontent.com/territorialism/x64ui/main/main.luau",
      "https://raw.githubusercontent.com/territorialism/x64/main/main.luau",
    },
    VersionFile = "version",
    Folder = "x64ui",
    Pin = nil,
    Offline = false,
    ForceRefresh = false,
    Verbose = true,
    Sentinel = "X64UI",
    MinBytes = 1500,
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
  local busted = url .. ((url:find("?", 1, true) and "&") or "?") .. "t=" .. tostring(os.clock())
  local requestFn = resolveRequestFunction()
  if requestFn then
    local ok, response = pcall(requestFn, {
      Url = busted,
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
      return game:HttpGet(busted, true)
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
  local chunk, compileError = loadstring(source, "@x64ui")
  if not chunk then
    chunk, compileError = loadstring(source)
  end
  if not chunk then
    return false, "source failed to compile: " .. tostring(compileError)
  end
  return true, chunk
end

local function runChunk(chunk, version, origin)
  local ok, library = pcall(chunk)
  if not ok then
    return nil, "runtime error: " .. tostring(library)
  end
  if type(library) ~= "table" or type(library.CreateWindow) ~= "function" then
    return nil, "did not return a usable library table"
  end
  if library.Supported == false then
    warnOut("this build is desktop-only and the current device is not supported")
  end
  info(("loaded x64ui %s from %s"):format(tostring(library.Version or version), origin))
  return library
end

local function entryUrls()
  local config = Loader.Config
  local list = {}
  if type(config.Entries) == "table" then
    for _, url in ipairs(config.Entries) do
      list[#list + 1] = url
    end
  end
  if type(config.Entry) == "string" and config.Entry ~= "" then
    if config.Entry:find("^https?://") then
      list[#list + 1] = config.Entry
    else
      list[#list + 1] = baseUrl() .. config.Entry
    end
  end
  return list
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

  local target = config.Pin or remoteVersion or cachedVersion or "latest"
  if not target then
    return nil, nil, nil, "no version available — offline with an empty cache"
  end

  if not config.ForceRefresh then
    local cached = readFile(cachePath(target))
    if cached then
      local ok, chunkOrReason = validate(cached)
      if ok then
        return cached, target, "cache", chunkOrReason
      end
      info("cached copy of " .. target .. " failed validation — refetching")
    end
  end

  if config.Offline then
    return nil, nil, nil, "offline and no valid cached copy of " .. tostring(target)
  end

  local lastErr
  for _, url in ipairs(entryUrls()) do
    info("trying " .. url)
    local source, err = httpGet(url)
    if not source then
      lastErr = tostring(err)
      info("  fetch failed: " .. lastErr)
    else
      local ok, chunkOrReason = validate(source)
      if ok then
        if FS.CanWrite then
          ensureFolder(config.Folder)
          if writeFile(cachePath(target), source) then
            writeFile(stampPath(), target)
          else
            info("cache write failed — running from memory this session")
          end
        end
        return source, target, "network:" .. url, chunkOrReason
      end
      lastErr = tostring(chunkOrReason)
      info("  validate failed: " .. lastErr)
    end
  end

  if cachedVersion then
    local fallback = readFile(cachePath(cachedVersion))
    if fallback then
      local ok, chunkOrReason = validate(fallback)
      if ok then
        warnOut("all downloads failed — using cached " .. cachedVersion)
        return fallback, cachedVersion, "cache", chunkOrReason
      end
    end
  end

  return nil, nil, nil, lastErr or "no usable source"
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
  for _, name in ipairs({ "latest", "6.0.0-desktop", "5.5.1-desktop" }) do
    pcall(delfile, cachePath(name))
  end
  info("cache cleaned")
  return true
end

function Loader.Load(overrides)
  if type(overrides) == "table" then
    for key, value in pairs(overrides) do
      Loader.Config[key] = value
    end
  end

  local source, version, origin, errOrChunk = resolveSource()
  if not source then
    error("[x64ui-loader] " .. tostring(errOrChunk), 0)
  end

  local chunk = errOrChunk
  if type(chunk) ~= "function" then
    local ok, c = validate(source)
    if not ok then
      error("[x64ui-loader] " .. tostring(c), 0)
    end
    chunk = c
  end

  local library, runErr = runChunk(chunk, version, origin)
  if not library then
    error("[x64ui-loader] " .. tostring(runErr), 0)
  end
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
