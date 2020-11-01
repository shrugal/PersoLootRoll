---@type string
local Name = ...
---@type Addon
local Addon = select(2, ...)
---@type L
local L = LibStub("AceLocale-3.0"):GetLocale(Name)
local Comm, Roll, Unit, Util = Addon.Comm, Addon.Roll, Addon.Unit, Addon.Util
---@class Trade : Module
local Self = Addon.Trade

Self.items = {player = {}, target = {}}
Self.timers = {}

-------------------------------------------------------
--                      Actions                      --
-------------------------------------------------------

-- Try to initiate a trade
---@param target string
function Self.Initiate(target)
    target = Unit.Name(target)

    -- Cancel any other trade
    Self.Cancel()

    Addon:Verbose(L["TRADE_START"], Comm.GetPlayerLink(target))

    -- Trade with owner
    if CheckInteractDistance(target, Util.INTERACT_TRADE) then
        InitiateTrade(target)
    -- Follow owner if trading is not possible
    elseif CheckInteractDistance(target, Util.INTERACT_FOLLOW) then
        FollowUnit(target)

        -- Check distance until we can trade
        Self.timers.follow = Addon:ScheduleRepeatingTimer(function ()
            -- Stop if not following anymore
            if not Unit.IsFollowing(target) then
                Self.Cancel()
            elseif CheckInteractDistance(target, Util.INTERACT_TRADE) then
                Addon:CancelTimer(Self.timers.follow)

                Self.timers.follow = Addon:ScheduleTimer(function ()
                    Self.timers.follow = nil
                    InitiateTrade(target)
                end, 0.5)
            end
        end, 0.5)
    end

    return true
end

-- Finalize a trade
function Self.End()
    if Self.target then
        -- Mark the player's rolls as traded
        for _, link in pairs(Self.items.player) do
            local roll = Roll.Find(nil, nil, link, nil, true)
            if roll and not roll.traded then
                roll:OnTraded(Self.target)
            end
        end

        -- Mark the target's rolls as traded
        for _, link in pairs(Self.items.target) do
            local roll = Roll.Find(nil, nil, link, nil, Self.target)
            if roll and not roll.traded then
                roll:OnTraded(Unit.Name("player"))
            end
        end

        Self.Clear()
    end
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
--                       Helper                      --
-------------------------------------------------------

-- Check if the user should be allowed to initiate trade with a roll owner or winner
---@param roll Roll
---@return boolean
function Self.ShouldInitTrade(roll)
    local target = roll:GetActionTarget()
    return target and (
        roll.chat
        or roll.posted
        or roll:GetOwnerAddon()
        or roll.item:GetNumEligible(false, true) == 0
        or IsGuildMember(target)
        or Unit.IsFriend(target)
        or Unit.IsClubMember(target)
    )
end

-------------------------------------------------------
--                    Events/Hooks                   --
-------------------------------------------------------

function Self:OnEnable()
    -- Register events
    Self:RegisterEvent("TRADE_SHOW")
    Self:RegisterEvent("TRADE_PLAYER_ITEM_CHANGED")
    Self:RegisterEvent("TRADE_TARGET_ITEM_CHANGED")
    Self:RegisterEvent("TRADE_CLOSED")
    Self:RegisterEvent("TRADE_REQUEST_CANCEL", Self.Clear)
end

function Self:TRADE_SHOW()
    Self.Clear()
    Self.target = Unit.Name("NPC")

    if Self.target then
        -- Find items the target has won and add them to the trade window
        local i = 1
        for _,roll in pairs(Addon.rolls) do
            if i > MAX_TRADE_ITEMS then
                break
            elseif roll.item.isOwner and roll.winner == Self.target and not roll.traded then
                local bag, slot, isTradable = roll.item:GetPosition()
                if bag and slot and isTradable then
                    ClearCursor()
                    PickupContainerItem(bag, slot)
                    ClickTradeButton(i)
                    i = i + 1
                end
            end
        end
    end
end

---@param slot integer
function Self:TRADE_PLAYER_ITEM_CHANGED(_, slot)
    Self.items.player[slot] = GetTradePlayerItemLink(slot)
end

---@param slot integer
function Self:TRADE_TARGET_ITEM_CHANGED(_, slot)
    Self.items.target[slot] = GetTradeTargetItemLink(slot)
end

function Self:TRADE_CLOSED()
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