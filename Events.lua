local Name, Addon = ...
local L = LibStub("AceLocale-3.0"):GetLocale(Name)
local Comm, GUI, Inspect, Item, Locale, Session, Roll, Trade, Unit, Util = Addon.Comm, Addon.GUI, Addon.Inspect, Addon.Item, Addon.Locale, Addon.Session, Addon.Roll, Addon.Trade, Addon.Unit, Addon.Util
local Self = Addon.Events

-- Message patterns
Self.PATTERN_BONUS_LOOT = LOOT_ITEM_BONUS_ROLL:gsub("%%s", ".+")
Self.PATTERN_ROLL_RESULT = RANDOM_ROLL_RESULT:gsub("%(", "%%("):gsub("%)", "%%)"):gsub("%%%d%$", "%%"):gsub("%%s", "(.+)"):gsub("%%d", "(%%d+)")

-- Version check
Self.VERSION_CHECK_DELAY = 5
-- Bids via whisper are ignored if we chatted after this many seconds BEFORE the roll started or AFTER the last one ended (max of the two)
Self.CHAT_MARGIN_BEFORE = 300
Self.CHAT_MARGIN_AFTER = 30

-- Remember the last locked item slot
Self.lastLocked = {}
-- Remember the bag of the last looted item
Self.lastLootedBag = nil
-- Remember the last item link posted in group chat so we can track random rolls
Self.lastPostedRoll = nil
-- Remember the last time a version check happened
Self.lastVersionCheck = nil
-- Remember the last time we chatted with someone and what roll (if any) we chatted about, so we know when to respond
Self.lastChatted = {}
Self.lastChattedRoll = {}
-- Remember the last suppressed message
Self.lastSuppressed = nil

-------------------------------------------------------
--                      Roster                       --
-------------------------------------------------------

function Self.GROUP_JOINED()
    -- Schedule version check
    Addon.timers.versionCheck = Addon:ScheduleTimer(function ()
        Comm.SendData(Comm.EVENT_CHECK)
    end, Self.VERSION_CHECK_DELAY)

    -- Discover PLH users
    Comm.SendPlh(Comm.PLH_ACTION_CHECK, nil, Unit.FullName("player"))
    
    -- Restore or ask for masterlooter
    Session.Restore()

    -- Start tracking process
    Addon:OnTrackingChanged(true)
end

function Self.GROUP_LEFT()
    -- Stop tracking process
    Addon:OnTrackingChanged(true)

    -- Clear masterlooter
    Session.SetMasterlooter(nil)
    wipe(Session.masterlooting)

    -- Clear versions and disabled
    wipe(Addon.versions)
    wipe(Addon.disabled)
    wipe(Addon.plhUsers)

    -- Clear lastXYZ stuff
    Self.lastPostedRoll = nil
    Self.lastVersionCheck = nil
    Self.lastSuppressed = nil
    wipe(Self.lastChatted)
    wipe(Self.lastChattedRoll)
end

function Self.PARTY_MEMBER_ENABLE(event, unit)
    if Addon:IsTracking() then Inspect.Queue(unit) end
end

function Self.RAID_ROSTER_UPDATE()
    Addon:OnTrackingChanged()
end

-------------------------------------------------------
--                     Inspect                       --
-------------------------------------------------------

function Self.INSPECT_READY(event, guid)
    local _, _, _, _, _, name, realm = GetPlayerInfoByGUID(guid)
    local unit = realm and realm ~= "" and name .. "-" .. realm or name
    Inspect.OnInspectReady(unit)
end

-------------------------------------------------------
--                      Items                        --
-------------------------------------------------------

function Self.ITEM_PUSH(event, bagId)
    Self.lastLootedBag = bagId == 0 and 0 or (bagId - CharacterBag0Slot:GetID() + 1)
end

function Self.ITEM_LOCKED(event, bagOrEquip, slot)
    tinsert(Self.lastLocked, {bagOrEquip, slot})
end

function Self.ITEM_UNLOCKED(event, bagOrEquip, slot)
    local pos = {bagOrEquip, slot}
    
    if #Self.lastLocked == 1 and not Util.TblEquals(pos, Self.lastLocked[1]) then
        -- The item has been moved
        Item.OnMove(Self.lastLocked[1], pos)
    elseif #Self.lastLocked == 2 then
        -- The item has switched places with another
        Item.OnSwitch(Self.lastLocked[1], Self.lastLocked[2])
    end

    wipe(Self.lastLocked)
end

function Self.BAG_UPDATE_DELAYED(event)
    for i, entry in pairs(Item.queue) do
        Addon:CancelTimer(entry.timer)
        entry.fn(unpack(entry.args))
    end
    wipe(Item.queue)
end

-------------------------------------------------------
--                   Chat message                    --
-------------------------------------------------------

-- System

function Self.CHAT_MSG_SYSTEM(event, msg)
    if not Addon:IsTracking() then return end

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
            
            Addon:Debug("Events.RandomRoll", unit, result, from, to, msg)

            -- Rolls lower than 50 will screw with the result scaling
            if not (unit and result and from and to) or to < 50 then
                Addon:Debug("Events.RandomRoll.Ignore")
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
                    Addon:Debug("Events.RandomRoll.UnitNotFound", unit)
                    return
                end
            end
            
            -- Find the roll
            local i, roll = to % 50
            if i == 0 then
                roll = Self.lastPostedRoll
            else
                roll = Util.TblFirstWhere(Addon.rolls, "status", Roll.STATUS_RUNNING, "posted", i)
            end

            
            -- Get the correct bid and scaled roll result
            local bid = to < 100 and Roll.BID_GREED or Roll.BID_NEED
            result = Util.NumRound(result * 100 / to)
            
            -- Register the unit's bid
            if roll and (roll.isOwner or Unit.IsSelf(unit)) and roll:UnitCanBid(unit, bid) then
                Addon:Debug("Events.RandomRoll.Bid", bid, result, roll)
                roll:Bid(bid, unit, result)
            else
                Addon:Debug("Events.RandomRoll.Reject", bid, result, roll and (roll.isOwner or Unit.IsSelf(unit)), roll and roll:UnitCanBid(unit, bid), roll)
            end

            return
        end
    end

    -- Check if a player joined the group/raid
    for _,pattern in pairs(Comm.PATTERNS_JOINED) do
        local unit = msg:match(pattern)
        if unit then
            -- Queue inspection
            Inspect.Queue(unit)
            return
        end
    end

    -- Check if a player left the group/raid
    for _,pattern in pairs(Comm.PATTERNS_LEFT) do
        local unit = msg:match(pattern)
        if unit then
            -- Clear rolls
            for id, roll in pairs(Addon.rolls) do
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

            -- Clear inspect cache
            Inspect.Clear(unit)

            -- Clear masterlooter
            if unit == Session.GetMasterlooter() then
                Session.SetMasterlooter(nil, nil, true)
            end
            Session.SetMasterlooting(unit, nil)
            Session.ClearMasterlooting(unit)

            -- Clear version and disabled
            Addon:SetVersion(unit, nil)
            return
        end
    end
end

-- Loot

function Self.CHAT_MSG_LOOT(event, msg, _, _, _, sender)
    local unit = Unit(sender)
    if not Addon:IsTracking() or not Unit.InGroup(unit) or not Unit.IsSelf(unit) and Addon:UnitIsTracking(unit, true) then return end

    local item = Item.GetLink(msg)

    if not msg:match(Self.PATTERN_BONUS_LOOT) and Item.ShouldBeChecked(item, unit) then
        Addon:Debug("Event.Loot", item, unit, Unit.IsSelf(unit), msg)

        item = Item.FromLink(item, unit)

        if item.isOwner then
            item:SetPosition(Self.lastLootedBag, 0)

            local owner = Session.GetMasterlooter() or unit
            local isOwner = Unit.IsSelf(owner)

            item:OnFullyLoaded(function ()
                if isOwner and item:ShouldBeRolledFor() then
                    Addon:Debug("Events.Loot.Start", owner)
                    Roll.Add(item, owner):Start()
                elseif not Addon.db.profile.dontShare and item:GetFullInfo().isTradable then
                    Addon:Debug("Events.Loot.Status", owner, isOwner)
                    local roll = Roll.Add(item, owner)
                    if isOwner then
                        roll:Schedule()
                    end
                    roll:SendStatus(true)
                else
                    Addon:Debug("Events.Loot.Cancel", Addon.db.profile.dontShare, owner, isOwner, unit, item.isOwner, item:HasSufficientQuality(), item:GetBasicInfo().isEquippable, item:GetFullInfo().isTradable, item:GetNumEligible(true))
                    Roll.Add(item, unit):Cancel()
                end
            end)
        elseif not Roll.Find(nil, nil, item, nil, unit) then
            Addon:Debug("Events.Loot.Schedule")
            Roll.Add(item, unit):Schedule()
        else
            Addon:Debug("Events.Loot.Duplicate")
        end
    end
end

-- Group/Raid/Instance

function Self.CHAT_MSG_GROUP(event, msg, sender)
    local unit = Unit(sender)
    if not Addon:IsTracking() then return end

    local link = Item.GetLink(msg)
    if link then
        Self.lastPostedRoll = nil

        local roll = Roll.Find(nil, unit, Item.GetInfo(link, "link") or link)
        if roll then
            -- Remember the last roll posted to chat
            Self.lastPostedRoll = roll

            if not roll.ownerId then
                -- Roll for the item in chat
                if not roll.posted and Addon.db.profile.messages.group.roll and roll.bid and Util.In(floor(roll.bid), Roll.BID_NEED, Roll.BID_GREED) then
                    RandomRoll("1", floor(roll.bid) == Roll.BID_GREED and "50" or "100")
                end

                -- Remember that the roll has been posted
                roll.posted = roll.posted or true
            end
        end
    end
end

-- Whisper

function Self.CHAT_MSG_WHISPER_FILTER(self, event, msg, sender, _, _, _, _, _, _, _, _, lineId)
    local unit = Unit(sender)
    if not Addon:IsTracking() or not Unit.InGroup(unit) then return end

    -- Log the conversation
    for i,roll in pairs(Addon.rolls) do
        if roll:IsRecent() and unit == roll:GetActionTarget() then
            Addon:Debug("Events.Whisper", roll.id, unit, lineId)

            roll:AddChat(msg, unit)
        end
    end

    -- Don't act on whispers from other addon users
    if Addon:IsTracking(unit) then return end

    local answer, suppress
    local lastEnded, firstStarted, running, recent, roll = 0
    local link = select(2, GetItemInfo(Item.GetLink(msg) or ""))

    -- Find eligible rolls
    if link then
        roll = Roll.Find(nil, nil, link)
    else
        -- Find running or recent rolls and determine firstStarted and lastEnded
        for i,roll in pairs(Addon.rolls) do
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
                Addon:Info(L["ROLL_IGNORING_BID"], Comm.GetPlayerLink(unit), roll.item.link, Comm.GetBidLink(roll, unit, Roll.BID_NEED), Comm.GetBidLink(roll, unit, Roll.BID_GREED))
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
            
            suppress = answer ~= nil and Addon.db.profile.messages.whisper.suppress
            answer = Addon.db.profile.messages.whisper.answer and answer
            
            -- Suppress the message and print an info message instead
            if suppress then
                Addon:Info(L["ROLL_WHISPER_SUPPRESSED"],
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

function Self.CHAT_MSG_WHISPER_INFORM_FILTER(self, event, msg, receiver, _, _, _, _, _, _, _, _, lineId)
    local unit = Unit(receiver)
    if not Addon:IsTracking() or not Unit.InGroup(unit) then return end

    -- Log the conversation
    for i,roll in pairs(Addon.rolls) do
        if roll:IsRecent() and unit == roll:GetActionTarget() then
            Addon:Debug("Events.WhisperInform", roll.id, unit, lineId)
            roll:AddChat(msg)
        end
    end

    Self.lastChatted[Unit.Name(receiver)] = time()

    return Self.lastSuppressed and Self.lastSuppressed + 1 == lineId or nil
end

-- Register

function Self.RegisterEvents()
    -- Roster
    Addon:RegisterEvent("GROUP_JOINED", Self.GROUP_JOINED)
    Addon:RegisterEvent("GROUP_LEFT", Self.GROUP_LEFT)
    Addon:RegisterEvent("PARTY_MEMBER_ENABLE", Self.PARTY_MEMBER_ENABLE)
    Addon:RegisterEvent("RAID_ROSTER_UPDATE", Self.RAID_ROSTER_UPDATE)
    -- Combat
    Addon:RegisterEvent("ENCOUNTER_START", Inspect.Stop)
    Addon:RegisterEvent("ENCOUNTER_END", Inspect.Start)
    -- Inspect
    Addon:RegisterEvent("INSPECT_READY", Self.INSPECT_READY)
    -- Trade
    Addon:RegisterEvent("TRADE_SHOW", Trade.Start)
    Addon:RegisterEvent("TRADE_PLAYER_ITEM_CHANGED", Trade.OnPlayerItem)
    Addon:RegisterEvent("TRADE_TARGET_ITEM_CHANGED", Trade.OnTargetItem)
    Addon:RegisterEvent("TRADE_CLOSED", Trade.OnClose)
    Addon:RegisterEvent("TRADE_REQUEST_CANCEL", Trade.Clear)
    -- Item
    Addon:RegisterEvent("ITEM_PUSH", Self.ITEM_PUSH)
    Addon:RegisterEvent("ITEM_LOCKED", Self.ITEM_LOCKED)
    Addon:RegisterEvent("ITEM_UNLOCKED", Self.ITEM_UNLOCKED)
    Addon:RegisterEvent("BAG_UPDATE_DELAYED", Self.BAG_UPDATE_DELAYED)
    -- Chat
    Addon:RegisterEvent("CHAT_MSG_SYSTEM", Self.CHAT_MSG_SYSTEM)
    Addon:RegisterEvent("CHAT_MSG_LOOT", Self.CHAT_MSG_LOOT)
    Addon:RegisterEvent("CHAT_MSG_PARTY", Self.CHAT_MSG_GROUP)
    Addon:RegisterEvent("CHAT_MSG_PARTY_LEADER", Self.CHAT_MSG_GROUP)
    Addon:RegisterEvent("CHAT_MSG_RAID", Self.CHAT_MSG_GROUP)
    Addon:RegisterEvent("CHAT_MSG_RAID_LEADER", Self.CHAT_MSG_GROUP)
    Addon:RegisterEvent("CHAT_MSG_RAID_WARNING", Self.CHAT_MSG_GROUP)
    Addon:RegisterEvent("CHAT_MSG_INSTANCE_CHAT", Self.CHAT_MSG_GROUP)
    Addon:RegisterEvent("CHAT_MSG_INSTANCE_CHAT_LEADER", Self.CHAT_MSG_GROUP)
    ChatFrame_AddMessageEventFilter("CHAT_MSG_WHISPER", Self.CHAT_MSG_WHISPER_FILTER)
    ChatFrame_AddMessageEventFilter("CHAT_MSG_WHISPER_INFORM", Self.CHAT_MSG_WHISPER_INFORM_FILTER)
end

function Self.UnregisterEvents()
    -- Roster
    Addon:UnregisterEvent("GROUP_JOINED")
    Addon:UnregisterEvent("GROUP_LEFT")
    Addon:UnregisterEvent("PARTY_MEMBER_ENABLE")
    Addon:UnregisterEvent("RAID_ROSTER_UPDATE")
    -- Combat
    Addon:UnregisterEvent("ENCOUNTER_START")
    Addon:UnregisterEvent("ENCOUNTER_END")
    -- Inspect
    Addon:UnregisterEvent("INSPECT_READY")
    Addon:UnregisterEvent("TRADE_SHOW")
    -- Trade
    Addon:UnregisterEvent("TRADE_PLAYER_ITEM_CHANGED")
    Addon:UnregisterEvent("TRADE_TARGET_ITEM_CHANGED")
    Addon:UnregisterEvent("TRADE_CLOSED")
    Addon:UnregisterEvent("TRADE_REQUEST_CANCEL")
    -- Item
    Addon:UnregisterEvent("ITEM_PUSH")
    Addon:UnregisterEvent("ITEM_LOCKED")
    Addon:UnregisterEvent("ITEM_UNLOCKED")
    Addon:UnregisterEvent("BAG_UPDATE_DELAYED")
    -- Chat
    Addon:UnregisterEvent("CHAT_MSG_SYSTEM")
    Addon:UnregisterEvent("CHAT_MSG_LOOT")
    Addon:UnregisterEvent("CHAT_MSG_PARTY")
    Addon:UnregisterEvent("CHAT_MSG_PARTY_LEADER")
    Addon:UnregisterEvent("CHAT_MSG_RAID")
    Addon:UnregisterEvent("CHAT_MSG_RAID_LEADER")
    Addon:UnregisterEvent("CHAT_MSG_RAID_WARNING")
    Addon:UnregisterEvent("CHAT_MSG_INSTANCE_CHAT")
    Addon:UnregisterEvent("CHAT_MSG_INSTANCE_CHAT_LEADER")
    ChatFrame_RemoveMessageEventFilter("CHAT_MSG_WHISPER", Self.CHAT_MSG_WHISPER_FILTER)
    ChatFrame_RemoveMessageEventFilter("CHAT_MSG_WHISPER_INFORM", Self.CHAT_MSG_WHISPER_INFORM_FILTER)
end

-------------------------------------------------------
--                   Addon message                   --
-------------------------------------------------------

-- Check
Comm.ListenData(Comm.EVENT_CHECK, function (event, data, channel, sender, unit)
    if not Self.lastVersionCheck or Self.lastVersionCheck + Self.VERSION_CHECK_DELAY < GetTime() then
        Self.lastVersionCheck = GetTime()

        if Addon.timers.versionCheck then
            Addon:CancelTimer(Addon.timers.versionCheck)
            Addon.timers.versionCheck = nil
        end

        local target = channel == Comm.TYPE_WHISPER and sender or channel

        -- Send version
        Comm.SendData(Comm.EVENT_VERSION, Addon.VERSION, target)
        
        -- Send disabled state
        if not Addon.db.profile.enabled then
            Comm.Send(Comm.EVENT_DISABLE, target)
        end
    end
end, true)

-- Version
Comm.ListenData(Comm.EVENT_VERSION, function (event, version, channel, sender, unit)
    Addon:SetVersion(unit, version)
end)

-- Enable/Disable
Comm.Listen(Comm.EVENT_ENABLE, function (event, _, _, _, unit) Addon.disabled[unit] = nil end, true)
Comm.Listen(Comm.EVENT_DISABLE, function (event, _, _, _, unit) Addon.disabled[unit] = true end, true)

-- Sync
Comm.Listen(Comm.EVENT_SYNC, function (event, msg, channel, sender, unit)
    -- Reset all owner ids and bids for the unit's rolls and items, because he/she doesn't know them anymore
    for id, roll in pairs(Addon.rolls) do
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

    if Addon:IsTracking() then
        -- Send rolls for items that we own
        for _,roll in pairs(Addon.rolls) do
            if roll.item.isOwner and not roll.traded and roll:UnitIsInvolved(unit) then
                roll:SendStatus(true, unit, roll.isOwner)
            end
        end

        -- As masterlooter we send another update a bit later to inform them about bids and votes
        if Session.IsMasterlooter() then
            Addon:ScheduleTimer(function ()
                for _,roll in pairs(Addon.rolls) do
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
    if not Addon:IsTracking() then return end

    data.owner = Unit.Name(data.owner)
    data.item.owner = Unit.Name(data.item.owner)
    data.winner = Unit.Name(data.winner)
    data.traded = data.traded and Unit.Name(data.traded)

    Roll.Update(data, unit)
end)

-- Bids
Comm.ListenData(Comm.EVENT_BID, function (event, data, channel, sender, unit)
    if not Addon:IsTracking() then return end

    local isImport = data.fromUnit ~= nil
    local owner = isImport and unit or nil
    local fromUnit = data.fromUnit or unit

    local roll = Roll.Find(data.ownerId, owner)
    if roll then
        roll:Bid(data.bid, fromUnit, isImport and data.roll, isImport)
    end
end)
Comm.ListenData(Comm.EVENT_BID_WHISPER, function (event, item)
    if not Addon:IsTracking() then return end

    local roll = Roll.Find(nil, nil, item)
    if roll then
        roll.whispers = roll.whispers + 1
    end
end)

-- Votes
Comm.ListenData(Comm.EVENT_VOTE, function (event, data, channel, sender, unit)
    if not Addon:IsTracking() then return end

    local owner = data.fromUnit and unit or nil
    local fromUnit = data.fromUnit or unit
    
    local roll = Roll.Find(data.ownerId, owner)
    if roll then
        roll:Vote(data.vote, fromUnit, owner ~= nil)
    end
end)

-- Declaring interest
Comm.ListenData(Comm.EVENT_INTEREST, function (event, data, channel, sender, unit)
    if not Addon:IsTracking() then return end

    local roll = Roll.Find(data.ownerId)
    if roll then
        roll.item:SetEligible(unit)
    end
end)

-- Masterlooter
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
--          Personal Loot Helper integration         --
-------------------------------------------------------

Comm.Listen(Comm.PLH_EVENT, function (event, msg, channel, _, unit)
    if not IsAddOnLoaded(Comm.PLH_NAME) then
        local action, itemId, owner, param = msg:match('^([^~]+)~([^~]+)~([^~]+)~?([^~]*)$')
        itemId = tonumber(itemId)
        owner = Unit(owner)
        local fromOwner = owner == unit

        if not Addon.versions[unit] then
            -- Check: Version check
            if action == Comm.PLH_ACTION_CHECK then
                Comm.SendPlh(Comm.PLH_ACTION_VERSION, Unit.FullName("player"), Comm.PLH_VERSION)
            -- Version: Answer to version check
            elseif action == Comm.PLH_ACTION_VERSION then
                Addon.plhUsers[unit] = param
            else
                local item = Item.IsLink(param) and param or itemId
                local roll = Roll.Find(nil, nil, item, nil, owner, Roll.STATUS_RUNNING) or Roll.Find(nil, nil, item, nil, owner)
                
                -- Trade: The owner offers the item up for requests
                if action == Comm.PLH_ACTION_TRADE and not roll and fromOwner and Item.IsLink(param) then
                    Addon:Debug("Events.PLH.Trade", itemId, owner, param, msg)
                    Roll.Add(param, owner):Start()
                elseif roll and (roll.isOwner or not roll.ownerId) then
                    -- Keep: The owner wants to keep the item
                    if action == Comm.PLH_ACTION_KEEP and fromOwner then
                        roll:End(owner)
                    -- Request: The sender bids on an item
                    elseif action == Comm.PLH_ACTION_REQUEST then
                        local bid = Util.Select(param, Comm.PLH_BID_NEED, Roll.BID_NEED, Comm.PLH_BID_DISENCHANT, Roll.BID_DISENCHANT, Roll.BID_GREED)
                        roll:Bid(bid, unit)
                    -- Offer: The owner has picked a winner
                    elseif action == Comm.PLH_ACTION_OFFER and fromOwner then
                        roll:End(param)
                    end
                end
            end
        end
    end
end)