-- Placar da sessão. Os nomes padrão vêm do pygame, em ASCII.

local Screen = require "screen"

local Scoreboard = {}
Scoreboard.__index = Scoreboard

function Scoreboard.new()
  return setmetatable({
    rows = {
      { name = "LEONHARD EULER", points = 2000 },
      { name = "CARL GAUSS", points = 1500 },
      { name = "EVARISTE GALOIS", points = 1000 },
      { name = "GOTTFRIED LEIBNIZ", points = 900 },
      { name = "ISAAC NEWTON", points = 800 },
      { name = "ARQUIMEDES", points = 700 },
      { name = "AL-KHWARIZMI", points = 650 },
      { name = "EUCLIDES", points = 600 },
      { name = "HENRI POINCARE", points = 550 },
      { name = "RENE DESCARTES", points = 0 },
    },
  }, Scoreboard)
end

function Scoreboard:rank(value)
  for i = 1, #self.rows do
    if value > self.rows[i].points then return i end
  end
  return nil
end

function Scoreboard:insert(rank, name, points)
  table.insert(self.rows, rank, { name = name, points = points })
  table.remove(self.rows)
end

function Scoreboard:draw(highlight)
  Screen.print_c("PONTUACAO", 16, Screen.WHITE)
  ui.print("NOME", 48, 36, Screen.GREEN)
  local header = "PONTOS"
  ui.print(header, Screen.W - 48 - #header * 6, 36, Screen.GREEN)
  for i = 1, #self.rows do
    local row = self.rows[i]
    local color = (i == highlight) and Screen.GREEN or Screen.WHITE
    local y = 50 + (i - 1) * 16
    ui.print(tostring(i), 28, y, color)
    ui.print(row.name, 48, y, color)
    local points = Screen.format_score(row.points)
    ui.print(points, Screen.W - 48 - #points * 6, y, color)
  end
  Screen.print_c("A OU B VOLTA", Screen.H - 14, Screen.WHITE)
end

return Scoreboard
