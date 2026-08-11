--[[
  x64ui main.luau

  Thin entry that returns the library. Prefer loading via loader.luau:

    local X64UI = loadstring(game:HttpGet(
      "https://raw.githubusercontent.com/territorialism/x64/main/loader.luau?cb=" .. os.time(),
      true
    ))()

  To publish a full monolithic build on this repo, replace this file with the
  complete source (must end with `return X64UI` and be ~100KB+).
]]

local url = "https://raw.githubusercontent.com/territorialism/x64ui/main/main.luau"
local ok, body = pcall(function()
  return game:HttpGet(url .. "?cb=" .. tostring(os.time()), true)
end)
if not ok or type(body) ~= "string" or #body < 40000 then
  error("[x64ui] failed to fetch library from " .. url .. " (" .. tostring(body) .. ")", 0)
end
if not body:find("return X64UI", 1, true) then
  error("[x64ui] downloaded source is incomplete", 0)
end

local chunk, err = loadstring(body, "@x64ui")
if not chunk then
  error("[x64ui] compile failed: " .. tostring(err), 0)
end

local ran, lib = pcall(chunk)
if not ran then
  error("[x64ui] runtime: " .. tostring(lib), 0)
end
if type(lib) ~= "table" or type(lib.CreateWindow) ~= "function" then
  error("[x64ui] library did not return CreateWindow", 0)
end

return lib
