-- Tiro. Some na borda, sem atravessar a tela.

local Screen = require "screen"
local Sprites = require "sprites"

local Bullet = {}
Bullet.__index = Bullet

function Bullet.new(ship)
  local real = math.rad(ship.angle + 90)
  return setmetatable({
    session = ship.session,
    x = ship.x,
    y = ship.y,
    vx = math.cos(real),
    vy = -math.sin(real),
    timer = 250,
    alive = true,
  }, Bullet)
end

function Bullet:update()
  self.timer = self.timer - Screen.DT
  self.x = self.x + self.vx * Screen.DT * Screen.MOVE
  self.y = self.y + self.vy * Screen.DT * Screen.MOVE
  if self.timer <= 0 or self.x < 0 or self.y < 0 or self.x >= Screen.W or self.y >= Screen.H then
    self.alive = false
    return
  end
  local rocks = self.session.rocks
  for i = 1, #rocks do
    local rock = rocks[i]
    if rock.alive then
      local reach = 3 + rock.size * 6
      if Screen.wrap_dist2(self.x, self.y, rock.x, rock.y) <= reach * reach then
        rock:split()
        self.alive = false
        return
      end
    end
  end
end

function Bullet:draw()
  if not self.alive then return end
  Screen.draw_centered(Sprites.img.bullet, self.x, self.y)
end

return Bullet
