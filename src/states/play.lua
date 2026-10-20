local State = require("state").State
local Session = require "session"

local Play = setmetatable({}, { __index = State })
Play.__index = Play

function Play.new(app)
  local self = setmetatable(State.new(), Play)
  self.app = app
  return self
end

function Play:startup()
  self.session = Session.new(self.app)
  self.app.audio:fx("start")
  self.app.audio:music("game", 26.4)
end

function Play:update()
  self.session:update()
  if self.session.over then
    self:go("over", { session = self.session })
  end
end

function Play:draw()
  self.session:draw()
  self.session:draw_hud(true)
end

return Play
