local State = require("state").State
local Screen = require "screen"

local LINES = {
  "CREDITOS",
  "",
  "AUTOR",
  "HUMBERTO DIAS",
  "",
  "JOGOS DIGITAIS",
  "SENAC 2015/2",
  "",
  "IDE",
  "PYCHARM",
  "",
  "EDITOR GRAFICO",
  "GIMP",
  "",
  "EDITOR VETORIAL",
  "INKSCAPE",
  "",
  "EDITOR SONORO",
  "AUDACITY",
  "",
  "EFEITOS SONOROS",
  "FREESOUND",
  "",
  "IMAGENS",
  "SPRITERS-RESOURCE",
  "",
  "PORTADO PARA LUPI",
  "",
  "COPYRIGHT 2015",
}

local Credits = setmetatable({}, { __index = State })
Credits.__index = Credits

function Credits.new(app)
  local self = setmetatable(State.new(), Credits)
  self.app = app
  self.y = Screen.H
  return self
end

function Credits:startup()
  self.y = Screen.H
end

function Credits:update()
  self.y = self.y - 0.4
  if self.y < -#LINES * 12 then self.y = Screen.H end
  if self.app.input:confirm() then self:go("menu") end
end

function Credits:draw()
  for i = 1, #LINES do
    local y = math.floor(self.y + (i - 1) * 12)
    if y > -10 and y < Screen.H then
      Screen.print_c(LINES[i], y, Screen.WHITE)
    end
  end
end

return Credits
