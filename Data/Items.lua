local Name, Addon = ...
local Unit = Addon.Unit
local Self = Addon.Item

-- Primary stats
Self.ATTRIBUTES = {
    LE_UNIT_STAT_STRENGTH, -- 1
    LE_UNIT_STAT_AGILITY,  -- 2
--  LE_UNIT_STAT_STAMINA,  -- 3
    LE_UNIT_STAT_INTELLECT -- 4
}

-- Roles
Self.ROLE_HEAL = 5
Self.ROLE_TANK = 6
Self.ROLE_MELEE = 7
Self.ROLE_RANGED = 8

-- Which class/spec can equip what
Self.CLASSES = {
    [Unit.DEATH_KNIGHT] = {
        armor = {LE_ITEM_ARMOR_GENERIC, LE_ITEM_ARMOR_PLATE},
        weapons = {LE_ITEM_WEAPON_AXE1H, LE_ITEM_WEAPON_MACE1H, LE_ITEM_WEAPON_SWORD1H, LE_ITEM_WEAPON_AXE2H, LE_ITEM_WEAPON_MACE2H, LE_ITEM_WEAPON_SWORD2H, LE_ITEM_WEAPON_POLEARM},
        specs = {
            -- Blood
            {role = Self.ROLE_TANK,     attribute = LE_UNIT_STAT_STRENGTH,  artifact = {id = 128402, relics = {RELIC_SLOT_TYPE_BLOOD, RELIC_SLOT_TYPE_SHADOW, RELIC_SLOT_TYPE_IRON}}},
            -- Frost
            {role = Self.ROLE_MELEE,    attribute = LE_UNIT_STAT_STRENGTH,  artifact = {id = 128292, relics = {RELIC_SLOT_TYPE_FROST, RELIC_SLOT_TYPE_SHADOW, RELIC_SLOT_TYPE_FROST}}},
            -- Unholy
            {role = Self.ROLE_MELEE,    attribute = LE_UNIT_STAT_STRENGTH,  artifact = {id = 128403, relics = {RELIC_SLOT_TYPE_FIRE, RELIC_SLOT_TYPE_SHADOW, RELIC_SLOT_TYPE_BLOOD}}}
        }
    },
    [Unit.DEMON_HUNTER] = {
        armor = {LE_ITEM_ARMOR_GENERIC, LE_ITEM_ARMOR_LEATHER},
        weapons = {LE_ITEM_WEAPON_AXE1H, LE_ITEM_WEAPON_SWORD1H, LE_ITEM_WEAPON_WARGLAIVE, LE_ITEM_WEAPON_DAGGER, LE_ITEM_WEAPON_UNARMED},
        specs = {
            -- Havoc
            {role = Self.ROLE_MELEE,    attribute = LE_UNIT_STAT_AGILITY,   artifact = {id = 127829, relics = {RELIC_SLOT_TYPE_FEL, RELIC_SLOT_TYPE_SHADOW, RELIC_SLOT_TYPE_FEL}}},
            -- Vengeance
            {role = Self.ROLE_TANK,     attribute = LE_UNIT_STAT_AGILITY,   artifact = {id = 128832, relics = {RELIC_SLOT_TYPE_IRON, RELIC_SLOT_TYPE_ARCANE, RELIC_SLOT_TYPE_FEL}}}
        }
    },
    [Unit.DRUID] = {
        armor = {LE_ITEM_ARMOR_GENERIC, LE_ITEM_ARMOR_LEATHER},
        weapons = {LE_ITEM_WEAPON_MACE1H, LE_ITEM_WEAPON_DAGGER, LE_ITEM_WEAPON_UNARMED, LE_ITEM_WEAPON_POLEARM, LE_ITEM_WEAPON_STAFF},
        specs = {
            -- Balance
            {role = Self.ROLE_RANGED,   attribute = LE_UNIT_STAT_INTELLECT, artifact = {id = 128858, relics = {RELIC_SLOT_TYPE_ARCANE, RELIC_SLOT_TYPE_LIFE, RELIC_SLOT_TYPE_ARCANE}}},
            -- Feral
            {role = Self.ROLE_MELEE,    attribute = LE_UNIT_STAT_AGILITY,   artifact = {id = 128860, relics = {RELIC_SLOT_TYPE_FROST, RELIC_SLOT_TYPE_BLOOD, RELIC_SLOT_TYPE_LIFE}}},
            -- Guardian
            {role = Self.ROLE_TANK,     attribute = LE_UNIT_STAT_AGILITY,   artifact = {id = 128821, relics = {RELIC_SLOT_TYPE_FIRE, RELIC_SLOT_TYPE_BLOOD, RELIC_SLOT_TYPE_LIFE}}},
            -- Restoration
            {role = Self.ROLE_HEAL,     attribute = LE_UNIT_STAT_INTELLECT, artifact = {id = 128306, relics = {RELIC_SLOT_TYPE_LIFE, RELIC_SLOT_TYPE_FROST, RELIC_SLOT_TYPE_LIFE}}}
        }
    },
    [Unit.HUNTER] = {
        armor = {LE_ITEM_ARMOR_GENERIC, LE_ITEM_ARMOR_MAIL},
        weapons = {LE_ITEM_WEAPON_AXE1H, LE_ITEM_WEAPON_SWORD1H, LE_ITEM_WEAPON_DAGGER, LE_ITEM_WEAPON_UNARMED, LE_ITEM_WEAPON_POLEARM, LE_ITEM_WEAPON_STAFF, LE_ITEM_WEAPON_BOWS, LE_ITEM_WEAPON_CROSSBOW, LE_ITEM_WEAPON_GUNS},
        specs = {
            -- Beast Mastery
            {role = Self.ROLE_RANGED,   attribute = LE_UNIT_STAT_AGILITY,   artifact = {id = 128861, relics = {RELIC_SLOT_TYPE_WIND, RELIC_SLOT_TYPE_ARCANE, RELIC_SLOT_TYPE_IRON}}},
            -- Marksmanship
            {role = Self.ROLE_RANGED,   attribute = LE_UNIT_STAT_AGILITY,   artifact = {id = 128826, relics = {RELIC_SLOT_TYPE_WIND, RELIC_SLOT_TYPE_BLOOD, RELIC_SLOT_TYPE_LIFE}}},
            -- Survival
            {role = Self.ROLE_MELEE,    attribute = LE_UNIT_STAT_AGILITY,   artifact = {id = 128808, relics = {RELIC_SLOT_TYPE_WIND, RELIC_SLOT_TYPE_IRON, RELIC_SLOT_TYPE_BLOOD}}}
        }
    },
    [Unit.MAGE] = {
        armor = {LE_ITEM_ARMOR_GENERIC, LE_ITEM_ARMOR_CLOTH},
        weapons = {LE_ITEM_WEAPON_SWORD1H, LE_ITEM_WEAPON_DAGGER, LE_ITEM_WEAPON_WAND, LE_ITEM_WEAPON_STAFF},
        specs = {
            -- Arcane
            {role = Self.ROLE_RANGED,   attribute = LE_UNIT_STAT_INTELLECT, artifact = {id = 127857, relics = {RELIC_SLOT_TYPE_ARCANE, RELIC_SLOT_TYPE_FROST, RELIC_SLOT_TYPE_ARCANE}}},
            -- Fire
            {role = Self.ROLE_RANGED,   attribute = LE_UNIT_STAT_INTELLECT, artifact = {id = 128820, relics = {RELIC_SLOT_TYPE_FIRE, RELIC_SLOT_TYPE_ARCANE, RELIC_SLOT_TYPE_FIRE}}},
            -- Frost
            {role = Self.ROLE_RANGED,   attribute = LE_UNIT_STAT_INTELLECT, artifact = {id = 128862, relics = {RELIC_SLOT_TYPE_FROST, RELIC_SLOT_TYPE_ARCANE, RELIC_SLOT_TYPE_FROST}}}
        }
    },
    [Unit.MONK] = {
        armor = {LE_ITEM_ARMOR_GENERIC, LE_ITEM_ARMOR_LEATHER},
        weapons = {LE_ITEM_WEAPON_AXE1H, LE_ITEM_WEAPON_MACE1H, LE_ITEM_WEAPON_SWORD1H, LE_ITEM_WEAPON_UNARMED, LE_ITEM_WEAPON_POLEARM, LE_ITEM_WEAPON_STAFF},
        specs = {
            -- Brewmaster
            {role = Self.ROLE_TANK,     attribute = LE_UNIT_STAT_AGILITY,   artifact = {id = 128938, relics = {RELIC_SLOT_TYPE_LIFE, RELIC_SLOT_TYPE_WIND, RELIC_SLOT_TYPE_IRON}}},
            -- Mistweaver
            {role = Self.ROLE_HEAL,     attribute = LE_UNIT_STAT_INTELLECT, artifact = {id = 128937, relics = {RELIC_SLOT_TYPE_FROST, RELIC_SLOT_TYPE_LIFE, RELIC_SLOT_TYPE_WIND}}},
            -- Windwalker
            {role = Self.ROLE_MELEE,    attribute = LE_UNIT_STAT_AGILITY,   artifact = {id = 128940, relics = {RELIC_SLOT_TYPE_WIND, RELIC_SLOT_TYPE_IRON, RELIC_SLOT_TYPE_WIND}}}
        }
    },
    [Unit.PALADIN] = {
        armor = {LE_ITEM_ARMOR_GENERIC, LE_ITEM_ARMOR_PLATE, LE_ITEM_ARMOR_SHIELD},
        weapons = {LE_ITEM_WEAPON_AXE1H, LE_ITEM_WEAPON_MACE1H, LE_ITEM_WEAPON_SWORD1H, LE_ITEM_WEAPON_AXE2H, LE_ITEM_WEAPON_MACE2H, LE_ITEM_WEAPON_SWORD2H, LE_ITEM_WEAPON_POLEARM},
        specs = {
            -- Holy
            {role = Self.ROLE_HEAL,     attribute = LE_UNIT_STAT_INTELLECT, artifact = {id = 128823, relics = {RELIC_SLOT_TYPE_HOLY, RELIC_SLOT_TYPE_LIFE, RELIC_SLOT_TYPE_HOLY}}},
            -- Protection
            {role = Self.ROLE_TANK,     attribute = LE_UNIT_STAT_STRENGTH,  artifact = {id = 128866, relics = {RELIC_SLOT_TYPE_HOLY, RELIC_SLOT_TYPE_IRON, RELIC_SLOT_TYPE_ARCANE}}},
            -- Retribution
            {role = Self.ROLE_MELEE,    attribute = LE_UNIT_STAT_STRENGTH,  artifact = {id = 120978, relics = {RELIC_SLOT_TYPE_HOLY, RELIC_SLOT_TYPE_FIRE, RELIC_SLOT_TYPE_HOLY}}}
        }
    },
    [Unit.PRIEST] = {
        armor = {LE_ITEM_ARMOR_GENERIC, LE_ITEM_ARMOR_CLOTH},
        weapons = {LE_ITEM_WEAPON_MACE1H, LE_ITEM_WEAPON_DAGGER, LE_ITEM_WEAPON_WAND, LE_ITEM_WEAPON_STAFF},
        specs = {
            -- Discipline
            {role = Self.ROLE_HEAL,     attribute = LE_UNIT_STAT_INTELLECT, artifact = {id = 128868, relics = {RELIC_SLOT_TYPE_HOLY, RELIC_SLOT_TYPE_SHADOW, RELIC_SLOT_TYPE_HOLY}}},
            -- Holy
            {role = Self.ROLE_HEAL,     attribute = LE_UNIT_STAT_INTELLECT, artifact = {id = 128825, relics = {RELIC_SLOT_TYPE_HOLY, RELIC_SLOT_TYPE_LIFE, RELIC_SLOT_TYPE_HOLY}}},
            -- Shadow
            {role = Self.ROLE_RANGED,   attribute = LE_UNIT_STAT_INTELLECT, artifact = {id = 128827, relics = {RELIC_SLOT_TYPE_SHADOW, RELIC_SLOT_TYPE_BLOOD, RELIC_SLOT_TYPE_SHADOW}}}
        }
    },
    [Unit.ROGUE] = {
        armor = {LE_ITEM_ARMOR_GENERIC, LE_ITEM_ARMOR_LEATHER},
        weapons = {LE_ITEM_WEAPON_AXE1H, LE_ITEM_WEAPON_MACE1H, LE_ITEM_WEAPON_SWORD1H, LE_ITEM_WEAPON_DAGGER, LE_ITEM_WEAPON_UNARMED, LE_ITEM_WEAPON_THROWN},
        specs = {
            -- Assassination
            {role = Self.ROLE_MELEE,    attribute = LE_UNIT_STAT_AGILITY,   artifact = {id = 128870, relics = {RELIC_SLOT_TYPE_SHADOW, RELIC_SLOT_TYPE_IRON, RELIC_SLOT_TYPE_BLOOD}}},
            -- Outlaw
            {role = Self.ROLE_MELEE,    attribute = LE_UNIT_STAT_AGILITY,   artifact = {id = 128872, relics = {RELIC_SLOT_TYPE_BLOOD, RELIC_SLOT_TYPE_IRON, RELIC_SLOT_TYPE_WIND}}},
            -- Subtlety
            {role = Self.ROLE_MELEE,    attribute = LE_UNIT_STAT_AGILITY,   artifact = {id = 128476, relics = {RELIC_SLOT_TYPE_FEL, RELIC_SLOT_TYPE_SHADOW, RELIC_SLOT_TYPE_FEL}}}
        }
    },
    [Unit.SHAMAN] = {
        armor = {LE_ITEM_ARMOR_GENERIC, LE_ITEM_ARMOR_MAIL, LE_ITEM_ARMOR_SHIELD},
        weapons = {LE_ITEM_WEAPON_AXE1H, LE_ITEM_WEAPON_MACE1H, LE_ITEM_WEAPON_DAGGER, LE_ITEM_WEAPON_UNARMED, LE_ITEM_WEAPON_AXE2H, LE_ITEM_WEAPON_MACE2H, LE_ITEM_WEAPON_STAFF},
        specs = {
            -- Elemental
            {role = Self.ROLE_RANGED,   attribute = LE_UNIT_STAT_INTELLECT, artifact = {id = 128935, relics = {RELIC_SLOT_TYPE_WIND, RELIC_SLOT_TYPE_FROST, RELIC_SLOT_TYPE_WIND}}},
            -- Enhancement
            {role = Self.ROLE_MELEE,    attribute = LE_UNIT_STAT_AGILITY,   artifact = {id = 128819, relics = {RELIC_SLOT_TYPE_FIRE, RELIC_SLOT_TYPE_IRON, RELIC_SLOT_TYPE_WIND}}},
            -- Restoration
            {role = Self.ROLE_HEAL,     attribute = LE_UNIT_STAT_INTELLECT, artifact = {id = 128911, relics = {RELIC_SLOT_TYPE_LIFE, RELIC_SLOT_TYPE_FROST, RELIC_SLOT_TYPE_LIFE}}}
        }
    },
    [Unit.WARLOCK] = {
        armor = {LE_ITEM_ARMOR_GENERIC, LE_ITEM_ARMOR_CLOTH},
        weapons = {LE_ITEM_WEAPON_SWORD1H, LE_ITEM_WEAPON_DAGGER, LE_ITEM_WEAPON_WAND, LE_ITEM_WEAPON_STAFF},
        specs = {
            -- Affliction
            {role = Self.ROLE_RANGED,   attribute = LE_UNIT_STAT_INTELLECT, artifact = {id = 128942, relics = {RELIC_SLOT_TYPE_SHADOW, RELIC_SLOT_TYPE_BLOOD, RELIC_SLOT_TYPE_SHADOW}}},
            -- Demonology
            {role = Self.ROLE_RANGED,   attribute = LE_UNIT_STAT_INTELLECT, artifact = {id = 128943, relics = {RELIC_SLOT_TYPE_SHADOW, RELIC_SLOT_TYPE_FIRE, RELIC_SLOT_TYPE_FEL}}},
            -- Destruction
            {role = Self.ROLE_RANGED,   attribute = LE_UNIT_STAT_INTELLECT, artifact = {id = 128941, relics = {RELIC_SLOT_TYPE_FEL, RELIC_SLOT_TYPE_FIRE, RELIC_SLOT_TYPE_FEL}}}
        }
    },
    [Unit.WARRIOR] = {
        armor = {LE_ITEM_ARMOR_GENERIC, LE_ITEM_ARMOR_PLATE, LE_ITEM_ARMOR_SHIELD},
        weapons = {LE_ITEM_WEAPON_AXE1H, LE_ITEM_WEAPON_MACE1H, LE_ITEM_WEAPON_SWORD1H, LE_ITEM_WEAPON_DAGGER, LE_ITEM_WEAPON_UNARMED, LE_ITEM_WEAPON_AXE2H, LE_ITEM_WEAPON_MACE2H, LE_ITEM_WEAPON_SWORD2H, LE_ITEM_WEAPON_POLEARM, LE_ITEM_WEAPON_STAFF, LE_ITEM_WEAPON_BOWS, LE_ITEM_WEAPON_CROSSBOW, LE_ITEM_WEAPON_GUNS, LE_ITEM_WEAPON_THROWN},
        specs = {
            -- Arms
            {role = Self.ROLE_MELEE,    attribute = LE_UNIT_STAT_STRENGTH,  artifact = {id = 128910, relics = {RELIC_SLOT_TYPE_IRON, RELIC_SLOT_TYPE_BLOOD, RELIC_SLOT_TYPE_SHADOW}}},
            -- Fury
            {role = Self.ROLE_MELEE,    attribute = LE_UNIT_STAT_STRENGTH,  artifact = {id = 128908, relics = {RELIC_SLOT_TYPE_FIRE, RELIC_SLOT_TYPE_WIND, RELIC_SLOT_TYPE_IRON}}},
            -- Protection
            {role = Self.ROLE_TANK,     attribute = LE_UNIT_STAT_STRENGTH,  artifact = {id = 128289, relics = {RELIC_SLOT_TYPE_IRON, RELIC_SLOT_TYPE_BLOOD, RELIC_SLOT_TYPE_FIRE}}}
        }
    }
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
Self.TYPE_RANGEDRIGHT = "INVTYPE_RANGEDRIGHT"
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
    [Self.TYPE_RANGEDRIGHT] = {INVSLOT_RANGED},
    [Self.TYPE_ROBE] = {INVSLOT_CHEST},
    [Self.TYPE_SHIELD] = {INVSLOT_OFFHAND},
    [Self.TYPE_SHOULDER] = {INVSLOT_SHOULDER},
    [Self.TYPE_TABARD] = {INVSLOT_TABARD},
    [Self.TYPE_THROWN] = {INVSLOT_RANGED},
    [Self.TYPE_TRINKET] = {INVSLOT_TRINKET1, INVSLOT_TRINKET2},
    [Self.TYPE_WAIST] = {INVSLOT_WAIST},
    [Self.TYPE_WEAPON] = {INVSLOT_MAINHAND, INVSLOT_OFFHAND},
    [Self.TYPE_WEAPONMAINHAND] = {INVSLOT_MAINHAND},
    [Self.TYPE_WEAPONOFFHAND] = {INVSLOT_OFFHAND},
    [Self.TYPE_WRIST] = {INVSLOT_WRIST}
}

-------------------------------------------------------
--                     Trinkets                      --
-------------------------------------------------------

-- Trinket types
Self.TRINKET_STR = LE_UNIT_STAT_STRENGTH    -- 1
Self.TRINKET_AGI = LE_UNIT_STAT_AGILITY     -- 2
Self.TRINKET_INT = LE_UNIT_STAT_INTELLECT   -- 4
Self.TRINKET_HEAL = Self.ROLE_HEAL          -- 5
Self.TRINKET_TANK = Self.ROLE_TANK          -- 6

-- From WoWHead:
-- Type: Trinket
-- Quality: Rare, Epic
-- Usable by: Both, -, <Type>
-- Added in expansion: <current expansion>
-- ID: > 0
-- Source type: Drop
-- => C&P into Google Sheets
-- E.g.: http://www.wowhead.com/trinkets/side:3/role:1/quality:3:4?filter=166:151:128;7:1:4;0:0:0
-- Clean up INT DPS trinkets afterwards, because there are probably some healing trinkets in there

Self.TRINKETS = {
    [Self.TRINKET_STR] = {
        [131799] = true, -- Zugdug's Piece of Paradise
        [151307] = true, -- Void Stalker's Contract
        [137338] = true, -- Shard of Rokmora
        [137312] = true, -- Nightmare Egg Shell
        [133644] = true, -- Memento of Angerboda
        [129163] = true, -- Lost Etin's Strength
        [130126] = true, -- Iron Branch
        [136975] = true, -- Hunger of the Pack
        [133647] = true, -- Gift of Radiance
        [144482] = true, -- Fel-Oiled Infernal Machine
        [136978] = true, -- Ember of Nullification
        [144122] = true, -- Carbonic Carbuncle
        [151312] = true, -- Ampoule of Pure Void
        [147011] = true, -- Vial of Ceaseless Toxins
        [139328] = true, -- Ursoc's Rending Paw
        [151190] = true, -- Specter of Betrayal
        [150526] = true, -- Shadowmoon Insignia
        [156310] = true, -- Mjolnir Runestone
        [140799] = true, -- Might of Krosus
        [141586] = true, -- Marfisi's Giant Censer
        [150527] = true, -- Madness of the Betrayer
        [154176] = true, -- Khaz'goroth's Courage
        [139324] = true, -- Goblet of Nightmarish Ichor
        [147022] = true, -- Feverish Carapace
        [140797] = true, -- Fang of Tichondrius
        [153544] = true, -- Eye of F'harg
        [142167] = true, -- Eye of Command
        [141535] = true, -- Ettin Fingernail
        [140796] = true, -- Entwined Elemental Foci
        [151977] = true, -- Diima's Glacial Aegis
        [140806] = true, -- Convergence of Fates
        [140790] = true, -- Claw of the Crystalline Scorpid
        [142508] = true, -- Chains of the Valorous
        [142159] = true, -- Bloodstained Handkerchief
        [154173] = true, -- Aggramar's Conviction
        [151968] = true, -- Shadow-Singed Fang
    },

    [Self.TRINKET_INT] = {
        [144136] = true, -- Vision of the Predator
        [144157] = true, -- Vial of Ichorous Blood
        [137367] = true, -- Stormsinger Fulmination Charge
        [151310] = true, -- Reality Breacher
        [137398] = true, -- Portable Manacracker
        [140400] = true, -- Perfect Dreamgrove BlossomDruid
        [137462] = true, -- Jewel of Insatiable Desire
        [137485] = true, -- Infernal Writ
        [144480] = true, -- Dreadstone of Endless Shadows
        [129056] = true, -- Dreadlord's Hamstring
        [140809] = true, -- Whispers in the Dark
        [139323] = true, -- Twisting Wind
        [147019] = true, -- Tome of Unraveling Sanity
        [150522] = true, -- The Skull of Gul'dan
        [140804] = true, -- Star Gate
        [151971] = true, -- Sheath of Asara
        [156187] = true, -- Scale of Fates
        [141536] = true, -- Padawsen's Unlucky Charm
        [141584] = true, -- Eyasu's Mulligan
        [140792] = true, -- Erratic Metronome
        [156021] = true, -- Energy Siphon
        [156288] = true, -- Elemental Focus Stone
        [142165] = true, -- Deteriorated Construct Core
        [147002] = true, -- Charm of the Rising Tide
        [147005] = true, -- Chalice of Moonlight
        [142507] = true, -- Brinewater Slime in a Bottle
        [151955] = true, -- Acrid Catalyst Injector
    },

    [Self.TRINKET_AGI] = {
        [144113] = true, -- Windswept Pages
        [151307] = true, -- Void Stalker's Contract
        [137537] = true, -- Tirathon's Betrayal
        [137373] = true, -- Tempered Egg of Serpentrix
        [137367] = true, -- Stormsinger Fulmination Charge
        [144477] = true, -- Splinters of Agronox
        [137338] = true, -- Shard of Rokmora
        [140400] = true, -- Perfect Dreamgrove BlossomDruid
        [137312] = true, -- Nightmare Egg Shell
        [121808] = true, -- Nether Conductors
        [133644] = true, -- Memento of Angerboda
        [136975] = true, -- Hunger of the Pack
        [129091] = true, -- Golza's Iron Fin
        [133647] = true, -- Gift of Radiance
        [136978] = true, -- Ember of Nullification
        [151312] = true, -- Ampoule of Pure Void
        [147011] = true, -- Vial of Ceaseless Toxins
        [139323] = true, -- Twisting Wind
        [147019] = true, -- Tome of Unraveling Sanity
        [141537] = true, -- Thrice-Accursed Compass
        [151190] = true, -- Specter of Betrayal
        [141585] = true, -- Six-Feather Fan
        [150526] = true, -- Shadowmoon Insignia
        [140802] = true, -- Nightblooming Frond
        [156310] = true, -- Mjolnir Runestone
        [150527] = true, -- Madness of the Betrayer
        [154174] = true, -- Golganneth's Vitality
        [139324] = true, -- Goblet of Nightmarish Ichor
        [147022] = true, -- Feverish Carapace
        [140797] = true, -- Fang of Tichondrius
        [142506] = true, -- Eye of Guarm
        [153544] = true, -- Eye of F'harg
        [142167] = true, -- Eye of Command
        [139630] = true, -- Etching of SargerasDemon Hunter
        [140796] = true, -- Entwined Elemental Foci
        [151977] = true, -- Diima's Glacial Aegis
        [142165] = true, -- Deteriorated Construct Core
        [140806] = true, -- Convergence of Fates
        [139329] = true, -- Bloodthirsty Instinct
        [142159] = true, -- Bloodstained Handkerchief
        [140794] = true, -- Arcanogolem Digit
        [154173] = true, -- Aggramar's Conviction
        [151968] = true, -- Shadow-Singed Fang
    },

    [Self.TRINKET_HEAL] = {
        [144136] = true, -- Vision of the Predator
        [144157] = true, -- Vial of Ichorous Blood
        [137452] = true, -- Thrumming Gossamer
        [137367] = true, -- Stormsinger Fulmination Charge
        [151310] = true, -- Reality Breacher
        [144159] = true, -- Price of Progress
        [137398] = true, -- Portable Manacracker
        [140400] = true, -- Perfect Dreamgrove BlossomDruid
        [137462] = true, -- Jewel of Insatiable Desire
        [137485] = true, -- Infernal Writ
        [137484] = true, -- Flask of the Solemn Night
        [151340] = true, -- Echo of L'ura
        [144480] = true, -- Dreadstone of Endless Shadows
        [129056] = true, -- Dreadlord's Hamstring
        [136714] = true, -- Amalgam's Seventh Spine
        [140809] = true, -- Whispers in the Dark
        [139323] = true, -- Twisting Wind
        [147019] = true, -- Tome of Unraveling Sanity
        [150522] = true, -- The Skull of Gul'dan
        [151958] = true, -- Tarratus Keystone
        [140804] = true, -- Star Gate
        [156277] = true, -- Spark of Hope
        [156245] = true, -- Show of Faith
        [151971] = true, -- Sheath of Asara
        [156187] = true, -- Scale of Fates
        [141536] = true, -- Padawsen's Unlucky Charm
        [150523] = true, -- Memento of Tyrande
        [151956] = true, -- Garothi Feedback Conduit
        [142162] = true, -- Fluctuating Energy
        [141584] = true, -- Eyasu's Mulligan
        [140803] = true, -- Etraeus' Celestial Map
        [140792] = true, -- Erratic Metronome
        [140805] = true, -- Ephemeral Paradox
        [154175] = true, -- Eonar's Compassion
        [156021] = true, -- Energy Siphon
        [156288] = true, -- Elemental Focus Stone
        [142165] = true, -- Deteriorated Construct Core
        [139322] = true, -- Cocoon of Enforced Solitude
        [147002] = true, -- Charm of the Rising Tide
        [147005] = true, -- Chalice of Moonlight
        [151960] = true, -- Carafe of Searing Light
        [142507] = true, -- Brinewater Slime in a Bottle
        [147003] = true, -- Barbaric Mindslaver
        [151955] = true, -- Acrid Catalyst Injector
        [140793] = true, -- Perfectly Preserved Cake
    },

    [Self.TRINKET_TANK] = {
        [131799] = true, -- Zugdug's Piece of Paradise
        [144113] = true, -- Windswept Pages
        [151307] = true, -- Void Stalker's Contract
        [137537] = true, -- Tirathon's Betrayal
        [137373] = true, -- Tempered Egg of Serpentrix
        [137367] = true, -- Stormsinger Fulmination Charge
        [144477] = true, -- Splinters of Agronox
        [137338] = true, -- Shard of Rokmora
        [140400] = true, -- Perfect Dreamgrove BlossomDruid
        [137312] = true, -- Nightmare Egg Shell
        [121808] = true, -- Nether Conductors
        [133644] = true, -- Memento of Angerboda
        [129163] = true, -- Lost Etin's Strength
        [130126] = true, -- Iron Branch
        [136975] = true, -- Hunger of the Pack
        [129091] = true, -- Golza's Iron Fin
        [133647] = true, -- Gift of Radiance
        [144482] = true, -- Fel-Oiled Infernal Machine
        [136978] = true, -- Ember of Nullification
        [144122] = true, -- Carbonic Carbuncle
        [151312] = true, -- Ampoule of Pure Void
        [147011] = true, -- Vial of Ceaseless Toxins
        [139328] = true, -- Ursoc's Rending Paw
        [139323] = true, -- Twisting Wind
        [147019] = true, -- Tome of Unraveling Sanity
        [141537] = true, -- Thrice-Accursed Compass
        [151190] = true, -- Specter of Betrayal
        [141585] = true, -- Six-Feather Fan
        [150526] = true, -- Shadowmoon Insignia
        [140802] = true, -- Nightblooming Frond
        [156310] = true, -- Mjolnir Runestone
        [140799] = true, -- Might of Krosus
        [141586] = true, -- Marfisi's Giant Censer
        [150527] = true, -- Madness of the Betrayer
        [154176] = true, -- Khaz'goroth's Courage
        [154174] = true, -- Golganneth's Vitality
        [139324] = true, -- Goblet of Nightmarish Ichor
        [147022] = true, -- Feverish Carapace
        [140797] = true, -- Fang of Tichondrius
        [142506] = true, -- Eye of Guarm
        [153544] = true, -- Eye of F'harg
        [142167] = true, -- Eye of Command
        [141535] = true, -- Ettin Fingernail
        [139630] = true, -- Etching of SargerasDemon Hunter
        [140796] = true, -- Entwined Elemental Foci
        [151977] = true, -- Diima's Glacial Aegis
        [142165] = true, -- Deteriorated Construct Core
        [140806] = true, -- Convergence of Fates
        [140790] = true, -- Claw of the Crystalline Scorpid
        [142508] = true, -- Chains of the Valorous
        [142159] = true, -- Bloodstained Handkerchief
        [140794] = true, -- Arcanogolem Digit
        [154173] = true, -- Aggramar's Conviction
        [142169] = true, -- Raven Eidolon
        [151978] = true, -- Smoldering Titanguard
        [151975] = true, -- Apocalypse Drive
    }
}