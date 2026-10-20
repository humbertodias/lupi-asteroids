-- Asteroids for the Lupi console (480x270, 60 fps).
-- Left and right rotate the ship. Up or A thrusts. B shoots.
-- The pointer aims the ship, and the left button shoots.

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
local Sprites = require "sprites"

local W, H = 480, 270
local DT = 1000 / 60
local MOVE = 0.55
local ALPH = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"

local WHITE, GREEN, YELLOW, BLACK

local function apply_palette()
  for i = 1, #Palette do
    ui.palset(i - 1, Palette[i])
  end
  WHITE = Palette.hex(0xFFFFFF)
  GREEN = Palette.hex(0x39FF6A)
  YELLOW = Palette.hex(0xFFE14A)
  BLACK = Palette.hex(0x000000)
end

local function randint(lo, hi)
  return lo + math.random(hi - lo + 1) - 1
end

local function wrap(v, limit)
  if v < 0 then return v + limit end
  if v >= limit then return v - limit end
  return v
end

local function wrap_dist2(ax, ay, bx, by)
  local dx = ax - bx
  local dy = ay - by
  if dx > W / 2 then dx = dx - W elseif dx < -W / 2 then dx = dx + W end
  if dy > H / 2 then dy = dy - H elseif dy < -H / 2 then dy = dy + H end
  return dx * dx + dy * dy
end

local function format_score(n)
  if n == math.floor(n) then return string.format("%d", n) end
  return string.format("%.1f", n)
end

local function print_c(text, y, color)
  ui.print(text, math.floor((W - #text * 6) / 2), y, color)
end

local function fx(name)
  if sfx and sfx.fx then sfx.fx("sfx/" .. name) end
end

local music_name, music_left = nil, 0

local function start_music(name, seconds)
  if music_name == name and music_left > 30 then return end
  music_name = name
  music_left = math.floor((seconds or 26) * 60)
  if sfx and sfx.music then sfx.music("sfx/" .. name) end
end

local function tick_music()
  if not music_name or music_left <= 0 then return end
  music_left = music_left - 1
  if music_left <= 0 then
    start_music(music_name, music_name == "game" and 26.4 or 28.9)
  end
end

local pointer_down = false
local pointer_edge = false
local cursor_x, cursor_y = W / 2, H / 2
local cursor_ok = false

local function read_pointer()
  cursor_ok = false
  pointer_edge = false
  if not (ui and ui.pointer) then
    pointer_down = false
    return
  end
  local x, y, shot, absolute = ui.pointer()
  local down = shot and true or false
  pointer_edge = down and not pointer_down
  pointer_down = down
  if x == nil then return end
  cursor_ok = true
  if absolute then
    cursor_x, cursor_y = x, y
  else
    cursor_x = cursor_x + x
    cursor_y = cursor_y + y
  end
  if cursor_x < 0 then cursor_x = 0 elseif cursor_x > W - 1 then cursor_x = W - 1 end
  if cursor_y < 0 then cursor_y = 0 elseif cursor_y > H - 1 then cursor_y = H - 1 end
end

-- The web runtime does not publish BTN_X. The ids match lupinho's gamepad map.
local function pad(name, fallback)
  local value = rawget(_G, name)
  if type(value) == "number" then return value end
  return fallback
end

local PAD_LEFT = pad("LEFT", 4)
local PAD_RIGHT = pad("RIGHT", 2)
local PAD_UP = pad("UP", 1)
local PAD_DOWN = pad("DOWN", 3)
local PAD_SHOOT = pad("BTN_Z", 7)
local PAD_THRUST = pad("BTN_X", 6)

local function held(id)
  return id ~= nil and ui.btn(id)
end

local function tapped(id)
  return id ~= nil and ui.btnp(id)
end

local function confirm()
  return tapped(PAD_SHOOT) or tapped(PAD_THRUST) or pointer_edge
end

local function draw_centered(spr, cx, cy)
  if not spr then return end
  local x = cx - spr.width / 2
  local y = cy - spr.height / 2
  local function blit(px, py)
    ui.spr(spr, math.floor(px), math.floor(py), false)
  end
  blit(x, y)
  local left = x < 0
  local right = x + spr.width > W
  local up = y < 0
  local down = y + spr.height > H
  if left then blit(x + W, y) end
  if right then blit(x - W, y) end
  if up then blit(x, y + H) end
  if down then blit(x, y - H) end
  if left and up then blit(x + W, y + H) end
  if left and down then blit(x + W, y - H) end
  if right and up then blit(x - W, y + H) end
  if right and down then blit(x - W, y - H) end
end

local function ship_sprite(angle)
  local frame = math.floor(angle / 22.5 + 0.5) % 16
  return Sprites.img.ship[string.format("a%02d", frame)]
end

local function fire_sprite(angle)
  local frame = math.floor(angle / 22.5 + 0.5) % 16
  return Sprites.img.fire[string.format("a%02d", frame)]
end

local function rock_sprite(rock)
  local key = string.format("c%ds%dr%d", rock.color, rock.size, rock.rot)
  return Sprites.img.rock[key]
end

local function rock_velocity(size, angle)
  local real = math.rad(angle)
  local cap = 0.5 / size
  local function axis(trig)
    local sign = (randint(0, 1) == 0) and -1 or 1
    local v = sign * ((randint(0, 69) + 5) / (80 + 30 * size)) * trig
    if v < -cap then v = -cap end
    if v > cap then v = cap end
    return v
  end
  return axis(math.cos(real)), axis(math.sin(real))
end

local function make_rock(x, y, size, color, angle)
  local vx, vy = rock_velocity(size, angle)
  return {
    x = x, y = y, vx = vx, vy = vy,
    size = size, color = color,
    rot = math.floor(angle / 45 + 0.5) % 8,
    alive = true,
  }
end

local WAVE = {
  { x = 47, y = 35, size = 2, color = 0 },
  { x = 70, y = 53, size = 1, color = 1 },
  { x = 141, y = 70, size = 1, color = 2 },
  { x = 23, y = 18, size = 1, color = 3 },
}

local hiscore = {
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
}

local MENU = { "JOGAR", "PLACAR", "COMO JOGAR", "CREDITOS" }
local CREDITS = {
  "CREDITOS",
  "",
  "AUTOR",
  "HUMBERTO DIAS",
  "",
  "JOGOS DIGITAIS",
  "SENAC 2015/2",
  "",
  "IDE",
  "PYCHARM",
  "",
  "EDITOR GRAFICO",
  "GIMP",
  "",
  "EDITOR VETORIAL",
  "INKSCAPE",
  "",
  "EDITOR SONORO",
  "AUDACITY",
  "",
  "EFEITOS SONOROS",
  "FREESOUND",
  "",
  "IMAGENS",
  "SPRITERS-RESOURCE",
  "",
  "PORTADO PARA LUPI",
  "",
  "COPYRIGHT 2015",
}

local phase = "splash"
local splash_t = 0
local menu_i = 1
local title_x = -80
local credit_y = H
local score_highlight = nil
local last_cursor_x, last_cursor_y = nil, nil

local stars = {}
local decor = {}
local rocks = {}
local bullets = {}
local booms = {}
local ship
local score = 0
local lives = 3
local level = 1
local level_left = 500
local thrust_on = false
local over_t = 0
local rank = nil
local init_n = { 1, 1, 1 }
local init_pos = 1

local function score_rank(value)
  for i = 1, #hiscore do
    if value > hiscore[i].points then return i end
  end
  return nil
end

local function spawn_wave()
  for i = 1, #WAVE do
    local spec = WAVE[i]
    rocks[#rocks + 1] = make_rock(spec.x, spec.y, spec.size, spec.color, randint(1, 359))
  end
  for _ = 1, level - 1 do
    rocks[#rocks + 1] = make_rock(randint(0, W - 1), randint(0, H - 1), 3, randint(0, 7), randint(1, 359))
  end
end

local function begin_play()
  score = 0
  lives = 3
  level = 1
  level_left = 500
  rocks = {}
  bullets = {}
  booms = {}
  ship = {
    x = W / 2, y = H / 2, vx = 0, vy = 0, angle = 0,
    load = 200, inv = 0, alive = true,
  }
  thrust_on = false
  phase = "play"
  fx("start")
  start_music("game", 26.4)
end

local function go_menu()
  phase = "menu"
  menu_i = 1
  start_music("menu", 28.9)
end

local function split_rock(rock)
  if rock.size > 1 then
    score = score + 15 / rock.size
    fx("hit")
    for _ = 1, 2 do
      local nx = wrap(rock.x + randint(-10, 10), W)
      local ny = wrap(rock.y + randint(-10, 10), H)
      rocks[#rocks + 1] = make_rock(nx, ny, rock.size - 1, rock.color, randint(1, 359))
    end
  else
    score = score + 5 / rock.size
  end
  rock.alive = false
end

local function explode_ship()
  fx("explosion")
  booms[#booms + 1] = { x = ship.x, y = ship.y, t = 18 }
  if lives > 1 and ship.alive then
    ship.inv = 2000
    ship.angle = 0
    ship.vx, ship.vy = 0, 0
    ship.load = 200
    ship.x, ship.y = W / 2, H / 2
    lives = lives - 1
  else
    lives = 0
    ship.alive = false
    phase = "over"
    over_t = 90
    rank = nil
  end
end

local function accelerate(angle)
  local real = math.rad(angle + 90)
  local radx = math.cos(real)
  local rady = -math.sin(real)
  local vx, vy = ship.vx, ship.vy
  if (rady < 0 and not (vy < -0.5)) or (rady > 0 and not (vy > 0.5)) then
    vy = vy + rady * 0.025
  end
  if (radx < 0 and not (vx < -0.5)) or (radx > 0 and not (vx > 0.5)) then
    vx = vx + radx * 0.025
  end
  ship.vx, ship.vy = vx, vy
end

local function shoot()
  if ship.load < 100 then return end
  local real = math.rad(ship.angle + 90)
  bullets[#bullets + 1] = {
    x = ship.x,
    y = ship.y,
    vx = math.cos(real),
    vy = -math.sin(real),
    timer = 250,
    alive = true,
  }
  ship.load = 0
  fx("shoot")
end

local function ship_visible()
  if ship.inv <= 0 then return true end
  return math.floor(ship.inv / 50) % 2 == 0
end

local function update_ship()
  local aimed = false
  if cursor_ok and (cursor_x ~= last_cursor_x or cursor_y ~= last_cursor_y) then
    local dx = cursor_x - ship.x
    local dy = cursor_y - ship.y
    if dx * dx + dy * dy > 64 then
      ship.angle = math.deg(math.atan(-dy, dx)) - 90
      aimed = true
    end
  end
  last_cursor_x, last_cursor_y = cursor_x, cursor_y

  if not aimed then
    if held(PAD_LEFT) then ship.angle = ship.angle + 0.4 * DT end
    if held(PAD_RIGHT) then ship.angle = ship.angle - 0.4 * DT end
  end
  ship.angle = ship.angle % 360

  thrust_on = held(PAD_UP) or held(PAD_THRUST)
  if thrust_on then
    accelerate(ship.angle)
    if ship.thrust_fx == nil or ship.thrust_fx <= 0 then
      fx("thrust")
      ship.thrust_fx = 50
    end
  end
  if ship.thrust_fx and ship.thrust_fx > 0 then
    ship.thrust_fx = ship.thrust_fx - 1
  end

  if held(PAD_SHOOT) or pointer_down then shoot() end
  if ship.load < 200 then ship.load = ship.load + DT end
  if ship.inv > 0 then ship.inv = ship.inv - DT end

  ship.x = wrap(ship.x + ship.vx * DT * MOVE, W)
  ship.y = wrap(ship.y + ship.vy * DT * MOVE, H)
end

local function update_rocks()
  for i = 1, #rocks do
    local rock = rocks[i]
    if rock.alive then
      rock.x = wrap(rock.x + 0.5 * DT * MOVE * rock.vx / (rock.size + 1), W)
      rock.y = wrap(rock.y + 0.5 * DT * MOVE * rock.vy / (rock.size + 1), H)
    end
  end
end

local function update_bullets()
  for i = 1, #bullets do
    local b = bullets[i]
    if b.alive then
      b.timer = b.timer - DT
      b.x = b.x + b.vx * DT * MOVE
      b.y = b.y + b.vy * DT * MOVE
      if b.timer <= 0 or b.x < 0 or b.y < 0 or b.x >= W or b.y >= H then
        b.alive = false
      else
        for j = 1, #rocks do
          local rock = rocks[j]
          if rock.alive then
            local reach = 3 + rock.size * 6
            if wrap_dist2(b.x, b.y, rock.x, rock.y) <= reach * reach then
              split_rock(rock)
              b.alive = false
              break
            end
          end
        end
      end
    end
  end
end

local function collide_ship()
  if not ship.alive or ship.inv > 0 then return end
  for i = 1, #rocks do
    local rock = rocks[i]
    if rock.alive then
      local reach = 9 + rock.size * 6
      if wrap_dist2(ship.x, ship.y, rock.x, rock.y) <= reach * reach then
        split_rock(rock)
        explode_ship()
        return
      end
    end
  end
end

local function compact(list)
  local n = 1
  for i = 1, #list do
    if list[i].alive then
      list[n] = list[i]
      n = n + 1
    end
  end
  for i = n, #list do list[i] = nil end
end

local function tick_booms()
  local n = 1
  for i = 1, #booms do
    booms[i].t = booms[i].t - 1
    if booms[i].t > 0 then
      booms[n] = booms[i]
      n = n + 1
    end
  end
  for i = n, #booms do booms[i] = nil end
end

local function update_decor()
  for i = 1, #decor do
    local rock = decor[i]
    rock.x = wrap(rock.x + 0.5 * DT * MOVE * rock.vx / (rock.size + 1), W)
    rock.y = wrap(rock.y + 0.5 * DT * MOVE * rock.vy / (rock.size + 1), H)
  end
end

local function update_splash()
  splash_t = splash_t + 1
  update_decor()
  if splash_t > 120 or confirm() then
    phase = "story"
  end
end

local function update_story()
  update_decor()
  if confirm() then go_menu() end
end

local function update_menu()
  update_decor()
  local target = (W - #"ASTEROIDES" * 6) / 2
  if title_x < target then title_x = title_x + 4 end

  if cursor_ok and (cursor_x ~= last_cursor_x or cursor_y ~= last_cursor_y) then
    for i = 1, #MENU do
      local y = 118 + (i - 1) * 16
      if cursor_y >= y - 2 and cursor_y < y + 12 then
        if menu_i ~= i then fx("hover") end
        menu_i = i
      end
    end
  end
  last_cursor_x, last_cursor_y = cursor_x, cursor_y

  if tapped(PAD_UP) then
    menu_i = menu_i - 1
    if menu_i < 1 then menu_i = #MENU end
    fx("hover")
  elseif tapped(PAD_DOWN) then
    menu_i = menu_i + 1
    if menu_i > #MENU then menu_i = 1 end
    fx("hover")
  elseif confirm() then
    fx("enter")
    local item = MENU[menu_i]
    if item == "JOGAR" then
      begin_play()
    elseif item == "PLACAR" then
      score_highlight = nil
      phase = "scores"
    elseif item == "COMO JOGAR" then
      phase = "help"
    else
      credit_y = H
      phase = "credits"
    end
  end
end

local function update_scores()
  if confirm() then go_menu() end
end

local function update_help()
  if confirm() then go_menu() end
end

local function update_credits()
  credit_y = credit_y - 0.4
  if credit_y < -#CREDITS * 12 then credit_y = H end
  if confirm() then go_menu() end
end

local function update_play()
  if ship.alive then update_ship() end
  update_rocks()
  update_bullets()
  if phase == "play" then collide_ship() end
  compact(rocks)
  compact(bullets)
  tick_booms()

  if phase ~= "play" then return end

  if level_left > 0 then
    level_left = level_left - DT
    if level_left <= 0 then spawn_wave() end
  elseif #rocks == 0 then
    level = level + 1
    level_left = 500
  end
end

local function update_over()
  tick_booms()
  if over_t > 0 then
    over_t = over_t - 1
    return
  end
  if rank == nil then
    rank = score_rank(score) or false
  end
  if rank then
    init_n = { 1, 1, 1 }
    init_pos = 1
    phase = "initials"
    return
  end
  if confirm() then go_menu() end
end

local function letter(i)
  local n = ((i - 1) % 26) + 1
  return ALPH:sub(n, n), n
end

local function update_initials()
  if tapped(PAD_LEFT) then
    init_n[init_pos] = init_n[init_pos] - 1
  elseif tapped(PAD_RIGHT) then
    init_n[init_pos] = init_n[init_pos] + 1
  elseif confirm() then
    fx("enter")
    if init_pos < 3 then
      init_pos = init_pos + 1
    else
      local name = letter(init_n[1]) .. letter(init_n[2]) .. letter(init_n[3])
      table.insert(hiscore, rank, { name = name, points = score })
      table.remove(hiscore)
      score_highlight = rank
      phase = "scores"
    end
  end
end

local function update_stars()
  for i = 1, #stars do
    local s = stars[i]
    s.x = s.x - s.speed
    if s.x < 0 then
      s.x = W - 1
      s.y = randint(0, H - 1)
    end
  end
end

local function draw_stars()
  for i = 1, #stars do
    local s = stars[i]
    local x, y = math.floor(s.x), math.floor(s.y)
    ui.rectfill(x, y, x + 1, y + 1, WHITE)
  end
end

local function draw_rocks(list)
  for i = 1, #list do
    local rock = list[i]
    if rock.alive ~= false then
      draw_centered(rock_sprite(rock), rock.x, rock.y)
    end
  end
end

local function draw_world()
  draw_rocks(rocks)
  for i = 1, #bullets do
    local b = bullets[i]
    if b.alive then draw_centered(Sprites.img.bullet, b.x, b.y) end
  end
  if ship and ship.alive and ship_visible() then
    if thrust_on then draw_centered(fire_sprite(ship.angle), ship.x, ship.y) end
    draw_centered(ship_sprite(ship.angle), ship.x, ship.y)
  end
  for i = 1, #booms do
    draw_centered(Sprites.img.boom, booms[i].x, booms[i].y)
  end
end

local function draw_hud()
  local life = Sprites.img.life
  for i = 1, lives do
    ui.spr(life, 8 + (i - 1) * 20, 8, false)
  end
  ui.print("PONTOS", W - 8 - 6 * 6, 8, WHITE)
  local text = format_score(score)
  ui.print(text, W - 8 - #text * 6, 18, WHITE)
  local count = "ASTEROIDES: " .. tostring(#rocks)
  print_c(count, H - 12, WHITE)
  if level_left > 0 and phase == "play" then
    print_c("ONDA " .. tostring(level), H / 2 - 4, WHITE)
  end
end

local function draw_menu()
  ui.print("ASTEROIDES", math.floor(title_x), 48, WHITE)
  for i = 1, #MENU do
    local y = 118 + (i - 1) * 16
    local label = MENU[i]
    local color = (i == menu_i) and GREEN or WHITE
    ui.print(label, math.floor((W - #label * 6) / 2), y, color)
  end
  local author = "HUMBERTO DIAS"
  ui.print(author, W - 8 - #author * 6, H - 14, WHITE)
end

local function draw_scores()
  print_c("PONTUACAO", 16, WHITE)
  ui.print("NOME", 48, 36, GREEN)
  local header = "PONTOS"
  ui.print(header, W - 48 - #header * 6, 36, GREEN)
  for i = 1, #hiscore do
    local row = hiscore[i]
    local color = (i == score_highlight) and GREEN or WHITE
    local y = 50 + (i - 1) * 16
    ui.print(tostring(i), 28, y, color)
    ui.print(row.name, 48, y, color)
    local points = format_score(row.points)
    ui.print(points, W - 48 - #points * 6, y, color)
  end
  print_c("A OU B VOLTA", H - 14, WHITE)
end

local function draw_help()
  print_c("COMO JOGAR", 28, WHITE)
  ui.print("GIRAR", 48, 62, GREEN)
  ui.print("ESQ DIR", 160, 62, WHITE)
  ui.print("A D", 300, 62, WHITE)
  ui.print("ACELERAR", 48, 78, GREEN)
  ui.print("CIMA A", 160, 78, WHITE)
  ui.print("W J", 300, 78, WHITE)
  ui.print("ATIRAR", 48, 94, GREEN)
  ui.print("B", 160, 94, WHITE)
  ui.print("K", 300, 94, WHITE)
  ui.print("MIRAR", 48, 110, GREEN)
  ui.print("MOUSE", 160, 110, WHITE)
  print_c("ASTEROIDES GRANDES SE PARTEM.", 146, WHITE)
  print_c("A NAVE ATRAVESSA AS BORDAS.", 160, WHITE)
  print_c("A OU B VOLTA", H - 14, WHITE)
end

local function draw_credits()
  for i = 1, #CREDITS do
    local y = math.floor(credit_y + (i - 1) * 12)
    if y > -10 and y < H then
      print_c(CREDITS[i], y, WHITE)
    end
  end
end

local function draw_initials()
  print_c("NOVO RECORDE", 70, GREEN)
  print_c(format_score(score), 86, WHITE)
  print_c("INICIAIS", 112, WHITE)
  local origin = math.floor(W / 2 - 16)
  for i = 1, 3 do
    local c = letter(init_n[i])
    local color = (i == init_pos) and GREEN or WHITE
    ui.print(c, origin + (i - 1) * 12, 136, color)
  end
  print_c("ESQ DIR TROCA", 168, WHITE)
  print_c("B CONFIRMA", 182, WHITE)
end

function update()
  apply_palette()
  ui.camera()
  ui.clip()
  read_pointer()
  tick_music()
  update_stars()

  if phase == "splash" then
    update_splash()
  elseif phase == "story" then
    update_story()
  elseif phase == "menu" then
    update_menu()
  elseif phase == "scores" then
    update_scores()
  elseif phase == "help" then
    update_help()
  elseif phase == "credits" then
    update_credits()
  elseif phase == "play" then
    update_play()
  elseif phase == "over" then
    update_over()
  elseif phase == "initials" then
    update_initials()
  end

  ui.cls(BLACK)
  draw_stars()

  if phase == "splash" or phase == "story" or phase == "menu" then
    draw_rocks(decor)
  elseif phase == "play" or phase == "over" then
    draw_world()
    draw_hud()
  end

  if phase == "splash" then
    print_c("POLYGON GAMES", H / 2 - 8, WHITE)
  elseif phase == "story" then
    print_c("ASTEROIDS", 48, WHITE)
    print_c("LANCADO EM 1979, FOI O", 78, WHITE)
    print_c("ARCADE MAIS VENDIDO DA ATARI.", 90, WHITE)
    print_c("O RECORDE GUARDAVA AS INICIAIS", 102, WHITE)
    print_c("AO LADO DA PONTUACAO.", 114, WHITE)
    print_c("A OU B CONTINUA", H - 28, GREEN)
  elseif phase == "menu" then
    draw_menu()
  elseif phase == "scores" then
    draw_scores()
  elseif phase == "help" then
    draw_help()
  elseif phase == "credits" then
    draw_credits()
  elseif phase == "over" then
    print_c("FIM DE JOGO", H / 2 - 16, WHITE)
    print_c(format_score(score), H / 2, WHITE)
    if over_t <= 0 and not rank then
      print_c("A OU B", H / 2 + 20, GREEN)
    end
  elseif phase == "initials" then
    draw_initials()
  end
end

math.randomseed(os.time())
for i = 1, 40 do
  stars[i] = { x = randint(0, W - 1), y = randint(0, H - 1), speed = (i % 3) * 0.15 + 0.15 }
end
for _ = 1, 6 do
  decor[#decor + 1] = make_rock(randint(0, W - 1), randint(0, H - 1), randint(1, 3), randint(0, 7), randint(1, 359))
end
start_music("menu", 28.9)
