local printTable = require("pattern_gen/utils").printTable
local settings_config = require('pattern_gen/settings_config')

local Render = {}
Render.__index = Render

-- #region Render
function Render.new(tilesMap, namesMap, tileSize, spread)
    local self = setmetatable({}, Render)
    self.tilesMap = tilesMap or {}
    self.namesMap = namesMap or {}
    self.spread = spread or 0
    self.tileSize = tileSize or 0
    return self
end

function Render:outlineBox(box, offset, tileName, tilesThrough)
  offset = offset or 0
  tileName = tileName or 'concrete'

--   game.print(serpent.line(box))
  -- offset box around a box
  local tiles = tilesThrough or {}
  local offset = offset or 2
  for x = box.left_top.x - offset, box.right_bottom.x + offset do
    table.insert(tiles, { position = { x = x, y = box.left_top.y - offset }, name = tileName })
    table.insert(tiles, { position = { x = x, y = box.right_bottom.y + offset }, name = tileName })
  end

  for y = box.left_top.y - offset, box.right_bottom.y + offset do
    table.insert(tiles, { position = { x = box.left_top.x - offset, y = y }, name = tileName })
    table.insert(tiles, { position = { x = box.right_bottom.x + offset, y = y }, name = tileName })
  end
  return tiles
end

function Render:offsetBox(box, offset)
  return {
    left_top = { x = box.left_top.x - offset, y = box.left_top.y - offset },
    right_bottom = { x = box.right_bottom.x + offset, y = box.right_bottom.y + offset },
  }
end

function Render:fillBox(box, offset, tileName, tilesThrough)
  offset = offset or 0
  tileName = tileName or 'concrete'

--   game.print(serpent.line(box))

  local tiles = tilesThrough or {}

  -- tiling pad under a box
  for x = box.left_top.x - offset, box.right_bottom.x + offset do
    for y = box.left_top.y - offset, box.right_bottom.y + offset do
      table.insert(tiles, { position = { x = x, y = y }, name = tileName })
    end
  end

  return tiles
end

function Render:roundBoxCoordinates(box)
  -- for _, box in ipairs(boxes) do
  box.left_top.x = math.floor(box.left_top.x)
  box.left_top.y = math.floor(box.left_top.y)
  box.right_bottom.x = math.floor(box.right_bottom.x)
  box.right_bottom.y = math.floor(box.right_bottom.y)
  -- end
end

function Render:getContainingBox(entities)
  local combinedBox = entities[1].bounding_box

  for _, ent in ipairs(entities) do
    local box = ent.bounding_box
    combinedBox.left_top.x = math.min(combinedBox.left_top.x, box.left_top.x)
    combinedBox.left_top.y = math.min(combinedBox.left_top.y, box.left_top.y)
    combinedBox.right_bottom.x = math.max(combinedBox.right_bottom.x, box.right_bottom.x)
    combinedBox.right_bottom.y = math.max(combinedBox.right_bottom.y, box.right_bottom.y)
  end

  return combinedBox
end

local function merge_lists(t1, t2)
    for _, value in ipairs(t2) do
        table.insert(t1, value)
    end
    return t1
end


function Render:makeJSON(wfcData, event)

    self:roundBoxCoordinates(event.area)

    local origin = event.area.left_top

    local player = game.players[event.player_index]
    local surface = player.surface

    local overlapSetting = settings.global[settings_config.OVERLAP.name].value
    local avoidBuildings = settings.global[settings_config.AVOID_BUILDINGS.name].value
    local preserveTiles = settings.global[settings_config.PRESERVE_EXISTING_TILES.name].value

    local bpTiles = {}
    -- local tileSize = self.tilesMap[wfcData[1].value or 0].data.length -- fix this mess
    -- this.tilesMap[wfcData[0].value || 0].data.length
    local tileSize = self.tileSize
    for _, t in ipairs(wfcData) do
        if t.value then -- handle broken tiles
            local tile = self.tilesMap[t.value]
            local startPositionX = 0
            local startPositionY = 0

            if overlapSetting and t.x > 0 then startPositionX = 1 end
            if overlapSetting and t.y > 0 then startPositionY = 1 end

            for row = startPositionY, tileSize - 1 do
                for column = startPositionX, tileSize - 1 do
                    local bpTile = {
                        position = {
                            x = t.x * (tileSize + self.spread - startPositionX) + column + origin.x,
                            y = t.y * (tileSize + self.spread - startPositionY) + row + origin.y,
                        },
                        name = self.namesMap.inverseNames[
                            tile.data[row + 1][column + 1]
                        ],
                    }
                    -- TODO skip tiles under buildings

                    if avoidBuildings and not surface.can_place_entity({ name = 'stone-wall', position = bpTile.position, inner_name = bpTile.name, force = player.force }) then
                        goto continue
                    end

                    if preserveTiles and not surface.can_place_entity({ name = 'tile-ghost', position = bpTile.position, inner_name = bpTile.name, force = player.force }) then
                        goto continue
                    end

                    table.insert(bpTiles, bpTile)
                    ::continue::
                end
            end
        end
    end

    -- TODO add existing tiles back

    return bpTiles
end
-- for _, ent in ipairs(event.entities) do
--     local cb = ent.type
--     if cb then
--       game.print(cb)
--     end

--     roundBoxCoordinates(ent.bounding_box)
--     local tiles
--     -- tiles = outlineBox(ent.bounding_box, 3, 'refined-hazard-concrete-left')
--     -- event.surface.set_tiles(tiles, true, true, true, true, game.players[event.player_index])

--     tiles = fillBox(ent.bounding_box, 0, 'refined-concrete')
--     event.surface.set_tiles(tiles, true, true, true, true, game.players[event.player_index])
--   end
function Render:renderTiles(origin)
    local bpTiles = {}

    local t1 = 0
    local t2 = 0

    game.print(string.format('tiles to render %s', #self.tilesMap))
    game.print(string.format('at position %s %s', origin.x, origin.y))

    local tileSize = self.tileSize

    -- printTable(self.tilesMap)

    for _, tile in pairs(self.tilesMap) do
        for row = 1, tileSize do
            for column = 1, tileSize do
                local bpTile = {
                    position = {
                        x = (t1 % 10) * 4 + column + math.floor(origin.x),
                        y = math.floor(t1 / 10) * 4 + row + math.floor(origin.y),
                    },
                    name = self.namesMap.inverseNames[
                    tile.data[row][column]
                    ],

                }

                table.insert(bpTiles, bpTile)
            end
        end
        t1 = t1 + 1
        -- if t1 > 20 then
        --     t2 = t2 + 1
        --     t1 = 0
        -- end
    end

    game.print(string.format('game tiles rendered %s of %s', t1, #bpTiles))

    return bpTiles
end

return {
    Render = Render
}
-- #endregion