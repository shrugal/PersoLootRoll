if not WoWUnit then return end

---@type string
local Name = ...
---@type Addon
local Addon = select(2, ...)
local Item, Roll, Util = Addon.Item, Addon.Roll, Addon.Util
local Assert, AssertEqual, AssertFalse, Replace = WoWUnit.IsTrue, WoWUnit.AreEqual, WoWUnit.IsFalse, WoWUnit.Replace

local Tests = WoWUnit(Name .. ".Unit.Roll")

local rolls = {
    {id = 1, ownerId = 1, owner = "player", status = Roll.STATUS_RUNNING, itemOwnerId = 1, item = {id = 1, owner = "player", infoLevel = 1, link = "item1"}},
    {id = 2, ownerId = 2, owner = "player", status = Roll.STATUS_DONE,    itemOwnerId = 2, item = {id = 2, owner = "player", infoLevel = 1, link = "item2"}},
    {id = 3, ownerId = 1, owner = "party1", status = Roll.STATUS_RUNNING, itemOwnerId = 1, item = {id = 2, owner = "party1", infoLevel = 1, link = "item3"}},
    nil,
    {id = 5, ownerId = 3, owner = "party2", status = Roll.STATUS_PENDING, itemOwnerId = 3, item = {id = 4, owner = "party2", infoLevel = 1, link = "item5"}},
    {id = 6, ownerId = 4, owner = "party2", status = Roll.STATUS_DONE,    itemOwnerId = 4, item = {id = 4, owner = "party2", infoLevel = 1, link = "item6"}},
    {id = 7, ownerId = 5, owner = "party3", status = Roll.STATUS_DONE,    itemOwnerId = 7, item = {id = 5, owner = "player", infoLevel = 1, link = "item7"}},
    {id = 8, ownerId = 6, owner = "party3", status = Roll.STATUS_DONE,    itemOwnerId = 2, item = {id = 6, owner = "party1", infoLevel = 1, link = "item8"}}
}

function Tests:GetTest()
    local obj = {}
    Replace(Addon, "rolls", {[1] = obj})
    AssertEqual(Roll.Get(1), obj)
    AssertFalse(Roll.Get(2))
end

function Tests:FindTest()
    Replace(Addon, "rolls", rolls)

    -- Find by id and owner
    AssertEqual(rolls[1], Roll.Find(1, "player"))
    AssertEqual(rolls[2], Roll.Find(2, "player"))
    AssertEqual(rolls[3], Roll.Find(1, "party1"))
    AssertEqual(rolls[5], Roll.Find(3, "party2"))
    AssertEqual(rolls[6], Roll.Find(4, "party2"))
    AssertEqual(rolls[7], Roll.Find(5, "party3"))
    AssertEqual(rolls[8], Roll.Find(6, "party3"))
    AssertFalse(Roll.Find(4, "player"))
    AssertFalse(Roll.Find(2, "party1"))
    -- Find by owner and item
    AssertEqual(rolls[1], Roll.Find(nil, "player", "item1"))
    AssertEqual(rolls[2], Roll.Find(nil, "player", "item2"))
    AssertEqual(rolls[3], Roll.Find(nil, "party1", "item3"))
    AssertEqual(rolls[5], Roll.Find(nil, "party2", "item5"))
    AssertEqual(rolls[6], Roll.Find(nil, "party2", "item6"))
    AssertEqual(rolls[7], Roll.Find(nil, "party3", "item7"))
    AssertEqual(rolls[8], Roll.Find(nil, "party3", "item8"))
    AssertFalse(Roll.Find(nil, "player", "item7"))
    AssertFalse(Roll.Find(nil, "party1", "item8"))
    -- Find by item owner and item owner id
    AssertEqual(rolls[1], Roll.Find(nil, nil, nil, 1, "player"))
    AssertEqual(rolls[2], Roll.Find(nil, nil, nil, 2, "player"))
    AssertEqual(rolls[3], Roll.Find(nil, nil, nil, 1, "party1"))
    AssertEqual(rolls[5], Roll.Find(nil, nil, nil, 3, "party2"))
    AssertEqual(rolls[6], Roll.Find(nil, nil, nil, 4, "party2"))
    AssertEqual(rolls[7], Roll.Find(nil, nil, nil, 7, "player"))
    AssertEqual(rolls[8], Roll.Find(nil, nil, nil, 2, "party1"))
    AssertFalse(Roll.Find(nil, nil, nil, 3, "player"))
    AssertFalse(Roll.Find(nil, nil, nil, 3, "party1"))
    AssertFalse(Roll.Find(nil, nil, nil, 7, "party3"))
    AssertFalse(Roll.Find(nil, nil, nil, 2, "party3"))
    -- Find by id, owner and status
    AssertEqual(rolls[1], Roll.Find(1, "player", nil, nil, nil, Roll.STATUS_RUNNING))
    AssertEqual(rolls[2], Roll.Find(2, "player", nil, nil, nil, Roll.STATUS_DONE))
    AssertEqual(rolls[3], Roll.Find(1, "party1", nil, nil, nil, Roll.STATUS_RUNNING))
    AssertFalse(Roll.Find(1, "player", nil, nil, nil, Roll.STATUS_DONE))
    AssertFalse(Roll.Find(2, "player", nil, nil, nil, Roll.STATUS_CANCELED))
    AssertFalse(Roll.Find(1, "party1", nil, nil, nil, Roll.STATUS_PENDING))
end

function Tests:FindWhereTest()
    Replace(Addon, "rolls", rolls)

    for _,roll in ipairs(rolls) do
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
    Replace(Addon, "rolls", Util.TblCounter())
    Roll.Add("item1", "player")
end
