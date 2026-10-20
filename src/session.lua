-- Uma partida: onda, nave, tiros e placar da vida.

local Screen = require "screen"
local Ship = require "ship"
local Asteroid = require "asteroid"
local Explosion = require "explosion"
local Sprites = require "sprites"

local WAVE = {
  { x = 47, y = 35, size = 2, color = 0 },
  { x = 70, y = 53, size = 1, color = 1 },
  { x = 141, y = 70, size = 1, color = 2 },
  { x = 23, y = 18, size = 1, color = 3 },
}

local Session = {}
Session.__index = Session

function Session.new(app)
  local self = setmetatable({
    app = app,
    score = 0,
    lives = 3,
    level = 1,
    level_left = 500,
    rocks = {},
    bullets = {},
    booms = {},
    over = false,
  }, Session)
  self.ship = Ship.new(self, Screen.W / 2, Screen.H / 2)
  return self
end

function Session:spawn_wave()
  for i = 1, #WAVE do
    local spec = WAVE[i]
    local rocks = self.rocks
    rocks[#rocks + 1] = Asteroid.new(spec.x, spec.y, spec.size, spec.color, Screen.randint(1, 359), self)
  end
  for _ = 1, self.level - 1 do
    local rocks = self.rocks
    rocks[#rocks + 1] = Asteroid.random(3, self)
  end
end

function Session:add_boom(x, y)
  self.booms[#self.booms + 1] = Explosion.new(x, y)
end

function Session:compact(list)
  local n = 1
  for i = 1, #list do
    if list[i].alive then
      list[n] = list[i]
      n = n + 1
    end
  end
  for i = n, #list do list[i] = nil end
end

function Session:tick_booms()
  local n = 1
  for i = 1, #self.booms do
    if self.booms[i]:tick() then
      self.booms[n] = self.booms[i]
      n = n + 1
    end
  end
  for i = n, #self.booms do self.booms[i] = nil end
end

function Session:collide_ship()
  local ship = self.ship
  if not ship.alive or ship.inv > 0 then return end
  for i = 1, #self.rocks do
    local rock = self.rocks[i]
    if rock.alive then
      local reach = 9 + rock.size * 6
      if Screen.wrap_dist2(ship.x, ship.y, rock.x, rock.y) <= reach * reach then
        rock:split()
        ship:explode()
        return
      end
    end
  end
end

function Session:update()
  if self.ship.alive then self.ship:update() end
  for i = 1, #self.rocks do
    if self.rocks[i].alive then self.rocks[i]:move() end
  end
  for i = 1, #self.bullets do
    if self.bullets[i].alive then self.bullets[i]:update() end
  end
  if not self.over then self:collide_ship() end
  self:compact(self.rocks)
  self:compact(self.bullets)
  self:tick_booms()
  if self.over then return end
  if self.level_left > 0 then
    self.level_left = self.level_left - Screen.DT
    if self.level_left <= 0 then self:spawn_wave() end
  elseif #self.rocks == 0 then
    self.level = self.level + 1
    self.level_left = 500
  end
end

function Session:draw()
  for i = 1, #self.rocks do self.rocks[i]:draw() end
  for i = 1, #self.bullets do self.bullets[i]:draw() end
  self.ship:draw()
  for i = 1, #self.booms do self.booms[i]:draw() end
end

function Session:draw_hud(show_wave)
  local life = Sprites.img.life
  for i = 1, self.lives do
    ui.spr(life, 8 + (i - 1) * 20, 8, false)
  end
  ui.print("PONTOS", Screen.W - 8 - 6 * 6, 8, Screen.WHITE)
  local text = Screen.format_score(self.score)
  ui.print(text, Screen.W - 8 - #text * 6, 18, Screen.WHITE)
  Screen.print_c("ASTEROIDES: " .. tostring(#self.rocks), Screen.H - 12, Screen.WHITE)
  if show_wave and self.level_left > 0 then
    Screen.print_c("ONDA " .. tostring(self.level), Screen.H / 2 - 4, Screen.WHITE)
  end
end

return Session
