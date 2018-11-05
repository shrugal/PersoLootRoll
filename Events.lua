local Name, Addon = ...
local L = LibStub("AceLocale-3.0"):GetLocale(Name)
local Comm, GUI, Item, Locale, Session, Roll, Unit, Util = Addon.Comm, Addon.GUI, Addon.Item, Addon.Locale, Addon.Session, Addon.Roll, Addon.Unit, Addon.Util
local Self = Addon

-- Message patterns
Self.PATTERN_BONUS_LOOT = LOOT_ITEM_BONUS_ROLL:gsub("%%s", ".+")
Self.PATTERN_ROLL_RESULT = RANDOM_ROLL_RESULT:gsub("%(", "%%("):gsub("%)", "%%)"):gsub("%%%d%$", "%%"):gsub("%%s", "(.+)"):gsub("%%d", "(%%d+)")

-- Version check
Self.VERSION_CHECK_DELAY = 5
-- Bids via whisper are ignored if we chatted after this many seconds BEFORE the roll started or AFTER the last one ended (max of the two)
Self.CHAT_MARGIN_BEFORE = 300
Self.CHAT_MARGIN_AFTER = 30

-- Remember the last item link posted in group chat so we can track random rolls
Self.lastPostedRoll = nil
-- Remember the last time a version check happened
Self.lastVersionCheck = nil
-- Remember the last time we chatted with someone and what roll (if any) we chatted about, so we know when to respond
Self.lastChatted = {}
Self.lastChattedRoll = {}
-- Remember the last suppressed message
Self.lastSuppressed = nil
-- Remember the last locked item slot
Self.lastLocked = {}
-- Remember the bag of the last looted item
Self.lastLootedBag = nil

-- Register

function Self.RegisterEvents()
    -- Roster
    Self:RegisterEvent("GROUP_JOINED")
    Self:RegisterEvent("GROUP_LEFT")
    Self:RegisterEvent("RAID_ROSTER_UPDATE")
    -- Chat
    Self:RegisterEvent("CHAT_MSG_SYSTEM")
    Self:RegisterEvent("CHAT_MSG_LOOT")
    Self:RegisterEvent("CHAT_MSG_PARTY", "CHAT_MSG_GROUP")
    Self:RegisterEvent("CHAT_MSG_PARTY_LEADER", "CHAT_MSG_GROUP")
    Self:RegisterEvent("CHAT_MSG_RAID", "CHAT_MSG_GROUP")
    Self:RegisterEvent("CHAT_MSG_RAID_LEADER", "CHAT_MSG_GROUP")
    Self:RegisterEvent("CHAT_MSG_RAID_WARNING", "CHAT_MSG_GROUP")
    Self:RegisterEvent("CHAT_MSG_INSTANCE_CHAT", "CHAT_MSG_GROUP")
    Self:RegisterEvent("CHAT_MSG_INSTANCE_CHAT_LEADER", "CHAT_MSG_GROUP")
    ChatFrame_AddMessageEventFilter("CHAT_MSG_WHISPER", Self.CHAT_MSG_WHISPER_FILTER)
    ChatFrame_AddMessageEventFilter("CHAT_MSG_WHISPER_INFORM", Self.CHAT_MSG_WHISPER_INFORM_FILTER)
    -- Item
    Self:RegisterEvent("ITEM_PUSH")
    Self:RegisterEvent("ITEM_LOCKED")
    Self:RegisterEvent("ITEM_UNLOCKED")
    Self:RegisterEvent("BAG_UPDATE_DELAYED")
end

-------------------------------------------------------
--                      Roster                       --
-------------------------------------------------------

function Self.GROUP_JOINED()
    Self:OnTrackingChanged(true)
end

function Self.GROUP_LEFT()
    -- Stop tracking process
    Self:OnTrackingChanged(true)

    -- Clear versions and disabled
    wipe(Self.versions)
    wipe(Self.disabled)
    wipe(Self.compAddonUsers)

    -- Clear lastXYZ stuff
    Self.lastPostedRoll = nil
    Self.lastVersionCheck = nil
    Self.lastSuppressed = nil
    wipe(Self.lastChatted)
    wipe(Self.lastChattedRoll)
end

function Self.RAID_ROSTER_UPDATE()
    Self:OnTrackingChanged()
end

-------------------------------------------------------
--                   Chat message                    --
-------------------------------------------------------

-- System

function Self.CHAT_MSG_SYSTEM(_, _, msg)
    if not Self:IsTracking() then return end

    -- Check if a player rolled
    do
        local unit, result, from, to = msg:match(Self.PATTERN_ROLL_RESULT)
        if unit and result and from and to then
            -- The roll result is the first return value in some locales
            if tonumber(unit) then
                unit, result, from, to = result, tonumber(unit), tonumber(from), tonumber(to)
            else
                result, from, to = tonumber(result), tonumber(from), tonumber(to)
            end
            
            Self:Debug("Events.RandomRoll", unit, result, from, to, msg)

            -- Rolls lower than 50 will screw with the result scaling
            if not (unit and result and from and to) or to < 50 then
                Self:Debug("Events.RandomRoll.Ignore")
                return
            end

            -- We don't get the full names for x-realm players
            if not UnitExists(unit) then
                for i=1,GetNumGroupMembers() do
                    local unitGroup = GetRaidRosterInfo(i)
                    if unitGroup and Util.StrStartsWith(unitGroup, unit) then
                        unit = unitGroup break
                    end
                end

                if not UnitExists(unit) then
                    Self:Debug("Events.RandomRoll.UnitNotFound", unit)
                    return
                end
            end
            
            -- Find the roll
            local i, roll = to % 50
            if i == 0 then
                roll = Self.lastPostedRoll
            else
                roll = Util.TblFirstWhere(Self.rolls, "status", Roll.STATUS_RUNNING, "posted", i)
            end

            
            -- Get the correct bid and scaled roll result
            local bid = to < 100 and Roll.BID_GREED or Roll.BID_NEED
            result = Util.NumRound(result * 100 / to)
            
            -- Register the unit's bid
            if roll and (roll.isOwner or Unit.IsSelf(unit)) and roll:UnitCanBid(unit, bid) then
                Self:Debug("Events.RandomRoll.Bid", bid, result, roll)
                roll:Bid(bid, unit, result)
            else
                Self:Debug("Events.RandomRoll.Reject", bid, result, roll and (roll.isOwner or Unit.IsSelf(unit)), roll and roll:UnitCanBid(unit, bid), roll)
            end

            return
        end
    end

    -- Check if a player left the group/raid
    for _,pattern in pairs(Comm.PATTERNS_LEFT) do
        local unit = msg:match(pattern)
        if unit then
            -- Clear rolls
            for id, roll in pairs(Self.rolls) do
                if roll.owner == unit or roll.item.owner == unit then
                    roll:Clear()
                elseif roll:CanBeWon(true) then
                    -- Remove from eligible list
                    if roll.item.eligible then
                        roll.item.eligible[unit] = nil
                    end

                    roll.bids[unit] = nil
                    if roll:ShouldEnd() then
                        roll:End()
                    end
                end
            end

            -- Clear version and disabled
            Self:SetVersion(unit, nil)
            return
        end
    end
end

-- Loot

function Self.CHAT_MSG_LOOT(_, _, msg, _, _, _, sender)
    local unit = Unit(sender)
    if not Self:IsTracking() or not Unit.InGroup(unit) or not Unit.IsSelf(unit) and Self:UnitIsTracking(unit, true) then return end

    local item = Item.GetLink(msg)

    if not msg:match(Self.PATTERN_BONUS_LOOT) and Item.ShouldBeChecked(item, unit) then
        Self:Debug("Event.Loot", item, unit, Unit.IsSelf(unit), msg)

        item = Item.FromLink(item, unit)

        if item.isOwner then
            item:SetPosition(Self.lastLootedBag, 0)

            local owner = Session.GetMasterlooter() or unit
            local isOwner = Unit.IsSelf(owner)

            item:OnFullyLoaded(function ()
                if isOwner and item:ShouldBeRolledFor() then
                    Self:Debug("Events.Loot.Start", owner)
                    Roll.Add(item, owner):Start()
                elseif not Self.db.profile.dontShare and item:GetFullInfo().isTradable then
                    Self:Debug("Events.Loot.Status", owner, isOwner)
                    local roll = Roll.Add(item, owner)
                    if isOwner then
                        roll:Schedule()
                    end
                    roll:SendStatus(true)
                else
                    Self:Debug("Events.Loot.Cancel", Self.db.profile.dontShare, owner, isOwner, unit, item.isOwner, item:HasSufficientQuality(), item:GetBasicInfo().isEquippable, item:GetFullInfo().isTradable, item:GetNumEligible(true))
                    Roll.Add(item, unit):Cancel()
                end
            end)
        elseif not Roll.Find(nil, nil, item, nil, unit) then
            Self:Debug("Events.Loot.Schedule")
            Roll.Add(item, unit):Schedule()
        else
            Self:Debug("Events.Loot.Duplicate")
        end
    end
end

-- Group/Raid/Instance

function Self.CHAT_MSG_GROUP(_, _, msg, sender)
    local unit = Unit(sender)
    if not Self:IsTracking() then return end

    local link = Item.GetLink(msg)
    if link then
        link = Item.GetInfo(link, "link") or link
        Self.lastPostedRoll = nil

        local roll = Roll.Find(nil, unit, link, nil, nil, Roll.STATUS_RUNNING) or Roll.Find(nil, unit, link)
        if roll then
            -- Remember the last roll posted to chat
            Self.lastPostedRoll = roll

            if not roll.ownerId then
                -- Roll for the item in chat
                if not roll.posted and Self.db.profile.messages.group.roll and roll.bid and Util.In(floor(roll.bid), Roll.BID_NEED, Roll.BID_GREED) then
                    RandomRoll("1", floor(roll.bid) == Roll.BID_GREED and "50" or "100")
                end

                -- Remember that the roll has been posted
                roll.posted = roll.posted or true
            end
        end
    end
end

-- Whisper

function Self.CHAT_MSG_WHISPER_FILTER(_, _, msg, sender, _, _, _, _, _, _, _, _, lineId)
    local unit = Unit(sender)
    if not Self:IsTracking() or not Unit.InGroup(unit) then return end

    -- Log the conversation
    for i,roll in pairs(Self.rolls) do
        if roll:IsRecent() and unit == roll:GetActionTarget() then
            Self:Debug("Events.Whisper", roll.id, unit, lineId)

            roll:AddChat(msg, unit)
        end
    end

    -- Don't act on whispers from other addon users
    if Self:IsTracking(unit) then return end

    local answer, suppress
    local lastEnded, firstStarted, running, recent, roll = 0
    local link = select(2, GetItemInfo(Item.GetLink(msg) or ""))

    -- Find eligible rolls
    if link then
        roll = Roll.Find(nil, nil, link)
    else
        -- Find running or recent rolls and determine firstStarted and lastEnded
        for i,roll in pairs(Self.rolls) do
            if roll:CanBeAwardedTo(unit, true) and (roll.status == Roll.STATUS_RUNNING or roll:IsRecent(Self.CHAT_MARGIN_AFTER)) then
                firstStarted = min(firstStarted or time(), roll.started)

                if roll.status == Roll.STATUS_RUNNING then
                    if not running then running = roll else running = true end
                else
                    if not recent then recent = roll else recent = true end
                end
            end
                
            if roll.status == Roll.STATUS_DONE and (roll.isOwner and roll.item:GetEligible(unit) or roll.owner == unit) then
                lastEnded = max(lastEnded, roll.ended + Self.CHAT_MARGIN_AFTER)
            end
        end

        roll = running or recent
    end

    if roll then
        -- Check if we should act on the whisper
        if not link and Self.lastChatted[unit] and Self.lastChatted[unit] > min(firstStarted, max(lastEnded, firstStarted - Self.CHAT_MARGIN_BEFORE)) then
            if roll ~= true and Self.lastChattedRoll[unit] ~= roll.id and roll:CanBeAwardedTo(unit) and not roll.bids[unit] then
                Self:Info(L["ROLL_IGNORING_BID"], Comm.GetPlayerLink(unit), roll.item.link, Comm.GetBidLink(roll, unit, Roll.BID_NEED), Comm.GetBidLink(roll, unit, Roll.BID_GREED))
            end
        else
            -- Ask for the item link if there is more than one roll right now
            if roll == true then
                answer = Comm.GetChatLine("MSG_ROLL_ANSWER_AMBIGUOUS", unit)
            -- The item is not tradable
            elseif not roll.item.isTradable then
                answer = Comm.GetChatLine("MSG_ROLL_ANSWER_NOT_TRADABLE", unit)
            -- I need it for myself
            elseif roll.status == Roll.STATUS_CANCELED or roll.isWinner then
                answer = Comm.GetChatLine("MSG_ROLL_ANSWER_NO_SELF", unit)
            -- Someone else won or got it
            elseif roll.winner and roll.winner ~= unit or roll.traded and roll.traded ~= unit then
                answer = Comm.GetChatLine("MSG_ROLL_ANSWER_NO_OTHER", unit)
            else
                -- The roll is scheduled or happening
                if roll:CanBeAwarded() then
                    -- He is eligible, so register the bid
                    if roll:UnitIsEligible(unit) and not roll.bids[unit] or floor(roll.bids[unit]) ~= Roll.BID_NEED then
                        roll:Bid(Roll.BID_NEED, unit)

                        -- Answer only if his bid didn't end the roll
                        answer = roll:CanBeAwarded() and Comm.GetChatLine("MSG_ROLL_ANSWER_BID", unit, roll.item.link) or false
                    end
                -- He can have it
                elseif (not roll.winner or roll.winner == unit) and not roll.traded then
                    roll.winner = unit
                    answer = roll.item.isOwner and Comm.GetChatLine("MSG_ROLL_ANSWER_YES", unit) or Comm.GetChatLine("MSG_ROLL_ANSWER_YES_MASTERLOOT", unit, roll.item.owner)
                end
            end
            
            suppress = answer ~= nil and Self.db.profile.messages.whisper.suppress
            answer = Self.db.profile.messages.whisper.answer and answer
            
            -- Suppress the message and print an info message instead
            if suppress then
                Self:Info(L["ROLL_WHISPER_SUPPRESSED"],
                    Comm.GetPlayerLink(unit),
                    roll.item.link,
                    Comm.GetTooltipLink(msg, L["MESSAGE"], L["MESSAGE"]),
                    answer and Comm.GetTooltipLink(answer, L["ANSWER"], L["ANSWER"]) or L["ANSWER"] .. ": -"
                )
                Self.lastSuppressed = answer and lineId or nil
            end

            -- Post the answer
            if answer then Comm.Chat(answer, unit) end
        end

        Self.lastChattedRoll[unit] = roll.id
    end
    
    Self.lastChatted[unit] = time()

    return suppress
end

function Self.CHAT_MSG_WHISPER_INFORM_FILTER(_, _, msg, receiver, _, _, _, _, _, _, _, _, lineId)
    local unit = Unit(receiver)
    if not Self:IsTracking() or not Unit.InGroup(unit) then return end

    -- Log the conversation
    for i,roll in pairs(Self.rolls) do
        if roll:IsRecent() and unit == roll:GetActionTarget() then
            Self:Debug("Events.WhisperInform", roll.id, unit, lineId)
            roll:AddChat(msg)
        end
    end

    Self.lastChatted[Unit.Name(receiver)] = time()

    return Self.lastSuppressed and Self.lastSuppressed + 1 == lineId or nil
end

-------------------------------------------------------
--                       Item                        --
-------------------------------------------------------

function Self.ITEM_PUSH(_, _, bagId)
    Self.lastLootedBag = bagId == 0 and 0 or (bagId - CharacterBag0Slot:GetID() + 1)
end

function Self.ITEM_LOCKED(_, _, bagOrEquip, slot)
    tinsert(Self.lastLocked, {bagOrEquip, slot})
end

function Self.ITEM_UNLOCKED(_, _, bagOrEquip, slot)
    local pos = {bagOrEquip, slot}
    
    if #Self.lastLocked == 1 and not Util.TblEquals(pos, Self.lastLocked[1]) then
        -- The item has been moved
        local from, to = Self.lastLocked[1], pos

        for i,roll in pairs(Addon.rolls) do
            if roll.item.isOwner and not roll.traded then
                if Util.TblEquals(from, roll.item.position) then
                    roll.item:SetPosition(to)
                    break
                end
            end
        end
    elseif #Self.lastLocked == 2 then
        -- The item has switched places with another
        local pos1, pos2 = Self.lastLocked[1], Self.lastLocked[2]
        local item1, item2

        for i,roll in pairs(Addon.rolls) do
            if not item1 and Util.TblEquals(pos1, roll.item.position) then
                item1 = roll.item
            elseif not item2 and Util.TblEquals(pos2, roll.item.position) then
                item2 = roll.item
            end
            if item1 and item2 then
                break
            end
        end
    
        if item1 then item1:SetPosition(pos2) end
        if item2 then item2:SetPosition(pos1) end
    end

    wipe(Self.lastLocked)
end

function Self.BAG_UPDATE_DELAYED()
    for i, entry in pairs(Item.queue) do
        Self:CancelTimer(entry.timer)
        entry.fn(unpack(entry.args))
    end
    wipe(Item.queue)
end

-------------------------------------------------------
--                   Addon message                   --
-------------------------------------------------------

-- Check
Comm.ListenData(Comm.EVENT_CHECK, function (event, data, channel, sender, unit)
    if not Self.lastVersionCheck or Self.lastVersionCheck + Self.VERSION_CHECK_DELAY < GetTime() then
        Self.lastVersionCheck = GetTime()

        if Self.timers.versionCheck then
            Self:CancelTimer(Self.timers.versionCheck)
            Self.timers.versionCheck = nil
        end

        local target = channel == Comm.TYPE_WHISPER and sender or channel

        -- Send version
        Comm.SendData(Comm.EVENT_VERSION, Self.VERSION, target)
        
        -- Send disabled state
        if not Addon.db.profile.enabled then
            Comm.Send(Comm.EVENT_DISABLE, target)
        end
    end
end, true)

-- Version
Comm.ListenData(Comm.EVENT_VERSION, function (event, version, channel, sender, unit)
    Self:SetVersion(unit, version)
end)

-- Enable/Disable
Comm.Listen(Comm.EVENT_ENABLE, function (event, _, _, _, unit) Self.disabled[unit] = nil end, true)
Comm.Listen(Comm.EVENT_DISABLE, function (event, _, _, _, unit) Self.disabled[unit] = true end, true)

-- Sync
Comm.Listen(Comm.EVENT_SYNC, function (event, msg, channel, sender, unit)
    -- Reset all owner ids and bids for the unit's rolls and items, because he/she doesn't know them anymore
    for id, roll in pairs(Self.rolls) do
        if roll.owner == unit then
            roll.ownerId = nil

            if roll.status == Roll.STATUS_RUNNING then
                roll:Restart(roll.started)
            elseif roll.status < Roll.STATUS_DONE then
                roll.bid = nil
            end
        end
        if roll.item.owner == unit then
            roll.itemOwnerId = nil
        end
    end

    if Self:IsTracking() then
        -- Send rolls for items that we own
        for _,roll in pairs(Self.rolls) do
            if roll.item.isOwner and not roll.traded and roll:UnitIsInvolved(unit) then
                roll:SendStatus(true, unit, roll.isOwner)
            end
        end

        -- As masterlooter we send another update a bit later to inform them about bids and votes
        if Session.IsMasterlooter() then
            Self:ScheduleTimer(function ()
                for _,roll in pairs(Self.rolls) do
                    if roll.isOwner and not roll.item.isOwner and not roll.traded and roll:UnitIsInvolved(unit) then
                        roll:SendStatus(nil, unit, true)
                    end
                end
            end, Roll.DELAY)
        end
    end
end)

-- Roll status
Comm.ListenData(Comm.EVENT_ROLL_STATUS, function (event, data, channel, sender, unit)
    if not Self:IsTracking() then return end

    data.owner = Unit.Name(data.owner)
    data.item.owner = Unit.Name(data.item.owner)
    data.winner = Unit.Name(data.winner)
    data.traded = data.traded and Unit.Name(data.traded)

    Roll.Update(data, unit)
end)

-- Bids
Comm.ListenData(Comm.EVENT_BID, function (event, data, channel, sender, unit)
    if not Self:IsTracking() then return end

    local isImport = data.fromUnit ~= nil
    local owner = isImport and unit or nil
    local fromUnit = data.fromUnit or unit

    local roll = Roll.Find(data.ownerId, owner)
    if roll then
        roll:Bid(data.bid, fromUnit, isImport and data.roll, isImport)
    end
end)
Comm.ListenData(Comm.EVENT_BID_WHISPER, function (event, item)
    if not Self:IsTracking() then return end

    local roll = Roll.Find(nil, nil, item)
    if roll then
        roll.whispers = roll.whispers + 1
    end
end)

-- Votes
Comm.ListenData(Comm.EVENT_VOTE, function (event, data, channel, sender, unit)
    if not Self:IsTracking() then return end

    local owner = data.fromUnit and unit or nil
    local fromUnit = data.fromUnit or unit
    
    local roll = Roll.Find(data.ownerId, owner)
    if roll then
        roll:Vote(data.vote, fromUnit, owner ~= nil)
    end
end)

-- Declaring interest
Comm.ListenData(Comm.EVENT_INTEREST, function (event, data, channel, sender, unit)
    if not Self:IsTracking() then return end

    local roll = Roll.Find(data.ownerId)
    if roll then
        roll.item:SetEligible(unit)
    end
end)