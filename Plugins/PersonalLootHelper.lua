local Name, Addon = ...
local Comm, Roll, Unit, Util = Addon.Comm, Addon.Roll, Addon.Unit, Addon.Util
local Self = Addon.PLH

Self.NAME = "Personal Loot Helper"
Self.VERSION = "2.08"
Self.EVENT = "PLH"

Self.BID_NEED = "MAIN SPEC"
Self.BID_GREED = "OFF SPEC"
Self.BID_DISENCHANT = "SHARD"

Self.ACTION_CHECK = "IDENTIFY_USERS"
Self.ACTION_VERSION = "VERSION"
Self.ACTION_KEEP = "KEEP"
Self.ACTION_TRADE = "TRADE"
Self.ACTION_REQUEST = "REQUEST"
Self.ACTION_OFFER = "OFFER"

function Self.IsUsedByUnit(unit)
    return Util.StrStartsWith(Addon.compAddonUsers[Unit.Name(unit)], Self.NAME)
end

-------------------------------------------------------
--                        Comm                       --
-------------------------------------------------------

-- Send a PLH message
function Self.Send(action, roll, param)
    if not IsAddOnLoaded(Self.NAME) then
        local txt = not roll and ("%s~ ~%s"):format(action, param)
                or type(roll) == "string" and ("%s~ ~%s~%s"):format(action, roll, param)
                or param and ("%s~%d~%s~%s"):format(action, roll.item.id, Unit.FullName(roll.item.owner), param)
                or ("%s~%d~%s"):format(action, roll.item.id, Unit.FullName(roll.item.owner))

        -- TODO: This fixes a beta bug that causes a dc when sending empty strings
        txt = (not txt or txt == "") and " " or txt

        -- Send the message
        Addon:SendCommMessage(Self.EVENT, txt, Self.GetDestination())
    end
end

Comm.Listen(Self.EVENT, function (event, msg, channel, _, unit)
    if not IsAddOnLoaded(Self.NAME) then
        local action, itemId, owner, param = msg:match('^([^~]+)~([^~]+)~([^~]+)~?([^~]*)$')
        itemId = tonumber(itemId)
        owner = Unit(owner)
        local fromOwner = owner == unit

        if not Addon.versions[unit] then
            -- Check: Version check
            if action == Self.ACTION_CHECK then
                Self.Send(Self.ACTION_VERSION, Unit.FullName("player"), Self.VERSION)
            -- Version: Answer to version check
            elseif action == Self.ACTION_VERSION then
                Addon.compAddonUsers[unit] = ("%s (%s)"):format(Self.NAME, param)
            else
                local item = Item.IsLink(param) and param or itemId
                local roll = Roll.Find(nil, nil, item, nil, owner, Roll.STATUS_RUNNING) or Roll.Find(nil, nil, item, nil, owner)
                
                -- Trade: The owner offers the item up for requests
                if action == Self.ACTION_TRADE and not roll and fromOwner and Item.IsLink(param) then
                    Addon:Debug("PLH.Event.Trade", msg, itemId, owner, param)
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
        end
    end
end)

-------------------------------------------------------
--                    Events/Hooks                   --
-------------------------------------------------------

function Self:OnEnable()
    -- Register events
    Self:RegisterEvent("GROUP_JOINED")
    Roll.On(Self, Roll.EVENT_START, "ROLL_START")
    Roll.On(Self, Roll.EVENT_BID, "ROLL_BID")
    Roll.On(Self, Roll.EVENT_END, "ROLL_END")

    if IsInGroup() then
        Self.GROUP_JOINED()
    end
end

function Self.GROUP_JOINED()
    Self.Send(Self.ACTION_CHECK, nil, Unit.FullName("player"))
end

function Self.ROLL_START(_, roll)
    if roll.isOwner then
        -- Send TRADE message
        Self.Send(Self.ACTION_TRADE, roll, roll.item.link)
    end
end


function Self.ROLL_BID(_, roll, bid, fromUnit, _, isImport)
    local fromSelf = Unit.IsSelf(fromUnit)

    if not isImport then
        if roll.isOwner then
            if fromSelf and floor(bid) == Roll.BID_NEED and not Session.GetMasterlooter() then
                -- Send KEEP message
                Self.Send(Self.ACTION_KEEP, roll)
            end
        elseif fromSelf and not roll.ownerId and bid ~= Roll.BID_PASS and Self.IsUsedByUnit(roll.owner) then
            -- Send REQUEST message
            local request = Util.Select(bid, Roll.BID_NEED, Self.BID_NEED, Roll.BID_DISENCHANT, Self.BID_DISENCHANT, Self.BID_GREED)
            Self.Send(Self.ACTION_REQUEST, roll, request)
        end
    end
end

function Self.ROLL_END(_, roll)
    if roll.winner and not roll.isWinner and roll.isOwner and Self.IsUsedByUnit(roll.winner) then
        -- Send OFFER message
        Self.Send(Self.ACTION_OFFER, roll, Unit.FullName(roll.winner))
    end
end