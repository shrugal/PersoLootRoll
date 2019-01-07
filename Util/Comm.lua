local Name, Addon = ...
local Events, Locale, Session, Roll, Unit, Util = Addon.Events, Addon.Locale, Addon.Session, Addon.Roll, Addon.Unit, Addon.Util
local Self = Addon.Comm

Self.PREFIX = Addon.ABBR
Self.CHAT_PREFIX = "[" .. Addon.ABBR .. "] "
-- Max # of whispers per item for all addons in the group
Self.MAX_WHISPERS = 2

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
Self.EVENT_CHECK = "CHECK"
Self.EVENT_VERSION = "VERSION"
Self.EVENT_ENABLE = "ENABLE"
Self.EVENT_DISABLE = "DISABLE"
Self.EVENT_SYNC = "SYNC"
Self.EVENT_ROLL_STATUS = "STATUS"
Self.EVENT_BID = "BID"
Self.EVENT_BID_WHISPER = "WHISPER"
Self.EVENT_VOTE = "VOTE"
Self.EVENT_INTEREST = "INTEREST"
Self.EVENT_MASTERLOOT_ASK = "ML-ASK"
Self.EVENT_MASTERLOOT_OFFER = "ML-OFFER"
Self.EVENT_MASTERLOOT_ACK = "ML-ACK"
Self.EVENT_MASTERLOOT_DEC = "ML-DEC"
Self.EVENTS = {Self.EVENT_CHECK, Self.EVENT_VERSION, Self.EVENT_ENABLE, Self.EVENT_DISABLE, Self.EVENT_SYNC, Self.EVENT_ROLL_STATUS, Self.EVENT_BID, Self.EVENT_BID_WHISPER, Self.EVENT_VOTE, Self.EVENT_INTEREST, Self.EVENT_MASTERLOOT_ASK, Self.EVENT_MASTERLOOT_OFFER, Self.EVENT_MASTERLOOT_ACK, Self.EVENT_MASTERLOOT_DEC}

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
    return Util.In(event, Self.EVENTS) and Self.PREFIX .. event or event
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

-- Check if initializing chat on given channel and to giver target is enabled
function Self.ShouldInitChat(target)
    local channel, unit = Self.GetDestination(target)
    local c = Addon.db.profile.messages

    -- Check group
    if not IsInGroup() or Addon:GetNumAddonUsers(true) + 1 == GetNumGroupMembers() then
        return false
    end

    -- Check whisper options
    if channel == Self.TYPE_WHISPER then
        if not c.whisper.ask then
            return false
        elseif UnitIsDND(unit) or Addon:UnitIsTracking(unit) or Unit.IsSelf(unit) then
            return false
        end

        -- Check target
        local target = c.whisper.target
        local guild = Unit.GuildName(unit)
        local isGuild, isCommunity, isFriend = Unit.IsGuildMember(unit), Unit.IsClubMember(unit), Unit.IsFriend(unit)

        if isGuild or isCommunity or isFriend then
            if isGuild and not target.guild or isCommunity and not target.community or isFriend and not target.friend then
                return false
            end
        elseif not target.other then
            return false
        end
    -- Check group options
    elseif not c.group.announce then
        return false
    end

    -- Check group type options
    local group = channel == Self.TYPE_WHISPER and c.whisper.groupType or c.group.groupType

    if IsInRaid(LE_PARTY_CATEGORY_INSTANCE) then
        return group.lfr
    elseif IsInGroup(LE_PARTY_CATEGORY_INSTANCE) then
        return group.lfd
    elseif Util.IsGuildGroup(Unit.GuildName("player") or "") then
        return group.guild
    elseif Util.IsCommunityGroup() then
        return group.community
    elseif IsInRaid() then
        return group.raid
    else
        return group.party
    end
end

-- Check if we should use concise messages
function Self.ShouldBeConcise()
    return Addon.db.profile.messages.group.concise and Util.GetNumDroppedItems() <= 1
end

-- Send a chat line
function Self.Chat(msg, target)
    local channel, player = Self.GetDestination(target)

    if channel ~= Self.TYPE_WHISPER then
        msg = Util.StrPrefix(msg, Self.CHAT_PREFIX)
    end

    Addon:Debug("Comm.Chat", channel, player, msg)

    SendChatMessage(msg, channel, nil, player)
end

function Self.GetChatLine(line, target, ...)
    local L = Locale.GetCommLocale(select(2, Self.GetDestination(target)))
    line = Addon.db.profile.messages.lines[L.lang] and Addon.db.profile.messages.lines[L.lang][line] or L[line]
    return L(line, ...)
end

function Self.ChatLine(line, target, ...)
    Self.Chat(Self.GetChatLine(line, target, ...), target)
end

-- Send an addon message
function Self.Send(event, msg, target, prio, callbackFn, callbackArg)
    event = Self.GetPrefix(event)
    local channel, player = Self.GetDestination(target)

    -- TODO: This fixes a beta bug that causes a dc when sending empty strings
    msg = (not msg or msg == "") and " " or msg

    -- Send the message
    if Addon:IsEnabled() then
        Addon:SendCommMessage(event, msg, channel, player, prio, callbackFn, callbackArg)
    end
end

-- Send structured addon data
function Self.SendData(event, data, target, prio, callbackFn, callbackArg)
    -- print("OUT", event, data, target)
    Self.Send(event, Addon:Serialize(data), target, prio, callbackFn, callbackArg)
end

-- Listen for an addon message
function Self.Listen(event, method, fromSelf, fromAll)
    Addon:RegisterComm(Self.GetPrefix(event), function (event, msg, channel, sender)
        msg = msg ~= "" and msg ~= " " and msg or nil
        local unit = Unit(sender)
        if Addon:IsEnabled() and fromAll or Unit.InGroup(unit, not fromSelf) then
            method(event, msg, channel, sender, unit)
        end
    end)
end

-- Listen for an addon message with data
function Self.ListenData(event, method, fromSelf, fromAll)
    Self.Listen(event, function (event, data, ...)
        local success, data = Addon:Deserialize(data)
        if success then
            -- print("IN", event, data)
            method(event, data, ...)
        end
    end, fromSelf, fromAll)
end

-------------------------------------------------------
--                   Chat messages                   --
-------------------------------------------------------

function Self.RollAdvertise(roll, i)
    if not roll.item.isOwner then
        Self.ChatLine("MSG_ROLL_START_MASTERLOOT", Self.TYPE_GROUP, roll.item.link, roll.item.owner, 100 + i)
    elseif Self.ShouldBeConcise() then
        Self.ChatLine("MSG_ROLL_START_CONCISE", Self.TYPE_GROUP, roll.item.link)
    else
        Self.ChatLine("MSG_ROLL_START", Self.TYPE_GROUP, roll.item.link, 100 + i)
    end
end

-- BID

-- Messages when bidding on a roll
function Self.RollBid(roll, bid, fromUnit, randomRoll, isImport)
    local L = LibStub("AceLocale-3.0"):GetLocale(Name)
    local fromSelf = Unit.IsSelf(fromUnit)
    
    -- Show a confirmation message
    if fromSelf then
        if bid == Roll.BID_PASS then
            Addon:Echo(isImport and Addon.ECHO_DEBUG or Addon.ECHO_VERBOSE, L["BID_PASS"], (roll.item and roll.item.link) or L["ITEM"], Self.GetPlayerLink(roll.item.owner))
        else
            Addon:Echo(isImport and Addon.ECHO_DEBUG or Addon.ECHO_VERBOSE, L["BID_START"], roll:GetBidName(bid), (roll.item and roll.item.link) or L["ITEM"], Self.GetPlayerLink(roll.item.owner))
        end
    end

    if not isImport and not roll.isTest then
        -- Inform others
        if roll.isOwner then
            local data = Util.TblHash("ownerId", roll.ownerId, "bid", bid, "roll", randomRoll, "fromUnit", Unit.FullName(fromUnit))

            -- Send to all or the council
            if Util.Check(Session.GetMasterlooter(), Session.rules.bidPublic, Addon.db.profile.bidPublic) then
                Self.SendData(Self.EVENT_BID, data)
            elseif Session.IsMasterlooter() then
                for target,_ in pairs(Session.rules.council or {}) do
                    Self.SendData(Self.EVENT_BID, data, target)
                end
            end

            Util.TblRelease(data)
        -- Send bid to owner
        elseif fromSelf then
            if roll.ownerId then
                Self.SendData(Self.EVENT_BID, Util.TblHash("ownerId", roll.ownerId, "bid", bid), roll.owner)
            elseif bid ~= Roll.BID_PASS and not roll:GetOwnerAddon() then
                local owner, link = roll.item.owner, roll.item.link

                -- Roll on it in chat
                if roll.posted then
                    if Addon.db.profile.messages.group.roll and Addon.lastPostedRoll == roll then
                        RandomRoll("1", floor(bid) == Roll.BID_GREED and "50" or "100")
                    end
                -- Whisper the owner
                elseif Addon.db.profile.messages.whisper.ask then
                    if roll.whispers >= Self.MAX_WHISPERS then
                        Addon:Info(L["BID_MAX_WHISPERS"], Self.GetPlayerLink(owner), link, Self.MAX_WHISPERS, Self.GetTradeLink(owner))
                    elseif not Self.ShouldInitChat(owner) then
                        Addon:Info(L["BID_NO_CHAT"], Self.GetPlayerLink(owner), link, Self.GetTradeLink(owner))
                    else
                        Self.ChatLine("MSG_BID_" .. random(Addon.db.profile.messages.whisper.variants and 5 or 1), owner, link or Locale.GetChatLine('MSG_ITEM', owner))
                        roll.whispers = roll.whispers + 1

                        Addon:Info(L["BID_CHAT"], Self.GetPlayerLink(owner), link, Self.GetTradeLink(owner))
                        Self.SendData(Self.EVENT_BID_WHISPER, {owner = Unit.FullName(owner), link = link})
                    end
                end
            end
        end
    end
end

-- VOTE

-- Messages when voting on a roll
function Self.RollVote(roll, vote, fromUnit, isImport)
    local fromSelf = Unit.IsSelf(fromUnit)

    -- Inform others
    if not isImport and not roll.isTest then
        if roll.isOwner then
            local data = Util.TblHash("ownerId", roll.ownerId, "vote", Unit.FullName(vote), "fromUnit", Unit.FullName(fromUnit))

            -- Send to all or the council
            if Session.rules.votePublic then
                Self.SendData(Self.EVENT_VOTE, data)
            elseif Session.IsMasterlooter() then
                for target,_ in pairs(Session.rules.council or {}) do
                    Self.SendData(Self.EVENT_VOTE, data, target)
                end
            end

            Util.TblRelease(data)
        elseif fromSelf then
            -- Send to owner
            Self.SendData(Self.EVENT_VOTE, Util.TblHash("ownerId", roll.ownerId, "vote", Unit.FullName(vote)), Session.GetMasterlooter())
        end
    end
end

-- END

-- Messages when ending a roll
function Self.RollEnd(roll)
    local L = LibStub("AceLocale-3.0"):GetLocale(Name)

    -- We won the item
    if roll.isWinner then
        if Session.GetMasterlooter() or not (roll.item.isOwner and roll.bid and floor(roll.bid) == Roll.BID_NEED) then
            if roll.item.isOwner then
                Addon:Info(L["ROLL_WINNER_OWN"], roll.item.link)
            else
                Addon:Info(L["ROLL_WINNER_SELF"], roll.item.link, Self.GetPlayerLink(roll.item.owner), Self.GetTradeLink(roll.item.owner))
            end

            roll:ShowAlertFrame()
        end

    -- Someone won our item
    elseif roll.winner then
        if roll.item.isOwner then
            Addon:Info(L["ROLL_WINNER_OTHER"], Self.GetPlayerLink(roll.winner), roll.item.link, Self.GetTradeLink(roll.winner))
        elseif roll.isOwner then
            Addon:Info(L["ROLL_WINNER_MASTERLOOT"], Self.GetPlayerLink(roll.winner), roll.item.link, Self.GetPlayerLink(roll.item.owner))
        end

        if roll.isOwner and not roll.isTest then
            local line = roll.bids[roll.winner] == Roll.BID_DISENCHANT and "DISENCHANT" or "WINNER"
            local concise = line == "WINNER" and Self.ShouldBeConcise()

            -- Announce to chat
            local toGroup = roll.posted and Self.ShouldInitChat()
            if toGroup then
                if not roll.item.isOwner then
                    Self.ChatLine("MSG_ROLL_" .. line .. "_MASTERLOOT", Self.TYPE_GROUP, Unit.FullName(roll.winner), roll.item.link, Unit.FullName(roll.item.owner), Locale.Gender(roll.item.owner, "MSG_HER", "MSG_HIM"))
                elseif concise then
                    Self.ChatLine("MSG_ROLL_WINNER_CONCISE", Self.TYPE_GROUP, Unit.ShortName(roll.winner))
                else
                    Self.ChatLine("MSG_ROLL_" .. line, Self.TYPE_GROUP, Unit.FullName(roll.winner), roll.item.link)
                end
            end
            
            -- Announce to target
            if Addon.db.profile.messages.whisper.answer and not Addon:UnitIsTracking(roll.winner, true) and not (toGroup and concise) then
                if roll.item:GetNumEligible(true) == 1 then
                    if roll.item.isOwner then
                        Self.ChatLine("MSG_ROLL_ANSWER_YES", roll.winner)
                    else
                        Self.ChatLine("MSG_ROLL_ANSWER_YES_MASTERLOOT", roll.winner, roll.item.owner)
                    end
                else
                    if not roll.item.isOwner then
                        Self.ChatLine("MSG_ROLL_" .. line .. "_WHISPER_MASTERLOOT", roll.winner, roll.item.link, Unit.FullName(roll.item.owner), Locale.Gender(roll.item.owner, "MSG_HER", "MSG_HIM"))
                    elseif concise then
                        Self.ChatLine("MSG_ROLL_WINNER_WHISPER_CONCISE", roll.winner)
                    else
                        Self.ChatLine("MSG_ROLL_" .. line .. "_WHISPER", roll.winner, roll.item.link)
                    end
                end
            end
        end
    end
end

-------------------------------------------------------
--                       Helper                      --
-------------------------------------------------------

function Self.GetPlayerLink(unit)
    local color = Unit.Color(unit)
    return ("|c%s|Hplayer:%s|h<%s>|h|r"):format(color.colorStr, unit, unit)
end

function Self.GetTradeLink(unit)
    return ("|cff4D85E6|Hplrtrade:%s|h[%s]|h|r"):format(unit, TRADE)
end

function Self.GetBidLink(roll, unit, bid)
    local L = LibStub("AceLocale-3.0"):GetLocale(Name)
    return ("|cff4D85E6|Hplrbid:%d:%s:%d|h[%s]|h|r"):format(roll.id, unit, bid, L["ROLL_BID_" .. bid])
end

function Self.GetTooltipLink(text, title, abbr)
    abbr = abbr and Self.EscapeString(abbr) or Util.StrAbbr(Self.EscapeString(text), 15)
    text = Self.EscapeString(text, true)
    title = Self.EscapeString(title or "", true)
    return ("|cff4D85E6|Hplrtooltip:%s:%s|h[%s]|h|r"):format(title, text, abbr)
end
 
function Self.EscapeString(str, isLinkParam)
    str = str:gsub("|H.-|h(.-)|h", "%1")
    
    if isLinkParam then
        return str:gsub(":", "@c@"):gsub("|", "@b@")
    else
        return str:gsub("|c%w%w%w%w%w%w%w%w(.-)|r", "%1")
    end
end
 
function Self.UnescapeString(str)
    return str:gsub("@c@", ":"):gsub("@b@", "|")
end