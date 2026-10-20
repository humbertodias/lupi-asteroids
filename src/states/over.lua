local State = require("state").State
local Screen = require "screen"

local Over = setmetatable({}, { __index = State })
Over.__index = Over

function Over.new(app)
  local self = setmetatable(State.new(), Over)
  self.app = app
  return self
end

function Over:startup(persist)
  self.session = persist.session
  self.t = 90
  self.rank = nil
end

function Over:update()
  self.session:tick_booms()
  if self.t > 0 then
    self.t = self.t - 1
    return
  end
  if self.rank == nil then
    self.rank = self.app.scores:rank(self.session.score) or false
  end
  if self.rank then
    self:go("initials", { rank = self.rank, score = self.session.score })
    return
  end
  if self.app.input:confirm() then self:go("menu") end
end

function Over:draw()
  self.session:draw()
  self.session:draw_hud(false)
  Screen.print_c("FIM DE JOGO", Screen.H / 2 - 16, Screen.WHITE)
  Screen.print_c(Screen.format_score(self.session.score), Screen.H / 2, Screen.WHITE)
  if self.t <= 0 and not self.rank then
    Screen.print_c("A OU B", Screen.H / 2 + 20, Screen.GREEN)
  end
end

return Over
