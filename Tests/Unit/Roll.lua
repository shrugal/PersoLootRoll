if not WoWUnit then return end

---@type string
local Name = ...
---@type Addon
local Addon = select(2, ...)
local Item, Roll, Util = Addon.Item, Addon.Roll, Addon.Util
local Assert, AssertEqual, AssertFalse, Replace = WoWUnit.IsTrue, WoWUnit.AreEqual, WoWUnit.IsFalse, WoWUnit.Replace

local Tests = WoWUnit(Name .. ".Unit.Roll")

function Tests:GetTest()
    local obj = {}
    Replace(Addon, "rolls", {[1] = obj})
    AssertEqual(Roll.Get(1), obj)
    AssertFalse(Roll.Get(2))
end

function Tests:FindTest()
    local rolls = {
        {id = 1, ownerId = 1, owner = "player", status = Roll.STATUS_RUNNING, item = {id = 1, itemOwnerId = 1, itemOwner = "player", infoLevel = 1, link = "item1"}},
        {id = 2, ownerId = 2, owner = "player", status = Roll.STATUS_DOME,    item = {id = 2, itemOwnerId = 2, itemOwner = "player", infoLevel = 1, link = "item2"}},
        {id = 3, ownerId = 1, owner = "party1", status = Roll.STATUS_RUNNING, item = {id = 2, itemOwnerId = 1, itemOwner = "party1", infoLevel = 1, link = "item3"}},
        nil,
        {id = 5, ownerId = 3, owner = "party2", status = Roll.STATUS_PENDING, item = {id = 4, itemOwnerId = 3, itemOwner = "party2", infoLevel = 1, link = "item5"}},
        {id = 6, ownerId = 4, owner = "party2", status = Roll.STATUS_DONE,    item = {id = 4, itemOwnerId = 4, itemOwner = "party2", infoLevel = 1, link = "item6"}},
        {id = 7, ownerId = 5, owner = "party3", status = Roll.STATUS_DONE,    item = {id = 5, itemOwnerId = 7, itemOwner = "player", infoLevel = 1, link = "item7"}},
        {id = 8, ownerId = 6, owner = "party3", status = Roll.STATUS_DONE,    item = {id = 6, itemOwnerId = 2, itemOwner = "party1", infoLevel = 1, link = "item8"}}
    }
    Replace(Addon, "rolls", rolls)
    AssertEqual(rolls[1], Roll.Find(1, "player"))
    AssertEqual(rolls[2], Roll.Find(2, "player"))
    AssertEqual(rolls[3], Roll.Find(1, "party1"))
    AssertEqual(rolls[5], Roll.Find(3, "party2"))
    AssertEqual(rolls[6], Roll.Find(4, "party2"))
    AssertEqual(rolls[7], Roll.Find(5, "party3"))
    AssertEqual(rolls[8], Roll.Find(6, "party3"))
    AssertFalse(Roll.Find(4, "player"))
    AssertFalse(Roll.Find(2, "party1"))
    AssertEqual(rolls[1], Roll.Find(nil, "player", "item1"))
    AssertEqual(rolls[2], Roll.Find(nil, "player", "item2"))
    AssertEqual(rolls[3], Roll.Find(nil, "party1", "item3"))
    AssertEqual(rolls[5], Roll.Find(nil, "party2", "item5"))
    AssertEqual(rolls[6], Roll.Find(nil, "party2", "item6"))
    AssertEqual(rolls[7], Roll.Find(nil, "party3", "item7"))
    AssertEqual(rolls[8], Roll.Find(nil, "party3", "item8"))
    AssertFalse(Roll.Find(nil, "player", "item7"))
    AssertFalse(Roll.Find(nil, "party1", "item8"))
end
