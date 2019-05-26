---@type string
local Name = ...
---@type Addon
local Addon = select(2, ...)
local Comm, Item, Roll, Session, Unit, Util = Addon.Comm, Addon.Item, Addon.Roll, Addon.Session, Addon.Unit, Addon.Util
---@class PLH : Module
local Self = Addon.PLH

Self.NAME = "PersonalLootHelper"
Self.VERSION = "2.08"
Self.PREFIX = "PLH"

Self.BID_NEED = "MAIN SPEC"
Self.BID_GREED = "OFF SPEC"
Self.BID_DISENCHANT = "SHARD"

Self.ACTION_CHECK = "IDENTIFY_USERS"
Self.ACTION_VERSION = "VERSION"
Self.ACTION_KEEP = "KEEP"
Self.ACTION_TRADE = "TRADE"
Self.ACTION_REQUEST = "REQUEST"
Self.ACTION_OFFER = "OFFER"

Self.initialized = false

-------------------------------------------------------
--                        Comm                       --
-------------------------------------------------------

-- Send a PLH message
---@param action string
---@param roll Roll|string
---@param param any
function Self.Send(action, roll, param)
    if Self:IsEnabled() then
        local msg = not roll and ("%s~ ~%s"):format(action, param)
            or type(roll) == "string" and ("%s~ ~%s~%s"):format(action, roll, param)
            or param and ("%s~%d~%s~%s"):format(action, roll.item.id, Unit.FullName(roll.item.owner), param)
            or ("%s~%d~%s"):format(action, roll.item.id, Unit.FullName(roll.item.owner))

        Comm.Send(Self.PREFIX, msg)
    end
end

-- Process incoming PLH message
Comm.Listen(Self.PREFIX, function (event, msg, channel, _, unit)
    if not Self:IsEnabled() or Addon.versions[unit] then return end

    local action, itemId, owner, param = msg:match('^([^~]+)~([^~]+)~([^~]+)~?([^~]*)$')
    itemId = tonumber(itemId)
    owner = Unit(owner)
    local fromOwner = owner == unit

    -- Check: Version check
    if action == Self.ACTION_CHECK then
        Self.Send(Self.ACTION_VERSION, Unit.FullName("player"), Self.VERSION)
    -- Version: Answer to version check
    elseif action == Self.ACTION_VERSION then
        Addon:SetCompAddonUser(unit, Self.NAME, param)
    else
        local item = Item.IsLink(param) and param or itemId
        local roll = Roll.Find(nil, nil, item, nil, owner, Roll.STATUS_RUNNING) or Roll.Find(nil, nil, item, nil, owner)

        -- Trade: The owner offers the item up for requests
        if action == Self.ACTION_TRADE and not roll and fromOwner and Item.IsLink(param) then
            Addon:Debug("PLH.Event.Trade", itemId, owner, param, msg)
            Roll.Add(param, owner):Start()
        elseif roll and (roll.isOwner or not roll.ownerId) then
            -- Keep: The owner wants to keep the item
            if action == Self.ACTION_KEEP and fromOwner then
                roll:End(owner)
            -- Request: The sender bids on an item
            elseif action == Self.ACTION_REQUEST then
                local bid = Util.Select(param, Self.BID_NEED, Roll.BID_NEED, Self.BID_DISENCHANT, Roll.BID_DISENCHANT, Roll.BID_GREED)
                roll:Bid(bid, unit)
            -- Offer: The owner has picked a winner
            elseif action == Self.ACTION_OFFER and fromOwner then
                roll:End(param)
            end
        end
    end
end)

-------------------------------------------------------
--                    Events/Hooks                   --
-------------------------------------------------------

function Self:ShouldBeEnabled()
    return not IsAddOnLoaded(Self.NAME)
        and Addon:IsActive()
end

function Self:OnInitialize()
    Self:CheckState()
    Self:RegisterMessage(Addon.EVENT_ACTIVE_CHANGE, Self.CheckState)
end

function Self:OnEnable()
    -- Register events
    Self:RegisterMessage(Roll.EVENT_START, "ROLL_START")
    Self:RegisterMessage(Roll.EVENT_BID, "ROLL_BID")
    Self:RegisterMessage(Roll.EVENT_AWARD, "ROLL_AWARD")

    -- Send version check
    Self.Send(Self.ACTION_CHECK, nil, Unit.FullName("player"))
end

function Self:OnDisable()
    -- Unregister events
    Self:UnregisterMessage(Roll.EVENT_START)
    Self:UnregisterMessage(Roll.EVENT_BID)
    Self:UnregisterMessage(Roll.EVENT_AWARD)
end

---@param roll Roll
function Self:ROLL_START(_, roll)
    if roll.isOwner and not roll.isTest then
        -- Send TRADE message
        Self.Send(Self.ACTION_TRADE, roll, roll.item.link)
    end
end

---@param roll Roll
---@param bid number
---@param fromUnit string
---@param isImport boolean
function Self:ROLL_BID(_, roll, bid, fromUnit, _, isImport)
    local fromSelf = Unit.IsSelf(fromUnit)

    if not isImport and not roll.isTest then
        if roll.isOwner then
            if fromSelf and floor(bid) == Roll.BID_NEED and not Session.GetMasterlooter() then
                -- Send KEEP message
                Self.Send(Self.ACTION_KEEP, roll)
            end
        elseif fromSelf and not roll.ownerId and bid ~= Roll.BID_PASS and Addon.GetCompAddonUser(roll.owner, Self.NAME) then
            -- Send REQUEST message
            local request = Util.Select(bid, Roll.BID_NEED, Self.BID_NEED, Roll.BID_DISENCHANT, Self.BID_DISENCHANT, Self.BID_GREED)
            Self.Send(Self.ACTION_REQUEST, roll, request)
        end
    end
end

---@param roll Roll
function Self:ROLL_AWARD(_, roll)
    if roll.winner and not roll.isWinner and roll.isOwner and Addon.GetCompAddonUser(roll.winner, Self.NAME) and not roll.isTest then
        -- Send OFFER message
        Self.Send(Self.ACTION_OFFER, roll, Unit.FullName(roll.winner))
    end
end