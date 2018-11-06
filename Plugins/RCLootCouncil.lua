local Name, Addon = ...
local Comm, Roll, Session, Unit, Util = Addon.Comm, Addon.Roll, Addon.Session, Addon.Unit, Addon.Util
local Self = Addon.RCLC

Self.NAME = "RCLootCouncil"
Self.VERSION = "2.9.0"
Self.PREFIX = "RCLootCouncil"

Self.CMD_VERSION_CHECK = "verTest"
Self.CMD_VERSION = "verTestReply"
Self.CMD_PLAYER_INFO_REQ = "playerInfoRequest"
Self.CMD_PLAYER_INFO = "playerInfo"
Self.CMD_RULES_REQ = "MLdb_request"
Self.CMD_RULES = "MLdb"
Self.CMD_COUNCIL_REQ = "council_request"
Self.CMD_COUNCIL = "council"
Self.CMD_SYNC_REQ = "reconnect"
Self.CMD_SYNC = "reconnectData"

Self.CMD_SESSION_START = "lootTable"
Self.CMD_SESSION_ADD = "lt_add"
Self.CMD_SESSION_ACK = "lootAck"
Self.CMD_SESSION_END = "session_end"
Self.CMD_SESSION_RANDOM = "rolls"

Self.CMD_ROLL_TRADABLE = "tradable"
Self.CMD_ROLL_UNTRADABLE = "not_tradable"
Self.CMD_ROLL_TRADE = "trade_complete"
Self.CMD_ROLL_KEEP = "rejected_trade"
Self.CMD_ROLL_AWARDED = "awarded"
Self.CMD_ROLL_REROLL = "reroll"
Self.CMD_ROLL_VOTE = "vote"
Self.CMD_ROLL_BID = "response"
Self.CMD_ROLL_BID_CHANGE = "change_response"
Self.CMD_ROLL_LOOTED = "bagged"
Self.CMD_ROLL_RANDOM = "roll"
Self.CMD_ROLL_RESTART = "reroll"

Self.RESP_PASS = "PASS"
Self.RESP_REMOVED = "REMOVED"
Self.RESP_WAIT = "WAIT"

Self.mldb = nil
Self.session = {}

function Self.IsUsedByUnit(unit)
    return Util.StrStartsWith(Addon.compAddonUsers[Unit.Name(unit)], Self.NAME)
end

function Self.FindOrAddRoll(link, itemOwner, owner)
    return Roll.Find(nil, owner, link, nil, itemOwner) or Roll.Add(Item.FromLink(link, itemOwner or owner), owner or itemOwner)
end

-------------------------------------------------------
--                    Translation                    --
-------------------------------------------------------

--- Translate a RCLC mldb to PLR session rules
-- From RCLootCouncil:
-- selfVote        = db.selfVote or nil
-- multiVote       = db.multiVote or nil
-- anonymousVoting = db.anonymousVoting or nil
-- allowNotes      = db.allowNotes or nil
-- numButtons      = db.buttons.default.numButtons
-- hideVotes       = db.hideVotes or nil
-- observe         = db.observe or nil
-- buttons         = changedButtons
-- responses       = changedResponses
-- timeout         = db.timeout
-- rejectTrade     = db.rejectTrade or nil
function Self.MldbToRules(mldb)
    Self.mldb = mldb

    local needAnswers, greedAnswers = Util.Tbl(), Util.Tbl()
    for i=1,mldb.buttons.maxButtons do
        local answer = Util.TblGet(mldb.buttons.default, i, "text")
        if answer then
            tinsert((answer == GREED or greedAnswers[1]) and greedAnswers or needAnswers, answer)
        end
    end

    Session.SetRules({
        timeoutBase = mldb.timeout or Roll.TIMEOUT,
        timeoutPerItem = 0,
        bidPublic = mldb.observe or false,
        votePublic = not mldb.anonymousVoting,
        answers1 = needAnswers,
        answers2 = greedAnswers,
        council = Session.rules.council or {}
    })
end

-- Translate a RCLC response to a PLR bid
function Self.ResponseToBid(resp)
    local numNeedAnswers = #Session.rules.needAnswers

    if resp == Self.RESP_PASS then
        return Roll.BID_PASS
    elseif type(resp) == "number" then
        if resp - 1 <= numNeedAnswers then
            return Roll.BID_NEED + (resp - 1)/10
        else
            return Roll.BID_GREED + (resp - numNeedAnswers - 2)/10
        end
    end
end

-- Translate a PLR bid to a RCLC response
function Self.BidToResponse(bid)
    if bid == Roll.BID_PASS then
        return Self.RESP_PASS
    else
        return 1 + (floor(bid) - 1) * (#needAnswers + 1) + (bid - floor(bid)) * 10
    end
end

-------------------------------------------------------
--                        Comm                       --
-------------------------------------------------------

-- Send a RCLC message
function Self.Send(cmd, target, ...)
    if not Self:IsEnabled() then return end

    local data = Util.Tbl(cmd, Util.Tbl(...))
    Comm.SendData(Self.PREFIX, data, target)
    Util.TblRelease(1, data)
end

-- Process incoming RCLC message
Comm.Listen(Self.PREFIX, function (event, msg, channel, _, unit)
    if not Self:IsEnabled() or Addon.versions[unit] then return end

    local success, cmd, data = Self:Deserialize(msg)
    if not success then return end

    local ml = Session.GetMasterlooter() or Unit.GroupLeader()
    local fromML = ml and UnitIsUnit(ml, unit)
    local isML = Unit.IsSelf(ml)

    -- VERSION_CHECK
    if cmd == Self.CMD_VERSION_CHECK then
        Addon:SetCompAddonUser(unit, Self.NAME, data[1])
        local class, rank = select(2, UnitClass("player")), select(2, GetGuildInfo("player"))
        Self.Send(Self.CMD_VERSION, channel == Comm.TYPE_WHISPER and unit or channel, Unit.FullName("player"), class, rank, Self.VERSION)
    
    -- VERSION
    elseif cmd == Self.CMD_VERSION then
        Addon:SetCompAddonUser(unit, Self.NAME, data[4])
    
    -- PLAYER_INFO_REQ
    elseif cmd == Self.CMD_PLAYER_INFO_REQ then
        local class, role, rank, ilvl, spec = select(2, UnitClass("player")), UnitGroupRolesAssigned("player"), select(2, GetGuildInfo("player")), select(2, GetAverageItemLevel()), GetSpecializationInfo(GetSpecialization())
        Self.Send(Self.CMD_PLAYER_INFO, unit, Unit.FullName("player"), class, role, rank, Unit.IsEnchanter(), 150, ilvl, spec)

    -- TRADABLE
    elseif cmd == Self.CMD_ROLL_TRADABLE then
        local roll = Self.FindOrAddRoll(data[1], unit, ml)
        roll.item.isTradable = true
    
    -- UNTRADABLE
    elseif cmd == Self.CMD_ROLL_UNTRADABLE then
        local roll = Self.FindOrAddRoll(data[1], unit)
        roll.item.isTradable = false
        roll:Cancel()

    -- KEEP
    elseif cmd == Self.CMD_ROLL_KEEP then
        local roll = Self.FindOrAddRoll(data[1], unit)
        roll.item.isTradable = true
        roll:Bid(Roll.BID_NEED, unit, nil, true):End(unit, true)

    -- BID
    elseif cmd == Self.CMD_ROLL_BID or Self.CMD_ROLL_BID_CHANGE then
        local sId, fromUnit, resp = unpack(data)
        local roll, bid = Self.session[sId], Self.ResponseToBid(type(resp) == "table" and resp.response or resp)
        if roll and bid and (fromML or unit == Unit(fromUnit)) then
            roll:Bid(bid, fromUnit, nil, fromML)
        end
    
    -- VOTE
    elseif cmd == Self.CMD_ROLL_VOTE then
        local sId, vote, n = unpack(data)
        local roll, vote = Self.session[sId], n > 0 and vote or nil
        if roll then
            roll:Vote(vote, unit)
        end

    -- RANDOM
    elseif cmd == Self.CMD_ROLL_RANDOM then
        -- TODO
        
    elseif fromML then
        -- RULES
        if cmd == Self.CMD_RULES then
            Session.SetMasterlooter(unit)
            Self.MldbToRules(data)

        -- COUNCIL
        elseif cmd == Self.CMD_COUNCIL then
            wipe(Session.rules.council)
            for _,v in pairs(council) do
                Session.rules.council[Unit.FullName(v)] = true
            end
            Session.SetRules(Session.rules)

        -- SYNC
        elseif cmd == Self.CMD_SYNC then
            -- TODO

        -- SESSION_START/SESSION_ADD
        elseif cmd == Self.CMD_SESSION_START or cmd == Self.CMD_SESSION_ADD then
            local ack = Util.TblHash("gear1", Util.Tbl(), "gear2", Util.Tbl(), "diff", Util.Tbl(), "response", Util.Tbl())

            for sId,v in pairs(data[1]) do
                sId = v.session or sId
                if not Self.session[sId] then
                    local roll = Self.FindOrAddRoll(v.link, v.owner, ml):Start()
                    Self.session[sId] = roll

                    local gear = roll.item:GetEquippedForLocation("player")
                    gear1[sId] = gear[1] or nil
                    gear2[sId] = gear[2] or nil
                    diff[sId] = (roll.item:GetBasicInfo().level or 0) - max(Item.GetInfo(gear[1], "level") or 0, Item.GetInfo(gear[2], "level") or 0) -- TODO: This is wrong when slots are not filled
                    response[sId] = not roll.item:GetEligible("player") or nil
                    
                    if not roll.item.isRelic then Util.TblRelease(gear) end
                end
            end

            if Util.TblCount(ack.diff) > 0 then
                local spec, ilvl = GetSpecializationInfo(GetSpecialization()), select(2, GetAverageItemLevel())
                Self.Send(Self.CMD_SESSION_ACK, Comm.TYPE_GROUP, Unit.FullName("player"), spec, ilvl, ack)
            end

            Util.TblRelease(1, ack)

        -- SESSION_END
        elseif cmd == Self.CMD_SESSION_END then
            for sId,roll in pairs(Self.session) do
                if Util.In(roll.status, Roll.STATUS_PENDING, Roll.STATUS_RUNNING) then
                    roll:Cancel()
                end
            end
            wipe(Self.session)

        -- SESSION_RANDOMS
        elseif cmd == Self.CMD_SESSION_RANDOMS then
            -- TODO

        -- REROLL
        elseif cmd == Self.CMD_ROLL_REROLL then
            -- TODO

        -- AWARDED
        elseif cmd == Self.CMD_ROLL_AWARDED then
            local sId, winner = unpack(data)
            local roll = Self.session[sId]
            if roll and winner then
                roll:End(winner, nil, true)
            end
        end
    end
end)

-------------------------------------------------------
--                    Events/Hooks                   --
-------------------------------------------------------

function Self:OnInitialize()
    Self:SetEnabledState(not IsAddOnLoaded(Self.NAME))
end

function Self:OnEnable()
    -- Register events
    Self:RegisterEvent("GROUP_JOINED")
    Roll.On(Self, Roll.EVENT_ADD, "ROLL_ADD")
    Roll.On(Self, Roll.EVENT_BID, "ROLL_BID")
    Roll.On(Self, Roll.EVENT_VOTE, "ROLL_VOTE")
    Roll.On(Self, Roll.EVENT_TRADE, "ROLL_TRADE")
end

function Self:OnDisable()
    -- Unregister events
    Roll.Unsubscribe(Self)
end

function Self.GROUP_JOINED()
    Self.Send(Self.CMD_VERSION_CHECK, Comm.TYPE_GROUP, Self.VERSION)
end

-- Roll.EVENT_ADD
function Self.ROLL_ADD(_, _, roll)
    -- TODO
end

-- Roll.EVENT_BID
function Self.ROLL_BID(_, _, roll, bid, fromUnit, rollResult, isImport)
    -- TODO
end

-- Roll.EVENT_VOTE
function Self.ROLL_VOTE(_, _, roll, vote, fromUnit, isImport)
    -- TODO
end

-- Roll.EVENT_TRADE
function Self.ROLL_TRADE(_, _, roll, target)
    -- TODO
end