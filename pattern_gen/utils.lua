local DIRECTION = {
    TOP = 1,
    RIGHT = 2,
    BOTTOM = 3,
    LEFT = 4
}

local function printTable(t, indent, name)
    indent = indent or 0
    name = name or 'root'
    local indentString = string.rep(' ', indent * 2)
    local indentString2 = string.rep(' ', (indent + 1) * 2)
    print(string.format('%s%s {', indentString, name))
    for k, v in pairs(t) do
        if type(v) == "table" then
            printTable(v, indent + 1, k)
        else
            -- If the value is another table, you need a custom function to print it recursively
            -- game.print(string.format('%s%s: %s', indentString2, k, tostring(v)))
        end
    end
    -- game.print(string.format('%s }', indentString))
end

return {
    DIRECTION = DIRECTION,
    printTable = printTable
}
