local Addon = LibStub("AceAddon-3.0"):GetAddon(PLR_NAME)
local Self = {}


-------------------------------------------------------
--                        WoW                        --
-------------------------------------------------------

-- Classes
Self.DEATH_KNIGHT = 6
Self.DEMON_HUNTER = 12
Self.DRUID = 11
Self.HUNTER = 3
Self.MAGE = 8
Self.MONK = 10
Self.PALADIN = 2
Self.PRIEST = 5
Self.ROGUE = 4
Self.SHAMAN = 7
Self.WARLOCK = 9
Self.WARRIOR = 1

-- Interaction distances
Self.INTERACT_INSPECT = 1 -- 28 yards
Self.INTERACT_TRADE = 2   -- 11.11 yards
Self.INTERACT_DUEL = 3    -- 9.9 yards
Self.INTERACT_FOLLOW = 4  -- 28 yards

Self.PATTERN_FOLLOW = AUTOFOLLOWSTART:gsub("%%s", "(.+)")

-- Unit names and realms

function Self.GetUnit(unit)
    return unit and unit:gsub("-" .. GetRealmName(), "") or ""
end

-- Get a unit's realm name
function Self.GetRealmName(unit)
    local name, realm = UnitName(Self.GetUnit(unit))
    return realm ~= "" and realm
        or name and GetRealmName()
        or unit and unit:match("^.+-(.+)$")
        or nil
end

-- Get a unit's name (incl. realm name if from another realm)
function Self.GetName(unit)
    unit = Self.GetUnit(unit)
    local name, realm = UnitName(unit)

    return name and name .. (realm and realm ~= "" and "-" .. realm or "")
        or unit and unit ~= "" and not unit:find("^[a-z]") and unit
        or nil
end

-- Get a unit's short name (without realm name)
function Self.GetShortName(unit)
    local name = UnitName(Self.GetUnit(unit))

    return name and name
        or unit and unit:match("^(.+)-.+$")
        or unit and unit ~= "" and not unit:find("^[a-z]") and unit
        or nil
end

-- Get a unit's full name (always incl. realm name)
function Self.GetFullName(unit)
    local name, realm = UnitFullName(Self.GetUnit(unit))
    realm = realm ~= "" and realm or GetRealmName()

    return name and name .. "-" .. realm
        or unit and unit:match("^(.*-.*)$")
        or unit and unit ~= "" and not unit:find("^[a-z]") and unit .. "-" .. realm
        or nil
end

-- Get a unit's short name with a (*) at the end if the unit is from another realm
function Self.GetShortenedName(unit)
    unit = Self.GetUnit(unit)
    local name, realm = UnitFullName(unit)

    return name and name ~= "" and name .. (realm and realm ~= "" and " (*)" or "")
        or unit and unit ~= "" and not unit:find("^[a-z]") and unit:gsub("-.+", " (*)")
        or nil
end

-- Get the unit's guild name, incl. realm if from another realm
function Self.GetGuildName(unit)
    local guild, _, _, realm = GetGuildInfo(unit)
    return guild and guild .. (realm and "-" .. realm or "") or nil
end

-- Get a unit's class color
function Self.GetUnitColor(unit)
    return RAID_CLASS_COLORS[select(2, UnitClass(Self.GetUnit(unit)))] or {r = 1, g = 1, b = 1, colorStr = "ffffffff"}
end

-- Get a unit's name in class color
function Self.GetColoredName(name, unit)
    local color = Self.GetUnitColor(unit or name)
    return ("|c%s%s|r"):format(color.colorStr, name)
end

-- Check if the player is following someone
function Self.IsFollowing(unit)
    return AutoFollowStatus:IsShown() and (not unit or unit == AutoFollowStatusText:GetText():match(Self.PATTERN_FOLLOW))
end

-- Check if the current group is a guild group (>=80% guild members)
function Self.IsGuildGroup(guild)
    guild = guild or Self.GetGuildName("player")
    if not guild or not IsInGroup() then
        return false
    end

    local count = 0

    for i=1, GetNumGroupMembers() do
        if guild == Self.GetGuildName(GetRaidRosterInfo(i)) then
            count = count + 1
        end
    end

    return count / GetNumGroupMembers() >= 0.8
end

-- Check if the given unit is on our friend list
function Self.UnitIsFriend(unit)
    local unit = Self.GetName(unit)

    for i=1, GetNumFriends() do
        if GetFriendInfo(i) == unit then
            return true
        end
    end
end

-- Check if the given unit is in our guild
function Self.UnitIsGuildMember(unit)
    local guild = Self.GetGuildName("player")
    return guild ~= nil and Self.GetGuildName(unit) == guild
end

-- The the unit's rank in our guild
function Self.UnitGuildRank(unit)
    local guild, _, rank, realm = GetGuildInfo(unit)
    return guild and guild .. (realm and "-" .. realm or "") == Self.GetGuildName("player") and rank or nil
end

-- Shortcut for checking whether a unit is in our party or raid
function Self.UnitInGroup(unit, onlyOthers)
    local isSelf = UnitIsUnit(unit, "player")
    if onlyOthers and isSelf then
        return false
    else
        return isSelf or UnitInParty(unit) or UnitInRaid(unit)
    end
end

-- Get hidden tooltip for scanning
function Self.GetHiddenTooltip()
    if not Self.hiddenTooltip then
        Self.hiddenTooltip = CreateFrame("GameTooltip", PLR_PREFIX .. "_HiddenTooltip", nil, "GameTooltipTemplate")
        Self.hiddenTooltip:SetOwner(UIParent, "ANCHOR_NONE")
    end

    return Self.hiddenTooltip
end

-- Fill a tooltip and scan it line by line
function Self.ScanTooltip(fn, linkOrbag, slot, ...)
    local tooltip = Self.GetHiddenTooltip()
    tooltip:ClearLines()

    if not slot then
        tooltip:SetHyperlink(linkOrbag)
    else
        tooltip:SetBagItem(linkOrbag, slot)
    end

    local lines = tooltip:NumLines()
    for i=2, lines do
        local line = _G[PLR_PREFIX .."_HiddenTooltipTextLeft" .. i]:GetText()
        if line then
            local a, b, c = fn(i, line, lines, ...)
            if a ~= nil then
                return a, b, c
            end
        end
    end
end

-- Search through the group/raid with a function
function Self.SearchGroup(fn)
    fn = Self.Fn(fn)
    for i=1, GetNumGroupMembers() do
        local r = {fn(i, GetRaidRosterInfo(i))}
        if r[1] ~= nil then
            return unpack(r)
        end
    end
end

-- Get the correct bag position, if it exists (e.g. 1, 31 -> 2, 1)
function Self.GetBagPosition(bag, slot)
    local numSlots = GetContainerNumSlots(bag)
    if bag < 0 or bag > NUM_BAG_SLOTS or not numSlots or numSlots == 0 then
        return nil, nil
    elseif slot > numSlots then
        return Self.GetBagPosition(bag + 1, slot - numSlots)
    else
        return bag, slot
    end
end

-- Search through the bags with a function. Providing startBag will only search that bag,
-- providing startSlot as well will search through all bags/slots after from that combination.
function Self.SearchBags(fn, startBag, startSlot, ...)
    local endBag = not startSlot and startBag or NUM_BAG_SLOTS
    startBag = startBag or 0
    startSlot = startSlot or 1

    for bag = startBag, endBag do
        for slot = bag == startBag and startSlot or 1, GetContainerNumSlots(bag) do
            local link = GetContainerItemLink(bag, slot)
            if link then
                local a, b, c = fn(link, bag, slot, ...)
                if a ~= nil then
                    return a, b, c
                end
            end
        end
    end
end

-------------------------------------------------------
--                      General                      --
-------------------------------------------------------

-- Check if two values are equal
function Self.Equals(a, b)
    return a == b
end

-- Compare two values, returns -1 for a < b, 0 for a == b and 1 for a > b
function Self.Compare(a, b)
    return a < b and -1 or a == b and 0 or 1
end

-- Create an iterator
function Self.Iter(from, to, step)
    local i = from or 0
    return function (steps, reset)
        i = (reset and (from or 0) or i) + (step or 1) * (steps or 1)
        return (not to or i <= to) and i or nil
    end
end

-------------------------------------------------------
--                       Table                       --
-------------------------------------------------------

-- Make sure the given value is a table
function Self.Tbl(v)
    return type(v) ~= "table" and {v} or v
end

-- Get a random key from the table
function Self.TblRandomKey(t)
    local keys = Self.TblKeys(t)
    return #keys > 0 and keys[math.random(#keys)] or nil
end

-- Get a random entry from the table
function Self.TblRandom(t)
    local key = Self.TblRandomKey(t)
    return key and t[key]
end

-- Create a table that tracks the highest numerical index and offers count+newIndex fields and Add function
function Self.TblCounter(t)
    t = t or {}
    local count = 0
    
    setmetatable(t, {
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
    return t
end

-- SUB

function Self.TblSub(t, s, e) return {unpack(t, s or 1, e)} end
function Self.TblHead(t, n) return Self.TblSub(t, 1, n or 1) end
function Self.TblTail(t, n) return Self.TblSub(t, #t - (n or 1)) end
function Self.TblSplice(t, s, e, u) return Self.TblMerge(Self.TblHead(t, s), u or {}, Self.TblSub(#t, e)) end

-- ITERATE

-- Good old FoldLeft
function Self.TblFoldL(t, fn, u, ...)
    fn = Self.Fn(fn)
    for i,v in pairs(t) do
        u = fn(u, v, i, ...)
    end
    return u
end

-- Iterate through a table
function Self.TblIter(t, fn, ...)
    fn = Self.Fn(fn)
    for i,v in pairs(t) do
        fn(v, i, ...)
    end
    return t
end

-- Copy a table
function Self.TblCopy(t, deep)
    local u = {}
    for i,v in pairs(t) do
        u[i] = deep and type(v) == "table" and Self.TblCopy(v, deep) or v
    end
    return u
end

-- COUNT, SUM, MULTIPLY

function Self.TblCount(t) return Self.TblFoldL(t, Self.FnInc, 0) end
function Self.TblSum(t) return Self.TblFoldL(t, Self.FnAdd, 0) end
function Self.TblMul(t) return Self.TblFoldL(t, Self.FnMul, 1) end

-- Count the # of occurences of val
function Self.TblCountVal(t, val)
    local n = 0
    for i,v in pairs(t) do
        if v == val then n = n + 1 end
    end
    return n
end

-- Count the # of tables that have given key/val pairs
function Self.TblCountWhere(t, keyOrTbl, valOrDeep)
    local isTbl, n = type(keyOrTbl) == "table", 0
    for i,v in pairs(t) do
        if isTbl and Self.TblContains(v, keyOrTbl, valOrDeep) or not isTbl and (valOrDeep == nil and v[keyOrTbl] ~= nil or valOrDeep ~= nil and v[keyOrTbl] == valOrDeep) then
            n = n + 1
        end
    end
    return n
end

-- Count using a function
function Self.TblCountFn(t, fn, ...)
    local fn, n = Self.Fn(fn), 0
    for i,v in pairs(t) do
        n = n + fn(v, ...)
    end
    return n
end

-- SEARCH

-- Search for something in a table and return the index
function Self.TblSearch(t, fn, ...)
    fn = Self.Fn(fn) or Self.FnId
    for i,v in pairs(t) do
        if fn(v, i, ...) then
            return i
        end
    end
end

-- Check if one table is contained within the other
function Self.TblContains(t, u, deep)
    if t == u then
        return true
    elseif (t == nil) ~= (u == nil) then
        return false
    end

    for i,v in pairs(u) do
        if deep and type(t[i]) == "table" and type(v) == "table" then
            if not Self.TblContains(t[i], v, true) then
                return false
            end
        elseif t[i] ~= v then
            return false
        end
    end
    return true
end

-- Check if two tables are equal
function Self.TblEquals(a, b, deep)
    return type(b) == "table" and Self.TblContains(a, b, deep) and Self.TblContains(b, a, deep)
end

-- Find a value in a table
function Self.TblFind(t, val)
    for i,v in pairs(t) do
        if v == val then return i end
    end
end

-- Find a set of key/value pairs in a table
function Self.TblFindWhere(t, keyOrTbl, valOrDeep)
    local isTbl = type(keyOrTbl) == "table"
    for i,v in pairs(t) do
        if isTbl and Self.TblContains(v, keyOrTbl, valOrDeep) or not isTbl and (valOrDeep == nil and v[keyOrTbl] ~= nil or valOrDeep ~= nil and v[keyOrTbl] == valOrDeep) then
            return i
        end
    end
end

-- Find the first element (optinally matching a fn)
function Self.TblFirst(t, fn, ...)
    fn = Self.Fn(fn)
    for i,v in pairs(t) do
        if not fn or fn(v, i, ...) then return v end
    end
end

-- Find the first set of key/value pairs in a table
function Self.TblFirstWhere(t, keyOrTbl, valOrDeep)
    local isTbl = type(keyOrTbl) == "table"
    for i,v in pairs(t) do
        if isTbl and Self.TblContains(v, keyOrTbl, valOrDeep) or not isTbl and (valOrDeep == nil and v[keyOrTbl] ~= nil or valOrDeep ~= nil and v[keyOrTbl] == valOrDeep) then
            return v
        end
    end
end

-- FILTER

-- Filter by a function
function Self.TblFilter(t, fn, k, ...)
    fn = Self.Fn(fn) or Self.FnId
    local u = {}
    for i,v in pairs(t) do
        if fn(v, i, ...) then
            if k then u[i] = v else tinsert(u, v) end
        end
    end
    return u
end

-- Pick specific keys from a table
function Self.TblSelect(t, ...)
    local isTbl = type(...) == "table"
    local u = {}
    for i=1,isTbl and #... or select("#", ...) do
        local v = isTbl and (...)[i] or select(i, ...)
        u[v] = t[v]
    end
    return u
end

-- Omit specific keys from a table
function Self.TblOmit(t, ...)
    local isTbl = type(...) == "table"
    local u = Self.TblCopy(t)
    for i=1,isTbl and #... or select("#", ...) do
        u[Tbl and (...)[i] or select(i, ...)] = nil
    end
    return u
end

-- Filter by a value
function Self.TblOnly(t, val, k)
    local u = {}
    for i,v in pairs(t) do
        if v == val then
            if k then u[i] = v else tinsert(u, v) end
        end
    end
    return u
end

-- Filter by not being a value
function Self.TblExcept(t, val, k)
    local u = {}
    for i,v in pairs(t) do
        if v ~= val then
            if k then u[i] = v else tinsert(u, v) end
        end
    end
    return u
end

-- Filter by a set of key/value pairs in a table
function Self.TblWhere(t, keyOrTbl, valOrDeep, k)
    local isTbl = type(keyOrTbl) == "table"
    local u = {}
    for i,v in pairs(t) do
        if isTbl and Self.TblContains(v, keyOrTbl, valOrDeep) or not isTbl and (valOrDeep == nil and v[keyOrTbl] ~= nil or valOrDeep ~= nil and v[keyOrTbl] == valOrDeep) then
            if k then u[i] = v else tinsert(u, v) end
        end
    end
    return u
end

-- Filter by not having a set of key/value pairs in a table
function Self.TblExceptWhere(t, keyOrTbl, valOrDeep, k)
    local isTbl = type(keyOrTbl) == "table"
    local u = {}
    for i,v in pairs(t) do
        if isTbl and not Self.TblContains(v, keyOrTbl, valOrDeep) or not isTbl and not (valOrDeep == nil and v[keyOrTbl] ~= nil or valOrDeep ~= nil and v[keyOrTbl] == valOrDeep) then
            if k then u[i] = v else tinsert(u, v) end
        end
    end
    return u
end

-- MAP

-- Change table values by applying a function
function Self.TblMap(t, fn, ...)
    fn = Self.Fn(fn)
    local u = {}
    for i,v in pairs(t) do
        u[i] = fn(v, i, ...)
    end
    return u
end

-- Change table keys by applying a function
function Self.TblMapKeys(t, fn, ...)
    fn = Self.Fn(fn)
    local u = {}
    for i,v in pairs(t) do
        u[fn(v, i, ...)] = v
    end
    return u
end

-- Change table keys and values by applying a function
function Self.TblMapBoth(t, fn, ...)
    fn = Self.Fn(fn)
    local u = {}
    for i,v in pairs(t) do
        i, v = fn(v, i, ...)
        u[i] = v
    end
    return u
end

-- Get table keys
function Self.TblKeys(t)
    local u = {}
    for i,v in pairs(t) do tinsert(u, i) end
    return u
end

-- Get table values as continuously indexed list
function Self.TblValues(t)
    local u = {}
    for i,v in pairs(t) do tinsert(u, v) end
    return u
end

-- Flip table keys and values
function Self.TblFlip(t, fn, ...)
    fn = Self.Fn(fn)
    local u = {}
    for i,v in pairs(t) do
        if fn then u[v] = fn(v, i, ...) else u[v] = i end
    end
    return u
end

-- Extract a list of property values
function Self.TblPluck(t, k)
    local u = {}
    for i,v in pairs(t) do
        u[i] = v[k]
    end
    return u
end

-- GROUP

-- Group table entries by funciton
function Self.TblGroup(t, fn)
    fn = Self.Fn(fn) or Self.FnId
    local u = {}
    for i,v in pairs(t) do
        i = fn(v, i)
        u[i] = u[i] or {}
        tinsert(u[i], v)
    end
    return u
end

-- Group table entries by key
function Self.TblGroupBy(t, k)
    fn = Self.Fn(fn) or Self.FnId
    local u = {}
    for i,v in pairs(t) do
        i = v[k]
        u[i] = u[i] or {}
        tinsert(u[i], v)
    end
    return u
end

-- Group the keys with the same values
function Self.TblGroupKeys(t)
    local u = {}
    for i,v in pairs(t) do
        u[v] = u[v] or {}
        tinsert(u[v], i)
    end
    return u
end

-- SET

-- Make sure all table entries are unique 
local Fn = function (v, u)
    local r = not u[v]
    u[v] = true
    return r
end
function Self.TblUnique(t, k)
    local u = {}
    return Self.Filter(t, Fn, k, u)
end

-- Calculate the intersection of tables
function Self.TblIntersect(t, ...)
    local k = select(select("#", ...), ...) == true

    local u = Self.TblCopy(t)
    for i=1,select("#", ...) - (k and 1 or 0) do
        tbl = Self.TblFlip(select(i, ...), Self.FnTrue)
        for i,v in pairs(u) do
            if not tbl[v] then
                if k then u[i] = nil else tremove(u, i) end
            end
        end
    end
    return u
end

-- Calculate the difference between tables
function Self.TblDiff(t, ...)
    local k = select(select("#", ...), ...) == true

    local u = Self.TblCopy(t)
    for i=1,select("#", ...) - (k and 1 or 0) do
        tbl = Self.TblFlip(select(i, ...), Self.FnTrue)
        for i,v in pairs(u) do
            if tbl[v] then
                if k then u[i] = nil else tremove(u, i) end
            end
        end
    end
    return u
end

-- CHANGE

function Self.TblPush(t, v) tinsert(t, v) return t end
function Self.TblPop(t) return tremove(t) end
function Self.TblDrop(t) tremove(t) return t end
function Self.TblShift(t) return tremove(t, 1) end
function Self.TblUnshift(t, v) tinsert(t, 1, v) return t end

-- Rotate by l (l>0: left, l<0: right)
function Self.TblRotate(t, l)
    l = l or 1
    for i=1, math.abs(l) do
        if l < 0 then
            tinsert(t, 1, tremove(t))
        else
            tinsert(t, tremove(t, 1))
        end
    end
    return t
end

-- Sort a table
local Fn = function (a, b) return a > b end
function Self.TblSort(t, fn)
    fn = fn == true and Fn or Self.Fn(fn) or nil
    table.sort(t, fn)
    return t
end

-- Sort a table of tables by given table keys and default values
local Fn = function (a, b) return -Self.Compare(a, b) end

function Self.TblSortBy(t, ...)
    local args = type(...) == "table" and (...) or {...}
    return Self.TblSort(t, function (a, b)
        for i=1, #args, 3 do
            local key, default, fn = args[i], args[i+1], args[i+2]
            fn = fn == true and Fn or Self.Fn(fn) or Self.Compare
            local cmp = fn(a[key] or default, b[key] or default)

            if cmp == 1 then
                return false
            elseif cmp == -1 or i+2 >= #args then
                return true
            end
        end
    end)
end

-- Merge two or more tables
function Self.TblMerge(t, ...)
    t = t or {}
    for i=1,select("#", ...) do
        local j = 1
        for k,v in pairs(select(i, ...)) do
            if k == j then tinsert(t, v) else t[k] = v end
            j = j + 1
        end
    end
    return t
end

-- OTHER

-- Convert the table into tuples of n
function Self.TblTuple(t, n)
    local u, n, r = {}, n or 2
    for i,v in pairs(t) do
        if not r or #r == n then
            r = {}
            tinsert(u, r)
        end
        tinsert(r, v)
    end
    return u
end

-- This just looks nicer when chaining
function Self.TblUnpack(t, fn)
    fn = Self.Fn(fn) or Self.FnId
    return fn(unpack(t))
end

-- Flatten a list of tables by one dimension
local Fn = function (u, v) return Self.TblMerge(u, v) end
function Self.TblFlatten(t)
    return Self.TblFoldL(t, Fn, {})
end

-- Join a table of strings
function Self.TblConcat(t, del)
    return table.concat(t, del)
end

-- Use Blizzard's inspect tool
function Self.TblInspect(t)
    UIParentLoadAddOn("Blizzard_DebugTools")
    DisplayTableInspectorWindow(t)
end

-------------------------------------------------------
--                       String                      --
-------------------------------------------------------

function Self.IsStr(str)
    return type(str) == "string"
end

function Self.StrStartsWith(str, str2)
    return Self.IsStr(str) and str:sub(1, str2:len()) == str2
end

function Self.StrEndsWith(str, str2)
    return Self.IsStr(str) and str:sub(-str2:len()) == str2
end

function Self.StrEmpty(str)
    return not Self.IsStr(str) or string == ""
end

function Self.StrWrap(str, before, after)
    if Self.StrEmpty(str) then
        return ""
    end

    return (before or " ") .. str .. (after or before or " ")
end

function Self.StrPrefix(str, prefix)
    return Self.StrWrap(str, prefix, "")
end

function Self.StrPostfix(str, postfix)
    return Self.StrWrap(str, "", postfix)
end

-- Split string on delimiter
function Self.StrSplit(str, del)
    return {del:split(str)}
end

-- Uppercase first char
function Self.StrUcFirst(str)
    return str:sub(1, 1):upper() .. str:sub(2)
end

-- Lowercase first char
function Self.StrLcFirst(str)
    return str:sub(1, 1):lower() .. str:sub(2)
end

-- Check if string is a number
function Self.StrIsNumber(str, leadingZero)
    return tonumber(str) and (leadingZero or not Self.StrStartsWith(str, "0"))
end

-------------------------------------------------------
--                       Number                      --
-------------------------------------------------------

-- Rounds a number
function Self.NumRound(num)
    return floor(num + .5)
end

-------------------------------------------------------
--                      Function                     --
-------------------------------------------------------

function Self.Fn(fn) return type(fn) == "string" and _G[fn] or fn end
function Self.FnId(...) return ... end
function Self.FnTrue() return true end
function Self.FnFalse() return false end
function Self.FnNoop() end

-- Some math
function Self.FnInc(i) return i+1 end
function Self.FnDec(i) return i-1 end
function Self.FnAdd(a, b) return a+b end
function Self.FnSub(a, b) return a-b end
function Self.FnMul(a, b) return a*b end
function Self.FnDiv(a, b) return a/b end

-- Get a function that always compares to a given value
function Self.FnEq(v)
    return function (w) return w == v end
end

-- MODIFY

-- Throttle a function, so it is called at most every n seconds
function Self.FnThrottle(fn, n)
    local timer
    return function (...)
        if not timer then
            timer = Addon:ScheduleTimer(function (...)
                timer = nil
                fn(...)
            end, n, ...)
        end
    end
end

-- Debounce a function, so it doesn't get called again for n seconds after it has been called
function Self.FnDebounce(fn, n)
    local called
    return function (...)
        if not called or called + n < GetTime() then
            called = GetTime()
            fn(...)
        end
    end
end

-------------------------------------------------------
--                       Other                       --
-------------------------------------------------------

-- xpcall safecall implementation

local xpcall = xpcall

local function errorhandler(err)
	return geterrorhandler()(err)
end

local function CreateDispatcher(argCount)
	local code = [[
		local xpcall, eh = ...
		local method, ARGS
		local function call() return method(ARGS) end
	
		local function dispatch(func, ...)
			method = func
			if not method then return end
			ARGS = ...
			return xpcall(call, eh)
		end
	
		return dispatch
	]]
	
	local ARGS = {}
	for i = 1, argCount do ARGS[i] = "arg"..i end
	code = code:gsub("ARGS", table.concat(ARGS, ", "))
	return assert(loadstring(code, "safecall Dispatcher["..argCount.."]"))(xpcall, errorhandler)
end

local Dispatchers = setmetatable({}, {__index=function(self, argCount)
	local dispatcher = CreateDispatcher(argCount)
	rawset(self, argCount, dispatcher)
	return dispatcher
end})
Dispatchers[0] = function(func)
	return xpcall(func, errorhandler)
end
 
function Self.Safecall(func, ...)
	return Dispatchers[select("#", ...)](func, ...)
end

-- SWITCH

-- Almost a real switch statement for lua
function Self.Switch(case)
    return function(code)
        local r = code[case] or code.default
        if type(r) == "function" then
            return r(case)
        else
            return r
        end
    end
end

-- IN

-- Shortcut for val == x or val == y or ...
function Self.In(val, ...)
    for i=1,select("#", ...) do
        if select(i, ...) == val then
            return true
        end
    end
    return false
end

-- TO STRING

-- Get string representation values for dumping
function Self.ToString(val, depth)
    depth = depth or 3
    local t = type(val)

    if t == "nil" then
        return "nil"
    elseif t == "table" then
        if depth == 0 then
            return "{...}"
        else
            local j = 1
            return Self.TblFoldL(val, function (s, v, i)
                if s ~= "{" then s = s .. ", " end
                if i ~= j then s = s .. i .. " = " end
                j = j + 1
                return s .. Self.ToString(v, depth-1)
            end, "{") .. "}"
        end
    elseif t == "boolean" then
        return val and "true" or "false"
    elseif t == "function" then
        return "(fn)"
    elseif t == "string" then
        return '"' .. val .. '"'
    else
        return val
    end
end

-- DUMP

-- Dump all given values
function Self.Dump(...)
    for i=1,select("#", ...) do
        print(Self.ToString((select(i, ...))))
    end
end

-- TRACE

-- Stacktrace
function Self.Trace()
    local s = Self(debugstack(2)).Split("\n").Except("")()
    print("------------------------- Trace -------------------------")
    for i,v in pairs(s) do
        print(i .. ": " .. v)
    end
    print("---------------------------------------------------------")
end

-- Enable chain-calling
Self.C = {v = nil, k = nil}
local Fn = function (...)
    local c, k, v = Self.C, rawget(Self.C, "k"), rawget(Self.C, "v")
    local pre = Self.Switch(type(v)) {
        table = "Tbl",
        string = "Str",
        number = "Num",
        ["function"] = "Fn"
    }
    k = pre and Self[pre .. k] and pre .. k or k

    c.v = Self[k](v, ...)
    return c
end
setmetatable(Self.C, {
    __index = function (c, k)
        c.k = Self.StrUcFirst(k)
        return Fn
    end,
    __call = function (c, i)
        local v = rawget(c, "v")
        if i ~= nil then return v[i] else return v end
    end
})
setmetatable(Self, {
    __call = function (_, v)
        Self.C.v = v
        Self.C.k = nil
        return Self.C
    end
})

-- Export

Addon.Util = Self