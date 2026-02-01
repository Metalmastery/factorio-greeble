local buildable_tiles = {}
for tile_name, tile in pairs(data.raw.tile) do
  if tile.minable then
    table.insert(buildable_tiles, tile_name)
  end
end

local planner = data.raw["selection-tool"]["greeble"]

planner.select.tile_filters = buildable_tiles
planner.alt_select.tile_filters = buildable_tiles
