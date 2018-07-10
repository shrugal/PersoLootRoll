local Name, Addon = ...
local L = LibStub("AceLocale-3.0"):GetLocale(Name)
local CB = LibStub("CallbackHandler-1.0")
local Comm, GUI, Unit, Util = Addon.Comm, Addon.GUI, Addon.Unit, Addon.Util
local Self = Addon.Masterloot

Self.EVENT_SET = "SET"
Self.EVENT_CLEAR = "CLEAR"
Self.EVENT_SESSION = "SESSION"
Self.EVENT_CHANGE = "CHANGE"
Self.EVENTS = {Self.EVENT_SET, Self.EVENT_CLEAR, Self.EVENT_SESSION}

Self.events = CB:New(Self, "On", "Off")

local changeFn = function (...) Self.events:Fire(Self.EVENT_CHANGE, ...) end
for _,ev in pairs(Self.EVENTS) do
    Self:On(ev, changeFn)
end

Self.masterlooter = nil
Self.session = {}
Self.masterlooting = {}

-------------------------------------------------------
--                    Masterlooter                   --
-------------------------------------------------------

-- Set (or reset) the masterlooter
function Self.SetMasterlooter(unit, session, silent)
    unit = unit and Unit.Name(unit)

    -- Clear old masterlooter
    if Self.masterlooter and Self.masterlooter ~= unit then
        if Self.IsMasterlooter() then
            Self.SendCancellation()
            Self.ClearMasterlooting("player")
        elseif not silent then
            Self.SendCancellation("player")
        end
        Self.masterlooter = nil
        wipe(Self.session)
    end
    
    PersoLootRollML = unit
    Self.masterlooter = unit

    -- Let others know
    if unit then
        Self.SetSession(session)

        local isSelf = UnitIsUnit(Self.masterlooter, "player")
        Addon:Info(isSelf and L["MASTERLOOTER_SELF"] or L["MASTERLOOTER_OTHER"], Comm.GetPlayerLink(unit))

        if isSelf then
            Self.SendOffer(nil, silent)
        elseif not silent then
            Self.SendConfirmation()
        end
    end

    Self.events:Fire(unit and Self.EVENT_SET or Self.EVENT_CLEAR, unit, session, silent)
end

-- Check if the unit (or the player) is our masterlooter
function Self.GetMasterlooter(unit)
    unit = Unit.Name(unit or "player")
    if UnitIsUnit(unit, "player") then
        return Self.masterlooter
    else
        return Self.masterlooting[unit]
    end
end

-- Check if the unit (or the player) is our masterlooter
function Self.IsMasterlooter(unit)
    return Self.masterlooter and UnitIsUnit(Self.masterlooter, unit or "player")
end

-- Set a unit's masterlooting status
function Self.SetMasterlooting(unit, ml)
    unit, ml = unit and Unit.Name(unit), ml and Unit.Name(ml)
    Self.masterlooting[unit] = ml

    if Self.IsMasterlooter() and Self.IsOnCouncil(unit) ~= Self.IsOnCouncil(unit, true) then
        Self.SetSession()
    end
end

-- Remove everyone from the masterlooting list who has the given unit as their masterlooter
function Self.ClearMasterlooting(unit)
    unit = Unit.Name(unit)
    for i,ml in pairs(Self.masterlooting) do
        if ml == unit then Self.masterlooting[i] = nil end
    end
end

-------------------------------------------------------
--                     Permission                    --
-------------------------------------------------------

-- Check if the given unit can become our masterlooter
function Self.UnitAllow(unit)
    unit = Unit.Name(unit)
    local config = Addon.db.profile.masterloot

    -- Always deny
    if not unit or not Unit.InGroup(unit) then
        return false
    end

    -- Always allow
    if UnitIsUnit(unit, "player") or config.allowAll then
        return true
    end

    -- Check whitelist
    for i,v in pairs(Addon.db.factionrealm.masterloot.whitelist) do
        if UnitIsUnit(unit, i) then
            return true
        end
    end
    
    local guild = Unit.GuildName(unit)

    -- Check everything else
    if config.allow.friend and Unit.IsFriend(unit) then
        return true
    elseif config.allow.guild and Unit.IsGuildMember(unit) then
        return true
    elseif config.allow.guildgroup and guild and Util.IsGuildGroup(guild) then
        return true
    elseif config.allow.raidleader or config.allow.raidassistant then
        for i=1,GetNumGroupMembers() do
            local name, rank = GetRaidRosterInfo(i)
            if name == unit then
                return config.allow.raidleader and rank == 2 or config.allow.raidassistant and rank == 1
            end
        end
    end

    return false
end

-- Check if we should auto-accept masterlooter requests from this unit
function Self.UnitAccept(unit)
    local config = Addon.db.profile.masterloot.accept

    if config.friend and Unit.IsFriend(unit) then
        return true
    elseif Unit.IsGuildMember(unit) then
        local rank = select(3, GetGuildInfo(unit))
        if config.guildmaster and rank == 1 or config.guildofficer and rank == 2 then
            return true
        end
    end

    return false
end

-------------------------------------------------------
--                       Session                     --
-------------------------------------------------------

-- Restore a session
function Self.Restore()
    if PersoLootRollML then
        Self.SetMasterlooter(PersoLootRollML, {}, true)
    end
    Self.SendRequest(PersoLootRollML)
end

-- Set the masterloot session
function Self.SetSession(session, silent)
    if Self.IsMasterlooter() then
        local config = Addon.db.profile.masterlooter

        -- Council
        local council = {}
        for i=1,GetNumGroupMembers() do
            local unit, rank = GetRaidRosterInfo(i)
            if unit and not UnitIsUnit(unit, "player") and Self.IsOnCouncil(unit, true, rank) then
                council[Unit.FullName(unit)] = true
            end
        end

        Self.session = {
            bidPublic = config.bidPublic,
            timeoutBase = config.timeoutBase or Roll.TIMEOUT,
            timeoutPerItem = config.timeoutPerItem or Roll.TIMEOUT_PER_ITEM,
            council = Util.TblCount(council) > 0 and council or nil,
            votePublic = config.votePublic,
            answers1 = config.answers1,
            answers2 = config.answers2
        }

        if not silent then
            Self.SendOffer(nil, true)
        end
    elseif session then
        Self.session = session
    else
        wipe(Self.session)
    end

    Self.events:Fire(Self.EVENT_SESSION, Self.session, silent)

    return Self.session
end

-- Refresh the masterloot session
function Self.RefreshSession()
    if Self.IsMasterlooter() then Self.SetSession() end
end

-- Check if the unit is on the loot council
function Self.IsOnCouncil(unit, refresh, groupRank)
    unit = Unit(unit or "player")
    local fullName = Unit.FullName(unit)

    if not refresh then
        return Self.session.council and Self.session.council[fullName] or false
    else
        -- Check if unit is part of our masterlooting group
        if not (Self.masterlooting[unit] == Self.masterlooter and Unit.InGroup(unit)) then
            return false
        -- Check whitelist
        elseif Addon.db.factionrealm.masterlooter.councilWhitelist[unit] or Addon.db.factionrealm.masterlooter.councilWhitelist[fullName] then
            return true
        end

        local config = Addon.db.profile.masterlooter

        -- Check guild rank
        if config.council.guildleader or config.council.guildofficer or Addon.db.char.masterloot.guildRank > 0 then
            local guildRank = Unit.GuildRank(unit)
            if config.council.guildleader and guildRank == 1 or config.council.guildofficer and guildRank == 2 then
                return true
            elseif guildRank == Addon.db.char.masterloot.guildRank then
                return true
            end
        end

        -- Check group rank
        if config.council.raidleader or config.council.raidassistant then
            if not groupRank then
                for i=1,GetNumGroupMembers() do
                    local unitGroup, rank = GetRaidRosterInfo(i)
                    if unitGroup == unit then groupRank = rank break end
                end
            end
            if config.council.raidleader and groupRank == 2 or config.council.raidassistant and groupRank == 1 then
                return true
            end
        end
    end
end

-------------------------------------------------------
--                         Comm                      --
-------------------------------------------------------

-- Ask someone to be your masterlooter
function Self.SendRequest(target)
    Comm.Send(Comm.EVENT_MASTERLOOT_ASK, nil, target)
end

-- Send masterlooter offer to unit
function Self.SendOffer(target, silent)
    if Self.IsMasterlooter() then
        Comm.SendData(Comm.EVENT_MASTERLOOT_OFFER, {session = Self.session, silent = silent}, target)
    end
end

-- Confirm unit as your masterlooter
function Self.SendConfirmation(target)
    Comm.Send(Comm.EVENT_MASTERLOOT_ACK, Unit.FullName(Self.masterlooter), target)
end

-- Stop being a masterlooter (unit == nil) or clear the unit's masterlooter
function Self.SendCancellation(unit, target)
    Comm.Send(Comm.EVENT_MASTERLOOT_DEC, unit and Unit.FullName(unit) or nil, target)
end