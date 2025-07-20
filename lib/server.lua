--- @diagnostic disable-next-line: lowercase-global
lib = lib or {}

lib.server = {}

assertType = exports.ns_core:assertType

function lib.server:new()
  local data = {}

  setmetatable(data, self)

  return self
end

function lib.server:use(name, mounter)
  
end
