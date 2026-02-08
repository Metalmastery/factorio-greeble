local ERRORS = require('pattern_gen/wfc/definitions').ERRORS

---@class Cell
---@field tilesMap Tile[]
---@field options table
---@field rules table
---@field neighbors table
---@field _neighborsLooped table
---@field x integer
---@field y integer
---@field isCollapsed boolean
---@field isPropagated boolean
---@field tileId integer
---@field chunkID integer
---@field id integer
---@field collapseCallback function(): void
local Cell = {}
Cell.__index = Cell

function Cell.new(x, y, options, rules, tilesMap)
    local self = setmetatable({}, Cell)
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
function Cell:reset()
    self:setTiles(self.tilesMap)
    self.isCollapsed = false
    self.isPropagated = false
    self.tileId = nil
    -- -- game.print(string.format('cell %s has %s options after reset', self.id, #self.options))
end

-- #tag setTiles
function Cell:setTiles(tilesMap)
    self.tilesMap = tilesMap
    self.options = {}
    for key, _ in pairs(tilesMap) do
        table.insert(self.options, key)
    end
end

-- #tag getCode
function Cell:getCode()
    return self.isCollapsed and tostring(self.tileId) or "."
end

-- #tag setNeighbors
function Cell:setNeighbors(ns)
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
function Cell:collapse()
    if self.isCollapsed then return end
    self.isCollapsed = true

    -- -- game.print(string.format('cell %s collapsed from %s', self.id, cause))

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

-- #tag collapseToSymmetric
---@param cell Cell
---@param verticalSymmetry boolean
---@param horizontalSymmetry boolean
function Cell:collapseToSymmetric(cell, horizontalSymmetry, verticalSymmetry)
    -- TODO refactor this
    -- get other cell's tile
    -- get other tile's reflection (full code or edges?)
    -- find option that matches that code
    local otherTile = self.tilesMap[cell.tileId]

    -- local ownTile = self.tilesMap[self.tileId]

    local codeTable = { otherTile.edges[DIRECTION.TOP], otherTile.edges[DIRECTION.RIGHT], otherTile.edges[DIRECTION.BOTTOM], otherTile.edges[DIRECTION.LEFT]}

    if horizontalSymmetry then
        codeTable = { otherTile.edges[DIRECTION.TOP], otherTile.edges[DIRECTION.LEFT], otherTile.edges[DIRECTION.BOTTOM], otherTile.edges[DIRECTION.RIGHT]}
    end

    if verticalSymmetry then
        codeTable = { otherTile.edges[DIRECTION.BOTTOM], otherTile.edges[DIRECTION.RIGHT], otherTile.edges[DIRECTION.TOP], otherTile.edges[DIRECTION.LEFT]}
    end

    if horizontalSymmetry and verticalSymmetry then
        codeTable = { otherTile.edges[DIRECTION.BOTTOM], otherTile.edges[DIRECTION.LEFT], otherTile.edges[DIRECTION.TOP], otherTile.edges[DIRECTION.RIGHT]}
    end

    local codeToMatch = table.concat(codeTable, ".")

    local filteredOption = {}

    for _, tileId in ipairs(self.options) do
        local tile = self.tilesMap[tileId]
        
        if tile.code == codeToMatch then
            table.insert(filteredOption, tileId)
        end
    end 

    self.options = filteredOption

    self:collapse()
end

-- #tag getNonCollapsedNeighbors
function Cell:getNonCollapsedNeighbors()
    local result = {}
    for _, n in ipairs(self.neighbors) do
        if n and not n.isCollapsed then
            table.insert(result, n)
        end
    end
    return result
end

-- #tag getCollapsedNeighbors
function Cell:getCollapsedNeighbors()
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
function Cell:updateOptions()
    if self.isCollapsed then return false end

    local newFiltered = {}

    -- -- game.print(string.format('check overlap between %s of chunk %s and %s of chunk %s', self.id, self
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
                -- -- game.print(string.format('cell %s neighbor %s discarded by chunkID (%s vs %s)', self.id, neighbor.id,
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
        --     -- game.print(string.format('cell %s filtered options from %s to %s', self.id, #self.options, #newFiltered))
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
function Cell:verifyNeighbors(log)
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

return Cell
