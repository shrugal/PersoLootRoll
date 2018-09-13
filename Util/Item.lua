local Name, Addon = ...
local Inspect, Unit, Util = Addon.Inspect, Addon.Unit, Addon.Util
local Self = Addon.Item

-------------------------------------------------------
--                     Constants                     --
-------------------------------------------------------

-- Item level threshold
Self.ILVL_THRESHOLD = 15

-- For editor auto-completion:
-- Quality: LE_ITEM_QUALITY_POOR, LE_ITEM_QUALITY_COMMON, LE_ITEM_QUALITY_UNCOMMON, LE_ITEM_QUALITY_RARE, LE_ITEM_QUALITY_EPIC, LE_ITEM_QUALITY_LEGENDARY, LE_ITEM_QUALITY_ARTIFACT, LE_ITEM_QUALITY_HEIRLOOM, LE_ITEM_QUALITY_WOW_TOKEN
-- Bind types: LE_ITEM_BIND_NONE, LE_ITEM_BIND_ON_ACQUIRE, LE_ITEM_BIND_ON_EQUIP, LE_ITEM_BIND_ON_USE, LE_ITEM_BIND_QUEST

-- Tooltip search patterns          1          2      3      4      5      6      7      8       9         10      11     12       13      14     15     16     17     18                  19
Self.PATTERN_LINK_DATA = "|?c?f?f?(%x*)|?H?([^:]*):?(%d+):?(%d*):?(%d*):?(%d*):?(%d*):?(%d*):?(%-?%d*):?(%-?%d*):?(%d*):?(%d*):?(%-?%d*):?(%d*):?(%d*):?(%d*):?(%d*):?(%d*)[^|]*|?h?%[?([^%[%]]*)%]?|?h?|?r?"
Self.PATTERN_LINK = "(|?c?f?f?%x*|?H?item:[^|]*|?h?[^|]*|?h?|?r?)"
Self.PATTERN_ILVL = ITEM_LEVEL:gsub("%%d", "(%%d+)")
Self.PATTERN_ILVL_SCALED = ITEM_LEVEL_ALT:gsub("%(%%d%)", "%%%(%%%d%%%)"):gsub("%%d", "(%%d+)")
Self.PATTERN_HEIRLOOM_LEVEL = ITEM_LEVEL_RANGE:gsub("%%d", "(%%d+)")
Self.PATTERN_RELIC_TYPE = RELIC_TOOLTIP_TYPE:gsub("%%s", "(.+)")
Self.PATTERN_CLASSES = ITEM_CLASSES_ALLOWED:gsub("%%s", "(.+)")
Self.PATTERN_SPEC = ITEM_REQ_SPECIALIZATION:gsub("%%s", "(.+)")
Self.PATTERN_STRENGTH = ITEM_MOD_STRENGTH:gsub("%%c%%s", "^%%p(.+)")
Self.PATTERN_INTELLECT = ITEM_MOD_INTELLECT:gsub("%%c%%s", "^%%p(.+)")
Self.PATTERN_AGILITY = ITEM_MOD_AGILITY:gsub("%%c%%s", "^%%p(.+)")
Self.PATTERN_SOULBOUND = ITEM_SOULBOUND
Self.PATTERN_TRADE_TIME_REMAINING = BIND_TRADE_TIME_REMAINING:gsub("%%s", ".+")
Self.PATTERN_APPEARANCE_KNOWN = TRANSMOGRIFY_TOOLTIP_APPEARANCE_KNOWN
Self.PATTERN_APPEARANCE_UNKNOWN = TRANSMOGRIFY_TOOLTIP_APPEARANCE_UNKNOWN
Self.PATTERN_APPEARANCE_UNKNOWN_ITEM = TRANSMOGRIFY_TOOLTIP_ITEM_UNKNOWN_APPEARANCE_KNOWN

-- Item loading status
Self.INFO_NONE = 0
Self.INFO_LINK = 1
Self.INFO_BASIC = 2
Self.INFO_FULL = 3

-- Item info positions
Self.INFO = {
    link = {
        color = 1,
        id = 3,
        -- enchantId = 4,
        -- gemIds = {5, 6, 7, 8},
        -- suffixId = 9,
        -- uniqueId = 10,
        linkLevel = 11,
        -- specId = 12,
        -- reforgeId = 13,
        -- difficultyId = 14,
        -- numBonusIds = 15,
        -- bonusIds = {16, 17},
        -- upgradeValue = 18,
        name = 19
    },
    basic = {
        name = 1,
        link = 2,
        quality = 3,
        level = 4,
        -- minLevel = 5,
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
        relicType = true,
        effectiveLevel = true,
        fromLevel = true,
        toLevel = true,
        maxLevel = true
    }
}

-- Cache the player's ilvl per slot
Self.playerCache = {}

-- New items waiting for the BAG_UPDATE_DELAYED event
Self.queue = {}

-- Check if item scaling is currently active
function Self.IsScalingActive(unit)
    return Util.NumBetween(UnitLevel(Unit(unit or "player")), 0, MAX_PLAYER_LEVEL)
end

-------------------------------------------------------
--                      Links                        --
-------------------------------------------------------

-- Get the item link from a string
function Self.GetLink(str)
    if type(str) == "table" then
        return str.link
    elseif type(str) == "string" then
        return select(3, str:find(Self.PATTERN_LINK))
    end
end

-- Get a version of the link that is scaled to the given player level
function Self.GetScaledLink(link, level)
    local it = Util.Iter()
    return link:gsub(".-:", function (s) if it() == 10 then return (level or MAX_PLAYER_LEVEL) .. ":" end end)
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
function Self.GetPrintableLink(str)
    return gsub(str.link or str, "\124", "\124\124");
end

-- Get just one item attribute, without creating an item instance or figuring out all other attributes as well
local scanFn = function (i, line, lines, attr)
    -- classes
    if attr == "classes" then
        local classes = line:match(Self.PATTERN_CLASSES)
        return classes and Util.StrSplit(classes, ", ")
    -- relicType
    elseif attr == "relicType" then
        return line:match(Self.PATTERN_RELIC_TYPE)
    -- effectiveLevel
    elseif attr == "effectiveLevel" then
        return tonumber(select(2, line:match(Self.PATTERN_ILVL_SCALED)) or line:match(Self.PATTERN_ILVL))
    -- fromlevel, toLevel
    elseif Util.In(attr, "fromLevel", "toLevel") then
        local from, to = line:match(Self.PATTERN_HEIRLOOM_LEVEL)
        return from and to and tonumber(attr == "fromLevel" and from or to) or nil
    end
end

function Self.GetInfo(item, attr, ...)
    local link = item and item.link or item

    if not link then
        return
    -- isRelic
    elseif attr == "isRelic" then
        return Self.GetInfo(item, "subType") == "Artifact Relic"
    -- isEquippable
    elseif attr == "isEquippable" then
        return IsEquippableItem(link) or Self.GetInfo(item, "isRelic")
    -- quality
    elseif attr == "quality" then
        local color = Self.GetInfo(item, "color")
        -- TODO: This is a workaround for epic item links having color "a335ee", but ITEM_QUALITY_COLORS has "a334ee"
        return color == "a335ee" and 4 or color and Util.TblFindWhere(ITEM_QUALITY_COLORS, "hex", "|cff" .. color) or 1
    -- level, baseLevel
    elseif Util.In(attr, "level", "baseLevel") then
        return (select(attr == "level" and 1 or 3, GetDetailedItemLevelInfo(link)))
    -- maxLevel
    elseif attr == "maxLevel" then
        if Self.GetInfo(item, "quality") == LE_ITEM_QUALITY_HEIRLOOM then
            return Self.GetInfo(Self.GetScaledLink(link, Self.GetInfo(item, "toLevel")), "level", ...)
        else
            return Self.GetInfo(item, "effectiveLevel", ...)
        end
    -- From link
    elseif Self.INFO.link[attr] then
        if item.link then
            return item:GetLinkInfo()[attr]
        else
            local v = select(Self.INFO.link[attr] + 2, link:find(Self.PATTERN_LINK_DATA))

            if v == "" then
                return attr == "expacId" and 0 or nil
            elseif Util.StrIsNumber(v) then
                return tonumber(v)
            else
                return v
            end
        end
    -- From GetItemInfo()
    elseif Self.INFO.basic[attr] then
        if item.link then
            return item:GetBasicInfo()[attr]
        else
            return (select(Self.INFO.basic[attr], GetItemInfo(link)))
        end
    -- From Tooltip scanning
    elseif Self.INFO.full[attr] then
        if attr == "effectiveLevel" and not Self.IsScalingActive((...)) then
            return Self.GetInfo(item, "level", ...)
        elseif item.link then
            return item:GetFullInfo()[attr]
        else
            return Util.ScanTooltip(scanFn, link, nil, attr)
        end
    end
end

-------------------------------------------------------
--               Create item instance                --
-------------------------------------------------------

-- Create an item instance from a link
function Self.FromLink(item, owner, bagOrEquip, slot, isTradable)
    if type(item) == "string" then
        owner = owner and Unit.Name(owner) or nil
        item = {
            link = item,
            owner = owner,
            isOwner = owner and UnitIsUnit(owner, "player"),
            infoLevel = Self.INFO_NONE,
            isTradable = Util.Default(isTradable, not owner or nil)
        }
        setmetatable(item, {__index = Self})
        item:SetPosition(bagOrEquip, slot)
    end

    return item
end

-- Create an item instance for the given equipment slot
function Self.FromSlot(slot, unit, isTradable)
    unit = unit or "player"
    local link = GetInventoryItemLink(unit, slot)
    if link then
        return Self.FromLink(link, unit, slot, nil, isTradable)
    end
end

-- Create an item instance from the given bag position
function Self.FromBagSlot(bag, slot, isTradable)
    local link = GetContainerItemLink(bag, slot)
    if link then
        return Self.FromLink(link, "player", bag, slot, isTradable)
    end
end

-- Get the currently equipped artifact weapon
function Self.GetEquippedArtifact(unit)
    unit = unit or "player"
    local classId = Unit.ClassId(unit)

    for _,slot in pairs(Self.SLOTS[Self.TYPE_WEAPON]) do
        local id = GetInventoryItemID(unit, slot) or Self.GetInfo(GetInventoryItemLink(unit, slot), "id")
        if id then
            for i,spec in pairs(Self.CLASSES[classId].specs) do
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
function Self:GetLinkInfo()
    if self.infoLevel < Self.INFO_LINK then
        -- Extract info from link
        local info = {select(3, self.link:find(Self.PATTERN_LINK_DATA))}
        
        -- Clean up data
        for i,v in pairs(info) do
            if v == "" then
                info[i] = i == 15 and 0 or nil
            elseif Util.StrIsNumber(v) then
                info[i] = tonumber(v)
            end
        end

        -- Set info
        for attr,pos in pairs(Self.INFO.link) do
            self[attr] = info[pos]
            if type(self[attr]) == "table" then
                for i,pos in ipairs(self[attr]) do
                    self[attr][i] = info[pos]
                end
            end
        end
        
        -- Some extra infos TODO: This is a workaround for epic item links having color "a335ee", but ITEM_QUALITY_COLORS has "a334ee"
        self.quality = info[1] == "a335ee" and 4 or info[1] and Util.TblFindWhere(ITEM_QUALITY_COLORS, "hex", "|cff" .. info[1]) or 1
        self.infoLevel = Self.INFO_LINK
    end

    return self, self.infoLevel >= Self.INFO_LINK
end

-- Get info from GetItemInfo()
function Self:GetBasicInfo()
    self:GetLinkInfo()
    
    if self.infoLevel == Self.INFO_LINK then
        local info = {GetItemInfo(self.link)}
        if #info > 0 then
            -- Get correct level
            local level, _, baseLevel = GetDetailedItemLevelInfo(self.link)

            -- Set info
            for attr,pos in pairs(Self.INFO.basic) do
                self[attr] = info[pos]
            end
            
            -- Some extra info
            self.level = level or self.level
            -- self.baseLevel = baseLevel or self.level
            self.isRelic = self.subType == "Artifact Relic"
            self.isEquippable = IsEquippableItem(self.link) or self.isRelic
            self.isSoulbound = self.bindType == LE_ITEM_BIND_ON_ACQUIRE or self.isEquipped and self.bindType == LE_ITEM_BIND_ON_EQUIP
            self.isTradable = not self.isSoulbound or nil
            self.infoLevel = Self.INFO_BASIC
        end
    end

    return self, self.infoLevel >= Self.INFO_BASIC
end

-- Get extra info by scanning the tooltip
function Self:GetFullInfo()
    self:GetBasicInfo()

    -- TODO: Optimize (e.g. restrict line numbers)!
    if self.infoLevel == Self.INFO_BASIC and self.isEquippable then
        Util.ScanTooltip(function (i, line)
            self.infoLevel = Self.INFO_FULL

            -- Class restrictions
            if not self.classes then
                local classes = line:match(Self.PATTERN_CLASSES)
                if classes then
                    self.classes = Util.StrSplit(classes:gsub(", ", ","), ",")
                    return
                end
            end

            -- Spec restrictions
            if not self.spec then
                local spec = line:match(Self.PATTERN_SPEC)
                if spec and Util.In(spec, Unit.Specs()) then
                    self.spec = spec
                    return
                end
            end

            -- Ilvl (incl. upgrades)
            if not self.effectiveLevel then
                self.effectiveLevel = tonumber(select(2, line:match(Self.PATTERN_ILVL_SCALED)) or line:match(Self.PATTERN_ILVL))
                if self.effectiveLevel then return end
            end

            -- Heirloom min/max level
            if self.quality == LE_ITEM_QUALITY_HEIRLOOM and not (self.fromLevel and self.toLevel) then
                local from, to = line:match(Self.PATTERN_HEIRLOOM_LEVEL)
                if from and to then
                    self.fromLevel, self.toLevel = tonumber(from), tonumber(to)
                    return
                end
            end

            -- Relic type
            if self.isRelic and not self.relicType then
                self.relicType = line:match(Self.PATTERN_RELIC_TYPE)
                if self.relicType then return end
            end

            -- Primary attributes
            self.attributes = self.attributes or {}
            for i,attr in pairs(Self.ATTRIBUTES) do
                if not self.attributes[attr] then
                    local attrName = attr == LE_UNIT_STAT_STRENGTH and "STRENGTH" or attr == LE_UNIT_STAT_INTELLECT and "INTELLECT" or "AGILITY"
                    local match = line:match(Self["PATTERN_" .. attrName])
                    if match then
                        self.attributes[attr] = tonumber((match:gsub(",", ""):gsub("\\.", "")))
                        return
                    end
                end
            end

            -- Transmog appearance
            if not self.isRelic and Addon.db.profile.filter.transmog and self.isTransmogKnown == nil then
                if line:match(Self.PATTERN_APPEARANCE_KNOWN) or line:match(Self.PATTERN_APPEARANCE_UNKNOWN_ITEM) then
                    self.isTransmogKnown = true
                elseif line:match(Self.PATTERN_APPEARANCE_UNKNOWN) then
                    self.isTransmogKnown = false
                end
            end
        end, self.link)

        Util.TblRelease(specs)

        -- Effective and max level
        self.effectiveLevel = self.effectiveLevel or self.level
        self.maxLevel = self.quality == LE_ITEM_QUALITY_HEIRLOOM and Self.GetInfo(Self.GetScaledLink(self.link, self.toLevel), "level") or self.effectiveLevel

        -- Get item position in bags or equipment
        local bagOrEquip, slot = self:GetPosition()
        if bagOrEquip and slot ~= 0 then
            self:SetPosition(bagOrEquip, slot)
        end

        -- Check if the item is tradable
        self.isTradable, self.isSoulbound, self.bindTimeout = self:IsTradable()
    end

    return self, self.infoLevel >= Self.INFO_FULL
end

-------------------------------------------------------
--              Equipment location info              --
-------------------------------------------------------

-- Get the equipment location or relic type
function Self:GetLocation()
    return self:GetBasicInfo().isRelic and self:GetFullInfo().relicType or self.equipLoc
end

-- Determine if two items belong to the same location
function Self:IsSameLocation(item, weaponsSameLoc)
    local selfLoc = (type(self) == "table" or Self.IsLink(self)) and Self.GetInfo(self, "equipLoc") or self
    local itemLoc = (type(item) == "table" or Self.IsLink(item)) and Self.GetInfo(item, "equipLoc") or item

    -- Artifact relics (and maybe other things without equipLoc)
    if Util.StrIsEmpty(selfLoc) then
        return Util.StrIsEmpty(itemLoc)
    elseif Util.StrIsEmpty(itemLoc) then
        return false
    end

    local selfWeapon = Util.In(selfLoc, Self.TYPES_WEAPON)
    local itemWeapon = Util.In(itemLoc, Self.TYPES_WEAPON)

    -- Weapons and armor
    if selfWeapon ~= itemWeapon then
        return false
    elseif selfWeapon and weaponsSameLoc then
        return true
    elseif selfLoc == Self.TYPE_WEAPONMAINHAND then
        return not Util.In(selfLoc, Self.TYPE_WEAPONOFFHAND, Self.TYPE_HOLDABLE)
    elseif Util.In(selfLoc, Self.TYPE_WEAPONOFFHAND, Self.TYPE_HOLDABLE) then
        return itemLoc ~= Self.TYPE_WEAPONMAINHAND
    else
        return selfWeapon or Util.TblEquals(Self.SLOTS[selfLoc], Self.SLOTS[itemLoc])
    end
end

-- Get a list of owned items by equipment location
function Self.GetOwnedForLocation(loc, allWeapons)
    local items = Util.Tbl()
    local classId = Unit.ClassId("player")

    local isRelic
    if type(loc) == "table" then
        isRelic = loc:GetBasicInfo().isRelic
        loc = isRelic and loc:GetFullInfo().relicType or loc.equipLoc
    else
        isRelic = loc:sub(1, 7) ~= "INVTYPE"
    end

    -- Only works for equippable items
    if not isRelic and not Self.SLOTS[loc] then return end

    -- Get equipped item(s)
    if isRelic then
        local weapon = Self.GetEquippedArtifact()
        items = weapon and weapon:GetRelics(loc) or items
    else
        local slots = Self.SLOTS[allWeapons and Util.In(loc, Self.TYPES_WEAPON) and Self.TYPE_WEAPON or loc]
        for i,slot in pairs(slots) do
            local link = GetInventoryItemLink("player", slot)
            if link and not Self.IsLegionLegendary(link) and Self.IsSameLocation(link, loc, allWeapons) then
                tinsert(items, link)
            end
        end
    end

    -- Get item(s) from bag
    for bag=1,NUM_BAG_SLOTS do
        for slot=1, GetContainerNumSlots(bag) do
            local link = GetContainerItemLink(bag, slot)

            if link and Self.GetInfo(link, "isEquippable") then
                if isRelic then
                    if Self.GetInfo(link, "isRelic") then
                        -- It's a relic
                        if Self.GetInfo(link, "relicType") == loc then
                            tinsert(items, link)
                        end
                    elseif Self.GetInfo(link, "classId") == LE_ITEM_CLASS_WEAPON then
                        -- It might be an artifact weapon
                        local id = Self.GetInfo(link, "id")
                        for i,spec in pairs(Self.CLASSES[classId].specs) do
                            if id == spec.artifact.id and Addon.db.char.specs[i] then
                                for slot,relicType in pairs(spec.artifact.relics) do
                                    if relicType == loc then
                                        tinsert(items, (select(2, GetItemGem(link, slot))))
                                    end
                                end
                            end
                        end
                    end
                elseif not Self.IsLegionLegendary(link) and Self.IsSameLocation(link, loc, allWeapons) then
                    tinsert(items, link)
                end
            end
        end
    end

    Util.TblRelease(roles, attrs)

    return items
end

-- Get number of slots for a given equipment location
function Self:GetSlotCountForLocation()
    -- No point in doing this if we don't have the info yet
    _, success = self:GetBasicInfo()
    if not success then return 0 end

    if self.isRelic then
        self:GetFullInfo()
        local n, classId = 0, Unit.ClassId("player")

        for i,spec in pairs(Self.CLASSES[classId].specs) do
            if Addon.db.char.specs[i] then
                n = n + Util.TblCountOnly(spec.artifact.relics, self.relicType)
            end
        end
        return n
    elseif self.isEquippable then
        return #Self.SLOTS[self.equipLoc]
    else
        return 0
    end
end

-- Get the threshold for the item's slot
function Self:GetThresholdForLocation(unit, upper)
    local unit = Unit(unit or "player")
    local f = Addon.db.profile.filter

    -- Relics have a lower threshold of -1, meaning they have to be higher in ilvl to be worth considering
    if not upper and self:GetBasicInfo().isRelic then
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
function Self:GetLevelForLocation(unit)
    unit = Unit(unit or "player")
    local loc = self:GetLocation()

    if Unit.IsSelf(unit) then
        -- For the player
        if self:IsWeapon() then
            -- Weapons
            Self.UpdatePlayerCacheWeapons()

            local loc = Util.Select(loc, Self.TYPE_HOLDABLE, Self.TYPE_WEAPONOFFHAND, Self.TYPE_2HWEAPON, Self.TYPE_WEAPON, loc)
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
            local cache = Self.playerCache[loc] or {}
            if not cache.ilvl or not cache.time or cache.time + Inspect.REFRESH < GetTime() then
                local owned = self:GetOwnedForLocation()
                cache.time = GetTime()
                cache.ilvl = owned and Util(owned)
                    .Map(Self.GetInfo, false, "maxLevel")
                    .Sort(true)(self:GetSlotCountForLocation()) or 0
                Self.playerCache[loc] = cache
            end

            return cache.ilvl or 0
        end
    else
        -- For other players
        return Inspect.GetLevel(Unit.Name(unit), loc)
    end
end

-- Get equipped item links for the location
function Self:GetEquippedForLocation(unit)
    unit = Unit(unit or "player")
    local isSelf = Unit.IsSelf(unit)

    if self:GetBasicInfo().isRelic then
        return Inspect.GetLink(unit, self:GetFullInfo().relicType)
    elseif self.isEquippable then
        links = Util.Tbl()
        for i,slot in pairs(Self.SLOTS[self.equipLoc]) do
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
function Self:GetRelics(relicTypes)
    local id = self:GetBasicInfo().id

    for _,class in pairs(Self.CLASSES) do
        for i,spec in pairs(class.specs) do
            if spec.artifact.id == id then
                local relics = {}
                for slot,relicType in pairs(spec.artifact.relics) do
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

    for _,class in pairs(Self.CLASSES) do
        for i,spec in pairs(class.specs) do
            if spec.artifact.id == id then
                local relics = spec.artifact.relics

                -- Remove all relicTypes that occur in other weapons
                if unique then
                    relics = Util.TblCopy(relics)
                    for slot,relicType in pairs(relics) do
                        for i,spec in pairs(class.specs) do
                            if spec.artifact.id ~= id then
                                for _,otherRelicType in pairs(spec.artifact.relics) do
                                    if otherRelicType == relicType then
                                        relics[slot] = nil break
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
--                    Properties                     --
-------------------------------------------------------

-- Check the item quality
function Self:HasSufficientQuality(loot)
    local quality = Self.GetInfo(self, "quality")

    if not quality or quality >= LE_ITEM_QUALITY_LEGENDARY then
        return false
    elseif loot and Util.IsLegacyLoot() then
        return quality >= LE_ITEM_QUALITY_COMMON
    elseif IsInRaid() then
        return quality >= LE_ITEM_QUALITY_EPIC
    else
        return quality >= LE_ITEM_QUALITY_RARE
    end
end

-- Check if an item can be equipped
function Self:CanBeEquipped(unit, ...)
    -- Check if it's equippable
    if not self:GetBasicInfo().isEquippable then
        return false
    end
    
    self:GetFullInfo()

    unit = unit or "player"
    local className, _, classId = UnitClass(unit)
    local isSelf = Unit.IsSelf(unit)

    -- Check if there are class/spec restrictions
    if self.classes and not Util.In(className, self.classes) then
        return false
    elseif ... then
        local found = false
        for i,spec in Util.Each(...) do
            if not (self.spec and self.spec ~= select(2, GetSpecializationInfo(spec))) and
               not (self:IsLegionArtifact() and self.id ~= Self.CLASSES[classId].specs[spec].artifact.id) then
                found = true break
            end
        end
        if not found then return false end
    end

    -- Everyone can wear cloaks
    if self.classId == LE_ITEM_CLASS_ARMOR and self.equipLoc == Self.TYPE_CLOAK then
        return true
    end

    -- Check relic type
    if self.isRelic then
        for i,spec in pairs(Self.CLASSES[classId].specs) do
            if (not isSelf or Addon.db.char.specs[i]) and Util.In(self.relicType, spec.artifact.relics) then
                return true
            end
        end

        return false
    end

    -- Check if the armor/weapon type can be equipped
    if Util.In(self.classId, LE_ITEM_CLASS_ARMOR, LE_ITEM_CLASS_WEAPON) then
        return Util.In(self.subClassId, Self.CLASSES[classId][self.classId == LE_ITEM_CLASS_ARMOR and "armor" or "weapons"])
    else
        return false
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

        for i,info in pairs(Self.CLASSES[classId].specs) do
            if not isSelf or Util.Check(..., Util.In(i, ...), true) then
                if self.attributes[info.attribute] then return true end
            end
        end
    end
    
    return false
end

-- Check against equipped ilvl
function Self:HasSufficientLevel(unit)
    return self:GetRealLevel() + self:GetThresholdForLocation(unit) >= self:GetLevelForLocation(unit)
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
            for i,spec in pairs(Self.CLASSES[Unit.ClassId(unit)].specs) do
                if  (not ... or Util.In(i, ...))
                    and (bit.band(cat, Self.MASK_ATTR) == 0 or bit.band(cat, spec.attribute) > 0)
                    and (bit.band(cat, Self.MASK_ROLE) == 0 or bit.band(cat, spec.role) > 0) then
                    return true
                end
            end
            return false
        end
    elseif not self:CanBeEquipped(unit, ...) or not self:HasMatchingAttributes(unit, ...) then
        return false
    elseif self:IsWeapon() and ... then
        for i,v in Util.Each(...) do
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
    if unit and not Unit.IsSelf(unit) or not (IsAddOnLoaded("Pawn") and PawnGetItemData and PawnIsItemAnUpgrade and PawnCommon and PawnCommon.Scales) then
        return false
    else
        local data = PawnGetItemData(self.link)
        if data then
            for i,scale in pairs(PawnIsItemAnUpgrade(data) or Util.TBL_EMPTY) do
                if not ... or Util.In(PawnCommon.Scales[scale.ScaleName].specID, ...) then
                    return true
                end
            end
        end
    end
end

-- Check if we need the transmog appearance
function Self:IsTransmogMissing(unit)
    return (not unit or Unit.IsSelf(unit)) and self:GetFullInfo().isTransmogKnown == false
end

-- Register an eligible unit's interest
function Self:SetEligible(unit)
    self:GetEligible()
    self.eligible[Unit.Name(unit)] = true
end

-- Check who in the group could use the item
function Self:GetEligible(unit)
    if not self.eligible then
        if unit then
            if not self.isSoulbound and Addon.db.profile.filter.transmog and self:IsTransmogMissing(unit) then
                return true
            elseif not self:CanBeEquipped(unit) then
                return nil
            elseif not self:HasSufficientLevel(unit) then
                return false
            elseif Addon.db.profile.filter.transmog and self:IsTransmogMissing(unit) then
                return true
            else
                local isSelf = Unit.IsSelf(unit)
                local specs = isSelf and Util(Addon.db.char.specs).CopyOnly(true, true).Keys()() or nil
                local isUseful = self:IsUseful(unit, specs)

                if isUseful and isSelf and Addon.db.profile.filter.pawn and IsAddOnLoaded("Pawn") then
                    isUseful = self:IsPawnUpgrade(unit, specs)
                end

                return isUseful or false, Util.TblRelease(specs)
            end
        else
            local eligible = Util.Tbl()
            for i=1,GetNumGroupMembers() do
                local unit = GetRaidRosterInfo(i)
                if unit then
                    eligible[unit] = self:GetEligible(unit)
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
function Self:GetNumEligible(checkIlvl, othersOnly)
    local n = 0
    for unit,v in pairs(self:GetEligible()) do
        n = n + ((not checkIlvl or v) and not (othersOnly and Unit.IsSelf(unit)) and 1 or 0)
    end
    return n
end

-------------------------------------------------------
--                     Decisions                     --
-------------------------------------------------------

-- Check if a looted item should be checked further
function Self:ShouldBeChecked(owner)
    owner = owner or type(self) == "table" and self.owner
    local item = type(self) == "table" and self.link or self
    return item and owner and not (Addon.db.profile.dontShare and not Unit.IsSelf(owner)) and IsEquippableItem(item) and Self.HasSufficientQuality(item, true)
end

-- Check if the item should be handled by the addon
function Self:ShouldBeConsidered()
    return self:HasSufficientQuality() and self:GetBasicInfo().isEquippable and self:GetFullInfo().isTradable
end

-- Check if the addon should offer to bid on an item
function Self:ShouldBeBidOn()
    return not Addon.db.profile.dontShare and self:ShouldBeConsidered() and self:GetEligible("player")
end

-- Check if the addon should start a roll for an item
function Self:ShouldBeRolledFor()
    return not (self.isOwner and Addon.db.profile.dontShare) and self:ShouldBeConsidered() and self:GetNumEligible(true, true) > 0
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
    local args, try = {...}
    try = function (n)
        if self:IsLoaded() then
            fn(unpack(args))
        elseif n > 0 then
            Addon:ScheduleTimer(try, 0.1, n-1)
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
        local entry, try = {fn = fn, args = {...}}
        try = function (n)
            local i = Util.TblFind(Self.queue, entry)
            if i then
                if self:IsFullyLoaded(n >= 5) then
                    tremove(Self.queue, i)
                    fn(unpack(entry.args))
                elseif n > 0 then
                    entry.timer = Addon:ScheduleTimer(try, 0.1, n-1)
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
            -- Check for azerite gear (will be tradable after build 27404)
            if tonumber((select(2, GetBuildInfo()))) <= 27404 and self:IsAzeriteGear() then
                return false, true, false
            end

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

    Util.ScanTooltip(function (i, line)
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
function Self:GetPosition(refresh)
    if not self.isOwner or not refresh and self.bagOrEquip and self.slot ~= 0 then
        return self.bagOrEquip, self.slot, self.isTradable
    end

    -- Check bags
    local bag, slot, isTradable
    for b = self.slot == 0 and self.bagOrEquip or 0, self.slot == 0 and self.bagOrEquip or NUM_BAG_SLOTS do
        for s=1,GetContainerNumSlots(b) do
            local link = GetContainerItemLink(b, s)
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
    if select(2, self:GetBasicInfo()) and not self.isRelic then
        for _, equipSlot in pairs(Self.SLOTS[self.equipLoc]) do
            if self.link == GetInventoryItemLink(self.owner, equipSlot) then
                return equipSlot, nil, false
            end
        end
    end
end

-- Set the item's position
function Self:SetPosition(bagOrEquip, slot)
    if type(bagOrEquip) == "table" then
        bagOrEquip, slot = unpack(bagOrEquip)
    end

    self.bagOrEquip = bagOrEquip
    self.slot = slot
    self.position = {bagOrEquip, slot}

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
function Self.GetPlayerCache(loc, spec)
    return Self.playerCache[spec and loc .. spec or loc]
end

-- Set an entry ont he player level cache
function Self.SetPlayerCache(loc, specOrCache, cache)
    cache = cache or specOrCache
    spec = cache and specOrCache
    Self.playerCache[spec and loc .. spec or loc] = cache
end

-- Update cache for all weapons that are useful to the player
function Self.UpdatePlayerCacheWeapons()
    local specs = Self.CLASSES[Unit.ClassId("player")].specs
    local owned

    for spec,info in pairs(specs) do
        for _,loc in pairs(info.weapons or Self.TYPES_WEAPON) do
            local loc = Util.Select(loc, Self.TYPE_HOLDABLE, Self.TYPE_WEAPONOFFHAND, Self.TYPE_2HWEAPON, Self.TYPE_WEAPON, loc)
            local key = loc .. spec
            local cache = Self.GetPlayerCache(loc, spec) or Util.Tbl()

            if not Self.IsPlayerCacheValid(cache) then
                -- Find another applicable and valid cache entry
                local found = false
                for i,info2 in pairs(specs) do
                    local cache2 = Self.GetPlayerCache(loc, i)
                    if info.attribute == info2.attribute and info.weapons == info2.weapons and Self.IsPlayerCacheValid(cache2) and not cache2.spec then
                        Util.TblMerge(cache, cache2)
                        found = true break
                    end
                end

                -- Create a new cache entry
                if not found then
                    cache.time = GetTime()
                    owned = owned or Self.GetOwnedForLocation(loc, true)
                    local main, off, both1, both2, twohand = 0, 0, 0, 0, 0

                    -- Go through all owned weapons and find highest ilvl for each type
                    for i,item in pairs(owned) do
                        owned[i] = Self.FromLink(item, "player"):GetBasicInfo()
                        item = owned[i]

                        if item:IsWeapon() then
                            cache.spec = cache.spec or item:GetFullInfo().spec ~= nil

                            if item:IsUseful("player", spec) then
                                if item.equipLoc == Self.TYPE_2HWEAPON or item:IsLegionArtifact() then
                                    twohand = max(twohand, item.maxLevel)
                                elseif item.equipLoc == Self.TYPE_WEAPONMAINHAND then
                                    main = max(main, item.maxLevel)
                                elseif Util.In(item.equipLoc, Self.TYPE_WEAPONOFFHAND, Self.TYPE_HOLDABLE) then
                                    off = max(off, item.maxLevel)
                                else
                                    both1, both2 = max(both1, both2, item.maxLevel), min(both1, max(both2, item.maxLevel))
                                end
                            end
                        end
                    end

                    -- Determine max ilvl for covering all the weapon's slots
                    if loc == Self.TYPE_WEAPONMAINHAND then
                        cache.ilvl = max(main, both1, twohand)
                    elseif loc == Self.TYPE_WEAPONOFFHAND then
                        cache.ilvl = max(off, both1, twohand)
                    else
                        cache.ilvl = max(min(main, off), min(main, both1), min(both1, off), both2, twohand)
                    end
                end

                Self.SetPlayerCache(loc, spec, cache)
            end
        end
    end

    Util.TblRelease(true, owned)
end

-- Check if a player cache entry is still valid
function Self.IsPlayerCacheValid(cache)
    local cache = Util.Check(type(cache) == "string", Self.playerCache[key], cache)
    return cache and cache.ilvl and cache.time and cache.time + Inspect.REFRESH < GetTime()
end

-------------------------------------------------------
--                       Helper                      --
-------------------------------------------------------

-- Get the real (unscaled) item level
function Self:GetRealLevel()
    return Self.IsScalingActive(self.owner) and self:GetFullInfo().effectiveLevel or self:GetBasicInfo().level
end

-- Check if the item should get special treatment for being a weapon
function Self:IsWeapon()
    return Util.In(self:GetBasicInfo().equipLoc, Self.TYPES_WEAPON)
end

-- Check if the item is a Legion legendary
function Self:IsLegionLegendary()
    return Self.GetInfo(self, "expacId") == Self.EXPAC_LEGION and Self.GetInfo(self, "quality") == LE_ITEM_QUALITY_LEGENDARY
end

-- Check if the item is a Legion artifact
function Self:IsLegionArtifact()
    return Self.GetInfo(self, "expacId") == Self.EXPAC_LEGION and Self.GetInfo(self, "quality") == LE_ITEM_QUALITY_ARTIFACT
end

-- Check if the item has azerite traits
function Self:IsAzeriteGear()
    return self:GetBasicInfo().expacId == Self.EXPAC_BFA and self.quality >= LE_ITEM_QUALITY_RARE and Util.In(self.equipLoc, Self.TYPE_HEAD, Self.TYPE_SHOULDER, Self.TYPE_CHEST, Self.TYPE_ROBE)
end

-------------------------------------------------------
--                      Events                       --
-------------------------------------------------------

-- An item as been moved
function Self.OnMove(from, to)
    for i,roll in pairs(Addon.rolls) do
        if roll.item.isOwner and not roll.traded then
            if Util.TblEquals(from, roll.item.position) then
                roll.item:SetPosition(to)
                return true
            end
        end
    end
end

-- Two items have switched places
function Self.OnSwitch(pos1, pos2)
    local item1, item2
    for i,roll in pairs(Addon.rolls) do
        if not item1 and Util.TblEquals(pos1, roll.item.position) then
            item1 = roll.item
        elseif not item2 and Util.TblEquals(pos2, roll.item.position) then
            item2 = roll.item
        end
        if item1 and item2 then
            break
        end
    end

    if item1 then item1:SetPosition(pos2) end
    if item2 then item2:SetPosition(pos1) end
end