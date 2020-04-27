if not WoWUnit then return end

---@type string
local Name = ...
---@type Addon
local Addon = select(2, ...)
local Test, Comm, Unit, Util = Addon.Test, Addon.Comm, Addon.Unit, Addon.Util
local Assert, AssertEqual, Replace = WoWUnit.IsTrue, WoWUnit.AreEqual, WoWUnit.Replace
local RI = LibStub("LibRealmInfo")

local Tests = WoWUnit(Name .. ".Unit.Util.Comm")

function Tests:GetPrefixTest()
    AssertEqual("PLRCHECK", Comm.GetPrefix("CHECK"))
    AssertEqual("ABCDEFG", Comm.GetPrefix("ABCDEFG"))
end

function Tests:GetDestinationTest()
    Test.ReplaceDefault()
    AssertEqual("PARTY", Comm.GetDestination())
    AssertEqual("PARTY", Comm.GetDestination("GROUP"))

    Replace("IsInGroup", Test.Const(false))
    AssertEqual(nil, Comm.GetDestination())

    Replace("IsInRaid", Test.Const(true))
    AssertEqual("RAID", Comm.GetDestination())

    Replace("IsInGroup", Test.Val(true))
    AssertEqual("INSTANCE_CHAT", Comm.GetDestination())

    for i,v in pairs(Comm.TYPES) do
        if v ~= "GROUP" then
            AssertEqual(v, Comm.GetDestination(v))
        end
    end

    Replace(Unit, "Name", Test.Id)
    local channel, unit = Comm.GetDestination("player")
    AssertEqual("WHISPER", channel)
    AssertEqual("player", unit)
end

function Tests:ShouldInitChatTest()
    Test.ReplaceDefault()
    Test.ReplaceLocale()
    Replace(Unit, "Name", Test.Id)

    local GROUP = "GROUP"
    local ITEM = "ITEM"
    local UNIT = "target"
    local PLAYER, TRADE = Comm.GetPlayerLink(UNIT), Comm.GetTradeLink(UNIT)

    local byType = {
        lfr = true,
        lfd = true,
        guild = true,
        community = true,
        raid = true,
        party = true,
        friend = true,
        other = true
    }
    local c =  {
        whisper = {
            ask = true,
            target = byType,
            groupType = byType
        },
        group = {
            announce = true,
            groupType = byType
        }
    }
    Replace(Addon.db.profile, "messages", c)

    -- Chat output assertion
    local assertTarget, assertLine, assertGroup
    local AssertInfo = Test.ReplaceFunction(Comm, "ChatInfo", function (line, item, target, group)
        AssertEqual(assertLine, line)
        AssertEqual(ITEM, item)
        AssertEqual(assertTarget, target)
        AssertEqual(assertGroup, group)
    end)

    -- Assertion helpers
    local AssertTrue = function (target)
        AssertEqual(true, Comm.ShouldInitChat(target, ITEM))
        AssertInfo(0)
    end
    local AssertFalse = function (target, ...)
        assertTarget, assertLine, assertGroup = target, ...
        AssertEqual(false, Comm.ShouldInitChat(target, ITEM))
        assertTarget, assertLine, assertGroup = nil
        AssertInfo(1)
    end
    local AssertGroupType = function(type, group)
        AssertTrue(GROUP)
        AssertTrue(UNIT)
        byType[type] = false
        AssertFalse(GROUP, "BID_NO_CHAT_GRP", group)
        AssertFalse(UNIT, "BID_NO_CHAT_GRP", group)
        byType[type] = true
    end
    local AssertTargetType = function(type, line)
        AssertTrue(UNIT)
        byType[type] = false
        AssertFalse(UNIT, line)
        byType[type] = true
    end

    -- Group types
    AssertGroupType("party", PARTY)
    Replace("IsInRaid", Test.Not)
    AssertGroupType("raid", RAID)
    Replace(Util, "IsCommunityGroup", Test.Const(true))
    AssertGroupType("community", CLUB_FINDER_COMMUNITY_TYPE)
    Replace(Util, "IsGuildGroup", Test.Const(true))
    AssertGroupType("guild", GUILD)
    Replace("IsInGroup", Test.Const(true))
    AssertGroupType("lfd", LOOKING_FOR_DUNGEON_PVEFRAME)
    Replace("IsInRaid", Test.Const(true))
    AssertGroupType("lfr", RAID_FINDER_PVEFRAME)
    -- Addon users
    Replace(Addon, "GetNumAddonUsers", Test.Val(4))
    AssertFalse(GROUP, "BID_NO_CHAT_ADDONS")
    -- Announce
    c.group.announce = false
    AssertFalse(GROUP, "BID_NO_CHAT_ANNOUNCE")
    -- Whisper target
    AssertTargetType("other", "BID_NO_CHAT_OTHER")
    Replace(Unit, "IsFriend", Test.Val(true))
    AssertTargetType("friend", "BID_NO_CHAT_FRIEND")
    Replace(Unit, "IsClubMember", Test.Val(true))
    AssertTargetType("community", "BID_NO_CHAT_CLUB")
    Replace(Unit, "IsGuildMember", Test.Val(true))
    AssertTargetType("guild", "BID_NO_CHAT_GUILD")
    Replace(Unit, "IsSelf", Test.Val(true))
    AssertFalse(UNIT, "BID_NO_CHAT_SELF")
    Replace(Addon, "UnitIsTracking", Test.Val(true))
    AssertFalse(UNIT, "BID_NO_CHAT_TRACKING")
    Replace("UnitIsDND", Test.Val(true))
    AssertFalse(UNIT, "BID_NO_CHAT_DND")
    c.whisper.ask = false
    AssertFalse(UNIT, "BID_NO_CHAT_ASK")
    -- Not in group
    Replace("IsInGroup", Test.Const(false))
    AssertFalse(nil, "BID_NO_CHAT")
end

function Tests:ChatTest()
end

function Tests:SendTest()
end

function Tests:SendDataTest()
end

function Tests:ListenDataTest()
end

function Tests:RollAdvertiseTest()
end

function Tests:RollBidTest()
end

function Tests:RollVoteTest()
end

function Tests:RollEndTest()
end

function Tests:GetPlayerLinkTest()
end

function Tests:GetTradeLinkTest()
end

function Tests:GetBidLinkTest()
end

function Tests:GetTooltipLinkTest()
end

function Tests:EscapeStringTest()
end

function Tests:UnescapeStringTest()
end

function Tests:ChatInfoTest()
    Test.ReplaceDefault()
    Test.ReplaceLocale()
    Replace(Unit, "Name", Test.Id)

    local LINE = "LINE"
    local GROUP = "GROUP"
    local ITEM = "ITEM"
    local GROUPTYPE = "GROUPTYPE"
    local UNIT = "target"
    local PLAYER, TRADE = Comm.GetPlayerLink(UNIT), Comm.GetTradeLink(UNIT)

    -- Chat output assertion
    local chatLine, param1, param2, param3, param4 = LINE
    local AssertInfo = Test.ReplaceFunction(Addon, "Info", function (_, line, arg1, arg2, arg3, arg4)
        AssertEqual(chatLine, line)
        AssertEqual(param1, arg1)
        AssertEqual(param2, arg2)
        AssertEqual(param3, arg3)
        AssertEqual(param4, arg4)
    end)

    param1 = ITEM
    Comm.ChatInfo(LINE, ITEM)
    AssertInfo()
    Comm.ChatInfo(LINE, ITEM, GROUP)
    AssertInfo()
    param2 = GROUPTYPE
    Comm.ChatInfo(LINE, ITEM, GROUP, GROUPTYPE)
    AssertInfo()
    param1, param2, param3 = PLAYER, ITEM, TRADE
    Comm.ChatInfo(LINE, ITEM, UNIT)
    AssertInfo()
    chatLine, param3, param4 = LINE .. "_ASK", GROUPTYPE, TRADE
    Comm.ChatInfo(LINE, ITEM, UNIT, GROUPTYPE)
    AssertInfo()
end
