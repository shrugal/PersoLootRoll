local Name, Addon = ...
local Item, Unit, Util = Addon.Item, Addon.Unit, Addon.Util
local Self = Addon.Inspect

-- How long before refreshing cache entries (s)
Self.REFRESH = 1800
-- How long before checking for requeues
Self.QUEUE_DELAY = 60
-- How long between two inspect requests
Self.INSPECT_DELAY = 2
-- How many tries per char
Self.MAX_PER_CHAR = 3
-- We are not interested in those slots
Self.IGNORE = {Item.TYPE_BODY, Item.TYPE_HOLDABLE, Item.TYPE_TABARD, Item.TYPE_THROWN}

Self.cache = {}
Self.queue = {}

Self.lastQueued = 0

-------------------------------------------------------
--                    Read cache                     --
-------------------------------------------------------

-- Get cache entry for given unit and location
function Self.Get(unit, location)
    return Self.cache[unit] and Self.cache[unit][location] or 0
end

-- Check if an entry exists and isn't out-of-date
function Self.IsValid(unit)
    return Self.cache[unit] and Self.cache[unit].time + Self.REFRESH > GetTime()
end

-------------------------------------------------------
--                   Update cache                    --
-------------------------------------------------------

-- Update the cache entry for the given player
function Self.Update(unit)
    unit = Unit.Name(unit)

    local info = Self.cache[unit] or {}

    -- Remember when we did this
    info.time = GetTime()

    -- Determine the level for all basic inventory locations
    for equipLoc,slots in pairs(Item.SLOTS) do
        if not Util.TblFind(Self.IGNORE, equipLoc) then
            local slotMin = false
            for i,slot in pairs(slots) do
                local link = GetInventoryItemLink(unit, slot)
                if link then
                    slotMin = min(slotMin or 1000, Item.GetInfo(link, "quality") ~= LE_ITEM_QUALITY_LEGENDARY and Item.GetInfo(link, "level") or 0)
                else
                    slotMin = false break
                end
            end

            -- Only set it if we got links for all slots
            if slotMin then
                info[equipLoc] = slotMin and max(0, info[equipLoc] or 0, slotMin)
            elseif not info[equipLoc] then
                info[equipLoc] = false
            end
        end
    end

    -- Determine the min level of all unique relic types for the currently equipped artifact weapon
    local weapon = Item.GetEquippedArtifact(unit)
    if weapon then
        local relics = weapon:GetUniqueRelicSlots()
        if relics then
            relics = Util.TblGroupKeys(relics)
            for relicType,slots in pairs(relics) do
                local slotMin = false
                for i,slot in pairs(slots) do
                    local link = weapon:GetGem(slot)
                    if link then
                        slotMin = min(slotMin or 1000, Item.GetInfo(link, "level") or 0)
                    else
                        slotMin = false break
                    end
                end

                -- Only set it if we got links for all slots
                if slotMin then
                    info[relicType] = slotMin and max(0, info[relicType] or 0, slotMin)
                elseif not info[relicType] then
                    info[relicType] = false
                end
            end
        end
    end

    -- Check if the inspect was successfull
    local n = Util.TblCount(info)
    local failed = n == 0 or Util.TblCountOnly(info, false) >= n/2
    local inspectsLeft = Self.queue[unit] or Self.MAX_PER_CHAR

    -- Update cache and queue entries
    Self.cache[unit] = info
    Self.queue[unit] = failed and inspectsLeft > 1 and inspectsLeft - 1 or nil
end

-- Clear everything and stop tracking for one or all players
function Self.Clear(unit)
    if unit then
        Self.cache[unit] = nil
        Self.queue[unit] = nil
    else
        Self.Stop()
        Self.lastQueued = 0
        wipe(Self.cache)
        wipe(Self.queue)
    end
end

-- Queue a unit or the entire group for inspection
function Self.Queue(unit)
    unit = Unit.Name(unit)
    if not Addon:IsTracking() or unit and UnitIsUnit(unit, "player") then
        return
    end

    if unit then
        Self.queue[unit] = Self.queue[unit] or Self.MAX_PER_CHAR
    else
        -- Queue all group members with missing or out-of-date cache entries
        local unitFound = false
        Util.SearchGroup(function (i, unit)
            unitFound = unitFound or unit and not UnitIsUnit(unit, "player")
            if unit and not UnitIsUnit(unit, "player") and not Self.queue[unit] and not Self.IsValid(unit) then
                Self.queue[unit] = Self.MAX_PER_CHAR
            end
        end)
        
        if unitFound then
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
    local units = Util.TblCopyFilter(Self.queue, filterFn, true)
    local unit = next(units) and Util(units).Only(Util.TblMax(units), true).RandomKey()()
    
    if unit then
        Self.target = unit
        NotifyInspect(unit)
    end

    local delay = max(Self.INSPECT_DELAY, Util.TblCount(Self.queue) == 0 and Self.QUEUE_DELAY - (GetTime() - Self.lastQueued) or 0)
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
--                      Events                       --
-------------------------------------------------------

-- INSPECT_READY
function Self.OnInspectReady(unit)
    -- Inspect the unit
    if unit == Self.target then
        if Self.queue[unit] and Unit.InGroup(unit, true) then
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