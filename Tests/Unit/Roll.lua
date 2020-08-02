if not WoWUnit then return end

---@type string
local Name = ...
---@type Addon
local Addon = select(2, ...)
local Item, Roll, Session, Test, Util = Addon.Item, Addon.Roll, Addon.Session, Addon.Test, Addon.Util
local Assert, AssertEqual, AssertFalse, Replace = WoWUnit.IsTrue, WoWUnit.AreEqual, WoWUnit.IsFalse, WoWUnit.Replace

local Tests = WoWUnit(Name .. ".Unit.Roll")

local GetUpdateData = function (roll, eligible, started, bidPublic, votePublic)
    local data = Util(roll):Copy():Select(
        "owner", "ownerId", "itemOwnerId", "status", "started",
        "timeout", "posted", "winner", "traded"
    )()

    data.disenchant = roll.disenchant or nil
    data.item ={
        link = roll.item.link,
        owner = roll.item.owner,
        isTradable = roll.item.isTradable or nil,
        eligible = eligible or 2
    }
    data.started = started or time() - 2

    if bidPublic then
        data.bids = roll.bids
        data.rolls = roll.rolls
    end
    if votePublic then
        data.votes = roll.votes
    end

    return data
end

local AssertRoll = function (roll, id, started, dump)
    local check = Addon.rolls[id]
    local item = Item.FromLink(roll.item.link, roll.item.owner, nil, nil, roll.item.isTradable)
    local running = roll.status >= Roll.STATUS_RUNNING or nil

    AssertEqual({
        id = id,
        ownerId = roll.ownerId,
        owner = roll.owner,
        isOwner = roll.isOwner,
        status = roll.status,
        itemOwnerId = roll.itemOwnerId,
        timeout = roll.timeout,
        disenchant = roll.disenchant,
        item = check.item.infoLevel > 0 and item:GetFullInfo() or item,
        created = check.created,
        started = started or check.started,
        timers = {bid = running or nil},
        votes = {},
        rolls = {},
        bids = {},
        whispers = 0
    }, check)
end

function Tests:GetTest()
    local obj = {}
    Replace(Addon, "rolls", {[1] = obj})
    AssertEqual(Roll.Get(1), obj)
    AssertFalse(Roll.Get(2))
end

function Tests:FindTest()
    Test.ReplaceDefault()
    Replace(Addon, "rolls", Test.rolls)

    -- Find by id and owner
    AssertEqual(Test.rolls[1], Roll.Find(1, "player"))
    AssertEqual(Test.rolls[2], Roll.Find(2, "player"))
    AssertEqual(Test.rolls[3], Roll.Find(1, "party1"))
    AssertEqual(Test.rolls[5], Roll.Find(3, "party2"))
    AssertEqual(Test.rolls[6], Roll.Find(4, "party2"))
    AssertEqual(Test.rolls[7], Roll.Find(5, "party3"))
    AssertEqual(Test.rolls[8], Roll.Find(6, "party3"))
    AssertFalse(Roll.Find(4, "player"))
    AssertFalse(Roll.Find(2, "party1"))
    -- Find by owner and item
    AssertEqual(Test.rolls[1], Roll.Find(nil, "player", Test.items.item1[2]))
    AssertEqual(Test.rolls[2], Roll.Find(nil, "player", Test.items.item2[2]))
    AssertEqual(Test.rolls[3], Roll.Find(nil, "party1", Test.items.item3[2]))
    AssertEqual(Test.rolls[5], Roll.Find(nil, "party2", Test.items.item5[2]))
    AssertEqual(Test.rolls[6], Roll.Find(nil, "party2", Test.items.item6[2]))
    AssertEqual(Test.rolls[7], Roll.Find(nil, "party3", Test.items.item7[2]))
    AssertEqual(Test.rolls[8], Roll.Find(nil, "party3", Test.items.item8[2]))
    AssertFalse(Roll.Find(nil, "player", "item7"))
    AssertFalse(Roll.Find(nil, "party1", "item8"))
    -- Find by item owner and item owner id
    AssertEqual(Test.rolls[1], Roll.Find(nil, nil, nil, 1, "player"))
    AssertEqual(Test.rolls[2], Roll.Find(nil, nil, nil, 2, "player"))
    AssertEqual(Test.rolls[3], Roll.Find(nil, nil, nil, 1, "party1"))
    AssertEqual(Test.rolls[5], Roll.Find(nil, nil, nil, 3, "party2"))
    AssertEqual(Test.rolls[6], Roll.Find(nil, nil, nil, 4, "party2"))
    AssertEqual(Test.rolls[7], Roll.Find(nil, nil, nil, 7, "player"))
    AssertEqual(Test.rolls[8], Roll.Find(nil, nil, nil, 2, "party1"))
    AssertFalse(Roll.Find(nil, nil, nil, 3, "player"))
    AssertFalse(Roll.Find(nil, nil, nil, 3, "party1"))
    AssertFalse(Roll.Find(nil, nil, nil, 7, "party3"))
    AssertFalse(Roll.Find(nil, nil, nil, 2, "party3"))
    -- Find by id, owner and status
    AssertEqual(Test.rolls[1], Roll.Find(1, "player", nil, nil, nil, Roll.STATUS_RUNNING))
    AssertEqual(Test.rolls[2], Roll.Find(2, "player", nil, nil, nil, Roll.STATUS_DONE))
    AssertEqual(Test.rolls[3], Roll.Find(1, "party1", nil, nil, nil, Roll.STATUS_RUNNING))
    AssertFalse(Roll.Find(1, "player", nil, nil, nil, Roll.STATUS_DONE))
    AssertFalse(Roll.Find(2, "player", nil, nil, nil, Roll.STATUS_CANCELED))
    AssertFalse(Roll.Find(1, "party1", nil, nil, nil, Roll.STATUS_PENDING))
end

function Tests:FindWhereTest()
    Replace(Addon, "rolls", Test.rolls)

    for _,roll in ipairs(Test.rolls) do
        AssertEqual(roll, Roll.FindWhere(roll))

        local args = {}
        for k,v in pairs(roll) do
            table.insert(args, k)
            table.insert(args, v)
        end
        AssertEqual(roll, Roll.FindWhere(unpack(args)))
    end

    AssertFalse(Roll.FindWhere({id = 4}))
    AssertFalse(Roll.FindWhere({id = 1, owner = "party1"}))
end

function Tests:AddTest()
    Test.ReplaceDefault()
    Replace(Addon, "rolls", Util.Counter.New())
    Replace(Roll, "CalculateTimeout", function () return 30 end)

    local AssertEvents = Test.ReplaceFunction(Addon, "SendMessage", false)

    local roll

    -- Item owned by the player
    roll = Util.Tbl.CopyDeep(Test.roll)
    roll.disenchant = false
    Roll.Add(roll.item.link, roll.owner)
    AssertRoll(roll, 1, nil, true)
    AssertEvents(1)

    -- Item owned by someone else
    roll = Util.Tbl.CopyDeep(Test.roll)
    roll.owner = Test.units.party1.name
    roll.isOwner = false
    roll.item.owner = roll.owner
    roll.item.isOwner = false
    roll.ownerId = 2
    roll.itemOwnerId = 2
    roll.timeout = 60
    roll.disenchant = true
    Roll.Add(roll.item.link, roll.owner, roll.ownerId, roll.itemOwnerId, roll.timeout, roll.disenchant)
    AssertRoll(roll, 2)
    AssertEvents(1)

    -- TODO: Item owned by masterlooter
end

function Tests.UpdateTest()
    Test.ReplaceDefault()
    Replace(Addon, "rolls", Util.Counter.New())
    Replace(Addon, "ScheduleTimer", function () return true end)

    local ml = nil
    Replace(Session, "GetMasterlooter", function () return ml end)

    local AssertEvents = Test.ReplaceFunction(Addon, "SendMessage", false)

    local roll

    -- Send roll
    roll = Test.rolls[3]
    Assert(Roll.Update(GetUpdateData(roll), roll.owner))
    AssertRoll(roll, 1)
    AssertEvents(3)

    -- Send again
    Assert(Roll.Update(GetUpdateData(roll), roll.owner))
    AssertFalse(Addon.rolls[2])
    AssertRoll(roll, 1)
    AssertEvents(0)

    -- Send again with different owner
    AssertFalse(Roll.Update(GetUpdateData(roll), Test.units.party2.name))
    AssertEvents(0)

    -- Send roll with unit different from item owner
    roll = Test.rolls[5]
    AssertFalse(Roll.Update(GetUpdateData(roll), Test.units.party1.name))
    AssertEvents(0)

    -- Send again with correct owner
    Assert(Roll.Update(GetUpdateData(roll), roll.owner))
    AssertRoll(roll, 2)
    AssertEvents(1)

    -- Send roll with owner different from item owner
    roll = Util.Tbl.CopyDeep(Test.rolls[8])
    roll.status = Roll.STATUS_PENDING
    Assert(Roll.Update(GetUpdateData(roll), roll.item.owner))
    AssertRoll(roll, 3)
    AssertEvents(1)

    -- Send update from owner with different ownerId
    roll.ownerId = 7
    Assert(Roll.Update(GetUpdateData(roll), roll.owner))
    AssertRoll(roll, 3)
    AssertFalse(Addon.rolls[4])
    AssertEvents(0)

    -- TODO: Send roll from ML
    -- TODO: Send update from ML
    -- TODO: Send roll and go through statuses
    -- TODO: Send trade from winner
    -- TODO: Send trade from item owner
end

function Tests.ClearTest()
    -- TODO
end

function Tests.TestTest()
    -- TODO
end

function Tests.PlrIdTest()
    -- TODO: isPlrId
    -- TODO: ToPlrId
    -- TODO: FromPlrId
    -- TODO: GetPlrId
end

function Tests.StartTest()
    -- TODO
end

function Tests.ScheduleTest()
    -- TODO
end

function Tests.RestartTest()
    -- TODO
end

function Tests.AdoptTest()
    -- TODO
end

function Tests.BidTest()
    -- TODO
end

function Tests.VoteTest()
    -- TODO
end

function Tests.ShouldEndTest()
    -- TODO
end

function Tests.EndTest()
    -- TODO
end

function Tests.CancelTest()
    -- TODO
end

function Tests.TradeTest()
    -- TODO: Trade
    -- TODO: OnTraded
end

function Tests.SetStatusTest()
    -- TODO
end

function Tests.DetermineWinnerTest()
    -- TODO
end

function Tests.ValidateTest()
    -- TODO
end

function Tests.ValidateBidTest()
    -- TODO
end

function Tests.ValidateVoteTest()
    -- TODO
end

function Tests.RollFrameTest()
    -- TODO: GetRollFrame
    -- TODO: ShowRollFrame
    -- TODO: HideRollFrame
end

function Tests.ToggleVisibilityTest()
    -- TODO
end

function Tests.AddChatTest()
    -- TODO
end

function Tests.ShouldAdvertiseTest()
    -- TODO
end

function Tests.ShouldBeConciseTest()
    local g = Addon.db.profile.messages.group
    Replace(g, "concise", false)
    Replace(Util, "GetNumDroppedItems", Test.Const(1))
    Replace(Util, "IsLegacyLoot", Test.Const(false))
    Replace(Util, "IsLegacyRun", Test.Const(false))
    Replace("GetNumGroupMembers", Test.Const(1))
    local roll = {
        HasMasterlooter = Test.Const(false),
        item = { GetNumEligible = Test.Const(2) }
    }
    local testFn = function () return Roll.ShouldBeConcise(roll) end

    -- Concise setting
    AssertFalse(testFn())
    Replace(g, "concise", true)
    Assert(testFn())
    -- Masterlooter
    Replace(roll, "HasMasterlooter", Test.Const(true))
    AssertFalse(testFn())
    Replace(roll, "HasMasterlooter", Test.Const(false))
    -- # of dropped items
    Replace(Util, "GetNumDroppedItems", Test.Const(2))
    AssertFalse(testFn())
    -- # of eligible players
    Replace(roll.item, "GetNumEligible", Test.Const(1))
    Assert(testFn())
    Replace(roll.item, "GetNumEligible", Test.Const(2))
    -- Legacy loot
    Replace(Util, "IsLegacyLoot", Test.Const(true))
    Replace(Util, "IsLegacyRun", Test.Const(true))
    Assert(testFn())
    for i=2,40 do
        Replace("GetNumGroupMembers", Test.Const(i))
        AssertEqual(i <= Roll.CONCISE_LEGACY_SIZE, testFn())
    end
end

function Tests.AdvertiseTest()
    -- TODO
end

function Tests.SendStatusTest()
    -- TODO
end

function Tests.GetRunTimeTest()
    -- TODO
end

function Tests.GetTimeLeftTest()
    -- TODO
end

function Tests.ExtendTimeoutTest()
    -- TODO: ExtendTimeout
end

function Tests.ExtendTimeLeftTest()
    -- TODO
end

function Tests.CalculateTimeoutTest()
    -- TODO
end

function Tests.ShouldBeBidOnTest()
    -- TODO
end

function Tests.UnitisEligibleTest()
    -- TODO
end

function Tests.CanBeWonTest()
    -- TODO
end

function Tests.UnitCanWinTest()
    -- TODO
end

function Tests.CanBeAwardedTest()
    -- TODO
end

function Tests.CanBeAwardedToTest()
    -- TODO
end

function Tests.CanBeGivenToTest()
    -- TODO
end

function Tests.CanBeAwardedRandomlyTest()
    -- TODO
end

function Tests.UnitCanBidTest()
    -- TODO
end

function Tests.UnitCanVoteTest()
    -- TODO
end

function Tests.UnitIsInvolvedTest()
    -- TODO
end

function Tests.CanBeStartedTest()
    -- TODO
end

function Tests.CanBeRunTest()
    -- TODO
end

function Tests.CanBeRestartedTest()
    -- TODO
end

function Tests.HasMasterlooterTest()
    -- TODO
end

function Tests.IsMasterlooterTest()
    -- TODO
end

function Tests.GetOwnerAddonTest()
    -- TODO
end

function Tests.GetActionRequiredTest()
    -- TODO
end

function Tests.GetActionTargetTest()
    -- TODO
end

function Tests.IsActiveTest()
    -- TODO
end

function Tests.IsRecentTest()
    -- TODO
end

function Tests.GetBidNameTest()
    -- TODO
end
