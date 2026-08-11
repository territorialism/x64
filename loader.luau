--[[
  x64ui/loader.luau — r3

  ALWAYS invoke with a cache-buster, or GitHub's CDN will serve a stale
  loader for up to five minutes:

    local url = "https://raw.githubusercontent.com/territorialism/x64/main/loader.luau"
    local X64UI = loadstring(game:HttpGet(url .. "?cb=" .. os.time(), true))()

  Optional, set BEFORE running:

    getgenv().X64UILoaderConfig = { ForceRefresh = true, Verbose = true }
]]

local Loader = {
  Config = {
    Owner = "territorialism",
    Repo = "x64",
    Branch = "main",
    -- Relative paths are resolved against raw.githubusercontent.com/{Owner}/{Repo}/{Branch}/
    -- Absolute https URLs are also accepted.
    Entries = {
      "https://raw.githubusercontent.com/territorialism/x64ui/main/main.luau",
      "main.luau",
      "src/init.luau",
    },
    VersionFile = "version",
    Folder = "x64ui",
    Pin = nil,
    Offline = false,
    ForceRefresh = false,
    Verbose = true,
    -- Real library is ~110–150 KB. Anything under 40 KB is not it.
    MinBytes = 40000,
    -- Head, middle and tail markers so a partial upload cannot pass.
    Markers = { "local X64UI", "CreateWindow", "AddToggle", "return X64UI" },
  },
}

--==============================================================
-- OUTPUT
--==============================================================

local function info(message)
  if Loader.Config.Verbose then
    print("[x64ui-loader] " .. tostring(message))
  end
end

local function warnOut(message)
  warn("[x64ui-loader] " .. tostring(message))
end

--==============================================================
-- FILESYSTEM
--==============================================================

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
  local okRead, data = pcall(readfile, path)
  if okRead and type(data) == "string" then return data end
  return nil
end

-- FIX: verify the DESTINATION after writing, not only a temp file.
local function writeFile(path, contents)
  if not FS.CanWrite then return false end
  local temp = path .. ".tmp"
  if not pcall(writefile, temp, contents) then return false end
  if FS.CanRead and readFile(temp) ~= contents then
    if FS.CanDelete then pcall(delfile, temp) end
    return false
  end
  if not pcall(writefile, path, contents) then
    if FS.CanDelete then pcall(delfile, temp) end
    return false
  end
  if FS.CanDelete then pcall(delfile, temp) end
  if FS.CanRead and readFile(path) ~= contents then
    if FS.CanDelete then pcall(delfile, path) end
    return false
  end
  return true
end

local function ensureFolder(path)
  if not FS.CanFolder then return end
  local ok, exists = pcall(isfolder, path)
  if ok and not exists then pcall(makefolder, path) end
end

--==============================================================
-- HTTP
--==============================================================

local bustCounter = 0

-- FIX: unconditional cache-busting that survives an existing query string,
-- seeded from wall-clock time plus a per-call counter rather than os.clock().
local function bust(url)
  bustCounter += 1
  local sep = url:find("?", 1, true) and "&" or "?"
  return ("%s%scb=%d_%d_%d"):format(url, sep, os.time(), bustCounter, math.random(1, 1e6))
end

local function requestTransports()
  local transports = {}
  if type(syn) == "table" and type(syn.request) == "function" then
    transports[#transports + 1] = { name = "syn.request", fn = syn.request }
  end
  if type(http) == "table" and type(http.request) == "function" then
    transports[#transports + 1] = { name = "http.request", fn = http.request }
  end
  if type(http_request) == "function" then
    transports[#transports + 1] = { name = "http_request", fn = http_request }
  end
  if type(request) == "function" then
    transports[#transports + 1] = { name = "request", fn = request }
  end
  return transports
end

-- FIX: try every request transport, then game:HttpGet. A single non-2xx
-- from one implementation must not mask a working transport.
local function httpGet(url)
  local target = bust(url)
  local failures = {}

  for _, transport in ipairs(requestTransports()) do
    local ok, response = pcall(transport.fn, {
      Url = target,
      Method = "GET",
      Headers = { ["Cache-Control"] = "no-cache", ["Pragma"] = "no-cache" },
    })
    if ok and type(response) == "table" then
      local status = tonumber(response.StatusCode or response.Status) or 0
      local body = response.Body or response.body
      if status >= 200 and status < 300 and type(body) == "string" and #body > 0 then
        return body, nil, transport.name
      end
      failures[#failures + 1] = ("%s -> HTTP %s"):format(transport.name, tostring(status))
    else
      failures[#failures + 1] = ("%s -> %s"):format(transport.name, tostring(response))
    end
  end

  local ok, body = pcall(function()
    return game:HttpGet(target, true)
  end)
  if ok and type(body) == "string" and #body > 0 then
    return body, nil, "game:HttpGet"
  end
  failures[#failures + 1] = "game:HttpGet -> " .. tostring(body)
  return nil, table.concat(failures, "; ")
end

--==============================================================
-- PATHS
--==============================================================

local function sanitize(value)
  return (tostring(value):gsub("[^%w%.%-_]", ""))
end

local function repoRoot()
  local config = Loader.Config
  return ("https://raw.githubusercontent.com/%s/%s/%s/"):format(
    config.Owner, config.Repo, config.Branch
  )
end

local function resolveUrl(entry)
  if entry:find("^https?://", 1) then
    return entry
  end
  return repoRoot() .. entry
end

local function cachePath(version)
  return ("%s/lib-%s.luau"):format(Loader.Config.Folder, sanitize(version))
end

local function stampPath()
  return ("%s/version.txt"):format(Loader.Config.Folder)
end

--==============================================================
-- VALIDATION
--==============================================================

local function classify(source)
  if source:find("^404") or source:find("Not Found", 1, true) then
    return "404 from the raw host — wrong repo, branch or path"
  end
  if source:find("<!DOCTYPE", 1, true) or source:find("<html", 1, true) then
    return "HTML page — use raw.githubusercontent.com, not github.com"
  end
  if source:find("^version https://git%-lfs") then
    return "Git LFS pointer — re-commit the file without LFS"
  end
  if source:find("^%-%-%[%[") then
    return "starts like the library but ends early — TRUNCATED UPLOAD, re-push the file"
  end
  return "unrecognised content"
end

local function validate(source)
  local config = Loader.Config
  if type(source) ~= "string" then
    return false, "source is not a string"
  end

  if #source < config.MinBytes then
    return false, ("%d bytes, need >= %d — %s | head: %q")
      :format(#source, config.MinBytes, classify(source), source:sub(1, 80):gsub("[\r\n]", " "))
  end

  for _, marker in ipairs(config.Markers) do
    if not source:find(marker, 1, true) then
      return false, ("missing marker %q — upload incomplete (%d bytes)"):format(marker, #source)
    end
  end

  if type(loadstring) ~= "function" then
    return false, "loadstring is unavailable"
  end

  local chunk, compileError = loadstring(source)
  if not chunk then
    return false, "failed to compile: " .. tostring(compileError)
  end
  return true, chunk
end

--==============================================================
-- RESOLUTION
--==============================================================

local function resolveSource()
  local config = Loader.Config

  local cachedVersion = readFile(stampPath())
  if cachedVersion then
    cachedVersion = cachedVersion:gsub("%s+", "")
  end

  local remoteVersion
  if not config.Offline then
    local body, err = httpGet(repoRoot() .. config.VersionFile)
    if body and #body < 64 then
      remoteVersion = body:gsub("%s+", "")
      info("remote version: " .. remoteVersion)
    else
      info("version file unavailable (" .. tostring(err) .. ")")
    end
  end

  -- FIX: never cache under a placeholder like "latest".
  local target = config.Pin or remoteVersion or cachedVersion
  local cacheable = target ~= nil and target ~= "" and target ~= "latest"

  if cacheable and not config.ForceRefresh then
    local cached = readFile(cachePath(target))
    if cached then
      local ok, chunk = validate(cached)
      if ok then
        info("cache hit: " .. target)
        return cached, target, "cache", chunk
      end
      info("cached " .. target .. " rejected (" .. tostring(chunk) .. ") — refetching")
    end
  end

  if config.Offline then
    return nil, nil, nil, "offline and no valid cached copy of " .. tostring(target)
  end

  local report = {}
  for _, entry in ipairs(config.Entries) do
    local url = resolveUrl(entry)
    local source, err, transport = httpGet(url)
    if not source then
      info(("%-48s fetch failed: %s"):format(entry, tostring(err)))
      report[#report + 1] = ("%s: fetch failed (%s)"):format(entry, tostring(err))
    else
      local ok, chunkOrReason = validate(source)
      if ok then
        info(("%-48s OK, %d bytes via %s"):format(entry, #source, tostring(transport)))
        if cacheable and FS.CanWrite then
          ensureFolder(config.Folder)
          if writeFile(cachePath(target), source) then
            writeFile(stampPath(), target)
          else
            info("cache write failed — running from memory this session")
          end
        end
        return source, target or "unversioned", "network (" .. entry .. ")", chunkOrReason
      end
      info(("%-48s rejected: %s"):format(entry, tostring(chunkOrReason)))
      report[#report + 1] = ("%s: %s"):format(entry, tostring(chunkOrReason))
    end
  end

  if cachedVersion then
    local fallback = readFile(cachePath(cachedVersion))
    if fallback then
      local ok, chunk = validate(fallback)
      if ok then
        warnOut("every candidate failed — falling back to cached " .. cachedVersion)
        return fallback, cachedVersion, "cache (fallback)", chunk
      end
    end
  end

  return nil, nil, nil, "no usable source.\n  " .. table.concat(report, "\n  ")
end

--==============================================================
-- PUBLIC
--==============================================================

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
  for _, name in ipairs({ "6.0.0-desktop", "5.5.1-desktop" }) do
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
    local ok, result = validate(source)
    if not ok then
      error("[x64ui-loader] " .. tostring(result), 0)
    end
    chunk = result
  end

  local ok, library = pcall(chunk)
  if not ok then
    error("[x64ui-loader] the library threw while loading: " .. tostring(library), 0)
  end
  if type(library) ~= "table" or type(library.CreateWindow) ~= "function" then
    error("[x64ui-loader] " .. tostring(version) .. " did not return a usable library", 0)
  end
  if library.Supported == false then
    warnOut("this build is desktop-only and the current device is unsupported")
    return library
  end

  info(("loaded %s from %s"):format(tostring(library.Version or version), tostring(origin)))
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
