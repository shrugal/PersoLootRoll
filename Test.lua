local Name = debug.getinfo(1).source:gsub("\\", "/"):match("([^/]+)/[^/]+$") or (os.getenv("PWD") or ""):match("[^/]+$")
local Addon = {}

-------------------------------------------------------
--                       Helper                      --
-------------------------------------------------------

local function checkfile(path)
    local f = io.open(path)
    return f and f:close()
end

local function readfile(path)
    local file = io.open(path) or error("File " .. path .. " not found")
    return file:read("*all"), file:close()
end

local function xml(s)
    local function parseargs(s)
        local arg = {}
        string.gsub(s, "([%-%w]+)=([\"'])(.-)%2", function(w, _, a) arg[w] = a end)
        return arg
    end

    -- Remove comments
    s = s:gsub("<!%-%-.-%-%->", "")

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

local extensions = {lua = true, xml = true, toc = true}
local function import(file)
    local path, ext = file:gsub("\\", "/"):match("^(.-)%.?([^.]+)$")

    if not path:match("/") then
        path = path:gsub("%.", "/")
    end

    if not extensions[ext] then
        path = path ~= "" and path .. "/" .. ext or ext
        for v in pairs(extensions) do
            if checkfile(path .. "." .. v) then ext = v break end
        end
    end

    path = path .. "." .. ext

    if ext == "lua" then
        return loadfile(path)(Name, Addon)
    elseif ext == "xml" then
        local dir = path:match("^(.-)[^/]+$")
        local nodes = xml(readfile(path))[1]
        for _,node in ipairs(nodes or {}) do
            if node.label == "Script" or node.label == "Include" then
                import(dir .. node.xarg.file)
            end
        end
    elseif ext == "toc" then
        for line in io.lines(path) do
            if line ~= "" and line:sub(1, 1) ~= "#" then
                import(line)
            end
        end
    else
        error("Unknown file extension " .. ext)
    end
end

local frames = {}
local fire = function (...) for _,f in ipairs(frames) do f:FireEvent(...) end end
local update = function () for _,f in ipairs(frames) do f:FireUpdate() end end

-------------------------------------------------------
--                      WoW mocks                    --
-------------------------------------------------------

local Fn = function () end
local Id = function (v) return v end
local Const = function (v) return function () return v end end
local Consts = function (...) local args = {...} return function () return unpack(args) end end
local Val = function (v) return function (a) if a then return v end end end
local Vals = function (...) local args = {...} return function (...) if ... then return unpack(args) end end end
local Meta = { __index = function (_, k) return k.sub and k:sub(1,1) == k:sub(1,1):upper() and Fn or nil end }
local Obj = setmetatable({}, Meta)

CreateFrame = function (_, name, parent)
    parent = parent or UIParent
    local scripts, events, points, lastUpdate, f = {}, {}, {}, 0
    local CreateChild = function () return CreateFrame(nil, nil, f) end
    f = setmetatable({
        SetScript = function (_, k, v) scripts[k] = v end,
        GetScript = function (_, k) return scripts[k] end,
        HasScript = function (_, k) return not not scripts[k] end,
        RegisterEvent = function (_, k) events[k] = true end,
        UnregisterEvent = function (_, k) events[k] = nil end,
        UnregisterAllEvents = function () wipe(events) end,
        SetParent = function (v) parent = v end,
        GetParent = function () return parent end,
        SetPoint = function (_, ...)
            local n, point, rel, relPoint, x, y = select("#", ...), ...
            if n == 1 then rel, relPoint, x, y = parent, point, 0, 0 end
            if n == 3 and type(rel) == "table" then x, y = 0, 0 end
            if n == 3 and type(rel) == "number" then x, y, rel, relPoint = rel, relPoint, parent, point end
            table.insert(points, {point, rel, relPoint, x, y})
        end,
        GetPoint = function (_, k) return unpack(points[k]) end,
        GetNumPoints = function () return #points end,
        ClearAllPoints = function () wipe(points) end,
        CreateTexture = CreateChild,
        CreateFontString = CreateChild,
        FireEvent = function (_, e, ...) if scripts.OnEvent and events[e] then scripts.OnEvent(f, e, ...) end end,
        FireUpdate = function () if scripts.OnUpdate then scripts.OnUpdate(f, os.clock() - lastUpdate) lastUpdate = os.clock() end end
    }, Meta)
    table.insert(frames, f)
    if name then _G[name] = f end
    return f
end

CreateFrame(nil, "UIParent")

local loggedIn = false
IsLoggedIn = function () return loggedIn end

local group = 0
GetNumGroupMembers = function () return group and group + 1 or 0 end
IsInGroup = function () return group > 0 end
IsInRaid = function () return group > 5 end

geterrorhandler = Const(Fn)
seterrorhandler = Fn
wipe = function (t) for i in pairs(t) do t[i] = nil end end
issecurevariable = Const(false)
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
string.trim = function (s) return s:match("^%s*(.-)%s*$") end
strsplit = string.split
strmatch = string.match
format = string.format
tinsert = table.insert
tremove = table.remove
time = function (...) return math.floor(os.time(...)) end
max = math.max
min = math.min

GetLocale = Const("enUs")
GetRealmName = Const("Mal'Ganis")
GetCurrentRegion = Const(3)
GetBuildInfo = Consts("8.2.0", "31478", "Aug 12 2019", 80200)
GetAddOnMetadata = Val("0-dev0")
GetAutoCompleteRealms = Const({"Echsenkessel", "Mal'Ganis", "Taerar"})
GetTime = function (...) return math.floor(os.clock(...)) end
GetInstanceInfo = Fn
GetLootRollTimeLeft = Val(0)
GetLootRollItemInfo = Fn
GetLootRollItemLink = Fn
RollOnLoot = Fn
GroupLootContainer_RemoveFrame = Fn
SetLootRollItem = Fn
SetItemRef = Fn
UnitPopup_ShowMenu = Fn
UnitName = function (v) return v ~= "" and v or nil end
UnitFullName = UnitName
UnitClass = Vals("Mage", "MAGE", 8)
UnitRace = Vals("Troll", "Troll", 8)
UnitFactionGroup = Vals("Horde", "Horde")
UnitGUID = Val("Player-1612-054E4E80")
UnitIsUnit = function (a, b) return a and a == b end
RegisterAddonMessagePrefix = Fn
IsInInstance = Const(false)
IsAddOnLoaded = function (n) return n == "WoWUnit" or n == Name end
InterfaceOptions_AddCategory = Fn
ChatFrame_AddMessageEventFilter = Fn

C_ChallengeMode = Obj
C_Timer = Obj
StaticPopupDialogs = {}
SlashCmdList = {}
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
HIGHLIGHT_FONT_COLOR_CODE = ""
FONT_COLOR_CODE_CLOSE = ""
DIFFICULTY_DUNGEON_NORMAL = 1
DIFFICULTY_DUNGEON_HEROIC = 2
DIFFICULTY_RAID10_NORMAL = 3
DIFFICULTY_RAID25_NORMAL = 4
DIFFICULTY_RAID10_HEROIC = 5
DIFFICULTY_RAID25_HEROIC = 6
DIFFICULTY_RAID_LFR = 7
DIFFICULTY_DUNGEON_CHALLENGE = 8
DIFFICULTY_RAID40 = 9
DIFFICULTY_PRIMARYRAID_NORMAL = 14
DIFFICULTY_PRIMARYRAID_HEROIC = 15
DIFFICULTY_PRIMARYRAID_MYTHIC = 16
DIFFICULTY_PRIMARYRAID_LFR = 17
NUM_GROUP_LOOT_FRAMES = 0
NUM_CHAT_WINDOWS = 0
LOOT_ITEM_BONUS_ROLL = "" -- TODO
CREATED_ITEM = "" -- TODO
LOOT_ITEM_CREATED_SELF = "" -- TODO
RANDOM_ROLL_RESULT = "" -- TODO

PLR_AwardLootButtonNormalText = CreateFrame()

-------------------------------------------------------
--                        Init                       --
-------------------------------------------------------

-- Import WoWUnit
CreateFrame(nil, "WoWUnit")
import("Libs.WoWUnit.Classes.Group")
import("Libs.WoWUnit.Classes.Test")
import("Libs.WoWUnit.WoWUnit.lua")
fire("ADDON_LOADED", "WoWUnit")

-- Import PLR
import(Name .. ".toc")
fire("ADDON_LOADED", Name)

-- Startup process
fire("SPELLS_CHANGED")
loggedIn = true
fire("PLAYER_LOGIN")
fire("PLAYER_ENTERING_WORLD")
fire("PLAYER_ALIVE")
update()

-------------------------------------------------------
--                     Run tests                     --
-------------------------------------------------------

print("[Testing]")
WoWUnit:RunTests("PLAYER_LOGIN")

local passedGroups = 0
for _,group in ipairs(WoWUnit.children) do
    local failed = {}
    for i,test in ipairs(group.children) do
        if test.numOk ~= 1 then table.insert(failed, i) end
    end

    print(group.name .. ": " .. (#failed == 0 and "Passed" or "FAILED") .. " (" .. (#group.children - #failed) .. "/" .. #group.children .. ")")

    for _,i in ipairs(failed) do
        local test = group.children[i]
        print(" - " .. test.name .. " (" .. i .. "): " .. table.concat(test.errors, ", "):gsub("|n|n", ""):gsub("|n", " "))
    end

    passedGroups = passedGroups + (#failed == 0 and 1 or 0)
end

local success = passedGroups == #WoWUnit.children
print("[Result]: " .. (success and "Passed" or "FAILED") .. " (" .. passedGroups .. "/" .. #WoWUnit.children .. ")")

os.exit(not success and 1 or 0)
