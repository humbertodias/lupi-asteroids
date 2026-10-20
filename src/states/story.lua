local State = require("state").State
local Screen = require "screen"

local Story = setmetatable({}, { __index = State })
Story.__index = Story

function Story.new(app)
  local self = setmetatable(State.new(), Story)
  self.app = app
  return self
end

function Story:update()
  self.app:update_decor()
  if self.app.input:confirm() then self:go("menu") end
end

function Story:draw()
  self.app:draw_decor()
  Screen.print_c("ASTEROIDS", 48, Screen.WHITE)
  Screen.print_c("LANCADO EM 1979, FOI O", 78, Screen.WHITE)
  Screen.print_c("ARCADE MAIS VENDIDO DA ATARI.", 90, Screen.WHITE)
  Screen.print_c("O RECORDE GUARDAVA AS INICIAIS", 102, Screen.WHITE)
  Screen.print_c("AO LADO DA PONTUACAO.", 114, Screen.WHITE)
  Screen.print_c("A OU B CONTINUA", Screen.H - 28, Screen.GREEN)
end

return Story
