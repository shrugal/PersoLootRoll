local Addon = LibStub("AceAddon-3.0"):GetAddon(PLR_NAME)
local Util = Addon.Util
local Self = {}

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
    [ITEM_MOD_STRENGTH_SHORT] = {Util.DEATH_KNIGHT, Util.PALADIN, Util.WARRIOR},
    [ITEM_MOD_INTELLECT_SHORT] = {Util.DRUID, Util.MAGE, Util.MONK, Util.PALADIN, Util.PRIEST, Util.SHAMAN, Util.WARLOCK},
    [ITEM_MOD_AGILITY_SHORT] = {Util.DEMON_HUNTER, Util.DRUID, Util.HUNTER, Util.MONK, Util.ROGUE, Util.SHAMAN}
}

-- What gear classes can equip
Self.CLASS_GEAR = {
    [LE_ITEM_CLASS_ARMOR] = {
        [LE_ITEM_ARMOR_GENERIC] = true,
        [LE_ITEM_ARMOR_CLOTH] = {Util.MAGE, Util.PRIEST, Util.WARLOCK},
        [LE_ITEM_ARMOR_LEATHER] = {Util.DEMON_HUNTER, Util.DRUID, Util.MONK, Util.ROGUE},
        [LE_ITEM_ARMOR_MAIL] = {Util.HUNTER, Util.SHAMAN},
        [LE_ITEM_ARMOR_PLATE] = {Util.DEATH_KNIGHT, Util.PALADIN, Util.WARRIOR},
        [LE_ITEM_ARMOR_SHIELD] = {Util.PALADIN, Util.SHAMAN, Util.WARRIOR}
    },
    [LE_ITEM_CLASS_WEAPON] = {
        [LE_ITEM_WEAPON_AXE1H] = {Util.DEATH_KNIGHT, Util.DEMON_HUNTER, Util.HUNTER, Util.MONK, Util.PALADIN, Util.ROGUE, Util.SHAMAN, Util.WARRIOR},
        [LE_ITEM_WEAPON_MACE1H] = {Util.DEATH_KNIGHT, Util.DRUID, Util.MONK, Util.PALADIN, Util.PRIEST, Util.ROGUE, Util.SHAMAN, Util.WARRIOR},
        [LE_ITEM_WEAPON_SWORD1H] = {Util.DEATH_KNIGHT, Util.DEMON_HUNTER, Util.HUNTER, Util.MAGE, Util.MONK, Util.PALADIN, Util.ROGUE, Util.WARLOCK, Util.WARRIOR},
        [LE_ITEM_WEAPON_WARGLAIVE] = {Util.DEMON_HUNTER},
        [LE_ITEM_WEAPON_DAGGER] = {Util.DEMON_HUNTER, Util.DRUID, Util.HUNTER, Util.MAGE, Util.PRIEST, Util.ROGUE, Util.SHAMAN, Util.WARLOCK, Util.WARRIOR},
        [LE_ITEM_WEAPON_UNARMED] = {Util.DEMON_HUNTER, Util.DRUID, Util.HUNTER, Util.MONK, Util.ROGUE, Util.SHAMAN, Util.WARRIOR},
        [LE_ITEM_WEAPON_WAND] = {Util.MAGE, Util.PRIEST, Util.WARLOCK},
        [LE_ITEM_WEAPON_AXE2H] = {Util.DEATH_KNIGHT, Util.PALADIN, Util.SHAMAN, Util.WARRIOR},
        [LE_ITEM_WEAPON_MACE2H] = {Util.DEATH_KNIGHT, Util.PALADIN, Util.SHAMAN, Util.WARRIOR},
        [LE_ITEM_WEAPON_SWORD2H] = {Util.DEATH_KNIGHT, Util.PALADIN, Util.WARRIOR},
        [LE_ITEM_WEAPON_POLEARM] = {Util.DEATH_KNIGHT, Util.DRUID, Util.HUNTER, Util.MONK, Util.PALADIN, Util.WARRIOR},
        [LE_ITEM_WEAPON_STAFF] = {Util.DRUID, Util.HUNTER, Util.MAGE, Util.MONK, Util.PRIEST, Util.SHAMAN, Util.WARLOCK, Util.WARRIOR},
        [LE_ITEM_WEAPON_BOWS] = {Util.HUNTER, Util.WARRIOR},
        [LE_ITEM_WEAPON_CROSSBOW] = {Util.HUNTER, Util.WARRIOR},
        [LE_ITEM_WEAPON_GUNS] = {Util.HUNTER, Util.WARRIOR},
        [LE_ITEM_WEAPON_THROWN] = {Util.ROGUE, Util.WARRIOR}
    }
}

-- Artifact relic slots
Self.CLASS_RELICS = {
    [Util.DEATH_KNIGHT] = {
        [128402] = {RELIC_SLOT_TYPE_BLOOD, RELIC_SLOT_TYPE_SHADOW, RELIC_SLOT_TYPE_IRON}, -- Blood
        [128292] = {RELIC_SLOT_TYPE_FROST, RELIC_SLOT_TYPE_SHADOW, RELIC_SLOT_TYPE_FROST}, -- Frost
        [128403] = {RELIC_SLOT_TYPE_FIRE, RELIC_SLOT_TYPE_SHADOW, RELIC_SLOT_TYPE_BLOOD}, -- Unholy
    },
    [Util.DEMON_HUNTER] = {
        [127829] = {RELIC_SLOT_TYPE_FEL, RELIC_SLOT_TYPE_SHADOW, RELIC_SLOT_TYPE_FEL}, -- Havoc
        [128832] = {RELIC_SLOT_TYPE_IRON, RELIC_SLOT_TYPE_ARCANE, RELIC_SLOT_TYPE_FEL}, -- Vengeance
    },
    [Util.DRUID] = {
        [128858] = {RELIC_SLOT_TYPE_ARCANE, RELIC_SLOT_TYPE_LIFE, RELIC_SLOT_TYPE_ARCANE}, -- Balance
        [128860] = {RELIC_SLOT_TYPE_FROST, RELIC_SLOT_TYPE_BLOOD, RELIC_SLOT_TYPE_LIFE}, -- Feral
        [128821] = {RELIC_SLOT_TYPE_FIRE, RELIC_SLOT_TYPE_BLOOD, RELIC_SLOT_TYPE_LIFE}, -- Guardian
        [128306] = {RELIC_SLOT_TYPE_LIFE, RELIC_SLOT_TYPE_FROST, RELIC_SLOT_TYPE_LIFE}, -- Restoration
    },
    [Util.HUNTER] = {
        [128861] = {RELIC_SLOT_TYPE_WIND, RELIC_SLOT_TYPE_ARCANE, RELIC_SLOT_TYPE_IRON}, -- Beast Mastery
        [128826] = {RELIC_SLOT_TYPE_WIND, RELIC_SLOT_TYPE_BLOOD, RELIC_SLOT_TYPE_LIFE}, -- Marksmanship
        [128808] = {RELIC_SLOT_TYPE_WIND, RELIC_SLOT_TYPE_IRON, RELIC_SLOT_TYPE_BLOOD}, -- Survival
    },
    [Util.MAGE] = {
        [127857] = {RELIC_SLOT_TYPE_ARCANE, RELIC_SLOT_TYPE_FROST, RELIC_SLOT_TYPE_ARCANE}, -- Arcane
        [128820] = {RELIC_SLOT_TYPE_FIRE, RELIC_SLOT_TYPE_ARCANE, RELIC_SLOT_TYPE_FIRE}, -- Fire
        [128862] = {RELIC_SLOT_TYPE_FROST, RELIC_SLOT_TYPE_ARCANE, RELIC_SLOT_TYPE_FROST}, -- Frost
    },
    [Util.MONK] = {
        [128938] = {RELIC_SLOT_TYPE_LIFE, RELIC_SLOT_TYPE_WIND, RELIC_SLOT_TYPE_IRON}, -- Brewmaster
        [128937] = {RELIC_SLOT_TYPE_FROST, RELIC_SLOT_TYPE_LIFE, RELIC_SLOT_TYPE_WIND}, -- Mistweaver
        [128940] = {RELIC_SLOT_TYPE_WIND, RELIC_SLOT_TYPE_IRON, RELIC_SLOT_TYPE_WIND}, -- Windwalker
    },
    [Util.PALADIN] = {
        [128823] = {RELIC_SLOT_TYPE_HOLY, RELIC_SLOT_TYPE_LIFE, RELIC_SLOT_TYPE_HOLY}, -- Holy
        [128866] = {RELIC_SLOT_TYPE_HOLY, RELIC_SLOT_TYPE_IRON, RELIC_SLOT_TYPE_ARCANE}, -- Protection
        [120978] = {RELIC_SLOT_TYPE_HOLY, RELIC_SLOT_TYPE_FIRE, RELIC_SLOT_TYPE_HOLY}, -- Retribution
    },
    [Util.PRIEST] = {
        [128868] = {RELIC_SLOT_TYPE_HOLY, RELIC_SLOT_TYPE_SHADOW, RELIC_SLOT_TYPE_HOLY}, -- Discipline
        [128825] = {RELIC_SLOT_TYPE_HOLY, RELIC_SLOT_TYPE_LIFE, RELIC_SLOT_TYPE_HOLY}, -- Holy
        [128827] = {RELIC_SLOT_TYPE_SHADOW, RELIC_SLOT_TYPE_BLOOD, RELIC_SLOT_TYPE_SHADOW}, -- Shadow
    },
    [Util.ROGUE] = {
        [128870] = {RELIC_SLOT_TYPE_SHADOW, RELIC_SLOT_TYPE_IRON, RELIC_SLOT_TYPE_BLOOD}, -- Assassination
        [128872] = {RELIC_SLOT_TYPE_BLOOD, RELIC_SLOT_TYPE_IRON, RELIC_SLOT_TYPE_WIND}, -- Outlaw
        [128476] = {RELIC_SLOT_TYPE_FEL, RELIC_SLOT_TYPE_SHADOW, RELIC_SLOT_TYPE_FEL}, -- Subtlety
    },
    [Util.SHAMAN] = {
        [128935] = {RELIC_SLOT_TYPE_WIND, RELIC_SLOT_TYPE_FROST, RELIC_SLOT_TYPE_WIND}, -- Elemental
        [128819] = {RELIC_SLOT_TYPE_FIRE, RELIC_SLOT_TYPE_IRON, RELIC_SLOT_TYPE_WIND}, -- Enhancement
        [128911] = {RELIC_SLOT_TYPE_LIFE, RELIC_SLOT_TYPE_FROST, RELIC_SLOT_TYPE_LIFE}, -- Restoration
    },
    [Util.WARLOCK] = {
        [128942] = {RELIC_SLOT_TYPE_SHADOW, RELIC_SLOT_TYPE_BLOOD, RELIC_SLOT_TYPE_SHADOW}, -- Affliction
        [128943] = {RELIC_SLOT_TYPE_SHADOW, RELIC_SLOT_TYPE_FIRE, RELIC_SLOT_TYPE_FEL}, -- Demonology
        [128941] = {RELIC_SLOT_TYPE_FEL, RELIC_SLOT_TYPE_FIRE, RELIC_SLOT_TYPE_FEL}, -- Destruction
    },
    [Util.WARRIOR] = {
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
    [Util.DEATH_KNIGHT] =   {Self.TRINKET_STR, Self.TRINKET_TANK},
    [Util.DEMON_HUNTER] =   {Self.TRINKET_AGI, Self.TRINKET_TANK},
    [Util.DRUID] =          {Self.TRINKET_AGI, Self.TRINKET_INT, Self.TRINKET_HEAL, Self.TRINKET_TANK},
    [Util.HUNTER] =         {Self.TRINKET_AGI},
    [Util.MAGE] =           {Self.TRINKET_INT},
    [Util.MONK] =           {Self.TRINKET_AGI, Self.TRINKET_HEAL, Self.TRINKET_TANK},
    [Util.PALADIN] =        {Self.TRINKET_STR, Self.TRINKET_HEAL, Self.TRINKET_TANK},
    [Util.PRIEST] =         {Self.TRINKET_INT, Self.TRINKET_HEAL},
    [Util.ROGUE] =          {Self.TRINKET_AGI},
    [Util.SHAMAN] =         {Self.TRINKET_AGI, Self.TRINKET_INT, Self.TRINKET_HEAL},
    [Util.WARLOCK] =        {Self.TRINKET_INT},
    [Util.WARRIOR] =        {Self.TRINKET_STR, Self.TRINKET_TANK}
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
    [Self.TYPE_2HWEAPON] = INVSLOT_MAINHAND,
    [Self.TYPE_BODY] = INVSLOT_BODY,
    [Self.TYPE_CHEST] = INVSLOT_CHEST,
    [Self.TYPE_CLOAK] = INVSLOT_BACK,
    [Self.TYPE_FEET] = INVSLOT_FEET,
    [Self.TYPE_FINGER] = {INVSLOT_FINGER1, INVSLOT_FINGER2},
    [Self.TYPE_HAND] = INVSLOT_HAND,
    [Self.TYPE_HEAD] = INVSLOT_HEAD,
    [Self.TYPE_HOLDABLE] = INVSLOT_OFFHAND,
    [Self.TYPE_LEGS] = INVSLOT_LEGS,
    [Self.TYPE_NECK] = INVSLOT_NECK,
    [Self.TYPE_ROBE] = INVSLOT_CHEST,
    [Self.TYPE_SHIELD] = INVSLOT_OFFHAND,
    [Self.TYPE_SHOULDER] = INVSLOT_SHOULDER,
    [Self.TYPE_TABARD] = INVSLOT_TABARD,
    [Self.TYPE_THROWN] = nil, -- TODO
    [Self.TYPE_TRINKET] = {INVSLOT_TRINKET1, INVSLOT_TRINKET2},
    [Self.TYPE_WAIST] = INVSLOT_WAIST,
    [Self.TYPE_WEAPON] = {INVSLOT_MAINHAND, INVSLOT_OFFHAND},
    [Self.TYPE_WEAPONMAINHAND] = INVSLOT_MAINHAND,
    [Self.TYPE_WEAPONOFFHAND] = INVSLOT_OFFHAND,
    [Self.TYPE_WRIST] = INVSLOT_WRIST
}

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

-------------------------------------------------------
--               Create item instance                --
-------------------------------------------------------

-- Create an item instance from a link
function Self.FromLink(item, owner, bagOrEquip, slot)
    if type(item) == "string" then
        owner = Util.GetName(owner or "player")
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

    return Util(Self.SLOTS[Self.TYPE_WEAPON]).Map(Util.FnPrep(Self.FromSlot, nil, unit)).First(function (item)
        return Self.CLASS_RELICS[classId][item:GetBasicInfo().id]
    end)()
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
        
        self.color = info[1]
        self.id = info[3]
        self.enchantId = info[4]
        self.gemIds = {info[5], info[6], info[7], info[8]}
        self.suffixId = info[9]
        self.uniqueId = info[10]
        self.linkLevel = info[11]
        self.specId = info[12]
        self.reforgeId = info[13]
        self.difficultyId = info[14]
        self.numBonusIds = info[15]
        self.bonusIds = {info[16], info[17]}
        self.upgradeValue = info[18]
        self.name = info[19]
        self.quality = info[1] and Util.TblFindWhere(ITEM_QUALITY_COLORS, {hex = "|cff" .. info[1]}) or 1
        self.infoLevel = Self.INFO_LINK
    end

    return self, self.infoLevel >= Self.INFO_LINK
end

-- Get info from GetItemInfo()
function Self:GetBasicInfo()
    self:GetLinkInfo()
    
    if self.infoLevel == Self.INFO_LINK then
        local info = {GetItemInfo(self.link or self.id)}
        if #info > 0 then
            -- Get correct level
            local level, _, baseLevel = GetDetailedItemLevelInfo(self.link or self.id)

            self.name = info[1]
            self.link = info[2]
            self.quality = info[3]
            self.level = level or info[4]
            self.baseLevel = baseLevel or level
            self.minLevel = info[5]
            self.type = info[6]
            self.subType = info[7]
            self.stackCount = info[8]
            self.equipLoc = info[9]
            self.texture = info[10]
            self.sellPrice = info[11]
            self.classId = info[12]
            self.subClassId = info[13]
            self.bindType = info[14]
            self.expacId = info[15]
            self.setId = info[16]
            self.isCraftingReagent = info[17]
            
            -- Some extra info
            self.isRelic = self.subType == "Artifact Relic"
            self.isEquippable = IsEquippableItem(self.link) or self.isRelic
            self.isSoulbound = self.bindType == LE_ITEM_BIND_ON_ACQUIRE or self.isEquipped and self.bindType == LE_ITEM_BIND_ON_EQUIP
            self.isTradable = not self.isSoulbound or nil
            self.infoLevel = Self.INFO_BASIC

            -- Trinket info
            if self.equipLoc == Self.TYPE_TRINKET then
                self.trinketTypes = Util.TblMap(Self.TRINKETS, function (trinkets, i) return trinkets[self.id] and i end)
            end
        end
    end

    return self, self.infoLevel >= Self.INFO_BASIC
end

-- Get extra info by scanning the tooltip
function Self:GetFullInfo(bag)
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
            items = weapon and Util.TblValues(weapon:GetRelics(self.relicType))
        else
            items = Util(Self.SLOTS[self.equipLoc]).Tbl().Map(Util.FnArgs(Self.FromSlot, 1))()
        end
    end

    -- Get item(s) from bag
    if bag ~= false then
        local classId = select(3, UnitClass("player"))

        Util.SearchBags(function (item, id)
            item:GetBasicInfo()

            if self.isRelic then
                if Self.CLASS_RELICS[classId][id] then
                    Util.TblMerge(items, Util.TblValues(item:GetRelics(self.relicType)))
                elseif item.isRelic and item:GetFullInfo().relicType == self.relicType then
                    tinsert(items, item)
                end
            elseif not item.isRelic and Self.SLOTS[item.equipLoc] == Self.SLOTS[self.equipLoc] then
                tinsert(items, item)
            end
        end)
    end

    return items
end

-- Get number of slots for a given equipment location
function Self:GetSlotCountForLocation()
    -- No point in doing this if we don't have the info yet
    _, success = self:GetBasicInfo()
    if not success then return 0 end

    if self.isRelic then
        self:GetFullInfo()
        return #(Util(Self.CLASS_RELICS[select(3, UnitClass("player"))]).Flatten().Only(self.relicType)())
    else
        return #(Util.Tbl(Self.SLOTS[self.equipLoc]))
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
    unit = Util.GetName(unit or "player")

    if UnitIsUnit(unit, "player") then
        -- For the player
        return Util(self:GetOwnedForLocation())
            .Apply(Self.GetBasicInfo)
            .ExceptWhere({quality = LE_ITEM_QUALITY_LEGENDARY})
            .Pluck("level")
            .Sort(true)(self:GetSlotCountForLocation()) or 0
    else
        -- For other players
        local location = self:GetBasicInfo().isRelic and self:GetFullInfo().relicType or self.equipLoc
        return Addon.Inspect.Get(unit, location)
    end
end

-------------------------------------------------------
--                 Gems, relics etc.                 --
-------------------------------------------------------

-- Get gems in the item
function Self:GetGem(slot)
    return Self.FromLink(select(2, GetItemGem(self.link, slot)), self.owner, self.isEquipped)
end

-- Get artifact relics in the item
function Self:GetRelics(relicTypes)
    _, success = self:GetBasicInfo()
    if not success then return {} end

    local relics = Util.TblFirst(Self.CLASS_RELICS, Util.FnPluck(self.id))[self.id]
    relicTypes = relicTypes and Util.Tbl(relicTypes)

    return relics and Util(relics).Filter(not relicTypes and Util.FnTrue or Util.FnPrep(Util.TblFind, relicTypes), true).Map(function (relicType, slot)
        local relic = self:GetGem(slot)
        if relic then relic.relicType = relicType end
        return relic
    end)() or {}
end

-- Get all relic slots with types that only occur in this weapon for the given class
function Self:GetUniqueRelicSlots()
    _, success = self:GetBasicInfo()
    if not success then return {} end

    local weapons = Self.CLASS_RELICS[Util.TblSearch(Self.CLASS_RELICS, Util.FnPluck(self.id))]

    return Util.TblDiff(weapons[self.id], unpack(Util(weapons).Omit(self.id).Values()()), true)
end

-------------------------------------------------------
--                    Properties                     --
-------------------------------------------------------

-- Check the item quality
function Self:HasSufficientQuality()
    self:GetLinkInfo()
    return self.quality >= (IsInRaid() and LE_ITEM_QUALITY_EPIC or LE_ITEM_QUALITY_RARE)
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
    local list = Util.TblGet(Self.CLASS_GEAR, {self.classId, self.subClassId})
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
        return Util.In(classId, Self.CLASS_ATTRIBUTES[attr])
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
        -- Check if it's the right trinket type
        return not next(self.trinketTypes) or next(Util.TblIntersect(self.trinketTypes, Self.CLASS_TRINKETS[select(3, UnitClass(unit))]))
    else
        return true
    end
end

-- Check who in the group could use the item
function Self:GetEligible(allOrUnit)
    if not self.eligible then
        self.eligible = {}
        Util.SearchGroup(function (i, unit)
            if unit and self:IsUseful(unit) then
                self.eligible[unit] = self:HasSufficientLevel(unit)
            end
        end)

        if Addon.DEBUG then
            self.eligible[UnitName("player")] = self:HasSufficientLevel()
        end
    end

    if type(allOrUnit) == "string" then
        return self.eligible[allOrUnit]
    elseif allOrUnit then
        return self.eligible
    else
        return Util(self.eligible).Only(true, true).Omit(UnitName("player"))()
    end
end

-------------------------------------------------------
--                     Decisions                     --
-------------------------------------------------------

-- Do basic and quick check if an item is worthy of further consideration
function Self:ShouldBeConsidered()
    return self:HasSufficientQuality() -- TODO
end

-- Check if the addon should offer to bid on an item
function Self:ShouldBeBidOn()
    return self:HasSufficientQuality() and self:IsUseful("player") and self:HasSufficientLevel()
end

-- Check if the addon should start a roll for an item
function Self:ShouldBeRolledFor()
    -- Check basic item properties
    if not (self:HasSufficientQuality() and self:GetBasicInfo().isEquippable and self:GetFullInfo().isTradable) then
        return false
    end

    -- Check if there are eligible players in the group
    return next(self:GetEligible()) ~= nil
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
    local bagOrEquip, slot = self:GetPosition()
    return bagOrEquip and slot ~= 0 and (not tradable or self:IsTradable(bagOrEquip, slot))
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
            return false, true, nil
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
        return self.bagOrEquip, self.slot
    end

    -- Check bags
    local bag, slot, isTradable
    Util.SearchBags(function (item, _, b, s)
        if item.link == self.link then
            isTradable = Self.IsTradable(b, s)
            if isTradable or not (bag and slot) then
                bag, slot = b, s
                if isTradable then return true end
            end
        end
    end, self.slot == 0 and self.bagOrEquip or nil)

    if bag and slot then
        return bag, slot
    elseif self.bagOrEquip and self.slot == 0 then
        return self.bagOrEquip, self.slot
    end

    -- Check equipment
    if not select(2, self:GetBasicInfo()) then return end

    for _, equipSlot in pairs(Util.Tbl(Self.SLOTS[self.equipLoc])) do
        if self.link == GetInventoryItemLink(equipSlot) then
            return equipSlot
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
    Util(Addon.rolls).Where({isOwner = true, traded = false}).Find(function (roll)
        if Util.TblEquals(from, roll.item.position) then
            roll.item:SetPosition(to)
            return true
        end
    end)
end

-- Two items have switched places
function Self.OnSwitch(pos1, pos2)
    local item1, item2
    local items = Util(Addon.rolls).Where({IsOwner = true, traded = false}).Filter(function (roll)
        if not item1 and Util.TblEquals(pos1, roll.item.position) then
            item1 = roll.item
        elseif not item2 and Util.TblEquals(pos2, roll.item.position) then
            item2 = roll.item
        end
        return item1 and item2
    end)

    if item1 then item1:SetPosition(pos2) end
    if item2 then item2:SetPosition(pos1) end
end

-- Export

Addon.Item = Self