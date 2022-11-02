---@type string
local Name = ...
---@type Addon
local Addon = select(2, ...)
local Comm, Item, Roll, Session, Unit, Util = Addon.Comm, Addon.Item, Addon.Roll, Addon.Session, Addon.Unit, Addon.Util
---@class RCLC : Module
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
Self.CMD_CANDIDATES = "candidates"
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
Self.council = nil
Self.offerShown = nil

Self.session = {}
Self.timers = {}

---@param link string
---@param itemOwner string
---@param owner string?
---@return Roll
function Self.FindOrAddRoll(link, itemOwner, owner)
    return Roll.Find(nil, owner, link, nil, itemOwner) or Roll.Add(Item.FromLink(link, itemOwner or owner), owner or itemOwner)
end

-------------------------------------------------------
--                    Translation                    --
-------------------------------------------------------

-- Set a new ML
function Self.SetMasterlooter(unit)
    Session.SetMasterlooter(unit)

    Self.SetRules()
    Self.SetCouncil()
end

-- Translate a RCLC mldb to PLR session rules
-- From RCLootCouncil:
-- selfVote        = db.selfVote or nil
-- multiVote       = db.multiVote or nil
-- allowNotes      = db.allowNotes or nil
-- anonymousVoting = db.anonymousVoting or nil
-- numButtons      = db.numButtons
-- hideVotes       = db.hideVotes or nil
-- observe         = db.observe or nil
-- buttons         = changedButtons
-- responses       = changedResponses
-- timeout         = db.timeout
-- rejectTrade     = db.rejectTrade or nil
---@param mldb table?
function Self.SetRules(mldb)
    Self.mldb = mldb or Self.mldb

    if Self.mldb then
        local needAnswers, greedAnswers = Util.Tbl.New(), Util.Tbl.New()
        for i=1,Self.mldb.numButtons do
            local answer = Util.Tbl.Get(Self.mldb.buttons.default, i, "text")
            if answer then
                tinsert((answer == GREED or greedAnswers[1]) and greedAnswers or needAnswers, answer)
            end
        end

        Session.SetRules({
            timeoutBase = Self.mldb.timeout or 0,
            timeoutPerItem = 0,
            bidPublic = true, -- Self.mldb.observe or false,
            votePublic = true, -- not Self.mldb.anonymousVoting,
            answers1 = needAnswers,
            answers2 = greedAnswers,
            council = Session.rules.council or Util.Tbl.New()
        })
    else
        Self.Send(Self.CMD_RULES_REQ)
    end
end

-- Set the council members
function Self.SetCouncil(council)
    Self.council = council or Self.council

    local ml = Session.GetMasterlooter()

    if not Self.council then
        Self.Send(Self.CMD_COUNCIL_REQ)
    elseif ml and Session.rules.council then
        wipe(Session.rules.council)

        for _,v in pairs(Self.council) do
            if not Unit.IsUnit(Unit(v), ml) then
                Session.rules.council[v] = true
            end
        end

        Session.SetRules(Session.rules)
    end
end

-- Translate a RCLC response to a PLR bid
---@param resp string
function Self.ResponseToBid(resp)
    local numNeedAnswers = #Session.rules.answers1

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
        return 1 + (floor(bid) - 1) * (#Session.rules.answers1 + 1) + (bid - floor(bid)) * 10
    end
end

-------------------------------------------------------
--                        Comm                       --
-------------------------------------------------------

-- Send a RCLC message
---@param cmd string
---@param target string?
function Self.Send(cmd, target, ...)
    if not Self:IsEnabled() then return end
    print("RCLC:OUT", cmd, target, ...)

    local data = Util.Tbl.New(...)
    Comm.Send(Self.PREFIX, Self:Serialize(cmd, data), target)
    Util.Tbl.Release(data)
end

-- Process incoming RCLC message
Comm.Listen(Self.PREFIX, function (event, msg, channel, _, unit)
    if not Self:IsEnabled() or Addon.versions[unit] then return end

    local success, cmd, data = Self:Deserialize(msg)
    if not success then return end

    local ml = Session.GetMasterlooter()
    local fromGL = Unit.IsUnit(unit, Unit.GroupLeader())
    local fromML = Unit.IsUnit(unit, ml)
    local isML = Unit.IsSelf(ml)

    print("RCLC:IN", cmd, data, channel, unit, fromGL, fromML)

    -- VERSION_CHECK
    if cmd == Self.CMD_VERSION_CHECK then
        if channel ~= Self.TYPE_WHISPER and Self.timers.version then
            Self:CancelTimer(Self.timers.version)
            Self.timers.version = nil
        end

        Addon:SetCompAddonUser(unit, Self.NAME, data[1])
        Session.SetMasterlooting(unit, Unit.GroupLeader())

        local class, rank = select(2, UnitClass("player")), select(2, GetGuildInfo("player"))
        Self.Send(Self.CMD_VERSION, channel == Comm.TYPE_WHISPER and unit or channel, Unit.FullName("player"), class, rank, Self.VERSION)

    -- VERSION
    elseif cmd == Self.CMD_VERSION then
        Addon:SetCompAddonUser(unit, Self.NAME, data[4])
        Session.SetMasterlooting(unit, Unit.GroupLeader())

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
    elseif Util.In(cmd, Self.CMD_ROLL_BID, Self.CMD_ROLL_BID_CHANGE) then
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

    -- ML messages
    elseif fromML then
        -- RULES
        if cmd == Self.CMD_RULES then
            Self.SetRules(data[1])

        -- COUNCIL
        elseif cmd == Self.CMD_COUNCIL then
            Self.SetCouncil(data[1])

        -- SESSION_START/SESSION_ADD
        elseif Util.In(cmd, Self.CMD_SESSION_START, Self.CMD_SESSION_ADD, Self.CMD_SYNC) then
            Util.Dump(data[1])
            local ack = Util.Tbl.Hash("gear1", Util.Tbl.New(), "gear2", Util.Tbl.New(), "diff", Util.Tbl.New(), "response", Util.Tbl.New())

            for sId,v in pairs(data[1]) do
                sId = v.session or sId
                if not Self.session[sId] then
                    local roll = Self.FindOrAddRoll(v.link, v.owner, ml):Start()
                    Self.session[sId] = roll

                    local gear = roll.item:GetEquippedForLocation("player")
                    ack.gear1[sId] = gear[1] or nil
                    ack.gear2[sId] = gear[2] or nil
                    ack.diff[sId] = (roll.item:GetBasicInfo().level or 0) - max(Item.GetInfo(gear[1], "level") or 0, Item.GetInfo(gear[2], "level") or 0) -- TODO: This is wrong when slots are not filled
                    ack.response[sId] = not roll.item:GetEligible("player") or nil

                    if not roll.item:IsRelic() then Util.Tbl.Release(gear) end
                end
            end

            if Util.Tbl.Count(ack.diff) > 0 then
                local spec, ilvl = GetSpecializationInfo(GetSpecialization()), select(2, GetAverageItemLevel())
                Self.Send(Self.CMD_SESSION_ACK, Comm.TYPE_GROUP, Unit.FullName("player"), spec, ilvl, ack)
            end

            Util.Tbl.Release(1, ack)

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

    -- GL messages
    elseif fromGL then
        -- RULES
        if cmd == Self.CMD_RULES then
            Self.mldb = data[1]

            if not Session.GetMasterlooter() and Session.UnitAllow(unit) then
                if Session.UnitAccept(unit) then
                    Self.SetMasterlooter(unit)
                elseif not Self.offerShown then
                    Self.offerShown = true
                    Session.ShowOfferDialog(unit, function ()
                        Self.offerShown = nil
                        Self.SetMasterlooter(unit)
                    end)
                end
            end
        elseif cmd == Self.CMD_COUNCIL then
            Self.council = data[1]
        end
    end
end)

-------------------------------------------------------
--                    Events/Hooks                   --
-------------------------------------------------------

function Self:ShouldBeEnabled()
    return not IsAddOnLoaded(Self.NAME)
        and Addon:IsActive()
        and false -- TODO
end

function Self:OnInitialize()
    Self:CheckState()
    Self:RegisterMessage(Addon.EVENT_ACTIVE_CHANGE, Self.CheckState)
end

function Self:OnEnable()
    -- Register events
    Self:RegisterEvent("PARTY_LEADER_CHANGED")
    Self:RegisterMessage(Roll.EVENT_ADD, "ROLL_ADD")
    Self:RegisterMessage(Roll.EVENT_BID, "ROLL_BID")
    Self:RegisterMessage(Roll.EVENT_VOTE, "ROLL_VOTE")
    Self:RegisterMessage(Roll.EVENT_TRADE, "ROLL_TRADE")
    Self:RegisterMessage(Session.EVENT_REQUEST, "SESSION_REQUEST")

    -- Send version check
    Self.timers.version = Self:ScheduleTimer(Self.Send, 5, Self.CMD_VERSION_CHECK, Comm.TYPE_GROUP, Self.VERSION)
    Self.timers.sync = Self:ScheduleTimer(Self.Send, 5, Self.CMD_SYNC_REQ)
end

function Self:OnDisable()
    Self:UnregisterAllEvents()
    Self:UnregisterMessage(Roll.EVENT_ADD)
    Self:UnregisterMessage(Roll.EVENT_BID)
    Self:UnregisterMessage(Roll.EVENT_VOTE)
    Self:UnregisterMessage(Roll.EVENT_TRADE)
    Self:UnregisterMessage(Session.EVENT_REQUEST)
end

function Self:PARTY_LEADER_CHANGED()
    Self.mldb, Self.council, Self.offerShown = nil
    wipe(Self.session)

    local ml = Session.GetMasterlooter()
    if ml and Addon:GetCompAddonUser(ml, Self.NAME) then
        Session.SetMasterlooter(nil)
    end
end

---@param roll Roll
function Self:ROLL_ADD(_, roll)
    -- TODO
end

---@param roll Roll
---@param bid number
---@param fromUnit string
---@param rollResult integer
---@param isImport boolean
function Self:ROLL_BID(_, roll, bid, fromUnit, rollResult, isImport)
    local sId = Util.Tbl.Find(Self.session, roll)
    if sId and Unit.IsSelf(fromUnit) and not isImport then
        Self.Send(Self.CMD_ROLL_BID, Comm.TYPE_GROUP, sId, Unit.FullName("player"), {response = Self.BidToResponse(roll.bid)})
    end
end

---@param roll Roll
---@param vote string
---@param fromUnit string
---@param isImport boolean
function Self:ROLL_VOTE(_, roll, vote, fromUnit, isImport)
    -- TODO
end

---@param roll Roll
---@param target string
function Self:ROLL_TRADE(_, roll, target)
    -- TODO
end

---@param target string
function Self:SESSION_REQUEST(_, target)
    if not target or UnitIsGroupLeader(target) then
        Self.offerShown = nil
        Self.Send(Self.CMD_RULES_REQ)
    end
end