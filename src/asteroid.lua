-- Asteroide. Tamanho 3 é o maior; ao quebrar, vira dois do tamanho abaixo.

local Screen = require "screen"
local Sprites = require "sprites"

local Asteroid = {}
Asteroid.__index = Asteroid

local function axis(size, cap, trig)
  local sign = (Screen.randint(0, 1) == 0) and -1 or 1
  local v = sign * ((Screen.randint(0, 69) + 5) / (80 + 30 * size)) * trig
  if v < -cap then v = -cap end
  if v > cap then v = cap end
  return v
end

function Asteroid.new(x, y, size, color, angle, session)
  local real = math.rad(angle)
  local cap = 0.5 / size
  return setmetatable({
    session = session,
    x = x,
    y = y,
    vx = axis(size, cap, math.cos(real)),
    vy = axis(size, cap, math.sin(real)),
    size = size,
    color = color,
    rot = math.floor(angle / 45 + 0.5) % 8,
    alive = true,
  }, Asteroid)
end

function Asteroid.random(size, session)
  return Asteroid.new(
    Screen.randint(0, Screen.W - 1),
    Screen.randint(0, Screen.H - 1),
    size or Screen.randint(1, 3),
    Screen.randint(0, 7),
    Screen.randint(1, 359),
    session)
end

function Asteroid:sprite()
  local key = string.format("c%ds%dr%d", self.color, self.size, self.rot)
  return Sprites.img.rock[key]
end

function Asteroid:move()
  local step = 0.5 * Screen.DT * Screen.MOVE
  self.x = Screen.wrap(self.x + step * self.vx / (self.size + 1), Screen.W)
  self.y = Screen.wrap(self.y + step * self.vy / (self.size + 1), Screen.H)
end

function Asteroid:split()
  local session = self.session
  if self.size > 1 then
    session.score = session.score + 15 / self.size
    session.app.audio:fx("hit")
    for _ = 1, 2 do
      local nx = Screen.wrap(self.x + Screen.randint(-10, 10), Screen.W)
      local ny = Screen.wrap(self.y + Screen.randint(-10, 10), Screen.H)
      local rocks = session.rocks
      rocks[#rocks + 1] = Asteroid.new(nx, ny, self.size - 1, self.color, Screen.randint(1, 359), session)
    end
  else
    session.score = session.score + 5 / self.size
  end
  self.alive = false
end

function Asteroid:draw()
  if self.alive == false then return end
  Screen.draw_centered(self:sprite(), self.x, self.y)
end

return Asteroid
