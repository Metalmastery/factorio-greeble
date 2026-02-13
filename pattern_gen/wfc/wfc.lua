local Cell = require('pattern_gen/wfc/cell')
local Chunk = require('pattern_gen/wfc/chunk')
local ERRORS = require('pattern_gen/wfc/definitions').ERRORS
local settings_config = require('pattern_gen/settings_config')

---@alias ExportCell { x : integer, y : integer, value : integer, rotated : integer, reflected : integer }


---@class WFC
---@field ready boolean
---@field failed boolean
---@field grid Cell[]
---@field tilesMap table
---@field hSymmetry boolean
---@field vSymmetry boolean
---@field neighbors4 table
---@field neighbors8 table
---@field neighborsSet table
---@field size Size
---@field targetSize Size
---@field chunkSize Size
---@field chunks Chunk[]
---@field rules Rule[]
---@field values integer[]
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

    -- game.print(string.format('!!! area size %s %s', areaSize.w, areaSize.h))

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
    if verticalSymmetry then
        rawGridSize.h = math.ceil(rawGridSize.h / 2)
    end

    if horizontalSymmetry then
        rawGridSize.w = math.ceil(rawGridSize.w / 2)
    end

    -- game.print(string.format('!!! raw grid size %s %s', rawGridSize.w, rawGridSize.h))

    local finalSize = {
        w = math.ceil(rawGridSize.w / chunkSize) * chunkSize,
        h = math.ceil(rawGridSize.h / chunkSize) * chunkSize,
    }

    -- game.print(string.format('!!! final grid size %s %s', finalSize.w, finalSize.h))

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

            local newCell = Cell.new(k, i, allValues, self.rules, self.tilesMap)
            table.insert(self.grid, newCell)
            newCell.id = #self.grid -- TODO fix
        end
    end

    for _, cell in ipairs(self.grid) do
        -- TODO fix +1 hack
        cell:setNeighbors(self:getNeighbors(cell.x + 1, cell.y + 1))
    end

    -- -- game.print(string.format('wfc grid size %s', #self.grid))

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

            -- game.print(string.format('chunkPosition %s %s', chunkPosition.x,
            -- chunkPosition.y)

            local chunk = Chunk.new(self.grid, self.size, chunkPosition, self.chunkSize, #chunks + 1)

            table.insert(chunks, chunk)

            -- game.print(string.format('  chunk %s created at %s,%s total chunks %s', chunk.id, chunkPosition.x,
            -- chunkPosition.y, #chunks))
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

    -- -- game.print(string.format('first random cell %s', cell.id))
end

-- #tag getLowestEntropyCell
---@return Cell
function WFC:getLowestEntropyCell(chunk, isFirstCell)
    isFirstCell = isFirstCell or false
    local grid = chunk.subgrid or self.grid -- default to global grid

    -- -- game.print(string.format('getLowestEntropyCell called with isFirstCell %s', isFirstCell))

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
        -- game.print(string.format('no cell to collapse %s %s', result == nil, lowest))
        return nil
    end

    if lowest == 0 then
        -- game.print(string.format('cell has no options %s %s', result == nil, lowest))
        return ERRORS.CELL_NO_OPTIONS
    end

    -- -- game.print(string.format('  -- found cell to collapse %s', result.id))
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
                            -- -- game.print(string.format('  cell %s is propagating to %s', c.id, neighbor.id))
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
---@param chunkToSolve Chunk
---@param attemptN any
function WFC:_solveAttempt(chunkToSolve, attemptN)
    -- game.print(string.format('-> attempt %s to solve chunk %s', attemptN, chunkToSolve.id))
    chunkToSolve:reset()

    if chunkToSolve.isFailed then
        return ERRORS.CELL_NO_OPTIONS
    end

    -- game.print(string.format('-> chunk %s has collapsed cells %s', chunkToSolve.id, chunkToSolve.collapsedCells))
    local counter = self.chunkSize.w * self.chunkSize.h * 10

    local cellToCollapse

    local isFirstCell = true

    while counter > 0 do
        -- -- game.print(string.format('counter %s %s', counter, counter == self.chunkSize.w * self.chunkSize.h))
        cellToCollapse = self:getLowestEntropyCell(chunkToSolve, counter == self.chunkSize.w * self.chunkSize.h)
        -- isFirstCell = false
        -- counter = counter - 1

        if getmetatable(cellToCollapse) ~= Cell then
            -- -- game.print(string.format('no cell to collapse? %s %s', cellToCollapse == nil,
            --     cellToCollapse == ERRORS.CELL_NO_OPTIONS))

            chunkToSolve.isFailed = not chunkToSolve.isSolved

            if isFirstCell then
                return cellToCollapse
            end
            return nil
        end

        -- TODO symmetry can collapse corresponding cell using rotated\reflected data of this one
        cellToCollapse:collapse()

        if isFirstCell then
            -- -- game.print(string.format('--> first cell %s collapsed to tile %s', cellToCollapse.id, cellToCollapse.tileId))

            chunkToSolve.triedToStartWith[cellToCollapse.id] = { cellToCollapse.tileId }
        end

        local propagateResult = self:propagateWave(chunkToSolve.subgrid)

        if propagateResult == ERRORS.CELL_NO_OPTIONS then
            chunkToSolve.isFailed = true
            -- -- game.print(string.format('break at %s', counter))
            break
        end

        isFirstCell = false
        counter = counter - 1
    end

    -- if failed then
    -- -- game.print(string.format('--resetting chunk at %s of %s', counter, self.chunkSize.w * self.chunkSize.h))
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

            if storage and storage.greeble_progress and storage.greeble_progress.valid then
                storage.greeble_progress.value = (chunkIndex) / #self.chunks
            end

            if storage and storage.greeble_attempts and storage.greeble_attempts.valid then
                storage.greeble_attempts.value = (att) / attempts
            end


            -- TODO fix dirty hack
            -- if chunkIndex < #self.chunks then
            --     self.chunks[chunkIndex + 1]:reset()
            -- end

            -- game.print('')
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
                -- game.print(string.format('move to chunk %s of %s', chunkIndex, #self.chunks))
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
                    -- game.print(string.format('11 move back to chunk %s of %s', chunkIndex, #self.chunks))
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
                    -- game.print(string.format('22 move back to chunk %s of %s', chunkIndex, #self.chunks))
                    return -- TODO sure?
                end
            end

            -- game.print(string.format('just move on with chunk %s: | solved: %s | failed: %s ', chunkToSolve.id,
            -- chunkToSolve.isSolved, chunkToSolve.isFailed))

            -- -- game.print(att)
        else
            self.failed = true
            -- game.print(att)
        end

        if finishCallback then
            finishCallback(att)
        end
        return false
    end

    self.cycleFunc()
    return nil
end

-- #tag collapseAll
function WFC:collapseAll()
    for _, cell in ipairs(self.grid) do
        cell:collapse()
    end
end

-- #tag exportWithCoordinates
---@return ExportCell[]
function WFC:exportWithCoordinates()

    -- TODO fix symmetry for odd grid size
    local verticalSymmetry = settings.global[settings_config.WFC_SYMMETRY_VERTICAL.name].value
    local horizontalSymmetry = settings.global[settings_config.WFC_SYMMETRY_HORIZONTAL.name].value

    -- game.print(string.format('WFC EXPORT        size %s %s', self.size.w, self.size.h))
    -- game.print(string.format('WFC EXPORT target size %s %s', self.targetSize.w, self.targetSize.h))

    local symmetryOffset = {
        w = 2 * self.size.w - 2,
        h = 2 * self.size.h - 2
    }

    local result = {}
    for _, cell in ipairs(self.grid) do
        -- if cell.tileId == 0 then -- game.print('zero id') end
        table.insert(result, {
            x = cell.x,
            y = cell.y,
            value = cell.tileId
        })

        -- TODO remove this after moving symmetry to solving stage
        if horizontalSymmetry then
            table.insert(result, {
                x = symmetryOffset.w - cell.x,
                y = cell.y,
                value = cell.tileId,
                rotated = 0,
                reflected = 1
            })
        end

        if verticalSymmetry then
            table.insert(result, {
                x = cell.x,
                y = symmetryOffset.h - cell.y,
                value = cell.tileId,
                rotated = 0,
                reflected = 2
            })
        end

        if horizontalSymmetry and verticalSymmetry then
            table.insert(result, {
                x = symmetryOffset.w - cell.x,
                y = symmetryOffset.h - cell.y,
                value = cell.tileId,
                rotated = 0,
                reflected = 3
            })
        end
    end
    return {
        size = self.targetSize,
        tiles = result
    }
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

            -- game.print(table.concat(output, '   '))
        end
        -- if y % self.chunkSize.h == 0 then
        --     -- game.print(string.rep('---', 42))
        -- else
        --     -- game.print('')
        -- end
    end

    -- for _, l in ipairs(log) do
    --     -- game.print(l)
    -- end
end

return WFC
