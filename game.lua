-- Asteroids no Lupi. Este arquivo só monta o jogo; cada objeto mora em src/.

local Screen = require "screen"
local Input = require "input"
local Audio = require "audio"
local StarField = require "starfield"
local Asteroid = require "asteroid"
local Scoreboard = require "scoreboard"
local Machine = require("state").Machine
local Splash = require "states.splash"
local Story = require "states.story"
local Menu = require "states.menu"
local Scores = require "states.scores"
local Help = require "states.help"
local Credits = require "states.credits"
local Play = require "states.play"
local Over = require "states.over"
local Initials = require "states.initials"

local App = {}
App.__index = App

function App.new()
  local self = setmetatable({
    input = Input.new(),
    audio = Audio.new(),
    scores = Scoreboard.new(),
    decor = {},
  }, App)
  self.stars = StarField.new(40)
  for _ = 1, 6 do
    self.decor[#self.decor + 1] = Asteroid.random()
  end
  self.audio:music("menu", 28.9)
  self.machine = Machine.new({
    splash = Splash.new(self),
    story = Story.new(self),
    menu = Menu.new(self),
    scores = Scores.new(self),
    help = Help.new(self),
    credits = Credits.new(self),
    play = Play.new(self),
    over = Over.new(self),
    initials = Initials.new(self),
  }, "splash")
  return self
end

function App:update_decor()
  for i = 1, #self.decor do
    self.decor[i]:move()
  end
end

function App:draw_decor()
  for i = 1, #self.decor do
    self.decor[i]:draw()
  end
end

function App:update()
  Screen.apply()
  ui.camera()
  ui.clip()
  self.input:read()
  self.audio:tick()
  self.stars:update()
  self.machine:update()

  ui.cls(Screen.BLACK)
  self.stars:draw()
  self.machine:draw()
end

math.randomseed(os.time())
local app = App.new()

function update()
  app:update()
end
