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
    Entry = "main.luau",
    Fallbacks = { "src/init.luau", "main.luau" },
    VersionFile = "version",
    Folder = "x64ui",
    Pin = nil,
    Offline = false,
    ForceRefresh = false,
    Verbose = true,
    Sentinel = "X64UI",
    MinBytes = 1024,
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
  local busted = url
  if not url:find("%?") then
    busted = url .. "?t=" .. tostring(os.clock())
  end
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
    local head = source:sub(1, 120):gsub("[\r\n]", " ")
    local hint = "unknown"
    if source:find("^404") or source:find("Not Found", 1, true) then
      hint = "not found — check Branch / Entry path"
    elseif source:find("<!DOCTYPE", 1, true) or source:find("<html", 1, true) then
      hint = "HTML page — BaseUrl must be raw.githubusercontent.com, not github.com"
    elseif source:find("^version https://git%-lfs") or source:find("git-lfs", 1, true) then
      hint = "Git LFS pointer — commit the file without LFS"
    elseif source:find("^%-%-%[%[") or source:find("x64ui", 1, true) then
      hint = "looks like a truncated upload or bootstrap stub — re-push the full library"
    end
    return false, ("source is only %d bytes (expected >= %d)\n  hint: %s\n  head: %s")
      :format(#source, config.MinBytes, hint, head)
  end

  if not source:find(config.Sentinel, 1, true) then
    return false, "source does not contain the expected sentinel (X64UI)"
  end

  local isAssembler = source:find("src/chunks", 1, true) or source:find("table.concat", 1, true)
  if not isAssembler and not source:find("return X64UI", 1, true) then
    return false, "source is missing 'return X64UI' — the upload is incomplete"
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

local function tryAssembleFromChunks()
  local root = baseUrl()
  local names = {
    "c01.luau", "c02.luau", "c03.luau", "c04.luau",
    "c05.luau", "c06.luau", "c07.luau", "c08.luau",
  }
  local parts = {}
  for _, name in ipairs(names) do
    local body, err = httpGet(root .. "src/chunks/" .. name)
    if not body then
      return nil, "chunk " .. name .. " missing: " .. tostring(err)
    end
    parts[#parts + 1] = body
  end
  local source = table.concat(parts)
  info(("assembled %d chunks → %d bytes"):format(#names, #source))
  return source
end

local function downloadLibrary()
  local root = baseUrl()
  local tried = {}
  local entries = { Loader.Config.Entry }
  for _, fb in ipairs(Loader.Config.Fallbacks or {}) do
    if fb ~= Loader.Config.Entry then
      entries[#entries + 1] = fb
    end
  end

  for _, entry in ipairs(entries) do
    info("trying " .. entry)
    local source, err = httpGet(root .. entry)
    if source then
      local ok, reason = validate(source)
      if ok then
        return source, entry
      end
      tried[#tried + 1] = entry .. ": " .. tostring(reason)
      info(entry .. " invalid: " .. tostring(reason))
    else
      tried[#tried + 1] = entry .. ": " .. tostring(err)
    end
  end

  info("trying src/chunks assembly")
  local assembled, aerr = tryAssembleFromChunks()
  if assembled then
    local ok, reason = validate(assembled)
    if ok then
      return assembled, "src/chunks"
    end
    tried[#tried + 1] = "chunks: " .. tostring(reason)
  else
    tried[#tried + 1] = "chunks: " .. tostring(aerr)
  end

  return nil, table.concat(tried, " | ")
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

  local target = config.Pin or remoteVersion or cachedVersion or "unknown"
  if not target or target == "" then
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
  local source, err = downloadLibrary()
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
