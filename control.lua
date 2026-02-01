local table_tostring = require('util/table_tostring')

local tile_patterns = require("scripts/tile-patterns.lua")
local planner_name = "greeble"

local testRun = require("pattern_gen/run").testRun

local function on_player_selected_area(event)
  game.print('left click')
  local item = event.item
  if item == planner_name then
    local min_x = math.huge
    local min_y = math.huge
    local max_x = -math.huge
    local max_y = -math.huge

    for _, tile in pairs(event.tiles) do
      min_x = math.min(tile.position.x, min_x)
      min_y = math.min(tile.position.y, min_y)
      max_x = math.max(tile.position.x, max_x)
      max_y = math.max(tile.position.y, max_y)
    end
    local tiles = {}
    for _, tile in pairs(event.tiles) do
      local new_position = { x = tile.position.x - min_x, y = tile.position.y - min_y }
      table.insert(tiles, { name = tile.name, position = new_position })
    end
    if not storage.tile_templates then
      storage.tile_templates = {}
    end
    storage.tile_templates[event.player_index] = { tiles = tiles, width = max_x - min_x + 1, height = max_y - min_y + 1 }
  end
end

-- local function draw_pattern(event)
--   local item = event.item
--   local instant_build = false
--   if not storage.tile_templates[event.player_index] then return end
--   if item == planner_name then
--     local player = game.players[event.player_index]
--     local template = storage.tile_templates[event.player_index]
--     local new_tiles = tile_patterns.repeat_pattern(template.tiles, template.width, template.height, event.area)
--     if instant_build then
--       event.surface.set_tiles(new_tiles, true, true, true, true, player)
--     else
--       for _, tile in pairs(new_tiles) do
-- event.surface.create_entity { name = "tile-ghost", inner_name = tile.name, position = tile.position, force = player.force, player = player, raise_built = true }
--       end
--     end
--   end
-- end

local function draw_tiles(event)
  game.print('draw_tiles')
  local item = event.item
  local instant_build = true
  if not storage.tile_templates[event.player_index] then return end
  if item == planner_name then
    local player = game.players[event.player_index]
    local new_tiles = testRun(event, true)
    if instant_build then
      event.surface.set_tiles(new_tiles, true, true, true, true, player)
    else
      for _, tile in pairs(new_tiles) do
        event.surface.create_entity { name = "tile-ghost", inner_name = tile.name, position = tile.position, force = player.force, player = player, raise_built = true }
      end
    end
  end
end

local function draw_pattern(event)
  game.print('draw_pattern')
  local item = event.item
  local instant_build = true
  if not storage.tile_templates[event.player_index] then return end
  if item == planner_name then
    local player = game.players[event.player_index]
    local new_tiles = testRun(event, false)
    -- if instant_build then
    --   event.surface.set_tiles(new_tiles, true, true, true, true, player)
    -- else
    --   for _, tile in pairs(new_tiles) do
    --     event.surface.create_entity { name = "tile-ghost", inner_name = tile.name, position = tile.position, force = player.force, player = player, raise_built = true }
    --   end
    -- end
  end
end

local function on_mod_settings_update(event)
  local player = game.players[event.player_index]
  local val = settings.global[event.setting].value

  game.print(string.format('setting updated %s %s', event.setting, val))
end

script.on_init(function()
  if not storage.tile_templates then
    game.print('create tile_templates')
    storage.tile_templates = {}
  end

  if not storage.greeble_previous_run then
    game.print('create greeble_previous_run')
    storage.greeble_previous_run = nil
  end
end)

script.on_configuration_changed(function()
  if not storage.tile_templates then
    storage.tile_templates = {}
  end
end)

script.on_event("greeble-open-menu", function(event)
  game.print("Keyboard shortcut pressed on tick: " .. tostring(event.tick))

  -- player.gui.center

  local player = game.players[event.player_index]

  -- local frame = player.gui.center.add { type = "frame" }
  -- frame.caption = "Greeble progress"
  -- local progressbar = frame.add { type = "progressbar" }

  -- -- TODO clear previous one if exists
  -- storage.greeble_progress = progressbar
  -- storage.greeble_frame = frame
end)

-- def boxes_distance(A_min, A_max, B_min, B_max):
-- delta1 = A_min - B_max
-- delta2 = B_min - A_max
-- u = np.max(np.array([np.zeros(len(delta1)), delta1]), axis=0)
-- v = np.max(np.array([np.zeros(len(delta2)), delta2]), axis=0)
-- dist = np.linalg.norm(np.concatenate([u, v]))
-- return dist

-- local function mergeBoxes(boxes, threshold)
--   threshold = threshold or 1

--   local result = {}

--   for _, box1 in ipairs(boxes) do
--     for _, box2 in ipairs(boxes) do
--       local offsetBox1 = offsetBox(box1, threshold)
--       local offsetBox2 = offsetBox(box2, threshold)
--       local box1hash = table.concat(offsetBox1.left_top) .. '-' .. table.concat(offsetBox1.right_bottom)
--       local box2hash = table.concat(offsetBox2.left_top) .. '-' .. table.concat(offsetBox2.right_bottom)

--       if offsetBox1.left_top.x >

--       -- if result[box1hash]

--     end
--   end


--   local result
-- end

script.on_event(defines.events.on_player_selected_area, on_player_selected_area)
-- script.on_event(defines.events.on_player_selected_area, testSize)
script.on_event(defines.events.on_player_alt_selected_area, on_player_selected_area)

script.on_event(defines.events.on_player_reverse_selected_area, draw_pattern)
script.on_event(defines.events.on_player_alt_reverse_selected_area, draw_tiles)

script.on_event(defines.events.on_runtime_mod_setting_changed, on_mod_settings_update)
