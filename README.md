# 🍕 NS Core - An open source FiveM library

An open source library of fivem that will help your develop your resource easier. We provided some useful features like "waiting player to be loaded", "position coords calculation", "cache system"

### Usage
First, put `ns_core` to be started in server.cfg and then imports to your resource

```lua
client_script '@ns_core/lib/client.lua'
```

Start of using library

```lua
local activeCoords = {}

local app = lib.client:new(self, ESX)
  print('Is player loaded', ESX.IsPlayerLoaded()) -- Output: Is player loaded  true

  --- Add coords
  app:addCoords('test-coords', vec3(...), 50.0, 3.0)

  CreateThread(function()
    while true do
      if not self.isDead then
        local key, data, distance = self:getNearestCoords(3.0)

        if key == nil then
          Wait(2000)
        else
          if self:onKey('JustReleased', 38, true) then
            print('Press e') -- Output: Press e
          end
        end
      else
        Wait(2000)
      end

      Wait(0)
    end
  end)
end

function app:onEnter(key, data, currentDistance)
  print(key, json.encode(data, { indent = true }), currentDistance) -- Output: test-coords { coords: vector3(...), lodDist: ..., interactDist: ... } 53.35...
  activeCoords[key] = true
end

function app:onExit(key)
  print(key) -- Output: test-coords
  activeCoords[key] = false
end

app:start()
```

and remember that you need to start `es_extended` and `ox_lib` before `ns_core`

### Dependecies
- mythic_progbar (***optional**) (if you want to use progress bar function)

### Requirements
- es_extended
- ox_lib
