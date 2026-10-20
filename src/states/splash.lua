local State = require("state").State
local Screen = require "screen"

local Splash = setmetatable({}, { __index = State })
Splash.__index = Splash

function Splash.new(app)
  local self = setmetatable(State.new(), Splash)
  self.app = app
  self.t = 0
  return self
end

function Splash:update()
  self.t = self.t + 1
  self.app:update_decor()
  if self.t > 120 or self.app.input:confirm() then
    self:go("story")
  end
end

function Splash:draw()
  self.app:draw_decor()
  Screen.print_c("POLYGON GAMES", Screen.H / 2 - 8, Screen.WHITE)
end

return Splash
