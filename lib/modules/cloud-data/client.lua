--- @diagnostic disable-next-line: lowercase-global
lib = lib or {}

lib.cloud_data = {
  watchers = {},
  data = {},
  watcherCount = {},
  requestedProps = {}
}

--- @param serverProp string
--- @param cb fun(newValue: any)
--- @return integer watcherId
function lib.cloud_data.watch(serverProp, cb)
  if type(serverProp) ~= 'string' or type(cb) ~= 'function' then
    error('Invalid parameters: serverProp must be string, cb must be function')
  end

  if lib.cloud_data.watchers[serverProp] == nil then
    lib.cloud_data.watchers[serverProp] = {}
    lib.cloud_data.watcherCount[serverProp] = 0
  end

  local watcherId = lib.cloud_data.watcherCount[serverProp] + 1
  lib.cloud_data.watcherCount[serverProp] = watcherId

  lib.cloud_data.watchers[serverProp][watcherId] = cb

  if not lib.cloud_data.requestedProps[serverProp] then
    lib.cloud_data.requestedProps[serverProp] = true
    
    TriggerServerEvent('ns_core.cloud-data:watch', serverProp)
    
    if lib.cloud_data.data[serverProp] ~= nil then
      pcall(cb, lib.cloud_data.data[serverProp])
    end
  else
    if lib.cloud_data.data[serverProp] ~= nil then
      pcall(cb, lib.cloud_data.data[serverProp])
    end
  end

  return watcherId
end

--- @param serverProp string
--- @param watcherId integer
--- @return boolean success
function lib.cloud_data.unwatch(serverProp, watcherId)
  if lib.cloud_data.watchers[serverProp] and lib.cloud_data.watchers[serverProp][watcherId] then
    lib.cloud_data.watchers[serverProp][watcherId] = nil
    
    local hasWatchers = false
    for _ in pairs(lib.cloud_data.watchers[serverProp]) do
      hasWatchers = true
      break
    end
    
    if not hasWatchers then
      lib.cloud_data.watchers[serverProp] = nil
      lib.cloud_data.requestedProps[serverProp] = nil
      TriggerServerEvent('ns_core.cloud-data:unwatch', serverProp)
    end
    
    return true
  end
  return false
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

    for _, cb in pairs(lib.cloud_data.watchers[serverProp]) do
      pcall(cb, newValue)
    end
  end
end)

RegisterNetEvent('ns_core.cloud-data:initial', function(serverProp, initialValue)
  lib.cloud_data.data[serverProp] = initialValue
  
  if lib.cloud_data.watchers[serverProp] then
    for _, cb in pairs(lib.cloud_data.watchers[serverProp]) do
      pcall(cb, initialValue)
    end
  end
end)

AddEventHandler('onResourceStop', function(resourceName)
  if resourceName == GetCurrentResourceName() then
    for prop in pairs(lib.cloud_data.requestedProps) do
      TriggerServerEvent('ns_core.cloud-data:unwatch', prop)
    end
  end
end)
