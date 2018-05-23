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
    return realm
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

-- Get a unit's class color
function Self.GetUnitColor(unit)
    return RAID_CLASS_COLORS[select(2, UnitClass(unit))] or {r = 1, g = 1, b = 1, colorStr = "ffffffff"}
end

-- Check if the player is following someone
function Self.IsFollowing(unit)
    return AutoFollowStatus:IsShown() and (not unit or unit == AutoFollowStatusText:GetText():match(Self.PATTERN_FOLLOW))
end

-- Check if the given unit is on your friend list
function Self.IsFriend(unit)
    local unit = Self.GetName(unit)

    for i=1, GetNumFriends() do
        if GetFriendInfo(i) == unit then
            return true
        end
    end
end

-- Check if the current group is a guild group (>=80% guild members)
function Self.IsGuildGroup()
    if not IsInGuild() or not IsInGroup() then
        return false
    end

    local guild = GetGuildInfo("player")
    local count = 0

    for i=1, GetNumGroupMembers() do
        if guild == GetGuildInfo(GetRaidRosterInfo(i)) then
            count = count + 1
        end
    end

    return count / GetNumGroupMembers() >= 0.8
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
function Self.ScanTooltip(fn, linkOrbag, slot)
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
            fn(i, line, lines)
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
function Self.SearchBags(fn, startBag, startSlot)
    local endBag = not startSlot and startBag or NUM_BAG_SLOTS
    startBag = startBag or 0
    startSlot = startSlot or 1

    for bag = startBag, endBag do
        for slot = bag == startBag and startSlot or 1, GetContainerNumSlots(bag) do
            local id = GetContainerItemID(bag, slot)
            if id then
                local r = {fn(Addon.Item.FromBagSlot(bag, slot), id, bag, slot)}
                if r[1] ~= nil then
                    return unpack(r)
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

-------------------------------------------------------
--                       Table                       --
-------------------------------------------------------

-- Make sure the given value is a table
function Self.Tbl(v)
    return type(v) ~= "table" and {v} or v
end

-- Get a value from a table
function Self.TblGet(t, path)
    return Self.TblFoldL(Self.TblPath(path), function (u, k)
        if u == nil or k == nil then return u else return u[k] end
    end, t)
end

-- Get a random entry from the table
function Self.TblRandom(t)
    local keys = Self.TblKeys(t)
    return #keys > 0 and t[keys[math.random(#keys)]] or nil
end

-- Set a value on a table
function Self.TblSet(t, path, val)
    path = Self.TblPath(path)
    Self.TblFoldL(path, function (u, k, i)
        if i == #path then u[k] = val elseif u[k] == nil then u[k] = {} end
        return u[k]
    end, t)
    return t
end

-- Convert a dot-separated string path (or just a number) to an array of segments
function Self.TblPath(path)
    if type(path) == "string" then
        return Self(path).Split(".").Map(function (v) return Self.StrIsNumber(v) and tonumber(v) or v end)()
    elseif type(path) == "number" then
        return {path}
    else
        return path
    end
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
function Self.TblFoldL(t, fn, u)
    fn = Self.Fn(fn)
    local i, v = next(t)
    while i do
        u = fn(u, v, i)
        i, v = next(t, i)
    end
    return u
end

-- Iterate through a table
function Self.TblIter(t, fn, u)
    fn = Self.Fn(fn)
    return Self.TblFoldL(t, function (u, v, i)
        fn(v, i, u)
        return u
    end, u or {})
end

-- Apply a function to all values
function Self.TblApply(t, fn, ...)
    fn = Self.Fn(fn)
    local args = {...}
    Self.TblIter(t, function (v, i)
        fn(v, unpack(args))
    end)
    return t
end

-- Copy a table
function Self.TblCopy(t)
    return Self.TblIter(function (v, i, u)
        u[i] = v
    end)
end

-- Iterate a table in chunks of n
function Self.TblChunk(t, n, f)
    local u = {}
    Self.TblIter(t, function (v, i, u)
        tinsert(u, v)
        if #u == (n or 1) then f(u) wipe(u) end
    end, u)
    if #u > 0 then f(u) end
end

-- Count, sum up, multiply
function Self.TblCount(t) return Self.TblFoldL(t, Self.FnInc, 0) end
function Self.TblSum(t) return Self.TblFoldL(t, Self.FnAdd, 0) end
function Self.TblMul(t) return Self.TblFoldL(t, Self.FnMul, 1) end

-- SEARCH

-- Search for something in a table and return the index
function Self.TblSearch(t, fn)
    fn = Self.Fn(fn) or Self.FnId
    local i, v = next(t)
    while i do
        if fn(v, i) then return i end
        i, v = next(t, i)
    end
end

-- Check if one table is contained within the other
function Self.TblContains(t, u, deep)
    return not Self.TblSearch(u, function (v, i)
        if deep and type(v) == "table" then
            return type(t[i]) ~= "table" or not Self.TblContains(t[i], v, true)
        else
            return t[i] ~= v
        end
    end)
end

-- Check if two tables are equal
function Self.TblEquals(a, b, deep)
    return type(b) == "table" and Self.TblContains(a, b, deep) and Self.TblContains(b, a, deep)
end

-- Find a value in a table
function Self.TblFind(t, val)
    return Self.TblSearch(t, Self.FnEq(val))
end

-- Find a set of key/value pairs in a table
function Self.TblFindWhere(t, u, deep)
    return Self.TblSearch(t, function (v)
        return Self.TblContains(v, u, deep)
    end)
end

-- Find the first element (optinally matching a fn)
function Self.TblFirst(t, fn)
    local i = Self.TblSearch(t, fn or Self.FnTrue)
    if i then return t[i] else return nil end
end

-- Find the first set of key/value pairs in a table
function Self.TblFirstWhere(t, u)
    local i = Self.TblFindWhere(t, u)
    if i then return t[i] else return nil end
end

-- FILTER

-- Filter by a function
function Self.TblFilter(t, fn, k)
    fn = Self.Fn(fn) or Self.FnId
    return Self.TblIter(t, function (v, i, u)
        if fn(v, i) then
            if k then u[i] = v else tinsert(u, v) end
        end
    end)
end

-- Pick specific keys from a table
function Self.TblSelect(t, ...)
    local keys = type(select(1, ...)) == "table" and select(1, ...) or {...}
    return Self.TblIter(keys, function (v, i, u)
        u[v] = t[v]
    end)
end

-- Omit specific keys from a table
function Self.TblOmit(t, ...)
    local keys = Self.TblFlip(type(select(1, ...)) == "table" and select(1, ...) or {...}, Self.FnTrue)
    return Self.TblFilter(t, function (v, i) return not keys[i] end, true)
end

-- Filter by a value
function Self.TblOnly(t, v, k)
    return Self.TblFilter(t, Self.FnEq(v), k)
end

-- Filter by not being a value
function Self.TblExcept(t, val, k)
    return Self.TblFilter(t, function (v)
        return val ~= v
    end, k)
end

-- Filter by a set of key/value pairs in a table
function Self.TblWhere(t, u, k, deep)
    return Self.TblFilter(t, function (v, i)
        return Self.TblContains(v, u, deep)
    end, k)
end

-- Filter by not having a set of key/value pairs in a table
function Self.TblExceptWhere(t, u, k, deep)
    return Self.TblFilter(t, function (v, i)
        return not Self.TblContains(v, u, deep)
    end, k)
end

-- MAP

-- Change table values by applying a function
function Self.TblMap(t, fn)
    fn = Self.Fn(fn)
    return Self.TblIter(t, function (v, i, u)
        u[i] = fn(v, i)
    end)
end

-- Get table keys
function Self.TblKeys(t)
    return Self.TblIter(t, function (v, i, u) tinsert(u, i) end)
end

-- Get table values as continuously indexed list
function Self.TblValues(t)
    local i = 1
    return Self.TblIter(t, function (v, _, u)
        u[i] = v
        i = i + 1
    end)
end

-- Flip table keys and values
function Self.TblFlip(t, fn)
    fn = Self.Fn(fn)
    return Self.TblIter(t, function (v, i, u)
        if fn then u[v] = fn(v, i) else u[v] = i end
    end)
end

-- Extract a list of property values
function Self.TblPluck(t, k)
    return Self.TblMap(t, Self.FnGet(k))
end

-- GROUP

-- Group table entries by funciton
function Self.TblGroup(t, fn)
    fn = Self.Fn(fn) or Self.FnId
    return Self.TblIter(t, function (v, i, u)
        i = fn(v, i)
        u[i] = u[i] or {}
        tinsert(u[i], v)
    end)
end

-- Group table entries by key
function Self.TblGroupBy(t, k)
    return Self.TblGroup(t, Self.FnGet(k))
end

-- Group the keys with the same values
function Self.TblGroupKeys(t)
    return Self.TblIter(t, function (v, i, u)
        u[v] = u[v] or {}
        tinsert(u[v], i)
    end)
end

-- SET

-- Make sure all table entries are unique 
function Self.TblUnique(t, k)
    local u = {}
    return Self.Filter(function (v)
        local r = not u[v]
        u[v] = true
        return r
    end, k)
end

-- Calculate the intersection of tables
function Self.TblIntersect(t, ...)
    local args = {...}
    local k = args[#args] == true and tremove(args)

    return Self.TblFoldL(args, function (u, tbl)
        tbl = Self.TblFlip(tbl, Self.FnTrue)
        return Self.TblFilter(u, function (v) return tbl[v] end, k)
    end, t)
end

-- Calculate the difference between tables
function Self.TblDiff(t, ...)
    local args = {...}
    local k = args[#args] == true and tremove(args)

    return Self.TblFoldL(args, function (u, tbl)
        tbl = Self.TblFlip(tbl, Self.FnTrue)
        return Self.TblFilter(u, function (v) return not tbl[v] end, k)
    end, t)
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
function Self.TblSort(t, fn)
    fn = fn == true and function (a, b) return a > b end or Self.Fn(fn) or nil
    table.sort(t, fn)
    return t
end

-- Merge two or more tables
function Self.TblMerge(t, ...)
    t = t or {}
    for _,u in pairs({...}) do
        local i = 1
        local k, v = next(u)
        while k do
            if k == i then tinsert(t, v) else t[k] = v end
            i = i + 1
            k, v = next(u, k)
        end
    end
    return t
end

-- OTHER

-- This just looks nicer when chaining
function Self.TblUnpack(t, fn)
    fn = Self.Fn(fn) or Self.FnId
    return fn(unpack(t))
end

-- Flatten a list of tables by one dimension
function Self.TblFlatten(t)
    return Self.TblIter(t, function (v, _, u)
        Self.TblMerge(u, v)
    end, {})
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
--                      Function                     --
-------------------------------------------------------

function Self.Fn(fn) return type(fn) == "string" and _G[fn] or fn end
function Self.FnId(...) return ... end
function Self.FnTrue() return true end
function Self.FnFalse() return false end

-- Some math
function Self.FnInc(i) return i+1 end
function Self.FnDec(i) return i-1 end
function Self.FnAdd(a, b) return a+b end
function Self.FnSub(a, b) return a-b end
function Self.FnMul(a, b) return a*b end
function Self.FnDiv(a, b) return a/b end

-- Get a function that always returns the same values
function Self.FnConst(...)
    local args = {...}
    return function () return unpack(args) end
end

-- Get function that always gets a specific key from a given table
function Self.FnGet(k) return Self.FnPrep(Self.TblGet, nil, k) end
function Self.FnGetFrom(t) return Self.FnPrep(Self.TblGet, t) end

-- Get a function that always compares to a given value
function Self.FnEq(v)
    return function (w) return w == v end
end

-- MODIFY

-- Fill in some function arguments already
function Self.FnPrep(fn, ...)
    fn = Self.Fn(fn)
    local args = {...}
    return function (...)
        return fn(unpack(Self.TblMerge({}, args, {...})))
    end
end

-- Make the function only accept n arguments and ignore the rest
function Self.FnArgs(fn, n)
    return function (...)
        return fn(unpack({...}, 1, n))
    end
end

-------------------------------------------------------
--                       Other                       --
-------------------------------------------------------

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

-- Shortcut for TblFind
function Self.In(val, ...)
    local t = #{...} > 1 and {...} or ...
    return Self.TblFind(t, val) ~= nil
end

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

-- Dump all given values
function Self.Dump(...)
    for i, v in pairs({...}) do
        print(Self.ToString(v))
    end
end

-- Enable chain-calling
setmetatable(Self, {
    __call = function (_, v)
        local c = {v = v}
        setmetatable(c, {
            __index = function (c, k)
                return function (...)

                    -- Figure out the correct key
                    local pre = Self.Switch(type(c.v)) {
                        table = "Tbl",
                        string = "Str",
                        number = "Num",
                        ["function"] = "Fn"
                    }
                    k = Self.StrUcFirst(k)
                    k = pre and Self[pre .. k] and pre .. k or k

                    -- Call the fn and save the result
                    c.v = Self[k](c.v, ...)
                    return c
                end
            end,
            __call = function (c, i)
                local v = rawget(c, "v")
                if i ~= nil then return v[i] else return v end
            end
        })
        return c
    end
})

-- Export

Addon.Util = Self