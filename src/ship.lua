-- Nave. O nariz do sprite aponta para cima no ângulo 0.

local Screen = require "screen"
local Input = require "input"
local Bullet = require "bullet"
local Sprites = require "sprites"

local Ship = {}
Ship.__index = Ship

Ship.ACCEL = 0.025
Ship.ROTATE = 0.4
Ship.LOAD = 200
Ship.RELOAD = 100

function Ship.new(session, x, y)
  return setmetatable({
    session = session,
    x = x,
    y = y,
    vx = 0,
    vy = 0,
    angle = 0,
    load = Ship.LOAD,
    inv = 0,
    alive = true,
    thrusting = false,
    thrust_fx = 0,
  }, Ship)
end

function Ship:sprite()
  local frame = math.floor(self.angle / 22.5 + 0.5) % 16
  return Sprites.img.ship[string.format("a%02d", frame)]
end

function Ship:fire_sprite()
  local frame = math.floor(self.angle / 22.5 + 0.5) % 16
  return Sprites.img.fire[string.format("a%02d", frame)]
end

function Ship:accelerate()
  local real = math.rad(self.angle + 90)
  local radx = math.cos(real)
  local rady = -math.sin(real)
  local vx, vy = self.vx, self.vy
  if (rady < 0 and not (vy < -0.5)) or (rady > 0 and not (vy > 0.5)) then
    vy = vy + rady * Ship.ACCEL
  end
  if (radx < 0 and not (vx < -0.5)) or (radx > 0 and not (vx > 0.5)) then
    vx = vx + radx * Ship.ACCEL
  end
  self.vx, self.vy = vx, vy
end

function Ship:shoot()
  if self.load < Ship.RELOAD then return end
  local bullets = self.session.bullets
  bullets[#bullets + 1] = Bullet.new(self)
  self.load = 0
  self.session.app.audio:fx("shoot")
end

function Ship:explode()
  self.session.app.audio:fx("explosion")
  self.session:add_boom(self.x, self.y)
  if self.session.lives > 1 and self.alive then
    self.inv = 2000
    self.angle = 0
    self.vx, self.vy = 0, 0
    self.load = Ship.LOAD
    self.x, self.y = Screen.W / 2, Screen.H / 2
    self.session.lives = self.session.lives - 1
  else
    self.session.lives = 0
    self.alive = false
    self.session.over = true
  end
end

function Ship:visible()
  if self.inv <= 0 then return true end
  return math.floor(self.inv / 50) % 2 == 0
end

function Ship:aim(input)
  if not input:moved() then return false end
  local dx = input.x - self.x
  local dy = input.y - self.y
  if dx * dx + dy * dy <= 64 then return false end
  self.angle = math.deg(math.atan(-dy, dx)) - 90
  return true
end

function Ship:update()
  local input = self.session.app.input
  if not self:aim(input) then
    if input:held(Input.LEFT) then self.angle = self.angle + Ship.ROTATE * Screen.DT end
    if input:held(Input.RIGHT) then self.angle = self.angle - Ship.ROTATE * Screen.DT end
  end
  input:commit()
  self.angle = self.angle % 360

  self.thrusting = input:held(Input.UP) or input:held(Input.THRUST)
  if self.thrusting then
    self:accelerate()
    if self.thrust_fx <= 0 then
      self.session.app.audio:fx("thrust")
      self.thrust_fx = 50
    end
  end
  if self.thrust_fx > 0 then self.thrust_fx = self.thrust_fx - 1 end

  if input:held(Input.SHOOT) or input.down then self:shoot() end
  if self.load < Ship.LOAD then self.load = self.load + Screen.DT end
  if self.inv > 0 then self.inv = self.inv - Screen.DT end

  self.x = Screen.wrap(self.x + self.vx * Screen.DT * Screen.MOVE, Screen.W)
  self.y = Screen.wrap(self.y + self.vy * Screen.DT * Screen.MOVE, Screen.H)
end

function Ship:draw()
  if not self.alive or not self:visible() then return end
  if self.thrusting then
    Screen.draw_centered(self:fire_sprite(), self.x, self.y)
  end
  Screen.draw_centered(self:sprite(), self.x, self.y)
end

return Ship
