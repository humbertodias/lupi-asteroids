-- Efeitos e as duas músicas em loop.

local Audio = {}
Audio.__index = Audio

function Audio.new()
  return setmetatable({ name = nil, left = 0 }, Audio)
end

function Audio:fx(name)
  if sfx and sfx.fx then sfx.fx("sfx/" .. name) end
end

function Audio:music(name, seconds)
  if self.name == name and self.left > 30 then return end
  self.name = name
  self.left = math.floor((seconds or 26) * 60)
  if sfx and sfx.music then sfx.music("sfx/" .. name) end
end

function Audio:tick()
  if not self.name or self.left <= 0 then return end
  self.left = self.left - 1
  if self.left <= 0 then
    local name = self.name
    self:music(name, name == "game" and 26.4 or 28.9)
  end
end

return Audio
