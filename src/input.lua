-- Controles. O runtime web não publica BTN_X; o número é o do gamepad do Lupi.

local Screen = require "screen"

local function pad(name, fallback)
  local value = rawget(_G, name)
  if type(value) == "number" then return value end
  return fallback
end

local Input = {}
Input.__index = Input

Input.LEFT = pad("LEFT", 4)
Input.RIGHT = pad("RIGHT", 2)
Input.UP = pad("UP", 1)
Input.DOWN = pad("DOWN", 3)
Input.SHOOT = pad("BTN_Z", 7)
Input.THRUST = pad("BTN_X", 6)

function Input.new()
  return setmetatable({
    down = false,
    edge = false,
    x = Screen.W / 2,
    y = Screen.H / 2,
    ok = false,
    last_x = nil,
    last_y = nil,
  }, Input)
end

function Input:held(id)
  return id ~= nil and ui.btn(id)
end

function Input:tapped(id)
  return id ~= nil and ui.btnp(id)
end

function Input:confirm()
  return self:tapped(Input.SHOOT) or self:tapped(Input.THRUST) or self.edge
end

function Input:moved()
  return self.ok and (self.x ~= self.last_x or self.y ~= self.last_y)
end

function Input:commit()
  self.last_x, self.last_y = self.x, self.y
end

function Input:read()
  self.ok = false
  self.edge = false
  if not (ui and ui.pointer) then
    self.down = false
    return
  end
  local x, y, shot, absolute = ui.pointer()
  local down = shot and true or false
  self.edge = down and not self.down
  self.down = down
  if x == nil then return end
  self.ok = true
  if absolute then
    self.x, self.y = x, y
  else
    self.x = self.x + x
    self.y = self.y + y
  end
  if self.x < 0 then self.x = 0 elseif self.x > Screen.W - 1 then self.x = Screen.W - 1 end
  if self.y < 0 then self.y = 0 elseif self.y > Screen.H - 1 then self.y = Screen.H - 1 end
end

return Input
