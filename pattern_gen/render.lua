local printTable = require("pattern_gen/utils").printTable
local settings_config = require('pattern_gen/settings_config')

---@class Render
---@field tilesMap Tile[]
---@field namesMap table
---@field spread integer
---@field tileSize integer
local Render = {}
Render.__index = Render

function Render.new(tilesMap, namesMap, tileSize, spread)
    local self = setmetatable({}, Render)
    self.tilesMap = tilesMap or {}
    self.namesMap = namesMap or {}
    self.spread = spread or 0
    self.tileSize = tileSize or 0
    return self
end

-- #tag outlineBox
function Render:outlineBox(box, offset, tileName, tilesThrough)
    offset = offset or 0
    tileName = tileName or 'concrete'

    --   -- game.print(serpent.line(box))
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

-- #tag offsetBox
function Render:offsetBox(box, offset)
    return {
        left_top = { x = box.left_top.x - offset, y = box.left_top.y - offset },
        right_bottom = { x = box.right_bottom.x + offset, y = box.right_bottom.y + offset },
    }
end

-- #tag fillBox
function Render:fillBox(box, offset, tileName, tilesThrough)
    offset = offset or 0
    tileName = tileName or 'concrete'

    --   -- game.print(serpent.line(box))

    local tiles = tilesThrough or {}

    -- tiling pad under a box
    for x = box.left_top.x - offset, box.right_bottom.x + offset do
        for y = box.left_top.y - offset, box.right_bottom.y + offset do
            table.insert(tiles, { position = { x = x, y = y }, name = tileName })
        end
    end

    return tiles
end

-- #tag roundBoxCoordinates
function Render:roundBoxCoordinates(box)
    -- for _, box in ipairs(boxes) do
    box.left_top.x = math.floor(box.left_top.x)
    box.left_top.y = math.floor(box.left_top.y)
    box.right_bottom.x = math.floor(box.right_bottom.x)
    box.right_bottom.y = math.floor(box.right_bottom.y)
    -- end
end

-- #tag getContainingBox
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

-- #tag getBestMatchingTile
---@param code string
---@param data any[]
---@return Tile|nil
function Render:getBestMatchingTile(tileToMatch, reflectionIndex)

    local code = tileToMatch.reflectedCodes[reflectionIndex]

    local matches = {}
    local bestMatches = {}

    for _, tile in pairs(self.tilesMap) do
        if tile.code == code then
            table.insert(matches, tile)

            if tile.originalID == tileToMatch.originalID then
                table.insert(bestMatches, tile)
            end
        end
    end

    if #matches == 0 then
        return nil
    end

    if #bestMatches > 0 then
        return bestMatches[math.random(#bestMatches)]
    end

    -- game.print(string.format('getBestMatchingTile %s found for code %s', #matches, code))

    return matches[math.random(#matches)]
end

-- #tag makeJSON
---comment
---@param wfcData { size: Size, tiles: ExportCell[] }
---@param event any
---@return { name: string, position: Point }[]
function Render:makeJSON(wfcData, event)
    self:roundBoxCoordinates(event.area)

    local origin = event.area.left_top

    local player = game.players[event.player_index]
    local surface = player.surface

    local overlapSetting = settings.global[settings_config.RENDER_OVERLAP_TILES.name].value
    local avoidBuildings = settings.global[settings_config.RENDER_AVOID_BUILDINGS.name].value
    local preserveTiles = settings.global[settings_config.RENDER_PRESERVE_EXISTING_TILES.name].value

    local bpTiles = {}
    
    local tileSize = self.tileSize

    local tileSizeAdjusted = tileSize
    if overlapSetting then
        tileSizeAdjusted = tileSizeAdjusted - 1
    end

    local totalGridSize = {
        w = wfcData.size.w * tileSizeAdjusted,
        h = wfcData.size.h * tileSizeAdjusted
    }

    local selectedAreaSize = {
        w = event.area.right_bottom.x - event.area.left_top.x,
        h = event.area.right_bottom.y - event.area.left_top.y
    }

    -- TODO use half excess to center symmetric patterns in selected area
    local excess = {
        w = totalGridSize.w - selectedAreaSize.w,
        h = totalGridSize.h - selectedAreaSize.h
    }

    game.print(string.format('totalGridSize %s, %s', totalGridSize.w, totalGridSize.h))
    game.print(string.format('selectedAreaSize %s, %s', selectedAreaSize.w, selectedAreaSize.h))
    game.print(string.format('excess %s, %s', excess.w, excess.h))

    for _, t in ipairs(wfcData.tiles) do
        if t.value then -- handle broken tiles
            local tile = self.tilesMap[t.value]
            local data = tile.data
            local tileCode = tile.code

            local startPositionX = 0
            local startPositionY = 0
            local includeTiles = tileSize - 1

            if overlapSetting then
                includeTiles = tileSize - 2
            end

            if t.reflected then
                data = tile.reflections[t.reflected]
                -- tileCode = tile.reflectedCodes[t.reflected]

                local bestMatchingTile = self:getBestMatchingTile(tile, t.reflected)

                if bestMatchingTile then
                    data = bestMatchingTile.data
                end

                -- TODO refactor this
                if overlapSetting then
                    if t.reflected == 1 then
                        startPositionX = 1
                    end

                    if t.reflected == 2 then
                        startPositionY = 1
                    end

                    if t.reflected == 3 then
                        startPositionX = 1
                        startPositionY = 1
                    end
                end
            end

            local test = includeTiles + 1

            local tilePosition = {
                x = t.x * (test + self.spread) + origin.x,
                y = t.y * (test + self.spread) + origin.y,
            }

            for row = startPositionY, startPositionY + includeTiles do
                for column = startPositionX, startPositionX + includeTiles do
                    local bpTile = {

                        position = {
                            x = tilePosition.x + column,
                            y = tilePosition.y + row,
                        },

                        name = self.namesMap.inverseNames[
                        data[row + 1][column + 1]
                        ],
                    }

                    if bpTile.position.x > event.area.right_bottom.x or bpTile.position.y > event.area.right_bottom.y then
                        goto continue
                    end

                    -- -- game.print(string.format('render tile %s row=%s column=%s at %s %s', bpTile.name, row, column,
                    --     bpTile.position.x, bpTile.position.y))

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
--       -- game.print(cb)
--     end

--     roundBoxCoordinates(ent.bounding_box)
--     local tiles
--     -- tiles = outlineBox(ent.bounding_box, 3, 'refined-hazard-concrete-left')
--     -- event.surface.set_tiles(tiles, true, true, true, true, game.players[event.player_index])

--     tiles = fillBox(ent.bounding_box, 0, 'refined-concrete')
--     event.surface.set_tiles(tiles, true, true, true, true, game.players[event.player_index])
--   end
-- #tag renderTiles
function Render:renderTiles(origin)
    local bpTiles = {}

    local t1 = 0
    local t2 = 0

    -- game.print(string.format('tiles to render %s', #self.tilesMap))
    -- game.print(string.format('at position %s %s', origin.x, origin.y))

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

    -- game.print(string.format('game tiles rendered %s of %s', t1, #bpTiles))

    return bpTiles
end

return {
    Render = Render
}
