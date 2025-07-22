--- @diagnostic disable-next-line: lowercase-global
lib = lib or {}

lib.cloud_data = { watchers = {}, data = {} }

--- @generic T
--- @param prop string
--- @param initialValue T 
function lib.cloud_data.create(prop, initialValue)
  lib.cloud_data.data[prop] = initialValue

  return
    --- @generic T
    --- @return T
    function()
      return lib.cloud_data.data[prop]
    end,
    --- @generic T
    --- @param newValue T
    function(newValue)
      lib.cloud_data.data[prop] = newValue

      if lib.cloud_data.watchers[prop] ~= nil then
        pcall(function()
          for _, playerId in ipairs(lib.cloud_data.watchers[prop]) do
            TriggerClientEvent('ns_core.cloud-data:watch', playerId, prop, newValue)
          end
        end)
      end
    end
end

--- @param prop string
RegisterNetEvent('ns_core.cloud-data:watch', function(prop)
  local playerId = source

  if playerId ~= nil and lib.cloud_data.data[prop] ~= nil then
    if lib.cloud_data.watchers[prop] == nil then
      lib.cloud_data.watchers[prop] = {}
    end

    table.insert(lib.cloud_data.watchers[prop], playerId)
  end
end)
