local Name, Addon = ...
local L = LibStub("AceLocale-3.0"):GetLocale(Name)
local Comm, GUI, Unit, Util = Addon.Comm, Addon.GUI, Addon.Unit, Addon.Util
local Self = Addon.Masterloot

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
    
    PLR_MASTERLOOTER = unit
    Self.masterlooter = unit

    -- Let others know
    if unit then
        Self.SetSession(session)

        local isSelf = UnitIsUnit(Self.masterlooter, "player")
        Addon:Info(isSelf and L["MASTERLOOTER_SELF"] or L["MASTERLOOTER_OTHER"]:format(Comm.GetPlayerLink(unit)))

        if isSelf then
            Self.SendOffer(nil, silent)
        elseif not silent then
            Self.SendConfirmation()
        end
    end

    GUI.Rolls.Update()
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
    for i,v in pairs(config.whitelist) do
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
        return Util.SearchGroup(function (i, name, rank)
            if name == unit then
                return config.allow.raidleader and rank == 2 or config.allow.raidassistant and rank == 1
            end
        end) 
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
    if PLR_MASTERLOOTER then
        Self.SetMasterlooter(PLR_MASTERLOOTER, {}, true)
    end
    Self.SendRequest(PLR_MASTERLOOTER)
end

-- Set the masterloot session
function Self.SetSession(session, silent)
    if Self.IsMasterlooter() then
        local config = Addon.db.profile.masterloot

        -- Council
        local council = {}
        Util.SearchGroup(function (i, unit, rank)
            if unit and not UnitIsUnit(unit, "player") and Self.IsOnCouncil(unit, true, rank) then
                council[Unit.FullName(unit)] = true
            end
        end)

        Self.session = {
            bidPublic = config.bidPublic,
            timeoutBase = Addon.db.profile.masterloot.timeoutBase or Roll.TIMEOUT,
            timeoutPerItem = Addon.db.profile.masterloot.timeoutPerItem or Roll.TIMEOUT_PER_ITEM,
            council = Util.TblCount(council) > 0 and council or nil,
            votePublic = config.votePublic
        }

        if not silent then
            Self.SendOffer(nil, true)
        end
    elseif session then
        Self.session = session
    else
        wipe(Self.session)
    end

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
        if not (Self.masterlooting[unit] == Self.masterlooter and Unit.InGroup(unit)) then
            return false
        end

        local config, guildRank = Addon.db.profile.masterloot, Unit.GuildRank(unit)
        groupRank = groupRank or Util.SearchGroup(function (i, unitGroup, rank) if unitGroup == unit then return rank end end)

        if config.councilWhitelist[unit] or config.councilWhitelist[fullName] then
            return true
        elseif config.council.raidleader and groupRank == 2 or config.council.raidassistant and groupRank == 1 then
            return true
        elseif config.council.guildleader and guildRank == 0 or config.council.guildofficer and guildRank == 1 then
            return true
        else
            return false
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