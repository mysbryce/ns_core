--- @diagnostic disable-next-line: lowercase-global
lib = lib or {}

lib.cloud_data = {
  watchers = {},
  data = {},
  validProps = {}
}

--- @generic T
--- @param prop string
--- @param initialValue T 
--- @return function getter, function setter
function lib.cloud_data.create(prop, initialValue)
  if type(prop) ~= 'string' then
    error('Property name must be a string')
  end

  lib.cloud_data.data[prop] = initialValue
  lib.cloud_data.validProps[prop] = true

  local getter = function()
    return lib.cloud_data.data[prop]
  end

  local setter = function(newValue)
    if lib.cloud_data.data[prop] ~= newValue then
      lib.cloud_data.data[prop] = newValue

      if lib.cloud_data.watchers[prop] ~= nil then
        local watchersList = {}
        
        for i = #lib.cloud_data.watchers[prop], 1, -1 do
          local playerId = lib.cloud_data.watchers[prop][i]
          
          if DoesPlayerExist(playerId) then
            table.insert(watchersList, playerId)
          else
            table.remove(lib.cloud_data.watchers[prop], i)
          end
        end
        
        lib.cloud_data.watchers[prop] = watchersList
        
        if #watchersList > 0 then
          for _, playerId in ipairs(watchersList) do
            TriggerClientEvent('ns_core.cloud-data:update', playerId, prop, newValue)
          end
        else
          lib.cloud_data.watchers[prop] = nil
        end
      end
    end
  end

  return getter, setter
end

--- @param prop string
--- @return boolean exists
function lib.cloud_data.exists(prop)
  return lib.cloud_data.validProps[prop] == true
end

--- @param prop string
--- @return any value
function lib.cloud_data.getValue(prop)
  if lib.cloud_data.validProps[prop] then
    return lib.cloud_data.data[prop]
  end
  return nil
end

--- @param prop string
--- @param value any
--- @return boolean success
function lib.cloud_data.setValue(prop, value)
  if lib.cloud_data.validProps[prop] then
    if lib.cloud_data.data[prop] ~= value then
      lib.cloud_data.data[prop] = value

      if lib.cloud_data.watchers[prop] ~= nil and #lib.cloud_data.watchers[prop] > 0 then
        for _, playerId in ipairs(lib.cloud_data.watchers[prop]) do
          TriggerClientEvent('ns_core.cloud-data:update', playerId, prop, value)
        end
      end
    end
    return true
  end
  return false
end

RegisterNetEvent('ns_core.cloud-data:watch', function(prop)
  local playerId = source

  if not playerId or not GetPlayerName(playerId) then
    return
  end

  if not lib.cloud_data.validProps[prop] then
    print(string.format("Warning: Client %d tried to watch non-existent property: %s", playerId, prop))
    return
  end

  if lib.cloud_data.watchers[prop] == nil then
    lib.cloud_data.watchers[prop] = {}
  end

  local alreadyWatching = false
  for _, existingPlayerId in ipairs(lib.cloud_data.watchers[prop]) do
    if existingPlayerId == playerId then
      alreadyWatching = true
      break
    end
  end

  if not alreadyWatching then
    table.insert(lib.cloud_data.watchers[prop], playerId)
  end

  TriggerClientEvent('ns_core.cloud-data:initial', playerId, prop, lib.cloud_data.data[prop])
end)

RegisterNetEvent('ns_core.cloud-data:unwatch', function(prop)
  local playerId = source

  if lib.cloud_data.watchers[prop] then
    for i = #lib.cloud_data.watchers[prop], 1, -1 do
      if lib.cloud_data.watchers[prop][i] == playerId then
        table.remove(lib.cloud_data.watchers[prop], i)
        break
      end
    end

    if #lib.cloud_data.watchers[prop] == 0 then
      lib.cloud_data.watchers[prop] = nil
    end
  end
end)

AddEventHandler('playerDropped', function(reason)
  local playerId = source
  
  for prop, watchers in pairs(lib.cloud_data.watchers) do
    for i = #watchers, 1, -1 do
      if watchers[i] == playerId then
        table.remove(watchers, i)
      end
    end

    if #watchers == 0 then
      lib.cloud_data.watchers[prop] = nil
    end
  end
end)

function lib.cloud_data.getStatus()
  local status = {
    totalProps = 0,
    totalWatchers = 0,
    propsWithWatchers = 0
  }

  for _ in pairs(lib.cloud_data.validProps) do
    status.totalProps = status.totalProps + 1
  end

  for prop, watchers in pairs(lib.cloud_data.watchers) do
    if watchers and #watchers > 0 then
      status.propsWithWatchers = status.propsWithWatchers + 1
      status.totalWatchers = status.totalWatchers + #watchers
    end
  end

  return status
end
