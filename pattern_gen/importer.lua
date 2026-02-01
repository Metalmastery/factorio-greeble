local Tile = require("pattern_gen/tile").Tile
local printTable = require("pattern_gen/utils").printTable
local DIRECTION = require("pattern_gen/utils").DIRECTION
local settings_config = require('pattern_gen/settings_config')
-- Tile and Importer Classes - Lua Port

-- Importer class
local Importer = {}
Importer.__index = Importer

-- #region Importer
function Importer.new(tileSize)
    local self = setmetatable({}, Importer)

    self.tileSize = tileSize or 3
    self.sourceGrid = {}
    self.namesMap = {
        names = {},
        inverseNames = {}
    }

    return self
end

-- #tag extractNamesMap
function Importer:extractNamesMap(sourceTiles)
    local names = {}
    local inverseNames = {}
    local counter = 1

    for _, t in ipairs(sourceTiles) do
        if not names[t.name] then
            names[t.name] = counter
            inverseNames[counter] = t.name
            counter = counter + 1
        end
    end

    return {
        names = names,
        inverseNames = inverseNames
    }
end

-- #tag buildSourceGrid
function Importer:buildSourceGrid(sourceTiles)
    local sourceGrid = {}

    for _, t in ipairs(sourceTiles) do
        if not t.position then
            print('no position')
            print(t.name)
            goto continue
        end

        local y = t.position.y + 1 -- Convert to 1-indexed
        local x = t.position.x + 1

        if not sourceGrid[y] then
            sourceGrid[y] = {}
        end

        sourceGrid[y][x] = self.namesMap.names[t.name]
        ::continue::
    end

    return sourceGrid
end

-- extractTiles(grid, size) {
--     const sourceW = grid[0].length,
--         sourceH = grid.length;

--     const tiles = [];
--     const unique = [];

--     const tileMap = {};

--     for (let y = 0; y < sourceH - size + 1; y++) {
--         for (let x = 0; x < sourceW - size + 1; x++) {
--             const tile = new Tile(size);
--             for (let t1 = 0; t1 < size; t1++) {
--                 for (let t2 = 0; t2 < size; t2++) {
--                     tile.data[t1][t2] = grid[y + t1][x + t2];
--                 }
--             }
--             tile.computeEdges();
--             const rotations = tile
--                 .getAllRotations()
--                 .forEach((rot) => {
--                     if (unique.includes(rot.code)) {
--                         tileMap[rot.code].frequency += 1;
--                         // console.log('duplicate', rot.code, tileMap[rot.code].frequency)
--                         return;
--                     }
--                     tileMap[rot.code] = rot;
--                     tiles.push(rot);
--                     unique.push(rot.code);
--                 });
--         }
--     }
--     return tiles;
-- }

-- #tag extractTiles
function Importer:extractTiles(grid, size)
    local sourceH = #grid
    local sourceW = #grid[1]

    local tiles = {}
    local unique = {}
    local tileMap = {}
    local inc = 1

    local skipIntermediates = settings.global[settings_config.SKIP_INTERMEDIATE.name].value
    local includeRotationsSetting = settings.global[settings_config.INCLUDE_ROTATED.name].value
    local includeMirroredSetting = settings.global[settings_config.INCLUDE_MIRRORED.name].value

    if skipIntermediates then
        inc = settings.global[settings_config.SKIP_INTERMEDIATE.name].value - 1
    end

    for y = 1, sourceH - size, inc do
        for x = 1, sourceW - size, inc do
            local tile = Tile.new(size)

            -- Extract tile data
            for t1 = 0, size - 1 do
                for t2 = 0, size - 1 do
                    tile.data[t1 + 1][t2 + 1] = grid[y + t1][x + t2]
                end
            end

            tile:computeEdges()

            local initial = { tile }
            local variations = {}

            if includeMirroredSetting then
                initial = tile:getMirrored()
            end

            if includeRotationsSetting then
                for _, t in ipairs(initial) do
                    local rotations = t:getAllRotations()

                    for _, rotated in ipairs(rotations) do
                        table.insert(variations, rotated)
                    end
                end
            else
                variations = initial
            end

            local discarded = 0
            for _, var in ipairs(variations) do
                if unique[var.code] then
                    -- Increment frequency for duplicate
                    -- game.print(string.format('   rotation code freq++ %s %s', tileMap[rot.code].frequency, rot.code))
                    tileMap[var.code].frequency = tileMap[var.code].frequency + 1
                else
                    -- game.print(string.fqormat('rotation code unique %s', rot.code))
                    tileMap[var.code] = var
                    table.insert(tiles, var)
                    unique[var.code] = true

                    discarded = discarded + 1
                end
            end

            -- game.print(string.format('discarded %s of %s tiles as duplicates for tile %s', discarded, #variations, tile.code))

        end
    end

    return tiles
end

-- #tag makeTileMap
function Importer:makeTileMap(tiles)
    local tileMap = {}
    for _, t in ipairs(tiles) do
        tileMap[t.id] = t
    end
    return tileMap
end

-- #tag relocateToZero
function Importer:relocateToZero(bp)
    local tiles = bp.blueprint.tiles

    if #tiles == 0 then
        return bp
    end

    local smallestX = tiles[1].position.x
    local smallestY = tiles[1].position.y

    for _, tile in ipairs(tiles) do
        smallestX = math.min(smallestX, tile.position.x)
        smallestY = math.min(smallestY, tile.position.y)
    end

    for _, tile in ipairs(tiles) do
        tile.position.x = tile.position.x - smallestX
        tile.position.y = tile.position.y - smallestY

        -- if tile.position.x == 0 or tile.position.y == 0 then
        --     game.print('importer position zero')
        -- end
    end

    return bp
end

-- #tag importBlueprint
function Importer:importBlueprint(importBp)
    local bp = self:relocateToZero(importBp)
    -- local bp = importBp
    local sourceTiles = bp.blueprint.tiles

    self.namesMap = self:extractNamesMap(sourceTiles)

    game.print(table.concat(self.namesMap.inverseNames, ','))

    local grid = self:buildSourceGrid(sourceTiles)

    game.print(string.format('importer grid size %s %s', #grid, #grid[1]))

    local tiles = self:extractTiles(grid, self.tileSize)

    game.print(string.format('tiles extracted %s', #tiles))

    local tilesMap = self:makeTileMap(tiles)

    game.print(string.format('tilemap size %s', #tilesMap))

    return {
        namesMap = self.namesMap,
        tilesMap = tilesMap
    }
end

-- #endregion Importer

-- Helper function to check if value exists in table (acts like array.includes())
local function tableContains(tbl, value)
    for _, v in ipairs(tbl) do
        if v == value then
            return true
        end
    end
    return false
end

return {
    Importer = Importer,
}
