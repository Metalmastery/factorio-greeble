local DIRECTION = require("pattern_gen/utils").DIRECTION

local function reverse_table_inplace(arr)
    local i, j = 1, #arr
    while i < j do
        arr[i], arr[j] = arr[j], arr[i]
        i = i + 1
        j = j - 1
    end
end

local function _getAllDataRotations(data)
    local newData = data
    local result = {}
    for t = 1, 3 do
        -- Rotate 90 degrees clockwise
        local rotated = {}
        for i = 1, #newData[1] do
            rotated[i] = {}
            for j = #newData, 1, -1 do
                table.insert(rotated[i], newData[j][i])
            end
        end

        newData = rotated
        table.insert(result, rotated)
    end
    return result
end

local function _getAllDataReflections(data)
    local newDataV = {}
    local newDataH = {}
    local newDataDiagonal = {}

    -- Deep copy data
    for i = 1, #data do
        newDataV[i] = {}
        newDataH[i] = {}
        newDataDiagonal[i] = {}
        for j = 1, #data[i] do
            newDataV[i][j] = data[i][j]
            newDataH[i][j] = data[i][j]
            newDataDiagonal[i][j] = data[i][j]
        end

        reverse_table_inplace(newDataDiagonal[i])
    end

    for i = 1, #data do
        reverse_table_inplace(newDataH[i])
        -- reverse_table_inplace(newDataDiagonal[i])
    end

    reverse_table_inplace(newDataV)
    reverse_table_inplace(newDataDiagonal)

    return { newDataH, newDataV, newDataDiagonal }
end

-- Tile class
local Tile = {}
Tile.__index = Tile
Tile._idBase = 1

-- #region Tile

---@class Tile
Tile.TYPE = {
    ORIGINAL = 'ORIGINAL',
    MIRROR = 'MIRROR',
    ORIGINAL_ROTATED = 'ORIGINAL_ROTATED',
    MIRROR_ROTATED = 'MIRROR_ROTATED'
}

---@return Tile
function Tile.new(size)
    -- game.print('tile created')
    local self = setmetatable({}, Tile)

    -- self.type = Tile.TYPE.ORIGINAL
    self.type = 'ORIGINAL'

    size = size or 3
    self.size = size
    self.frequency = 1
    self.id = Tile._idBase
    Tile._idBase = Tile._idBase + 1

    self.edges = {}
    self.code = ""
    self.data = {}

    -- Initialize data grid
    for t = 1, size do
        self.data[t] = {}
        for k = 1, size do
            self.data[t][k] = nil
        end
    end

    -- Initialize edges
    for d = 1, 4 do
        self.edges[d] = ""
    end

    self.rotations = {}

    return self
end

-- #tag computeEdges
---@return nil
function Tile:computeEdges()
    -- TODO move this out
    -- self.rotations = _getAllDataRotations(self.data)
    -- self.reflections = _getAllDataReflections(self.data)

    -- TOP edge (first row)
    local topParts = {}
    local bottomParts = {}
    local leftParts = {}
    local rightParts = {}
    for i = 1, #self.data do
        table.insert(bottomParts, tostring(self.data[#self.data][i]))
        table.insert(topParts, tostring(self.data[1][i]))
        table.insert(leftParts, tostring(self.data[i][1]))
        table.insert(rightParts, tostring(self.data[i][#self.data]))
    end

    self.edges[DIRECTION.TOP] = table.concat(topParts, "-")
    self.edges[DIRECTION.BOTTOM] = table.concat(bottomParts, "-")

    self.edges[DIRECTION.LEFT] = table.concat(leftParts, "-")
    self.edges[DIRECTION.RIGHT] = table.concat(rightParts, "-")

    -- self.edges[DIRECTION.TOP] = table.concat(bottomParts, "-")
    -- self.edges[DIRECTION.BOTTOM] = table.concat(topParts, "-")

    -- self.edges[DIRECTION.LEFT] = table.concat(rightParts, "-")
    -- self.edges[DIRECTION.RIGHT] = table.concat(leftParts, "-")

    local codeTable = {
        self.edges[DIRECTION.TOP],
        self.edges[DIRECTION.RIGHT],
        self.edges[DIRECTION.BOTTOM],
        self.edges[DIRECTION.LEFT]
    }
    -- Create code from all edges
    self.code = table.concat(codeTable, ".")
    -- game.print(self.code)
end

-- #tag getRotatedData
function Tile:getRotatedData(data)
end

-- #tag getReflectedData
function Tile:getReflectedData()
end

---@return Tile[]
-- #tag getAllRotations
function Tile:getAllRotations()
    local rotatedClones = { self }
    local newData = self.data

    for t = 1, 3 do
        -- Rotate 90 degrees clockwise
        local rotated = {}
        for i = 1, #newData[1] do
            rotated[i] = {}
            for j = #newData, 1, -1 do
                table.insert(rotated[i], newData[j][i])
            end
        end

        newData = rotated

        local newTile = Tile.new(self.size)

        -- Deep copy the rotated data
        for i = 1, #newData do
            for j = 1, #newData[i] do
                newTile.data[i][j] = newData[i][j]
            end
        end

        newTile:computeEdges()

        -- if self.type == Tile.TYPE.ORIGINAL then
        --     newTile.type = Tile.TYPE.ORIGINAL_ROTATED
        -- end

        -- if self.type == Tile.TYPE.MIRROR then
        --     newTile.type = Tile.TYPE.MIRROR_ROTATED
        -- else
        --     newTile.type = 'wtf'
        -- end

        newTile.type = self.type .. '_ROTATED'

        table.insert(rotatedClones, newTile)
    end

    return rotatedClones
end

-- #tag getReflected
---@return Tile[]
function Tile:getReflected()
    local mirrorClones = { self }
    local newData = self.data

    local newTileV = Tile.new(self.size)
    local newTileH = Tile.new(self.size)
    local newTileDiagonal = Tile.new(self.size)

    -- Deep copy data
    for i = 1, #newData do
        for j = 1, #newData[i] do
            newTileV.data[i][j] = self.data[i][j]
            newTileH.data[i][j] = self.data[i][j]
            newTileDiagonal.data[i][j] = self.data[i][j]
        end

        reverse_table_inplace(newTileDiagonal.data[i])
    end

    for i = 1, #newData do
        reverse_table_inplace(newTileH.data[i])
        -- reverse_table_inplace(newTileDiagonal.data[i])
    end

    reverse_table_inplace(newTileV.data)
    reverse_table_inplace(newTileDiagonal.data)

    newTileH:computeEdges()
    newTileV:computeEdges()
    newTileDiagonal:computeEdges()

    newTileV.type = self.type .. '_MIRROR'
    newTileH.type = self.type .. '_MIRROR'
    newTileDiagonal.type = self.type .. '_MIRROR'

    -- newTileV.type = Tile.TYPE.MIRROR
    -- newTileH.type = Tile.TYPE.MIRROR
    -- newTileDiagonal.type = Tile.TYPE.MIRROR

    table.insert(mirrorClones, newTileH)
    table.insert(mirrorClones, newTileV)
    table.insert(mirrorClones, newTileDiagonal)

    return mirrorClones
end

-- #tag isOverlapping
---@return boolean
function Tile:isOverlapping(other, direction)
    if not other then return false end

    local oppositeDirection = ((direction + 1) % 4) + 1

    -- if self.edges[direction] ~= other.edges[oppositeDirection] then
    --     print(direction, oppositeDirection, getmetatable(other) == Tile, self.id, other.id)
    --     game.print(string.format('overlap %s %s %s', self.edges[direction] == other.edges[oppositeDirection],
    --         self.edges[direction], other.edges[oppositeDirection]))
    -- end

    return self.edges[direction] == other.edges[oppositeDirection]
end

-- #endregion Tile

return {
    Tile = Tile,
}
