local State = require("state").State
local Screen = require "screen"

local Help = setmetatable({}, { __index = State })
Help.__index = Help

function Help.new(app)
  local self = setmetatable(State.new(), Help)
  self.app = app
  return self
end

function Help:update()
  if self.app.input:confirm() then self:go("menu") end
end

function Help:draw()
  Screen.print_c("COMO JOGAR", 28, Screen.WHITE)
  ui.print("GIRAR", 48, 62, Screen.GREEN)
  ui.print("ESQ DIR", 160, 62, Screen.WHITE)
  ui.print("A D", 300, 62, Screen.WHITE)
  ui.print("ACELERAR", 48, 78, Screen.GREEN)
  ui.print("CIMA A", 160, 78, Screen.WHITE)
  ui.print("W J", 300, 78, Screen.WHITE)
  ui.print("ATIRAR", 48, 94, Screen.GREEN)
  ui.print("B", 160, 94, Screen.WHITE)
  ui.print("K", 300, 94, Screen.WHITE)
  ui.print("MIRAR", 48, 110, Screen.GREEN)
  ui.print("MOUSE", 160, 110, Screen.WHITE)
  Screen.print_c("ASTEROIDES GRANDES SE PARTEM.", 146, Screen.WHITE)
  Screen.print_c("A NAVE ATRAVESSA AS BORDAS.", 160, Screen.WHITE)
  Screen.print_c("A OU B VOLTA", Screen.H - 14, Screen.WHITE)
end

return Help
