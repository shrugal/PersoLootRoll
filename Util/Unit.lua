local Name, Addon = ...
local RI = LibStub("LibRealmInfo")
local Util = Addon.Util
local Self = Addon.Unit

-- Search patterns
Self.PATTERN_FOLLOW = AUTOFOLLOWSTART:gsub("%%s", "(.+)")

-- Classes
Self.DEATH_KNIGHT = 6
Self.DEMON_HUNTER = 12
Self.DRUID = 11
Self.HUNTER = 3
Self.MAGE = 8
Self.MONK = 10
Self.PALADIN = 2
Self.PRIEST = 5
Self.ROGUE = 4
Self.SHAMAN = 7
Self.WARLOCK = 9
Self.WARRIOR = 1

-- Specs
Self.SPECS = {
    250, 251, 252,      -- Death Knight
    577, 581,           -- Demon Hunter
    102, 103, 104, 105, -- Druid
    253, 254, 255,      -- Hunter
    62, 63, 64,         -- Mage
    268, 270, 269,      -- Monk
    65, 66, 70,         -- Paladin
    256, 257, 258,      -- Priest
    259, 260, 261,      -- Rogue
    262, 263, 264,      -- Shaman
    265, 266, 267,      -- Warlock
    71, 72, 73          -- Warrior
}

-------------------------------------------------------
--                       Realm                       --
-------------------------------------------------------

-- Get the player's realm name for use in unit strings
function Self.RealmName()
    return (GetRealmName():gsub("%s", ""))
end

-- Get a unit's realm name
function Self.Realm(unit)
    local name, realm = UnitFullName(Self(unit))
    realm = realm ~= "" and realm or Self.RealmName()

    return name and realm or unit and unit:match("^.*-(.*)$") or nil
end

-- Get a unique indentifier for the unit's realm connection
function Self.ConnectedRealm(unit)
    local realm = Self.Realm(unit)
    local connections = realm and select(9, RI:GetRealmInfo(realm))

    if connections  then
        local s = ""
        for _,id in ipairs(connections) do
            s = s .. (s == "" and "" or "-") .. select(3, RI:GetRealmInfoByID(id))
        end
        return s
    else
        return realm
    end
end

-------------------------------------------------------
--                        Name                       --
-------------------------------------------------------

-- Get a unit's name (incl. realm name if from another realm)
function Self.Name(unit)
    unit = Self(unit)
    local name, realm = UnitName(unit)

    return name and name .. (realm and realm ~= "" and "-" .. realm or "")
        or unit and unit ~= "" and not unit:find("^[a-z]") and unit
        or nil
end

-- Get a unit's short name (without realm name)
function Self.ShortName(unit)
    local name = UnitName(Self(unit))

    return name and name
        or unit and unit:match("^(.+)-.+$")
        or unit and unit ~= "" and not unit:find("^[a-z]") and unit
        or nil
end

-- Get a unit's full name (always incl. realm name)
function Self.FullName(unit)
    local name, realm = UnitFullName(Self(unit))
    realm = realm ~= "" and realm or Self.RealmName()

    return name and name .. "-" .. realm
        or unit and unit:match("^(.*-.*)$")
        or unit and unit ~= "" and not unit:find("^[a-z]") and unit .. "-" .. realm
        or nil
end

-- Get a unit's short name with a (*) at the end if the unit is from another realm
function Self.ShortenedName(unit)
    unit = Self(unit)
    local name, realm = UnitFullName(unit)

    return name and name ~= "" and name .. (realm and not Util.In(realm, "", Self.RealmName()) and " (*)" or "")
        or unit and unit ~= "" and not unit:find("^[a-z]") and unit:gsub("-.+", " (*)")
        or nil
end

-- Get a unit's name in class color
function Self.ColoredName(name, unit)
    return ("|c%s%s|r"):format(Self.Color(unit or name).colorStr, name)
end

-- It's just such a common usecase
function Self.ColoredShortenedName(unit)
    return unit and Self.ColoredName(Self.ShortenedName(unit), unit)
end

-------------------------------------------------------
--                      Social                       --
-------------------------------------------------------

-- Get the unit's guild name, incl. realm if from another realm
function Self.GuildName(unit)
    if not unit then return end

    local guild, _, _, realm = GetGuildInfo(unit or "")
    return guild and guild .. (realm and "-" .. realm or "") or nil
end

-- The the unit's rank in our guild
function Self.GuildRank(unit)
    if not unit then return end

    local guild, _, rank, realm = GetGuildInfo(unit)
    return guild and guild .. (realm and "-" .. realm or "") == Self.GuildName("player") and rank or nil
end

-- Check if the given unit is in our guild
function Self.IsGuildMember(unit)
    if not unit then return false end

    local guild = Self.GuildName("player")
    return guild ~= nil and Self.GuildName(unit) == guild
end

-- Check if the given unit is on our friend list
function Self.IsFriend(unit)
    if not unit then return false end

    local unit = Self.Name(unit)
    for i=1, GetNumFriends() do
        if GetFriendInfo(i) == unit then
            return true
        end
    end
end

-- Check if the given unit is part of one of our character coummunities
function Self.IsClubMember(unit)
    if not unit then return false end

    local guid = UnitGUID(unit)
    for _,info in pairs(C_Club.GetSubscribedClubs()) do
        if info.clubType == Enum.ClubType.Character then
            for _,memberId in pairs(C_Club.GetClubMembers(info.clubId)) do
                if C_Club.GetMemberInfo(info.clubId, memberId).guid == guid then
                    return true
                end
            end
        end
    end
end

-- Get common community ids
function Self.CommonClubs(unit)
    if not unit then return end

    local t, guid = Util.Tbl(), UnitGUID(unit)
    for _,info in pairs(C_Club.GetSubscribedClubs()) do
        if info.clubType == Enum.ClubType.Character then
            for _,memberId in pairs(C_Club.GetClubMembers(info.clubId)) do
                if C_Club.GetMemberInfo(info.clubId, memberId).guid == guid then
                    tinsert(t, info.clubId)
                end
            end
        end
    end
    return Util.TblUnique(t)
end

function Self.ClubMemberInfo(unit, clubId)
    if not unit then return end

    unit = Self.Name(unit)
    for _,memberId in pairs(C_Club.GetClubMembers(clubId)) do
        local info = C_Club.GetMemberInfo(clubId, memberId)
        if info.name == unit then
            return info
        end
    end
end

-------------------------------------------------------
--                       Other                       --
-------------------------------------------------------

-- Check if the unit is the current player
function Self.IsSelf(unit)
    return unit and UnitIsUnit(unit, "player")
end

-- Get the unit's class id
function Self.ClassId(unit)
    return unit and select(3, UnitClass(unit))
end

-- Get a list of all specs
function Self.Specs(unit)
    if unit then
        local classId, specs = Self.ClassId(unit), Util.Tbl()
        for i=1,GetNumSpecializationsForClassID(classId) do
            specs[i] = select(2, GetSpecializationInfoForClassID(classId, i))
        end
        return specs
    else
        Self.specs = Self.specs or Util.TblCopy(Self.SPECS, function (id) return select(2, GetSpecializationInfoByID(id)) end)
        return Self.specs
    end
end

-- Get a unit's class color
function Self.Color(unit)
    return RAID_CLASS_COLORS[select(2, UnitClass(Self(unit))) or "PRIEST"]
end

-- Check if the player is following someone
function Self.IsFollowing(unit)
    return AutoFollowStatus:IsShown() and (not unit or unit == AutoFollowStatusText:GetText():match(Self.PATTERN_FOLLOW))
end

-- Shortcut for checking whether a unit is in our party or raid
function Self.InGroup(unit, onlyOthers)
    local isSelf = Self.IsSelf(unit)
    return not (isSelf and onlyOthers) and (isSelf or UnitInParty(unit) or UnitInRaid(unit))
end

-- Check if the player is an enchanter
function Self.IsEnchanter()
    for _,i in Util.Each(GetProfessions()) do
        if i and select(7, GetProfessionInfo(i)) == 333 then return true end
    end
end

setmetatable(Self, {
    __call = function (_, unit)
        return unit and unit:gsub("-" .. Self.RealmName(), "") or ""
    end
})