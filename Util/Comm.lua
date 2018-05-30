local Addon = LibStub("AceAddon-3.0"):GetAddon(PLR_NAME)
local Util = Addon.Util
local Locale = Addon.Locale
local Self = {}

-- Distribution types
Self.TYPE_GROUP = "GROUP"
Self.TYPE_PARTY = "PARTY"
Self.TYPE_RAID = "RAID"
Self.TYPE_GUILD = "GUILD"
Self.TYPE_OFFICER = "OFFICER"
Self.TYPE_BATTLEGROUND = "BATTLEGROUND"
Self.TYPE_WHISPER = "WHISPER"
Self.TYPE_INSTANCE = "INSTANCE_CHAT"
Self.TYPES = {Self.TYPE_GROUP, Self.TYPE_PARTY, Self.TYPE_RAID, Self.TYPE_GUILD, Self.TYPE_OFFICER, Self.TYPE_BATTLEGROUND, Self.TYPE_WHISPER, Self.TYPE_INSTANCE}

-- Addon events
Self.EVENT_SYNC = "SYNC"
Self.EVENT_ROLL_STATUS = "STATUS"
Self.EVENT_BID = "BID"
Self.EVENT_VERSION_ASK = "VERSION-ASK"
Self.EVENT_VERSION = "VERSION"
Self.EVENT_MASTERLOOT_ASK = "ML-ASK"
Self.EVENT_MASTERLOOT_OFFER = "ML-OFFER"
Self.EVENT_MASTERLOOT_ACK = "ML-ACK"
Self.EVENT_MASTERLOOT_DEC = "ML-DEC"

-- Message patterns
Self.PATTERN_PARTY_JOINED = ERR_JOINED_GROUP_S:gsub("%%s", "(.+)")
Self.PATTERN_INSTANCE_JOINED = ERR_INSTANCE_GROUP_ADDED_S:gsub("%%s", "(.+)")
Self.PATTERN_RAID_JOINED = ERR_RAID_MEMBER_ADDED_S:gsub("%%s", "(.+)")
Self.PATTERN_PARTY_LEFT = ERR_LEFT_GROUP_S:gsub("%%s", "(.+)")
Self.PATTERN_INSTANCE_LEFT = ERR_INSTANCE_GROUP_REMOVED_S:gsub("%%s", "(.+)")
Self.PATTERN_RAID_LEFT = ERR_RAID_MEMBER_REMOVED_S:gsub("%%s", "(.+)")
Self.PATTERNS_JOINED = {Self.PATTERN_PARTY_JOINED, Self.PATTERN_INSTANCE_JOINED, Self.PATTERN_RAID_JOINED}
Self.PATTERNS_LEFT = {Self.PATTERN_PARTY_LEFT, Self.PATTERN_INSTANCE_LEFT, Self.PATTERN_RAID_LEFT}

-------------------------------------------------------
--                      Chatting                     --
-------------------------------------------------------

-- Get the complete message prefix for an event
function Self.GetPrefix(event)
    if not Util.StrStartsWith(event, PLR_PREFIX) then
        event = PLR_PREFIX .. event
    end

    return event
end

-- Figure out the channel and target for a message
function Self.GetDestination(target)
    local target = target or Self.TYPE_GROUP

    if target == Self.TYPE_GROUP then
        if IsInGroup(LE_PARTY_CATEGORY_INSTANCE) then
            return Self.TYPE_INSTANCE
        elseif IsInRaid() then
            return Self.TYPE_RAID
        else
            return Self.TYPE_PARTY
        end
    elseif Util.TblFind(Self.TYPES, target) then
        return target
    else
        return Self.TYPE_WHISPER, Util.GetName(target)
    end
end

-- Check if chat on given channel and to giver target is enabled
function Self.ShouldChat(target)
    local channel, unit = Self.GetDestination(target)
    local config = Addon.db.profile

    -- Check whisper target
    if channel == Self.TYPE_WHISPER then
        if UnitIsUnit(unit, "player") then
            return false
        end

        local target = config.whisper.target
        local guild = Util.GetGuildName(unit)
        local isGuild, isFriend = guild ~= nil and guild == Util.GetGuildName("player"), Util.UnitIsFriend(unit)

        if isGuild or isFriend then
            if isFriend and not target.friend or isGuild and not target.guild then
                return false
            end
        elseif not target.other then
            return false
        end
    end

    -- Check party type
    local group = channel == Self.TYPE_WHISPER and config.whisper.group or config.announce

    if IsInRaid(LE_PARTY_CATEGORY_INSTANCE) then
        return group.lfr
    elseif IsInGroup(LE_PARTY_CATEGORY_INSTANCE) then
        return group.lfd
    elseif Util.IsGuildGroup() then
        return group.guild
    elseif IsInRaid() then
        return group.raid
    elseif IsInGroup() then
        return group.party
    end

    return true
end

-- Send a chat line
function Self.Chat(msg, target)
    local channel, player = Self.GetDestination(target)

    -- TODO: DEBUG
    Addon:Print("@" .. (player or channel) .. ": " .. msg)
    do return end
    -- TODO: DEBUG

    SendChatMessage(msg, channel, nil, player)
end

function Self.ChatLine(line, target, ...)
    local _, player = Self.GetDestination(target)
    local L = Locale.GetCommLocale(player)

    Self.Chat(L(line, ...), target)
end

-- Send an addon message
function Self.Send(event, txt, target, prio, callbackFn, callbackArg)
    event = Self.GetPrefix(event)

    -- Figure out the correct channel and target
    local channel, player = Self.GetDestination(target)

    -- Send the message
    Addon:SendCommMessage(event, txt or "", channel, player, prio, callbackFn, callbackArg)
end

-- Send structured addon data
function Self.SendData(event, data, target, prio, callbackFn, callbackArg)
    Self.Send(event, Addon:Serialize(data), target, prio, callbackFn, callbackArg)
end

-- Listen for an addon message
function Self.Listen(event, method, fromSelf, fromAll)
    Addon:RegisterComm(Self.GetPrefix(event), function (event, msg, channel, sender)
        local unit = Util.GetUnit(sender)
        if fromAll or Util.UnitInGroup(unit, not fromSelf) then
            method(event, msg, channel, sender, unit)
        end
    end)
end

-- Listen for an addon message with data
function Self.ListenData(event, method)
    Self.Listen(event, function (event, data, ...)
        local success, data = Addon:Deserialize(data)
        if success then
            method(event, data, ...)
        end
    end)
end

-------------------------------------------------------
--                   Chat messages                   --
-------------------------------------------------------

-- Send a bid to another player
function Self.ChatBid(player, itemLink)
    Self.ChatLine("BID", player, itemLink or Locale.GetCommLine('ITEM', player))
end

-------------------------------------------------------
--                       Helper                      --
-------------------------------------------------------

function Self.GetPlayerLink(player)
    local color = Util.GetUnitColor(player)
    return ("|c%s|Hplayer:%s|h[%s]|h|r"):format(color.colorStr, player, player)
end

function Self.GetTradeLink(player)
    local L = LibStub("AceLocale-3.0"):GetLocale(PLR_NAME)
    return ("|cff4D85E6|Hplrtrade:%s|h[%s]|h|r"):format(player, TRADE)
end

-- Export

Addon.Comm = Self