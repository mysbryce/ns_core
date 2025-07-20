local appData = { events = {} }
--- @diagnostic disable-next-line: lowercase-global
lib = lib or {}

lib.server = {}

assertType = exports.ns_core:assertType

--- @return NS.Server
function lib.server:new()
  local data = {}

  setmetatable(data, self)

  self.__index = self

  return self
end

lib.server.event = {}

--- @param name string
--- @param handler fun(...)
--- @param isNet boolean?
function lib.server.event:register(name, handler, isNet)
  assertType(1, name, 'string')
  assertType(2, handler, 'function')

  if isNet == nil then isNet = false end

  if isNet then
    RegisterNetEvent(name)
  end

  return AddEventHandler(name)
end

--- @param mounted string
function lib.server.event:use(mounted)
  assertType(1, mounted, 'string')

  --- @param name string
  --- @param handler fun(...)
  --- @param isNet boolean?
  return function(name, handler, isNet)
    return self:register(('%s:%s'):format(mounted, name), handler, isNet)
  end
end
