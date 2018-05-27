local Addon = LibStub("AceAddon-3.0"):GetAddon(PLR_NAME)
local Self = {}
local Util = Addon.Util
local Item = Addon.Item
local Comm = Addon.Comm
local Roll = Addon.Roll
local Inspect = Addon.Inspect

-- Message patterns
local PATTERN_BONUS_LOOT = LOOT_ITEM_BONUS_ROLL:gsub("%%s", ".+")
local PATTERN_ROLL_RESULT = RANDOM_ROLL_RESULT:gsub("%(", "%%("):gsub("%)", "%%)"):gsub("%%s", "(.+)"):gsub("%%d", "(%%d+)")

-- Remember the last locked item slot
local lastLocked = {}
-- Remember the bag of the last looted item
local lastLootedBag
-- Remember the last item link posted in group chat so we can track random rolls
local lastPostedRoll

-------------------------------------------------------
--                      Roster                       --
-------------------------------------------------------

Addon:RegisterEvent("GROUP_JOINED", function (event, ...)
    -- TODO: Version check
    
    -- Start inspecting
    Inspect.Queue()
    Inspect.Start()
end)

Addon:RegisterEvent("GROUP_LEFT", function (event, ...)
    -- Clear all rolls
    Util.TblApply(Addon.rolls, Roll.Clear)

    -- Stop inspecting
    Inspect.Clear()
end)

Addon:RegisterEvent("PARTY_MEMBER_ENABLE", function (event, unit)
    Inspect.Queue(unit)
    Inspect.Start()
end)

-------------------------------------------------------
--                      Combat                       --
-------------------------------------------------------

-- Don't inspect in fight
Addon:RegisterEvent("ENCOUNTER_START", Inspect.Stop)
Addon:RegisterEvent("ENCOUNTER_END", Inspect.Start)

-------------------------------------------------------
--                     Inspect                       --
-------------------------------------------------------

Addon:RegisterEvent("INSPECT_READY", function (event, guid)
    local _, _, _, _, _, name, realm = GetPlayerInfoByGUID(guid)
    local unit = realm and realm ~= "" and name .. "-" .. realm or name
    Inspect.OnInspectReady(unit)
end)

-------------------------------------------------------
--                      Trade                        --
-------------------------------------------------------

Addon:RegisterEvent("TRADE_SHOW", Addon.Trade.OnOpen)
Addon:RegisterEvent("TRADE_PLAYER_ITEM_CHANGED", Addon.Trade.OnPlayerItem)
Addon:RegisterEvent("TRADE_TARGET_ITEM_CHANGED", Addon.Trade.OnTargetItem)
Addon:RegisterEvent("TRADE_CLOSED", Addon.Trade.OnClose)
Addon:RegisterEvent("TRADE_REQUEST_CANCEL", Addon.Trade.OnCancel)

-------------------------------------------------------
--                      Items                        --
-------------------------------------------------------

Addon:RegisterEvent("ITEM_PUSH", function (event, bagId)
    lastLootedBag = bagId == 0 and 0 or (bagId - CharacterBag0Slot:GetID() + 1)
end)

Addon:RegisterEvent("ITEM_LOCKED", function (event, bagOrEquip, slot)
    tinsert(lastLocked, slot and {bagOrEquip, slot} or bagOrEquip)
end)

Addon:RegisterEvent("ITEM_UNLOCKED", function (event, bagOrEquip, slot)
    local pos = {bagOrEquip, slot}
    
    if #lastLocked == 1 and not Util.TblEquals(pos, lastLocked[1]) then
        -- The item has been moved
        Item.OnMove(lastLocked, pos)
    elseif #lastLocked == 2 then
        -- The item has switched places with another
        Item.OnSwitch(lastLocked[1], lastLocked[2])
    end

    wipe(lastLocked)
end)

Addon:RegisterEvent("BAG_UPDATE_DELAYED", function (event)
    for i, entry in pairs(Item.queue) do
        Addon:CancelTimer(entry.timer)
        entry.fn(unpack(entry.args))
    end
    wipe(Item.queue)
end)

-------------------------------------------------------
--                   Chat message                    --
-------------------------------------------------------

-- System

Addon:RegisterEvent("CHAT_MSG_SYSTEM", function (event, msg)
    -- Check if a player rolled
    do
        local unit, result, from, to = msg:match(PATTERN_ROLL_RESULT)
        if unit and result and from and to then
            result, from, to = tonumber(result), tonumber(from), tonumber(to)
            if to ~= 1 then return end
            
            -- Find the roll
            local i, roll = to % 50
            if i == 0 then
                roll = lastPostedRoll
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
end)

-- Loot

Addon:RegisterEvent("CHAT_MSG_LOOT", function (event, msg, _, _, _, owner)
    unit = Util.GetUnit(owner)
    if not Addon:IsTracking() or not Util.UnitInGroup(unit) then return end

    local item = Item.GetLink(msg)

    if item and unit then
        item = Item.FromLink(item, unit)

        -- Do first quick check, to ignore 99.99% of the loot
        if not item:ShouldBeConsidered() then return end

        if item.isOwner then
            item:SetPosition(lastLootedBag, 0)

            item:OnFullyLoaded(function ()
                if item:ShouldBeRolledFor() then
                    Roll.Add(item, unit):Start()
                elseif item:GetBasicInfo().isEquippable then
                    Roll.Add(item, unit):Cancel()
                end
            end)
        elseif not msg:match(PATTERN_BONUS_LOOT) and not Roll.Find(nil, unit, item) then
            Roll.Add(item, unit):Schedule()
        end
    end
end)

-- Group/Raid/Instance

function Self.OnGroupMessage(event, msg, sender)
    unit = Util.GetUnit(sender)
    if not Addon:IsTracking() then return end

    local fromSelf = UnitIsUnit(unit, "player")
    local fromAddon = Util.StrStartsWith(msg, PLR_CHAT)

    local link = Item.GetLink(msg)
    if link then
        print("Link", link)
        local item = Item:FromLink(link)
        item:OnLoaded(function ()
            print("Loaded", item.link)
            local roll = Roll.Find(nil, unit, item)
            if not roll then return end
            print("Roll", roll)

            -- Remember the last roll posted to chat
            lastPostedRoll = roll
            
            -- Remember that the roll has been posted
            roll.posted = true
            
            if not fromSelf and not fromAddon then
                -- Roll for the item in chat
                if Addon.db.profile.roll and Util.In(roll.answer, Roll.ANSWER_NEED, Roll.ANSWER_GREED) then
                    RandomRoll("1", roll.answer == Roll.ANSWER_GREED and "50" or "100")
                end
            end
        end)
    end
end

Addon:RegisterEvent("CHAT_MSG_PARTY", Self.OnGroupMessage)
Addon:RegisterEvent("CHAT_MSG_PARTY_LEADER", Self.OnGroupMessage)
Addon:RegisterEvent("CHAT_MSG_RAID", Self.OnGroupMessage)
Addon:RegisterEvent("CHAT_MSG_RAID_LEADER", Self.OnGroupMessage)

-- Whisper

Addon:RegisterEvent("CHAT_MSG_WHISPER", function (event, msg, sender)
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
    elseif roll.status == Roll.STATUS_CANCELED or roll.winner ==  UnitName("player") then
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
            if answer then Comm.ChatLine("ROLL_ANSWER_YES", unit) end
        end
    end
end)

-------------------------------------------------------
--                   Addon message                   --
-------------------------------------------------------

-- Roll status
Comm.Listen(Comm.EVENT_ROLL_STATUS, function (event, data, channel, sender)
    unit = Util.GetUnit(sender)
    if not Util.UnitInGroup(unit, true) then return end

    local success, data = Addon:Deserialize(data)
    
    if success and data.id then
        Addon.Roll.Update(data, sender)
    end
end)

-- Bids
Comm.Listen(Comm.EVENT_BID, function (event, data, channel, sender)
    unit = Util.GetUnit(sender)
    if not Util.UnitInGroup(unit, true) then return end

    local success, data = Addon:Deserialize(data)
    
    if success and data.id and data.answer then
        local roll = Addon.rolls[data.id]
        
        if roll and roll.isOwner then
            roll:Bid(data.answer, unit)
        end
    end
end)

-- Export

Addon.Events = Self