if not WoWUnit then return end

---@type string
local Name = ...
---@type Addon
local Addon = select(2, ...)
local AssertEqual, Replace = WoWUnit.AreEqual, WoWUnit.Replace
local Roll, Unit, Util = Addon.Roll, Addon.Unit, Addon.Util

---@class Tests
Addon.Test = {}
local Self = Addon.Test

Self.Fn = function () end
Self.Id = function (v) return v end
Self.Not = function (v) return not v end
Self.Const = function (v) return function () return v end end
Self.Consts = function (...) local args = {...} return function () return unpack(args) end end
Self.Val = function (v) return function (a) if a then return v end end end
Self.Vals = function (...) local args = {...} return function (...) if ... then return unpack(args) end end end

function Self.Dump(o, maxDepth, depth)
    maxDepth = maxDepth or 5
    depth = depth or 1
    local s, i = "", (" "):rep(depth * 4)
    if type(o) == "table" then
        if depth > maxDepth then
            s = "{...}"
        else
            for k,v in pairs(o) do
                if type(k) ~= "string" then k = '['..k..']' end
                s = s .. (#s > 0 and "," or "") .. "\n" .. i .. k .. " = " .. Self.Dump(v, maxDepth, depth + 1)
            end
            s = "{" .. (#s > 0 and s .. "\n" .. (" "):rep((depth - 1) * 4) or s) .. "}"
        end
    elseif type(o) == "string" then
        s = '"' .. o .. '"'
    else
        s = tostring(o)
    end
    if depth > 1 then return s else print(s) end
 end

-- Wrap fn in call counter and optionally mock it
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
        calls = 0
    end
    local get = function () return calls end
    local set = function (n) calls = n or 0 end
    return call, test, get, set
end

-- Replace a fn with a mock using Self.MockFunction
function Self.ReplaceFunction(obj, key, mock)
    if type(obj) ~= "table" then
        obj, key, mock = _G, obj, key
    end
    local fn, test = Self.MockFunction(obj[key], mock)
    Replace(obj, key, fn)
    return test
end

function Self.ReplaceLocale(mock)
    Replace(LibStub("AceLocale-3.0").apps, Name, mock or setmetatable({}, {
        __index = function (_, key) return key end
    }))
end

-- Apply default replacements to mock up a controlled test environment
function Self.ReplaceDefault()
    for _,fn in pairs({
        "GetRealmName", "UnitName", "UnitFullName", "UnitIsUnit", "UnitClass", "UnitExists",
        "GetItemInfo", "GetDetailedItemLevelInfo",
        "GetNumGroupMembers", "IsInGroup", "IsInRaid", "GetRaidRosterInfo",
        "UnitInParty", "UnitInRaid"
    }) do
        Replace(fn, Self[fn])
    end
end

-------------------------------------------------------
--                     Mock data                     --
-------------------------------------------------------

Self.units = {
    player = {name = "PlayerName", class = Unit.MAGE},
    party1 = {name = "Party1Name", class = Unit.ROGUE},
    party2 = {name = "Party2Name-Echsenkessel", class = Unit.HUNTER},
    party3 = {name = "Party3Name-Kazzak", class = Unit.WARRIOR},
    party4 = {name = "Party4Name-Chantséternels", class = Unit.PRIEST}
}

Self.items = {
    item1 = {"item1", "|Hitem:1::::::::" .. MAX_PLAYER_LEVEL .. ":66::3:1:3524:::|h[item1]|h|r", 4, 100, MAX_PLAYER_LEVEL, "Armor", "Cloth", 1, "INVTYPE_CLOAK", 2901576, 594645, 4, 1, 1, 7, nil, false},
    item2 = {"item2", "||Hitem:2::::::::" .. MAX_PLAYER_LEVEL .. ":66::3:1:3524:::|h[item2]|h|r", 4, 100, MAX_PLAYER_LEVEL, "Armor", "Cloth", 1, "INVTYPE_WRIST", 2906595, 362722, 4, 1, 1, 7, nil, false},
    item3 = {"item3", "||Hitem:3::::::::" .. MAX_PLAYER_LEVEL .. ":66::3:1:3524:::|h[item3]|h|r", 4, 100, MAX_PLAYER_LEVEL, "Armor", "Leather", 1, "INVTYPE_HAND", 2912998, 368329, 4, 2, 1, 7, nil, false},
    nil,
    item5 = {"item5", "||Hitem:5::::::::" .. MAX_PLAYER_LEVEL .. ":66::3:1:3524:::|h[item5]|h|r", 4, 100, MAX_PLAYER_LEVEL, "Armor", "Mail", 1, "INVTYPE_WAIST", 2909745, 381146, 4, 3, 1, 7, nil, false},
    item6 = {"item6", "||Hitem:6::::::::" .. MAX_PLAYER_LEVEL .. ":66::3:1:3524:::|h[item6]|h|r", 4, 100, MAX_PLAYER_LEVEL, "Armor", "Plate", 1, "INVTYPE_HAND", 2901582, 374089, 4, 4, 1, 7, nil, false},
    item7 = {"item7", "||Hitem:7::::::::" .. MAX_PLAYER_LEVEL .. ":66::3:1:3524:::|h[item7]|h|r", 4, 100, MAX_PLAYER_LEVEL, "Weapon", "One-Handed Maces", 1, "INVTYPE_WEAPON", 2923736, 1058637, 2, 4, 1, 7, nil, false},
    item8 = {"item8", "||Hitem:8::::::::" .. MAX_PLAYER_LEVEL .. ":66::3:1:3524:::|h[item8]|h|r", 4, 100, MAX_PLAYER_LEVEL, "Armor", "Plate", 1, "INVTYPE_CHEST", 2901581, 0, 4, 4, 1, 7, nil, false}
}

Self.roll = {id = 1, ownerId = 1, owner = Self.units.player.name, isOwner = true,  status = Roll.STATUS_PENDING, itemOwnerId = 1, timeout = 30, item = {owner = Self.units.player.name, isOwner = true, infoLevel = 0, link = Self.items.item1[2]}}

Self.rolls = {
    {id = 1, ownerId = 1, owner = Self.units.player.name, isOwner = true,  status = Roll.STATUS_RUNNING, itemOwnerId = 1, timeout = 30, item = {id = 1, owner = Self.units.player.name, infoLevel = 1, link = Self.items.item1[2], isTradable = true}},
    {id = 2, ownerId = 2, owner = Self.units.player.name, isOwner = true,  status = Roll.STATUS_DONE,    itemOwnerId = 2, timeout = 30, item = {id = 2, owner = Self.units.player.name, infoLevel = 1, link = Self.items.item2[2], isTradable = true}},
    {id = 3, ownerId = 1, owner = Self.units.party1.name, isOwner = false, status = Roll.STATUS_RUNNING, itemOwnerId = 1, timeout = 30, item = {id = 3, owner = Self.units.party1.name, infoLevel = 1, link = Self.items.item3[2], isTradable = true}, disenchant = true},
    nil,
    {id = 5, ownerId = 3, owner = Self.units.party2.name, isOwner = false, status = Roll.STATUS_PENDING, itemOwnerId = 3, timeout = 30, item = {id = 5, owner = Self.units.party2.name, infoLevel = 1, link = Self.items.item5[2], isTradable = true}},
    {id = 6, ownerId = 4, owner = Self.units.party2.name, isOwner = false, status = Roll.STATUS_DONE,    itemOwnerId = 4, timeout = 30, item = {id = 6, owner = Self.units.party2.name, infoLevel = 1, link = Self.items.item6[2], isTradable = true}},
    {id = 7, ownerId = 5, owner = Self.units.party3.name, isOwner = false, status = Roll.STATUS_DONE,    itemOwnerId = 7, timeout = 30, item = {id = 7, owner = Self.units.player.name, infoLevel = 1, link = Self.items.item7[2], isTradable = true}, disenchant = true},
    {id = 8, ownerId = 6, owner = Self.units.party3.name, isOwner = false, status = Roll.STATUS_DONE,    itemOwnerId = 2, timeout = 30, item = {id = 8, owner = Self.units.party1.name, infoLevel = 1, link = Self.items.item8[2], isTradable = true}, disenchant = true},
    {id = 9, ownerId = 9, owner = Self.units.player.name, isOwner = true,  status = Roll.STATUS_PENDING, itemOwnerId = 3, timeout = 30, item = {id = 8, owner = Self.units.party3.name, infoLevel = 1, link = Self.items.item8[2], isTradable = true}}
}

Self.group = Util(Self.units):Copy():Pluck("name")()

function Self.GetRealmName()
    return "Mal'Ganis"
end

function Self.Unit(v)
    return Self.units[v] or select(2, Util.Tbl.FindWhere(Self.units, "name", v))
end

function Self.UnitName(v)
    local unit = Self.Unit(v)
    if unit then
        return strsplit("-", unit.name)
    end
end

function Self.UnitFullName(v)
    local name, realm = Self.UnitName(v)
    return name, realm ~= "" and realm or name and Self.GetRealmName()
end

function Self.UnitIsUnit(a, b)
    return a and a == b or Self.Unit(a) == Self.Unit(b)
end

function Self.UnitExists(v)
    return not not Self.Unit(v)
end

function Self.UnitClass(v)
    local unit = Self.Unit(v)
    if unit then
        return GetClassInfo(unit.class)
    end
end

function Self.GetItemInfo(v)
    if v then
        return unpack(
            Self.items[v] or
            Self.items["item" .. v] or
            select(2, Util.Tbl.FindWhere(Self.items, 2, v)) or
            {}
        )
    end
end

function Self.GetDetailedItemLevelInfo(v)
    local lvl = select(4, Self.GetItemInfo(v))
    return lvl, false, lvl
end

function Self.GetNumGroupMembers() return Util.Tbl.Count(Self.group) end
function Self.IsInGroup(type) return not type and Self.GetNumGroupMembers() > 0 end
function Self.IsInRaid(type) return not type and Self.GetNumGroupMembers() > 5 end
function Self.UnitInRaid(v) return Self.UnitInParty(v) end

function Self.UnitInParty(v)
    return not not (Self.group[v] or Util.Tbl.Find(Self.group, v))
end

function Self.GetRaidRosterInfo(i)
    local unit = Self.Unit(Self.group[i])
    if unit then
        local class = {Self.UnitClass(unit.name)}
        return unit.name, i == 1 and 2 or 0, ceil(i / 5), 120, class[1], class[2], "Zone", true, false, Util.Select(i, 3, "TANK", 4, "HEALER", "DAMAGE"), nil
    end
end