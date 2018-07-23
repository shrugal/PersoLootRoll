local Name, Addon = ...
local Inspect, Unit, Util = Addon.Inspect, Addon.Unit, Addon.Util
local Self = Addon.Item

-------------------------------------------------------
--                     Constants                     --
-------------------------------------------------------

-- Item level threshold
Self.ILVL_THRESHOLD = 30

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
        -- expacId = 15,
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
Self.playerSlotLevels = {}

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
function Self.GetLink(str, translate)
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
    local link = item.link or item

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
function Self.FromLink(item, owner, bagOrEquip, slot)
    if type(item) == "string" then
        owner = owner and Unit.Name(owner) or nil
        item = {
            link = item,
            owner = owner,
            isOwner = owner and UnitIsUnit(owner, "player"),
            infoLevel = Self.INFO_NONE,
            isTradable = not owner or nil
        }
        setmetatable(item, {__index = Self})
        item:SetPosition(bagOrEquip, slot)
    end

    return item
end

-- Create an item instance for the given equipment slot
function Self.FromSlot(slot, unit)
    unit = unit or "player"
    local link = GetInventoryItemLink(unit, slot)
    if link then
        return Self.FromLink(link, unit, slot)
    end
end

-- Create an item instance from the given bag position
function Self.FromBagSlot(bag, slot)
    local link = GetContainerItemLink(bag, slot)
    if link then
        return Self.FromLink(link, "player", bag, slot)
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
                    return Self.FromSlot(slot, unit)
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
                    self.classes = Util.StrSplit(classes, ", ")
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
            if not self.isRelic and Addon.db.profile.transmog and self.isTransmogKnown == nil then
                if line:match(Self.PATTERN_APPEARANCE_KNOWN) or line:match(Self.PATTERN_APPEARANCE_UNKNOWN_ITEM) then
                    self.isTransmogKnown = true
                elseif line:match(Self.PATTERN_APPEARANCE_UNKNOWN) then
                    self.isTransmogKnown = false
                end
            end
        end, self.link)

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

-- Determine if two items belong to the same location
function Self:IsSameLocation(item)
    local selfLoc = Self.GetInfo(self, "equipLoc")
    local itemLoc = Self.GetInfo(item, "equipLoc")

    -- Artifact relics (and maybe other things without equipLoc)
    if Util.StrIsEmpty(selfLoc) then
        return Util.StrIsEmpty(itemLoc)
    elseif Util.StrIsEmpty(itemLoc) then
        return false
    end

    local selfWeapon = Util.In(selfLoc, Self.TYPE_WEAPONS)
    local itemWeapon = Util.In(itemLoc, Self.TYPE_WEAPONS)

    -- Weapons and armor
    if selfWeapon ~= itemWeapon then
        return false
    elseif not selfWeapon then
        return Util.TblEquals(Self.SLOTS[selfLoc], Self.SLOTS[itemLoc])
    elseif selfLoc == Self.TYPE_WEAPONMAINHAND then
        return not Util.In(selfLoc, Self.TYPE_WEAPONOFFHAND, Self.TYPE_HOLDABLE)
    elseif Util.In(selfLoc, Self.TYPE_WEAPONOFFHAND, Self.TYPE_HOLDABLE) then
        return itemLoc ~= Self.TYPE_WEAPONMAINHAND
    else
        return true
    end
end

-- Get a list of owned items by equipment location
function Self:GetOwnedForLocation(equipped, bag)
    local items = Util.Tbl()
    local classId = Unit.ClassId("player")

    -- We need to scan more slots for weapons
    local slots = Self.SLOTS[self:IsWeapon() and Self.TYPE_WEAPON or self.equipLoc]

    -- We will need the relic type for relics
    if self.isRelic then
        self:GetFullInfo()
    end

    -- Get equipped item(s)
    if self.isEquippable and equipped ~= false then
        if self.isRelic then
            local weapon = Self.GetEquippedArtifact()
            items = weapon and weapon:GetRelics(self.relicType) or items
        else
            for i,slot in pairs(slots) do
                local link = GetInventoryItemLink("player", slot)
                if link and Self.GetInfo(link, "quality") ~= LE_ITEM_QUALITY_LEGENDARY and self:IsSameLocation(link) then
                    tinsert(items, link)
                end
            end
        end
    end

    -- Get item(s) from bag
    if bag ~= false then
        for bag=1,NUM_BAG_SLOTS do
            for slot=1, GetContainerNumSlots(bag) do
                local link = GetContainerItemLink(bag, slot)

                if link and Self.GetInfo(link, "isEquippable") then
                    if self.isRelic then
                        if Self.GetInfo(link, "isRelic") then
                            -- It's a relic
                            if Self.GetInfo(link, "relicType") == self.relicType then
                                tinsert(items, link)
                            end
                        elseif Self.GetInfo(link, "classId") == LE_ITEM_CLASS_WEAPON then
                            -- It might be an artifact weapon
                            local id = Self.GetInfo(link, "id")
                            for i,spec in pairs(Self.CLASSES[classId].specs) do
                                if id == spec.artifact.id and Addon.db.char.specs[i] then
                                    for slot,relicType in pairs(spec.artifact.relics) do
                                        if relicType == self.relicType then
                                            tinsert(items, (select(2, GetItemGem(link, slot))))
                                        end
                                    end
                                end
                            end
                        end
                    elseif Self.GetInfo(link, "quality") ~= LE_ITEM_QUALITY_LEGENDARY and self:IsSameLocation(link) then
                        tinsert(items, link)
                    end
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

    -- Relics have a lower threshold of -1, meaning they have to be higher in ilvl to be worth considering
    if not upper and self:GetBasicInfo().isRelic then
        return -1
    end

    -- Use DB option only for the player and only for the lower threshold
    local applyCustomThresholds = not upper and Unit.IsSelf(unit)
    local threshold = applyCustomThresholds and Addon.db.profile.ilvlThreshold or Self.ILVL_THRESHOLD

    -- Scale threshold for lower level chars
    local level = UnitLevel(unit)
    threshold = ceil(threshold * (level and level > 0 and level / MAX_PLAYER_LEVEL or 1))

    -- Trinkets have double the normal threshold
    if (not applyCustomThresholds or Addon.db.profile.ilvlThresholdTrinkets) and self:GetBasicInfo().equipLoc == Self.TYPE_TRINKET then
        threshold = threshold * 2
    end

    return threshold
end

-- Get the reference level for equipment location
function Self:GetLevelForLocation(unit)
    unit = Unit(unit or "player")
    local loc = self:GetBasicInfo().isRelic and self:GetFullInfo().relicType or self.equipLoc

    if Unit.IsSelf(unit) then
        -- For the player
        if self:IsWeapon() then
            -- Weapons
            local loc = Util.Select(loc, Self.TYPE_HOLDABLE, Self.TYPE_WEAPONOFFHAND, Self.TYPE_2HWEAPON, Self.TYPE_WEAPON, loc)
            local specs = Self.CLASSES[Unit.ClassId(unit)].specs
            local owned, slotMin

            -- Find the min owned itemlvl for all usable attributes the weapon has
            for attr in pairs(self:GetFullInfo().attributes) do
                if Util.TblFindWhere(specs, "attribute", attr) then
                    local cache = Self.playerSlotLevels[loc .. attr] or {}
                    if not cache.ilvl or not cache.time or cache.time + Inspect.REFRESH < GetTime() then
                        cache.time = GetTime()
                        owned = owned or self:GetOwnedForLocation()
                        local main, off, both1, both2, twohand = 0, 0, 0, 0, 0

                        for i,item in pairs(owned) do
                            owned[i] = Self.FromLink(item, "player"):GetBasicInfo()
                            item = owned[i]

                            if item:IsWeapon() and item:GetFullInfo().attributes[attr] then
                                if item.equipLoc == Self.TYPE_WEAPONMAINHAND then
                                    main = max(main, item.level)
                                elseif Util.In(item.equipLoc, Self.TYPE_WEAPONOFFHAND, Self.TYPE_HOLDABLE) then
                                    off = max(off, item.level)
                                elseif item.equipLoc == Self.TYPE_2HWEAPON then
                                    twohand = max(twohand, item.level)
                                else
                                    both1, both2 = max(both1, both2, item.level), min(both1, max(both2, item.level))
                                end
                            end
                        end

                        if loc == Self.TYPE_WEAPONMAINHAND then
                            cache.ilvl = max(main, both1, twohand)
                        elseif loc == Self.TYPE_WEAPONOFFHAND then
                            cache.ilvl = max(off, both1, twohand)
                        else
                            cache.ilvl = max(min(main, off), min(main, both1), min(both1, off), both2, twohand)
                        end

                        Self.playerSlotLevels[loc .. attr] = cache
                    end

                    slotMin = min(slotMin or cache.ilvl, cache.ilvl)
                end
            end

            Util.TblRelease(true, owned)

            return slotMin or 0
        else
            -- Everything else
            local cache = Self.playerSlotLevels[loc] or {}
            if not cache.ilvl or not cache.time or cache.time + Inspect.REFRESH < GetTime() then
                cache.time = GetTime()
                cache.ilvl = Util(self:GetOwnedForLocation())
                    .Map(Self.GetInfo, false, "maxLevel")
                    .Sort(true)(self:GetSlotCountForLocation())
                Self.playerSlotLevels[loc] = cache
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
function Self:HasSufficientQuality()
    local quality = Self.GetInfo(self, "quality")
    local threshold = IsInRaid() and not Addon.db.profile.transmog and LE_ITEM_QUALITY_EPIC or LE_ITEM_QUALITY_RARE

    return quality and quality >= threshold and quality < LE_ITEM_QUALITY_LEGENDARY
end

-- Check if an item can be equipped
function Self:CanBeEquipped(unit)
    -- Check if it's equippable
    if not self:GetBasicInfo().isEquippable then
        return false
    end
    
    self:GetFullInfo()

    unit = unit or "player"
    local className, _, classId = UnitClass(unit)
    local isSelf = Unit.IsSelf(unit)

    -- Check if there are class restrictions
    if self.classes and not Util.In(className, self.classes) then
        return false
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
function Self:HasMatchingAttributes(unit)
    unit = unit or "player"
    local isSelf, classId = Unit.IsSelf(unit), Unit.ClassId(unit)

    self:GetFullInfo()

    -- Item has no primary attributes
    if not self.attributes or not next(self.attributes) then
        return true
    -- Check if item has a primary attribute that the class can use
    else
        for i,spec in pairs(Self.CLASSES[classId].specs) do
            if not isSelf or Addon.db.char.specs[i] then
                for attr,_ in pairs(self.attributes) do
                    if attr == spec.attribute then
                        return true
                    end
                end
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
function Self:IsUseful(unit)
    unit = unit or "player"

    if not (self:CanBeEquipped(unit) and self:HasMatchingAttributes(unit)) then
        return false
    elseif self:GetBasicInfo().equipLoc == Self.TYPE_TRINKET then
        if not Util.TblFindWhere(Self.TRINKETS, self.id) then
            return true
        else
            local isSelf, classId = Unit.IsSelf(unit), Unit.ClassId(unit)
            for i,spec in pairs(Self.CLASSES[classId].specs) do
                if (not isSelf or Addon.db.char.specs[i]) then
                    if Self.TRINKETS[spec.attribute][self.id] or Self.TRINKETS[spec.role] and Self.TRINKETS[spec.role][self.id] then
                        return true
                    end
                end
            end
            return false
        end
    else
        return true
    end
end

-- Check if we need the transmog appearance
function Self:IsTransmogNeeded(unit)
    return (not unit or Unit.IsSelf(unit)) and Addon.db.profile.transmog and self:GetFullInfo().isTransmogKnown == false
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
            if not self:CanBeEquipped(unit) then
                return nil
            else
                return self:IsTransmogNeeded(unit) or self:IsUseful(unit) and self:HasSufficientLevel(unit)
            end
        else
            local eligible = {}
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
function Self:GetNumEligible(checkIlvl)
    return checkIlvl and Util.TblCountOnly(self:GetEligible(), true) or Util.TblCount(self:GetEligible())
end

-------------------------------------------------------
--                     Decisions                     --
-------------------------------------------------------

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
    return not (self.isOwner and Addon.db.profile.dontShare) and self:ShouldBeConsidered() and self:GetNumEligible(true) > (self:GetEligible(self.owner) and 1 or 0)
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
--                       Helper                      --
-------------------------------------------------------

-- Get the real (unscaled) item level
function Self:GetRealLevel()
    return Self.IsScalingActive(self.owner) and self:GetFullInfo().effectiveLevel or self:GetBasicInfo().level
end

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

-- Get the equipment location or relic type
function Self:GetLocation()
    return self:GetBasicInfo().isRelic and self:GetFullInfo().relicType or self.equipLoc
end

function Self:IsWeapon()
    return Util.In(Self.GetInfo(self, "equipLoc"), Self.TYPE_WEAPONS)
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