local Name, Addon = ...
local L = LibStub("AceLocale-3.0"):GetLocale(Name)
local CB = LibStub("CallbackHandler-1.0")
local Comm, GUI, Roll, Unit, Util = Addon.Comm, Addon.GUI, Addon.Roll, Addon.Unit, Addon.Util
local Self = Addon.Session

-- Events
Self.events = CB:New(Self, "On", "Off")

--- Fired when a session is started
-- @string unit   The masterlooter
-- @table  rules  The session rules
-- @bool   silent Whether other players are informed about it
Self.EVENT_START = "START"

--- Fired when a session is stopped/cleared
-- @bool silent Whether other players are informed about it
Self.EVENT_CLEAR = "CLEAR"

--- Fired when rules are set or changed
-- @table  rules  The session rules
-- @bool   silent Whether other players are informed about it
Self.EVENT_RULES = "RULES"


--- Catchall event that fires for all of the above
-- @string event The original event
-- @param  ...   The original event parameters
Self.EVENT_CHANGE = "CHANGE"

Self.EVENTS = {Self.EVENT_START, Self.EVENT_CLEAR, Self.EVENT_RULES}

local changeFn = function (...) Self.events:Fire(Self.EVENT_CHANGE, ...) end
for _,ev in pairs(Self.EVENTS) do
    Self:On(ev, changeFn)
end

Self.masterlooter = nil
Self.rules = {}
Self.masterlooting = {}

-------------------------------------------------------
--                    Masterlooter                   --
-------------------------------------------------------

-- Set (or reset) the masterlooter
function Self.SetMasterlooter(unit, rules, silent)
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
        wipe(Self.rules)
    end
    
    PersoLootRollML = unit
    Self.masterlooter = unit

    Addon:OnTrackingChanged()

    -- Let others know
    if unit then
        Self.SetRules(rules)

        local isSelf = UnitIsUnit(Self.masterlooter, "player")
        Addon:Info(isSelf and L["MASTERLOOTER_SELF"] or L["MASTERLOOTER_OTHER"], Comm.GetPlayerLink(unit))

        if isSelf then
            Self.SendOffer(nil, silent)
        elseif not silent then
            Self.SendConfirmation()
        end
    end

    -- Fire event
    if unit then
        Self.events:Fire(Self.EVENT_START, unit, rules, silent)
    else
        Self.events:Fire(Self.EVENT_CLEAR, silent)
    end
end

-- Check if the unit (or the player) is our masterlooter
function Self.GetMasterlooter(unit)
    unit = Unit.Name(unit or "player")
    if Unit.IsSelf(unit) then
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
        Self.SetRules()
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

-- Check if the given unit can send us a ruleset
function Self.UnitAllow(unit)
    unit = Unit.Name(unit)
    local config = Addon.db.profile.masterloot

    -- Always deny
    if not unit or not Unit.InGroup(unit) then
        return false
    end

    -- Always allow
    if Unit.IsSelf(unit) or config.allowAll then
        return true
    end

    -- Check whitelist
    for i,v in pairs(Addon.db.profile.masterloot.whitelists[GetRealmName()] or Util.TBL_EMPTY) do
        if UnitIsUnit(unit, i) then return true end
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

-- Check if we should auto-accept rulesets from this unit
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
    if Unit.InGroup(PersoLootRollML) then
        Self.SetMasterlooter(PersoLootRollML, {}, true)
    end
    Self.SendRequest(PersoLootRollML)
end

-- Set the session rules
function Self.SetRules(rules, silent)
    if Self.IsMasterlooter() then
        local c = Addon.db.profile.masterloot

        -- Council
        local council = {}
        for i=1,GetNumGroupMembers() do
            local unit, rank = GetRaidRosterInfo(i)
            if unit and not Unit.IsSelf(unit) and Self.IsOnCouncil(unit, true, rank) then
                council[Unit.FullName(unit)] = true
            end
        end

        Self.rules = {
            timeoutBase = c.rules.timeoutBase or Roll.TIMEOUT,
            timeoutPerItem = c.rules.timeoutPerItem or Roll.TIMEOUT_PER_ITEM,
            bidPublic = c.rules.bidPublic,
            answers1 = c.rules.needAnswers,
            answers2 = c.rules.greedAnswers,
            council = next(council) and council or nil,
            votePublic = c.council.votePublic,
        }

        if not silent then
            Self.SendOffer(nil, true)
        end
    elseif rules then
        Self.rules = rules
    else
        wipe(Self.rules)
    end

    Self.events:Fire(Self.EVENT_RULES, Self.rules, silent)

    return Self.rules
end

-- Refresh the session rules
function Self.RefreshRules()
    if Self.IsMasterlooter() then Self.SetRules() end
end
Self.RefreshRules = Util.FnDebounce(Self.RefreshRules, 1, true)

-- Check if the unit is on the loot council
function Self.IsOnCouncil(unit, refresh, groupRank)
    unit = Unit(unit or "player")
    local fullName = Unit.FullName(unit)
    local c = Addon.db.profile.masterloot
    local r = GetRealmName()

    if not refresh then
        return Self.rules.council and Self.rules.council[fullName] or false
    else
        -- Check if unit is part of our masterlooting group
        if not (Self.masterlooting[unit] == Self.masterlooter and Unit.InGroup(unit)) then
            return false
        -- Check whitelist
        elseif c.council.whitelists[r] and (c.council.whitelists[r][unit] or c.council.whitelists[r][fullName]) then
            return true
        end

        -- Check club rank
        local clubId = Addon.db.char.masterloot.council.clubId
        if clubId then
            local club = c.council.clubs[clubId]
            if club and club.ranks and next(club.ranks) then
                local info = Unit.ClubMemberInfo(unit, clubId)
                if info then
                    local rank = info.guildRankOrder or info.role
                    if rank and club.ranks[rank] then
                        return true
                    end
                end
            end
        end

        -- Check group rank
        if c.council.roles.raidleader or c.council.roles.raidassistant then
            if not groupRank then
                for i=1,GetNumGroupMembers() do
                    local unitGroup, rank = GetRaidRosterInfo(i)
                    if unitGroup == unit then groupRank = rank break end
                end
            end
            if c.council.roles.raidleader and groupRank == 2 or c.council.roles.raidassistant and groupRank == 1 then
                return true
            end
        end
    end

    return false
end

-------------------------------------------------------
--                        Comm                       --
-------------------------------------------------------

-- Ask someone to be your masterlooter
function Self.SendRequest(target)
    Comm.Send(Comm.EVENT_MASTERLOOT_ASK, nil, target)
end

-- Send masterlooter offer to unit
function Self.SendOffer(target, silent)
    if Self.IsMasterlooter() then
        Comm.SendData(Comm.EVENT_MASTERLOOT_OFFER, {session = Self.rules, silent = silent}, target)
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

-- ASK
Comm.Listen(Comm.EVENT_MASTERLOOT_ASK, function (event, msg, channel, sender, unit)
    if Session.IsMasterlooter() then
        Session.SetMasterlooting(unit, nil)
        Session.SendOffer(unit)
    elseif channel == Comm.TYPE_WHISPER then
        Session.SendCancellation(nil, unit)
    elseif Session.GetMasterlooter() then
        Session.SendConfirmation(unit)
    end
end)

-- OFFER
Comm.ListenData(Comm.EVENT_MASTERLOOT_OFFER, function (event, data, channel, sender, unit)
    Session.SetMasterlooting(unit, unit)

    if Session.IsMasterlooter(unit) then
        Session.SendConfirmation()
        Session.SetRules(data.session)
    elseif Session.UnitAllow(unit) then
        if Session.UnitAccept(unit) then
            Session.SetMasterlooter(unit, data.session)
        elseif not data.silent then
            local dialog = StaticPopupDialogs[GUI.DIALOG_MASTERLOOT_ASK]
            dialog.text = L["DIALOG_MASTERLOOT_ASK"]:format(unit)
            dialog.OnAccept = function ()
                Session.SetMasterlooter(unit, data.session)
            end
            StaticPopup_Show(GUI.DIALOG_MASTERLOOT_ASK)
        end
    end
end)

-- ACK
Comm.Listen(Comm.EVENT_MASTERLOOT_ACK, function (event, ml, channel, sender, unit)
    ml = Unit(ml)
    if ml then
        if UnitIsUnit(ml, "player") and not Session.IsMasterlooter() then
            Session.SendCancellation(nil, channel == Comm.TYPE_WHISPER and unit or nil)
        else
            Session.SetMasterlooting(unit, ml)
        end
    end
end)

-- DEC
Comm.Listen(Comm.EVENT_MASTERLOOT_DEC, function (event, player, channel, sender, unit)
    player = Unit(player)

    -- Clear the player's masterlooter
    if Session.IsMasterlooter(unit) and (Util.StrIsEmpty(player) or UnitIsUnit(player, "player")) then
        Session.SetMasterlooter(nil, nil, true)
    elseif player == unit or Session.masterlooting[player] == unit then
        Session.SetMasterlooting(player, nil)
    end

    -- Clear everybody who has the sender as masterlooter
    if Util.StrIsEmpty(player) then
        Session.ClearMasterlooting(unit)
    end
end)

-------------------------------------------------------
--                    Events/Hooks                   --
-------------------------------------------------------

function Self:OnEnable()
    -- Register events
    Self:RegisterEvent("GROUP_JOINED")
    Self:RegisterEvent("GROUP_LEFT")
    Self:RegisterEvent("CHAT_MSG_SYSTEM")
end

function Self.GROUP_JOINED()
    Self.Restore()
end

function Self.GROUP_LEFT()
    Self.SetMasterlooter(nil)
    wipe(Self.masterlooting)
end

function Self.CHAT_MSG_SYSTEM(_, msg)
    -- Check if a player left the group/raid
    for _,pattern in pairs(Comm.PATTERNS_LEFT) do
        local unit = msg:match(pattern)
        if unit then
            -- Clear masterlooter
            if unit == Session.GetMasterlooter() then
                Session.SetMasterlooter(nil, nil, true)
            end
            Session.SetMasterlooting(unit, nil)
            Session.ClearMasterlooting(unit)
        end
    end
end