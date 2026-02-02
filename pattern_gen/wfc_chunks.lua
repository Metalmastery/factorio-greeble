-- Wave Function Collapse Algorithm - Lua Port
local printTable = require("pattern_gen/utils").printTable

local DIRECTION = require("pattern_gen/utils").DIRECTION

local settings_config = require('pattern_gen/settings_config')

local ERRORS = {
    CELL_NO_OPTIONS = 1,
    CHUNK_NO_CELLS = 2
}

-- Rule class
local Rule = {}
Rule.__index = Rule

function Rule.new()
    local self = setmetatable({}, Rule)
    self.symbol = nil
    self.code = ""      -- 8 symbols for directions
    self.strictness = 1 -- 0 to 1
    return self
end

-- #region Cell
-- WfcCell class
local WfcCell = {}
WfcCell.__index = WfcCell

function WfcCell.new(x, y, options, rules, tilesMap)
    local self = setmetatable({}, WfcCell)
    self.tilesMap = tilesMap
    self.options = options or {}
    self.rules = rules or {}
    self.neighbors = {}
    self._neighborsLooped = {}
    self.x = x
    self.y = y
    self.isCollapsed = false
    self.isPropagated = false
    self.tileId = nil

    self.chunkID = 0

    self.id = nil

    self.collapseCallback = function() end

    return self
end

-- #tag reset
function WfcCell:reset()
    self:setTiles(self.tilesMap)
    self.isCollapsed = false
    self.isPropagated = false
    self.tileId = nil
    -- game.print(string.format('cell %s has %s options after reset', self.id, #self.options))
end

-- #tag setTiles
function WfcCell:setTiles(tilesMap)
    self.tilesMap = tilesMap
    self.options = {}
    for key, _ in pairs(tilesMap) do
        table.insert(self.options, key)
    end
end

-- #tag getCode
function WfcCell:getCode()
    return self.isCollapsed and tostring(self.tileId) or "."
end

-- #tag setNeighbors
function WfcCell:setNeighbors(ns)
    self.neighbors = ns
    -- Create looped neighbors (copy + first element)
    self._neighborsLooped = {}
    for i = 1, #ns do
        self._neighborsLooped[i] = ns[i]
    end

    -- TODO why table is incorrect?

    local string_table = {}

    for _, value in ipairs(self.neighbors) do
        if value then
            table.insert(string_table, value.id)
        else
            table.insert(string_table, ' XXX ')
        end
    end


    -- print(string.format('cell %s has neighbors %s', self.id, table.concat(string_table, ' ')))
    table.insert(self._neighborsLooped, ns[1])
end

-- #tag collapse
function WfcCell:collapse()
    if self.isCollapsed then return end
    self.isCollapsed = true

    -- game.print(string.format('cell %s collapsed from %s', self.id, cause))

    if #self.options == 1 then
        self.tileId = self.options[1]
        self:collapseCallback(self)
        return
    end

    if #self.options == 0 then
        self.tileId = nil
        self:collapseCallback(self)
        return
    end

    -- Lua arrays are 1-indexed
    local randomIndex = math.random(1, #self.options)
    self.tileId = self.options[randomIndex]
    self:collapseCallback(self)
    return
end

-- #tag getNonCollapsedNeighbors
function WfcCell:getNonCollapsedNeighbors()
    local result = {}
    for _, n in ipairs(self.neighbors) do
        if n and not n.isCollapsed then
            table.insert(result, n)
        end
    end
    return result
end

-- #tag getCollapsedNeighbors
function WfcCell:getCollapsedNeighbors()
    local result = {}
    for _, n in ipairs(self.neighbors) do
        if n and n.isCollapsed then
            table.insert(result, n)
        end
    end
    return result
end

-- TODO fix

-- #tag updateOptions
function WfcCell:updateOptions()
    if self.isCollapsed then return false end

    local newFiltered = {}

    -- game.print(string.format('check overlap between %s of chunk %s and %s of chunk %s', self.id, self
    --                 .chunkID,
    --                 neighbor.id, neighbor.chunkID))

    for _, tileId in ipairs(self.options) do
        local tile = self.tilesMap[tileId]
        local tileIsOk = true

        for dir = 1, 4 do
            local neighbor = self.neighbors[dir]

            if not neighbor then
                goto continue
            end

            -- TODO check how tiles from different chunks interact
            if neighbor.chunkID > self.chunkID then
                -- game.print(string.format('cell %s neighbor %s discarded by chunkID (%s vs %s)', self.id, neighbor.id,
                --     self.chunkID, neighbor.chunkID))

                goto continue
            end

            if not neighbor.isCollapsed then
                goto continue
            end

            local neighborTile = self.tilesMap[neighbor.tileId]

            if not tile:isOverlapping(neighborTile, dir) then
                tileIsOk = false
                break
            end

            ::continue::
        end

        if tileIsOk then
            table.insert(newFiltered, tileId)
        end
    end



    if #self.options == #newFiltered then
        return false
        -- else
        --     game.print(string.format('cell %s filtered options from %s to %s', self.id, #self.options, #newFiltered))
    end

    self.options = newFiltered

    if #self.options == 0 then
        return ERRORS.CELL_NO_OPTIONS
    end

    if #self.options == 1 then
        self:collapse()
    end

    return true
end

-- #tag verifyNeighbors
function WfcCell:verifyNeighbors(log)
    if not self.isCollapsed then
        table.insert(log,
            string.format('cell %s is not collapsed', self.id))
    end

    for dir = 1, 4 do
        local tile = self.tilesMap[self.tileId]
        local neighbor = self.neighbors[dir]

        if not neighbor or not neighbor.isCollapsed then
            goto continue
        end

        local neighborTile = self.tilesMap[neighbor.tileId]

        if not tile:isOverlapping(neighborTile, dir) then
            local oppositeDir = ((dir + 1) % 4) + 1
            table.insert(log,
                string.format('cell verify: cell %s does not match cell %s in direction %s: %s %s, types  %s  %s',
                    self.id,
                    neighbor.id, dir,
                    tile.edges[dir], neighborTile.edges[oppositeDir], tile.type, neighborTile.type))
        end

        ::continue::
    end
end

-- #endregion Cell

local WfcChunk = {}
WfcChunk.__index = WfcChunk

-- #region Chunk
function WfcChunk.new(grid, gridSize, position, chunkSize, id)
    local self = setmetatable({}, WfcChunk)

    self.id = id

    self.position = position -- x,y
    self.size = chunkSize    -- w,h

    self.gridSize = gridSize -- w,h

    self.grid = grid
    self.subgrid = self:build_subgrid()

    self.isFailed = false
    self.isSolved = false

    self.collapsedCells = 0

    self.triedToStartWith = {}
    self.hasPossibleSolutions = true

    return self
end

-- #tag cell_collapse_callback
function WfcChunk:cell_collapse_callback(cell)
    self.collapsedCells = self.collapsedCells + 1
    -- game.print(string.format('  cell %s collapsed to %s, chunk %s collapsed %s of %s', cell.id, cell.tileId, self.id, self.collapsedCells, #self.subgrid))
    if self.collapsedCells == #self.subgrid then
        game.print(string.format('- !!! chunk %s collapsed', self.id))
        self.isSolved = true
    end
end

-- #tag build_subgrid
function WfcChunk:build_subgrid()
    -- print(string.format('parent grid size %s', #self.grid))
    local subgrid = {}

    local max = 0
    local min = #self.grid

    local startIndex = (self.position.y - 1) * self.gridSize.w + self.position.x

    for y = 1, self.size.h do
        local l = 1
        local r = self.size.w
        local inc = 1

        if y % 2 == 0 then
            l, r = r, l
            inc = -1
        end

        -- print()

        for x = l, r, inc do
            local gridX = x - 1
            local gridY = y - 1

            local parentGridIndex = startIndex + (gridY) * self.gridSize.w + gridX

            -- io.write(parentGridIndex .. ' ' )

            max = math.max(max, parentGridIndex)
            min = math.min(min, parentGridIndex)

            local bounds = true
            local value = nil

            if parentGridIndex < 1 or parentGridIndex > #self.grid then
                bounds = false
            end

            if bounds then
                value = self.grid[parentGridIndex]
                value.chunkID = self.id
                value.collapseCallback = function(cell) self:cell_collapse_callback(cell) end
            else
                print(string.format('    value at %s %s', gridX, gridY))
            end

            -- subgrid[y][x] = self.grid[gridY][gridX] -- linking value
            table.insert(subgrid, value)
            -- self.position.x
        end
    end
    game.print(string.format('subgrid size %s with parent index %s to %s', #subgrid, min, max))
    return subgrid
end

-- #tag reset
function WfcChunk:reset()
    self.isFailed = false
    self.isSolved = false
    self.collapsedCells = 0

    for _, cell in ipairs(self.subgrid) do
        cell:reset()
    end

    for _, cell in ipairs(self.subgrid) do
        -- TODO check for errors, if any cell has no options - backtrack to previous chunk
        local result = cell:updateOptions()
        if result == ERRORS.CELL_NO_OPTIONS then
            self.isFailed = true
            self.hasPossibleSolutions = false
            game.print('!!! NO OPTIONS ON RESET !!!')
            break
        end
    end
end

-- #endregion Chunk

-- #region WFC
-- WFC main class
local WFC = {}
WFC.__index = WFC

function WFC.new(area, tilesMap, rules)
    local chunkSize = settings.global[settings_config.WFC_CHUNK_SIZE.name].value

    local self = setmetatable({}, WFC)

    self.ready = false
    self.failed = false

    self.grid = {}
    self.tilesMap = tilesMap
    self.hSymmetry = false
    self.vSymmetry = false

    self.neighbors4 = {
        { 0,  -1 },
        { 1,  0 },
        { 0,  1 },
        { -1, 0 }
    }

    self.neighbors8 = {
        { -1, -1 },
        { 0,  -1 },
        { 1,  -1 },
        { 1,  0 },
        { 1,  1 },
        { 0,  1 },
        { -1, 1 },
        { -1, 0 }
    }

    self.neighborsSet = self.neighbors4

    self.targetSize = {
        w = 0,
        h = 0
    }

    self.size, self.targetSize = self:getGridSizeFromArea(area)

    self.chunkSize = {
        w = chunkSize,
        h = chunkSize
    }

    self.chunks = {}

    self.rules = rules or {}

    -- TODO wtf is this
    -- Build values array with frequency
    self.values = {}
    for tileId, tile in pairs(tilesMap) do
        for i = 1, (tile.frequency or 1) do
            table.insert(self.values, tileId)
        end
    end

    return self
end

-- #tag getGridSizeFromArea
function WFC:getGridSizeFromArea(area)
    local chunkSize = settings.global[settings_config.WFC_CHUNK_SIZE.name].value
    local tileSize = settings.global[settings_config.IMPORT_TILE_SIZE.name].value
    local tileOverlap = settings.global[settings_config.RENDER_OVERLAP_TILES.name].value
    local verticalSymmetry = settings.global[settings_config.WFC_SYMMETRY_VERTICAL.name].value
    local horizontalSymmetry = settings.global[settings_config.WFC_SYMMETRY_HORIZONTAL.name].value

    -- size in tiles
    local areaSize = {
        w = math.floor(area.right_bottom.x) - math.floor(area.left_top.x),
        h = math.floor(area.right_bottom.y) - math.floor(area.left_top.y)
    }

    game.print(string.format('!!! area size %s %s', areaSize.w, areaSize.h))

    local rawGridSize = {
        w = math.ceil(areaSize.w / tileSize),
        h = math.ceil(areaSize.h / tileSize)
    }

    if tileOverlap then
        rawGridSize = {
            w = math.ceil(areaSize.w / (tileSize - 1)), -- check for better option
            h = math.ceil(areaSize.h / (tileSize - 1))
        }
    end

    local targetSize = {
        w = math.ceil(rawGridSize.w / chunkSize) * chunkSize,
        h = math.ceil(rawGridSize.h / chunkSize) * chunkSize,
    }

    -- TODO check when to apply symmetry, rawGridSize or earlier\later
    -- if verticalSymmetry then
    --     rawGridSize.h = math.ceil(rawGridSize.h / 2)
    -- end

    -- if horizontalSymmetry then
    --     rawGridSize.w = math.ceil(rawGridSize.w / 2)
    -- end

    game.print(string.format('!!! raw grid size %s %s', rawGridSize.w, rawGridSize.h))

    local finalSize = {
        w = math.ceil(rawGridSize.w / chunkSize) * chunkSize,
        h = math.ceil(rawGridSize.h / chunkSize) * chunkSize,
    }

    game.print(string.format('!!! final grid size %s %s', finalSize.w, finalSize.h))

    return finalSize, targetSize
end

-- #tag buildGrid
function WFC:buildGrid()
    self.grid = {}

    for i = 0, self.size.h - 1 do
        for k = 0, self.size.w - 1 do
            -- Copy all values
            local allValues = {}
            for _, v in ipairs(self.values) do
                table.insert(allValues, v)
            end

            local newCell = WfcCell.new(k, i, allValues, self.rules, self.tilesMap)
            table.insert(self.grid, newCell)
            newCell.id = #self.grid -- TODO fix
        end
    end

    for _, cell in ipairs(self.grid) do
        -- TODO fix +1 hack
        cell:setNeighbors(self:getNeighbors(cell.x + 1, cell.y + 1))
    end

    -- game.print(string.format('wfc grid size %s', #self.grid))

    self.chunks = self:buildChunks()
end

-- #tag buildChunks
function WFC:buildChunks()
    local hChunks = math.ceil(self.size.w / self.chunkSize.w)
    local vChunks = math.ceil(self.size.h / self.chunkSize.h)

    local chunksAmount = hChunks * vChunks

    local chunks = {}

    for y = 1, vChunks do
        local l = 1
        local r = hChunks
        local inc = 1

        if y % 2 == 0 then
            l, r = r, l
            inc = -1
        end

        for x = l, r, inc do
            local chunkPosition = {
                x = 1 + (x - 1) * self.chunkSize.w,
                y = 1 + (y - 1) * self.chunkSize.h,
            }

            game.print(string.format('chunkPosition %s %s', chunkPosition.x,
                chunkPosition.y))

            local chunk = WfcChunk.new(self.grid, self.size, chunkPosition, self.chunkSize, #chunks + 1)

            table.insert(chunks, chunk)

            game.print(string.format('  chunk %s created at %s,%s total chunks %s', chunk.id, chunkPosition.x,
                chunkPosition.y, #chunks))
        end
    end

    return chunks
end

-- #tag getFirstRandomCell
function WFC:getFirstRandomCell(chunk)
    -- TODO add checking chunk's triedToStartWith?

    local grid = chunk.subgrid

    local rnd
    local cell
    local t = 10

    repeat
        rnd = math.random(1, #grid)
        cell = grid[rnd]
        t = t + 1
    until (not cell.isCollapsed and not chunk.triedToStartWith[cell.id]) or t > 0

    if cell.isCollapsed then
        print('-- WTF --')
    end

    return cell

    -- game.print(string.format('first random cell %s', cell.id))
end

-- #tag getLowestEntropyCell
function WFC:getLowestEntropyCell(chunk, isFirstCell)
    isFirstCell = isFirstCell or false
    local grid = chunk.subgrid or self.grid -- default to global grid

    -- game.print(string.format('getLowestEntropyCell called with isFirstCell %s', isFirstCell))

    if isFirstCell then
        return self:getFirstRandomCell(grid);
    end


    local lowest = #self.values
    local result = nil

    for _, cell in ipairs(grid) do
        if cell.options ~= nil and not cell.isCollapsed then
            if #cell.options < lowest or
                (#cell.options == lowest and math.random() > 0.5) then
                result = cell
                lowest = #cell.options
            end
        end
    end

    if result == nil then
        game.print(string.format('no cell to collapse %s %s', result == nil, lowest))
        return nil
    end

    if lowest == 0 then
        game.print(string.format('cell has no options %s %s', result == nil, lowest))
        return ERRORS.CELL_NO_OPTIONS
    end

    -- game.print(string.format('  -- found cell to collapse %s', result.id))
    return result
end

-- #tag getCell
function WFC:getCell(x, y)
    -- Convert 2D coordinates to 1D array index (1-indexed)
    return self.grid[y * self.size.w + x + 1]
end

-- #tag getNeighbors
function WFC:getNeighbors(x, y)
    local neighbors = {}

    -- print(string.format('getNeighbors %s %s', x, y))
    for _, n in ipairs(self.neighborsSet) do
        -- print(x, y, x + n[1] < 1, x + n[1] >= self.size.w,
        --     y + n[2] < 1, y + n[2] >= self.size.h)

        if x + n[1] < 1 or x + n[1] > self.size.w or
            y + n[2] < 1 or y + n[2] > self.size.h then
            table.insert(neighbors, false)
        else
            -- TODO fix -1 hack
            table.insert(neighbors, self:getCell(x + n[1] - 1, y + n[2] - 1))
        end
    end

    return neighbors
end

-- #tag propagateWave
function WFC:propagateWave(grid)
    grid = grid or self.grid -- default to global grid
    local result = true
    local isAnythingUpdated = false
    while result do
        result = false
        for _, c in ipairs(grid) do
            if c.isCollapsed and not c.isPropagated then
                c.isPropagated = true
                local activeNeighbors = c:getNonCollapsedNeighbors()
                if #activeNeighbors > 0 then
                    for _, neighbor in ipairs(activeNeighbors) do
                        if neighbor.chunkID == c.chunkID then
                            -- game.print(string.format('  cell %s is propagating to %s', c.id, neighbor.id))
                            local propagateResult = neighbor:updateOptions()
                            result = result or propagateResult

                            if result == ERRORS.CELL_NO_OPTIONS then
                                return ERRORS.CELL_NO_OPTIONS
                            else
                                isAnythingUpdated = true
                            end
                        end
                    end
                end
            end
        end
    end
    return isAnythingUpdated
end

-- #tag _solveAttempt
function WFC:_solveAttempt(chunkToSolve, attemptN)
    game.print(string.format('-> attempt %s to solve chunk %s', attemptN, chunkToSolve.id))
    chunkToSolve:reset()

    if chunkToSolve.isFailed then
        return ERRORS.CELL_NO_OPTIONS
    end

    game.print(string.format('-> chunk %s has collapsed cells %s', chunkToSolve.id, chunkToSolve.collapsedCells))
    local counter = self.chunkSize.w * self.chunkSize.h * 10

    local cellToCollapse

    local isFirstCell = true

    while counter > 0 do
        -- game.print(string.format('counter %s %s', counter, counter == self.chunkSize.w * self.chunkSize.h))
        cellToCollapse = self:getLowestEntropyCell(chunkToSolve, counter == self.chunkSize.w * self.chunkSize.h)
        -- isFirstCell = false
        -- counter = counter - 1

        if getmetatable(cellToCollapse) ~= WfcCell then
            -- game.print(string.format('no cell to collapse? %s %s', cellToCollapse == nil,
            --     cellToCollapse == ERRORS.CELL_NO_OPTIONS))

            chunkToSolve.isFailed = not chunkToSolve.isSolved

            if isFirstCell then
                return cellToCollapse
            end
            return nil
        end

        ---@diagnostic disable-next-line: need-check-nil
        cellToCollapse:collapse()

        if isFirstCell then
            ---@diagnostic disable-next-line: need-check-nil
            -- game.print(string.format('--> first cell %s collapsed to tile %s', cellToCollapse.id, cellToCollapse.tileId))
            ---@diagnostic disable-next-line: need-check-nil
            chunkToSolve.triedToStartWith[cellToCollapse.id] = { cellToCollapse.tileId }
        end

        local propagateResult = self:propagateWave(chunkToSolve.subgrid)

        if propagateResult == ERRORS.CELL_NO_OPTIONS then
            chunkToSolve.isFailed = true
            -- game.print(string.format('break at %s', counter))
            break
        end

        isFirstCell = false
        counter = counter - 1
    end

    -- if failed then
    -- game.print(string.format('--resetting chunk at %s of %s', counter, self.chunkSize.w * self.chunkSize.h))
    -- end

    return cellToCollapse
end

-- -- #tag step
function WFC:step()

end

-- #tag solve
function WFC:solve(finishCallback, stepCallback, chunkCallback)
    self:buildGrid()

    local attempts = settings.global[settings_config.WFC_SOLVE_ATTEMPTS_LIMIT.name].value
    local attemptsForCurrentChunk = attempts

    local att = attempts

    self.ready = false

    local chunkIndex = 1

    local backtrackAmount = 1

    self.cycleFunc = function()
        if att > 0 then
            att = att - 1
            local chunkToSolve = self.chunks[chunkIndex]


            if storage.greeble_progress and storage.greeble_progress.valid then
                storage.greeble_progress.value = (chunkIndex) / #self.chunks
            end

            if storage.greeble_attempts and storage.greeble_attempts.valid then
                storage.greeble_attempts.value = (att) / attempts
            end


            -- TODO fix dirty hack
            -- if chunkIndex < #self.chunks then
            --     self.chunks[chunkIndex + 1]:reset()
            -- end

            game.print('')
            local prevRun = self:_solveAttempt(chunkToSolve, attemptsForCurrentChunk - att)


            if stepCallback then
                stepCallback(att / attempts)
            end

            -- TODO check why it breaks generation
            if chunkToSolve.isSolved then
                -- backtrackAmount = math.max(backtrackAmount - 1, 1) -- TODO test this

                backtrackAmount = 0
                chunkIndex = chunkIndex + 1

                if chunkIndex > #self.chunks then
                    self.ready = true
                end

                attemptsForCurrentChunk = att
                if chunkCallback then
                    chunkCallback()
                end
                game.print(string.format('move to chunk %s of %s', chunkIndex, #self.chunks))
                return -- TODO sure?
            else
                if not chunkToSolve.hasPossibleSolutions and chunkIndex > backtrackAmount then
                    -- TODO fix hack
                    backtrackAmount = math.min(backtrackAmount + 2, chunkIndex - 2)
                    -- TODO fix hack
                    chunkToSolve.triedToStartWith = {}
                    chunkIndex = chunkIndex - backtrackAmount -- TODO test

                    for i = chunkIndex + 1, #self.chunks do
                        self.chunks[i].triedToStartWith = {}
                    end

                    attemptsForCurrentChunk = att
                    game.print(string.format('11 move back to chunk %s of %s', chunkIndex, #self.chunks))
                    return -- TODO sure?
                end

                if (attemptsForCurrentChunk - att > 5) and chunkIndex > 1 then
                    backtrackAmount = math.min(backtrackAmount + 2, chunkIndex - 2)
                    -- TODO fix hack
                    chunkToSolve.triedToStartWith = {}
                    chunkIndex = chunkIndex - backtrackAmount -- TODO test

                    for i = chunkIndex + 1, #self.chunks do
                        self.chunks[i].triedToStartWith = {}
                    end

                    self.chunks[chunkIndex].triedToStartWith = {}

                    attemptsForCurrentChunk = att
                    game.print(string.format('22 move back to chunk %s of %s', chunkIndex, #self.chunks))
                    return -- TODO sure?
                end
            end

            game.print(string.format('just move on with chunk %s: | solved: %s | failed: %s ', chunkToSolve.id,
                chunkToSolve.isSolved, chunkToSolve.isFailed))

            -- game.print(att)
        else
            self.failed = true
            game.print(att)
        end

        if finishCallback then
            finishCallback(att)
        end
        return false
    end

    self.cycleFunc()
    -- For Factorio, you'd need to implement this differently
    -- using game.on_nth_tick or similar event handlers
    return nil
end

-- #tag collapseAll
function WFC:collapseAll()
    for _, cell in ipairs(self.grid) do
        cell:collapse()
    end
end

-- #tag exportWithCoordinates
function WFC:exportWithCoordinates()

    game.print(string.format('WFC EXPORT        size %s %s', self.size.w, self.size.h))
    game.print(string.format('WFC EXPORT target size %s %s', self.targetSize.w, self.targetSize.h))

    local result = {}
    for _, cell in ipairs(self.grid) do
        if cell.tileId == 0 then game.print('zero id') end
        table.insert(result, {
            x = cell.x,
            y = cell.y,
            value = cell.tileId
        })

        -- table.insert(result, {
        --     x = self.targetSize.w - cell.x + 5 ,
        --     y = cell.y,
        --     value = cell.tileId,
        --     rotated = 0,
        --     reflected = 1
        -- })

        -- table.insert(result, {
        --     x = cell.x,
        --     y = self.targetSize.h - cell.y + 5,
        --     value = cell.tileId,
        --     rotated = 0,
        --     reflected = 2
        -- })

        -- table.insert(result, {
        --     x = self.targetSize.w - cell.x + 5,
        --     y = self.targetSize.h - cell.y + 5,
        --     value = cell.tileId,
        --     rotated = 0,
        --     reflected = 3
        -- })
    end
    return result
end

-- #tag debugGrid
function WFC:debugGrid()
    local log = {}
    for y = 1, self.size.h do
        for d = 1, 3 do
            local output = {}
            for x = 1, self.size.w do
                local cell = self:getCell(x - 1, y - 1)

                local tile = self.tilesMap[cell.tileId]

                if d == 1 then
                    table.insert(output, string.format("%4d  ", cell.id))
                    cell:verifyNeighbors(log)
                else
                    table.insert(output, '      ')
                end

                table.insert(output, table.concat(tile.data[d], ' - '))

                if x % self.chunkSize.w == 0 then
                    table.insert(output, '|')
                end
            end
            -- table.insert(tile.data[d][x])

            game.print(table.concat(output, '   '))
        end
        if y % self.chunkSize.h == 0 then
            game.print(string.rep('---', 42))
        else
            game.print('')
        end
    end

    for _, l in ipairs(log) do
        game.print(l)
    end
end

-- #endregion WFC

return {
    WFC = WFC,
    WfcCell = WfcCell,
    Rule = Rule,
}
