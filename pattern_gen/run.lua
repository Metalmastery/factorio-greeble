local Tile = require("pattern_gen/tile").Tile
local Importer = require("pattern_gen/importer").Importer
local WFC = require("pattern_gen/wfc_chunks").WFC
local Render = require("pattern_gen/render").Render
local printTable = require("pattern_gen/utils").printTable

local settings_config = require('pattern_gen/settings_config')

local gridSize = { width = 10, height = 12 }
local tileSize = 3

local function finishCallback()
end

local function stepCallback()
end

local function clear_ghost(surface, tile_type, position, force)
    local tile = surface.get_tile(position)
    if tile.has_tile_ghost(force) then
        -- Docs are wrong, this returns a table of LuaEntites
        local ghosts = tile.get_tile_ghosts(force) ---@cast ghosts LuaEntity[]
        for _, ghost in pairs(ghosts) do
            -- if ghost.type == "tile-ghost" and ghost.ghost_name ~= tile_type then
            --     ghost.destroy()
            -- end

            if ghost.type == "tile-ghost" then
                ghost.destroy()
            end
        end
    end
end

--- Build a tile ghost on the map.
--- @param surface LuaSurface the surface to build the tile on
--- @param tile_type string which tile to build
--- @param position TilePosition where to build the tile
--- @param force string|integer|LuaForce the force to build the tile for
local function create_tile_ghost(surface, tile_type, position, force)
    -- TilePosition should be interchangeable with MapPosition
    ---@diagnostic disable-next-line: cast-type-mismatch
    local pos = position ---@cast pos MapPosition
    -- Using Alternative Function Signature
    ---@diagnostic disable-next-line: missing-parameter
    clear_ghost(surface, tile_type, position, force)
    -- if surface.can_place_entity({ name = "tile-ghost", position = pos, inner_name = tile_type, force = force, build_check_type = defines.build_check_type.script_ghost }) then
    surface.create_entity({
        name = "tile-ghost",
        position = pos,
        inner_name = tile_type,
        force = force,
        expires = false,
    })
    -- end
end

local function cleanupPreviousRun(event)
    if not storage.greeble_previous_run then
        return
    end

    local area = storage.greeble_previous_run
    local player = game.players[event.player_index]

    for x = area.left_top.x, area.right_bottom.x do
        for y = area.left_top.y, area.right_bottom.y do
            clear_ghost(event.surface, "greeble-non-buildable-tile", { x = math.floor(x), y = math.floor(y) },
                player.force)
        end
    end

    storage.greeble_previous_run = nil
end

local function getCoordinateKey(position)
    return math.floor(position.x) .. '-' .. math.floor(position.y)
end

local function mergeTiles(table1, table2)
    local result = {}
    local unique = {}

    for _, tile in ipairs(table1) do
        unique[getCoordinateKey(tile.position)] = tile
        table.insert(result, tile)
    end

    for _, tile in ipairs(table2) do
        if not unique[getCoordinateKey(tile.position)] then
            table.insert(result, tile)
        end
    end
    return result
end

function testRun(event, tilesOnly)
    cleanupPreviousRun(event)

    tilesOnly = tilesOnly or false
    -- reset id for tiles?
    Tile._idBase = 1

    local template = storage.tile_templates[event.player_index]

    local startPosition = event.area.left_top or { x = 0, y = 0 }
    local importer = Importer.new(tileSize)

    -- TODO build grid based on size, not tiles -> fill up missing spots to alllow sparse templates
    local importedData = importer:importBlueprint({ blueprint = { tiles = template.tiles } })

    local spreadSetting = settings.global[settings_config.SPREAD.name].value
    local render = Render.new(importedData.tilesMap, importedData.namesMap, tileSize, (spreadSetting and 1 or 0))

    local result

    if tilesOnly then
        result = render:renderTiles(startPosition)
        return result
    end

    local wfc = WFC.new(event.area, importedData.tilesMap, {});

    local function chunkCallback()
        -- local wfcSimpleData = wfc:exportWithCoordinates()
        -- result = render:makeJSON(wfcSimpleData, startPosition)
        -- event.surface.set_tiles(result, true, true, true, true, game.players[event.player_index])
    end

    wfc:solve(nil, nil, chunkCallback)

    local player = game.players[event.player_index]
    -- event.surface.create_entity { name = "tile-ghost", inner_name = 'greeble-non-buildable-tile', position = event.area.left_top, force = player.force, player = player }
    -- event.surface.create_entity { name = "greeble-non-buildable-tile", position = event.area.left_top, force = player.force, player = player }

    for x = event.area.left_top.x, event.area.right_bottom.x do
        for y = event.area.left_top.y, event.area.right_bottom.y do
            create_tile_ghost(event.surface, "greeble-non-buildable-tile", { x = math.floor(x), y = math.floor(y) },
                player.force)
        end
    end

    storage.greeble_previous_run = event.area

    local player = game.players[event.player_index]

    local frame = player.gui.center.add {
        type = "frame",
        direction = "vertical",
        caption = "Greeble progress"
    }

    frame.add { type = "label", caption = "Attempts left" }
    local attempts = frame.add { type = "progressbar" }

    frame.add { type = "label", caption = "Chunks solved" }
    local progressbar = frame.add { type = "progressbar" }
    local cancelButton = frame.add { type = "button" }
    cancelButton.caption = "Cancel"

    local originalEvent = event

    script.on_event(defines.events.on_gui_click, function(event)
        script.on_event(defines.events.on_tick, nil)

        if storage.greeble_frame then
            storage.greeble_frame.destroy()
        end

        cleanupPreviousRun(originalEvent)
    end)

    if storage.greeble_frame then
        storage.greeble_frame.destroy()
    end
    -- TODO clear previous one if exists
    storage.greeble_attempts = attempts
    storage.greeble_progress = progressbar
    storage.greeble_frame = frame

    script.on_event(defines.events.on_tick, function()
        if wfc.ready or wfc.failed then
            cleanupPreviousRun(event)

            local outline = {}
            local fill = {}

            -- TODO attach to settings
            for _, ent in ipairs(originalEvent.entities) do
                render:roundBoxCoordinates(ent.bounding_box)
                -- local fill = render:outlineBox(ent.bounding_box, 2, 'refined-hazard-concrete-left')
                outline = render:outlineBox(ent.bounding_box, 2, 'stone-path', outline)
                -- event.surface.set_tiles(fill, true, true, true, true, game.players[event.player_index])
                fill = render:fillBox(ent.bounding_box, 1, 'refined-concrete', fill)
                -- event.surface.set_tiles(fill, true, true, true, true, game.players[event.player_index])
            end

            local wfcSimpleData = wfc:exportWithCoordinates()
            result = render:makeJSON(wfcSimpleData, originalEvent)
            -- event.surface.set_tiles(result, true, true, true, true, game.players[event.player_index])


            local finalTiles = mergeTiles(fill, outline)
            finalTiles = mergeTiles(finalTiles, result)

            -- TODO fix this mess
            event.surface.set_tiles(finalTiles, true, true, true, true, game.players[event.player_index])

            -- TODO move UI to separate filed
            if storage.greeble_frame then
                storage.greeble_frame.destroy()
            end
            script.on_event(defines.events.on_tick, nil)
        end

        if wfc.ready then
            -- local wfcSimpleData = wfc:exportWithCoordinates()
            -- result = render:makeJSON(wfcSimpleData, startPosition)
            -- event.surface.set_tiles(result, true, true, true, true, game.players[event.player_index])
            script.on_event(defines.events.on_tick, nil)
        else
            local t = 10

            while t > 0 and not wfc.ready and not wfc.failed do
                wfc.cycleFunc()
                t = t - 1
            end
        end
    end)


    -- printTable(wfcSimpleData)

    -- printTable(result)
end

return {
    testRun = testRun
}

-- testRun()
