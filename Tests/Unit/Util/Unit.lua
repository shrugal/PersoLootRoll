if not WoWUnit then return end

---@type string
local Name = ...
---@type Addon
local Addon = select(2, ...)
local Test, Unit, Util = Addon.Test, Addon.Unit, Addon.Util
local Assert, AssertEqual, Replace = WoWUnit.IsTrue, WoWUnit.AreEqual, WoWUnit.Replace
local RI = LibStub("LibRealmInfo")

local Tests = WoWUnit(Name .. ".Unit.Util.Unit")

function Tests:RealmNameTest()
end

function Tests:RealmTest()
end

function Tests:ConnectedRealmTest()
    -- The players's realm
    AssertEqual(table.concat(GetAutoCompleteRealms(), "-"), Unit.ConnectedRealm("player"))

    Replace(RI, "GetCurrentRegion", Test.Const("EU"))

    -- A normal connected realm
    AssertEqual("Aggramar-Hellscream", Unit.ConnectedRealm("Unit-Aggramar"))
    -- A realm with spaces
    AssertEqual("Todeswache-Forscherliga-ZirkeldesCenarius-DerRatvonDalaran-DerMithrilorden-DieNachtwache", Unit.ConnectedRealm("Unit-ZirkeldesCenarius"))
    -- A realm without connections
    AssertEqual("Archimonde", Unit.ConnectedRealm("Unit-Archimonde"))
    -- A realm that doesn't exist
    AssertEqual("Abcdefg", Unit.ConnectedRealm("Unit-Abcdefg"))
end

function Tests:NameTest()
end

function Tests:ShortNameTest()
end

function Tests:FullNameTest()
end

function Tests:ShortenedNameTest()
end

function Tests:ColoredNameTest()
end

function Tests:ColoredShortenedNameTest()
end

function Tests:GuildNameTest()
end

function Tests:GuildRankTest()
end

function Tests:IsGuildMemberTest()
end

function Tests:IsGuildOfficerTest()
end

function Tests:IsFriendTest()
end

function Tests:IsClubMemberTest()
end

function Tests:CommonClubsTest()
end

function Tests:ClubMemberInfoTest()
end

function Tests:InGroupTest()
end

function Tests:GroupRankTest()
end

function Tests:GroupLeaderTest()
end

function Tests:IsUnitTest()
end

function Tests:IsSelfTest()
end

function Tests:ClassIdTest()
end

function Tests:SpecsTest()
end

function Tests:ExpansionTest()
end

function Tests:ColorTest()
end

function Tests:IsFollowingTest()
end

function Tests:IsEnchanterTest()
end