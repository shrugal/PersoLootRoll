---@type string
local Name = ...
---@type Addon
local Addon = select(2, ...)
---@type L
local L = LibStub("AceLocale-3.0"):GetLocale(Name)
local Comm, GUI, Roll, Unit, Util = Addon.Comm, Addon.GUI, Addon.Roll, Addon.Unit, Addon.Util
---@class Session : Module
local Self = Addon.Session

-- Events

--- Fired when requesting a ML
-- @string target The target, group if omitted
Self.EVENT_REQUEST = "PLR_SESSION_REQUEST"

--- Fired when a session is started
-- @string unit   The masterlooter
-- @table  rules  The session rules
-- @bool   silent Whether other players are informed about it
Self.EVENT_START = "PLR_SESSION_START"

--- Fired when a session is stopped/cleared
-- @bool silent Whether other players are informed about it
Self.EVENT_CLEAR = "PLR_SESSION_CLEAR"

--- Fired when rules are set or changed
-- @table  rules  The session rules
-- @bool   silent Whether other players are informed about it
Self.EVENT_RULES = "PLR_SESSION_RULES"

--- Catchall event that fires for all events in Self.EVENTS
-- @string event The original event
-- @param  ...   The original event parameters
Self.EVENT_CHANGE = "PLR_SESSION_CHANGE"

Self.EVENTS = {Self.EVENT_START, Self.EVENT_CLEAR, Self.EVENT_RULES}

local changeFn = function (...) Self:SendMessage(Self.EVENT_CHANGE, ...) end
for _,e in pairs(Self.EVENTS) do Self:RegisterMessage(e, changeFn) end

Self.masterlooter = nil
Self.rules = {}
Self.masterlooting = {}
Self.rejectShown = {}

-------------------------------------------------------
--                    Masterlooter                   --
-------------------------------------------------------

-- Set (or reset) the masterlooter
---@param unit string?
---@param rules table?
---@param silent boolean?
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

    Addon:CheckState(true)

    -- Let others know
    if unit then
        Self.SetRules(rules)
        Self.rejectShown[unit] = nil

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
        Self:SendMessage(Self.EVENT_START, unit, rules, silent)
    else
        Self:SendMessage(Self.EVENT_CLEAR, silent)
    end
end

-- Check if the unit (or the player) is our masterlooter
---@param unit string?
function Self.GetMasterlooter(unit)
    unit = Unit.Name(unit or "player")
    if Unit.IsSelf(unit) then
        return Self.masterlooter
    else
        return Self.masterlooting[unit]
    end
end

-- Check if the unit (or the player) is our masterlooter
---@param unit string?
---@return boolean?
function Self.IsMasterlooter(unit)
    return Self.masterlooter and UnitIsUnit(Self.masterlooter, unit or "player")
end

-- Set a unit's masterlooting status
---@param unit string
---@param ml string?
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
---@param unit string
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
    for i,v in pairs(Addon.db.profile.masterloot.whitelists[GetRealmName()] or Util.Tbl.EMPTY) do
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

function Self.ShowOfferDialog(unit, onAccept)
    local dialog = StaticPopupDialogs[GUI.DIALOG_MASTERLOOT_ASK]
    dialog.text = L["DIALOG_MASTERLOOT_ASK"]:format(unit)
    dialog.OnAccept = onAccept
    StaticPopup_Show(GUI.DIALOG_MASTERLOOT_ASK)
end

-------------------------------------------------------
--                       Session                     --
-------------------------------------------------------

-- Restore a session
function Self.Restore()
    if Unit.InGroup(PersoLootRollML) then
        Self.SetMasterlooter(PersoLootRollML, {}, true)
        Self.SendRequest(PersoLootRollML)
    end
end

-- Set the session rules
---@param rules table?
---@param silent boolean?
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
            allowKeep = c.rules.allowKeep
        }

        if not silent then
            Self.SendOffer(nil, true)
        end
    elseif rules then
        Self.rules = rules
    else
        wipe(Self.rules)
    end

    Self:SendMessage(Self.EVENT_RULES, Self.rules, silent)

    return Self.rules
end

-- Refresh the session rules
function Self.RefreshRules()
    if Self.IsMasterlooter() then
        Self.SetRules()
    end
end
Self.RefreshRules = Util.Fn.Debounce(Self.RefreshRules, 0.1, true)

-- Check if the unit is on the loot council
---@param unit string?
---@param refresh boolean?
---@param groupRank integer?
function Self.IsOnCouncil(unit, refresh, groupRank)
    unit = Unit(unit or "player")
    local fullName = Unit.FullName(unit)
    local c = Addon.db.profile.masterloot
    local r = GetRealmName()

    if Unit.IsUnit(unit, Self.GetMasterlooter()) then
        return true
    elseif not refresh then
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
        local clubId = Addon.db.char.masterloot.clubId
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
        if (c.council.roles.raidleader or c.council.roles.raidassistant) and Util.Select(groupRank or Unit.GroupRank(unit), Unit.GROUP_RANK_LEADER, c.council.roles.raidleader, Unit.GROUP_RANK_ASSISTANT, c.council.roles.raidassistant) then
            return true
        end
    end

    return false
end

-------------------------------------------------------
--                        Comm                       --
-------------------------------------------------------

-- Ask someone to be your masterlooter
---@param target string
function Self.SendRequest(target)
    if target then
        Self.rejectShown[target] = nil
    else
        wipe(Self.rejectShown)
    end

    Comm.Send(Comm.EVENT_MASTERLOOT_ASK, nil, target)
    Self:SendMessage(Self.EVENT_REQUEST, target)
end

-- Send masterlooter offer to unit
---@param target string?
---@param silent boolean?
function Self.SendOffer(target, silent)
    if Self.IsMasterlooter() then
        Comm.SendData(Comm.EVENT_MASTERLOOT_OFFER, {session = Self.rules, silent = silent}, target)
    end
end

-- Confirm unit as your masterlooter
---@param target string?
function Self.SendConfirmation(target)
    Comm.Send(Comm.EVENT_MASTERLOOT_ACK, Unit.FullName(Self.masterlooter), target)
end

-- Stop being a masterlooter (unit == nil) or clear the unit's masterlooter
function Self.SendCancellation(unit, target)
    Comm.Send(Comm.EVENT_MASTERLOOT_DEC, unit and Unit.FullName(unit) or nil, target)
end

-- ASK
Comm.Listen(Comm.EVENT_MASTERLOOT_ASK, function (event, msg, channel, sender, unit)
    if Self.IsMasterlooter() then
        Self.SetMasterlooting(unit, nil)
        Self.SendOffer(unit)
    elseif channel == Comm.TYPE_WHISPER then
        Self.SendCancellation(nil, unit)
    elseif Self.GetMasterlooter() then
        Self.SendConfirmation(unit)
    end
end)

-- OFFER
Comm.ListenData(Comm.EVENT_MASTERLOOT_OFFER, function (event, data, channel, sender, unit)
    Self.SetMasterlooting(unit, unit)

    if Self.IsMasterlooter(unit) then
        Self.SendConfirmation()
        Self.SetRules(data.session)
    elseif Self.UnitAllow(unit) then
        if Self.UnitAccept(unit) then
            Self.SetMasterlooter(unit, data.session)
        elseif not data.silent then
            Self.ShowOfferDialog(unit, function ()
                Self.SetMasterlooter(unit, data.session)
            end)
        end
    elseif not data.silent and not Self.rejectShown[unit] then
        Self.rejectShown[unit] = true
        Addon:Info(L["MASTERLOOTER_REJECT"], Comm.GetPlayerLink(unit))
    end
end)

-- ACK
Comm.Listen(Comm.EVENT_MASTERLOOT_ACK, function (event, ml, channel, sender, unit)
    ml = Unit(ml)
    if ml then
        if UnitIsUnit(ml, "player") and not Self.IsMasterlooter() then
            Self.SendCancellation(nil, channel == Comm.TYPE_WHISPER and unit or nil)
        else
            Self.SetMasterlooting(unit, ml)
        end
    end
end)

-- DEC
Comm.Listen(Comm.EVENT_MASTERLOOT_DEC, function (event, player, channel, sender, unit)
    player = Unit(player)

    -- Clear the player's masterlooter
    if Self.IsMasterlooter(unit) and (Util.Str.IsEmpty(player) or UnitIsUnit(player, "player")) then
        Self.SetMasterlooter(nil, nil, true)
    elseif player == unit or Self.masterlooting[player] == unit then
        Self.SetMasterlooting(player, nil)
    end

    -- Clear everybody who has the sender as masterlooter
    if Util.Str.IsEmpty(player) then
        Self.ClearMasterlooting(unit)
    end
end)

-------------------------------------------------------
--                    Events/Hooks                   --
-------------------------------------------------------

function Self:OnEnable()
    -- Register events
    Self:RegisterEvent("GROUP_JOINED", Self.Restore)
    Self:RegisterEvent("GROUP_LEFT")
    Self:RegisterEvent("CHAT_MSG_SYSTEM")

    if IsInGroup() then
        Self.Restore()
    end
end

function Self:GROUP_LEFT()
    Self.SetMasterlooter(nil)
    wipe(Self.masterlooting)
    wipe(Self.rejectShown)
end

---@param msg string
function Self:CHAT_MSG_SYSTEM(_, msg)
    -- Check if a player left the group/raid
    for _,pattern in pairs(Comm.PATTERNS_LEFT) do
        local unit = msg:match(pattern)
        if unit then
            -- Clear masterlooter
            if unit == Self.GetMasterlooter() then
                Self.SetMasterlooter(nil, nil, true)
            end
            Self.SetMasterlooting(unit, nil)
            Self.ClearMasterlooting(unit)
            Self.rejectShown[unit] = nil
        end
    end
end