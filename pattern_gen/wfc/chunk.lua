local ERRORS = require('pattern_gen/wfc/definitions').ERRORS

---@alias Point { x: integer, y: integer }
---@alias Size { w: integer, h: integer }

---@class Chunk (exact)
---@field id integer
---@field position Point
---@field size Size
---@field gridSize Size
---@field grid Cell[]
---@field subgrid table
---@field isFailed boolean
---@field isSolved boolean
---@field collapsedCells integer
---@field triedToStartWith table
---@field hasPossibleSolutions boolean
local Chunk = {}
Chunk.__index = Chunk

function Chunk.new(grid, gridSize, position, chunkSize, id)
    local self = setmetatable({}, Chunk)

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
function Chunk:cell_collapse_callback(cell)
    self.collapsedCells = self.collapsedCells + 1
    -- -- game.print(string.format('  cell %s collapsed to %s, chunk %s collapsed %s of %s', cell.id, cell.tileId, self.id, self.collapsedCells, #self.subgrid))
    if self.collapsedCells == #self.subgrid then
        -- game.print(string.format('- !!! chunk %s collapsed', self.id))
        self.isSolved = true
    end
end

-- #tag build_subgrid
function Chunk:build_subgrid()
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
    -- game.print(string.format('subgrid size %s with parent index %s to %s', #subgrid, min, max))
    return subgrid
end

-- #tag reset
function Chunk:reset()
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
            -- game.print('!!! NO OPTIONS ON RESET !!!')
            break
        end
    end
end

return Chunk
