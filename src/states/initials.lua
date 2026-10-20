local State = require("state").State
local Input = require "input"
local Screen = require "screen"

local Initials = setmetatable({}, { __index = State })
Initials.__index = Initials

function Initials.new(app)
  local self = setmetatable(State.new(), Initials)
  self.app = app
  self.letters = { 1, 1, 1 }
  self.pos = 1
  return self
end

function Initials:startup(persist)
  self.rank = persist.rank
  self.score = persist.score
  self.letters = { 1, 1, 1 }
  self.pos = 1
end

function Initials:letter(i)
  local n = ((i - 1) % 26) + 1
  return Screen.ALPH:sub(n, n)
end

function Initials:update()
  local input = self.app.input
  if input:tapped(Input.LEFT) then
    self.letters[self.pos] = self.letters[self.pos] - 1
  elseif input:tapped(Input.RIGHT) then
    self.letters[self.pos] = self.letters[self.pos] + 1
  elseif input:confirm() then
    self.app.audio:fx("enter")
    if self.pos < 3 then
      self.pos = self.pos + 1
    else
      local name = self:letter(self.letters[1]) .. self:letter(self.letters[2]) .. self:letter(self.letters[3])
      self.app.scores:insert(self.rank, name, self.score)
      self:go("scores", { highlight = self.rank })
    end
  end
end

function Initials:draw()
  Screen.print_c("NOVO RECORDE", 70, Screen.GREEN)
  Screen.print_c(Screen.format_score(self.score), 86, Screen.WHITE)
  Screen.print_c("INICIAIS", 112, Screen.WHITE)
  local origin = math.floor(Screen.W / 2 - 16)
  for i = 1, 3 do
    local color = (i == self.pos) and Screen.GREEN or Screen.WHITE
    ui.print(self:letter(self.letters[i]), origin + (i - 1) * 12, 136, color)
  end
  Screen.print_c("ESQ DIR TROCA", 168, Screen.WHITE)
  Screen.print_c("B CONFIRMA", 182, Screen.WHITE)
end

return Initials
