local patterns = {}

local function add_positions(pos1, pos2)
  return {x = pos1.x + pos2.x, y = pos1.y + pos2.y}
end

patterns.repeat_pattern = function(tiles, input_width, input_height, output_area)
  local position = output_area.left_top
  local width = output_area.right_bottom.x - output_area.left_top.x
  local height = output_area.right_bottom.y - output_area.left_top.y
  local x_repetitions = math.ceil(width / input_width)
  local y_repetitions = math.ceil(height / input_height)
  local new_tiles = {}
  for x_repetition = 0, x_repetitions - 1 do
    for y_repetition = 0, y_repetitions - 1 do
      for _, tile in pairs(tiles) do
        local new_position = add_positions(tile.position, position)
        new_position = add_positions(new_position, {x = x_repetition * input_width, y = y_repetition * input_height})
        if new_position.x < output_area.right_bottom.x and new_position.y < output_area.right_bottom.y then
          table.insert(new_tiles, {name = tile.name, position = new_position})
        end
      end
    end
  end
  return new_tiles
end

return patterns