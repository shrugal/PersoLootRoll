---@type Addon
local Addon = select(2, ...)
local AceEvent = LibStub("AceEvent-3.0")
local Util = Addon.Util
---@class Registrar
local Self = Util.Registrar

---
-- A hash or list of entries that can be accessed and updated by key, fires
-- approriate events for every such operation and offers quick access to table
-- utility functions in Util.
---

Self.EVENT_SET = "SET"
Self.EVENT_UPDATE = "UPDATE"
Self.EVENT_REMOVE = "REMOVE"
Self.EVENT_CHANGE = "CHANGE"

-- Create a new registrar instance
---@param name string       The name for this registrar, used to generate an event prefix
---@param idKey any         If passed the registrar operates as a continually indexed list
---@param addFn function    Custom "Add" function
---@return Registrar        The new registrar
function Self.New(name, idKey, addFn)
    local prefix = "PLR_" .. name

    return setmetatable({
        idKey = idKey,
        register = {},
        prefix = prefix,
        EVENT_SET = prefix .. "_" .. Self.EVENT_SET,
        EVENT_UPDATE = prefix .. "_" .. Self.EVENT_UPDATE,
        EVENT_REMOVE = prefix .. "_" .. Self.EVENT_REMOVE,
        EVENT_CHANGE = prefix .. "_" .. Self.EVENT_CHANGE,
        Add = addFn and function (self, key, ...)
            return self:Set(key, addFn(key, ...))
        end or nil
    }, {__index = Self})
end

-- Get an entry by key
---@param key any
---@return any
---@return any
function Self:Get(key)
    if self.idKey then
        local i, v = Util.Tbl.FindWhere(self.register, self.idKey, key)
        return v, i
    else
        return self.register[key]
    end
end

-- Set an entry for the given key
---@param key any
---@param val any
---@param i integer Position in the list
---@return any
function Self:Set(key, val, i)
    local prev, prevI = self:Get(key)

    if self.idKey then
        val[self.idKey] = key

        if prev and i ~= prevI then
            tremove(self.register, prevI)
            i = i > prevI and i - 1 or i
        else
            i = i or prevI
        end
    end

    Util.Tbl.Insert(self.register, not self.idKey and key or i, val, not self.idKey or prev)
    self:SendMessage(Self.EVENT_SET, key, val, prev, i or #self.register)

    return val
end

-- Update an entry by key
---@param key any
---@return any
function Self:Update(key, ...)
    local val = self:Get(key)
    if val then
        for i=1, select("#", ...), 2 do
            local k, v = select(i, ...), select(i+1, ...)
            val[k] = v
            Self:SendMessage(Self.EVENT_UPDATE, key, val, k, v)
        end
    end

    return val
end

-- Remove one or more entries by key
---@vararg any A list of keys
function Self:Remove(...)
    for _,key in Util.Each(...) do
        local val, i = self:Get(key)
        if val ~= nil then
            Util.Tbl.Remove(self.register, not self.idKey and key or i, not self.idKey)
            self:SendMessage(Self.EVENT_REMOVE, key, val)
        end
    end
end

-- Interate through all entries
function Self:Iter()
    if self.idKey then
        return ipairs(self.register)
    else
        return pairs(self.register)
    end
end

-- Get a list of keys
function Self:Keys()
    if self.idKey then
        return Util(self.register):Copy():Pluck(self.idKey)()
    else
        return Util.Tbl.Keys(self.register)
    end
end

-- Makes Util table functions available on the Registrar instance
local k
local fn = function (self, ...)
    return Util.Tbl[k](self.register, ...)
end
setmetatable(Self, {
    __index = function (self, key)
        if Util.Tbl[key] then
            k = key
            return fn
        end
    end
})

-- Helper to fire events
---@param msg string
function Self:SendMessage(msg, ...)
    local e = self.prefix .. "_" .. msg

    AceEvent.messages.Fire(self, e, ...)
    AceEvent.messages.Fire(self, Self.EVENT_CHANGE, e, ...)
end
