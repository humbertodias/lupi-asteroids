-- Tela 480x270 e o desenho compartilhado pelos objetos.

require "palette"
if not Palette.hex then
  function Palette.hex(rgb)
    rgb = math.floor(tonumber(rgb) or 0)
    local r = math.floor(rgb / 65536) % 256
    local g = math.floor(rgb / 256) % 256
    local b = rgb % 256
    local target = math.floor(b / 8) * 1024 + math.floor(g / 8) * 32 + math.floor(r / 8)
    local function channel_dist(color)
      local cr = color % 32
      local cg = math.floor(color / 32) % 32
      local cb = math.floor(color / 1024) % 32
      local tr = target % 32
      local tg = math.floor(target / 32) % 32
      local tb = math.floor(target / 1024) % 32
      local dr, dg, db = cr - tr, cg - tg, cb - tb
      return dr * dr + dg * dg + db * db
    end
    local limit = #Palette
    if limit > 256 then limit = 256 end
    local best, best_d = 2, math.huge
    for i = 2, limit do
      local d = channel_dist(Palette[i])
      if d < best_d then
        best, best_d = i, d
        if d == 0 then break end
      end
    end
    return best - 1
  end
end

local Screen = {
  W = 480,
  H = 270,
  DT = 1000 / 60,
  MOVE = 0.55,
  ALPH = "ABCDEFGHIJKLMNOPQRSTUVWXYZ",
}

function Screen.apply()
  for i = 1, #Palette do
    ui.palset(i - 1, Palette[i])
  end
  Screen.WHITE = Palette.hex(0xFFFFFF)
  Screen.GREEN = Palette.hex(0x39FF6A)
  Screen.YELLOW = Palette.hex(0xFFE14A)
  Screen.BLACK = Palette.hex(0x000000)
end

function Screen.randint(lo, hi)
  return lo + math.random(hi - lo + 1) - 1
end

function Screen.wrap(v, limit)
  if v < 0 then return v + limit end
  if v >= limit then return v - limit end
  return v
end

function Screen.wrap_dist2(ax, ay, bx, by)
  local dx = ax - bx
  local dy = ay - by
  if dx > Screen.W / 2 then dx = dx - Screen.W elseif dx < -Screen.W / 2 then dx = dx + Screen.W end
  if dy > Screen.H / 2 then dy = dy - Screen.H elseif dy < -Screen.H / 2 then dy = dy + Screen.H end
  return dx * dx + dy * dy
end

function Screen.format_score(n)
  if n == math.floor(n) then return string.format("%d", n) end
  return string.format("%.1f", n)
end

function Screen.print_c(text, y, color)
  ui.print(text, math.floor((Screen.W - #text * 6) / 2), y, color)
end

function Screen.draw_centered(spr, cx, cy)
  if not spr then return end
  local x = cx - spr.width / 2
  local y = cy - spr.height / 2
  local function blit(px, py)
    ui.spr(spr, math.floor(px), math.floor(py), false)
  end
  blit(x, y)
  local left = x < 0
  local right = x + spr.width > Screen.W
  local up = y < 0
  local down = y + spr.height > Screen.H
  if left then blit(x + Screen.W, y) end
  if right then blit(x - Screen.W, y) end
  if up then blit(x, y + Screen.H) end
  if down then blit(x, y - Screen.H) end
  if left and up then blit(x + Screen.W, y + Screen.H) end
  if left and down then blit(x + Screen.W, y - Screen.H) end
  if right and up then blit(x - Screen.W, y + Screen.H) end
  if right and down then blit(x - Screen.W, y - Screen.H) end
end

return Screen
