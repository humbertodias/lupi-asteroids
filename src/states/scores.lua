local State = require("state").State

local Scores = setmetatable({}, { __index = State })
Scores.__index = Scores

function Scores.new(app)
  local self = setmetatable(State.new(), Scores)
  self.app = app
  self.highlight = nil
  return self
end

function Scores:startup(persist)
  self.highlight = persist and persist.highlight
end

function Scores:update()
  if self.app.input:confirm() then self:go("menu") end
end

function Scores:draw()
  self.app.scores:draw(self.highlight)
end

return Scores
