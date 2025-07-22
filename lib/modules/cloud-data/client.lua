--- @diagnostic disable-next-line: lowercase-global
lib = lib or {}

lib.cloud_data = { watchers = {}, data = {} }

--- @param serverProp string
--- @param cb fun(newValue: any)
--- @return integer
function lib.cloud_data.watch(serverProp, cb)
  if lib.cloud_data.watchers[serverProp] == nil then
    lib.cloud_data.watchers[serverProp] = {}
  end

  local nums = #lib.cloud_data.watchers[serverProp]
  local newIndex = nums + 1

  lib.cloud_data.watchers[serverProp][newIndex] = cb
  lib.cloud_data.data[serverProp] = nil

  pcall(function()
    TriggerServerEvent('ns_core.cloud-data:watch', serverProp)
  end)

  return newIndex
end

--- @generic T
--- @param serverProp string
--- @return T?
function lib.cloud_data.get(serverProp)
  return lib.cloud_data.data[serverProp]
end

--- @param serverProp string
--- @param newValue any
RegisterNetEvent('ns_core.cloud-data:update', function(serverProp, newValue)
  if lib.cloud_data.watchers[serverProp] ~= nil then
    lib.cloud_data.data[serverProp] = newValue

    pcall(function()
      lib.cloud_data.watchers[serverProp](newValue)
    end)
  end
end)
