--[[
  x64ui main entry — assembles src/chunks into the library.
  Prefer loading via loader.luau.
]]
local base = "https://raw.githubusercontent.com/territorialism/x64/main/src/chunks/"
local n = 5
local parts = {}
local fetch = function(url)
  if type(request) == "function" then
    local ok, res = pcall(request, { Url = url, Method = "GET" })
    if ok and type(res) == "table" and type(res.Body) == "string" and #res.Body > 0 then
      return res.Body
    end
  end
  return game:HttpGet(url)
end
for i = 1, n do
  local url = base .. string.format("p%02d.luau", i)
  local body = fetch(url)
  assert(type(body) == "string" and #body > 0, "missing chunk " .. tostring(i))
  parts[i] = body
end
local source = table.concat(parts)
local chunk, err = loadstring(source, "@x64ui")
if not chunk then
  error("[x64ui] assemble compile failed: " .. tostring(err), 0)
end
local ok, lib = pcall(chunk)
if not ok then
  error("[x64ui] assemble runtime failed: " .. tostring(lib), 0)
end
if type(lib) ~= "table" or type(lib.CreateWindow) ~= "function" then
  error("[x64ui] assemble did not return a library", 0)
end
return lib
