-- Explosão da nave. O sprite fica na tela por 18 frames.

local Screen = require "screen"
local Sprites = require "sprites"

local Explosion = {}
Explosion.__index = Explosion

function Explosion.new(x, y)
  return setmetatable({ x = x, y = y, t = 18 }, Explosion)
end

function Explosion:tick()
  self.t = self.t - 1
  return self.t > 0
end

function Explosion:draw()
  Screen.draw_centered(Sprites.img.boom, self.x, self.y)
end

return Explosion
