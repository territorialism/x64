--[[
  x64ui main entry (bootstrap)

  The previous tip main.luau was corrupted mid-file (line ~138) and would not
  compile. Until the full 6.0.0 body is published as src/chunks/c01..c10,
  this bootstrap loads a known-good library build.

  Prefer: loadstring(game:HttpGet(".../loader.luau"))()
]]

local urls = {
  -- preferred: assembled clean chunks (when present)
  "https://raw.githubusercontent.com/territorialism/x64/main/src/init.luau",
  -- fallback: last known good monolithic build on the sister repo
  "https://raw.githubusercontent.com/territorialism/x64ui/main/main.luau",
}

local function fetch(url)
  if type(request) == "function" then
    local ok, res = pcall(request, {
      Url = url .. "?t=" .. tostring(os.clock()),
      Method = "GET",
      Headers = { ["Cache-Control"] = "no-cache" },
    })
    if ok and type(res) == "table" then
      local status = tonumber(res.StatusCode) or 0
      local body = res.Body
      if status >= 200 and status < 300 and type(body) == "string" and #body > 4096 then
        return body
      end
    end
  end
  local ok, body = pcall(function()
    return game:HttpGet(url .. "?t=" .. tostring(os.clock()), true)
  end)
  if ok and type(body) == "string" and #body > 4096 then
    return body
  end
  return nil
end

local source, lastErr
for _, url in ipairs(urls) do
  local body = fetch(url)
  if body and body:find("X64UI", 1, true) and body:find("CreateWindow", 1, true) then
    local chunk, err = loadstring(body, "@x64ui")
    if chunk then
      local ok, lib = pcall(chunk)
      if ok and type(lib) == "table" and type(lib.CreateWindow) == "function" then
        return lib
      end
      lastErr = "runtime: " .. tostring(lib)
    else
      lastErr = "compile: " .. tostring(err)
    end
  else
    lastErr = "fetch failed or too small: " .. url
  end
end

error("[x64ui] failed to load library — " .. tostring(lastErr), 0)
