-- Campo de estrelas atrás de todas as telas.

local Screen = require "screen"

local StarField = {}
StarField.__index = StarField

function StarField.new(count)
  local self = setmetatable({ stars = {} }, StarField)
  for i = 1, count do
    self.stars[i] = {
      x = Screen.randint(0, Screen.W - 1),
      y = Screen.randint(0, Screen.H - 1),
      speed = (i % 3) * 0.15 + 0.15,
    }
  end
  return self
end

function StarField:update()
  for i = 1, #self.stars do
    local star = self.stars[i]
    star.x = star.x - star.speed
    if star.x < 0 then
      star.x = Screen.W - 1
      star.y = Screen.randint(0, Screen.H - 1)
    end
  end
end

function StarField:draw()
  for i = 1, #self.stars do
    local star = self.stars[i]
    local x, y = math.floor(star.x), math.floor(star.y)
    ui.rectfill(x, y, x + 1, y + 1, Screen.WHITE)
  end
end

return StarField
