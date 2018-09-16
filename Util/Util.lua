local Name, Addon = ...
local Unit = Addon.Unit
local Self = Addon.Util

-------------------------------------------------------
--                        WoW                        --
-------------------------------------------------------

-- More than this much percent of players in the group must be from
-- one guild/community for it to be considered a guild/community group
Self.GROUP_THRESHOLD = 0.50

-- Interaction distances
Self.INTERACT_INSPECT = 1 -- 28 yards
Self.INTERACT_TRADE = 2   -- 11.11 yards
Self.INTERACT_DUEL = 3    -- 9.9 yards
Self.INTERACT_FOLLOW = 4  -- 28 yards

-- Expansions
Self.EXP_CLASSIC = 1
Self.EXP_BC = 2
Self.EXP_WOTLK = 3
Self.EXP_CATA = 4
Self.EXP_MOP = 5
Self.EXP_WOD = 6
Self.EXP_LEGION = 7
Self.EXP_BFA = 8
Self.EXP_NEXT = 9
Self.EXP_LEVELS = {60, 70, 80, 85, 90, 100, 110, 120, 130, 140}

-- Check if the current group is a guild group
function Self.IsGuildGroup(guild)
    if not IsInGroup() or guild == "" then
        return false
    end

    local n, guilds = GetNumGroupMembers(), Self.Tbl()

    for i=1,n do
        local g = Unit.GuildName(GetRaidRosterInfo(i))
        if g then
            guilds[g] = (guilds[g] or 0) + 1
            if (not guild or g == guild) and guilds[g] / n > Self.GROUP_THRESHOLD then
                Self.TblRelease(guilds)
                return g
            end
        end
    end
    Self.TblRelease(guilds)
end

-- Check if the current group is a community group
function Self.IsCommunityGroup(commId)
    if not IsInGroup() or not Self.TblFirstWhere(C_Club.GetSubscribedClubs(), "clubType", Enum.ClubType.Character, "clubId", commId) then
        return false
    end

    local n, comms = GetNumGroupMembers(), Self.Tbl()
    for i=1,n do
        local c = Unit.CommonClubs(GetRaidRosterInfo(i))
        if c then
            for _,clubId in pairs(c) do
                comms[clubId] = (comms[clubId] or 0) + 1
                if (not commId or commId == clubId) and comms[clubId] / n >= Self.GROUP_THRESHOLD then
                    Self.TblRelease(comms, c)
                    return clubId
                end
            end
            Self.TblRelease(c)
        end
    end
    Self.TblRelease(comms)
end

-- Get a list of guild ranks
function Self.GetGuildRanks()
    local t, i, name = Self.Tbl(), 1, GuildControlGetRankName(1)
    while not Self.StrIsEmpty(name) do
        t[i] = name
        i, name = i + 1, GuildControlGetRankName(i + 1)
    end
    return t
end

function Self.GetClubRanks(clubId)
    local info = C_Club.GetClubInfo(clubId)
    if not info then
        return
    elseif info.clubType == Enum.ClubType.Guild then
        return Self.GetGuildRanks()
    else
        return Self.TblFlip(Enum.ClubRoleIdentifier)
    end
end

-- Get the expansion for the current instance
function Self.GetInstanceExp()
    if IsInInstance() then
        local mapID = C_Map.GetBestMapForUnit("player")
        return mapID and Self.INSTANCES[EJ_GetInstanceForMap(mapID)] or nil
    end
end

-- Check if the legacy loot mode is active
function Self.IsLegacyLoot()
    if IsInInstance() and GetLootMethod() == "personalloot" then
        local iExp = Self.GetInstanceExp()
        local pExp = Self.TblFindFn(Self.EXP_LEVELS, function (v) return v >= UnitLevel("player") end, true)

        return iExp and pExp and iExp < pExp - 1
    end
end

-- Check if currently in a timewalking dungeon
function Self.IsTimewalking()
    return Self.In(select(3, GetInstanceInfo()), 24, 33)
end

function Self.GetNumDroppedItems()
    local difficulty, _, maxPlayers = select(3, GetInstanceInfo())

    if difficulty == DIFFICULTY_DUNGEON_CHALLENGE then
        -- In M+ we get 2 items at the end of the dungeon, +1 if in time, +0.4 per keystone level above 15
        local _, level, _, onTime = C_ChallengeMode.GetCompletionInfo();
        return 2 + (onTime and 1 or 0) + (level > 15 and math.ceil(0.4 * (level - 15)) or 0)
    else
        -- Normally we get about 1 item per 5 players in the group
        local players = GetNumGroupMembers()
        if Self.IsLegacyLoot() then
            players = Self.In(difficulty, DIFFICULTY_RAID_LFR, DIFFICULTY_PRIMARYRAID_LFR, DIFFICULTY_PRIMARYRAID_NORMAL, DIFFICULTY_PRIMARYRAID_HEROIC) and 20 or maxPlayers
        end
        return math.ceil(players / 5)
    end
end

-- Get hidden tooltip for scanning
function Self.GetHiddenTooltip()
    if not Self.hiddenTooltip then
        Self.hiddenTooltip = CreateFrame("GameTooltip", Addon.ABBR .. "_HiddenTooltip", nil, "GameTooltipTemplate")
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
        local line = _G[Addon.ABBR .."_HiddenTooltipTextLeft" .. i]:GetText()
        if line then
            local a, b, c = fn(i, line, lines, ...)
            if a ~= nil then
                return a, b, c
            end
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

-------------------------------------------------------
--                      General                      --
-------------------------------------------------------

-- Check if two values are equal
function Self.Equals(a, b)
    return a == b
end

-- Compare two values, returns -1 for a < b, 0 for a == b and 1 for a > b
function Self.Compare(a, b)
    return a == b and 0
    or a == nil and 1
    or b == nil and -1
    or a > b and 1 or -1
end

-- Create an iterator
function Self.Iter(from, to, step)
    local i = from or 0
    return function (steps, reset)
        i = (reset and (from or 0) or i) + (step or 1) * (steps or 1)
        return (not to or i <= to) and i or nil
    end
end

-- Return val if it's not nil, default otherwise
function Self.Default(val, default)
    if val ~= nil then return val else return default end
end

-- Return a when cond is true, b otherwise
function Self.Check(cond, a, b)
    if cond then return a else return b end
end

-- Iterate tables or parameter lists
local Fn = function (t, i)
    i = (i or 0) + 1
    if i > #t then
        Self.TblReleaseTmp(t)
    else
        local v = t[i]
        return i, Self.Check(v == Self.TBL_NIL, nil, v)
    end
end
function Self.Each(...)
    if ... and type(...) == "table" then
        return next, ...
    elseif select("#", ...) == 0 then
        return Self.FnNoop
    else
        return Fn, Self.TblTmp(...)
    end
end
function Self.IEach(...)
    if ... and type(...) == "table" then
        return Fn, ...
    else
        return Self.Each(...)
    end
end

-- Shortcut for val == x or val == y or ...
function Self.In(val, ...)
    for i,v in Self.Each(...) do
        if v == val then return true end
    end
    return false
end

-- Shortcut for val == a and b or val == c and d or ...
function Self.Select(val, ...)
    local n = select("#", ...)
    
    for i=1, n - n % 2, 2 do
        local a, b = select(i, ...)
        if val == a then return b end
    end

    if n % 2 == 1 then
        return select(n, ...)
    end
end

-- STACK: Useful for ternary conditionals, e.g. val = (cond1 and Push(false) or cond2 and Push(true) or Push(nil)).Pop()

Self.stack = {}

function Self.Push(val)
    tinsert(Self.stack, val == nil and Self.TBL_NIL or val)
    return Self
end

function Self.Pop()
    local val = tremove(Self.stack)
    return Self.Check(val == Self.TBL_NIL, nil, val)
end

-------------------------------------------------------
--                       Table                       --
-------------------------------------------------------

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

-- REUSABLE TABLES: Store unused tables in a cache to reuse them later

-- A cache for temp tables
Self.tblPool = {}
Self.tblPoolSize = 10

-- For when we need an empty table as noop or special marking
Self.TBL_EMPTY = {}

-- For when we need to store nil values in a table
Self.TBL_NIL = {}

-- Get a table (newly created or from the cache), and fill it with values
function Self.Tbl(...)
    local t = tremove(Self.tblPool) or {}
    for i=1, select("#", ...) do
        t[i] = select(i, ...)
    end
    return t
end

-- Get a table (newly created or from the cache), and fill it with key/value pairs
function Self.TblHash(...)
    local t = tremove(Self.tblPool) or {}
    for i=1, select("#", ...), 2 do
        t[select(i, ...)] = select(i + 1, ...)
    end
    return t
end

-- Add one or more tables to the cache, first parameter can define a recursive depth
function Self.TblRelease(...)
    local depth = type(...) ~= "table" and (type(...) == "number" and max(0, (...)) or ... and Self.tblPoolSize) or 0

    for i=1, select("#", ...) do
        local t = select(i, ...)
        if type(t) == "table" and t ~= Self.TBL_EMPTY and t ~= Self.TBL_NIL then
            if #Self.tblPool < Self.tblPoolSize then
                tinsert(Self.tblPool, t)

                if depth > 0 then
                    for _,v in pairs(t) do
                        if type(v) == "table" then Self.TblRelease(depth - 1, v) end
                    end
                end

                wipe(t)
                setmetatable(t, nil)
            else
                break
            end
        end
    end
end

-- TEMPORARY TABLES: Tables that are automatically released after certain operations (such as loops)

function Self.TblTmp(...)
    local t = tremove(Self.tblPool) or {}
    for i=1, select("#", ...) do
        local v = select(i, ...)
        t[i] = v == nil and Self.TBL_NIL or v
    end
    return setmetatable(t, Self.TBL_EMPTY)
end

function Self.TblHashTmp(...) return setmetatable(Self.TblHash(...), Self.TBL_EMPTY) end
function Self.TblIsTmp(t) return getmetatable(t) == Self.TBL_EMPTY end

function Self.TblReleaseTmp(...)
    for i=1, select("#", ...) do
        local t = select(i, ...)
        if type(t) == "table" and Self.TblIsTmp(t) then Self.TblRelease(t) end
    end
end

-- GET/SET

-- Get a value from a table
function Self.TblGet(t, ...)
    local n = select("#", ...)

    if n == 1 then
        if type(...) == "table" then
            return Self.TblGet(t, unpack(...))
        elseif type(...) == "string" and (...):find("%.") then
            return Self.TblGet(t, ("."):split(...))
        end
    end
    
    for i=1,n do if t ~= nil then t = t[select(i, ...)] end end

    return t
end

-- Set a value on a table
function Self.TblSet(t, ...)
    local n = select("#", ...) - 1
    local val = select(n + 1, ...)

    if n == 1 then
        if type(...) == "table" then
            return Self.TblSet(t, unpack((...)), val)
        elseif type(...) == "string" and (...):find("%.") then
            return Self.TblSet(t, ("."):split((...)), val)
        end
    end

    local u = t
    for i=1,n do
        local k = select(i, ...)
        if i == n then
            u[k] = val
        else
            if u[k] == nil then u[k] = {} end
            u = u[k]
        end
    end

    return t
end

-- Get a random key from the table
function Self.TblRandomKey(t)
    local keys = Self.TblKeys(t)
    local r = #keys > 0 and keys[math.random(#keys)] or nil
    Self.TblRelease(keys)
    return r
end

-- Get a random entry from the table
function Self.TblRandom(t)
    local key = Self.TblRandomKey(t)
    return key and t[key]
end

-- Get table keys
function Self.TblKeys(t)
    local u = Self.Tbl()
    for i,v in pairs(t) do tinsert(u, i) end
    return u
end

-- Get table values as continuously indexed list
function Self.TblValues(t)
    local u = Self.Tbl()
    for i,v in pairs(t) do tinsert(u, v) end
    return u
end

-- Turn a table into a continuously indexed list (in-place)
function Self.TblList(t)
    local k, n, i, v = 1, Self.TblCount(t), next(t, nil)
    while i do
        local nextI, nextV = next(t, i)
        if type(i) ~= "number" or i >= k then
            if i ~= k then
                for j=k, n do
                    if t[j] == nil then
                        k, t[j], t[i] = j, v break
                    end
                end
            end
            k = k + 1
        end
        i, v = nextI, nextV
    end
    return t
end

-- Check if the table is a continuesly indexed list
function Self.TblIsList(t)
    return #t == Self.TblCount(t)
end

-- SUB

function Self.TblSub(t, s, e) return {unpack(t, s or 1, e)} end
function Self.TblHead(t, n) return Self.TblSub(t, 1, n or 1) end
function Self.TblTail(t, n) return Self.TblSub(t, #t - (n or 1)) end
function Self.TblSplice(t, s, e, u) return Self.TblMerge(Self.TblHead(t, s), u or {}, Self.TblSub(#t, e)) end

-- ITERATE

-- Good old FoldLeft
function Self.TblFoldL(t, fn, u, index, ...)
    fn, u = Self.Fn(fn), u or Self.Tbl()
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

-- Call a function on every table entry
function Self.TblCall(t, fn, val, index, ...)
    for i,v in pairs(t) do
        local f = Self.Fn(fn, v)
        if val then
            if index then f(v, i, ...) else f(v, ...) end
        else
            if index then f(i, ...) else f(...) end
        end
    end
end

-- COUNT, SUM, MULTIPLY, MIN, MAX

function Self.TblCount(t) return Self.TblFoldL(t, Self.FnInc, 0) end
function Self.TblSum(t) return Self.TblFoldL(t, Self.FnAdd, 0) end
function Self.TblMul(t) return Self.TblFoldL(t, Self.FnMul, 1) end
function Self.TblMin(t, start) return Self.TblFoldL(t, math.min, start or select(2, next(t))) end
function Self.TblMax(t, start) return Self.TblFoldL(t, math.max, start or select(2, next(t))) end

-- Count the # of occurences of given value(s)
function Self.TblCountOnly(t, ...)
    local n = 0
    for i,v in pairs(t) do
        if Self.In(v, ...) then n = n + 1 end
    end
    return n
end

-- Count the # of occurences of everything except given value(s)
function Self.TblCountExcept(t, ...)
    local n = 0
    for i,v in pairs(t) do
        if not Self.In(v, ...) then n = n + 1 end
    end
    return n
end

-- Count the # of tables that have given key/val pairs
function Self.TblCountWhere(t, ...)
    local n = 0
    for i,u in pairs(t) do
        if Self.TblFindWhere(u, ...) then n = n + 1 end
    end
    return n
end

-- Count using a function
function Self.TblCountFn(t, fn, index, ...)
    local n, fn = 0, Self.Fn(fn)
    for i,v in pairs(t) do
        n = n + index and fn(v, i, ...) or fn(v, ...)
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

-- Check if a table matches the given key-value pairs
function Self.TblMatches(t, ...)
    for i=1, select("#", ...), 2 do
        local key, val = select(i, ...)
        local v = Self.TblGet(t, key)
        if v == nil or val ~= nil and v ~= val then
            return false
        end
    end
    return true
end

-- Check a table's existence and content
function Self.TblIsFilled(t) return t and next(t) and t or nil end

-- Find a value in a table
function Self.TblFind(t, val)
    for i,v in pairs(t) do
        if v == val then return i, v end
    end
end

-- Find a set of key/value pairs in a table
function Self.TblFindWhere(t, ...)
    local isTbl, tbl, deep = type(...) == "table", ...
    for i,v in pairs(t) do
        if isTbl and Self.TblContains(v, tbl, deep) or not isTbl and Self.TblMatches(v, ...) then
            return i, v
        end
    end
end

-- Find the first element matching a fn
function Self.TblFindFn(t, fn, val, index, ...)
    for i,v in pairs(t) do
        if Self.FnCall(Self.Fn(fn, v), v, i, val, index, ...) then
            return i, v
        end
    end
end

-- Find the first element (optinally matching a fn)
function Self.TblFirst(t, fn, val, index, ...)
    if not fn then
        return select(2, next(t))
    else
        return select(2, Self.TblFindFn(t, fn, val, index, ...))
    end
end

-- Find the first set of key/value pairs in a table
function Self.TblFirstWhere(t, ...)
    return select(2, Self.TblFindWhere(t, ...))
end

-- FILTER

-- Filter by a function
function Self.TblFilter(t, fn, index, k, ...)
    fn = Self.Fn(fn) or Self.FnId

    if not k and Self.TblIsList(t) then
        for i=#t,1,-1 do
            if index and not fn(t[i], i, ...) or not index and not fn(t[i], ...) then
                tremove(t, i)
            end
        end
    else
        for i,v in pairs(t) do
            if index and not fn(v, i, ...) or not index and not fn(v, ...) then
                Self.TblRemove(t, i, k)
            end
        end
    end

    return t
end

-- Pick specific keys from a table
function Self.TblSelect(t, ...)
    for i,v in pairs(t) do
        if not Util.In(i, ...) then t[i] = nil end
    end
    return t
end

-- Omit specific keys from a table
function Self.TblUnselect(t, ...)
    for i,v in Self.Each(...) do t[v] = nil end
    return t
end

-- Filter by a value
function Self.TblOnly(t, val, k)
    return Self.TblFilter(t, Self.Equals, false, k, val)
end

-- Filter by not being a value
local Fn = function (v, val) return v ~= val end
function Self.TblExcept(t, val, k)
    return Self.TblFilter(t, Fn, false, k, val)
end

-- Filter by a set of key/value pairs in a table
function Self.TblWhere(t, k, ...)
    return Self.TblFilter(t, Self.TblMatches, false, k, ...)
end

-- Filter by not having a set of key/value pairs in a table
local Fn = function (...) return not Self.TblMatches(...) end
function Self.TblExceptWhere(t, k, ...)
    return Self.TblFilter(t, Fn, false, k, ...)
end

-- COPY

-- Copy a table and optionally apply a function to every entry
function Self.TblCopy(t, fn, index, ...)
    local fn, u = Self.Fn(fn), Self.Tbl()
    for i,v in pairs(t) do
        if fn then
            if index then u[i] = fn(v, i, ...) else u[i] = fn(v, ...) end
        else
            u[i] = v
        end
    end
    return u
end

-- Filter by a function
function Self.TblCopyFilter(t, fn, val, index, k, ...)
    fn = Self.Fn(fn) or Self.FnId
    local u = Self.Tbl()
    for i,v in pairs(t) do
        if Self.FnCall(fn, v, i, val, index, ...) then
            Self.TblInsert(u, i, v, k)
        end
    end
    return u
end

-- Pick specific keys from a table
function Self.TblCopySelect(t, ...)
    local u = Self.Tbl()
    for i,v in Self.Each(...) do u[v] = t[v] end
    return u
end

-- Omit specific keys from a table
function Self.TblCopyUnselect(t, ...)
    local u, isTbl = Self.Tbl(), type(...) == "table"
    for i,v in pairs(t) do
        if not Util.In(i, ...) then
            u[i] = v
        end
    end
    return u
end

-- Filter by a value
function Self.TblCopyOnly(t, val, k)
    local u = Self.Tbl()
    for i,v in pairs(t) do
        if v == val then
            Self.TblInsert(u, i, v, k)
        end
    end
    return u
end

-- Filter by not being a value
function Self.TblCopyExcept(t, val, k)
    local u = Self.Tbl()
    for i,v in pairs(t) do
        if v ~= val then
            Self.TblInsert(u, i, v, k)
        end
    end
    return u
end

-- Filter by a set of key/value pairs in a table
function Self.TblCopyWhere(t, k, ...)
    local u = Self.Tbl()
    for i,v in pairs(t) do
        if Self.TblFindWhere(u, ...) then
            Self.TblInsert(u, i, v, k)
        end
    end
    return u
end

-- Filter by not having a set of key/value pairs in a table
function Self.TblCopyExceptWhere(t, k, ...)
    local u = Self.Tbl()
    for i,v in pairs(t) do
        if not Self.TblFindWhere(u, ...) then
            Self.TblInsert(u, i, v, k)
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
    local u = Self.Tbl()
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
function Self.TblFlip(t, val, ...)
    local u = Self.Tbl()
    for i,v in pairs(t) do
        if type(val) == "function" then
            u[v] = val(v, i, ...)
        elseif val ~= nil then
            u[v] = val
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
    local u = Self.Tbl()
    for i,v in pairs(t) do
        i = fn(v, i)
        u[i] = u[i] or Self.Tbl()
        tinsert(u[i], v)
    end
    return u
end

-- Group table entries by key
function Self.TblGroupBy(t, k)
    fn = Self.Fn(fn) or Self.FnId
    local u = Self.Tbl()
    for i,v in pairs(t) do
        i = v[k]
        u[i] = u[i] or Self.Tbl()
        tinsert(u[i], v)
    end
    return u
end

-- Group the keys with the same values
function Self.TblGroupKeys(t)
    local u = Self.Tbl()
    for i,v in pairs(t) do
        u[v] = u[v] or Self.Tbl()
        tinsert(u[v], i)
    end
    return u
end

-- SET

-- Make sure all table entries are unique 
function Self.TblUnique(t, k)
    local u = Self.Tbl()
    for i,v in pairs(t) do
        if u[v] ~= nil then
            Self.TblRemove(t, i, k)
        else
            u[v] = true
        end
    end
    Self.TblRelease(u)
    return t
end

-- Substract the given tables from the table
function Self.TblDiff(t, ...)
    local k = select(select("#", ...), ...) == true

    for i,v in pairs(t) do
        for i=1, select("#", ...) - (k and 1 or 0) do
            if Self.In(v, (select(i, ...))) then
                Self.TblRemove(t, i, k)
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
                Self.TblRemove(t, i, k)
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

function Self.TblInsert(t, i, v, k) if k or type(i) ~= "number" then t[i] = v else tinsert(t, v) end end
function Self.TblRemove(t, i, k) if k or type(i) ~= "number" then t[i] = nil else tremove(t, i) end end
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
local Fn = function (a, b) return Self.Compare(b, a) end
function Self.TblSortBy(t, ...)
    local args = type(...) == "table" and (...) or {...}
    return Self.TblSort(t, function (a, b)
        for i=1, #args, 3 do
            local key, default, fn = args[i], args[i+1], args[i+2]            
            fn = fn == true and Fn or Self.Fn(fn) or Self.Compare

            local cmp = fn(a and a[key] or default, b and b[key] or default)
            if cmp ~= 0 then return cmp == -1 end
        end
    end)
end

-- Merge two or more tables
function Self.TblMerge(t, ...)
    t = t or Self.Tbl()
    for i=1,select("#", ...) do
        local tbl, j = (select(i, ...)), 1
        if tbl then
            for k,v in pairs(tbl) do
                if k == j then tinsert(t, v) else t[k] = v end
                j = j + 1
            end
        end
    end
    return t
end

-- OTHER

-- Convert the table into tuples of n
function Self.TblTuple(t, n)
    local u, n, r = Self.Tbl(), n or 2
    for i,v in pairs(t) do
        if not r or #r == n then
            r = Self.Tbl()
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
    return Self.TblFoldL(t, Fn, Self.Tbl())
end

-- Wipe multiple tables at once
function Self.TblWipe(...)
    for i=1,select("#", ...) do wipe((select(i, ...))) end
    return ...
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
    return Self.Tbl(del:split(str))
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

-- Get abbreviation of given length
function Self.StrAbbr(str, length)
    return str:len() <= length and str or str:sub(1, length) .. "..."
end

function Self.StrColor(r, g, b, a)
    return ("%.2x%.2x%.2x%.2x"):format((a or 1) * 255, (r or 1) * 255, (g or 1) * 255, (b or 1) * 255)
end

function Self.StrReplace(str, from, len, sub)
    from, len, sub = from or 1, len or str:len(), sub or ""
    local to = from < 0 and str:len() + from + len + 1 or from + len
    return str:sub(1, from - 1) .. sub .. str:sub(to)
end

function Self.StrToCamelCase(str, del)
    local s = ""
    for v in str:gmatch("[^" .. (del or "%p%s") .. "]+") do
        s = s .. Self.StrUcFirst(v:lower())
    end
    return Self.StrLcFirst(s)
end

function Self.StrFromCamelCase(str, del, case)
    local s = str:gsub("%u", (del or " ") .. "%1")
    return case == true and s:upper() or case == false and s:lower() or s
end

-------------------------------------------------------
--                       Number                      --
-------------------------------------------------------

-- Rounds a number
function Self.NumRound(num, p)
    p = math.pow(10, p or 0)
    return floor(num * p + .5) / p
end

-- Check if num is in interval (exclusive or inclusive)
function Self.NumBetween(num, a, b) return num > a and num < b end
function Self.NumIn(num, a, b) return num >= a and num <= b end

function Self.NumToHex(num, minLength)
    return ("%." .. (minLength or 1) .. "x"):format(num)
end

-------------------------------------------------------
--                      Boolean                      --
-------------------------------------------------------

function Self.Bool(v)
    return not not v
end

-- True if an uneven # of inputs are true
function Self.BoolXOR(...)
    local n = 0
    for _,v in Self.Each(...) do if v then n = n + 1 end end
    return n % 2 == 1
end

-------------------------------------------------------
--                      Function                     --
-------------------------------------------------------

function Self.Fn(fn, obj) return type(fn) == "string" and (obj and obj[fn] or _G[fn]) or fn end
function Self.FnId(...) return ... end
function Self.FnTrue() return true end
function Self.FnFalse() return false end
function Self.FnZero() return 0 end
function Self.FnNoop() end

function Self.FnCall(fn, v, i, val, index, ...)
    if val and index then return fn(v, i, ...)
    elseif val then       return fn(v, ...)
    elseif index then     return fn(i, ...)
    else                  return fn(...)
    end
end

-- Some math
function Self.FnInc(i) return i+1 end
function Self.FnDec(i) return i-1 end
function Self.FnAdd(a, b) return a+b end
function Self.FnSub(a, b) return a-b end
function Self.FnMul(a, b) return a*b end
function Self.FnDiv(a, b) return a/b end

-- MODIFY

-- Throttle a function, so it is executed at most every n seconds
function Self.FnThrottle(fn, n, leading)
    local Fn, timer, called
    Fn = function (...)
        if not timer then
            if leading then fn(...) end
            timer = Addon:ScheduleTimer(function (...)
                timer = nil
                if not leading then fn(...) end
                if called then
                    called = nil
                    Fn(...)
                end
            end, n, ...)
        else
            called = true
        end
    end
    return Fn
end

-- Debounce a function, so it is executed only n seconds after the last call
function Self.FnDebounce(fn, n, leading)
    local timer, called
    return function (...)
        if not timer then
            if leading then fn(...) end
            timer = Addon:ScheduleTimer(function (...)
                timer = nil
                if not leading or called then
                    called = nil
                    fn(...)
                end
            end, n, ...)
        else
            called = true
            Addon:ExtendTimerTo(timer, n)
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

-- Get string representation values for dumping
function Self.ToString(val, depth)
    depth = depth or 3
    local t = type(val)

    if t == "nil" then
        return "nil"
    elseif t == "table" then
        local fn = val.ToString or val.toString or val.tostring
        if depth == 0 then
            return "{...}"
        elseif type(fn) == "function" and fn ~= Self.ToString then
            return fn(val, depth)
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
    local pre = t == "table" and "Tbl" or t == "string" and "Str" or t == "number" and "Num" or t == "boolean" and "Bool" or t == "function" and "Fn" or ""

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