local Name, Addon = ...
local L = LibStub("AceLocale-3.0"):GetLocale(Name)
local Comm, GUI, Inspect, Item, Locale, Masterloot, Roll, Trade, Unit, Util = Addon.Comm, Addon.GUI, Addon.Inspect, Addon.Item, Addon.Locale, Addon.Masterloot, Addon.Roll, Addon.Trade, Addon.Unit, Addon.Util
local Self = Addon.Events

-- Message patterns
Self.PATTERN_BONUS_LOOT = LOOT_ITEM_BONUS_ROLL:gsub("%%s", ".+")
Self.PATTERN_ROLL_RESULT = RANDOM_ROLL_RESULT:gsub("%(", "%%("):gsub("%)", "%%)"):gsub("%%s", "(.+)"):gsub("%%d", "(%%d+)")

-- Version check
Self.VERSION_CHECK_DELAY = 5

-- Remember the last locked item slot
Self.lastLocked = {}
-- Remember the bag of the last looted item
Self.lastLootedBag = nil
-- Remember the last item link posted in group chat so we can track random rolls
Self.lastPostedRoll = nil
-- Remember the last time a version check happened
Self.lastVersionCheck = nil
-- Remember the last time we chatted with someone, so we know when to respond
Self.lastChatted = {}

-------------------------------------------------------
--                      Roster                       --
-------------------------------------------------------

function Self.GROUP_JOINED(event)
    -- Send sync event
    Comm.Send(Comm.EVENT_SYNC)

    -- Restore or ask for masterlooter
    Masterloot.Restore()

    -- Schedule version check
    Addon.timers.versionCheck = Addon:ScheduleTimer(function ()
        Comm.SendData(Comm.EVENT_VERSION_ASK)
    end, Self.VERSION_CHECK_DELAY)
    
    -- Start inspecting
    Inspect.Queue()
    Inspect.Start()
end

function Self.GROUP_LEFT(event)
    -- Clear all rolls
    Util.TblIter(Addon.rolls, Roll.Clear)

    -- Stop inspecting
    Inspect.Clear()

    -- Clear masterlooter
    Masterloot.SetMasterlooter(nil)
    wipe(Masterloot.masterlooting)

    -- Clear versions
    wipe(Addon.versions)

    -- Clear lastXYZ stuff
    Self.lastPostedRoll = nil
    Self.lastVersionCheck = nil
    wipe(Self.lastChatted)
end

function Self.PARTY_MEMBER_ENABLE(event, unit)
    Inspect.Queue(unit)
    Inspect.Start()
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
    -- Check if a player rolled
    do
        local unit, result, from, to = msg:match(Self.PATTERN_ROLL_RESULT)
        if unit and result and from and to then
            result, from, to = tonumber(result), tonumber(from), tonumber(to)

            -- Rolls lower than 50 will screw with the result scaling
            if to < 50 then
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
                    return
                end
            end
            
            -- Find the roll
            local i, roll = to % 50
            if i == 0 then
                roll = Self.lastPostedRoll
            else
                roll = Util.TblFirstWhere(Addon.rolls, {status = Roll.STATUS_RUNNING, posted = i})
            end
            
            -- Get the correct bid and scaled roll result
            local bid = to < 100 and Roll.BID_GREED or Roll.BID_NEED
            result = result * 100 / to
            
            -- Register the unit's bid
            if Unit.InGroup(unit) and roll and (UnitIsUnit(unit, "player") and roll:CanBeWon(unit) or roll:CanBeAwardedTo(unit)) and not roll.bids[unit] then
                roll:Bid(bid, unit, result)
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
                    roll:CheckEnd()
                end
            end

            -- Clear inspect cache
            Inspect.Clear(unit)

            -- Clear masterlooter
            if unit == Masterloot.GetMasterlooter() then
                Masterloot.SetMasterlooter(nil, nil, true)
            end
            Masterloot.SetMasterlooting(unit, nil)
            Masterloot.ClearMasterlooting(unit)

            -- Clear version
            Addon:SetVersion(unit, nil)
            return
        end
    end
end

-- Loot

function Self.CHAT_MSG_LOOT(event, msg, _, _, _, sender)
    unit = Unit(sender)
    if not Addon:IsTracking() or not Unit.InGroup(unit) then return end

    local item = Item.GetLink(msg)

    if item and unit and Item.HasSufficientQuality(item) then
        item = Item.FromLink(item, unit)

        if item.isOwner then
            item:SetPosition(Self.lastLootedBag, 0)

            local owner = Masterloot.GetMasterlooter() or unit
            local isOwner = UnitIsUnit(owner, "player")

            item:OnFullyLoaded(function ()
                if isOwner and item:ShouldBeRolledFor() then
                    Roll.Add(item, owner):Start()
                elseif item.isEquippable then
                    if item:GetFullInfo().isTradable then
                        local roll = Roll.Add(item, owner)
                        if isOwner then
                            roll:Schedule()
                        end
                        roll:SendStatus(true)
                    else
                        Roll.Add(item, unit):Cancel()
                    end
                end
            end)
        elseif not msg:match(Self.PATTERN_BONUS_LOOT) and not Roll.Find(nil, unit, item) then
            Roll.Add(item, unit):Schedule()
        end
    end
end

-- Group/Raid/Instance

function Self.CHAT_MSG_PARTY(event, msg, sender)
    unit = Unit(sender)
    if not Addon:IsTracking() then return end

    local fromSelf = UnitIsUnit(unit, "player")
    local fromAddon = Util.StrStartsWith(msg, Addon.PREFIX_CHAT)

    local link = Item.GetLink(msg)
    if link then
        local item = Item.FromLink(link, unit):GetBasicInfo()

        local roll = Roll.Find(nil, unit, item:IsLoaded() and item.link or item.id)
        if roll then
            -- Remember the last roll posted to chat
            Self.lastPostedRoll = roll
            
            -- Remember that the roll has been posted
            roll.posted = true
            
            if not fromSelf and not fromAddon then
                -- Roll for the item in chat
                if Addon.db.profile.roll and roll.bid and Util.In(floor(roll.bid), Roll.BID_NEED, Roll.BID_GREED) then
                    RandomRoll("1", floor(roll.bid) == Roll.BID_GREED and "50" or "100")
                end
            end
        end
    end
end

-- Whisper

function Self.CHAT_MSG_WHISPER(event, msg, sender)
    unit = Unit(sender)
    if not Addon:IsTracking() or not Unit.InGroup(unit) then return end

    local answer = Addon.db.profile.answer
    local link = Item.GetLink(msg)
    link = link and select(2, GetItemInfo(link))
    local roll

    if link then
        -- Get the roll by link
        roll = Roll.Find(nil, nil, link)
    else
        -- Go through all currently running rolls
        rolls = Roll.ForUnit(unit)

        -- Ask for the item link if there is more than one roll right now
        if #rolls > 1 then
            if answer then Comm.ChatLine("ROLL_ANSWER_AMBIGUOUS", unit) end
        else
            roll = rolls[1]
        end
    end


    if roll then
        -- We chatted with this player after starting the roll, so it might be about something else
        if not link and Self.lastChatted[unit] and roll.started and Self.lastChatted[unit] > roll.started then
            if roll:CanBeAwardedTo(unit) and not roll.bids[unit] then
                Addon:Info(L["ROLL_IGNORING_BID"]:format(Comm.GetPlayerLink(unit), roll.item.link, Comm.GetBidLink(roll, unit, Roll.BID_NEED), Comm.GetBidLink(roll, unit, Roll.BID_GREED)))
            end
        -- The item is not tradable
        elseif not roll.item.isTradable then
            if answer then Comm.ChatLine("ROLL_ANSWER_NOT_TRADABLE", unit) end
        -- I need it for myself
        elseif roll.status == Roll.STATUS_CANCELED or roll.isWinner then
            if answer then Comm.ChatLine("ROLL_ANSWER_NO_SELF", unit) end
        -- Someone else won or got it
        elseif roll.winner and roll.winner ~= unit or roll.traded and roll.traded ~= unit then
            if answer then Comm.ChatLine("ROLL_ANSWER_NO_OTHER", unit) end
        else
            -- The roll is scheduled or happening
            if roll:CanBeAwarded() then
                -- He is eligible, so register the bid
                if roll:UnitIsEligible(unit) and not roll.bds[unit] or floor(roll.bids[unit]) ~= Roll.BID_NEED then
                    roll:Bid(Roll.BID_NEED, unit, true)

                    -- Answer only if his bid didn't end the roll
                    if answer and roll:CanBeAwarded() then
                        Comm.ChatLine("ROLL_ANSWER_BID", unit, roll.item.link)
                    end
                end
            -- He can have it
            elseif (not roll.winner or roll.winner == unit) and not roll.traded then
                roll.winner = unit
                if answer then
                    if roll.item.isOwner then
                        Comm.ChatLine("ROLL_ANSWER_YES", unit)
                    else
                        Comm.ChatLine("ROLL_ANSWER_YES_MASTERLOOT", unit, roll.item.owner)
                    end
                end
            end
        end
    end
    
    Self.lastChatted[unit] = time()
end

function Self.CHAT_MSG_WHISPER_INFORM(event, msg, receiver)
    Self.lastChatted[Unit.Name(receiver)] = time()
end

-- Register

function Self.RegisterEvents()
    -- Roster
    Addon:RegisterEvent("GROUP_JOINED", Self.GROUP_JOINED)
    Addon:RegisterEvent("GROUP_LEFT", Self.GROUP_LEFT)
    Addon:RegisterEvent("PARTY_MEMBER_ENABLE", Self.PARTY_MEMBER_ENABLE)
    -- Combat
    Addon:RegisterEvent("ENCOUNTER_START", Inspect.Stop)
    Addon:RegisterEvent("ENCOUNTER_END", Inspect.Start)
    -- Inspect
    Addon:RegisterEvent("INSPECT_READY", Self.INSPECT_READY)
    -- Trade
    Addon:RegisterEvent("TRADE_SHOW", Trade.OnOpen)
    Addon:RegisterEvent("TRADE_PLAYER_ITEM_CHANGED", Trade.OnPlayerItem)
    Addon:RegisterEvent("TRADE_TARGET_ITEM_CHANGED", Trade.OnTargetItem)
    Addon:RegisterEvent("TRADE_CLOSED", Trade.OnClose)
    Addon:RegisterEvent("TRADE_REQUEST_CANCEL", Trade.OnCancel)
    -- Item
    Addon:RegisterEvent("ITEM_PUSH", Self.ITEM_PUSH)
    Addon:RegisterEvent("ITEM_LOCKED", Self.ITEM_LOCKED)
    Addon:RegisterEvent("ITEM_UNLOCKED", Self.ITEM_UNLOCKED)
    Addon:RegisterEvent("BAG_UPDATE_DELAYED", Self.BAG_UPDATE_DELAYED)
    -- Chat
    Addon:RegisterEvent("CHAT_MSG_SYSTEM", Self.CHAT_MSG_SYSTEM)
    Addon:RegisterEvent("CHAT_MSG_LOOT", Self.CHAT_MSG_LOOT)
    Addon:RegisterEvent("CHAT_MSG_PARTY", Self.CHAT_MSG_PARTY)
    Addon:RegisterEvent("CHAT_MSG_PARTY_LEADER", Self.CHAT_MSG_PARTY)
    Addon:RegisterEvent("CHAT_MSG_RAID", Self.CHAT_MSG_PARTY)
    Addon:RegisterEvent("CHAT_MSG_RAID_LEADER", Self.CHAT_MSG_PARTY)
    Addon:RegisterEvent("CHAT_MSG_WHISPER", Self.CHAT_MSG_WHISPER)
    Addon:RegisterEvent("CHAT_MSG_WHISPER_INFORM", Self.CHAT_MSG_WHISPER_INFORM)
end

function Self.UnregisterEvents()
    -- Roster
    Addon:UnregisterEvent("GROUP_JOINED")
    Addon:UnregisterEvent("GROUP_LEFT")
    Addon:UnregisterEvent("PARTY_MEMBER_ENABLE")
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
    Addon:UnregisterEvent("CHAT_MSG_WHISPER")
    Addon:UnregisterEvent("CHAT_MSG_WHISPER_INFORM")
end

-------------------------------------------------------
--                   Addon message                   --
-------------------------------------------------------

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

    -- Send rolls for items that we own
    for _,roll in pairs(Addon.rolls) do
        if roll.item.isOwner and (roll:UnitCanBid(unit) or roll:UnitCanVote(unit)) then
            roll:SendStatus(true, unit, roll.isOwner)
        end
    end

    -- As masterlooter we send another update a bit later to inform them about bids and votes
    if Masterloot.IsMasterlooter() then
        Addon:ScheduleTimer(function ()
            for _,roll in pairs(Addon.rolls) do
                if roll.isOwner and not roll.item.isOwner and (roll:UnitCanBid(unit) or roll:UnitCanVote(unit)) then
                    roll:SendStatus(nil, unit, true)
                end
            end
        end, Roll.DELAY)
    end
end)

-- Version check
Comm.ListenData(Comm.EVENT_VERSION_ASK, function (event, data, channel, sender, unit)
    -- Send version
    if not Self.lastVersionCheck or Self.lastVersionCheck + Self.VERSION_CHECK_DELAY < GetTime() then
        Self.lastVersionCheck = GetTime()

        if Addon.timers.versionCheck then
            Addon:CancelTimer(Addon.timers.versionCheck)
            Addon.timers.versionCheck = nil
        end

        Comm.SendData(Comm.EVENT_VERSION, floor(Addon.VERSION), channel == Comm.TYPE_WHISPER and sender or channel)
    end
end, true)
Comm.ListenData(Comm.EVENT_VERSION, function (event, version, channel, sender, unit)
    Addon:SetVersion(unit, tonumber(version))
end)

-- Roll status
Comm.ListenData(Comm.EVENT_ROLL_STATUS, function (event, data, channel, sender, unit)
    data.owner = Unit.Name(data.owner)
    data.item.owner = Unit.Name(data.item.owner)
    data.winner = Unit.Name(data.winner)
    data.traded = data.traded and Unit.Name(data.traded)

    Roll.Update(data, unit)
end)

-- Bids
Comm.ListenData(Comm.EVENT_BID, function (event, data, channel, sender, unit)
    local owner = data.fromUnit and unit or nil
    local fromUnit = data.fromUnit or unit

    local roll = Roll.Find(data.ownerId, owner)
    if roll then
        roll:Bid(data.bid, fromUnit, owner ~= nil)
    end
end)

-- Votes
Comm.ListenData(Comm.EVENT_VOTE, function (event, data, channel, sender, unit)
    local owner = data.fromUnit and unit or nil
    local fromUnit = data.fromUnit or unit
    
    local roll = Roll.Find(data.ownerId, owner)
    if roll then
        roll:Vote(data.vote, fromUnit, owner ~= nil)
    end
end)

-- Declaring interest
Comm.ListenData(Comm.EVENT_INTEREST, function (event, data, channel, sender, unit)
    local roll = Roll.Find(data.ownerId)
    if roll then
        roll.item:SetEligible(unit)
    end
end)

-- Masterlooter
Comm.Listen(Comm.EVENT_MASTERLOOT_ASK, function (event, msg, channel, sender, unit)
    if Masterloot.IsMasterlooter() then
        Masterloot.SetMasterlooting(unit, nil)
        Masterloot.SendOffer(unit)
    elseif channel == Comm.TYPE_WHISPER then
        Masterloot.SendCancellation(nil, unit)
    elseif Masterloot.GetMasterlooter() then
        Masterloot.SendConfirmation(unit)
    end
end)
Comm.ListenData(Comm.EVENT_MASTERLOOT_OFFER, function (event, data, channel, sender, unit)
    Masterloot.SetMasterlooting(unit, unit)

    if Masterloot.IsMasterlooter(unit) then
        Masterloot.SendConfirmation()
        Masterloot.SetSession(data.session)
    elseif Masterloot.UnitAllow(unit) then
        if Masterloot.UnitAccept(unit) then
            Masterloot.SetMasterlooter(unit, data.session)
        elseif not data.silent then
            local dialog = StaticPopupDialogs[GUI.DIALOG_MASTERLOOT_ASK]
            dialog.text = L["DIALOG_MASTERLOOT_ASK"]:format(unit)
            dialog.OnAccept = function ()
                Masterloot.SetMasterlooter(unit, data.session)
            end
            StaticPopup_Show(GUI.DIALOG_MASTERLOOT_ASK)
        end
    end
end)
Comm.Listen(Comm.EVENT_MASTERLOOT_ACK, function (event, ml, channel, sender, unit)
    ml = Unit(ml)
    if ml then
        if UnitIsUnit(ml, "player") and not Masterloot.IsMasterlooter() then
            Masterloot.SendCancellation(nil, channel == Comm.TYPE_WHISPER and unit or nil)
        else
            Masterloot.SetMasterlooting(unit, ml)
        end
    end
end)
Comm.Listen(Comm.EVENT_MASTERLOOT_DEC, function (event, player, channel, sender, unit)
    player = Unit(player)

    -- Clear the player's masterlooter
    if Masterloot.IsMasterlooter(unit) and (Util.StrIsEmpty(player) or UnitIsUnit(player, "player")) then
        Masterloot.SetMasterlooter(nil, nil, true)
    elseif player == unit or Masterloot.masterlooting[player] == unit then
        Masterloot.SetMasterlooting(player, nil)
    end

    -- Clear everybody who has the sender as masterlooter
    if Util.StrIsEmpty(player) then
        Masterloot.ClearMasterlooting(unit)
    end
end)