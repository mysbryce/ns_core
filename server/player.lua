--- @param source integer
--- @param name string
--- @return ESXItem?
lib.callback.register('ns_core:getItem', function(source, name)
  if ESX then
    local xPlayer = ESX.GetPlayerFromId(source)

    if xPlayer then
      local item = xPlayer.getInventoryItem(name)
      return item
    end

    return nil
  end

  return nil
end)

--- @param source integer
--- @param name string
--- @return ESXPlayerAccount?
lib.callback.register('ns_core:getAccount', function(source, name)
  if ESX then
    local xPlayer = ESX.GetPlayerFromId(source)

    if xPlayer then
      local account = xPlayer.getAccount(name)
      return account
    end

    return nil
  end

  return nil
end)
