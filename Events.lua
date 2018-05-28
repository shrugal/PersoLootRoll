local Addon = LibStub("AceAddon-3.0"):GetAddon(PLR_NAME)
local Util = Addon.Util
local Item = Addon.Item
local Locale = Addon.Locale
local Comm = Addon.Comm
local Roll = Addon.Roll
local Inspect = Addon.Inspect
local GUI = Addon.GUI
local Self = {}

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

-------------------------------------------------------
--                      Roster                       --
-------------------------------------------------------

function Self.GROUP_JOINED(event, ...)
    -- Schedule version check
    Addon.timers.versionCheck = Addon:ScheduleTimer(function ()
        Comm.Send(Comm.EVENT_VERSION_ASK)
    end, Self.VERSION_CHECK_DELAY)
    
    -- Start inspecting
    Inspect.Queue()
    Inspect.Start()
end

function Self.GROUP_LEFT(event, ...)
    -- Clear all rolls
    Util.TblApply(Addon.rolls, Roll.Clear)

    -- Stop inspecting
    Inspect.Clear()

    -- Clear masterlooter
    Addon:SetMasterlooter(nil)
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
    tinsert(Self.lastLocked, slot and {bagOrEquip, slot} or bagOrEquip)
end

function Self.ITEM_UNLOCKED(event, bagOrEquip, slot)
    local pos = {bagOrEquip, slot}
    
    if #Self.lastLocked == 1 and not Util.TblEquals(pos, Self.lastLocked[1]) then
        -- The item has been moved
        Item.OnMove(Self.lastLocked, pos)
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
            if to ~= 1 then return end
            
            -- Find the roll
            local i, roll = to % 50
            if i == 0 then
                roll = Self.lastPostedRoll
            else
                roll = Util.TblFirstWhere(Addon.rolls, {isOwner = true, status = Roll.STATUS_RUNNING, posted = i})
            end
            
            -- Get the correct answer
            local answer = to < 100 and Roll.ANSWER_GREED or Roll.ANSWER_NEED
            
            -- Register the unit's bid
            if Util.UnitInGroup(unit, true) and roll and roll:CanBeAwardedTo(unit) and not roll:UnitHasBid(unit, answer) then
                roll:Bid(unit, answer, true)
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
            Util(Addon.rolls).Where({owner = unit}).Apply(Roll.Clear)
            for id, roll in pairs(Addon.rolls) do
                if roll:CanBeWon(true) then
                    -- Remove from eligible list
                    if roll.item.eligible then
                        roll.item.eligible[unit] = nil
                    end

                    if roll.isOwner then
                        -- Remove bids
                        for _, bids in pairs(roll.bids) do bids[unit] = nil end
                        -- Check if we can end the rolls now
                        roll:CheckEnd()
                    end
                end
            end

            -- Clear inspect cache
            Inspect.Clear(unit)
            return
        end
    end
end

-- Loot

function Self.CHAT_MSG_LOOT(event, msg, _, _, _, sender)
    unit = Util.GetUnit(sender)
    if not Addon:IsTracking() or not Util.UnitInGroup(unit) then return end

    local item = Item.GetLink(msg)

    if item and unit then
        item = Item.FromLink(item, unit)

        -- Do first quick check, to ignore 99.99% of the loot
        if not item:ShouldBeConsidered() then return end

        if item.isOwner then
            item:SetPosition(Self.lastLootedBag, 0)

            item:OnFullyLoaded(function ()
                if item:ShouldBeRolledFor() then
                    Roll.Add(item, Addon.masterlooter or unit):Start()
                elseif item:GetBasicInfo().isEquippable then
                    Roll.Add(item, Addon.masterlooter or unit):Cancel()
                end
            end)
        elseif not msg:match(Self.PATTERN_BONUS_LOOT) and not Roll.Find(nil, unit, item) then
            Roll.Add(item, unit):Schedule()
        end
    end
end

-- Group/Raid/Instance

function Self.CHAT_MSG_PARTY(event, msg, sender)
    unit = Util.GetUnit(sender)
    if not Addon:IsTracking() then return end

    local fromSelf = UnitIsUnit(unit, "player")
    local fromAddon = Util.StrStartsWith(msg, PLR_CHAT)

    local link = Item.GetLink(msg)
    if link then
        local item = Item.FromLink(link)

        local roll = Roll.Find(nil, unit, item:IsLoaded() and item.link or item.id)
        if roll then
            print("Roll", roll)

            -- Remember the last roll posted to chat
            Self.lastPostedRoll = roll
            
            -- Remember that the roll has been posted
            roll.posted = true
            
            if not fromSelf and not fromAddon then
                -- Roll for the item in chat
                if Addon.db.profile.roll and Util.In(roll.answer, Roll.ANSWER_NEED, Roll.ANSWER_GREED) then
                    RandomRoll("1", roll.answer == Roll.ANSWER_GREED and "50" or "100")
                end
            end
        end
    end
end

-- Whisper

function Self.CHAT_MSG_WHISPER(event, msg, sender)
    unit = Util.GetUnit(sender)
    if not Addon:IsTracking() or not Util.UnitInGroup(unit) then return end

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

    -- No roll found
    if not roll then
        return
    -- The item is not tradable
    elseif not roll.item.isTradable then
        if answer then Comm.ChatLine("ROLL_ANSWER_NOT_TRADABLE", unit) end
    -- I need it for myself
    elseif roll.status == Roll.STATUS_CANCELED or UnitIsUnit(roll.winner, "player") then
        if answer then Comm.ChatLine("ROLL_ANSWER_NO_SELF", unit) end
    -- Someone else won or got it
    elseif roll.winner and roll.winner ~= unit or roll.traded and roll.traded ~= unit then
        if answer then Comm.ChatLine("ROLL_ANSWER_NO_OTHER", unit) end
    else
        -- The roll is scheduled or happening
        if roll:CanBeAwarded() then
            -- He is eligible, so register the bid
            if roll:UnitIsEligible(unit) and not roll:UnitHasBid(unit, Roll.ANSWER_NEED) then
                roll:Bid(Roll.ANSWER_NEED, unit, true)

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
    Addon:RegisterEvent("TRADE_SHOW", Addon.Trade.OnOpen)
    Addon:RegisterEvent("TRADE_PLAYER_ITEM_CHANGED", Addon.Trade.OnPlayerItem)
    Addon:RegisterEvent("TRADE_TARGET_ITEM_CHANGED", Addon.Trade.OnTargetItem)
    Addon:RegisterEvent("TRADE_CLOSED", Addon.Trade.OnClose)
    Addon:RegisterEvent("TRADE_REQUEST_CANCEL", Addon.Trade.OnCancel)
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
end

-------------------------------------------------------
--                   Addon message                   --
-------------------------------------------------------

-- Version check
Comm.Listen(Comm.EVENT_VERSION_ASK, function (event, msg, channel, sender, unit)
    if not Self.lastVersionCheck or Self.lastVersionCheck + Self.VERSION_CHECK_DELAY < GetTime() then
        Self.lastVersionCheck = GetTime()

        if Addon.timers.versionCheck then
            Addon:CancelTimer(Addon.timers.versionCheck)
            Addon.timers.versionCheck = nil
        end

        Comm.Send(Comm.EVENT_VERSION, Addon.VERSION .. "", channel == Comm.TYPE_WHISPER and sender or channel)

        if Addon:IsMasterlooter() then
            Comm.Send(Comm.EVENT_MASTERLOOT_ASK, nil, sender)
        end
    end
end, true)
Comm.Listen(Comm.EVENT_VERSION, function (event, msg, channel, sender, unit)
    Addon.versions[unit] = tonumber(msg)
end)

-- Roll status
Comm.ListenData(Comm.EVENT_ROLL_STATUS, function (event, data, channel, sender, unit)
    if data.id then
        Addon.Roll.Update(data, sender)
    end
end)

-- Bids
Comm.ListenData(Comm.EVENT_BID, function (event, data, channel, sender, unit)
    if data.id and data.answer then
        local roll = Addon.rolls[data.id]
        
        if roll and roll.isOwner then
            roll:Bid(data.answer, unit)
        end
    end
end)

-- Masterlooter
Comm.Listen(Comm.EVENT_MASTERLOOT_ASK, function (event, msg, channel, sender, unit)
    if Addon:IsMasterlooter(unit) then
        Comm.Send(Comm.EVENT_MASTERLOOT_ACK, nil, sender)
    elseif Util.UnitAllowMasterloot(unit) then
        if Util.UnitAcceptMasterloot(unit) then
            Addon:SetMasterlooter(unit)
        else
            local dialog = StaticPopupDialogs[Self.DIALOG_MASTERLOOT_ASK]
            dialog.text = L["DIALOG_MASTERLOOT_ASK"]:format(unit)
            dialog.OnAccept = function ()
                Addon:SetMasterlooter(unit)
            end
        end
    end
end)
Comm.Listen(Comm.EVENT_MASTERLOOT_ACK, function (event, msg, channel, sender, unit)
    if Addon:IsMasterlooter() then
        Addon.masterlooting[unit] = true
    end
end)
Comm.Listen(Comm.EVENT_MASTERLOOT_STOP, function (event, msg, channel, sender, unit)
    if Addon:IsMasterlooter() then
        Addon.masterlooting[unit] = nil
    elseif Addon:IsMasterlooter(unit) then
        Addon:SetMasterlooter(nil, true)
    end
end)

-- Export

Addon.Events = Self