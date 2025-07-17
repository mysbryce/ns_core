--- @diagnostic disable-next-line: lowercase-global
lib = lib or {}

lib.client = {}

--- @param onPlayerLoaded fun(self: NS.Client, esx: ESXObject)?
--- @return NS.Client
function lib.client:new(onPlayerLoaded)
  local data = {}

  setmetatable(data, self)

  self.__index = self
  self.debugMode = false
  self.onPlayerLoaded = onPlayerLoaded

  --- ESX
  --- @type ESXObject
  self.esx = exports.es_extended:getSharedObject()
  --- @type boolean
  self.isDead = false

  --- Coords utility
  --- @type table<string, NS.Core.TargetCoords>
  self.targetCoords = {}
  --- @type string?
  self.nearestTarget = nil
  --- @type number?
  self.nearestDist = nil
  --- @type table<string, boolean>
  self.inCoords = {}

  --- Cache utility
  --- @generic T
  --- @type table<string, T>
  self.cache = {}

  --- Progress utility
  self.progress = { worker = false, workerName = nil, workerTakeDamage = true }

  return self
end

--- @param name string
--- @param target vector3
--- @param lodDist number
--- @param interactDist number
function lib.client:addCoords(name, target, lodDist, interactDist)
  self.targetCoords[name] = {
    coords = target,
    lodDist = lodDist,
    interactDist = interactDist
  }

  self.inCoords[name] = false
end

--- @param name string
function lib.client:removeCoords(name)
  if type(name) == 'string' and self.targetCoords[name] then
    self.targetCoords[name] = nil
    self.inCoords[name] = nil
  end
end

--- @param minimumDist number?
--- @return string?, NS.Core.TargetCoords?, number?
function lib.client:getNearestCoords(minimumDist)
  if minimumDist == nil then minimumDist = 999999 end

  if self.nearestDist ~= nil and self.nearestDist <= minimumDist then
    return self.nearestTarget, self.targetCoords[self.nearestTarget], self.nearestDist
  end

  return nil, nil, nil
end

--- @param name string
--- @param validate boolean?
--- @return ESXItem?
function lib.client:getItem(name, validate)
  if validate == nil then validate = false end
  if name == nil then name = '' end

  if not validate then
    for _, v in ipairs(self.esx.GetPlayerData().inventory) do
      if v.name == name then
        return v
      end
    end
  else
    --- @type ESXItem?
    local item = lib.callback.await('ns_core:getItem', false, name)
    return item
  end
end

--- @param name string
--- @param validate boolean?
--- @return ESXPlayerAccount?
function lib.client:getAccount(name, validate)
  if validate == nil then validate = false end
  if name == nil then name = '' end

  if not validate then
    for _, v in ipairs(self.esx.GetPlayerData().accounts) do
      if v.name == name then
        return v
      end
    end
  else
    --- @type ESXPlayerAccount?
    local account = lib.callback.await('ns_core:getAccount', false, name)
    return account
  end
end

--- @param mode 'Pressed' | 'JustPressed' | 'Released' | 'JustReleased'
--- @param key integer
--- @param allowDisable boolean?
--- @return boolean
function lib.client:onKey(mode, key, allowDisable)
  if allowDisable == nil then allowDisable = false end

  local defFunction = ('IsControl%s'):format(mode)

  --- @return boolean, boolean
  local function handleKey()
    return pcall(function()
      local defResult = _G[defFunction](0, key)

      if allowDisable then
        local disFunction = ('IsDisabledControl%s'):format(mode)
        local disResult = _G[disFunction](0, key)

        return defResult or disResult
      end

      return defResult
    end)
  end

  if _G[defFunction] ~= nil then
    local retval, isPressed = handleKey()

    return retval and isPressed
  else
    error(('function %s is not defined in _G or ENV'):format(defFunction))
    return false
  end
end

--- @param ... any
--- @return boolean
function lib.client:handleNils(...)
  for _, v in ipairs(...) do
    if v == nil then return false end
  end

  return true
end

--- @param object NS.ProgressBar.Object
--- @param async boolean? default is true
--- @return boolean?
--- @async
function lib.client:startProgress(object, async)
  if self.progress.worker == true then
    error(('progressbar is working on %s'):format(self.progress.workerName))
    return
  end

  if object.canCancel == nil then object.canCancel = false end

  if async == nil then async = true end

  self.progress.worker = true
  self.progress.workerName = ('%s_progbar'):format(object?.name or 'ns_core')
  self.progress.workerTakeDamage = object?.canTakeDamage

  --- @type integer
  local ped = self.cache.ped
  --- @type string?
  local animLib,
  --- @type string?
  animName,
  --- @type integer?
  animFlag = nil, nil, nil
  --- @type promise?
  local pm = nil
  --- @type integer?
  local prop = nil

  if object?.animation ~= nil then
    animLib = object?.animation?.clip or ''
    animName = object?.animation?.name or ''
    animFlag = object?.animation?.flag or ''
  end

  if not async then
    pm = promise.new()
  end

  if object?.prop ~= nil then
    local objectName = object?.prop?.model or ''
    local targetBone = object?.prop?.bone or 0
    local targetCoords = object?.prop?.coords or vec3(0.0, 0.0, 0.0)
    local targetRotation = object?.prop?.rotation or vec3(0.0, 0.0, 0.0)

    if objectName ~= '' and targetBone ~= 0 and targetCoords and targetRotation then
      lib.requestModel(objectName)

      local coords = GetEntityCoords(ped)
      prop = CreateObject(GetHashKey(objectName), coords.x, coords.y, coords.z, true, true, true)
      local boneIndex = GetPedBoneIndex(ped, targetBone)
      AttachEntityToEntity(prop, ped, boneIndex, targetCoords.x, targetCoords.y, targetCoords.z, targetRotation.x,
        targetRotation.y, targetRotation.z, true, true, false, true, 1, true)
    end
  end

  local params = {
    name = self.progress.workerName,
    duration = object?.duration or 5000,
    label = object?.label or 'Loading',
    table.unpack(object?.addons or {}),
  }

  if params.controlDisables == nil then
    params.controlDisables = {
      disableMovement = true,
      disableCarMovement = true,
      disableMouse = false,
      disableCombat = true,
    }
  end

  TriggerEvent('mythic_progbar:client:ProgressWithStartAndTick', params, function()
      if animLib ~= '' and animName ~= '' and animFlag ~= '' then
        lib.requestAnimDict(animLib)
        TaskPlayAnim(ped, animLib, animName, 8.0, -8.0, -1, animFlag, 0, false, false, false)
      end
    end,
    function()
      if object.canCancel then
        if IsControlJustPressed(0, 73) or IsDisabledControlJustPressed(0, 73) then
          TriggerEvent('mythic_progbar:client:cancel')
        end
      end
    end,
    function(cancelled)
      if not async and pm then
        pm:resolve(cancelled)
      elseif async then
        if not cancelled then
          pcall(function() object?.onCompleted() end)
        else
          pcall(function() object?.onCancelled() end)
        end
      end

      if animLib ~= '' then
        RemoveAnimDict(animLib)
      end

      if prop ~= nil then
        DeleteEntity(prop)
      end

      self.progress.worker = false
      self.progress.workerName = nil
      self.progress.workerTakeDamage = true
    end)

  if not async and pm then
    --- @type boolean
    local result = Citizen.Await(pm)
    return result
  end
end

--- @param prefix NS.Debug.Type
--- @param text string
function lib.client:debug(prefix, text)
  if self.debugMode then
    local color

    if prefix == 'success' then
      color = '^2'
    elseif prefix == 'info' then
      color = '^5'
    elseif prefix == 'warn' then
      color = '^3'
    elseif prefix == 'error' then
      color = '^1'
    end

    print(('%s[%s]^7 %s^7'):format(color, string.upper(prefix), text))
  end
end

--- @param toggle boolean?
function lib.client:setDebugMode(toggle)
  if toggle == nil then toggle = true end

  self.debugMode = toggle
end

--- @param async boolean?
function lib.client:start(async)
  if lib.callback == nil then
    error('this resource must add [shared_script \'@ox_lib/init.lua\'] to your fxmanifest.lua')
    return
  end

  if async == nil then async = false end

  if self.esx == nil then
    while self.esx == nil do
      self.esx = exports.es_extended:getSharedObject()
      Wait(1000)
    end
  end

  local loader = function()
    if type(self.onPlayerLoaded) == 'function' then
      while not self.esx.IsPlayerLoaded() do
        Wait(50)
      end

      self.onPlayerLoaded(self, self.esx)
    end

    CreateThread(function()
      --- @class integer
      self.cache.ped = PlayerPedId()

      while true do
        self.cache.ped = PlayerPedId()

        Wait(200)
      end
    end)

    CreateThread(function()
      while true do
        if not self.isDead then
          local ped = self.cache.ped
          local coords = GetEntityCoords(ped)
          --- @type string?
          local currentNearestKey = nil
          --- @type number?
          local currentNearestDist = nil

          for key, data in pairs(self.targetCoords) do
            local dist = #(coords - data.coords)

            if currentNearestKey == nil or (dist <= currentNearestDist) then
              currentNearestKey = key
              currentNearestDist = dist
            end

            if dist <= data.lodDist and (self.inCoords[key] ~= true) then
              self.inCoords[key] = true

              pcall(function() self:onEnter(key, data, dist) end)
            elseif dist > data.lodDist and (self.inCoords[key] == true) then
              self.inCoords[key] = false

              pcall(function() self:onExit(key) end)
            end
          end

          self.nearestTarget = currentNearestKey
          self.nearestDist = currentNearestDist
        end

        Wait(500)
      end
    end)

    AddEventHandler('esx:onPlayerDeath', function()
      self.isDead = true

      for key, value in pairs(self.targetCoords) do
        if value then
          self.inCoords[key] = false

          pcall(function()
            self:onExit(key)
          end)
        end
      end

      if self.progress.worker and not self.progress.workerTakeDamage then
        TriggerEvent('mythic_progbar:client:cancel')
      end
    end)

    AddEventHandler('esx:onPlayerSpawn', function()
      self.isDead = false
    end)

    AddEventHandler('gameEventTriggered', function(name, args)
      if name == 'CEventNetworkEntityDamage' then
        local victim = args[1]
        local attacker = args[2]
        local myPed = self.cache.ped

        if IsEntityAPed(attacker) and victim == myPed then
          if self.progress.worker and not self.progress.workerTakeDamage then
            TriggerEvent('mythic_progbar:client:cancel')
            ClearPedSecondaryTask(myPed)
          end
        end
      end
    end)
  end

  if async then
    CreateThread(loader)
  else
    loader()
  end
end
