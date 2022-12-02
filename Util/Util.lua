---@type Addon
local Addon = select(2, ...)
local Item, Unit = Addon.Item, Addon.Unit
---@class Util
local Self = Addon.Util
setmetatable(Self, LibStub:GetLibrary("LibUtil"))

---@type Counter
Self.Counter = {}
---@type Registrar
Self.Registrar = {}

-------------------------------------------------------
--                        WoW                        --
-------------------------------------------------------

-- More than this much percent of players in the group must be from
-- one guild/community for it to be considered a guild/community group
Self.GROUP_THRESHOLD = 0.50

-- Interaction distances
Self.INTERACT_INSPECT = 1 -- 28 yards
Self.INTERACT_TRADE = 2   -- 11.11 yards
Self.INTERACT_DUEL = 3    -- 9.9 yards
Self.INTERACT_FOLLOW = 4  -- 28 yards

-- Expansions
Self.EXP_CLASSIC = 1
Self.EXP_BC = 2
Self.EXP_WOTLK = 3
Self.EXP_CATA = 4
Self.EXP_MOP = 5
Self.EXP_WOD = 6
Self.EXP_LEGION = 7
Self.EXP_BFA = 8
Self.EXP_SL = 9

-- Check if the current group is a guild group
---@return string|boolean
function Self.IsGuildGroup(guild)
    if not IsInGroup() or guild == "" then
        return false
    end

    local n, guilds = GetNumGroupMembers(), Self.Tbl()

    for i=1,n do
        local g = Unit.GuildName(GetRaidRosterInfo(i))
        if g then
            guilds[g] = (guilds[g] or 0) + 1
            if (not guild or g == guild) and guilds[g] / n > Self.GROUP_THRESHOLD then
                Self.Tbl.Release(guilds)
                return g
            end
        end
    end
    Self.Tbl.Release(guilds)
end

-- Check if the current group is a community group
---@param commId integer
---@return integer|boolean
function Self.IsCommunityGroup(commId)
    if not IsInGroup() or not Self.Tbl.FirstWhere(C_Club.GetSubscribedClubs(), "clubType", Enum.ClubType.Character, "clubId", commId) then
        return false
    end

    local n, comms = GetNumGroupMembers(), Self.Tbl()
    for i=1,n do
        local c = Unit.CommonClubs(GetRaidRosterInfo(i))
        if c then
            for _,clubId in pairs(c) do
                comms[clubId] = (comms[clubId] or 0) + 1
                if (not commId or commId == clubId) and comms[clubId] / n >= Self.GROUP_THRESHOLD then
                    Self.Tbl.Release(comms, c)
                    return clubId
                end
            end
            Self.Tbl.Release(c)
        end
    end
    Self.Tbl.Release(comms)
end

-- Get a list of guild ranks
---@return table<integer,string>
function Self.GetGuildRanks()
    local t, i, name = Self.Tbl(), 1, GuildControlGetRankName(1)
    while not Self.Str.IsEmpty(name) do
        t[i] = name
        i, name = i + 1, GuildControlGetRankName(i + 1)
    end
    return t
end

-- Get a list of club ranks
---@return table<integer,string>
function Self.GetClubRanks(clubId)
    if not clubId then return end

    local info = C_Club.GetClubInfo(clubId)
    if not info then
        return
    elseif info.clubType == Enum.ClubType.Guild then
        return Self.GetGuildRanks()
    else
        return Self.Tbl.Flip(Enum.ClubRoleIdentifier)
    end
end

-- Get the expansion for the current instance
function Self.GetInstanceExpansion()
    if not IsInInstance() then return 0 end
    if Self.IsMythicPlus() then return GetMaximumExpansionLevel() end

    local mapID = C_Map.GetBestMapForUnit("player")
    
    return mapID and Self.INSTANCES[EJ_GetInstanceForMap(mapID)] or 0
end

-- Check if the current session is below the player's current expansion
function Self.IsLegacyRun(unit)
    local unitLvl = UnitLevel(unit or "player")
    local instanceExp, currExp, maxExp = Self.GetInstanceExpansion(), GetExpansionLevel(), GetMaximumExpansionLevel()

    local isCurrExpPlayer = unitLvl > MAX_PLAYER_LEVEL - 10 or currExp < maxExp and unitLvl == MAX_PLAYER_LEVEL - 10
    local isCurrExpInstance = instanceExp == 0 or instanceExp == currExp + 1

    return isCurrExpPlayer and not isCurrExpInstance
end

-- Check if currently in a M+ dungeon
function Self.IsMythicPlus()
    return select(3, GetInstanceInfo()) == DifficultyUtil.ID.DungeonChallenge
end

-- Check if currently in a timewalking dungeon
function Self.IsTimewalking()
    return Self.In(select(3, GetInstanceInfo()), DifficultyUtil.ID.DungeonTimewalker, DifficultyUtil.ID.RaidTimewalker)
end

-- Get the usual # of dropped items in the current instance and group setting
function Self.GetNumDroppedItems()
    local difficulty, _, maxPlayers = select(3, GetInstanceInfo())

    if difficulty == DifficultyUtil.ID.DungeonChallenge then
        -- In M+ we get 2 items at the end of the dungeon, +1 if in time, +0.4 per keystone level above 15
        local _, level, _, onTime = C_ChallengeMode.GetCompletionInfo();
        return 2 + (onTime and 1 or 0) + (level > 15 and math.ceil(0.4 * (level - 15)) or 0)
    else
        -- Normally we get about 1 item per 5 players in the group
        local players = GetNumGroupMembers()
        if difficulty == DifficultyUtil.ID.PrimaryRaidMythic then
            players = 20
        elseif C_Loot.IsLegacyLootModeEnabled() then
            local d = DifficultyUtil.ID
            players = Self.In(difficulty, d.RaidLFR, d.PrimaryRaidLFR, d.PrimaryRaidNormal, d.PrimaryRaidHeroic) and max(players, 20) or maxPlayers
        end
        return math.ceil(players / 5)
    end
end

-- Get hidden tooltip for scanning
function Self.GetHiddenTooltip()
    if not Self.hiddenTooltip then
        Self.hiddenTooltip = CreateFrame("GameTooltip", Addon.ABBR .. "_HiddenTooltip", nil, "GameTooltipTemplate")
        Self.hiddenTooltip:SetOwner(UIParent, "ANCHOR_NONE")
    end

    return Self.hiddenTooltip
end

-- Fill a tooltip and scan it line by line
---@param linkOrBag string | integer
function Self.ScanTooltip(fn, linkOrBag, slot, ...)
    local tooltip = Self.GetHiddenTooltip()
    tooltip:ClearLines()

    if slot then
        tooltip:SetBagItem(linkOrBag, slot)
    elseif Item.GetInfo(linkOrBag, "itemType") == "item" then
        tooltip:SetHyperlink(linkOrBag)
    else
        return
    end

    local lines = tooltip:NumLines()
    for i=2, lines do
        local line = _G[Addon.ABBR .."_HiddenTooltipTextLeft" .. i]:GetText()
        if line then
            local a, b, c = fn(i, line, lines, ...)
            if a ~= nil then
                return a, b, c
            end
        end
    end
end

-- Get the correct bag position, if it exists (e.g. 1, 31 -> 2, 1)
---@return integer
---@return integer
function Self.GetBagPosition(bag, slot)
    local numSlots = C_Container.GetContainerNumSlots(bag)
    if bag < 0 or bag > NUM_BAG_SLOTS or not numSlots or numSlots == 0 then
        return nil, nil
    elseif slot > numSlots then
        return Self.GetBagPosition(bag + 1, slot - numSlots)
    else
        return bag, slot
    end
end
