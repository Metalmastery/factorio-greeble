local Tile = require("pattern_gen/tile").Tile
local Importer = require("pattern_gen/importer")
local WFC = require("pattern_gen/wfc_chunks").WFC
local Render = require("pattern_gen/render").Render
local printTable = require("pattern_gen/utils").printTable

local settings_config = require('pattern_gen/settings_config')

local blueprint_data = require('pattern_gen/data/bp_5_5').data3

local tileSize = 3

local function finishCallback()
end

local function stepCallback()
end

local wfc
local cycle

local colors = {
    red = "\27[0;31m",
    green = "\27[0;32m",
    blue = "\27[0;34m",
    reset = "\27[0m"
}
-- print(colors.red .. "This text is red." .. colors.reset)

local function recolor_number(match)
    return colors.green .. match .. colors.reset
end

game = {
    print = function(v)
        v = string.gsub(v, '%d+', recolor_number)
        v = string.gsub(v, '-->', colors.blue .. "-->" .. colors.reset)
        v = string.gsub(v, '!!!', colors.red .. "!!!" .. colors.reset)
        print(v)
    end,


}

settings = {
    global = {
        [settings_config.IMPORT_REMOVE_DUPLICATES.name] = { value = false },
        [settings_config.IMPORT_INCLUDE_ROTATED.name] = { value = true },
        [settings_config.IMPORT_INCLUDE_REFLECTED.name] = { value = true },
        [settings_config.IMPORT_SKIP_INTERMEDIATE.name] = { value = false },
        [settings_config.IMPORT_TILE_SIZE.name] = { value = 3 },

        [settings_config.RENDER_PRESERVE_EXISTING_TILES.name] = { value = true },
        [settings_config.RENDER_AVOID_BUILDINGS.name] = { value = false },
        [settings_config.RENDER_OUTLINE_BUILDINGS.name] = { value = false },
        [settings_config.RENDER_SPREAD_TILES.name] = { value = false },
        [settings_config.RENDER_OVERLAP_TILES.name] = { value = true },

        [settings_config.WFC_CHUNK_SIZE.name] = { value = 3 },
        [settings_config.WFC_SYMMETRY_HORIZONTAL.name] = { value = true },
        [settings_config.WFC_SYMMETRY_VERTICAL.name] = { value = false },

        [settings_config.WFC_SOLVE_ATTEMPTS_LIMIT.name] = { value = 1000 },
        [settings_config.WFC_SOLVE_ATTEMPTS_PER_TICK.name] = { value = 10 },
    }
}


function testRun(event, tilesOnly)
    tilesOnly = tilesOnly or false
    Tile._idBase = 1

    local startPosition = { x = 0, y = 0 }
    local importer = Importer.new(tileSize)
    local importedData = importer:importBlueprint(blueprint_data)
    -- local importedData = importer:importBlueprint({ blueprint = { tiles = template.tiles } })

    local render = Render.new(importedData.tilesMap, importedData.namesMap, tileSize, 0)

    local result

    if tilesOnly then
        result = render:renderTiles(startPosition)
        return result
    end

    local area = {
        left_top = { x = 0, y = 0 },
        right_bottom = { x = 25, y = 36 },
    }

    -- local gridSize = { width = 9, height = 3 }

    wfc = WFC.new(area, importedData.tilesMap, {});
    wfc:solve(finishCallback, stepCallback)

    cycle = function()
        if wfc.ready then
            -- local wfcSimpleData = wfc:exportWithCoordinates()
            -- result = render:makeJSON(wfcSimpleData, startPosition)
            print('result is ready')
            wfc:debugGrid()
            return false
        end

        if wfc.ready or wfc.failed then
            local wfcSimpleData = wfc:exportWithCoordinates()
            result = render:makeJSON(wfcSimpleData, startPosition)
            print('wfc is done')
            return false
        end

        local t = 1

        while t > 0 and not wfc.ready and not wfc.failed do
            wfc.cycleFunc()
            t = t - 1
        end




        return true
    end
end

testRun()

-- cycle()


for i = 1, 10 do
    if not cycle() then
        break
    end
end

-- while not (wfc.ready or wfc.failed) do
--     cycle()
-- end
