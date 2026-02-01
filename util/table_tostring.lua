-- https://stackoverflow.com/a/61541952
local function table_tostring(table)
    local index = 1
    local holder = "{"
    while true do
       if type(table[index]) == "function" then
          index = index + 1
       elseif type(table[index]) == "table" then
          holder = holder..table_tostring(table[index])
       elseif type(table[index]) == "number" then
          holder = holder..tostring(table[index])
       elseif type(table[index]) == "string" then
          holder = holder.."\""..table[index].."\""
       elseif table[index] == nil then
          holder = holder.."nil"
       elseif type(table[index]) == "boolean" then
          holder = (table[index] and "true" or "false")
       end
       if index + 1 > #table then
         break
       end
       holder = holder..","
       index = index + 1
    end
    return holder.."}"
 end

 return table_tostring