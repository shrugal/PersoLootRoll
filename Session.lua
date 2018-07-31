local Name, Addon = ...
local L = LibStub("AceLocale-3.0"):GetLocale(Name)
local CB = LibStub("CallbackHandler-1.0")
local Comm, GUI, Unit, Util = Addon.Comm, Addon.GUI, Addon.Unit, Addon.Util
local Self = Addon.Session

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
Self.rules = {}
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
        wipe(Self.rules)
    end
    
    PersoLootRollML = unit
    Self.masterlooter = unit

    Addon:OnTrackingChanged()

    -- Let others know
    if unit then
        Self.SetRules(session)

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
        local config = Addon.db.profile.masterlooter

        -- Council
        local council = {}
        for i=1,GetNumGroupMembers() do
            local unit, rank = GetRaidRosterInfo(i)
            if unit and not Unit.IsSelf(unit) and Self.IsOnCouncil(unit, true, rank) then
                council[Unit.FullName(unit)] = true
            end
        end

        Self.rules = {
            clubId = nil, -- TODO
            guild = nil, -- TODO
            masterlooter = nil, -- TODO
            bidPublic = config.bidPublic,
            timeoutBase = config.timeoutBase or Roll.TIMEOUT,
            timeoutPerItem = config.timeoutPerItem or Roll.TIMEOUT_PER_ITEM,
            council = Util.TblCount(council) > 0 and council or nil,
            votePublic = config.votePublic,
            answers1 = config.answers1,
            answers2 = config.answers2,
            answers3 = nil -- TODO
        }

        if not silent then
            Self.SendOffer(nil, true)
        end
    elseif rules then
        Self.rules = rules
    else
        wipe(Self.rules)
    end

    Self.events:Fire(Self.EVENT_SESSION, Self.rules, silent)

    return Self.rules
end

-- Refresh the session rules
function Self.RefreshRules()
    if Self.IsMasterlooter() then Self.SetRules() end
end

-- Check if the unit is on the loot council
function Self.IsOnCouncil(unit, refresh, groupRank)
    unit = Unit(unit or "player")
    local fullName = Unit.FullName(unit)

    if not refresh then
        return Self.rules.council and Self.rules.council[fullName] or false
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
--                     Communities                   --
-------------------------------------------------------

-- Read session rule(s) from community description
function Self.ReadFromCommunity(clubId, key)
    local info = C_Club.GetClubInfo(clubId)
    if info and not Util.StrIsEmpty(info.description) then
        local t, found = not key and Util.Tbl() or nil, false

        for i,line in Util.Each(("\n"):split(info.description)) do
            local name, val = line:match("^PLR%-(.-): ?(.*)")
            if name then
                name = Util.StrToCamelCase(name)
                if not key then
                    t[name] = Self.DecodeRule(name, val)
                elseif key == name then
                    return Self.DecodeRule(name, val)
                end
            end
        end

        return t
    end
end

-- Write session rule(s) do community description. We can only write to 
function Self.WriteToCommunity(clubId, keyOrTbl, val)
    local isKey = type(keyOrTbl) ~= "table"

    local info = C_Club.GetClubInfo(clubId)
    if info then
        local desc, found = Util.StrSplit(info.description, "\n"), Util.Tbl()

        -- Update or delete existing entries
        for i,line in ipairs(desc) do
            local name = line:match("^PLR%-(.-):")
            if name then
                name = Util.StrToCamelCase(name)
                found[name] = true

                if not isKey or isKey == name then
                    local v
                    if isKey then v = val else v = keyOrTbl[name] end

                    if v ~= nil then
                        desc[i] = ("PLR-%s: %s"):format(Util.StrFromCamelCase(name, "-", true), Self.EncodeRule(name, v))
                    else
                        tremove(desc, i)
                    end

                    if isKey then break end
                end
            end
        end

        -- Add new entries
        for name,v in Util.Each(keyOrTbl) do
            if isKey then name, v = v, val end

            if not found[name] and v ~= nil then
                if not next(found) then
                    tinsert(desc, "\n------ PersoLootRoll ------")
                end

                found[name] = true
                tinsert(desc, ("PLR-%s: %s"):format(Util.StrFromCamelCase(name, "-", true), Self.EncodeRule(name, v)))
            end
        end

        local str = Util.TblConcat(desc, "\n")
        Util.TblRelease(desc, found)

        -- We can only write to guild communities, and only when we have the rights to do so
        local priv = C_Club.GetClubPrivileges(clubId)
        if priv and priv.canSetDescription and info.clubType == Enum.ClubType.Guild then
            SetGuildInfoText(str)
            return true
        else
            return str
        end
    end
end

-- Encode a session rule to its string representation
function Self.EncodeRule(name, val)
    local t = type(val)
    if Util.In(t, "string", "number") then
        return val
    elseif t == "boolean" then
        return val and "true" or "false"
    elseif t == "table" then
        local s
        for i,v in pairs(val) do
            v = Util.Select(true,
                name == "answers1" and v == NEED,   Roll.ANSWER_NEED,
                name == "answers2" and v == GREED,  Roll.ANSWER_GREED,
                v
            )
            s = (s and s .. ", " or "") .. v
        end
        return s or ""
    else
        return ""
    end
end

-- Decode a session rule from its string representation
function Self.DecodeRule(name, str)
    if Util.In(name, "bidPublic", "votePublic") then
        return Util.In(str:lower(), "true", "1", "yes")
    elseif Util.In(name, "timeoutBase", "timeoutPerItem", "councilRank") then
        return tonumber(str)
    elseif Util.In(name, "masterlooter", "council", "answers1", "answers2", "answers3") then
        local val = Util.Tbl()
        for v in str:gmatch("[^,]+") do
            v = v:gsub("^%s*(.*)%s*$", "%1")
            if name == "answers1" and v == NEED then
                v = Roll.ANSWER_NEED
            elseif name == "answers2" and v == GREED then
                v = Roll.ANSWER_GREED
            end
            tinsert(val, v) end
        return val
    elseif str ~= "" then
        return str
    end
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