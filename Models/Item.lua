---@type string
local Name = ...
---@type Addon
local Addon = select(2, ...)
local Inspect, Unit, Util = Addon.Inspect, Addon.Unit, Addon.Util
---@class Item
local Self = Addon.Item

local Meta = { __index = Self }

---@alias ItemRef Item|string|integer

-------------------------------------------------------
--                     Constants                     --
-------------------------------------------------------

-- Character level threshold
Self.LVL_THRESHOLD = 10
-- Item level threshold
Self.ILVL_THRESHOLD = 15

-- Link pattern
Self.PATTERN_LINK = "(|?c?f?f?%x*|H[^:]+:[^|]*|?h?[^|]*|?h?|?r?)"

-- Tooltip search patterns
---@type string
Self.PATTERN_ILVL = ITEM_LEVEL:gsub("%%d", "(%%d+)")
---@type string
Self.PATTERN_ILVL_SCALED = ITEM_LEVEL_ALT:gsub("%(%%d%)", "%%(%%d%%)"):gsub("%%d", "(%%d+)")
---@type string
Self.PATTERN_MIN_LEVEL = ITEM_MIN_LEVEL:gsub("%%d", "(%%d+)")
---@type string
Self.PATTERN_HEIRLOOM_LEVEL = ITEM_LEVEL_RANGE:gsub("%%d", "(%%d+)")
---@type string
Self.PATTERN_RELIC_TYPE = RELIC_TOOLTIP_TYPE:gsub("%%s", "(.+)")
---@type string
Self.PATTERN_CLASSES = ITEM_CLASSES_ALLOWED:gsub("%%s", "(.+)")
---@type string
Self.PATTERN_SPEC = ITEM_REQ_SPECIALIZATION:gsub("%%s", "(.+)")
---@type string
Self.PATTERN_STRENGTH = ITEM_MOD_STRENGTH:gsub("%%c%%s", "^%%p(.+)")
---@type string
Self.PATTERN_INTELLECT = ITEM_MOD_INTELLECT:gsub("%%c%%s", "^%%p(.+)")
---@type string
Self.PATTERN_AGILITY = ITEM_MOD_AGILITY:gsub("%%c%%s", "^%%p(.+)")
---@type string
Self.PATTERN_SOULBOUND = ITEM_SOULBOUND
---@type string
Self.PATTERN_TRADE_TIME_REMAINING = BIND_TRADE_TIME_REMAINING:gsub("%%s", ".+")
---@type string
Self.PATTERN_APPEARANCE_KNOWN = TRANSMOGRIFY_TOOLTIP_APPEARANCE_KNOWN
---@type string
Self.PATTERN_APPEARANCE_UNKNOWN = TRANSMOGRIFY_TOOLTIP_APPEARANCE_UNKNOWN
---@type string
Self.PATTERN_APPEARANCE_UNKNOWN_ITEM = TRANSMOGRIFY_TOOLTIP_ITEM_UNKNOWN_APPEARANCE_KNOWN

-- Item loading status
Self.INFO_NONE = 0
Self.INFO_LINK = 1
Self.INFO_BASIC = 2
Self.INFO_FULL = 3

-- Item info positions
Self.INFO = {
    link = {
        color = "%|cff(%x+)",
        itemType = "%|H([^:]+)",
        name = "%|h%[([^%]]+)%]%|h",
        id = 1,
        -- enchantId = 2,
        -- gemId1 = 3,
        -- gemId2 = 4,
        -- gemId3 = 5,
        -- gemId4 = 6,
        -- suffixId = 7,
        -- uniqueId = 8,
        linkLevel = 9,
        -- specId = 10,
        upgradeId = 11,
        -- difficultyId = 12,
        numBonusIds = 13,
        -- bonusIds = 14,
        upgradeLevel = 15
    },
    basic = {
        name = 1,
        link = 2,
        quality = 3,
        level = 4,
        minLevel = 5,
        -- type = 6,
        subType = 7,
        -- stackCount = 8,
        equipLoc = 9,
        texture = 10,
        -- sellPrice = 11,
        classId = 12,
        subClassId = 13,
        bindType = 14,
        expacId = 15,
        -- setId = 16,
        -- isCraftingReagent = 17
    },
    full = {
        classes = true,
        spec = true,
        relicType = true,
        realLevel = true,
        realMinLevel = true,
        fromLevel = true,
        toLevel = true,
        attributes = true,
        isTransmogKnown = true,
        isTransmogSourceKnown = true
    }
}

-- Cache the player's ilvl per slot
Self.playerCache = {}

-- New items waiting for the BAG_UPDATE_DELAYED event
Self.queue = {}

-------------------------------------------------------
--                      Links                        --
-------------------------------------------------------

-- Get the item link from a string
---@param str string|Item
---@return string?
function Self.GetLink(str)
    if type(str) == "table" then
        return str.link
    elseif type(str) == "string" then
        return select(3, str:find(Self.PATTERN_LINK))
    end
end

-- Get a version of the link for the given player level
---@param link string
---@param level integer
function Self.GetLinkForLevel(link, level)
    local i = 0
    return link:gsub(":[^:]*", function(s)
        i = i + 1
        if i == Self.INFO.link.linkLevel then
            return ":" .. (level or MAX_PLAYER_LEVEL)
        end
    end)
end

-- Get a version of the link that is scaled to the given player level
---@param link string
---@param level integer
function Self.GetLinkScaled(link, level)
    local i, numBonusIds = 0, 1
    return link:gsub(":([^:]*)", function(s)
        i = i + 1
        if i == Self.INFO.link.numBonusIds then
            numBonusIds = tonumber(s) or 0
        elseif i == Self.INFO.link.upgradeLevel - 1 + numBonusIds then
            return ":" .. (level or MAX_PLAYER_LEVEL)
        end
    end)
end

-- Check if string is an item link
function Self.IsLink(str)
    str = Self.GetLink(str)

    if type(str) == "string" then
        local i, j = str:find(Self.PATTERN_LINK)
        return i == 1 and j == str:len()
    else
        return false
    end
end

-- Make item link printable
---@param str string
---@return string
---@return integer
function Self.GetPrintableLink(str)
    return gsub(str.link or str, "\124", "\124\124");
end

-- Get just one item attribute, without creating an item instance or figuring out all other attributes as well
-- TODO: Optimize with line number restrictions
---@param i integer
---@param line string
---@param lines table
---@param attr string
---@return any
local fullScanFn = function(i, line, lines, attr)
    -- classes
    if attr == "classes" then
        local classes = line:match(Self.PATTERN_CLASSES)
        return classes and Util.Str.Split(classes, ", ") or nil
        -- spec
    elseif attr == "spec" then
        local spec = line:match(Self.PATTERN_SPEC)
        return spec and Util.In(spec, Unit.Specs()) and spec or nil
        -- relicType
    elseif attr == "relicType" then
        return line:match(Self.PATTERN_RELIC_TYPE) or nil
        -- realLevel
    elseif attr == "realLevel" then
        return tonumber(select(2, line:match(Self.PATTERN_ILVL_SCALED)) or line:match(Self.PATTERN_ILVL))
        -- realMinLevel
    elseif attr == "realMinLevel" then
        return tonumber(line:match(Self.PATTERN_MIN_LEVEL))
        -- fromlevel, toLevel
    elseif Util.In(attr, "fromLevel", "toLevel") then
        local from, to = line:match(Self.PATTERN_HEIRLOOM_LEVEL)
        return from and to and tonumber(attr == "fromLevel" and from or to) or nil
        -- attributes
    elseif attr == "attributes" then
        local match
        for _, a in pairs(Self.ATTRIBUTES) do
            match = line:match(Self["PATTERN_" .. Util.Select(a, LE_UNIT_STAT_STRENGTH, "STRENGTH", LE_UNIT_STAT_INTELLECT, "INTELLECT", "AGILITY")])
            if match then break end
        end

        if match then
            local attrs = Util.Tbl.New()
            for j = i, min(lines, i + 3) do
                line = _G[Addon.ABBR .. "_HiddenTooltipTextLeft" .. j]:GetText()
                for _, a in pairs(Self.ATTRIBUTES) do
                    if not attrs[a] then
                        match = line:match(Self["PATTERN_" .. Util.Select(a, LE_UNIT_STAT_STRENGTH, "STRENGTH", LE_UNIT_STAT_INTELLECT, "INTELLECT", "AGILITY")])
                        attrs[a] = match and tonumber((match:gsub(",", ""):gsub("\\.", ""))) or nil
                    end
                end
            end
            return attrs
        end
        -- isTransmogKnown
    elseif attr == "isTransmogKnown" then
        if line:match(Self.PATTERN_APPEARANCE_KNOWN) or line:match(Self.PATTERN_APPEARANCE_UNKNOWN_ITEM) then
            return true
        elseif line:match(Self.PATTERN_APPEARANCE_UNKNOWN) then
            return false
        end
        -- isTransmogSourceKnown
    elseif attr == "isTransmogSourceKnown" then
        if line:match(Self.PATTERN_APPEARANCE_KNOWN .. "$") then
            return true
        elseif line:match(Self.PATTERN_APPEARANCE_UNKNOWN) or line:match(Self.PATTERN_APPEARANCE_UNKNOWN_ITEM) then
            return false
        end
    end
end

---@param item Item|string|integer
---@param attr string
---@return any
function Self.GetInfo(item, attr, ...)
    local isInstance = type(item) == "table" and item.link and true --[[@as boolean]]
    local id = isInstance and item.id or tonumber(item)
    local link = isInstance and item.link or Self.IsLink(item) and item --[[@as string]]
    item = isInstance and item or link or id

    if not item then
        return
        -- Already known
    elseif isInstance and item[attr] ~= nil then
        return item[attr]
        -- id
    elseif attr == "id" and id then
        return id
        -- link
    elseif attr == "link" and link then
        return link
        -- level, baseLevel, realLevel
    elseif Util.In(attr, "level", "baseLevel") or attr == "realLevel" and not Self.IsScaled(item) then
        return (select(attr == "baseLevel" and 3 or 1, GetDetailedItemLevelInfo(link or id)))
        -- realMinLevel
    elseif attr == "realMinLevel" and not Self.IsScaled(item) then
        return (select(Self.INFO.basic.minLevel, GetItemInfo(link or id)))
        -- maxLevel
    elseif attr == "maxLevel" then
        if Self.GetInfo(item, "quality") == Enum.ItemQuality.Heirloom then
            return Self.GetInfo(Self.GetLinkForLevel(link, Self.GetInfo(item, "toLevel")), "level", ...)
        else
            return Self.GetInfo(item, "realLevel", ...)
        end
        -- isEquippable
    elseif attr == "isEquippable" then
        return IsEquippableItem(link or id) or Self.IsGearToken(item) or Self.IsRelic(item)
        -- visualId, visualSourceId
    elseif link and (attr == "visualId" or attr == "visualSourceId") then
        return (select(attr == "visualId" and 1 or 2, C_TransmogCollection.GetItemInfo(link)))
        -- From link
    elseif Self.INFO.link[attr] then
        if isInstance then
            return item:GetLinkInfo()[attr]
        else
            if type(Self.INFO.link[attr]) == "string" then
                return select(3, link:find(Self.INFO.link[attr] --[[@as string]]))
            else
                local info, i, numBonusIds, bonusIds = Self.INFO.link, 0, 1
                for v in link:gmatch(":(%-?%d*)") do
                    i = i + 1
                    if attr == "bonusIds" and i > info.numBonusIds then
                        if i > info.numBonusIds + numBonusIds then
                            return bonusIds
                        else
                            bonusIds = bonusIds or Util.Tbl.New()
                            tinsert(bonusIds, tonumber(v))
                        end
                    elseif i == info[attr] - 1 + numBonusIds then
                        return tonumber(v)
                    elseif i == info.numBonusIds then
                        numBonusIds = tonumber(v) or 0
                    end
                end
            end
        end
        -- From GetItemInfo()
    elseif Self.INFO.basic[attr] then
        if isInstance then
            return item:GetBasicInfo()[attr]
            -- quality
        elseif attr == "quality" then
            local color = Self.GetInfo(item, "color")
            -- TODO: This is a workaround for epic item links having color "a335ee", but ITEM_QUALITY_COLORS has "a334ee"
            return color == "a335ee" and 4 or color and Util.Tbl.FindWhere(ITEM_QUALITY_COLORS, "hex", "|cff" .. color) or 1
            -- equipLoc
        elseif attr == "equipLoc" and Self.IsGearToken(item) then
            return Self.GetGearTokenEquipLoc(item)
        else
            return (select(Self.INFO.basic[attr], GetItemInfo(item)))
        end
        -- From ScanTooltip()
    elseif Self.INFO.full[attr] then
        if isInstance then
            return item:GetFullInfo()[attr]
        else
            local val = Util.ScanTooltip(fullScanFn, link, nil, attr)
            return val
                or attr == "realLevel" and Self.GetInfo(item, "level")
                or attr == "realMinLevel" and Self.GetInfo(item, "minLevel")
                or attr == "isTransmogKnown" and Self.IsAppearanceKnown(item)
                or attr == "isTransmogSourceKnown" and Self.IsAppearanceSourceKnown(item)
                or val
        end
    end
end

-------------------------------------------------------
--               Create item instance                --
-------------------------------------------------------

-- Create an item instance from a link
---@param item Item|string
---@param owner string?
---@param bagOrEquip integer?
---@param slot integer?
---@param isTradable boolean?
---@return Item
function Self.FromLink(item, owner, bagOrEquip, slot, isTradable)
    if type(item) == "string" then
        owner = owner and Unit.Name(owner) or nil
        item = setmetatable({
            link = item,
            owner = owner,
            isOwner = Unit.IsSelf(owner),
            infoLevel = Self.INFO_NONE,
            isTradable = Util.Default(isTradable, not owner or nil)
        }, Meta)
        item:SetPosition(bagOrEquip, slot)
    end

    return item
end

-- Create an item instance for the given equipment slot
---@param slot integer
---@param unit string
function Self.FromSlot(slot, unit, isTradable)
    unit = unit or "player"
    local link = GetInventoryItemLink(unit, slot)
    if link then
        return Self.FromLink(link, unit, slot, nil, isTradable)
    end
end

-- Create an item instance from the given bag position
---@param bag integer
---@param slot integer
---@param isTradable boolean
function Self.FromBagSlot(bag, slot, isTradable)
    local link = C_Container.GetContainerItemLink(bag, slot)
    if link then
        return Self.FromLink(link, "player", bag, slot, isTradable)
    end
end

-- Get the currently equipped artifact weapon
---@param unit string?
function Self.GetEquippedArtifact(unit)
    unit = unit or "player"
    local classId = Unit.ClassId(unit)

    for _, slot in pairs(Self.SLOTS[Self.TYPE_WEAPON]) do
        local id = GetInventoryItemID(unit, slot) or Self.GetInfo(GetInventoryItemLink(unit, slot), "id")
        if id then
            for i, spec in pairs(Self.CLASSES[classId].specs) do
                if id == spec.artifact.id then
                    return Self.FromSlot(slot, unit, false)
                end
            end
        end
    end
end

-------------------------------------------------------
--                       Info                        --
-------------------------------------------------------

-- Get item info from a link
---@param self Item
function Self:GetLinkInfo()
    if self.infoLevel < Self.INFO_LINK then
        local info = Self.INFO.link

        -- Extract string data
        for attr, p in pairs(info) do
            if type(p) == "string" then
                self[attr] = select(3, self.link:find(p))
            end
        end

        -- Extract int data
        local i, attr = 0
        for v in self.link:gmatch(":(%-?%d*)") do
            i = i + 1

            if info.bonusIds and Util.Num.In(i - info.numBonusIds, 1, self.numBonusIds or 0) then
                Util.Tbl.Set(self, "bonusIds", i - info.numBonusIds, tonumber(v))
            else
                attr = Util.Tbl.Find(info, i - 1 + (self.numBonusIds or 1))
                if attr then
                    self[attr] = tonumber(v)
                end
            end

            if i == 1 and self.itemType and self.itemType ~= "item" then
                break
            end
        end

        -- TODO: This is a workaround for epic item links having color "a335ee", but ITEM_QUALITY_COLORS has "a334ee"
        self.quality = self.color == "a335ee" and 4 or self.color and Util.Tbl.FindWhere(ITEM_QUALITY_COLORS, "hex", "|cff" .. self.color) or 1

        self.infoLevel = Self.INFO_LINK
    end

    return self, self.infoLevel >= Self.INFO_LINK
end

-- Get info from GetItemInfo()
function Self:GetBasicInfo()
    self:GetLinkInfo()

    if self.infoLevel == Self.INFO_LINK then
        local data
        if self.itemType == "battlepet" then
            data = Util.Tbl.New(C_PetJournal.GetPetInfoBySpeciesID(self.id))
            if next(data) then
                self.texture = data[2]
                self.isTradable = data[9]
                self.isPetKnown = C_PetJournal.GetOwnedBattlePetString(self.id) ~= nil
                self.infoLevel = Self.INFO_BASIC
            end
        else
            data = Util.Tbl.New(GetItemInfo(self.link))
            if next(data) then
                -- Get correct level
                local level, _, baseLevel = GetDetailedItemLevelInfo(self.link)

                -- Set data
                for attr, pos in pairs(Self.INFO.basic) do
                    self[attr] = data[pos]
                end

                -- Some extra data
                self.level = level or self.level
                self.baseLevel = baseLevel or self.level
                self.isEquippable = IsEquippableItem(self.link) or self:IsGearToken() or Self.IsRelic(self)
                self.equipLoc = Util.Str.IsEmpty(self.equipLoc) and self:GetGearTokenEquipLoc() or self.equipLoc
                self.isSoulbound = self.bindType == LE_ITEM_BIND_ON_ACQUIRE or self.isEquipped and self.bindType == LE_ITEM_BIND_ON_EQUIP
                self.isTradable = Util.Default(self.isTradable, not self.isSoulbound or nil)
                self.visualId, self.visualSourceId = C_TransmogCollection.GetItemInfo(self.link)

                if self.subType == "Companion Pets" then
                    local tradable, _, _, _, speciesId = select(9, C_PetJournal.GetPetInfoByItemID(self.id))
                    self.isTradable, self.isPetKnown = tradable, C_PetJournal.GetOwnedBattlePetString(speciesId) ~= nil
                end

                self.infoLevel = Self.INFO_BASIC
            end
        end
        Util.Tbl.Release(data)
    end

    return self, self.infoLevel >= Self.INFO_BASIC
end

-- Get extra info by scanning the tooltip
function Self:GetFullInfo()
    self:GetBasicInfo()

    if self.infoLevel == Self.INFO_BASIC and self.isEquippable then
        Util.ScanTooltip(function(i, line, lines)
            self.infoLevel = Self.INFO_FULL

            for attr in pairs(Self.INFO.full) do
                if self[attr] == nil then
                    self[attr] = fullScanFn(i, line, lines, attr)
                end
            end
        end, self.link)

        -- Lookup transmog collection info
        self.isTransmogKnown = self.isTransmogKnown or self:IsAppearanceKnown()
        self.isTransmogSourceKnown = self.isTransmogSourceKnown or self:IsAppearanceSourceKnown()

        -- Effective and max level
        self.realLevel = self.realLevel or self.level
        self.maxLevel = self.quality == Enum.ItemQuality.Heirloom and Self.GetInfo(Self.GetLinkForLevel(self.link, self.toLevel), "level") or self.realLevel

        -- Get item position in bags or equipment
        local bagOrEquip, slot = self:GetPosition()
        if bagOrEquip and slot ~= 0 then
            self:SetPosition(bagOrEquip, slot)
        end

        -- Check if the item is tradable
        self.isTradable, self.isSoulbound, self.bindTimeout = self:IsTradable()

        if Addon.DEBUG and self.isOwner then
            self.isTradable, self.bindTimeout = true, self.isSoulbound
        end
    end

    return self, self.infoLevel >= Self.INFO_FULL
end

-------------------------------------------------------
--              Equipment location info              --
-------------------------------------------------------

-- Get the equipment location or relic type
---@return string
function Self:GetLocation()
    return self:IsRelic() and self:GetFullInfo().relicType or self.equipLoc
end

-- Determine if two items belong to the same location
---@param locA Item|string|integer
---@param locB Item|string|integer
function Self.IsSameLocation(locA, locB, allWeapons)
    locA = (type(locA) == "table" or Self.IsLink(locA)) and Self.GetInfo(locA, "equipLoc") or locA
    locB = (type(locB) == "table" or Self.IsLink(locB)) and Self.GetInfo(locB, "equipLoc") or locB

    -- Artifact relics (and maybe other things without equipLoc)
    if Util.Str.IsEmpty(locA) then
        return Util.Str.IsEmpty(locB)
    elseif Util.Str.IsEmpty(locB) then
        return false
    end

    local aIsWeapon = Util.In(locA, Self.TYPES_WEAPON)
    local bIsWeapon = Util.In(locB, Self.TYPES_WEAPON)
    local aIsRanged = Util.In(locA, Self.TYPES_RANGED)
    local bIsRanged = Util.In(locB, Self.TYPES_RANGED)

    -- Weapons and armor
    if aIsWeapon ~= bIsWeapon or aIsRanged ~= bIsRanged then
        return false
    elseif aIsWeapon and allWeapons then
        return true
    elseif locA == Self.TYPE_WEAPONMAINHAND then
        return not Util.In(locB, Self.TYPES_OFFHAND)
    elseif Util.In(locA, Self.TYPES_OFFHAND) then
        return locB ~= Self.TYPE_WEAPONMAINHAND
    else
        return aIsWeapon or Util.Tbl.Equals(Self.SLOTS[locA], Self.SLOTS[locB])
    end
end

-- Get a list of owned items by equipment location
---@param loc Item|string
---@param allWeapons boolean?
function Self.GetOwnedForLocation(loc, allWeapons)
    local items = Util.Tbl.New()
    local classId = Unit.ClassId("player")

    local isRelic
    if type(loc) == "table" then
        isRelic = loc:IsRelic()
        loc = isRelic and loc:GetFullInfo().relicType or loc.equipLoc
    else
        isRelic = loc:sub(1, 7) ~= "INVTYPE"
    end

    -- Get equipped item(s)
    if isRelic then
        local weapon = Self.GetEquippedArtifact()
        items = weapon and weapon:GetRelics(loc) or items
    elseif Self.SLOTS[loc] then
        local slots = Self.SLOTS[allWeapons and Util.In(loc, Self.TYPES_WEAPON) and Self.TYPE_WEAPON or loc]
        for i, slot in pairs(slots) do
            local link = GetInventoryItemLink("player", slot)
            if link and not Self.IsLegendary(link) and Self.IsSameLocation(link, loc, allWeapons) then
                tinsert(items, link)
            end
        end
    else
        return
    end

    -- Get item(s) from bag
    for bag = 0, NUM_BAG_SLOTS do
        for slot = 1, C_Container.GetContainerNumSlots(bag) do
            local link = C_Container.GetContainerItemLink(bag, slot)

            if link and Self.GetInfo(link, "isEquippable") then
                if isRelic then
                    if Self.IsRelic(link) then
                        -- It's a relic
                        if Self.GetInfo(link, "relicType") == loc then
                            tinsert(items, link)
                        end
                    elseif Self.GetInfo(link, "classId") == Enum.ItemClass.Weapon then
                        -- It might be an artifact weapon
                        local id = Self.GetInfo(link, "id")
                        for i, spec in pairs(Self.CLASSES[classId].specs) do
                            if id == spec.artifact.id and Addon.db.char.specs[i] then
                                for slot, relicType in pairs(spec.artifact.relics) do
                                    if relicType == loc then
                                        tinsert(items, (select(2, GetItemGem(link, slot))))
                                    end
                                end
                            end
                        end
                    end
                elseif not Self.IsLegendary(link) and Self.IsSameLocation(link, loc, allWeapons) then
                    tinsert(items, link)
                end
            end
        end
    end

    return items
end

-- Get number of slots for a given equipment location
function Self:GetSlotCountForLocation(unit)
    if not self:GetBasicInfo().isEquippable or not select(2, self:GetBasicInfo()) then
        return 0
    end

    local class = Self.CLASSES[Unit.ClassId(unit or "player")]

    if self:IsRelic() then
        self:GetFullInfo()
        local n = 0
        for i, spec in pairs(class.specs) do
            if Addon.db.char.specs[i] then
                n = n + Util.Tbl.CountOnly(spec.artifact.relics, self.relicType)
            end
        end
        return n
    elseif self:IsWeaponToken() then
        return 2
    elseif self.equipLoc == Self.TYPE_WEAPON then
        for i, spec in pairs(class.specs) do
            if Addon.db.char.specs[i] and spec.dualWield then
                return 2
            end
        end

        return class.dualWield and 2 or 1
    elseif self.isEquippable then
        return #Self.SLOTS[self.equipLoc]
    else
        return 0
    end
end

-- Get the threshold for the item's slot
---@param unit string?
---@param upper boolean?
function Self:GetThresholdForLocation(unit, upper)
    unit = Unit(unit or "player")
    local f = Addon.db.profile.filter

    -- Lower threshold of -1 for relics and legacy runs, so items have to be higher in ilvl to be worth considering
    if not upper and (self:IsRelic() or Util.IsLegacyRun(unit)) then
        return -1
    end

    -- Use DB option only for the player and only for the lower threshold
    local custom = not upper and Unit.IsSelf(unit)
    local threshold = custom and f.ilvlThreshold or Self.ILVL_THRESHOLD

    -- Scale threshold for lower level chars
    local level = UnitLevel(unit)
    threshold = ceil(threshold * (level and level > 0 and level / MAX_PLAYER_LEVEL or 1))

    -- Trinkets and rings might have double the normal threshold
    if Util.Select(self:GetBasicInfo().equipLoc, Self.TYPE_TRINKET, f.ilvlThresholdTrinkets or not custom, Self.TYPE_FINGER, f.ilvlThresholdRings and custom) then
        threshold = threshold * 2
    end

    return threshold
end

-- Get the reference level for equipment location
---@param unit string
function Self:GetLevelForLocation(unit)
    if not self:GetBasicInfo().isEquippable then return 0 end

    unit = Unit(unit or "player")
    local loc = self:GetLocation()

    if Unit.IsSelf(unit) then
        -- For the player
        if self:IsWeapon() then
            -- Weapons
            Self.UpdatePlayerCacheWeapons()

            local slotMin

            for spec in pairs(Self.CLASSES[Unit.ClassId(unit)].specs) do
                if self:IsUseful(unit, spec) then
                    local cache = Self.GetPlayerCache(loc, spec)
                    slotMin = cache and min(slotMin or cache.ilvl, cache.ilvl)
                end
            end

            return slotMin or 0
        else
            -- Everything else
            local cache = Self.GetPlayerCache(loc) or Util.Tbl.New()
            if not Self.IsPlayerCacheValid(cache) then
                local owned = self:GetOwnedForLocation()
                cache.time = GetTime()
                cache.ilvl = owned and Util(owned)
                    :Map(Self.GetInfo, nil, nil, "maxLevel")
                    :Sort(true)(self:GetSlotCountForLocation(unit)) or 0
                Self.SetPlayerCache(loc, cache)
            end

            return cache.ilvl or 0
        end
    else
        -- For other players
        return Inspect.GetLevel(Unit.Name(unit), loc)
    end
end

-- Get equipped item links for the location
---@param unit string
function Self:GetEquippedForLocation(unit)
    unit = Unit(unit or "player")
    local isSelf = Unit.IsSelf(unit)

    if self:IsRelic() then
        return Inspect.GetLink(unit, self:GetFullInfo().relicType)
    elseif self.isEquippable then
        local links = Util.Tbl.New()
        for i, slot in pairs(Self.SLOTS[self.equipLoc]) do
            tinsert(links, isSelf and GetInventoryItemLink(unit, slot) or Inspect.GetLink(unit, slot) or nil)
        end
        return links
    end
end

-------------------------------------------------------
--                 Gems, relics etc.                 --
-------------------------------------------------------

-- Get gems in the item
function Self:GetGem(slot)
    return (select(2, GetItemGem(self.link, slot)))
end

-- Get artifact relics in the item
---@param relicTypes string|table?
function Self:GetRelics(relicTypes)
    local id = self:GetBasicInfo().id

    for _, class in pairs(Self.CLASSES) do
        for i, spec in pairs(class.specs) do
            if spec.artifact.id == id then
                local relics = {}
                for slot, relicType in pairs(spec.artifact.relics) do
                    if not relicTypes or Util.In(relicType, relicTypes) then
                        tinsert(relics, self:GetGem(slot))
                    end
                end
                return relics
            end
        end
    end
end

-- Get all relic slots (optionally with types that only occur in this weapon for the given class)
function Self:GetRelicSlots(unique)
    local id = self:GetBasicInfo().id

    for _, class in pairs(Self.CLASSES) do
        for i, spec in pairs(class.specs) do
            if spec.artifact.id == id then
                local relics = spec.artifact.relics

                -- Remove all relicTypes that occur in other weapons
                if unique then
                    relics = Util.Tbl.Copy(relics)
                    for slot, relicType in pairs(relics) do
                        for i, spec in pairs(class.specs) do
                            if spec.artifact.id ~= id then
                                for _, otherRelicType in pairs(spec.artifact.relics) do
                                    if otherRelicType == relicType then
                                        relics[slot] = nil
                                        break
                                    end
                                end
                            end
                            if not relics[slot] then break end
                        end
                    end
                end

                return relics
            end
        end
    end
end

-------------------------------------------------------
--                       Tests                       --
-------------------------------------------------------

-- Check if an item can be equipped
---@param unit string
function Self:CanBeEquipped(unit, ...)
    -- Check if it's equippable
    if not self:GetBasicInfo().isEquippable then
        return false
    end

    self:GetFullInfo()

    unit = unit or "player"
    local className, _, classId = UnitClass(unit)
    local class = Self.CLASSES[classId]
    local isSelf = Unit.IsSelf(unit)

    -- Check if there are class/spec restrictions
    if self.classes and not Util.In(className, self.classes) then
        return false
    elseif ... then
        local found = false
        for i, spec in Util.Each(...) do
            if not (self.spec and self.spec ~= select(2, GetSpecializationInfo(spec))) and
                not (self:IsArtifact() and self.id ~= class.specs[spec].artifact.id) then
                found = true
                break
            end
        end
        if not found then return false end
    end

    -- Check if the armor/weapon type can be equipped
    if Util.In(self.classId, Enum.ItemClass.Armor, Enum.ItemClass.Weapon) then
        return self.equipLoc == Self.TYPE_CLOAK
            or Util.In(self.subClassId, class[self.classId == Enum.ItemClass.Armor and "armor" or "weapons"])
        -- Everyone can use weapon tokens for their class
    elseif self:IsGearToken() then
        return true
        -- Check relic type
    elseif self:IsRelic() then
        for i, spec in pairs(class.specs) do
            if (not isSelf or Addon.db.char.specs[i]) and Util.In(self.relicType, spec.artifact.relics) then
                return true
            end
        end
    end

    return false
end

-- Check the item quality
---@param self ItemRef
function Self:HasSufficientQuality(isLootEvent)
    local quality = Self.GetInfo(self, "quality")

    if not quality or quality >= Enum.ItemQuality.Legendary then
        return false
    elseif not IsEquippableItem(self.link or self) then
        return quality >= Enum.ItemQuality.Uncommon
    elseif isLootEvent or Addon.db.profile.filter.transmog or Util.IsLegacyRun() then
        return quality >= Enum.ItemQuality.Common
    elseif IsInRaid() then
        return quality >= Enum.ItemQuality.Epic
    else
        return quality >= Enum.ItemQuality.Rare
    end
end

-- Check if item either has no or matching primary attributes
function Self:HasMatchingAttributes(unit, ...)
    unit = unit or "player"
    self:GetFullInfo()

    -- Item has no primary attributes
    if not self.attributes or not next(self.attributes) then
        return true
        -- Check if item has a primary attribute that the class/spec can use
    else
        local isSelf, classId = Unit.IsSelf(unit), Unit.ClassId(unit)

        for i, info in pairs(Self.CLASSES[classId].specs) do
            if not isSelf or Util.Check(..., Util.In(i, ...), true) then
                if self.attributes[info.attribute] then return true end
            end
        end
    end

    return false
end

-- Check against equipped ilvl
function Self:HasSufficientLevel(unit)
    unit = unit or "player"
    return (self:GetInfo("realLevel") or 1) + self:GetThresholdForLocation(unit) >= self:GetLevelForLocation(unit)
end

-- Check against current character level
function Self:HasSufficientCharacterLevel(unit, fixedThreshold)
    unit = unit or "player"

    local threshold = (fixedThreshold or not Unit.IsSelf(unit)) and Self.LVL_THRESHOLD
        or Addon.db.profile.filter.lvlThreshold

    return threshold == -1 or (UnitLevel(unit) or 1) + threshold >= (self:GetInfo("realMinLevel") or 1)
end

-- Check if item is useful for the player
function Self:IsUseful(unit, ...)
    unit = unit or "player"
    self:GetBasicInfo()

    if self.equipLoc == Self.TYPE_TRINKET then
        if not Self.TRINKETS[self.id] then
            return true
        else
            local cat = Self.TRINKETS[self.id]
            for i, spec in pairs(Self.CLASSES[Unit.ClassId(unit)].specs) do
                if (not ... or Util.In(i, ...))
                    and (bit.band(cat, Self.MASK_ATTR) == 0 or bit.band(cat, spec.attribute) > 0)
                    and (bit.band(cat, Self.MASK_ROLE) == 0 or bit.band(cat, spec.role) > 0) then
                    return true
                end
            end
            return false
        end
    elseif not self:CanBeEquipped(unit, ...) then
        return false
    elseif self:IsRelic() and UnitLevel(unit) > MAX_PLAYER_LEVEL - 10 then
        return false
    elseif self:IsGearToken() then
        return true
    elseif not self:HasMatchingAttributes(unit, ...) then
        return false
    elseif self:IsWeapon() and ... then
        for i, v in Util.Each(...) do
            local spec = Self.CLASSES[Unit.ClassId(unit)].specs[v]
            if not spec.weapons or Util.In(self.equipLoc, spec.weapons) then return true end
        end
        return false
    else
        return true
    end
end

-- Check if the item is an upgrade according to Pawn
function Self:IsPawnUpgrade(unit, ...)
    if unit and Unit.IsSelf(unit) and IsAddOnLoaded("Pawn") and PawnGetItemData and PawnIsItemAnUpgrade and PawnCommon and PawnCommon.Scales then
        local data = PawnGetItemData(self.link)
        if data then
            for i, scale in pairs(PawnIsItemAnUpgrade(data) or Util.Tbl.EMPTY) do
                if not ... or Util.In(PawnCommon.Scales[scale.ScaleName].specID, ...) then
                    return true
                end
            end
        end
        return false
    end
end

-------------------------------------------------------
--                      Eligible                     --
-------------------------------------------------------

function Self:IsCollectibleMissing(unit)
    local isPet = self:IsPet()
    local isTransmogable = self:IsTransmogable(unit)
    local f = Addon.db.profile.filter

    if not isPet and not isTransmogable then
        return false
    elseif not Unit.IsSelf(unit or "player") then
        return not Addon:UnitIsTracking(unit) and Util.IsLegacyRun(unit)
    elseif isPet then
        return (not f.enabled or f.pets) and self:GetBasicInfo().isPetKnown == false
    else
        return (not f.enabled or f.transmog) and (
            not self:GetFullInfo().isTransmogKnown
                or f.enabled and f.transmogItem and not self:GetFullInfo().isTransmogSourceKnown
            )
    end
end

function Self:IsUpgrade(unit)
    local f = Addon.db.profile.filter

    if not self:HasSufficientLevel(unit) then
        return false
    elseif not self:HasSufficientCharacterLevel(unit) then
        return false
    elseif Unit.IsSelf(unit) and f.enabled then
        local specs = Util(Addon.db.char.specs):CopyOnly(true, true):Keys()()
        local isUseful = true

        if not self:IsUseful(unit, specs) then
            isUseful = false
        elseif f.pawn and self.equipLoc ~= Self.TYPE_TRINKET and not self:IsGearToken() then
            isUseful = self:IsPawnUpgrade(unit, specs) ~= false
        end

        Util.Tbl.Release(specs)
        return isUseful
    else
        return self:IsUseful(unit)
    end
end

-- Register an eligible unit's interest
function Self:SetEligible(unit, to)
    self:GetEligible()
    self.eligible[Unit.Name(unit)] = to == nil and true or to
end

-- Check who in the group could use the item, either for one unit or all units in the group.
-- - nil: A unit can't reasonably use the item (they can' wear it or send it to and alt)
-- - false: They probably don't want it (e.g. ilvl too low)
-- - true: It might be an upgrade of some sort (e.g. ilvl high enough or collectible)
---@param unit string?
---@return table|boolean|nil
function Self:GetEligible(unit)
    if not self.eligible then
        if unit then
            if self:IsCollectibleMissing(unit) then
                return true
            elseif not self:GetBasicInfo().isEquippable then
                return false
            elseif self.isSoulbound and not self:CanBeEquipped(unit) then
                return nil
            else
                return self:IsUpgrade(unit) or false
            end
        else
            local eligible = Util.Tbl.New()
            for i = 1, GetNumGroupMembers() do
                local u = GetRaidRosterInfo(i)
                if u then
                    eligible[u] = self:GetEligible(u)
                end
            end

            if Addon.DEBUG and self.isOwner and eligible[UnitName("player")] == nil then
                eligible[UnitName("player")] = self:GetEligible("player")
            end

            self.eligible = eligible
        end
    end

    if unit then
        return self.eligible[Unit.Name(unit)]
    else
        return self.eligible
    end
end

-- Get the # of eligible players
---@param checkInterest boolean?
---@param othersOnly boolean?
function Self:GetNumEligible(checkInterest, othersOnly)
    local n = 0
    for unit, v in pairs(self:GetEligible()) do
        if (not checkInterest or v) and not (othersOnly and Unit.IsSelf(unit)) then
            n = n + 1
        end
    end
    return n
end

-------------------------------------------------------
--                     Decisions                     --
-------------------------------------------------------

-- Check if a looted item should be checked further, only accessing link info
---@param item string
---@param owner string
function Self.ShouldBeChecked(item, owner)
    return item and owner
        and (not Addon.db.profile.dontShare or Unit.IsSelf(owner))
        and Self.HasSufficientQuality(item, true)
        and not Self.IsConduit(item)
end

-- Check if the item should be handled by the addon
function Self:ShouldBeConsidered()
    return self:IsPet() or self:HasSufficientQuality() and self:GetBasicInfo().isEquippable and self:GetFullInfo().isTradable
end

-- Check if the addon should offer to bid on an item
---@return boolean
function Self:ShouldBeBidOn()
    if Addon.db.profile.dontShare or not self:ShouldBeConsidered() then
        return false
    end

    local eligible = self:GetEligible("player") --[[@as boolean]]
    return eligible or not Addon.db.profile.filter.enabled and eligible ~= nil
end

-- Check if the addon should start a roll for an item
function Self:ShouldBeRolledFor()
    return not (Addon.db.profile.dontShare and self.isOwner) and self:ShouldBeConsidered() and self:GetNumEligible(true, self.isOwner) > 0
end

-------------------------------------------------------
--                      Loading                      --
-------------------------------------------------------

-- Check if item data is loaded
function Self:IsLoaded()
    return self:GetBasicInfo().infoLevel >= Self.INFO_BASIC
end

-- Run a function when item data is loaded
function Self:OnLoaded(fn, ...)
    local args, try = { ... }
    try = function(n)
        if self:IsLoaded() then
            fn(unpack(args))
        elseif n > 0 then
            Addon:ScheduleTimer(try, 0.1, n - 1)
        end
    end
    try(10)
end

-- Check if item data is fully loaded (loaded + position available)
function Self:IsFullyLoaded(tradable)
    if not self:IsLoaded() then return false end
    local bagOrEquip, slot, isTradable = self:GetPosition()
    return bagOrEquip and slot ~= 0 and (not tradable or isTradable)
end

-- Run a function when item data is fully loaded
function Self:OnFullyLoaded(fn, ...)
    if not self.isOwner then
        self:OnLoaded(fn, ...)
    else
        local entry, try = { fn = fn, args = { ... } }
        try = function(n)
            local i = Util.Tbl.Find(Self.queue, entry)
            if i then
                if self:IsFullyLoaded(n >= 5) then
                    tremove(Self.queue, i)
                    fn(unpack(entry.args))
                elseif n > 0 then
                    entry.timer = Addon:ScheduleTimer(try, 0.1, n - 1)
                else
                    tremove(Self.queue, i)
                end
            end
        end
        tinsert(Self.queue, entry)
        try(10)
    end
end

-------------------------------------------------------
--              Position and tradability             --
-------------------------------------------------------

-- Check if the item (given by self or bag+slot) is tradable
---@param selfOrBag Item|integer?
---@param slot integer?
---@return boolean?
---@return boolean
---@return boolean
function Self.IsTradable(selfOrBag, slot)
    local bag, isSoulbound, bindTimeout

    -- selforBag is an item instance
    if type(selfOrBag) == "table" then
        local self = selfOrBag

        if self.isTradable ~= nil then
            return self.isTradable, self.isSoulbound, self.bindTimeout
        elseif self.isEquipped then
            return false, true, false
        elseif not self.owner then
            return true, false, false
        elseif not self.isOwner then
            -- Check ilvl
            local level = self:GetLevelForLocation(self.owner)
            local isTradable = level == 0 or level + self:GetThresholdForLocation(self.owner, true) >= self.level

            return isTradable, self.isSoulbound, self.isSoulbound and isTradable
        else
            bag, slot = self.bagOrEquip, self.slot
            isSoulbound, bindTimeout = self.isSoulbound, self.bindTimeout
        end
    else
        bag = selfOrBag
    end

    -- Can't scan the tooltip if bag or slot is missing
    if not bag or not slot or slot == 0 then
        return nil, isSoulbound, bindTimeout
    end

    Util.ScanTooltip(function(i, line)
        -- Soulbound
        if not isSoulbound then
            isSoulbound = line:match(Self.PATTERN_SOULBOUND) ~= nil
            if isSoulbound then return end
        end
        -- Bind timeout
        if not bindTimeout then
            bindTimeout = line:match(Self.PATTERN_TRADE_TIME_REMAINING) ~= nil
            if bindTimeout then return end
        end
    end, bag, slot)

    return not isSoulbound or bindTimeout, isSoulbound, bindTimeout
end

-- Get the item's position
---@param refresh boolean?
function Self:GetPosition(refresh)
    if not self.isOwner or not refresh and self.bagOrEquip and self.slot ~= 0 then
        return self.bagOrEquip, self.slot, self.isTradable
    end

    -- Check bags
    local bag, slot, isTradable
    for b = self.slot == 0 and self.bagOrEquip or 0, self.slot == 0 and self.bagOrEquip or NUM_BAG_SLOTS do
        for s = 1, C_Container.GetContainerNumSlots(b) do
            local link = C_Container.GetContainerItemLink(b, s)
            if link == self.link then
                isTradable = Self.IsTradable(b, s)
                if isTradable or not (bag and slot) then
                    bag, slot = b, s
                    if isTradable then break end
                end
            end
        end

        if bag and slot and isTradable then break end
    end

    if bag and slot then
        return bag, slot, isTradable
    elseif self.bagOrEquip and self.slot == 0 then
        return self.bagOrEquip, self.slot, self.isTradable
    end

    -- Check equipment
    if select(2, self:GetBasicInfo()) and not self:IsRelic() then
        for _, equipSlot in pairs(Self.SLOTS[self.equipLoc]) do
            if self.link == GetInventoryItemLink(self.owner, equipSlot) then
                return equipSlot, nil, false
            end
        end
    end
end

-- Set the item's position
---@param bagOrEquip table|integer?
---@param slot integer?
function Self:SetPosition(bagOrEquip, slot)
    if type(bagOrEquip) == "table" then
        bagOrEquip, slot = unpack(bagOrEquip)
    end

    self.bagOrEquip = bagOrEquip
    self.slot = slot
    self.position = { bagOrEquip, slot }

    self.isEquipped = bagOrEquip and slot == nil
    self.isSoulbound = self.isSoulbound or self.isEquipped
    if self.isEquipped and self.isTradable then
        self.isTradable = false
        self.bindTimeout = false
    end
end

-------------------------------------------------------
--                 Player level cache                --
-------------------------------------------------------

-- Get an entry from the player level cache
---@param loc string
---@param spec integer?
function Self.GetPlayerCache(loc, spec)
    loc = Self.GetCacheLocation(loc)

    return Self.playerCache[spec and loc .. spec or loc]
end

-- Set an entry ont he player level cache
---@param loc string
---@param specOrCache integer|table
---@param cache table?
function Self.SetPlayerCache(loc, specOrCache, cache)
    loc = Self.GetCacheLocation(loc)
    local spec = cache and specOrCache
    ---@cast cache table
    cache = cache or specOrCache

    Self.playerCache[spec and loc .. spec or loc] = cache
end

-- Normalize cache locations
function Self.GetCacheLocation(loc)
    return Util.In(loc, Self.TYPES_RANGED) and Self.TYPE_RANGED
        or loc == Self.TYPE_HOLDABLE and Self.TYPE_WEAPONOFFHAND
        or loc
end

-- Update cache for all weapons that are useful to the player
function Self.UpdatePlayerCacheWeapons()
    local class = Self.CLASSES[Unit.ClassId("player")]

    for _, loc in pairs(Self.TYPES_WEAPON) do
        ---@type { [string]: Item }
        local owned

        for i, spec in pairs(class.specs) do
            if not spec.weapons or Util.In(loc, spec.weapons) then
                local cache = Self.GetPlayerCache(loc, i) or Util.Tbl.New()

                if not Self.IsPlayerCacheValid(cache) then
                    cache.time = GetTime()
                    owned = owned or Self.GetOwnedForLocation(loc, true)

                    local main, off, both1, both2, twohand = 0, 0, 0, 0, 0
                    local dualWield = class.dualWield or spec.dualWield

                    -- Go through all owned weapons and find highest ilvl for each type
                    for j, item in pairs(owned) do
                        owned[j] = Self.FromLink(item, "player"):GetBasicInfo()
                        item = owned[j]

                        if item:IsWeapon() and item:HasSufficientCharacterLevel("player", true) and item:IsUseful("player", i) then
                            if item.equipLoc == Self.TYPE_2HWEAPON or item:IsRangedWeapon() or item:IsArtifact() then
                                twohand = max(twohand, item.maxLevel)
                            elseif item.equipLoc == Self.TYPE_WEAPONMAINHAND then
                                main = max(main, item.maxLevel)
                            elseif Util.In(item.equipLoc, Self.TYPES_OFFHAND) then
                                off = max(off, item.maxLevel)
                            else
                                both1, both2 = max(both1, both2, item.maxLevel), min(both1, max(both2, item.maxLevel))
                            end
                        end
                    end

                    -- Determine max ilvl for covering all the weapon's slots
                    if loc == Self.TYPE_WEAPONMAINHAND or loc == Self.TYPE_WEAPON and not dualWield then
                        cache.ilvl = max(main, twohand, dualWield and both2 or both1)
                    elseif loc == Util.In(loc, Self.TYPES_OFFHAND) then
                        cache.ilvl = max(off, twohand, dualWield and both2 or 0)
                    else
                        cache.ilvl = max(min(max(main, both1), off), twohand, dualWield and max(min(main, both1), both2) or 0)
                    end

                    Self.SetPlayerCache(loc, i, cache)
                end
            end
        end

        owned = Util.Tbl.Release(true, owned)
    end
end

-- Check if a player cache entry is still valid
---@param cache table
function Self.IsPlayerCacheValid(cache)
    return cache and cache.ilvl and cache.time and cache.time + Inspect.REFRESH > GetTime()
end

-------------------------------------------------------
--                       Helper                      --
-------------------------------------------------------

-- Basically tells us whether GetRealItemLevelInfo doesn't give us the correct ilvl
---@param self ItemRef
function Self:IsScaled()
    if Self.GetInfo(self, "quality") == Enum.ItemQuality.Heirloom then
        return true
    end

    local linkLevel = Self.GetInfo(self, "linkLevel")
    local upgradeLevel = Self.GetInfo(self, "upgradeLevel")
    return linkLevel and upgradeLevel and (linkLevel ~= upgradeLevel or upgradeLevel > UnitLevel("player"))
end

-- Check if the item should get special treatment for being a weapon
function Self:IsWeapon()
    return Util.In(Self.GetInfo(self, "equipLoc"), Self.TYPES_WEAPON)
end

function Self:IsRangedWeapon()
    return Util.In(Self.GetInfo(self, "equipLoc"), Self.TYPES_RANGED)
end

-- Check if the item is a legendary from Legion or Shadowlands
function Self:IsLegendary()
    return Self.GetInfo(self, "quality") == Enum.ItemQuality.Legendary
        and Util.In(Self.GetInfo(self, "expacId"), Self.EXPAC_LEGION, Self.EXPAC_SL)
end

-- Check if the item is a Legion artifact
function Self:IsArtifact()
    return Self.GetInfo(self, "quality") == Enum.ItemQuality.Artifact
        and Self.GetInfo(self, "expacId") == Self.EXPAC_LEGION
end

-- Check if the item is a Legion artifact relic
---@param self ItemRef
function Self:IsRelic()
    return Self.GetInfo(self, "subType") == "Artifact Relic"
end

-- Check if the item has BFA azerite traits
---@param self ItemRef
function Self:IsAzeriteGear()
    return Self.GetInfo(self, "quality") >= Enum.ItemQuality.Rare
        and Self.GetInfo(self, "expacId") == Self.EXPAC_BFA
        and Util.In(Self.GetInfo(self, "equipLoc"), Self.TYPE_HEAD, Self.TYPE_SHOULDER, Self.TYPE_CHEST, Self.TYPE_ROBE)
end

-- Check if the item is a Shadowlands conduit
---@param self Item|string
function Self:IsConduit()
    return C_Soulbinds.IsItemConduitByItemInfo(Self.GetLink(self))
end

---@param self ItemRef
function Self:IsArmorToken()
    return Self.GetArmorTokenEquipLoc(self) ~= nil
end

---@param self ItemRef
function Self:IsWeaponToken()
    return Self.GetInfo(self, "expacId") == Self.EXPAC_SL and Self.GetInfo(self, "subType") == "Context Token" -- T28
end

---@param self ItemRef
function Self:IsGearToken()
    return Self.IsArmorToken(self) or Self.IsWeaponToken(self)
end

---@param self ItemRef
function Self:GetArmorTokenEquipLoc()
    return Self.GEAR_TOKENS[Self.GetInfo(self, "id")]
end

---@param self ItemRef
function Self:GetGearTokenEquipLoc()
    return Self.GetArmorTokenEquipLoc(self) or Self.IsWeaponToken(self) and Self.TYPE_WEAPON
end

-- Check if the item is a battlepet
---@param self ItemRef
function Self:IsPet()
    return Self.GetInfo(self, "itemType") == "battlepet"
        or (
        Self.GetInfo(self, "classId") == Enum.ItemClass.Miscellaneous
            and Self.GetInfo(self, "subClassId") == Enum.ItemMiscellaneousSubclass.CompanionPet
        )
end

---@param self ItemRef
function Self:IsGem()
    return Self.GetInfo(self, "itemType") == "Gem" and not Self.IsRelic(self)
end

-- Check if the item has a collectible appearance that can be unlocked
function Self:IsTransmogable(unit)
    return C_Item.IsDressableItemByID(self.link) and (not self.isSoulbound or self:CanBeEquipped(unit))
end

-- Check if the visual appearance is known
---@param self ItemRef
function Self:IsAppearanceKnown()
    if Self.IsAppearanceSourceKnown(self) then
        return true
    end

    local visualId = Self.GetInfo(self, "visualId")
    if visualId then
        local sources = C_TransmogCollection.GetAllAppearanceSources(visualId)
        if sources then
            for _, sourceId in pairs(sources) do
                if Self.IsAppearanceSourceKnown(self, sourceId) then
                    return true
                end
            end
            return false
        end
    end
end

-- Check if the visual appearance is known from the item
---@param self ItemRef
---@param sourceId integer?
function Self:IsAppearanceSourceKnown(sourceId)
    sourceId = sourceId or Self.GetInfo(self, "visualSourceId")
    return sourceId and select(5, C_TransmogCollection.GetAppearanceSourceInfo(sourceId))
end
