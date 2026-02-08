
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

return Rule

-- test 222222