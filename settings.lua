local settings_config = require('pattern_gen/settings_config')

local t = {}
for key, setting in pairs(settings_config) do
    table.insert(t, setting)
end

data:extend(t)
