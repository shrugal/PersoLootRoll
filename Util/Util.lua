local Name, Addon = ...
local Unit = Addon.Unit
local Self = Addon.Util

-------------------------------------------------------
--                        WoW                        --
-------------------------------------------------------

-- Interaction distances
Self.INTERACT_INSPECT = 1 -- 28 yards
Self.INTERACT_TRADE = 2   -- 11.11 yards
Self.INTERACT_DUEL = 3    -- 9.9 yards
Self.INTERACT_FOLLOW = 4  -- 28 yards

Self.PATTERN_FOLLOW = AUTOFOLLOWSTART:gsub("%%s", "(.+)")

-- Check if the current group is a guild group (>=80% guild members)
function Self.IsGuildGroup(guild)
    guild = guild or Unit.GuildName("player")
    if not guild or not IsInGroup() then
        return false
    end

    local count = 0

    for i=1, GetNumGroupMembers() do
        if guild == Unit.GuildName(GetRaidRosterInfo(i)) then
            count = count + 1
        end
    end

    return count / GetNumGroupMembers() >= 0.8
end

-- Get hidden tooltip for scanning
function Self.GetHiddenTooltip()
    if not Self.hiddenTooltip then
        Self.hiddenTooltip = CreateFrame("GameTooltip", Addon.PREFIX .. "_HiddenTooltip", nil, "GameTooltipTemplate")
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
        local line = _G[Addon.PREFIX .."_HiddenTooltipTextLeft" .. i]:GetText()
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

-- SUB

function Self.TblSub(t, s, e) return {unpack(t, s or 1, e)} end
function Self.TblHead(t, n) return Self.TblSub(t, 1, n or 1) end
function Self.TblTail(t, n) return Self.TblSub(t, #t - (n or 1)) end
function Self.TblSplice(t, s, e, u) return Self.TblMerge(Self.TblHead(t, s), u or {}, Self.TblSub(#t, e)) end

-- ITERATE

-- Good old FoldLeft
function Self.TblFoldL(t, fn, u, index, ...)
    fn = Self.Fn(fn)
    for i,v in pairs(t) do
        if index then
            u = fn(u, v, i, ...)
        else
            u = fn(u, v, ...)
        end
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

-- COUNT, SUM, MULTIPLY, MIN, MAX

function Self.TblCount(t) return Self.TblFoldL(t, Self.FnInc, 0) end
function Self.TblSum(t) return Self.TblFoldL(t, Self.FnAdd, 0) end
function Self.TblMul(t) return Self.TblFoldL(t, Self.FnMul, 1) end
function Self.TblMin(t, start) return Self.TblFoldL(t, math.min, start or select(2, next(t))) end
function Self.TblMax(t, start) return Self.TblFoldL(t, math.max, start or select(2, next(t))) end

-- Count the # of occurences of given value(s)
function Self.TblCountVal(t, ...)
    local n = 0
    for i,v in pairs(t) do
        if Self.In(v, ...) then n = n + 1 end
    end
    return n
end

-- Count the # of occurences of everything except given value(s)
function Self.TblCountNot(t, ...)
    local n = 0
    for i,v in pairs(t) do
        if not Self.In(v, ...) then n = n + 1 end
    end
    return n
end

-- Count the # of tables that have given key/val pairs
function Self.TblCountWhere(t, keyOrTbl, valOrDeep)
    local n = 0
    for i,u in pairs(t) do
        if Self.TblFindWhere(u, keyOrTbl, valOrDeep) then
            n = n + 1
        end
    end
    return n
end

-- Count using a function
function Self.TblCountFn(t, fn, ...)
    local n, fn = 0, Self.Fn(fn)
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
    return type(a) == "table" and type(b) == "table" and Self.TblContains(a, b, deep) and Self.TblContains(b, a, deep)
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
    local i = Self.TblFindWhere(t, keyOrTbl, valOrDeep)
    if i ~= nil then return t[i] end
end

-- FILTER

-- Filter by a function
function Self.TblFilter(t, fn, k, ...)
    fn = Self.Fn(fn) or Self.FnId
    for i,v in pairs(t) do
        if not fn(v, i, ...) then
            if k then t[i] = nil else tremove(t, i) end
        end
    end
    return t
end

-- Pick specific keys from a table
function Self.TblSelect(t, ...)
    for i,v in pairs(t) do
        if not Util.In(i, ...) then
            t[i] = nil
        end
    end
    return t
end

-- Omit specific keys from a table
function Self.TblUnselect(t, ...)
    if type(...) == "table" then
        for i,v in pairs(...) do t[v] = nil end
    else
        for i=1,select("#", ...) do t[select(i, ...)] = nil end
    end
    return t
end

-- Filter by a value
function Self.TblOnly(t, val, k)
    for i,v in pairs(t) do
        if v ~= val then
            if k then t[i] = nil else tremove(t, i) end
        end
    end
    return t
end

-- Filter by not being a value
function Self.TblExcept(t, val, k)
    for i,v in pairs(t) do
        if v == val then
            if k then t[i] = nil else tremove(t, i) end
        end
    end
    return t
end

-- Filter by a set of key/value pairs in a table
function Self.TblWhere(t, keyOrTbl, valOrDeep, k)
    for i,v in pairs(t) do
        if not Self.TblFindWhere(v, keyOrTbl, valOrDeep) then
            if k then t[i] = nil else tremove(t, i) end
        end
    end
    return t
end

-- Filter by not having a set of key/value pairs in a table
function Self.TblExceptWhere(t, keyOrTbl, valOrDeep, k)
    for i,v in pairs(t) do
        if Self.TblFindWhere(t, keyOrTbl, valOrDeep) then
            if k then t[i] = nil else tremove(t, i) end
        end
    end
    return t
end

-- COPY

-- Copy a table and optionally apply a function to every entry
function Self.TblCopy(t, fn, index, ...)
    local fn, u = Self.Fn(fn), {}
    for i,v in pairs(t) do
        if fn then
            if index then
                u[i] = fn(v, i, ...)
            else
                u[i] = fn(v, ...)
            end
        else
            u[i] = v
        end
    end
    return u
end

-- Filter by a function
function Self.TblCopyFilter(t, fn, k, ...)
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
function Self.TblCopySelect(t, ...)
    local u = {}
    if type(...) == "table" then
        for i,v in pairs(...) do u[v] = t[v] end
    else
        for i=1,select("#", ...) do
            local v = select(i, ...)
            u[v] = t[v]
        end
    end
    return u
end

-- Omit specific keys from a table
function Self.TblCopyUnselect(t, ...)
    local u, isTbl = {}, type(...) == "table"
    for i,v in pairs(t) do
        if not Util.In(i, ...) then
            u[i] = v
        end
    end
    return u
end

-- Filter by a value
function Self.TblCopyOnly(t, val, k)
    local u = {}
    for i,v in pairs(t) do
        if v == val then
            if k then u[i] = v else tinsert(u, v) end
        end
    end
    return u
end

-- Filter by not being a value
function Self.TblCopyExcept(t, val, k)
    local u = {}
    for i,v in pairs(t) do
        if v ~= val then
            if k then u[i] = v else tinsert(u, v) end
        end
    end
    return u
end

-- Filter by a set of key/value pairs in a table
function Self.TblCopyWhere(t, keyOrTbl, valOrDeep, k)
    local u = {}
    for i,v in pairs(t) do
        if Self.TblFindWhere(u, keyOrTbl, valOrDeep) then
            if k then u[i] = v else tinsert(u, v) end
        end
    end
    return u
end

-- Filter by not having a set of key/value pairs in a table
function Self.TblCopyExceptWhere(t, keyOrTbl, valOrDeep, k)
    local u = {}
    for i,v in pairs(t) do
        if not Self.TblFindWhere(u, keyOrTbl, valOrDeep) then
            if k then u[i] = v else tinsert(u, v) end
        end
    end
    return u
end

-- MAP

-- Change table values by applying a function
function Self.TblMap(t, fn, index, ...)
    fn = Self.Fn(fn)
    for i,v in pairs(t) do
        if index then
            t[i] = fn(v, i, ...)
        else
            t[i] = fn(v, ...)
        end
    end
    return t
end

-- Change table keys by applying a function
function Self.TblMapKeys(t, fn, value, ...)
    fn = Self.Fn(fn)
    local u = {}
    for i,v in pairs(t) do
        if value then
            u[fn(i, v, ...)] = v
        else
            u[fn(i, ...)] = v
        end
    end
    return u
end

-- Change table values by extracting a key
function Self.TblPluck(t, k)
    for i,v in pairs(t) do
        t[i] = v[k]
    end
    return t
end

-- Flip table keys and values
function Self.TblFlip(t, fn, ...)
    fn = Self.Fn(fn)
    local u = {}
    for i,v in pairs(t) do
        if fn then
            u[v] = fn(v, i, ...)
        else
            u[v] = i
        end
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
function Self.TblUnique(t, k)
    for i,v in pairs(t) do
        if Self.TblCountVal(t, v) > 1 then
            if k then t[i] = nil else tremove(t, i) end
        end
    end
end

-- Substract the given tables from the table
function Self.TblDiff(t, ...)
    local k = select(select("#", ...), ...) == true

    for i,v in pairs(t) do
        for i=1, select("#", ...) - (k and 1 or 0) do
            if Self.In(v, (select(i, ...))) then
                if k then t[i] = nil else tremove(t, i) end
                break
            end
        end
    end
    return t
end

-- Intersect the table with given tables
function Self.TblIntersect(t, ...)
    local k = select(select("#", ...), ...) == true

    for i,v in pairs(t) do
        for i=1, select("#", ...) - (k and 1 or 0) do
            if not Self.In(v, (select(i, ...))) then
                if k then t[i] = nil else tremove(t, i) end
                break
            end
        end
    end
    return t
end

-- Check if the intersection of the given tables is not empty
function Self.TblIntersects(t, ...)
    for i,v in pairs(t) do
        local found = true
        for i=1, select("#", ...) do
            if not Self.In(v, (select(i, ...))) then
                found = false
                break
            end
        end

        if found then
            return true
        end
    end
    return false
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

function Self.StrIsEmpty(str)
    return not Self.IsStr(str) or str == ""
end

function Self.StrWrap(str, before, after)
    if Self.StrIsEmpty(str) then
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

-- Safecall
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

-- Shortcut for val == x or val == y or ...
function Self.In(val, ...)
    if type(...) == "table" then
        return Self.TblFind((...), val) ~= nil
    else
        for i=1,select("#", ...) do
            if select(i, ...) == val then return true end
        end
        return false
    end
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
            end, "{", true) .. "}"
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
    for i=1,select("#", ...) do
        print(Self.ToString((select(i, ...))))
    end
end

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

    local t = type(v)
    local pre = t == "table" and "Tbl" or t == "string" and "Str" or t == "number" and "num" or t == "function" and "Fn" or ""

    c.v = (Self[pre .. k] or Self[k])(v, ...)
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