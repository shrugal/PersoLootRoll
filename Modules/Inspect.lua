---@type string
local Name = ...
---@type Addon
local Addon = select(2, ...)
local Comm, Item, Unit, Util = Addon.Comm, Addon.Item, Addon.Unit, Addon.Util
---@class Inspect : Module
local Self = Addon.Inspect

-- How long before refreshing cache entries (s)
Self.REFRESH = 1800
-- How long before checking for requeues
Self.QUEUE_DELAY = 60
-- How long between two inspect requests
Self.INSPECT_DELAY = 2
-- How many tries per char
Self.MAX_PER_CHAR = 10
-- We are not interested in those slots
Self.IGNORE = {Item.TYPE_BODY, Item.TYPE_HOLDABLE, Item.TYPE_TABARD, Item.TYPE_RANGEDRIGHT, Item.TYPE_THROWN}

Self.cache = {}
Self.queue = {}

Self.lastQueued = 0

-------------------------------------------------------
--                    Read cache                     --
-------------------------------------------------------

-- Get ivl for given unit and location
---@param unit string
---@param location string
---@return integer
function Self.GetLevel(unit, location)
    return Self.cache[unit] and Self.cache[unit].levels[Item.GetCacheLocation(location)] or 0
end

-- Get link(s) for given unit and slot
---@param unit string
---@param slot string
---@return string?
function Self.GetLink(unit, slot)
    return Self.cache[unit] and Self.cache[unit].links[slot] or nil
end

-- Check if an entry exists and isn't out-of-date
---@param unit string
function Self.IsValid(unit)
    return Self.cache[unit] and Self.cache[unit].time + Self.REFRESH > GetTime()
end

-------------------------------------------------------
--                   Update cache                    --
-------------------------------------------------------

-- Update the cache entry for the given player
function Self.Update(unit)
    unit = Unit.Name(unit)

    local info = Self.cache[unit] or Util.Tbl.Hash("levels", Util.Tbl.New(), "links", Util.Tbl.New())
    local isValid = Self.IsValid(unit)

    -- Remember when we did this
    info.time = GetTime()

    -- Equipped items
    for equipLoc,slots in pairs(Item.SLOTS) do
        if not Util.In(equipLoc, Self.IGNORE) then
            local slotMin
            for i,slot in pairs(slots) do
                if GetInventoryItemTexture(unit, slot) then
                    local link = GetInventoryItemLink(unit, slot) or isValid and info.links[slot]
                    if link then
                        info.links[slot] = link
                        if slotMin ~= false then
                            local lvl = Item.GetInfo(link, "quality") == Enum.ItemQuality.Legendary and 0 or Item.GetInfo(link, "maxLevel", unit)
                            slotMin = lvl and min(slotMin or lvl, lvl) or false
                        end
                    else
                        info.links[slot] = false
                        slotMin = false
                    end
                else
                    info.links[slot] = nil
                    slotMin = slotMin ~= false and 0 or false
                end
            end

            -- Only set it if we got links for all slots
            equipLoc = Item.GetCacheLocation(equipLoc)
            if slotMin then
                info.levels[equipLoc] = max(0, info.levels[equipLoc] or 0, slotMin)
            elseif not (isValid and info.levels[equipLoc]) then
                info.levels[equipLoc] = false
            end
        end
    end

    -- Equipped relics
    local weapon = Item.GetEquippedArtifact(unit)
    local relics = weapon and weapon:GetRelicSlots()
    local uniqueTypes = weapon and weapon:GetRelicSlots(true)

    if relics and uniqueTypes then
        relics, uniqueTypes = Util.Tbl.GroupKeys(relics), Util.Tbl.Flip(uniqueTypes)

        for relicType,slots in pairs(relics) do
            local slotMin
            local links = Util.Tbl.New()
            local isUnique = uniqueTypes[relicType]

            for i,slot in pairs(slots) do
                local link = weapon:GetGem(slot)
                if link then
                    tinsert(links, link)
                    if isUnique and slotMin ~= false then
                        local lvl = Item.GetInfo(link, "realLevel", unit)
                        slotMin = lvl and min(slotMin or lvl, lvl) or false
                    end
                elseif isUnique then
                    slotMin = false
                end
            end

            -- Only set it if we got links for all slots
            if slotMin then
                info.levels[relicType] = max(0, info.levels[relicType] or 0, slotMin)
            elseif isUnique and not (isValid and info.levels[relicType]) then
                info.levels[relicType] = false
            elseif not info.levels[relicType] then
                info.levels[relicType] = nil
            end

            -- Handle links
            if not info.links[relicType] then
                info.links[relicType] = links
            else
                if slotMin or not isValid or #info.links[relicType] < #links then
                    wipe(info.links[relicType])
                    Util.Tbl.Merge(info.links[relicType], links)
                end
                Util.Tbl.Release(links)
            end
        end
    end

    Util.Tbl.Release(1, weapon, relics, uniqueTypes)

    -- Check if the inspect was successfull
    local failed = Util.Tbl.CountOnly(info.levels, false) + Util.Tbl.CountOnly(info.links, false) > 0
    local inspectsLeft = Self.queue[unit] or Self.MAX_PER_CHAR

    -- Update cache and queue entries
    Self.cache[unit] = info
    Self.queue[unit] = failed and inspectsLeft > 1 and inspectsLeft - 1 or nil
end

-- Clear everything and stop tracking for one or all players
---@param unit string?
function Self.Clear(unit)
    if unit then
        Util.Tbl.Release(true, Self.cache[unit])
        Self.cache[unit] = nil
        Self.queue[unit] = nil
    else
        Self.lastQueued = 0
        Util.Tbl.Release(true, unpack(Self.cache))
        wipe(Self.cache)
        wipe(Self.queue)
    end
end

-- Queue a unit or the entire group for inspection
---@param unit string?
function Self.Queue(unit)
    unit = Unit.Name(unit)
    if not Addon:IsTracking() then return end

    if unit then
        Self.queue[unit] = Self.queue[unit] or Self.MAX_PER_CHAR
    elseif IsInGroup() then
        -- Queue all group members with missing or out-of-date cache entries
        local allFound = true
        for i=1,GetNumGroupMembers() do
            unit = GetRaidRosterInfo(i)
            if not unit then
                allFound = false
            elseif not (Self.IsValid(unit) or Self.queue[unit]) then
                Self.queue[unit] = Self.MAX_PER_CHAR
            end
        end

        if allFound then
            Self.lastQueued = GetTime()
        end
    end
end

-- Start the inspection loop
local filterFn = function (i, unit) return CanInspect(unit) end
function Self.Loop()
    -- Check if the loop is already running
    if Addon:TimerIsRunning(Self.timer) then return end

    -- Queue new units to inspect
    if Self.lastQueued + Self.QUEUE_DELAY <= GetTime() then
        Self.Queue()
    end

    -- Get the next unit to inspect (with max inspects left -> wide search, random -> so we don't get stuck on one unit)
    local units = Util.Tbl.CopyFilter(Self.queue, filterFn, true, nil, true)
    local unit = next(units) and Util(units):Only(Util.Tbl.Max(units), true):RandomKey()()

    if unit then
        Self.target = unit
        NotifyInspect(unit)
    end

    local delay = max(Self.INSPECT_DELAY, Util.Tbl.Count(Self.queue) == 0 and Self.QUEUE_DELAY - (GetTime() - Self.lastQueued) or 0)
    Self.timer = Addon:ScheduleTimer(Self.Loop, delay)
 end

-- Check if we should start the loop, and then start it
function Self.Start()
    local timerIsRunning = Addon:TimerIsRunning(Self.timer)
    local delayHasPassed = Self.timer and GetTime() - (Self.timer.ends - Self.timer.delay) > Self.INSPECT_DELAY

    if Addon:IsTracking() and (not timerIsRunning or delayHasPassed) then
        Self.Stop()
        Self.Loop()
    end
end

-- Stop the inspection loop
function Self.Stop()
    if Self.timer then
        Addon:CancelTimer(Self.timer)
        Self.timer = nil
    end
end

-------------------------------------------------------
--                   Events/Hooks                    --
-------------------------------------------------------

function Self:OnEnable()
    -- Register events
    Self:RegisterEvent("ENCOUNTER_START", Self.Stop)
    Self:RegisterEvent("ENCOUNTER_END", Self.Start)
    Self:RegisterEvent("PARTY_MEMBER_ENABLE")
    Self:RegisterEvent("INSPECT_READY")
    Self:RegisterEvent("CHAT_MSG_SYSTEM")
    Self:RegisterMessage(Addon.EVENT_ACTIVE_CHANGE, "ACTIVE_CHANGE")
    Self:RegisterMessage(Addon.EVENT_TRACKING_CHANGE, "TRACKING_CHANGE")

    -- IsInGroup doesn't work correctly right after logging in, so check again a few seconds later
    if not Self.timer then
        Self:ScheduleTimer(Self.Start, 10)
    end
end

---@param unit string
function Self:PARTY_MEMBER_ENABLE(_, unit)
    if Addon:IsTracking() then Self.Queue(unit) end
end

---@param guid string
function Self:INSPECT_READY(_, guid)
    local _, _, _, _, _, name, realm = GetPlayerInfoByGUID(guid)
    local unit = realm and realm ~= "" and name .. "-" .. realm or name

    -- Inspect the unit
    if unit == Self.target then
        if Self.queue[unit] and Unit.InGroup(unit) then
            Self.Update(unit)
        end

        ClearInspectPlayer()
        Self.target = nil
    end

    -- Extend a running loop timer
    if Addon:TimerIsRunning(Self.timer) then
        Self.timer = Addon:ExtendTimerTo(Self.timer, Self.INSPECT_DELAY)
    end
end

---@param msg string
function Self:CHAT_MSG_SYSTEM(_, msg)
    if not Addon:IsTracking() then return end

    -- Check if a player joined the group/raid
    for _,pattern in pairs(Comm.PATTERNS_JOINED) do
        local unit = msg:match(pattern)
        if unit then
            -- Queue inspection
            Self.Queue(unit)
            return
        end
    end

    -- Check if a player left the group/raid
    for _,pattern in pairs(Comm.PATTERNS_LEFT) do
        local unit = msg:match(pattern)
        if unit then
            -- Clear inspect cache
            Self.Clear(unit)
        end
    end
end

---@param active boolean
function Self:ACTIVE_CHANGE(active)
    if not active then
        Self.Clear()
    end
end

---@param tracking boolean
function Self:TRACKING_CHANGE(tracking)
    if tracking then
        Self.Queue()
        Self.Start()
    else
        Self.Stop()
    end
end