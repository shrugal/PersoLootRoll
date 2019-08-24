local Name = "PersoLootRoll"
local Addon = {}

-------------------------------------------------------
--                       Helper                      --
-------------------------------------------------------

local function dump(o, d)
    d = d or 1
    local s, i = "", (" "):rep(d * 4)
    if type(o) == "table" then
        for k,v in pairs(o) do
            if type(k) ~= "string" then k = '['..k..']' end
            s = s .. (#s > 0 and "," or "") .. "\n" .. i .. k .. " = " .. dump(v, d + 1)
        end
        s = "{" .. (#s > 0 and s .. "\n" .. (" "):rep((d - 1) * 4) or s) .. "}"
    elseif type(o) == "string" then
        s = '"' .. o .. '"'
    else
        s = tostring(o)
    end
    if d > 1 then return s else print(s) end
 end

local function readfile(path)
    local file, content = io.open(path), ""
    if file then content = file:read("*all") file:close() end
    return content
end

local function xml(s)
    local function parseargs(s)
        local arg = {}
        string.gsub(s, "([%-%w]+)=([\"'])(.-)%2", function(w, _, a) arg[w] = a end)
        return arg
    end

    local stack = {}
    local top = {}
    table.insert(stack, top)
    local ni, c, label, xarg, empty
    local i, j = 1, 1
    while true do
        ni, j, c, label, xarg, empty = string.find(s,
                                                   "<(%/?)([%w:]+)(.-)(%/?)>", i)
        if not ni then break end
        local text = string.sub(s, i, ni - 1)
        if not string.find(text, "^%s*$") then table.insert(top, text) end
        if empty == "/" then -- empty element tag
            table.insert(top, {label = label, xarg = parseargs(xarg), empty = 1})
        elseif c == "" then -- start tag
            top = {label = label, xarg = parseargs(xarg)}
            table.insert(stack, top) -- new level
        else -- end tag
            local toclose = table.remove(stack) -- remove top
            top = stack[#stack]
            if #stack < 1 then
                error("nothing to close with " .. label)
            end
            if toclose.label ~= label then
                error("trying to close " .. toclose.label .. " with " .. label)
            end
            table.insert(top, toclose)
        end
        i = j + 1
    end
    local text = string.sub(s, i)
    if not string.find(text, "^%s*$") then table.insert(stack[#stack], text) end
    if #stack > 1 then error("unclosed " .. stack[#stack].label) end
    return stack[1]
end

local import, importLua, importXml

function importLua(path, ...)
    if ... then
        local code = readfile(path) .. "\nreturn " .. table.concat({...}, ", ")
        local export = {loadstring(code, path)(Name, Addon)}
        for i, v in ipairs(export) do
            if v ~= nil then
                _G[select(i, ...)] = v
            end
        end
        return unpack(export)
    else
        return loadfile(path)(Name, Addon)
    end
end

function importXml(path, ...)
    local dir = string.gsub(path, "(.*\\)(.*)", "%1")
    local nodes = xml(readfile(path))[1]
    for _,node in ipairs(nodes or {}) do
        if node.label == "Script" or node.label == "Include" then
            import(dir .. "\\" .. node.xarg.file, ...)
        end
    end
end

function import(path, ...)
    local ext, f = path:match("([^.]+)$")
    if ext ~= "lua" and ext ~= "xml" then
        path = path:gsub("%.", "\\")
        f = io.open(path .. "\\" .. ext:lower() .. ".xml")
        path = f and f:close() and path .. "\\" .. ext:lower() or path
        f = io.open(path .. ".xml")
        ext = f and f:close() and "xml" or "lua"
        path = path .. "." .. ext
    end

    if ext == "lua" then
        importLua(path, ...)
    elseif ext == "xml" then
        importXml(path, ...)
    end
end

-------------------------------------------------------
--                      WoW mocks                    --
-------------------------------------------------------

local Fn = function () end
local Id = function (v) return v end
local Const = function (v) return function () return v end end
local Consts = function (...) local args = {...} return function () return unpack(args) end end
local Val = function (v) return function (a) if a then return v end end end
local Vals = function (...) local args = {...} return function (...) if ... then return unpack(args) end end end
local Meta = {__index = Const(Fn)}

CreateFrame = function (name)
    local f = setmetatable({ GetScript = Val(Fn), CreateTexture = CreateFrame }, Meta)
    if name then _G[name] = f end
    return f
end
wipe = function (t) for i in pairs(t) do t[i] = nil end end
hooksecurefunc = function (tbl, name, fn)
    if not fn then tbl, name, fn = _G, tbl, name end
    local orig = tbl[name]
    tbl[name] = function (...) local r = {orig(...)} fn(...) return unpack(r) end
end
string.split = function (del, str, n)
    local t, i = {}, 0
    local push = function (v) i = i + 1 if n and i > n then t[n] = t[n] .. del .. v else table.insert(t, v) end end
    for a, b in string.gmatch(str, "([^" .. del .. "]*)" .. del .. "([^" .. del .. "]*)") do
        if i == 0 or a:len() > 0 or b:len() == 0 then push(a) end
        if i == 1 or b:len() > 0 then push(b) end
    end
    if i == 0 then table.insert(t, str) end
    return unpack(t)
end
GetLocale = Const("enUs")
GetRealmName = Const("Mal'Ganis")
GetCurrentRegion = Const(3)
GetBuildInfo = Consts("8.2.0", "31478", "Aug 12 2019", 80200)
GetAddOnMetadata = Val("0-dev0")
GetAutoCompleteRealms = Const({"Echsenkessel", "Mal'Ganis", "Taerar"})
GetTime = os.time
UnitName = Id
UnitClass = Vals("Mage", "MAGE", 8)
UnitRace = Vals("Troll", "Troll", 8)
UnitFactionGroup = Vals("Horde", "Horde")
UnitGUID = Val("Player-1612-054E4E80")
RegisterAddonMessagePrefix = Fn
strsplit = string.split
strmatch = string.match
tinsert = table.insert
tremove = table.remove

C_Timer = {}
StaticPopupDialogs = {}
AlertFrame = CreateFrame()

LE_UNIT_STAT_STRENGTH = 1
LE_UNIT_STAT_AGILITY = 2
LE_UNIT_STAT_INTELLECT = 4
ITEM_LEVEL = "Item Level %d"
ITEM_LEVEL_ALT = "Item Level %d (%d)"
ITEM_MIN_LEVEL = "Requires Level %d"
ITEM_LEVEL_RANGE = "Requires level %d to %d"
RELIC_TOOLTIP_TYPE = "%s Artifact Relic"
ITEM_CLASSES_ALLOWED = "Classes: %s"
ITEM_REQ_SPECIALIZATION = "Requires: %s"
ITEM_MOD_STRENGTH = "%c%s Strength"
ITEM_MOD_INTELLECT = "%c%s Intellect"
ITEM_MOD_AGILITY = "%c%s Agility"
ITEM_SOULBOUND = "Soulbound"
BIND_TRADE_TIME_REMAINING = "You may trade this item with players that were also eligible to loot this item for the next %s."
TRANSMOGRIFY_TOOLTIP_APPEARANCE_KNOWN = "You've collected this appearance"
TRANSMOGRIFY_TOOLTIP_APPEARANCE_UNKNOWN = "You haven't collected this appearance"
TRANSMOGRIFY_TOOLTIP_ITEM_UNKNOWN_APPEARANCE_KNOWN = "You've collected this appearance, but not from this item"
ERR_JOINED_GROUP_S = "%s joins the party."
ERR_INSTANCE_GROUP_ADDED_S = "%s has joined the instance group."
ERR_RAID_MEMBER_ADDED_S = "%s has joined the raid group."
ERR_LEFT_GROUP_S = "%s leaves the party."
ERR_INSTANCE_GROUP_REMOVED_S = "%s has left the instance group."
ERR_RAID_MEMBER_REMOVED_S = "%s has left the raid group."
AUTOFOLLOWSTART = "Following %s."

-------------------------------------------------------
--                    Import stuff                   --
-------------------------------------------------------

-- Import PLR
import("Libs")
import("Init")
import("Util")
import("Locale")
import("Data")
import("Models")
import("Core")
import("Modules")
import("Plugins")
import("GUI")

-- Import WoWUnit
WoWUnit = CreateFrame()
import("Libs.WoWUnit.Classes.Group")
import("Libs.WoWUnit.Classes.Test")
import("Libs.WoWUnit.WoWUnit")

-- Import tests
import("Tests")

dump(PLR)-- TODO
