local Name, Addon = ...
local Inspect = Addon.Inspect
local Unit = Addon.Unit
local Util = Addon.Util
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
Self.PATTERN_RELIC_TYPE = RELIC_TOOLTIP_TYPE:gsub("%%s", "(.+)")
Self.PATTERN_CLASSES = ITEM_CLASSES_ALLOWED:gsub("%%s", "(.+)")
Self.PATTERN_STRENGTH = ITEM_MOD_STRENGTH:gsub("%%c", "%%p"):gsub("%%s", "(%%d+)")
Self.PATTERN_INTELLECT = ITEM_MOD_INTELLECT:gsub("%%c", "%%p"):gsub("%%s", "(%%d+)")
Self.PATTERN_AGILITY = ITEM_MOD_AGILITY:gsub("%%c", "%%p"):gsub("%%s", "(%%d+)")
Self.PATTERN_SOULBOUND = ITEM_SOULBOUND
Self.PATTERN_TRADE_TIME_REMAINING = BIND_TRADE_TIME_REMAINING:gsub("%%s", ".+")

-- Item loading status
Self.INFO_NONE = 0
Self.INFO_LINK = 1
Self.INFO_BASIC = 2
Self.INFO_FULL = 3

-- Primary stats
Self.ATTRIBUTES = {ITEM_MOD_STRENGTH_SHORT, ITEM_MOD_INTELLECT_SHORT, ITEM_MOD_AGILITY_SHORT}

-- What primary attributes classes use
Self.CLASS_ATTRIBUTES = {
    [ITEM_MOD_STRENGTH_SHORT] = {Unit.DEATH_KNIGHT, Unit.PALADIN, Unit.WARRIOR},
    [ITEM_MOD_INTELLECT_SHORT] = {Unit.DRUID, Unit.MAGE, Unit.MONK, Unit.PALADIN, Unit.PRIEST, Unit.SHAMAN, Unit.WARLOCK},
    [ITEM_MOD_AGILITY_SHORT] = {Unit.DEMON_HUNTER, Unit.DRUID, Unit.HUNTER, Unit.MONK, Unit.ROGUE, Unit.SHAMAN}
}

-- What gear classes can equip
Self.CLASS_GEAR = {
    [LE_ITEM_CLASS_ARMOR] = {
        [LE_ITEM_ARMOR_GENERIC] = true,
        [LE_ITEM_ARMOR_CLOTH] = {Unit.MAGE, Unit.PRIEST, Unit.WARLOCK},
        [LE_ITEM_ARMOR_LEATHER] = {Unit.DEMON_HUNTER, Unit.DRUID, Unit.MONK, Unit.ROGUE},
        [LE_ITEM_ARMOR_MAIL] = {Unit.HUNTER, Unit.SHAMAN},
        [LE_ITEM_ARMOR_PLATE] = {Unit.DEATH_KNIGHT, Unit.PALADIN, Unit.WARRIOR},
        [LE_ITEM_ARMOR_SHIELD] = {Unit.PALADIN, Unit.SHAMAN, Unit.WARRIOR}
    },
    [LE_ITEM_CLASS_WEAPON] = {
        [LE_ITEM_WEAPON_AXE1H] = {Unit.DEATH_KNIGHT, Unit.DEMON_HUNTER, Unit.HUNTER, Unit.MONK, Unit.PALADIN, Unit.ROGUE, Unit.SHAMAN, Unit.WARRIOR},
        [LE_ITEM_WEAPON_MACE1H] = {Unit.DEATH_KNIGHT, Unit.DRUID, Unit.MONK, Unit.PALADIN, Unit.PRIEST, Unit.ROGUE, Unit.SHAMAN, Unit.WARRIOR},
        [LE_ITEM_WEAPON_SWORD1H] = {Unit.DEATH_KNIGHT, Unit.DEMON_HUNTER, Unit.HUNTER, Unit.MAGE, Unit.MONK, Unit.PALADIN, Unit.ROGUE, Unit.WARLOCK, Unit.WARRIOR},
        [LE_ITEM_WEAPON_WARGLAIVE] = {Unit.DEMON_HUNTER},
        [LE_ITEM_WEAPON_DAGGER] = {Unit.DEMON_HUNTER, Unit.DRUID, Unit.HUNTER, Unit.MAGE, Unit.PRIEST, Unit.ROGUE, Unit.SHAMAN, Unit.WARLOCK, Unit.WARRIOR},
        [LE_ITEM_WEAPON_UNARMED] = {Unit.DEMON_HUNTER, Unit.DRUID, Unit.HUNTER, Unit.MONK, Unit.ROGUE, Unit.SHAMAN, Unit.WARRIOR},
        [LE_ITEM_WEAPON_WAND] = {Unit.MAGE, Unit.PRIEST, Unit.WARLOCK},
        [LE_ITEM_WEAPON_AXE2H] = {Unit.DEATH_KNIGHT, Unit.PALADIN, Unit.SHAMAN, Unit.WARRIOR},
        [LE_ITEM_WEAPON_MACE2H] = {Unit.DEATH_KNIGHT, Unit.PALADIN, Unit.SHAMAN, Unit.WARRIOR},
        [LE_ITEM_WEAPON_SWORD2H] = {Unit.DEATH_KNIGHT, Unit.PALADIN, Unit.WARRIOR},
        [LE_ITEM_WEAPON_POLEARM] = {Unit.DEATH_KNIGHT, Unit.DRUID, Unit.HUNTER, Unit.MONK, Unit.PALADIN, Unit.WARRIOR},
        [LE_ITEM_WEAPON_STAFF] = {Unit.DRUID, Unit.HUNTER, Unit.MAGE, Unit.MONK, Unit.PRIEST, Unit.SHAMAN, Unit.WARLOCK, Unit.WARRIOR},
        [LE_ITEM_WEAPON_BOWS] = {Unit.HUNTER, Unit.WARRIOR},
        [LE_ITEM_WEAPON_CROSSBOW] = {Unit.HUNTER, Unit.WARRIOR},
        [LE_ITEM_WEAPON_GUNS] = {Unit.HUNTER, Unit.WARRIOR},
        [LE_ITEM_WEAPON_THROWN] = {Unit.ROGUE, Unit.WARRIOR}
    }
}

-- Artifact relic slots
Self.CLASS_RELICS = {
    [Unit.DEATH_KNIGHT] = {
        [128402] = {RELIC_SLOT_TYPE_BLOOD, RELIC_SLOT_TYPE_SHADOW, RELIC_SLOT_TYPE_IRON}, -- Blood
        [128292] = {RELIC_SLOT_TYPE_FROST, RELIC_SLOT_TYPE_SHADOW, RELIC_SLOT_TYPE_FROST}, -- Frost
        [128403] = {RELIC_SLOT_TYPE_FIRE, RELIC_SLOT_TYPE_SHADOW, RELIC_SLOT_TYPE_BLOOD}, -- Unholy
    },
    [Unit.DEMON_HUNTER] = {
        [127829] = {RELIC_SLOT_TYPE_FEL, RELIC_SLOT_TYPE_SHADOW, RELIC_SLOT_TYPE_FEL}, -- Havoc
        [128832] = {RELIC_SLOT_TYPE_IRON, RELIC_SLOT_TYPE_ARCANE, RELIC_SLOT_TYPE_FEL}, -- Vengeance
    },
    [Unit.DRUID] = {
        [128858] = {RELIC_SLOT_TYPE_ARCANE, RELIC_SLOT_TYPE_LIFE, RELIC_SLOT_TYPE_ARCANE}, -- Balance
        [128860] = {RELIC_SLOT_TYPE_FROST, RELIC_SLOT_TYPE_BLOOD, RELIC_SLOT_TYPE_LIFE}, -- Feral
        [128821] = {RELIC_SLOT_TYPE_FIRE, RELIC_SLOT_TYPE_BLOOD, RELIC_SLOT_TYPE_LIFE}, -- Guardian
        [128306] = {RELIC_SLOT_TYPE_LIFE, RELIC_SLOT_TYPE_FROST, RELIC_SLOT_TYPE_LIFE}, -- Restoration
    },
    [Unit.HUNTER] = {
        [128861] = {RELIC_SLOT_TYPE_WIND, RELIC_SLOT_TYPE_ARCANE, RELIC_SLOT_TYPE_IRON}, -- Beast Mastery
        [128826] = {RELIC_SLOT_TYPE_WIND, RELIC_SLOT_TYPE_BLOOD, RELIC_SLOT_TYPE_LIFE}, -- Marksmanship
        [128808] = {RELIC_SLOT_TYPE_WIND, RELIC_SLOT_TYPE_IRON, RELIC_SLOT_TYPE_BLOOD}, -- Survival
    },
    [Unit.MAGE] = {
        [127857] = {RELIC_SLOT_TYPE_ARCANE, RELIC_SLOT_TYPE_FROST, RELIC_SLOT_TYPE_ARCANE}, -- Arcane
        [128820] = {RELIC_SLOT_TYPE_FIRE, RELIC_SLOT_TYPE_ARCANE, RELIC_SLOT_TYPE_FIRE}, -- Fire
        [128862] = {RELIC_SLOT_TYPE_FROST, RELIC_SLOT_TYPE_ARCANE, RELIC_SLOT_TYPE_FROST}, -- Frost
    },
    [Unit.MONK] = {
        [128938] = {RELIC_SLOT_TYPE_LIFE, RELIC_SLOT_TYPE_WIND, RELIC_SLOT_TYPE_IRON}, -- Brewmaster
        [128937] = {RELIC_SLOT_TYPE_FROST, RELIC_SLOT_TYPE_LIFE, RELIC_SLOT_TYPE_WIND}, -- Mistweaver
        [128940] = {RELIC_SLOT_TYPE_WIND, RELIC_SLOT_TYPE_IRON, RELIC_SLOT_TYPE_WIND}, -- Windwalker
    },
    [Unit.PALADIN] = {
        [128823] = {RELIC_SLOT_TYPE_HOLY, RELIC_SLOT_TYPE_LIFE, RELIC_SLOT_TYPE_HOLY}, -- Holy
        [128866] = {RELIC_SLOT_TYPE_HOLY, RELIC_SLOT_TYPE_IRON, RELIC_SLOT_TYPE_ARCANE}, -- Protection
        [120978] = {RELIC_SLOT_TYPE_HOLY, RELIC_SLOT_TYPE_FIRE, RELIC_SLOT_TYPE_HOLY}, -- Retribution
    },
    [Unit.PRIEST] = {
        [128868] = {RELIC_SLOT_TYPE_HOLY, RELIC_SLOT_TYPE_SHADOW, RELIC_SLOT_TYPE_HOLY}, -- Discipline
        [128825] = {RELIC_SLOT_TYPE_HOLY, RELIC_SLOT_TYPE_LIFE, RELIC_SLOT_TYPE_HOLY}, -- Holy
        [128827] = {RELIC_SLOT_TYPE_SHADOW, RELIC_SLOT_TYPE_BLOOD, RELIC_SLOT_TYPE_SHADOW}, -- Shadow
    },
    [Unit.ROGUE] = {
        [128870] = {RELIC_SLOT_TYPE_SHADOW, RELIC_SLOT_TYPE_IRON, RELIC_SLOT_TYPE_BLOOD}, -- Assassination
        [128872] = {RELIC_SLOT_TYPE_BLOOD, RELIC_SLOT_TYPE_IRON, RELIC_SLOT_TYPE_WIND}, -- Outlaw
        [128476] = {RELIC_SLOT_TYPE_FEL, RELIC_SLOT_TYPE_SHADOW, RELIC_SLOT_TYPE_FEL}, -- Subtlety
    },
    [Unit.SHAMAN] = {
        [128935] = {RELIC_SLOT_TYPE_WIND, RELIC_SLOT_TYPE_FROST, RELIC_SLOT_TYPE_WIND}, -- Elemental
        [128819] = {RELIC_SLOT_TYPE_FIRE, RELIC_SLOT_TYPE_IRON, RELIC_SLOT_TYPE_WIND}, -- Enhancement
        [128911] = {RELIC_SLOT_TYPE_LIFE, RELIC_SLOT_TYPE_FROST, RELIC_SLOT_TYPE_LIFE}, -- Restoration
    },
    [Unit.WARLOCK] = {
        [128942] = {RELIC_SLOT_TYPE_SHADOW, RELIC_SLOT_TYPE_BLOOD, RELIC_SLOT_TYPE_SHADOW}, -- Affliction
        [128943] = {RELIC_SLOT_TYPE_SHADOW, RELIC_SLOT_TYPE_FIRE, RELIC_SLOT_TYPE_FEL}, -- Demonology
        [128941] = {RELIC_SLOT_TYPE_FEL, RELIC_SLOT_TYPE_FIRE, RELIC_SLOT_TYPE_FEL}, -- Destruction
    },
    [Unit.WARRIOR] = {
        [128910] = {RELIC_SLOT_TYPE_IRON, RELIC_SLOT_TYPE_BLOOD, RELIC_SLOT_TYPE_SHADOW}, -- Arms
        [128908] = {RELIC_SLOT_TYPE_FIRE, RELIC_SLOT_TYPE_WIND, RELIC_SLOT_TYPE_IRON}, -- Fury
        [128289] = {RELIC_SLOT_TYPE_IRON, RELIC_SLOT_TYPE_BLOOD, RELIC_SLOT_TYPE_FIRE}, -- Protection
    }
}

-- Trinket types
Self.TRINKET_AGI = 1
Self.TRINKET_INT = 2
Self.TRINKET_STR = 3
Self.TRINKET_HEAL = 4
Self.TRINKET_TANK = 5

-- What trinkets classes use
Self.CLASS_TRINKETS = {
    [Unit.DEATH_KNIGHT] =   {Self.TRINKET_STR, Self.TRINKET_TANK},
    [Unit.DEMON_HUNTER] =   {Self.TRINKET_AGI, Self.TRINKET_TANK},
    [Unit.DRUID] =          {Self.TRINKET_AGI, Self.TRINKET_INT, Self.TRINKET_HEAL, Self.TRINKET_TANK},
    [Unit.HUNTER] =         {Self.TRINKET_AGI},
    [Unit.MAGE] =           {Self.TRINKET_INT},
    [Unit.MONK] =           {Self.TRINKET_AGI, Self.TRINKET_HEAL, Self.TRINKET_TANK},
    [Unit.PALADIN] =        {Self.TRINKET_STR, Self.TRINKET_HEAL, Self.TRINKET_TANK},
    [Unit.PRIEST] =         {Self.TRINKET_INT, Self.TRINKET_HEAL},
    [Unit.ROGUE] =          {Self.TRINKET_AGI},
    [Unit.SHAMAN] =         {Self.TRINKET_AGI, Self.TRINKET_INT, Self.TRINKET_HEAL},
    [Unit.WARLOCK] =        {Self.TRINKET_INT},
    [Unit.WARRIOR] =        {Self.TRINKET_STR, Self.TRINKET_TANK}
}

-- Armor locations
Self.TYPE_2HWEAPON = "INVTYPE_2HWEAPON"
Self.TYPE_BODY = "INVTYPE_BODY"
Self.TYPE_CHEST = "INVTYPE_CHEST"
Self.TYPE_CLOAK = "INVTYPE_CLOAK"
Self.TYPE_FEET = "INVTYPE_FEET"
Self.TYPE_FINGER = "INVTYPE_FINGER"
Self.TYPE_HAND = "INVTYPE_HAND"
Self.TYPE_HEAD = "INVTYPE_HEAD"
Self.TYPE_HOLDABLE = "INVTYPE_HOLDABLE"
Self.TYPE_LEGS = "INVTYPE_LEGS"
Self.TYPE_NECK = "INVTYPE_NECK"
Self.TYPE_ROBE = "INVTYPE_ROBE"
Self.TYPE_SHIELD = "INVTYPE_SHIELD"
Self.TYPE_SHOULDER = "INVTYPE_SHOULDER"
Self.TYPE_TABARD = "INVTYPE_TABARD"
Self.TYPE_THROWN = "INVTYPE_THROWN"
Self.TYPE_TRINKET = "INVTYPE_TRINKET"
Self.TYPE_WAIST = "INVTYPE_WAIST"
Self.TYPE_WEAPON = "INVTYPE_WEAPON"
Self.TYPE_WEAPONMAINHAND = "INVTYPE_WEAPONMAINHAND"
Self.TYPE_WEAPONOFFHAND = "INVTYPE_WEAPONOFFHAND"
Self.TYPE_WRIST = "INVTYPE_WRIST"

-- Armor inventory slots
Self.SLOTS = {
    [Self.TYPE_2HWEAPON] = {INVSLOT_MAINHAND},
    [Self.TYPE_BODY] = {INVSLOT_BODY},
    [Self.TYPE_CHEST] = {INVSLOT_CHEST},
    [Self.TYPE_CLOAK] = {INVSLOT_BACK},
    [Self.TYPE_FEET] = {INVSLOT_FEET},
    [Self.TYPE_FINGER] = {INVSLOT_FINGER1, INVSLOT_FINGER2},
    [Self.TYPE_HAND] = {INVSLOT_HAND},
    [Self.TYPE_HEAD] = {INVSLOT_HEAD},
    [Self.TYPE_HOLDABLE] = {INVSLOT_OFFHAND},
    [Self.TYPE_LEGS] = {INVSLOT_LEGS},
    [Self.TYPE_NECK] = {INVSLOT_NECK},
    [Self.TYPE_ROBE] = {INVSLOT_CHEST},
    [Self.TYPE_SHIELD] = {INVSLOT_OFFHAND},
    [Self.TYPE_SHOULDER] = {INVSLOT_SHOULDER},
    [Self.TYPE_TABARD] = {INVSLOT_TABARD},
    [Self.TYPE_THROWN] = {}, -- TODO
    [Self.TYPE_TRINKET] = {INVSLOT_TRINKET1, INVSLOT_TRINKET2},
    [Self.TYPE_WAIST] = {INVSLOT_WAIST},
    [Self.TYPE_WEAPON] = {INVSLOT_MAINHAND, INVSLOT_OFFHAND},
    [Self.TYPE_WEAPONMAINHAND] = {INVSLOT_MAINHAND},
    [Self.TYPE_WEAPONOFFHAND] = {INVSLOT_OFFHAND},
    [Self.TYPE_WRIST] = {INVSLOT_WRIST}
}

-- Item info positions
Self.INFO = {
    link = {
        color = 1,
        id = 3,
        -- enchantId = 4,
        -- gemIds = {5, 6, 7, 8},
        -- suffixId = 9,
        -- uniqueId = 10,
        -- linkLevel = 11,
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
        relicType = true
    }
}

-- Cache the player's ilvl per slot
Self.playerSlotLevels = {}

-- New items waiting for the BAG_UPDATE_DELAYED event
Self.queue = {}

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
    end
end

function Self.GetInfo(link, attr)
    link = link.link or link

    if not link then
        return
    -- isRelic
    elseif attr == "isRelic" then
        return Self.GetInfo(link, "subType") == "Artifact Relic"
    -- isEquippable
    elseif attr == "isEquippable" then
        return IsEquippableItem(link) or Self.GetInfo(link, "isRelic")
    -- level, baseLevel
    elseif Util.In(attr, "level", "baseLevel") then
        return (select(attr == "level" and 1 or 3, GetDetailedItemLevelInfo(link)))
    -- quality
    elseif attr == "quality" then
        local color = Self.GetInfo(link, "color")
        return color and Util.TblFindWhere(ITEM_QUALITY_COLORS, "hex", "|cff" .. color) or 1
    -- From link
    elseif Self.INFO.link[attr] then
        local v = select(Self.INFO.link[attr] + 2, link:find(Self.PATTERN_LINK_DATA))

        if v == "" then
            return attr == "expacId" and 0 or nil
        elseif Util.StrIsNumber(v) then
            return tonumber(v)
        else
            return v
        end
    -- From GetItemInfo()
    elseif Self.INFO.basic[attr] then
        return select(Self.INFO.basic[attr], GetItemInfo(link))
    -- From Tooltip scanning
    elseif Self.INFO.full[attr] then
        return Util.ScanTooltip(scanFn, link, nil, nil, attr)
    end
end

-------------------------------------------------------
--               Create item instance                --
-------------------------------------------------------

-- Create an item instance from a link
function Self.FromLink(item, owner, bagOrEquip, slot)
    if type(item) == "string" then
        owner = Unit.Name(owner or "player")
        item = {
            link = item,
            owner = owner,
            isOwner = UnitIsUnit(owner, "player"),
            infoLevel = Self.INFO_NONE
        }
        setmetatable(item, {__index = Self})
        item:SetPosition(bagOrEquip, slot)
    end

    return item
end

-- Create an item instance for the given equipment slot
function Self.FromSlot(slot, unit)
    local link = GetInventoryItemLink(unit or "player", slot)
    if link then
        return Self.FromLink(link, unit, slot)
    end
end

-- Create an item instance from the given bag position
function Self.FromBagSlot(bag, slot)
    local link = GetContainerItemLink(bag, slot)
    if link then
        return Self.FromLink(link, nil, bag, slot)
    end
end

-- Get the currently equipped artifact weapon
function Self.GetEquippedArtifact(unit)
    unit = unit or "player"
    local classId = select(3, UnitClass(unit))

    for i,slot in pairs(Self.SLOTS[Self.TYPE_WEAPON]) do
        local id = GetInventoryItemID(unit, slot)
        if id and Self.CLASS_RELICS[classId][id] then
            return Self.FromSlot(slot, unit)
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
        
        -- Some extra infos
        self.quality = info[1] and Util.TblFindWhere(ITEM_QUALITY_COLORS, "hex", "|cff" .. info[1]) or 1
        self.infoLevel = Self.INFO_LINK
    end

    return self, self.infoLevel >= Self.INFO_LINK
end

-- Get info from GetItemInfo()
local mapFn = function (trinkets, i, id) return trinkets[id] and i end

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

            -- Trinket info
            if self.equipLoc == Self.TYPE_TRINKET then
                self.trinketTypes = Util.TblCopy(Self.TRINKETS, mapFn, self.id)
            end
        end
    end

    return self, self.infoLevel >= Self.INFO_BASIC
end

-- Get extra info by scanning the tooltip
function Self:GetFullInfo()
    self:GetBasicInfo()

    -- TODO: Optimize (e.g. restrict line numbers)!
    if self.infoLevel == Self.INFO_BASIC then
        Util.ScanTooltip(function (i, line)
            self.infoLevel = Self.INFO_FULL

            -- Ilvl (incl. upgrades)
            if not self.level then
                self.level = tonumber(line:match(Self.PATTERN_ILVL))
                if self.level then return end
            end
            -- Class restrictions
            if not self.classes then
                local classes = line:match(Self.PATTERN_CLASSES)
                if classes then
                    self.classes = Util.StrSplit(classes, ", ")
                    return
                end
            end

            if self.isEquippable then
                -- Relic type
                if self.isRelic and not self.relicType then
                    self.relicType = line:match(Self.PATTERN_RELIC_TYPE)
                    if self.relicType then return end
                end
                -- Primary attributes
                self.attributes = self.attributes or {}
                for i,attr in pairs(Self.ATTRIBUTES) do
                    if not self.attributes[attr] then
                        self.attributes[attr] = line:match(Self["PATTERN_" .. attr:upper()]) -- TODO: Doesn't get the values correctly
                        if self.attributes[attr] then return end
                    end
                end
            end
        end, self.link)

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

-- Get a list of owned items by equipment location
local searchFn = function (link, b, s, items, self, classId)
    if Self.GetInfo(link, "isEquippable") then
        if self.isRelic then
            local id = Self.GetInfo(link, "id")
            if Self.CLASS_RELICS[classId][id] then
                for i=1,3 do
                    if Self.CLASS_RELICS[classId][id][i] == self.relicType then
                        tinsert(items, (select(2, GetItemGem(link, i))))
                    end
                end
            elseif Self.GetInfo(link, "isRelic") and Self.GetInfo(link, "relicType") == self.relicType then
                tinsert(items, link)
            end
        elseif Self.GetInfo(link, "quality") ~= LE_ITEM_QUALITY_LEGENDARY then
            local subType, _, equipLoc = select(7, GetItemInfo(link))
            if subType and subType ~= "Artifact Relic" and equipLoc and Util.TblEquals(Self.SLOTS[equipLoc], Self.SLOTS[self.equipLoc]) then
                tinsert(items, link)
            end
        end
    end
end

function Self:GetOwnedForLocation(equipped, bag)
    local items = {}

    -- No point in doing this if we don't have the info yet
    _, success = self:GetBasicInfo()
    if not success then return items end

    -- We will need the relic type for relics
    if self.isRelic then
        self:GetFullInfo()
    end

    -- Get equipped item(s)
    if equipped ~= false then
        if self.isRelic then
            local weapon = Self.GetEquippedArtifact()
            items = weapon and weapon:GetRelics(self.relicType) or items
        else for i,slot in pairs(Self.SLOTS[self.equipLoc]) do
            local link = GetInventoryItemLink("player", slot)
            if link and Self.GetInfo(link, "quality") ~= LE_ITEM_QUALITY_LEGENDARY then
                tinsert(items, link)
            end
        end end
    end

    -- Get item(s) from bag
    if bag ~= false then
        Util.SearchBags(searchFn, nil, nil, items, self, (select(3, UnitClass("player"))))
    end

    return items
end

-- Get number of slots for a given equipment location
function Self:GetSlotCountForLocation()
    -- No point in doing this if we don't have the info yet
    _, success = self:GetBasicInfo()
    if not success then return 0 end

    if self.isRelic then
        return Util.TblCountFn(Self.CLASS_RELICS[select(3, UnitClass("player"))], Util.TblCountVal, self:GetFullInfo().relicType)
    else
        return #Self.SLOTS[self.equipLoc]
    end
end

-- Get the threshold for the item's slot
function Self:GetThresholdForLocation()
    local threshold = Self.ILVL_THRESHOLD

    -- Trinkets have double the normal threshold
    if self:GetBasicInfo().equipLoc == Self.TYPE_TRINKET then
        threshold = threshold * 2
    end

    return threshold
end

-- Get the reference level for equipment location
function Self:GetLevelForLocation(unit)
    unit = Unit.Name(unit or "player")
    local location = self:GetBasicInfo().isRelic and self:GetFullInfo().relicType or self.equipLoc

    if UnitIsUnit(unit, "player") then
        -- For the player
        local cache = Self.playerSlotLevels[location] or {}
        if not cache.ilvl or not cache.time or cache.time + Inspect.REFRESH < GetTime() then
            cache.time = GetTime()
            cache.ilvl = Util(self:GetOwnedForLocation())
                .Map(Self.GetInfo, false, "level")
                .Sort(true)(self:GetSlotCountForLocation())
            Self.playerSlotLevels[location] = cache
        end

        return cache.ilvl or 0
    else
        -- For other players
        return Inspect.Get(unit, location)
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
    _, success = self:GetBasicInfo()
    if not success then return {} end

    local weaponRelics = Util.TblFirstWhere(Self.CLASS_RELICS, self.id)[self.id]
    relicTypes = relicTypes and Util.Tbl(relicTypes)

    local relics = {}
    for slot,relicType in pairs(weaponRelics) do
        if not relicTypes or Util.TblFind(relicTypes, relicType) then
            tinsert(relics, self:GetGem(slot))
        end
    end

    return relics
end

-- Get all relic slots with types that only occur in this weapon for the given class
function Self:GetUniqueRelicSlots()
    _, success = self:GetBasicInfo()
    if not success then return {} end

    local weapons = Util.TblFirstWhere(Self.CLASS_RELICS, self.id)
    local selfRelics = Util.TblCopy(weapons[self.id])

    -- Remove all relicTypes that occur in other weapons
    for id,relics in pairs(weapons) do
        if id ~= self.id then
            for _,relicType in pairs(relics) do
                for slot,selfRelicType in pairs(selfRelics) do
                    if relicType == selfRelicType then
                        selfRelics[slot] = nil
                    end
                end
            end
        end
    end

    return selfRelics
end

-------------------------------------------------------
--                    Properties                     --
-------------------------------------------------------

-- Check the item quality
function Self:HasSufficientQuality()
    return self:GetLinkInfo().quality >= (IsInRaid() and LE_ITEM_QUALITY_EPIC or LE_ITEM_QUALITY_RARE)
end

-- Check if an item can be equipped
function Self:CanBeEquipped(unit)
    -- Check if it's equippable
    if not self:GetBasicInfo().isEquippable then
        return false
    end
    
    self:GetFullInfo()
    local className, _, classId = UnitClass(unit or "player")

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
        for itemId, types in pairs(Self.CLASS_RELICS[classId]) do
            if Util.In(self.relicType, types) then
                return true
            end
        end
        return false
    end

    -- Check if the armor/weapon type can be equipped
    local list = Self.CLASS_GEAR[self.classId] and Self.CLASS_GEAR[self.classId][self.subClassId]
    return list and (list == true or Util.TblFind(list, classId) ~= nil)
end

-- Check if item either has no or matching primary attributes
function Self:HasMatchingAttributes(unit)
    self:GetFullInfo()

    -- Item has no primary attributes
    if not self.attributes or not next(self.attributes) then
        return true
    end
    
    -- Check if item has a primary attribute that the class can use
    local classId = select(3, UnitClass(unit or "player"))

    return Util.TblSearch(self.attributes, function (v, attr)
        return Util.TblFind(Self.CLASS_ATTRIBUTES[attr], classId)
    end) ~= nil
end

-- Check against equipped ilvl
function Self:HasSufficientLevel(unit)
    return self:GetBasicInfo().level + self:GetThresholdForLocation() >= self:GetLevelForLocation(unit or "player")
end

-- Check if item is useful for the player
function Self:IsUseful(unit)
    unit = unit or "player"

    if not (self:CanBeEquipped(unit) and self:HasMatchingAttributes(unit)) then
        return false
    elseif self:GetBasicInfo().equipLoc == Self.TYPE_TRINKET then
        return not next(self.trinketTypes) or Util.TblIntersects(self.trinketTypes, Self.CLASS_TRINKETS[select(3, UnitClass(unit))])
    else
        return true
    end
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
                return self:IsUseful(unit) and self:HasSufficientLevel(unit)
            end
        else
            self.eligible = {}
            Util.SearchGroup(function (i, unit)
                if unit and self:CanBeEquipped(unit) then
                    self.eligible[unit] = self:IsUseful(unit) and self:HasSufficientLevel(unit)
                end
            end)

            if Addon.DEBUG and self.isOwner and self.eligible[UnitName("player")] == nil then
                self.eligible[UnitName("player")] = self:IsUseful() and self:HasSufficientLevel()
            end
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
    local n = 0
    for unit,ilvl in pairs(self:GetEligible()) do
        if not checkIlvl or ilvl then n = n + 1 end
    end
    return n
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
    return self:ShouldBeConsidered() and self:GetEligible("player")
end

-- Check if the addon should start a roll for an item
function Self:ShouldBeRolledFor()
    return self:ShouldBeConsidered() and self:GetNumEligible(true) > (self:GetEligible(self.owner) and 1 or 0)
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
        elseif not self.isOwner then
            local level = self:GetLevelForLocation(self.owner)
            local isTradable = level == 0 or level + self:GetThresholdForLocation() >= self.level

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
    if not self.isOwner then
        return
    elseif not refresh and self.bagOrEquip and self.slot ~= 0 then
        return self.bagOrEquip, self.slot, self.isTradable
    end

    -- Check bags
    local bag, slot, isTradable
    Util.SearchBags(function (link, b, s)
        if link == self.link then
            isTradable = Self.IsTradable(b, s)
            if isTradable or not (bag and slot) then
                bag, slot = b, s
                if isTradable then return true end
            end
        end
    end, self.slot == 0 and self.bagOrEquip or nil)

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