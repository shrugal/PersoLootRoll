if not WoWUnit then return end

---@type string
local Name = ...
---@type Addon
local Addon = select(2, ...)
local AssertEqual, Replace = WoWUnit.AreEqual, WoWUnit.Replace

---@class Tests
Addon.Test = {}
local Self = Addon.Test

function Self.Dump(o, d)
    d = d or 1
    local s, i = "", (" "):rep(d * 4)
    if type(o) == "table" then
        for k,v in pairs(o) do
            if type(k) ~= "string" then k = '['..k..']' end
            s = s .. (#s > 0 and "," or "") .. "\n" .. i .. k .. " = " .. Self.Dump(v, d + 1)
        end
        s = "{" .. (#s > 0 and s .. "\n" .. (" "):rep((d - 1) * 4) or s) .. "}"
    elseif type(o) == "string" then
        s = '"' .. o .. '"'
    else
        s = tostring(o)
    end
    if d > 1 then return s else print(s) end
 end

function Self.MockFunction(fn, mock)
    local calls = 0
    local call = function (...)
        calls = calls + 1
        if mock then
            return mock(...)
        elseif mock == nil then
            return fn(...)
        end
    end
    local test = function (n)
        AssertEqual(n or 1, calls)
    end
    local get = function () return calls end
    local set = function (n) calls = n or 0 end
    return call, test, get, set
end

function Self.ReplaceFunction(obj, key, mock)
    local fn, test
    if type(obj) == "function" then
        fn, test = Self.MockFunction(obj, key)
        Replace(obj, fn)
    else
        fn, test = Self.MockFunction(obj[key], mock)
        Replace(obj, key, fn)
    end
    return test
end