---@type Addon
local Addon = select(2, ...)
local Util = Addon.Util
---@class Counter
local Self = Util.Counter

-- Create a table that tracks the highest numerical index and offers count+newIndex fields and Add function
---@param t table
---@return table
function Self.New(t)
    t = t or {}
    local count = 0

    return setmetatable(t, {
        __index = function (t, k)
            return k == "count" and count
                or k == "nextIndex" and count+1
                or k == "Add" and function (v) t[count+1] = v return count end
                or rawget(t, k)
        end,
        __newindex = function (t, k, v)
            if v ~= nil and type(k) == "number" and k > count then
                count = k
            end
            rawset(t, k, v)
        end
    })
end