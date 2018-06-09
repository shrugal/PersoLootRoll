local Name, Addon = ...
local L = LibStub("AceLocale-3.0"):GetLocale(Name)
local Locale, Masterloot, Roll, Unit, Util = Addon.Locale, Addon.Masterloot, Addon.Roll, Addon.Unit, Addon.Util
local Self = Addon.Comm

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
Self.EVENT_ROLL_STATUS = "STATUS"
Self.EVENT_BID = "BID"
Self.EVENT_VOTE = "VOTE"
Self.EVENT_INTEREST = "INTEREST"
Self.EVENT_SYNC = "SYNC"
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
    if not Util.StrStartsWith(event, Addon.PREFIX) then
        event = Addon.PREFIX .. event
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
        return Self.TYPE_WHISPER, Unit.Name(target)
    end
end

-- Check if chat on given channel and to giver target is enabled
function Self.ShouldChat(target)
    local channel, unit = Self.GetDestination(target)
    local config = Addon.db.profile

    -- Check group
    if not IsInGroup() or Util.TblCount(Addon.versions) + 1 == GetNumGroupMembers() then
        return false
    end

    -- Check whisper target
    if channel == Self.TYPE_WHISPER then
        if Addon.versions[unit] or UnitIsUnit(unit, "player") then
            return false
        end

        local target = config.whisper.target
        local guild = Unit.GuildName(unit)
        local isGuild, isFriend = guild ~= nil and guild == Unit.GuildName("player"), Unit.IsFriend(unit)

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
    else
        return group.party
    end
end

-- Send a chat line
function Self.Chat(msg, target)
    local channel, player = Self.GetDestination(target)

    if Addon.DEBUG then
        Addon:Print("@" .. (player or channel) .. ": " .. msg)
        do return end
    end

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

    -- TODO: This fixes a beta bug that causes a dc when sending empty strings
    txt = (not txt or txt == "") and " " or txt

    -- Send the message
    Addon:SendCommMessage(event, txt, channel, player, prio, callbackFn, callbackArg)
end

-- Send structured addon data
function Self.SendData(event, data, target, prio, callbackFn, callbackArg)
    Self.Send(event, Addon:Serialize(data), target, prio, callbackFn, callbackArg)
end

-- Listen for an addon message
function Self.Listen(event, method, fromSelf, fromAll)
    Addon:RegisterComm(Self.GetPrefix(event), function (event, msg, channel, sender)
        msg = msg ~= "" and msg ~= " " and msg or nil
        local unit = Unit(sender)
        if fromAll or Unit.InGroup(unit, not fromSelf) then
            method(event, msg, channel, sender, unit)
        end
    end)
end

-- Listen for an addon message with data
function Self.ListenData(event, method, fromSelf, fromAll)
    Self.Listen(event, function (event, data, ...)
        local success, data = Addon:Deserialize(data)
        if success then
            method(event, data, ...)
        end
    end, fromSelf, fromAll)
end

-------------------------------------------------------
--                   Chat messages                   --
-------------------------------------------------------

-- BID

-- Send a bid to another player
function Self.RollBid(owner, link, manually)
    if manually or Self.ShouldChat(owner) then
        Self.ChatLine("BID", owner, link or Locale.GetSelfLine('ITEM', owner))
        Addon:Info(L["BID_CHAT"]:format(Self.GetPlayerLink(owner), link, Self.GetTradeLink(owner)))
    else
        Addon:Info(L["BID_NO_CHAT"]:format(Self.GetPlayerLink(owner), link, Self.GetTradeLink(owner)))
    end
end

-- Show an error message for an invalid bid
function Self.RollBidError(roll, sender)
    if UnitIsUnit(sender, "player") then
        Addon:Err(L["ERROR_ROLL_BID_UNKNOWN_SELF"])
    else
        Addon:Verbose(L["ERROR_ROLL_BID_UNKNOWN_OTHER"]:format(sender, roll.item.link))
    end
end

-- Show a confirmation message for a bid by the player
function Self.RollBidSelf(roll)
    if roll.bid == Roll.BID_PASS then
        Addon:Verbose(L["BID_PASS"]:format((roll.item and roll.item.link) or L["ITEM"], Self.GetPlayerLink(roll.item.owner)))
    else
        Addon:Verbose(L["BID_START"]:format(L["ROLL_BID_" .. roll.bid], (roll.item and roll.item.link) or L["ITEM"], Self.GetPlayerLink(roll.item.owner)))
    end
end

-- VOTE

function Self.RollVote(roll)

end

function Self.RollVoteError(roll, sender)

end

-- END

-- Messages when ending a roll
function Self.RollEnd(roll, isWhisper)
    -- We won the item
    if roll.isWinner then
        if not roll.isOwner or roll.bid ~= Roll.BID_NEED or Masterloot.GetMasterlooter() then
            if roll.item.isOwner then
                Addon:Info(L["ROLL_WINNER_OWN"]:format(roll.item.link))
            else
                Addon:Info(L["ROLL_WINNER_SELF"]:format(roll.item.link, Self.GetPlayerLink(roll.item.owner), Self.GetTradeLink(roll.item.owner)))
            end

            roll:ShowAlertFrame()
        end

    -- Someone won our item
    else
        if roll.item.isOwner then
            Addon:Info(L["ROLL_WINNER_OTHER"]:format(Self.GetPlayerLink(roll.winner), roll.item.link, Self.GetTradeLink(roll.winner)))
        elseif roll.isOwner then
            Addon:Info(L["ROLL_WINNER_MASTERLOOT"]:format(Self.GetPlayerLink(roll.winner), roll.item.link, Self.GetPlayerLink(roll.item.owner)))
        end

        if roll.isOwner then
            -- Announce to chat
            if roll.posted and Self.ShouldChat() then
                if roll.item.isOwner then
                    Self.ChatLine("ROLL_WINNER", Self.TYPE_GROUP, Unit.FullName(roll.winner), roll.item.link)
                else
                    Self.ChatLine("ROLL_WINNER_MASTERLOOT", Self.TYPE_GROUP, Unit.FullName(roll.winner), roll.item.link, Unit.FullName(roll.item.owner), Locale.Gender(roll.item.owner, "HER", "HIM"))
                end
            end
            
            -- Announce to target
            if Addon.db.profile.answer and not Addon.versions[roll.winner] then
                if roll.item:GetNumEligible(true) == 1 then
                    if roll.item.isOwner then
                        Self.ChatLine("ROLL_ANSWER_YES", roll.winner)
                    else
                        Self.ChatLine("ROLL_ANSWER_YES_MASTERLOOT", roll.winner, roll.item.owner)
                    end
                else
                    if roll.item.isOwner then
                        Self.ChatLine("ROLL_WINNER_WHISPER", roll.winner, roll.item.link)
                    else
                        Self.ChatLine("ROLL_WINNER_WHISPER_MASTERLOOT", roll.winner, roll.item.link, Unit.FullName(roll.item.owner), Locale.Gender(roll.item.owner, "HER", "HIM"))
                    end
                end
            end
        end
    end
end

-------------------------------------------------------
--                       Helper                      --
-------------------------------------------------------

function Self.GetPlayerLink(player)
    local color = Unit.Color(player)
    return ("|c%s|Hplayer:%s|h[%s]|h|r"):format(color.colorStr, player, player)
end

function Self.GetTradeLink(player)
    return ("|cff4D85E6|Hplrtrade:%s|h[%s]|h|r"):format(player, TRADE)
end

function Self.GetBidLink(roll, player, bid)
    return ("|cff4D85E6|Hplrbid:%d:%s:%d|h[%s]|h|r"):format(roll.id, player, bid, L["ROLL_BID_" .. bid])
end