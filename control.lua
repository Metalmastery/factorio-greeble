local planner_name = "greeble"

local testRun = require("pattern_gen/run").testRun
local selectTemplate = require("pattern_gen/run").selectTemplate

local function draw_tiles(event)
  -- game.print('draw_tiles')
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
  -- game.print('draw_pattern')
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

  -- game.print(string.format('setting updated %s %s', event.setting, val))
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
  -- game.print("Keyboard shortcut pressed on tick: " .. tostring(event.tick))

  -- player.gui.center

  local player = game.players[event.player_index]

  -- local frame = player.gui.center.add { type = "frame" }
  -- frame.caption = "Greeble progress"
  -- local progressbar = frame.add { type = "progressbar" }

  -- -- TODO clear previous one if exists
  -- storage.greeble_progress = progressbar
  -- storage.greeble_frame = frame
end)


script.on_event(defines.events.on_player_selected_area, selectTemplate)
script.on_event(defines.events.on_player_alt_selected_area, selectTemplate)

script.on_event(defines.events.on_player_reverse_selected_area, draw_pattern)
script.on_event(defines.events.on_player_alt_reverse_selected_area, draw_tiles)

script.on_event(defines.events.on_runtime_mod_setting_changed, on_mod_settings_update)
