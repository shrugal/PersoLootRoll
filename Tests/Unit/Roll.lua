if not WoWUnit then return end

---@type string
local Name = ...
---@type Addon
local Addon = select(2, ...)
local Roll, Test, Util = Addon.Roll, Addon.Test, Addon.Util
local Assert, AssertEqual, AssertFalse, Replace = WoWUnit.IsTrue, WoWUnit.AreEqual, WoWUnit.IsFalse, WoWUnit.Replace

local Tests = WoWUnit(Name .. ".Unit.Roll")

local GetUpdateData = function (roll, eligible, bidPublic, votePublic)
    local data = Util(roll).Copy().Select(
        "owner", "ownerId", "itemOwnerId", "status", "started",
        "timeout", "posted", "winner", "traded"
    )()

    data.id = data.ownerId
    data.disenchant = roll.disenchant or nil
    data.item ={
        link = roll.item.link,
        owner = roll.item.owner,
        isTradable = roll.item.isTradable or nil,
        eligible = eligible or 1
    }

    if bidPublic then
        data.bids = roll.bids
        data.rolls = roll.rolls
    end
    if votePublic then
        data.votes = roll.votes
    end

    return data
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
    Replace(Addon, "rolls", Util.TblCounter())
    Replace(Roll, "CalculateTimeout", function () return 30 end)
    local AssertDebugCalled = Test.ReplaceFunction(Addon, "Debug", false)
    local AssertSendMessageCalled = Test.ReplaceFunction(Addon, "SendMessage", false)

    -- Item owned by the player
    local roll = Roll.Add(Test.items.item1[2], Test.units.player.name)
    AssertEqual({
        disenchant = false,
        timers = {},
        whispers = 0,
        votes = {},
        item = {
            isOwner = true,
            infoLevel = 0,
            link = Test.items.item1[2],
            position = {},
            owner = Test.units.player.name
        },
        status = 0,
        created = time(),
        rolls = {},
        timeout = 30,
        id = 1,
        owner = Test.units.player.name,
        ownerId = 1,
        isOwner = true,
        itemOwnerId = 1,
        bids = {}
    }, roll)
    AssertEqual(roll, Addon.rolls[1])
    AssertDebugCalled()
    AssertSendMessageCalled()

    -- Item owned by someone else
    roll = Roll.Add(Test.items.item2[2], Test.units.party1.name, 2, 1, 60, true)
    AssertEqual({
        disenchant = true,
        timers = {},
        whispers = 0,
        votes = {},
        item = {
            isOwner = false,
            infoLevel = 0,
            link = Test.items.item2[2],
            position = {},
            owner = Test.units.party1.name
        },
        status = 0,
        created = time(),
        rolls = {},
        timeout = 60,
        id = 2,
        owner = Test.units.party1.name,
        ownerId = 2,
        isOwner = false,
        itemOwnerId = 1,
        bids = {}
    }, roll)
    AssertEqual(roll, Addon.rolls[2])
    AssertDebugCalled(2)
    AssertSendMessageCalled(2)

    -- TODO: Item owned by masterlooter
end

function Tests.UpdateTest()
    Test.ReplaceDefault()
    Replace(Addon, "rolls", Util.TblCounter())

    local data = GetUpdateData(Test.rolls[3], 2)
    Roll.Update(data, data.owner)
end
