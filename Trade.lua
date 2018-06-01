local Addon = LibStub("AceAddon-3.0"):GetAddon(PLR_NAME)
local L = LibStub("AceLocale-3.0"):GetLocale(PLR_NAME)
local Util = Addon.Util
local Comm = Addon.Comm
local Item = Addon.Item
local Roll = Addon.Roll
local Self = {}

Self.items = {player = {}, target = {}}
Self.timers = {}

-------------------------------------------------------
--                      Actions                      --
-------------------------------------------------------

-- Try to initiate a trade
function Self.Initiate(target)
    target = Util.GetName(target)

    -- Cancel any other trade
    Self.Cancel()

    Addon:Verbose(L["TRADE_START"]:format(Comm.GetPlayerLink(target)))
        
    -- Trade with owner
    if CheckInteractDistance(target, Util.INTERACT_TRADE) then
        InitiateTrade(target)
    -- Follow owner if trading is not possible
    elseif CheckInteractDistance(target, Util.INTERACT_FOLLOW) then
        FollowUnit(target)

        -- Check distance until we can trade
        Self.timers.follow = Addon:ScheduleRepeatingTimer(function ()
            -- Stop if not following anymore
            if not Util.IsFollowing(target) then
                Self.Cancel()
            elseif CheckInteractDistance(target, Util.INTERACT_TRADE) then
                Addon:CancelTimer(Self.timers.follow)
               
                Self.timers.follow = Addon:ScheduleTimer(function ()
                    Self.timers.follow = nil
                    InitiateTrade(target)
                end, 0.5)
            end
        end, 0.5)
    else
        -- This just causes a nice error message
        InitiateTrade(target)
    end

    return true
end

-- Start a trade
function Self.Start()
    if not Self.target then return end

    -- Find items the target has won and add them to the trade window
    local rolls = Util(Addon.rolls).Where({item = {isOwner = true}, winner = Self.target, traded = false}, nil, true)()
    for i,roll in pairs(rolls) do
        PickupContainerItem(roll.item:GetPosition())
        DropItemOnUnit(Self.target)
    end
end

-- Finalize a trade
function Self.End()
    if not Self.target then return end

    -- Mark the player's rolls as traded
    for _, link in pairs(Self.items.player) do
        local roll = Roll.Find(nil, nil, link)
        if roll and not roll.traded then
            roll:OnTraded(Self.target)
        end
    end

    -- Mark the target's rolls as traded
    for _, link in pairs(Self.items.target) do
        local roll = Roll.Find(nil, Self.target, link)
        if roll and not roll.traded then
            roll:OnTraded(UnitName("player"))
        end
    end

    Self.Clear()
end

-- Cancel current and planed trades
function Self.Cancel()
    -- Cancel an ongoing follow
    FollowUnit("player")
    if Self.timers.follow then
        Addon:CancelTimer(Self.timers.follow)
        Self.timers.follow = nil
    end

    -- Cancel any ongoing trades
    CancelTrade()
    Self.Clear()
end

-- Clear current trade data
function Self.Clear()
    Self.target = nil

    -- Cancel an ongoing OnClose
    if Self.timers.onClose then
        Addon:CancelTimer(Self.timers.onClose)
        Self.timers.onClose = nil
    end

    -- Remove all saved trade items
    wipe(Self.items.player)
    wipe(Self.items.target)
end

-------------------------------------------------------
--                       Events                      --
-------------------------------------------------------

-- Called when a trade is started
function Self.OnOpen()
    Self.Clear()

    Self.target = UnitName("NPC")

    Self.Start()
end

-- Save (or clear) item links for later reference
function Self.OnPlayerItem(_, slot)
    Self.items.player[slot] = GetTradePlayerItemLink(slot)
end
function Self.OnTargetItem(_, slot)
    Self.items.target[slot] = GetTradeTargetItemLink(slot)
end

-- Called when a trade is ended (successfully or not)
function Self.OnClose()
    -- This usually get's called twice in a row
    if Self.timers.onClose then
        Addon:CancelTimer(Self.timers.onClose)
        Self.timers.onClose = nil
    end

    -- We need to wait because there could be a cancel event right after
    if Self.target then
        Self.timers.onClose = Addon:ScheduleTimer(Self.End, 1)
    end
end

function Self.OnCancel()
    Self.Clear()
end

-- Export

Addon.Trade = Self