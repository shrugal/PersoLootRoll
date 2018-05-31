local Addon = LibStub("AceAddon-3.0"):GetAddon(PLR_NAME)
local L = LibStub("AceLocale-3.0"):GetLocale(PLR_NAME)
local Util = Addon.Util
local Comm = Addon.Comm
local Self = {}

Self.masterlooter = nil
Self.session = {}
Self.masterlooting = {}

-------------------------------------------------------
--                    Masterlooter                   --
-------------------------------------------------------

-- Set (or reset) the masterlooter
function Self.SetMasterlooter(unit, session, silent)
    unit = unit and Util.GetName(unit)

    if Self.masterlooter then
        if unit ~= Self.masterlooter then
            wipe(Self.masterlooting)
            wipe(Self.session)
            if not silent then
                Comm.Send(Comm.EVENT_MASTERLOOT_DEC, nil, UnitIsUnit(Self.masterlooter, "player") and Comm.TYPE_GROUP or Self.masterlooter)
            end
        end
    end
    
    PLR_MASTERLOOTER = unit
    Self.masterlooter = unit

    if unit then
        Self.SetSession(session)

        local isSelf = UnitIsUnit(Self.masterlooter, "player")
        Addon:Info(isSelf and L["MASTERLOOTER_SELF"] or L["MASTERLOOTER_OTHER"]:format(Comm.GetPlayerLink(unit)))

        if isSelf then
            Self.SendOffer(nil, silent)
        elseif not silent then
            Comm.Send(Comm.EVENT_MASTERLOOT_ACK, nil, unit)
        end
    end

    Addon.GUI.Rolls.Update()
end

-- Check if the unit (or the player) is our masterlooter
function Self:GetMasterlooter(unit)
    return Self.masterlooter
end

-- Check if the unit (or the player) is our masterlooter
function Self.IsMasterlooter(unit)
    return Self.masterlooter and UnitIsUnit(Self.masterlooter, unit or "player")
end

-------------------------------------------------------
--                     Permission                    --
-------------------------------------------------------

-- Check if the given unit can become our masterlooter
function Self.UnitAllow(unit)
    unit = Util.GetName(unit)
    local config = Addon.db.profile.masterloot

    -- Always deny
    if not unit or not Util.UnitInGroup(unit) then
        return false
    end

    -- Always allow
    if UnitIsUnit(unit, "player") or config.allowAll then
        return true
    end

    -- Check whitelist
    for i,v in pairs(config.whitelist) do
        if UnitIsUnit(unit, v) then
            return true
        end
    end
    
    local guild = Util.GetGuildName(unit)

    -- Check everything else
    if config.allow.friend and Util.UnitIsFriend(unit) then
        return true
    elseif config.allow.guild and Util.UnitIsGuildMember(unit) then
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

    if config.friend and Util.UnitIsFriend(unit) then
        return true
    elseif Util.UnitIsGuildMember(unit) then
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
    Comm.Send(Comm.EVENT_MASTERLOOT_ASK, nil, PLR_MASTERLOOTER)
end

-- Set the masterloot session
function Self.SetSession(session, silent)
    if Self.IsMasterlooter() then
        local config = Addon.db.profile.masterloot

        -- Council
        local council = {}

        for unit,_ in pairs(config.councilWhitelist) do
            if Util.UnitInGroup(unit) then
                council[Util.GetFullName(unit)] = true
            end
        end

        Util.SearchGroup(function (i, unit, rank)
            if config.council.raidleader and rank == 2 or config.council.raidassistant and rank == 1 then
                council[Util.GetFullName(unit)] = true
            else
                local guildRank = Util.UnitGuildRank(unit)
                if config.council.guildleader and rank == 0 or config.council.guildofficer and rank == 1 then
                    council[Util.GetFullName(unit)] = true
                end
            end
        end)

        council[Util.GetFullName("player")] = nil

        Self.session = {
            bidPublic = config.bidPublic,
            council = Util.TblCount(council) > 0 and council or nil,
            votePublic = config.votePublic
        }

        if not silent then
            Self.SendOffer(nil, true)
        end
    else
        Self.session = session or {}
    end

    return Self.session
end

-- Check if the unit is on the loot council
function Self.IsOnCouncil(unit)
    return Self.session.council and Self.session.council[Util.GetFullName(unit or "player")]
end

-------------------------------------------------------
--                         Comm                      --
-------------------------------------------------------

function Self.SendOffer(unit, silent)
    if Self.IsMasterlooter() then
        Comm.SendData(Comm.EVENT_MASTERLOOT_OFFER, {session = Self.session, silent = silent}, unit)
    end
end

-- Export

Addon.Masterloot = Self