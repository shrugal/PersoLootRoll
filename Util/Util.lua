---@type Addon
local Addon = select(2, ...)
local Unit = Addon.Unit
---@class Util
local Self = Addon.Util

---@type Registrar
Self.Registrar = {}

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

-- Check if the current group is a guild group
---@return string|boolean
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
---@param commId integer
---@return integer|boolean
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
---@return table<integer,string>
function Self.GetGuildRanks()
    local t, i, name = Self.Tbl(), 1, GuildControlGetRankName(1)
    while not Self.StrIsEmpty(name) do
        t[i] = name
        i, name = i + 1, GuildControlGetRankName(i + 1)
    end
    return t
end

-- Get a list of club ranks
---@return table<integer,string>
function Self.GetClubRanks(clubId)
    if not clubId then return end

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
    local iExp = Self.GetInstanceExp()
    return iExp and GetLootMethod() == "personalloot" and iExp < Unit.Expansion("player") - 1
end

-- Check if the current session is a transmog run
function Self.IsTransmogRun()
    local iExp = Self.GetInstanceExp()
    return iExp and GetLootMethod() == "personalloot" and iExp < Unit.Expansion("player")
end

-- Check if currently in a timewalking dungeon
function Self.IsTimewalking()
    return Self.In(select(3, GetInstanceInfo()), 24, 33)
end

-- Get the usual # of dropped items in the current instance and group setting
function Self.GetNumDroppedItems()
    local difficulty, _, maxPlayers = select(3, GetInstanceInfo())

    if difficulty == DIFFICULTY_DUNGEON_CHALLENGE then
        -- In M+ we get 2 items at the end of the dungeon, +1 if in time, +0.4 per keystone level above 15
        local _, level, _, onTime = C_ChallengeMode.GetCompletionInfo();
        return 2 + (onTime and 1 or 0) + (level > 15 and math.ceil(0.4 * (level - 15)) or 0)
    else
        -- Normally we get about 1 item per 5 players in the group
        local players = GetNumGroupMembers()
        if difficulty == DIFFICULTY_PRIMARYRAID_MYTHIC then
            players = 20
        elseif Self.IsLegacyLoot() then
            players = Self.In(difficulty, DIFFICULTY_RAID_LFR, DIFFICULTY_PRIMARYRAID_LFR, DIFFICULTY_PRIMARYRAID_NORMAL, DIFFICULTY_PRIMARYRAID_HEROIC) and max(players, 20) or maxPlayers
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
---@param linkOrBag string | integer
function Self.ScanTooltip(fn, linkOrBag, slot, ...)
    local tooltip = Self.GetHiddenTooltip()
    tooltip:ClearLines()

    if not slot then
        tooltip:SetHyperlink(linkOrBag)
    else
        tooltip:SetBagItem(linkOrBag, slot)
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
---@return integer
---@return integer
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
---@generic T
---@param a T
---@param b T
function Self.Compare(a, b)
    return a == b and 0
    or a == nil and 1
    or b == nil and -1
    or a > b and 1 or -1
end

-- Create an iterator
---@param from number
---@param to number
---@param step number
---@return function(steps: number, reset: boolean): number
function Self.Iter(from, to, step)
    local i = from or 0
    return function (steps, reset)
        i = (reset and (from or 0) or i) + (step or 1) * (steps or 1)
        return (not to or i <= to) and i or nil
    end
end

-- Return val if it's not nil, default otherwise
---@generic T
---@param val T
---@param default T
---@return T
function Self.Default(val, default)
    if val ~= nil then return val else return default end
end

-- Return a when cond is true, b otherwise
---@generic T
---@param cond any
---@param a T
---@param b T
---@return T
function Self.Check(cond, a, b)
    if cond then return a else return b end
end

-- Check if the value is truthy (true, ~=0, ~="", ~=[])
---@param val any
function Self.IsSet(val)
    local t = type(val)
    return val
        and val ~= 0
        and not (t == "string" and val:trim() == "")
        and not (t == "table" and not next(t))
        and true or false
end

-- Check if the value is falsy (false, 0, "", [])
function Self.IsEmpty(val)
    return not Self.IsSet(val)
end

-- Iterate tables or parameter lists
---@generic T, I
---@param t T[]
---@param i I
---@return I, T
local Fn = function (t, i)
    i = (i or 0) + 1
    if i > #t then
        Self.TblReleaseTmp(t)
    else
        local v = t[i]
        return i, Self.Check(v == Self.TBL_NIL, nil, v)
    end
end
---@generic T, I
---@return function(t: T[], i: I): I, T
---@return T
---@return I
function Self.Each(...)
    if ... and type(...) == "table" then
        return next, ...
    elseif select("#", ...) == 0 then
        return Self.FnNoop
    else
        return Fn, Self.TblTmp(...)
    end
end
---@generic T, I
---@return function(t: T[], i: I): I, T
---@return T
---@return I
function Self.IEach(...)
    if ... and type(...) == "table" then
        return Fn, ...
    else
        return Self.Each(...)
    end
end

-- Shortcut for val == x or val == y or ...
---@param val any
---@return boolean
function Self.In(val, ...)
    for i,v in Self.Each(...) do
        if v == val then return true end
    end
    return false
end

-- Shortcut for val == a and b or val == c and d or ...
---@param val any
---@return any
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

---@param val any
function Self.Push(val)
    tinsert(Self.stack, val == nil and Self.TBL_NIL or val)
    return Self
end

---@return any
function Self.Pop()
    local val = tremove(Self.stack)
    return Self.Check(val == Self.TBL_NIL, nil, val)
end

-------------------------------------------------------
--                       Table                       --
-------------------------------------------------------

-- Create a table that tracks the highest numerical index and offers count+newIndex fields and Add function
---@param t table
---@return table
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
---@vararg table|boolean
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

-- Unpack and release a table
local Fn = function (t, ...) Self.TblRelease(t) return ... end
---@param t table
function Self.TblUnpack(t)
    return Fn(t, unpack(t))
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

function Self.TblHashTmp(...)
    return setmetatable(Self.TblHash(...), Self.TBL_EMPTY)
end

---@param t table
function Self.TblIsTmp(t)
    return getmetatable(t) == Self.TBL_EMPTY
end

---@vararg table
function Self.TblReleaseTmp(...)
    for i=1, select("#", ...) do
        local t = select(i, ...)
        if type(t) == "table" and Self.TblIsTmp(t) then Self.TblRelease(t) end
    end
end

-- GET/SET

-- Get a value from a table
---@return any
function Self.TblGet(t, ...)
    local n, path = select("#", ...), ...

    if n == 1 and type(path) == "string" and path:find("%.") then
        path = Self.TblTmp(("."):split((...)))
    elseif type(path) ~= "table" then
        path = Self.TblTmp(...)
    end

    for i,k in Self.IEach(path) do
        if k == nil then
            break
        elseif t ~= nil then
            t = t[k]
        end
    end

    return t
end

-- Set a value on a table
---@vararg any
---@return table
---@return any
function Self.TblSet(t, ...)
    local n, path = select("#", ...), ...
    local val = select(n, ...)

    if n == 2 and type(path) == "string" and path:find("%.") then
        path = Self.TblTmp(("."):split((...)))
    elseif type(path) ~= "table" then
        path = Self.TblTmp(...)
        tremove(path)
    end

    local u, j = t
    for i,k in Self.IEach(path) do
        if k == nil then
            break
        elseif j then
            if u[j] == nil then u[j] = Self.Tbl() end
            u = u[j]
        end
        j = k
    end

    u[j] = val

    return t, val
end

-- Get a random key from the table
function Self.TblRandomKey(t)
    if not next(t) then
        return
    else
        local n = random(Self.TblCount(t))
        for i,v in pairs(t) do
            n = n - 1
            if n == 0 then return i end
        end
    end
end

-- Get a random entry from the table
---@param t table
---@return any
function Self.TblRandom(t)
    local key = Self.TblRandomKey(t)
    return key and t[key]
end

-- Get table keys
---@param t table
---@return table
function Self.TblKeys(t)
    local u = Self.Tbl()
    for i,v in pairs(t) do tinsert(u, i) end
    return u
end

-- Get table values as continuously indexed list
---@param t table
---@return table
function Self.TblValues(t)
    local u = Self.Tbl()
    for i,v in pairs(t) do tinsert(u, v) end
    return u
end

-- Turn a table into a continuously indexed list (in-place)
---@param t table
---@return table
function Self.TblList(t)
    local n = Self.TblCount(t)
    for k=1, n do
        if not t[k] then
            local l
            for i,v in pairs(t) do
                if type(i) == "number" then
                    l = min(l or i, i)
                else
                    l = i break
                end
            end
            t[k], t[l] = t[l], nil
        end
    end
    return t
end

-- Check if the table is a continuesly indexed list
function Self.TblIsList(t)
    return #t == Self.TblCount(t)
end

-- SUB

---@param t table
---@param s integer
---@param e integer
function Self.TblSub(t, s, e)
    return {unpack(t, s or 1, e)}
end

function Self.TblHead(t, n)
    return Self.TblSub(t, 1, n or 1)
end

---@param t table
---@param n integer
function Self.TblTail(t, n)
    return Self.TblSub(t, #t - (n or 1))
end

---@param t table
---@param s integer
---@param e integer
---@param u integer
function Self.TblSplice(t, s, e, u)
    return Self.TblMerge(Self.TblHead(t, s), u or {}, Self.TblSub(#t, e))
end

-- ITERATE

-- Good old FoldLeft
---@param t table
---@param u any
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
---@param fn function
---@param index boolean
---@param notVal boolean
function Self.TblCall(t, fn, index, notVal, ...)
    for i,v in pairs(t) do
        Self.FnCall(Self.Fn(fn, v), v, i, index, notVal, ...)
    end
end

-- COUNT, SUM, MULTIPLY, MIN, MAX

---@return integer
function Self.TblCount(t)
    return Self.TblFoldL(t, Self.FnInc, 0)
end

---@param t table
---@return number
function Self.TblSum(t)
    return Self.TblFoldL(t, Self.FnAdd, 0)
end

---@param t table
---@return number
function Self.TblMul(t)
    return Self.TblFoldL(t, Self.FnMul, 1)
end

---@param t table
---@param start number
---@return number
function Self.TblMin(t, start)
    return Self.TblFoldL(t, math.min, start or select(2, next(t)))
end

---@param t table
---@param start number
---@return number
function Self.TblMax(t, start)
    return Self.TblFoldL(t, math.max, start or select(2, next(t)))
end

-- Count the # of occurences of given value(s)
---@param t table
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
---@param t table
function Self.TblCountWhere(t, ...)
    local n = 0
    for i,u in pairs(t) do
        if Self.TblMatches(u, ...) then n = n + 1 end
    end
    return n
end

-- Count using a function
---@param index boolean
---@param notVal boolean
function Self.TblCountFn(t, fn, index, notVal, ...)
    local n, fn = 0, Self.Fn(fn)
    for i,v in pairs(t) do
        local val = Self.FnCall(fn, v, i, index, notVal, ...)
        n = n + (tonumber(val) or val and 1 or 0)
    end
    return n
end

-- SEARCH

-- Search for something in a table and return the index
---@param t table
---@param fn function(v: any, i: any): boolean
function Self.TblSearch(t, fn, ...)
    fn = Self.Fn(fn) or Self.FnId
    for i,v in pairs(t) do
        if fn(v, i, ...) then
            return i
        end
    end
end

-- Check if one table is contained within the other
---@param t table
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
---@param deep boolean
function Self.TblEquals(a, b, deep)
    return type(a) == "table" and type(b) == "table" and Self.TblContains(a, b, deep) and Self.TblContains(b, a, deep)
end

-- Check if a table matches the given key-value pairs
---@param t table
function Self.TblMatches(t, ...)
    if type(...) == "table" then
        return Self.TblContains(t, ...)
    else
        for i=1, select("#", ...), 2 do
            local key, val = select(i, ...)
            local v = Self.TblGet(t, key)
            if v == nil or val ~= nil and v ~= val then
                return false
            end
        end

        return true
    end
end

-- Check if a value is a filled table
---@param t table
function Self.TblIsSet(t)
    return type(t) == "table" and next(t) and true or false
end

-- Check if a value is not a table or empty
---@param t table
function Self.TblIsEmpty(t)
    return not Self.TblIsSet(t)
end

-- Find a value in a table
---@param t table
---@param val any
---@return any
---@return any
function Self.TblFind(t, val)
    for i,v in pairs(t) do
        if v == val then return i, v end
    end
end

-- Find a set of key/value pairs in a table
---@return any
---@return any
function Self.TblFindWhere(t, ...)
    for i,v in pairs(t) do
        if Self.TblMatches(v, ...) then return i, v end
    end
end

-- Find the first element matching a fn
---@param index boolean
---@param notVal boolean
---@return any
---@return any
function Self.TblFindFn(t, fn, index, notVal, ...)
    for i,v in pairs(t) do
        if Self.FnCall(Self.Fn(fn, v), v, i, index, notVal, ...) then
            return i, v
        end
    end
end

-- Find the first element (optinally matching a fn)
---@return any
function Self.TblFirst(t, fn, index, notVal, ...)
    if not fn then
        return select(2, next(t))
    else
        return select(2, Self.TblFindFn(t, fn, index, notVal, ...))
    end
end

-- Find the first set of key/value pairs in a table
---@return any
function Self.TblFirstWhere(t, ...)
    return select(2, Self.TblFindWhere(t, ...))
end

-- FILTER

-- Filter by a function
---@param t table
---@param index boolean
---@param notVal boolean
---@param k boolean
function Self.TblFilter(t, fn, index, notVal, k, ...)
    fn = Self.Fn(fn) or Self.FnId

    if not k and Self.TblIsList(t) then
        for i=#t,1,-1 do
            if not Self.FnCall(fn, t[i], i, index, notVal, ...) then
                tremove(t, i)
            end
        end
    else
        for i,v in pairs(t) do
            if not Self.FnCall(fn, v, i, index, notVal, ...) then
                Self.TblRemove(t, i, k)
            end
        end
    end

    return t
end

-- Pick specific keys from a table
function Self.TblSelect(t, ...)
    for i in pairs(t) do
        if not Self.In(i, ...) then t[i] = nil end
    end
    return t
end

-- Omit specific keys from a table
---@param t table
function Self.TblUnselect(t, ...)
    for i,v in Self.Each(...) do t[v] = nil end
    return t
end

-- Filter by a value
---@param k boolean
function Self.TblOnly(t, val, k)
    return Self.TblFilter(t, Self.Equals, nil, nil, k, val)
end

-- Filter by not being a value
local Fn = function (v, val) return v ~= val end
---@param val any
---@param k boolean
function Self.TblExcept(t, val, k)
    return Self.TblFilter(t, Fn, nil, nil, k, val)
end

-- Filter by a set of key/value pairs in a table
---@param t table
---@param k boolean
function Self.TblWhere(t, k, ...)
    return Self.TblFilter(t, Self.TblMatches, nil, nil, k, ...)
end

-- Filter by not having a set of key/value pairs in a table
local Fn = function (...) return not Self.TblMatches(...) end
---@param t table
---@param k boolean
function Self.TblExceptWhere(t, k, ...)
    return Self.TblFilter(t, Fn, nil, nil, k, ...)
end

-- COPY

-- Copy a table and optionally apply a function to every entry
---@param fn function
---@param index boolean
---@param notVal boolean
function Self.TblCopy(t, fn, index, notVal, ...)
    local fn, u = Self.Fn(fn), Self.Tbl()
    for i,v in pairs(t) do
        if fn then
            u[i] = Self.FnCall(fn, v, i, index, notVal, ...)
        else
            u[i] = v
        end
    end
    return u
end

-- Filter by a function
function Self.TblCopyFilter(t, fn, index, notVal, k, ...)
    fn = Self.Fn(fn) or Self.FnId
    local u = Self.Tbl()
    for i,v in pairs(t) do
        if Self.FnCall(fn, v, i, index, notVal, ...) then
            Self.TblInsert(u, k and i, v, k)
        end
    end
    return k and u or Self.TblList(u)
end

-- Pick specific keys from a table
function Self.TblCopySelect(t, ...)
    local u = Self.Tbl()
    for i,v in Self.Each(...) do u[v] = t[v] end
    return u
end

-- Omit specific keys from a table
function Self.TblCopyUnselect(t, ...)
    local u = Self.Tbl()
    for i,v in pairs(t) do
        if not Self.In(i, ...) then
            u[i] = v
        end
    end
    return u
end

-- Filter by a value
---@param t table
---@param k boolean
function Self.TblCopyOnly(t, val, k)
    local u = Self.Tbl()
    for i,v in pairs(t) do
        if v == val then
            Self.TblInsert(u, k and i, v, k)
        end
    end
    return u
end

-- Filter by not being a value
---@param val any
---@param k boolean
function Self.TblCopyExcept(t, val, k)
    local u = Self.Tbl()
    for i,v in pairs(t) do
        if v ~= val then
            Self.TblInsert(u, k and i, v, k)
        end
    end
    return u
end

-- Filter by a set of key/value pairs in a table
---@param t table
---@param k boolean
function Self.TblCopyWhere(t, k, ...)
    local u = Self.Tbl()
    for i,v in pairs(t) do
        if Self.TblFindWhere(u, ...) then
            Self.TblInsert(u, k and i, v, k)
        end
    end
    return u
end

-- Filter by not having a set of key/value pairs in a table
---@param t table
---@param k boolean
function Self.TblCopyExceptWhere(t, k, ...)
    local u = Self.Tbl()
    for i,v in pairs(t) do
        if not Self.TblFindWhere(u, ...) then
            Self.TblInsert(u, k and i, v, k)
        end
    end
    return u
end

-- MAP

-- Change table values by applying a function
---@param index boolean
---@param notVal boolean
function Self.TblMap(t, fn, index, notVal, ...)
    fn = Self.Fn(fn)
    for i,v in pairs(t) do
        t[i] = Self.FnCall(fn, v, i, index, notVal, ...)
    end
    return t
end

-- Change table keys by applying a function
---@param index boolean
---@param notVal boolean
function Self.TblMapKeys(t, fn, index, notVal, ...)
    fn = Self.Fn(fn)
    local u = Self.Tbl()
    for i,v in pairs(t) do
        u[Self.FnCall(fn, i, v, index, notVal, ...)] = v
    end
    return u
end

-- Change table values by extracting a key
---@param t table
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
---@param t table
---@param fn function(v: any, i: any): any
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
---@param t table
function Self.TblGroupBy(t, k)
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
---@param t table
---@param k boolean
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
---@param t table
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
---@param t table
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
---@param t table
function Self.TblIntersects(t, ...)
    for _,v in pairs(t) do
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

---@param i any
---@param v any
---@param k boolean
function Self.TblInsert(t, i, v, k)
    if k or i and not tonumber(i) then
        t[i] = v
    elseif i then
        tinsert(t, i, v)
    else
        tinsert(t, v)
    end
end

function Self.TblRemove(t, i, k)
    if k or i and not tonumber(i) then
        t[i] = nil
    elseif i then
        tremove(t, i)
    else
        tremove(t)
    end
end

---@param t table
function Self.TblPush(t, v)
    tinsert(t, v)
    return t
end

---@param t table
function Self.TblPop(t)
    return tremove(t)
end

---@param t table
function Self.TblDrop(t)
    tremove(t)
    return t
end

---@param t table
function Self.TblShift(t)
    return tremove(t, 1)
end

---@param t table
function Self.TblUnshift(t, v)
    tinsert(t, 1, v)
    return t
end

-- Rotate by l (l>0: left, l<0: right)
---@param t table
---@param l integer
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
    local args = type(...) == "table" and (...) or Self.TblTmp(...)
    return Self.TblSort(t, function (a, b)
        for i=1, #args, 3 do
            local key, default, fn = args[i], args[i+1], args[i+2]
            fn = fn == true and Fn or Self.Fn(fn) or Self.Compare

            local cmp = fn(a and a[key] or default, b and b[key] or default)
            if cmp ~= 0 then return cmp == -1 end
        end
    end), Self.TblReleaseTmp(args)
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
---@param t table
---@param n integer
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

-- Flatten a list of tables by one dimension
local Fn = function (u, v) return Self.TblMerge(u, v) end
---@param t table
---@return table
function Self.TblFlatten(t)
    return Self.TblFoldL(t, Fn, Self.Tbl())
end

-- Wipe multiple tables at once
---@vararg table
function Self.TblWipe(...)
    for i=1,select("#", ...) do wipe((select(i, ...))) end
    return ...
end

-- Join a table of strings
function Self.TblConcat(t, del)
    return Self.StrJoin(del, t)
end

-- Use Blizzard's inspect tool
function Self.TblInspect(t)
    UIParentLoadAddOn("Blizzard_DebugTools")
    DisplayTableInspectorWindow(t)
end

-------------------------------------------------------
--                       String                      --
-------------------------------------------------------

---@return boolean
function Self.StrIsSet(str)
    return type(str) == "string" and str:trim() ~= ""
end

---@param str string
function Self.StrIsEmpty(str)
    return not Self.StrIsSet(str)
end

---@param str string
function Self.StrStartsWith(str, str2)
    return type(str) == "string" and str:sub(1, str2:len()) == str2
end

---@param str string
---@param str2 string
function Self.StrEndsWith(str, str2)
    return type(str) == "string" and str:sub(-str2:len()) == str2
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
    local t = Self.Tbl()
    for v in (str .. del):gmatch("(.-)" .. del:gsub(".", "%%%1")) do
        tinsert(t, v)
    end
    return t
end

-- Join a bunch of strings with given delimiter
---@vararg string
function Self.StrJoin(del, ...)
    local s = ""
    for _,v in Self.Each(...) do
        if not Self.StrIsEmpty(v) then
            s = s .. (s == "" and "" or del or " ") .. v
        end
    end
    return s
end

-- Uppercase only if language supports letter casing
---@param str string
---@param locale string
function Self.StrUcLang(str, locale)
    return Self.In(locale or GetLocale(), "koKR", "zhCN", "zhTW") and str or str:upper()
end

-- Lowercase only if language supports letter casing
---@param str string
---@param locale string
function Self.StrLcLang(str, locale)
    return Self.In(locale or GetLocale(), "koKR", "zhCN", "zhTW") and str or str:lower()
end

-- Uppercase first char
---@param str string
---@param locale string
function Self.StrUcFirst(str, locale)
    return str:sub(1, 1):upper() .. str:sub(2)
end

-- Lowercase first char
---@param str string
---@param locale string
---@return string
function Self.StrLcFirst(str, locale)
    return str:sub(1, 1):lower() .. str:sub(2)
end

-- Check if string is a number
---@param str string
---@param leadingZero boolean
function Self.StrIsNumber(str, leadingZero)
    return tonumber(str) and (leadingZero or not Self.StrStartsWith(str, "0"))
end

-- Get abbreviation of given length
---@param str string
function Self.StrAbbr(str, length)
    return str:len() <= length and str or str:sub(1, length) .. "..."
end

---@param a number
function Self.StrColor(r, g, b, a)
    return ("%.2x%.2x%.2x%.2x"):format((a or 1) * 255, (r or 1) * 255, (g or 1) * 255, (b or 1) * 255)
end

---@param str string
---@param from integer
---@param len integer
---@param sub string
function Self.StrReplace(str, from, len, sub)
    from, len, sub = from or 1, len or str:len(), sub or ""
    local to = from < 0 and str:len() + from + len + 1 or from + len
    return str:sub(1, from - 1) .. sub .. str:sub(to)
end

---@param str string
---@param del string
function Self.StrToCamelCase(str, del)
    local s = ""
    for v in str:gmatch("[^" .. (del or "%p%s") .. "]+") do
        s = s .. Self.StrUcFirst(v:lower())
    end
    return Self.StrLcFirst(s)
end

---@param str string
---@param del string
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

-- Check if num is in interval (exclusive)
---@param num number
---@param a number
---@param b number
function Self.NumBetween(num, a, b)
    return num > a and num < b
end

-- Check if num is in interval (inclusive)
function Self.NumIn(num, a, b)
    return num >= a and num <= b
end

---@param num number
---@param minLength number
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

---@param index boolean
---@param notVal boolean
---@return any
function Self.FnCall(fn, v, i, index, notVal, ...)
    if index and notVal then
        return fn(i, ...)
    elseif index then
        return fn(v, i, ...)
    elseif notVal then
        return fn(...)
    else
        return fn(v, ...)
    end
end

-- Get a value directly or as return value of a function
---@param fn function
function Self.FnVal(fn, ...)
    return (type(fn) == "function" and Self.Push(fn(...)) or Self.Push(fn)).Pop()
end

-- Some math
---@param i number
function Self.FnInc(i)
    return i+1
end

---@param i number
function Self.FnDec(i)
    return i-1
end

---@param a number
---@param b number
function Self.FnAdd(a, b)
    return a+b
end

---@param a number
---@param b number
function Self.FnSub(a, b)
    return a-b
end

---@param a number
---@param b number
function Self.FnMul(a, b)
    return a*b
end

---@param a number
---@param b number
function Self.FnDiv(a, b)
    return a/b
end

-- MODIFY

-- Throttle a function, so it is executed at most every n seconds
---@param fn function
---@param n number
---@param leading boolean
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
            timer = Addon:ExtendTimerTo(timer, n, ...)
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

---@param func function
function Self.Safecall(func, ...)
	return Dispatchers[select("#", ...)](func, ...)
end

-- Get string representation values for dumping
---@param val any
---@param depth integer
---@return string
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