---@type Addon
local Addon = select(2, ...)
local GUI, Unit, Util = Addon.GUI, Addon.Unit, Addon.Util
---@type Item
local Self = Addon.Item

local Armor = Enum.ItemArmorSubclass
local Weapon = Enum.ItemWeaponSubclass

-- Expac IDs
Self.EXPAC_CLASSIC = 0
Self.EXPAC_BC = 1
Self.EXPAC_WOTLK = 2
Self.EXPAC_CATA = 3
Self.EXPAC_MOP = 4
Self.EXPAC_WOD = 5
Self.EXPAC_LEGION = 6
Self.EXPAC_BFA = 7
Self.EXPAC_SL = 8

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
Self.TYPE_RANGED = "INVTYPE_RANGED"
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

-- All types that get special treatment
Self.TYPES_WEAPON = { Self.TYPE_WEAPON, Self.TYPE_WEAPONMAINHAND, Self.TYPE_WEAPONOFFHAND, Self.TYPE_HOLDABLE, Self.TYPE_2HWEAPON, Self.TYPE_RANGED, Self.TYPE_RANGEDRIGHT, Self.TYPE_THROWN }
Self.TYPES_OFFHAND = { Self.TYPE_WEAPONOFFHAND, Self.TYPE_HOLDABLE }
Self.TYPES_1HWEAPON = { Self.TYPE_WEAPON, Self.TYPE_WEAPONMAINHAND, Self.TYPE_WEAPONOFFHAND, Self.TYPE_HOLDABLE }
Self.TYPES_2HWEAPON = { Self.TYPE_2HWEAPON }
Self.TYPES_RANGED = { Self.TYPE_RANGED, Self.TYPE_RANGEDRIGHT, Self.TYPE_THROWN }
Self.TYPES_NO_TRANSMOG = { Self.TYPE_NECK, Self.TYPE_FINGER, Self.TYPE_TRINKET }

-- Armor inventory slots
Self.SLOTS = {
    [Self.TYPE_2HWEAPON] = { INVSLOT_MAINHAND },
    [Self.TYPE_BODY] = { INVSLOT_BODY },
    [Self.TYPE_CHEST] = { INVSLOT_CHEST },
    [Self.TYPE_CLOAK] = { INVSLOT_BACK },
    [Self.TYPE_FEET] = { INVSLOT_FEET },
    [Self.TYPE_FINGER] = { INVSLOT_FINGER1, INVSLOT_FINGER2 },
    [Self.TYPE_HAND] = { INVSLOT_HAND },
    [Self.TYPE_HEAD] = { INVSLOT_HEAD },
    [Self.TYPE_HOLDABLE] = { INVSLOT_OFFHAND },
    [Self.TYPE_LEGS] = { INVSLOT_LEGS },
    [Self.TYPE_NECK] = { INVSLOT_NECK },
    [Self.TYPE_RANGED] = { INVSLOT_MAINHAND },
    [Self.TYPE_RANGEDRIGHT] = { INVSLOT_MAINHAND },
    [Self.TYPE_ROBE] = { INVSLOT_CHEST },
    [Self.TYPE_SHIELD] = { INVSLOT_OFFHAND },
    [Self.TYPE_SHOULDER] = { INVSLOT_SHOULDER },
    [Self.TYPE_TABARD] = { INVSLOT_TABARD },
    [Self.TYPE_THROWN] = { INVSLOT_MAINHAND },
    [Self.TYPE_TRINKET] = { INVSLOT_TRINKET1, INVSLOT_TRINKET2 },
    [Self.TYPE_WAIST] = { INVSLOT_WAIST },
    [Self.TYPE_WEAPON] = { INVSLOT_MAINHAND, INVSLOT_OFFHAND },
    [Self.TYPE_WEAPONMAINHAND] = { INVSLOT_MAINHAND },
    [Self.TYPE_WEAPONOFFHAND] = { INVSLOT_OFFHAND },
    [Self.TYPE_WRIST] = { INVSLOT_WRIST }
}

-- Primary stats
Self.ATTRIBUTES = {
    LE_UNIT_STAT_STRENGTH, -- 1
    LE_UNIT_STAT_AGILITY, -- 2
    --  LE_UNIT_STAT_STAMINA,  -- 3
    LE_UNIT_STAT_INTELLECT -- 4
}

-- Roles
Self.ROLE_HEAL = 16
Self.ROLE_TANK = 32
Self.ROLE_MELEE = 64
Self.ROLE_RANGED = 128

-- Which class/spec can equip what
Self.CLASSES = {
    [Unit.DEATH_KNIGHT] = {
        armor = { Armor.Generic, Armor.Plate },
        weapons = { Weapon.Axe1H, Weapon.Mace1H, Weapon.Sword1H, Weapon.Axe2H, Weapon.Mace2H, Weapon.Sword2H, Weapon.Polearm },
        specs = {
            { -- Blood
              role = Self.ROLE_TANK,
              attribute = LE_UNIT_STAT_STRENGTH,
              weapons = Self.TYPES_2HWEAPON,
              artifact = { id = 128402, relics = { RELIC_SLOT_TYPE_BLOOD, RELIC_SLOT_TYPE_SHADOW, RELIC_SLOT_TYPE_IRON } }
            },
            { -- Frost
              role = Self.ROLE_MELEE,
              attribute = LE_UNIT_STAT_STRENGTH,
              dualWield = true,
              artifact = { id = 128292, relics = { RELIC_SLOT_TYPE_FROST, RELIC_SLOT_TYPE_SHADOW, RELIC_SLOT_TYPE_FROST }, twinId = 128293 }
            },
            { -- Unholy
              role = Self.ROLE_MELEE,
              attribute = LE_UNIT_STAT_STRENGTH,
              weapons = Self.TYPES_2HWEAPON,
              artifact = { id = 128403, relics = { RELIC_SLOT_TYPE_FIRE, RELIC_SLOT_TYPE_SHADOW, RELIC_SLOT_TYPE_BLOOD } }
            }
        }
    },
    [Unit.DEMON_HUNTER] = {
        armor = { Armor.Generic, Armor.Leather },
        weapons = { Weapon.Axe1H, Weapon.Sword1H, Weapon.Warglaive, Weapon.Dagger, Weapon.Unarmed },
        specs = {
            { -- Havoc
              role = Self.ROLE_MELEE,
              attribute = LE_UNIT_STAT_AGILITY,
              artifact = { id = 127829, relics = { RELIC_SLOT_TYPE_FEL, RELIC_SLOT_TYPE_SHADOW, RELIC_SLOT_TYPE_FEL }, twinId = 127830 }
            },
            { -- Vengeance
              role = Self.ROLE_TANK,
              attribute = LE_UNIT_STAT_AGILITY,
              artifact = { id = 128832, relics = { RELIC_SLOT_TYPE_IRON, RELIC_SLOT_TYPE_ARCANE, RELIC_SLOT_TYPE_FEL }, twinId = 128831 }
            }
        }
    },
    [Unit.DRUID] = {
        armor = { Armor.Generic, Armor.Leather },
        weapons = { Weapon.Mace1H, Weapon.Dagger, Weapon.Unarmed, Weapon.Polearm, Weapon.Staff },
        specs = {
            { -- Balance
              role = Self.ROLE_RANGED,
              attribute = LE_UNIT_STAT_INTELLECT,
              artifact = { id = 128858, relics = { RELIC_SLOT_TYPE_ARCANE, RELIC_SLOT_TYPE_LIFE, RELIC_SLOT_TYPE_ARCANE } }
            },
            { -- Feral
              role = Self.ROLE_MELEE,
              attribute = LE_UNIT_STAT_AGILITY,
              artifact = { id = 128860, relics = { RELIC_SLOT_TYPE_FROST, RELIC_SLOT_TYPE_BLOOD, RELIC_SLOT_TYPE_LIFE }, twinId = 128859 }
            },
            { -- Guardian
              role = Self.ROLE_TANK,
              attribute = LE_UNIT_STAT_AGILITY,
              artifact = { id = 128821, relics = { RELIC_SLOT_TYPE_FIRE, RELIC_SLOT_TYPE_BLOOD, RELIC_SLOT_TYPE_LIFE }, twinId = 128822 }
            },
            { -- Restoration
              role = Self.ROLE_HEAL,
              attribute = LE_UNIT_STAT_INTELLECT,
              artifact = { id = 128306, relics = { RELIC_SLOT_TYPE_LIFE, RELIC_SLOT_TYPE_FROST, RELIC_SLOT_TYPE_LIFE } }
            }
        }
    },
    [Unit.EVOKER] = {
        armor = { Armor.Generic, Armor.Mail },
        weapons = { Weapon.Axe1H, Weapon.Mace1H, Weapon.Sword1H, Weapon.Dagger, Weapon.Unarmed, Weapon.Polearm, Weapon.Staff },
        specs = {
            { -- Devastation
              role = Self.ROLE_RANGED,
              attribute = LE_UNIT_STAT_INTELLECT,
              artifact = { id = 0, relics = {} }
            },
            { -- Preservation
              role = Self.ROLE_HEAL,
              attribute = LE_UNIT_STAT_INTELLECT,
              artifact = { id = 0, relics = {} }
            },
        }
    },
    [Unit.HUNTER] = {
        armor = { Armor.Generic, Armor.Mail },
        weapons = { Weapon.Axe1H, Weapon.Sword1H, Weapon.Dagger, Weapon.Unarmed, Weapon.Polearm, Weapon.Staff, Weapon.Bows, Weapon.Crossbow, Weapon.Guns },
        specs = {
            { -- Beast Mastery
              role = Self.ROLE_RANGED,
              attribute = LE_UNIT_STAT_AGILITY,
              weapons = Self.TYPES_RANGED,
              artifact = { id = 128861, relics = { RELIC_SLOT_TYPE_WIND, RELIC_SLOT_TYPE_ARCANE, RELIC_SLOT_TYPE_IRON } }
            },
            { -- Marksmanship
              role = Self.ROLE_RANGED,
              attribute = LE_UNIT_STAT_AGILITY,
              weapons = Self.TYPES_RANGED,
              artifact = { id = 128826, relics = { RELIC_SLOT_TYPE_WIND, RELIC_SLOT_TYPE_BLOOD, RELIC_SLOT_TYPE_LIFE } }
            },
            { -- Survival
              role = Self.ROLE_MELEE,
              attribute = LE_UNIT_STAT_AGILITY,
              dualWield = true,
              artifact = { id = 128808, relics = { RELIC_SLOT_TYPE_WIND, RELIC_SLOT_TYPE_IRON, RELIC_SLOT_TYPE_BLOOD } }
            }
        }
    },
    [Unit.MAGE] = {
        armor = { Armor.Generic, Armor.Cloth },
        weapons = { Weapon.Sword1H, Weapon.Dagger, Weapon.Wand, Weapon.Staff },
        specs = {
            { -- Arcane
              role = Self.ROLE_RANGED,
              attribute = LE_UNIT_STAT_INTELLECT,
              artifact = { id = 127857, relics = { RELIC_SLOT_TYPE_ARCANE, RELIC_SLOT_TYPE_FROST, RELIC_SLOT_TYPE_ARCANE } }
            },
            { -- Fire
              role = Self.ROLE_RANGED,
              attribute = LE_UNIT_STAT_INTELLECT,
              artifact = { id = 128820, relics = { RELIC_SLOT_TYPE_FIRE, RELIC_SLOT_TYPE_ARCANE, RELIC_SLOT_TYPE_FIRE }, twinId = 133959 }
            },
            { -- Frost
              role = Self.ROLE_RANGED,
              attribute = LE_UNIT_STAT_INTELLECT,
              artifact = { id = 128862, relics = { RELIC_SLOT_TYPE_FROST, RELIC_SLOT_TYPE_ARCANE, RELIC_SLOT_TYPE_FROST } }
            }
        }
    },
    [Unit.MONK] = {
        armor = { Armor.Generic, Armor.Leather },
        weapons = { Weapon.Axe1H, Weapon.Mace1H, Weapon.Sword1H, Weapon.Unarmed, Weapon.Polearm, Weapon.Staff },
        specs = {
            { -- Brewmaster
              role = Self.ROLE_TANK,
              attribute = LE_UNIT_STAT_AGILITY,
              dualWield = true,
              artifact = { id = 128938, relics = { RELIC_SLOT_TYPE_LIFE, RELIC_SLOT_TYPE_WIND, RELIC_SLOT_TYPE_IRON } }
            },
            { -- Mistweaver
              role = Self.ROLE_HEAL,
              attribute = LE_UNIT_STAT_INTELLECT,
              artifact = { id = 128937, relics = { RELIC_SLOT_TYPE_FROST, RELIC_SLOT_TYPE_LIFE, RELIC_SLOT_TYPE_WIND } }
            },
            { -- Windwalker
              role = Self.ROLE_MELEE,
              attribute = LE_UNIT_STAT_AGILITY,
              dualWield = true,
              artifact = { id = 128940, relics = { RELIC_SLOT_TYPE_WIND, RELIC_SLOT_TYPE_IRON, RELIC_SLOT_TYPE_WIND }, twinId = 0 }
            }
        }
    },
    [Unit.PALADIN] = {
        armor = { Armor.Generic, Armor.Plate, Armor.Shield },
        weapons = { Weapon.Axe1H, Weapon.Mace1H, Weapon.Sword1H, Weapon.Axe2H, Weapon.Mace2H, Weapon.Sword2H, Weapon.Polearm },
        specs = {
            { -- Holy
              role = Self.ROLE_HEAL,
              attribute = LE_UNIT_STAT_INTELLECT,
              artifact = { id = 128823, relics = { RELIC_SLOT_TYPE_HOLY, RELIC_SLOT_TYPE_LIFE, RELIC_SLOT_TYPE_HOLY } }
            },
            { -- Protection
              role = Self.ROLE_TANK,
              attribute = LE_UNIT_STAT_STRENGTH,
              weapons = Self.TYPES_1HWEAPON,
              artifact = { id = 128866, relics = { RELIC_SLOT_TYPE_HOLY, RELIC_SLOT_TYPE_IRON, RELIC_SLOT_TYPE_ARCANE }, twinId = 0 }
            },
            { -- Retribution
              role = Self.ROLE_MELEE,
              attribute = LE_UNIT_STAT_STRENGTH,
              weapons = Self.TYPES_2HWEAPON,
              artifact = { id = 120978, relics = { RELIC_SLOT_TYPE_HOLY, RELIC_SLOT_TYPE_FIRE, RELIC_SLOT_TYPE_HOLY } }
            }
        }
    },
    [Unit.PRIEST] = {
        armor = { Armor.Generic, Armor.Cloth },
        weapons = { Weapon.Mace1H, Weapon.Dagger, Weapon.Wand, Weapon.Staff },
        specs = {
            { -- Discipline
              role = Self.ROLE_HEAL,
              attribute = LE_UNIT_STAT_INTELLECT,
              artifact = { id = 128868, relics = { RELIC_SLOT_TYPE_HOLY, RELIC_SLOT_TYPE_SHADOW, RELIC_SLOT_TYPE_HOLY } }
            },
            { -- Holy
              role = Self.ROLE_HEAL,
              attribute = LE_UNIT_STAT_INTELLECT,
              artifact = { id = 128825, relics = { RELIC_SLOT_TYPE_HOLY, RELIC_SLOT_TYPE_LIFE, RELIC_SLOT_TYPE_HOLY } }
            },
            { -- Shadow
              role = Self.ROLE_RANGED,
              attribute = LE_UNIT_STAT_INTELLECT,
              artifact = { id = 128827, relics = { RELIC_SLOT_TYPE_SHADOW, RELIC_SLOT_TYPE_BLOOD, RELIC_SLOT_TYPE_SHADOW }, twinId = 0 }
            }
        }
    },
    [Unit.ROGUE] = {
        armor = { Armor.Generic, Armor.Leather },
        weapons = { Weapon.Axe1H, Weapon.Mace1H, Weapon.Sword1H, Weapon.Dagger, Weapon.Unarmed, Weapon.Thrown },
        dualWield = true,
        specs = {
            { -- Assassination
              role = Self.ROLE_MELEE,
              attribute = LE_UNIT_STAT_AGILITY,
              artifact = { id = 128870, relics = { RELIC_SLOT_TYPE_SHADOW, RELIC_SLOT_TYPE_IRON, RELIC_SLOT_TYPE_BLOOD }, twinId = 0 }
            },
            { -- Outlaw
              role = Self.ROLE_MELEE,
              attribute = LE_UNIT_STAT_AGILITY,
              artifact = { id = 128872, relics = { RELIC_SLOT_TYPE_BLOOD, RELIC_SLOT_TYPE_IRON, RELIC_SLOT_TYPE_WIND }, twinId = 0 }
            },
            { -- Subtlety
              role = Self.ROLE_MELEE,
              attribute = LE_UNIT_STAT_AGILITY,
              artifact = { id = 128476, relics = { RELIC_SLOT_TYPE_FEL, RELIC_SLOT_TYPE_SHADOW, RELIC_SLOT_TYPE_FEL }, twinId = 0 }
            }
        }
    },
    [Unit.SHAMAN] = {
        armor = { Armor.Generic, Armor.Mail, Armor.Shield },
        weapons = { Weapon.Axe1H, Weapon.Mace1H, Weapon.Dagger, Weapon.Unarmed, Weapon.Axe2H, Weapon.Mace2H, Weapon.Staff },
        specs = {
            { -- Elemental
              role = Self.ROLE_RANGED,
              attribute = LE_UNIT_STAT_INTELLECT,
              artifact = { id = 128935, relics = { RELIC_SLOT_TYPE_WIND, RELIC_SLOT_TYPE_FROST, RELIC_SLOT_TYPE_WIND }, twinId = 0 }
            },
            { -- Enhancement
              role = Self.ROLE_MELEE,
              attribute = LE_UNIT_STAT_AGILITY,
              weapons = Self.TYPES_1HWEAPON,
              dualWield = true,
              artifact = { id = 128819, relics = { RELIC_SLOT_TYPE_FIRE, RELIC_SLOT_TYPE_IRON, RELIC_SLOT_TYPE_WIND } }
            },
            { -- Restoration
              role = Self.ROLE_HEAL,
              attribute = LE_UNIT_STAT_INTELLECT,
              artifact = { id = 128911, relics = { RELIC_SLOT_TYPE_LIFE, RELIC_SLOT_TYPE_FROST, RELIC_SLOT_TYPE_LIFE } }
            }
        }
    },
    [Unit.WARLOCK] = {
        armor = { Armor.Generic, Armor.Cloth },
        weapons = { Weapon.Sword1H, Weapon.Dagger, Weapon.Wand, Weapon.Staff },
        specs = {
            { -- Affliction
              role = Self.ROLE_RANGED,
              attribute = LE_UNIT_STAT_INTELLECT,
              artifact = { id = 128942, relics = { RELIC_SLOT_TYPE_SHADOW, RELIC_SLOT_TYPE_BLOOD, RELIC_SLOT_TYPE_SHADOW } }
            },
            { -- Demonology
              role = Self.ROLE_RANGED,
              attribute = LE_UNIT_STAT_INTELLECT,
              artifact = { id = 128943, relics = { RELIC_SLOT_TYPE_SHADOW, RELIC_SLOT_TYPE_FIRE, RELIC_SLOT_TYPE_FEL } }
            },
            { -- Destruction
              role = Self.ROLE_RANGED,
              attribute = LE_UNIT_STAT_INTELLECT,
              artifact = { id = 128941, relics = { RELIC_SLOT_TYPE_FEL, RELIC_SLOT_TYPE_FIRE, RELIC_SLOT_TYPE_FEL } }
            }
        }
    },
    [Unit.WARRIOR] = {
        armor = { Armor.Generic, Armor.Plate, Armor.Shield },
        weapons = { Weapon.Axe1H, Weapon.Mace1H, Weapon.Sword1H, Weapon.Dagger, Weapon.Unarmed, Weapon.Axe2H, Weapon.Mace2H, Weapon.Sword2H, Weapon.Polearm, Weapon.Staff, Weapon.Bows, Weapon.Crossbow, Weapon.Guns, Weapon.Thrown },
        specs = {
            { -- Arms
              role = Self.ROLE_MELEE,
              attribute = LE_UNIT_STAT_STRENGTH,
              weapons = Self.TYPES_2HWEAPON,
              dualWield = true,
              artifact = { id = 128910, relics = { RELIC_SLOT_TYPE_IRON, RELIC_SLOT_TYPE_BLOOD, RELIC_SLOT_TYPE_SHADOW } }
            },
            { -- Fury
              role = Self.ROLE_MELEE,
              attribute = LE_UNIT_STAT_STRENGTH,
              weapons = Self.TYPES_2HWEAPON,
              dualWield = true,
              artifact = { id = 128908, relics = { RELIC_SLOT_TYPE_FIRE, RELIC_SLOT_TYPE_WIND, RELIC_SLOT_TYPE_IRON } }
            },
            { -- Protection
              role = Self.ROLE_TANK,
              attribute = LE_UNIT_STAT_STRENGTH,
              weapons = Self.TYPES_1HWEAPON,
              artifact = { id = 128289, relics = { RELIC_SLOT_TYPE_IRON, RELIC_SLOT_TYPE_BLOOD, RELIC_SLOT_TYPE_FIRE } }
            }
        }
    }
}

-------------------------------------------------------
--                   Gear tokens                     --
-------------------------------------------------------

Self.GEAR_TOKENS = {
    -- T27: Sepulcher of the First Ones
    [191002] = Self.TYPE_HEAD,
    [191003] = Self.TYPE_HEAD,
    [191004] = Self.TYPE_HEAD,
    [191005] = Self.TYPE_HEAD,
    [191006] = Self.TYPE_SHOULDER,
    [191007] = Self.TYPE_SHOULDER,
    [191008] = Self.TYPE_SHOULDER,
    [191009] = Self.TYPE_SHOULDER,
    [191010] = Self.TYPE_CHEST,
    [191011] = Self.TYPE_CHEST,
    [191012] = Self.TYPE_CHEST,
    [191013] = Self.TYPE_CHEST,
    [191014] = Self.TYPE_HAND,
    [191015] = Self.TYPE_HAND,
    [191016] = Self.TYPE_HAND,
    [191017] = Self.TYPE_HAND,
    [191018] = Self.TYPE_LEGS,
    [191019] = Self.TYPE_LEGS,
    [191020] = Self.TYPE_LEGS,
    [191021] = Self.TYPE_LEGS,
    -- T28: Vault of the Incarnates
    [196586] = Self.TYPE_CHEST,
    [196587] = Self.TYPE_HAND,
    [196588] = Self.TYPE_LEGS,
    [196589] = Self.TYPE_SHOULDER,
    [196590] = Self.TYPE_HEAD,
    [196591] = Self.TYPE_CHEST,
    [196592] = Self.TYPE_HAND,
    [196593] = Self.TYPE_LEGS,
    [196594] = Self.TYPE_SHOULDER,
    [196595] = Self.TYPE_HEAD,
    [196596] = Self.TYPE_CHEST,
    [196597] = Self.TYPE_HAND,
    [196598] = Self.TYPE_LEGS,
    [196599] = Self.TYPE_SHOULDER,
    [196600] = Self.TYPE_HEAD,
    [196601] = Self.TYPE_CHEST,
    [196602] = Self.TYPE_HAND,
    [196603] = Self.TYPE_LEGS,
    [196604] = Self.TYPE_SHOULDER,
    [196605] = Self.TYPE_HEAD,

}

-------------------------------------------------------
--                     Trinkets                      --
-------------------------------------------------------

-- Trinket types
Self.TRINKET_STR = LE_UNIT_STAT_STRENGTH -- 1
Self.TRINKET_AGI = LE_UNIT_STAT_AGILITY -- 2
Self.TRINKET_INT = LE_UNIT_STAT_INTELLECT -- 4
Self.TRINKET_HEAL = Self.ROLE_HEAL -- 16
Self.TRINKET_TANK = Self.ROLE_TANK -- 32
Self.TRINKET_MELEE = Self.ROLE_MELEE -- 64
Self.TRINKET_RANGED = Self.ROLE_RANGED -- 128

-- Bit mask to check trinket list entries
Self.MASK_ATTR = 0x0f
Self.MASK_ROLE = 0xf0

-- The specs we use to scan for trinket types
Self.TRINKET_SPECS = {
    [Self.TRINKET_STR] = { Unit.WARRIOR, 1 }, -- Arms Warrior
    [Self.TRINKET_AGI] = { Unit.ROGUE, 1 }, -- Assasination Rogue
    [Self.TRINKET_INT] = { Unit.MAGE, 1 }, -- Arcane Mage
    [Self.TRINKET_RANGED] = { Unit.HUNTER, 2 }, -- Marksmanship Hunter
    [Self.TRINKET_HEAL] = { Unit.PRIEST, 2 }, -- Holy Priest
    [Self.TRINKET_TANK] = { Unit.WARRIOR, 3 } -- Protection Warrior
}

Self.TRINKET_UPDATE_TRIES = 2
Self.TRINKET_UPDATE_PER_TRY = 1

-- Completely rebuild the trinket list
---@param tier integer
---@param isRaid integer
---@param instance integer
---@param difficulty integer
function Self.UpdateTrinkets(tier, isRaid, instance, difficulty)
    tier = tier or 1
    isRaid = (isRaid == true or isRaid == 1) and 1 or 0
    instance = instance or 1
    difficulty = difficulty or 1

    local timeout = Self.TRINKET_UPDATE_TRIES * Self.TRINKET_UPDATE_PER_TRY

    -- New tier
    if isRaid == 0 and instance == 1 and difficulty == 1 then
        Addon:Info("Tier %d:", tier)
    end

    -- Go through all tiers, dungeon/raid, instances and difficulties
    for t = tier, EJ_GetNumTiers() do
        EJ_SelectTier(t)
        ---@diagnostic disable-next-line: count-down-loop
        for r = isRaid, 1 do
            while EJ_GetInstanceByIndex(instance, r == 1) do
                local i, name = EJ_GetInstanceByIndex(instance, r == 1)
                EJ_SelectInstance(i)
                for d = difficulty, 99 do
                    if EJ_IsValidInstanceDifficulty(d) then
                        Addon:Info("Scanning %q (%d, %d, %d)", name, t, i, d)
                        Self.UpdateInstanceTrinkets(t, i, d)
                        Addon.timers.trinketUpdate = PLR:ScheduleTimer(Self.UpdateTrinkets, timeout, t, r, instance, d + 1)
                        return Addon.timers.trinketUpdate
                    end
                end
                instance, difficulty = instance + 1, 1
            end
            instance = 1
        end
        isRaid = 0
    end

    Addon:Info("Updating trinkets complete!")
    Self.ExportTrinkets()
end

-- Cancel an ongoing update operation
function Self.CancelUpdateTrinkets()
    if Addon.timers.trinketUpdate then
        Addon:CancelTimer(Addon.timers.trinketUpdate)
    end
end

-- Update trinkets for one instance+difficulty
---@param tier integer
---@param instance integer
---@param difficulty integer
---@param timeLeft number?
function Self.UpdateInstanceTrinkets(tier, instance, difficulty, timeLeft)
    timeLeft = timeLeft or Self.TRINKET_UPDATE_TRIES * Self.TRINKET_UPDATE_PER_TRY
    if timeLeft < Self.TRINKET_UPDATE_PER_TRY then return end

    -- Prevent the encounter journal to interfere
    if _G.EncounterJournal then _G.EncounterJournal:UnregisterAllEvents() end

    EJ_SelectTier(tier)
    EJ_SelectInstance(instance)
    EJ_SetDifficulty(difficulty)
    C_EncounterJournal.SetSlotFilter(Enum.ItemSlotFilterType.Trinket)

    -- Get trinkets for all the reference specs
    local t = {}
    for n, info in pairs(Self.TRINKET_SPECS) do
        EJ_SetLootFilter(info[1], GetSpecializationInfoForClassID(unpack(info)))
        for i = 1, EJ_GetNumLoot() do
            local id = C_EncounterJournal.GetLootInfoByIndex(i).itemID
            t[id] = (t[id] or 0) + n
        end
    end

    -- Determine the least specific category for each trinket
    for id, v in pairs(t) do
        local str = bit.band(v, Self.TRINKET_STR)
        local agi = (bit.band(v, Self.TRINKET_AGI) > 0 or bit.band(v, Self.TRINKET_RANGED) > 0) and Self.TRINKET_AGI or 0
        local int = (bit.band(v, Self.TRINKET_INT) > 0 or bit.band(v, Self.TRINKET_HEAL) > 0) and Self.TRINKET_INT or 0
        local tank = bit.band(v, Self.TRINKET_TANK)
        local heal = bit.band(v, Self.TRINKET_HEAL)
        local melee = (bit.band(v, Self.TRINKET_STR) > 0 or bit.band(v, Self.TRINKET_AGI) > 0) and Self.TRINKET_MELEE or 0
        local ranged = (bit.band(v, Self.TRINKET_RANGED) > 0 or bit.band(v, Self.TRINKET_INT) > 0) and Self.TRINKET_RANGED or 0

        local attr, role = str + agi + int, tank + heal + melee + ranged
        attr = attr == Self.TRINKET_STR + Self.TRINKET_AGI + Self.TRINKET_INT and 0 or attr
        role = role == Self.TRINKET_TANK + Self.TRINKET_HEAL + Self.TRINKET_MELEE + Self.TRINKET_RANGED and 0 or role

        local cat = attr + role
        if cat > 0 then
            Self.TRINKETS[id] = cat
        end
    end

    -- Schedule retry
    if timeLeft >= Self.TRINKET_UPDATE_PER_TRY then
        Addon:ScheduleTimer(Self.UpdateInstanceTrinkets, Self.TRINKET_UPDATE_PER_TRY, tier, instance, difficulty, timeLeft - Self.TRINKET_UPDATE_PER_TRY)
    end
end

-- Export the trinkets list
---@param loaded boolean?
function Self.ExportTrinkets(loaded)
    if not loaded and next(Self.TRINKETS) then
        for id in pairs(Self.TRINKETS) do
            GetItemInfo(id)
        end
        Addon:ScheduleTimer(Self.ExportTrinkets, 1, true)
    else
        local keys = Util(Self.TRINKETS):Keys():Sort()()
        local txt = ""

        for _,id in ipairs(keys) do
            local cat = Self.TRINKETS[id]
            local pad = ("0"):rep(6 - strlen(tostring(id)))
            local space = (" "):rep(3 - strlen(cat))
            txt = txt .. ("\n    [%s%d] = %d, %s-- %s"):format(pad, id, cat, space, GetItemInfo(id) or "?")
        end

        GUI.ShowExportWindow("Export trinkets", "Self.TRINKETS = {" .. txt .. "\n}")
    end
end

Self.TRINKETS = {
  [011810] = 32,  -- Force of Will
  [011815] = 227, -- Hand of Justice
  [011819] = 20,  -- Second Wind
  [011832] = 20,  -- Burst of Knowledge
  [022321] = 227, -- Heart of Wyrmthalak
  [024376] = 32,  -- Runed Fungalcap
  [024390] = 20,  -- Auslese's Light Channeler
  [026055] = 20,  -- Oculus of the Hidden Eye
  [027416] = 32,  -- Fetish of the Fallen
  [027529] = 32,  -- Figurine of the Colossus
  [027683] = 148, -- Quagmirran's Eye
  [027770] = 32,  -- Argussian Compass
  [027828] = 20,  -- Warp-Scarab Brooch
  [027896] = 20,  -- Alembic of Infernal Power
  [028034] = 195, -- Hourglass of the Unraveller
  [028190] = 20,  -- Scarab of the Infinite Cycle
  [028223] = 148, -- Arcanist's Stone
  [028288] = 195, -- Abacus of Violent Odds
  [028370] = 20,  -- Bangle of Endless Blessings
  [028418] = 148, -- Shiffar's Nexus-Horn
  [028590] = 148, -- Ribbon of Sacrifice
  [028727] = 148, -- Pendant of the Violet Eye
  [028789] = 148, -- Eye of Magtheridon
  [028823] = 148, -- Eye of Gruul
  [028830] = 227, -- Dragonspine Trophy
  [030665] = 20,  -- Earring of Soulful Meditation
  [032483] = 148, -- The Skull of Gul'dan
  [032496] = 148, -- Memento of Tyrande
  [032505] = 227, -- Madness of the Betrayer
  [034430] = 148, -- Glimmering Naaru Sliver
  [034470] = 148, -- Timbal's Focusing Crystal
  [034471] = 20,  -- Vial of the Sunwell
  [034472] = 195, -- Shard of Contempt
  [034473] = 32,  -- Commendation of Kael'thas
  [036972] = 148, -- Tome of Arcane Phenomena
  [036993] = 32,  -- Seal of the Pantheon
  [037064] = 195, -- Vestige of Haldor
  [037111] = 20,  -- Soul Preserver
  [037166] = 195, -- Sphere of Red Dragon's Blood
  [037220] = 32,  -- Essence of Gossamer
  [037264] = 132, -- Pendulum of Telluric Currents
  [037390] = 195, -- Meteorite Whetstone
  [037638] = 32,  -- Offering of Sacrifice
  [037657] = 148, -- Spark of Life
  [037660] = 148, -- Forge Ember
  [037723] = 195, -- Incisor Fragment
  [037734] = 20,  -- Talisman of Troll Divinity
  [037844] = 148, -- Winged Talisman
  [037872] = 32,  -- Lavanthor's Talisman
  [037873] = 148, -- Mark of the War Prisoner
  [039229] = 148, -- Embrace of the Spider
  [040258] = 148, -- Forethought Talisman
  [040371] = 227, -- Bandit's Insignia
  [045148] = 148, -- Living Flame
  [045158] = 32,  -- Heart of Iron
  [045263] = 195, -- Wrathstone
  [045286] = 195, -- Pyrite Infuser
  [045292] = 148, -- Energy Siphon
  [045308] = 148, -- Eye of the Broodmother
  [045313] = 32,  -- Furnace Stone
  [045466] = 148, -- Scale of Fates
  [045490] = 148, -- Pandora's Plea
  [045507] = 32,  -- The General's Heart
  [045518] = 132, -- Flare of the Heavens
  [045522] = 195, -- Blood of the Old God
  [045535] = 148, -- Show of Faith
  [045609] = 227, -- Comet's Trail
  [045703] = 148, -- Spark of Hope
  [045866] = 132, -- Elemental Focus Stone
  [045929] = 20,  -- Sif's Remembrance
  [045931] = 195, -- Mjolnir Runestone
  [046021] = 32,  -- Royal Seal of King Llane
  [046038] = 227, -- Dark Matter
  [046051] = 148, -- Meteorite Crystal
  [046312] = 192, -- Vanquished Clutches of Yogg-Saron
  [047213] = 132, -- Abyssal Rune
  [047214] = 195, -- Banner of Victory
  [047215] = 20,  -- Tears of the Vanquished
  [047216] = 32,  -- The Black Heart
  [047271] = 148, -- Solace of the Fallen
  [047303] = 227, -- Death's Choice
  [047316] = 148, -- Reign of the Dead
  [047432] = 148, -- Solace of the Fallen
  [047464] = 227, -- Death's Choice
  [047477] = 148, -- Reign of the Dead
  [050198] = 195, -- Needle-Encrusted Scorpion
  [050235] = 32,  -- Ick's Rotting Thumb
  [050259] = 148, -- Nevermelting Ice Crystal
  [050260] = 20,  -- Ephemeral Snowflake
  [050339] = 148, -- Sliver of Pure Ice
  [050346] = 148, -- Sliver of Pure Ice
  [050359] = 148, -- Althor's Abacus
  [050366] = 148, -- Althor's Abacus
  [054573] = 148, -- Glowing Twilight Scale
  [054589] = 148, -- Glowing Twilight Scale
  [056280] = 32,  -- Porcelain Crab
  [056285] = 65,  -- Might of the Ocean
  [056290] = 148, -- Sea Star
  [056295] = 194, -- Grace of the Herald
  [056320] = 148, -- Witching Hourglass
  [056328] = 194, -- Key to the Endless Chamber
  [056339] = 148, -- Tendrils of Burrowing Dark
  [056345] = 65,  -- Magnetite Mirror
  [056347] = 32,  -- Leaden Despair
  [056351] = 20,  -- Tear of Blood
  [056370] = 32,  -- Heart of Thunder
  [056393] = 65,  -- Heart of Solace
  [056394] = 194, -- Tia's Grace
  [056400] = 132, -- Sorrowsong
  [056407] = 148, -- Anhuur's Hymnal
  [056414] = 20,  -- Blood of Isiset
  [056427] = 194, -- Left Eye of Rajh
  [056431] = 65,  -- Right Eye of Rajh
  [056440] = 194, -- Skardyn's Grace
  [056449] = 32,  -- Throngus's Finger
  [056458] = 97,  -- Mark of Khardros
  [056462] = 148, -- Gale of Shadows
  [056463] = 20,  -- Corrupted Egg Shell
  [059224] = 97,  -- Heart of Rage
  [059332] = 32,  -- Symbiotic Worm
  [059354] = 20,  -- Jar of Ancient Remedies
  [059441] = 194, -- Prestor's Talisman of Machination
  [059473] = 194, -- Essence of the Cyclone
  [059500] = 148, -- Fall of Mortality
  [059506] = 97,  -- Crushing Weight
  [059519] = 148, -- Theralion's Mirror
  [061033] = 194, -- Vicious Gladiator's Badge of Conquest
  [061047] = 194, -- Vicious Gladiator's Insignia of Conquest
  [065026] = 194, -- Prestor's Talisman of Machination
  [065029] = 20,  -- Jar of Ancient Remedies
  [065048] = 32,  -- Symbiotic Worm
  [065072] = 97,  -- Heart of Rage
  [065105] = 148, -- Theralion's Mirror
  [065118] = 97,  -- Crushing Weight
  [065124] = 148, -- Fall of Mortality
  [065140] = 194, -- Essence of the Cyclone
  [068925] = 148, -- Variable Pulse Lightning Capacitor
  [068926] = 148, -- Jaws of Defeat
  [068927] = 194, -- The Hungerer
  [068981] = 32,  -- Spidersilk Spindle
  [068982] = 148, -- Necromantic Focus
  [068983] = 148, -- Eye of Blazing Power
  [068994] = 194, -- Matrix Restabilizer
  [068995] = 97,  -- Vessel of Acceleration
  [069110] = 148, -- Variable Pulse Lightning Capacitor
  [069111] = 148, -- Jaws of Defeat
  [069112] = 194, -- The Hungerer
  [069138] = 32,  -- Spidersilk Spindle
  [069139] = 148, -- Necromantic Focus
  [069149] = 148, -- Eye of Blazing Power
  [069150] = 194, -- Matrix Restabilizer
  [069167] = 97,  -- Vessel of Acceleration
  [070399] = 194, -- Ruthless Gladiator's Badge of Conquest
  [070400] = 97,  -- Ruthless Gladiator's Badge of Victory
  [070401] = 148, -- Ruthless Gladiator's Badge of Dominance
  [070402] = 148, -- Ruthless Gladiator's Insignia of Dominance
  [070403] = 97,  -- Ruthless Gladiator's Insignia of Victory
  [070404] = 194, -- Ruthless Gladiator's Insignia of Conquest
  [072897] = 194, -- Arrow of Time
  [072898] = 148, -- Foul Gift of the Demon Lord
  [072899] = 97,  -- Varo'then's Brooch
  [072900] = 32,  -- Veil of Lies
  [072901] = 65,  -- Rosary of Light
  [073491] = 97,  -- Cataclysmic Gladiator's Insignia of Victory
  [073496] = 97,  -- Cataclysmic Gladiator's Badge of Victory
  [073497] = 148, -- Cataclysmic Gladiator's Insignia of Dominance
  [073498] = 148, -- Cataclysmic Gladiator's Badge of Dominance
  [073643] = 194, -- Cataclysmic Gladiator's Insignia of Conquest
  [073648] = 194, -- Cataclysmic Gladiator's Badge of Conquest
  [077197] = 194, -- Wrath of Unchaining
  [077198] = 132, -- Will of Unbinding
  [077199] = 148, -- Heart of Unliving
  [077200] = 97,  -- Eye of Unmaking
  [077201] = 32,  -- Resolve of Undying
  [077202] = 194, -- Starcatcher Compass
  [077203] = 148, -- Insignia of the Corrupted Mind
  [077204] = 148, -- Seal of the Seven Signs
  [077205] = 97,  -- Creche of the Final Dragon
  [077206] = 32,  -- Soulshifter Vortex
  [077207] = 194, -- Vial of Shadows
  [077208] = 132, -- Cunning of the Cruel
  [077209] = 20,  -- Windward Heart
  [077210] = 97,  -- Bone-Link Fetish
  [077211] = 32,  -- Indomitable Pride
  [077969] = 20,  -- Seal of the Seven Signs
  [077970] = 32,  -- Soulshifter Vortex
  [077971] = 148, -- Insignia of the Corrupted Mind
  [077972] = 65,  -- Creche of the Final Dragon
  [077973] = 194, -- Starcatcher Compass
  [077974] = 194, -- Wrath of Unchaining
  [077975] = 132, -- Will of Unbinding
  [077976] = 20,  -- Heart of Unliving
  [077977] = 97,  -- Eye of Unmaking
  [077978] = 32,  -- Resolve of Undying
  [077979] = 194, -- Vial of Shadows
  [077980] = 132, -- Cunning of the Cruel
  [077981] = 20,  -- Windward Heart
  [077982] = 65,  -- Bone-Link Fetish
  [077983] = 32,  -- Indomitable Pride
  [077989] = 148, -- Seal of the Seven Signs
  [077990] = 32,  -- Soulshifter Vortex
  [077991] = 148, -- Insignia of the Corrupted Mind
  [077992] = 97,  -- Creche of the Final Dragon
  [077993] = 194, -- Starcatcher Compass
  [077994] = 194, -- Wrath of Unchaining
  [077995] = 132, -- Will of Unbinding
  [077996] = 20,  -- Heart of Unliving
  [077997] = 97,  -- Eye of Unmaking
  [077998] = 32,  -- Resolve of Undying
  [077999] = 194, -- Vial of Shadows
  [078000] = 148, -- Cunning of the Cruel
  [078001] = 20,  -- Windward Heart
  [078002] = 97,  -- Bone-Link Fetish
  [078003] = 32,  -- Indomitable Pride
  [086131] = 32,  -- Vial of Dragon's Blood
  [086132] = 194, -- Bottle of Infinite Stars
  [086133] = 132, -- Light of the Cosmos
  [086144] = 65,  -- Lei Shen's Final Orders
  [086147] = 20,  -- Qin-xi's Polarizing Seal
  [086323] = 32,  -- Stuff of Nightmares
  [086327] = 20,  -- Spirits of the Sun
  [086332] = 194, -- Terror in the Mists
  [086336] = 65,  -- Darkmist Vortex
  [086388] = 132, -- Essence of Terror
  [086790] = 32,  -- Vial of Dragon's Blood
  [086791] = 194, -- Bottle of Infinite Stars
  [086792] = 132, -- Light of the Cosmos
  [086802] = 65,  -- Lei Shen's Final Orders
  [086805] = 20,  -- Qin-xi's Polarizing Seal
  [086881] = 32,  -- Stuff of Nightmares
  [086885] = 20,  -- Spirits of the Sun
  [086890] = 194, -- Terror in the Mists
  [086894] = 65,  -- Darkmist Vortex
  [086907] = 132, -- Essence of Terror
  [087057] = 194, -- Bottle of Infinite Stars
  [087063] = 32,  -- Vial of Dragon's Blood
  [087065] = 132, -- Light of the Cosmos
  [087072] = 65,  -- Lei Shen's Final Orders
  [087075] = 20,  -- Qin-xi's Polarizing Seal
  [087160] = 32,  -- Stuff of Nightmares
  [087163] = 20,  -- Spirits of the Sun
  [087167] = 194, -- Terror in the Mists
  [087172] = 65,  -- Darkmist Vortex
  [087175] = 132, -- Essence of Terror
  [088294] = 194, -- Flashing Steel Talisman
  [088355] = 194, -- Searing Words
  [088358] = 97,  -- Lessons of the Darkmaster
  [088360] = 20,  -- Price of Progress
  [094512] = 194, -- Renataki's Soul Charm
  [094513] = 132, -- Wushoolay's Final Choice
  [094514] = 20,  -- Horridon's Last Gasp
  [094515] = 65,  -- Fabled Feather of Ji-Kun
  [094516] = 32,  -- Fortitude of the Zandalari
  [094518] = 32,  -- Delicate Vial of the Sanguinaire
  [094519] = 65,  -- Primordius' Talisman of Rage
  [094520] = 20,  -- Inscribed Bag of Hydra-Spawn
  [094521] = 132, -- Breath of the Hydra
  [094522] = 194, -- Talisman of Bloodlust
  [094523] = 194, -- Bad Juju
  [094524] = 132, -- Unerring Vision of Lei Shen
  [094525] = 20,  -- Stolen Relic of Zuldazar
  [094526] = 65,  -- Spark of Zandalar
  [094527] = 32,  -- Ji-Kun's Rising Winds
  [094528] = 32,  -- Soul Barrier
  [094529] = 65,  -- Gaze of the Twins
  [094530] = 20,  -- Lightning-Imbued Chalice
  [094531] = 132, -- Cha-Ye's Essence of Brilliance
  [094532] = 194, -- Rune of Re-Origination
  [095625] = 194, -- Renataki's Soul Charm
  [095641] = 20,  -- Horridon's Last Gasp
  [095654] = 65,  -- Spark of Zandalar
  [095665] = 194, -- Bad Juju
  [095669] = 132, -- Wushoolay's Final Choice
  [095677] = 32,  -- Fortitude of the Zandalari
  [095711] = 132, -- Breath of the Hydra
  [095712] = 20,  -- Inscribed Bag of Hydra-Spawn
  [095726] = 65,  -- Fabled Feather of Ji-Kun
  [095727] = 32,  -- Ji-Kun's Rising Winds
  [095748] = 194, -- Talisman of Bloodlust
  [095757] = 65,  -- Primordius' Talisman of Rage
  [095763] = 20,  -- Stolen Relic of Zuldazar
  [095772] = 132, -- Cha-Ye's Essence of Brilliance
  [095779] = 32,  -- Delicate Vial of the Sanguinaire
  [095799] = 65,  -- Gaze of the Twins
  [095802] = 194, -- Rune of Re-Origination
  [095811] = 32,  -- Soul Barrier
  [095814] = 132, -- Unerring Vision of Lei Shen
  [095817] = 20,  -- Lightning-Imbued Chalice
  [096369] = 194, -- Renataki's Soul Charm
  [096385] = 20,  -- Horridon's Last Gasp
  [096398] = 65,  -- Spark of Zandalar
  [096409] = 194, -- Bad Juju
  [096413] = 132, -- Wushoolay's Final Choice
  [096421] = 32,  -- Fortitude of the Zandalari
  [096455] = 132, -- Breath of the Hydra
  [096456] = 20,  -- Inscribed Bag of Hydra-Spawn
  [096470] = 65,  -- Fabled Feather of Ji-Kun
  [096471] = 32,  -- Ji-Kun's Rising Winds
  [096492] = 194, -- Talisman of Bloodlust
  [096501] = 65,  -- Primordius' Talisman of Rage
  [096507] = 20,  -- Stolen Relic of Zuldazar
  [096516] = 132, -- Cha-Ye's Essence of Brilliance
  [096523] = 32,  -- Delicate Vial of the Sanguinaire
  [096543] = 65,  -- Gaze of the Twins
  [096546] = 194, -- Rune of Re-Origination
  [096555] = 32,  -- Soul Barrier
  [096558] = 132, -- Unerring Vision of Lei Shen
  [096561] = 20,  -- Lightning-Imbued Chalice
  [109995] = 194, -- Blood Seal of Azzakel
  [109996] = 194, -- Thundertower's Targeting Reticle
  [109997] = 194, -- Kihra's Adrenaline Injector
  [109998] = 194, -- Gor'ashan's Lodestone Spike
  [109999] = 194, -- Witherbark's Branch
  [110000] = 132, -- Crushto's Runic Alarm
  [110001] = 132, -- Tovra's Lightning Repository
  [110002] = 132, -- Fleshrender's Meathook
  [110003] = 132, -- Ragewing's Firefang
  [110004] = 132, -- Coagulated Genesaur Blood
  [110005] = 20,  -- Crystalline Blood Drop
  [110006] = 20,  -- Rukhran's Quill
  [110007] = 20,  -- Voidmender's Shadowgem
  [110008] = 20,  -- Tharbek's Lucky Pebble
  [110009] = 20,  -- Leaf of the Ancient Protectors
  [110010] = 65,  -- Mote of Corruption
  [110011] = 65,  -- Fires of the Sun
  [110012] = 65,  -- Bonemaw's Big Toe
  [110013] = 65,  -- Emberscale Talisman
  [110014] = 65,  -- Spores of Alacrity
  [110015] = 32,  -- Toria's Unseeing Eye
  [110016] = 32,  -- Solar Containment Unit
  [110017] = 32,  -- Enforcer's Stun Grenade
  [110018] = 32,  -- Kyrak's Vileblood Serum
  [110019] = 32,  -- Xeri'tac's Unhatched Egg Sac
  [112426] = 132, -- Purified Bindings of Immerseus
  [112476] = 32,  -- Rook's Unlucky Talisman
  [112503] = 65,  -- Fusion-Fire Core
  [112703] = 65,  -- Evil Eye of Galakras
  [112729] = 32,  -- Juggernaut's Focusing Crystal
  [112754] = 194, -- Haromm's Talisman
  [112768] = 132, -- Kardris' Toxic Totem
  [112778] = 20,  -- Nazgrim's Burnished Insignia
  [112792] = 32,  -- Vial of Living Corruption
  [112815] = 132, -- Frenzied Crystal of Rage
  [112825] = 194, -- Sigil of Rampage
  [112849] = 20,  -- Thok's Acid-Grooved Tooth
  [112850] = 65,  -- Thok's Tail Tip
  [112877] = 20,  -- Dysmorphic Samophlange of Discontinuity
  [112879] = 194, -- Ticking Ebon Detonator
  [112913] = 65,  -- Skeer's Bloodsoaked Talisman
  [112924] = 32,  -- Curse of Hubris
  [112938] = 132, -- Black Blood of Y'Shaarj
  [112947] = 194, -- Assurance of Consequence
  [112948] = 20,  -- Prismatic Prison of Pride
  [113612] = 194, -- Scales of Doom
  [113645] = 65,  -- Tectus' Beating Heart
  [113650] = 32,  -- Pillar of the Earth
  [113658] = 65,  -- Bottle of Infesting Spores
  [113834] = 32,  -- Pol's Blinded Eye
  [113835] = 132, -- Shards of Nothing
  [113842] = 20,  -- Emblem of Caustic Healing
  [113853] = 194, -- Captive Micro-Aberration
  [113854] = 20,  -- Mark of Rapid Replication
  [113859] = 132, -- Quiescent Runestone
  [113861] = 32,  -- Evergaze Arcane Eidolon
  [113889] = 20,  -- Elementalist's Shielding Talisman
  [113893] = 32,  -- Blast Furnace Door
  [113905] = 32,  -- Tablet of Turnbuckle Teamwork
  [113931] = 194, -- Beating Heart of the Mountain
  [113948] = 132, -- Darmac's Unstable Talisman
  [113969] = 65,  -- Vial of Convulsive Shadows
  [113983] = 65,  -- Forgemaster's Insignia
  [113984] = 132, -- Blackiron Micro Crucible
  [113985] = 194, -- Humming Blackiron Trigger
  [113986] = 20,  -- Auto-Repairing Autoclave
  [113987] = 32,  -- Battering Talisman
  [116289] = 194, -- Bloodmaw's Tooth
  [116290] = 132, -- Emblem of Gushing Wounds
  [116291] = 20,  -- Immaculate Living Mushroom
  [116292] = 65,  -- Mote of the Mountain
  [116293] = 32,  -- Idol of Suppression
  [116314] = 194, -- Blackheart Enforcer's Medallion
  [116315] = 132, -- Furyheart Talisman
  [116316] = 20,  -- Captured Flickerspark
  [116317] = 65,  -- Storage House Key
  [116318] = 32,  -- Stoneheart Idol
  [118114] = 194, -- Meaty Dragonspine Trophy
  [119192] = 20,  -- Ironspike Chew Toy
  [119193] = 65,  -- Horn of Screaming Spirits
  [119194] = 132, -- Goren Soul Repository
  [123992] = 32,  -- Figurine of the Colossus
  [124223] = 194, -- Fel-Spring Coil
  [124224] = 194, -- Mirror of the Blademaster
  [124225] = 66,  -- Soul Capacitor
  [124226] = 194, -- Malicious Censer
  [124227] = 132, -- Iron Reaver Piston
  [124228] = 132, -- Desecrated Shadowmoon Insignia
  [124229] = 132, -- Unblinking Gaze of Sethe
  [124230] = 132, -- Prophecy of Fear
  [124231] = 20,  -- Flickering Felspark
  [124232] = 20,  -- Intuition's Gift
  [124233] = 20,  -- Demonic Phylactery
  [124234] = 20,  -- Unstable Felshadow Emulsion
  [124235] = 65,  -- Rumbling Pebble
  [124236] = 65,  -- Unending Hunger
  [124237] = 65,  -- Discordant Chorus
  [124238] = 65,  -- Empty Drinking Horn
  [124239] = 32,  -- Imbued Stone Sigil
  [124240] = 32,  -- Warlord's Unseeing Eye
  [124241] = 32,  -- Anzu's Cursed Plume
  [124242] = 32,  -- Tyrant's Decree
  [124515] = 130, -- Talisman of the Master Tracker
  [124516] = 132, -- Tome of Shifting Words
  [124519] = 20,  -- Repudiation of War
  [124520] = 66,  -- Bleeding Hollow Toxin Vessel
  [124523] = 97,  -- Worldbreaker's Resolve
  [127173] = 148, -- Shiffar's Nexus-Horn
  [127184] = 32,  -- Runed Fungalcap
  [127201] = 132, -- Quagmirran's Eye
  [127245] = 148, -- Warp-Scarab Brooch
  [127441] = 195, -- Hourglass of the Unraveller
  [127448] = 20,  -- Scarab of the Infinite Cycle
  [127474] = 195, -- Vestige of Haldor
  [127493] = 195, -- Meteorite Whetstone
  [127512] = 148, -- Winged Talisman
  [127550] = 32,  -- Offering of Sacrifice
  [127594] = 195, -- Sphere of Red Dragon's Blood
  [128140] = 194, -- Smoldering Felblade Remnant
  [128141] = 148, -- Crackling Fel-Spark Plug
  [128142] = 148, -- Pledge of Iron Loyalty
  [128143] = 97,  -- Fragmented Runestone Etching
  [128144] = 227, -- Vial of Vile Viscera
  [128145] = 194, -- Howling Soul Gem
  [128146] = 148, -- Ensnared Orb of the Sky
  [128147] = 148, -- Teardrop of Blood
  [128148] = 97,  -- Fetid Salivation
  [128149] = 227, -- Accusation of Inferiority
  [128150] = 194, -- Pressure-Compressed Loop
  [128151] = 148, -- Portent of Disaster
  [128152] = 148, -- Decree of Demonic Sovereignty
  [128153] = 97,  -- Unquenchable Doomfire Censer
  [128154] = 227, -- Grasp of the Defiler
  [133192] = 99,  -- Porcelain Crab
  [133197] = 65,  -- Might of the Ocean
  [133201] = 148, -- Sea Star
  [133206] = 194, -- Key to the Endless Chamber
  [133216] = 148, -- Tendrils of Burrowing Dark
  [133222] = 65,  -- Magnetite Mirror
  [133224] = 32,  -- Leaden Despair
  [133227] = 20,  -- Tear of Blood
  [133246] = 32,  -- Heart of Thunder
  [133252] = 20,  -- Rainsong
  [133268] = 65,  -- Heart of Solace
  [133269] = 194, -- Tia's Grace
  [133275] = 132, -- Sorrowsong
  [133281] = 32,  -- Impetuous Query
  [133282] = 194, -- Skardyn's Grace
  [133291] = 32,  -- Throngus's Finger
  [133300] = 65,  -- Mark of Khardros
  [133304] = 148, -- Gale of Shadows
  [133305] = 20,  -- Corrupted Egg Shell
  [133420] = 194, -- Arrow of Time
  [133461] = 132, -- Timbal's Focusing Crystal
  [133462] = 20,  -- Vial of the Sunwell
  [133463] = 195, -- Shard of Contempt
  [133464] = 32,  -- Commendation of Kael'thas
  [133641] = 134, -- Eye of Skovald
  [133644] = 67,  -- Memento of Angerboda
  [133645] = 20,  -- Naglfar Fare
  [133646] = 20,  -- Mote of Sanctification
  [133647] = 32,  -- Gift of Radiance
  [133766] = 20,  -- Nether Anti-Toxin
  [136714] = 20,  -- Amalgam's Seventh Spine
  [136715] = 67,  -- Spiked Counterweight
  [136716] = 134, -- Caged Horror
  [136975] = 227, -- Hunger of the Pack
  [136978] = 32,  -- Ember of Nullification
  [137301] = 132, -- Corrupted Starlight
  [137306] = 134, -- Oakheart's Gnarled Root
  [137312] = 67,  -- Nightmare Egg Shell
  [137315] = 32,  -- Writhing Heart of Darkness
  [137329] = 134, -- Figurehead of the Naglfar
  [137338] = 32,  -- Shard of Rokmora
  [137344] = 32,  -- Talisman of the Cragshaper
  [137349] = 134, -- Naraxas' Spiked Tongue
  [137357] = 67,  -- Mark of Dargrul
  [137362] = 32,  -- Parjesh's Medallion
  [137367] = 134, -- Stormsinger Fulmination Charge
  [137369] = 67,  -- Giant Ornamental Pearl
  [137373] = 194, -- Tempered Egg of Serpentrix
  [137378] = 20,  -- Bottled Hurricane
  [137398] = 132, -- Portable Manacracker
  [137400] = 32,  -- Coagulated Nightwell Residue
  [137406] = 67,  -- Terrorbound Nexus
  [137430] = 32,  -- Impenetrable Nerubian Husk
  [137433] = 150, -- Obelisk of the Void
  [137439] = 67,  -- Tiny Oozeling in a Jar
  [137440] = 32,  -- Shivermaw's Jawbone
  [137446] = 134, -- Elementium Bomb Squirrel Generator
  [137452] = 20,  -- Thrumming Gossamer
  [137459] = 67,  -- Chaos Talisman
  [137462] = 20,  -- Jewel of Insatiable Desire
  [137484] = 20,  -- Flask of the Solemn Night
  [137485] = 132, -- Infernal Writ
  [137486] = 67,  -- Windscar Whetstone
  [137537] = 194, -- Tirathon's Betrayal
  [137538] = 32,  -- Orb of Torment
  [137539] = 67,  -- Faulty Countermeasure
  [137540] = 20,  -- Concave Reflecting Lens
  [137541] = 134, -- Moonlit Prism
  [138222] = 20,  -- Vial of Nightmare Fog
  [138224] = 134, -- Unstable Horrorslime
  [138225] = 32,  -- Phantasmal Echo
  [139320] = 67,  -- Ravaged Seed Pod
  [139321] = 132, -- Swarming Plaguehive
  [139322] = 20,  -- Cocoon of Enforced Solitude
  [139323] = 134, -- Twisting Wind
  [139324] = 32,  -- Goblet of Nightmarish Ichor
  [139325] = 67,  -- Spontaneous Appendages
  [139326] = 132, -- Wriggling Sinew
  [139327] = 32,  -- Unbridled Fury
  [139328] = 65,  -- Ursoc's Rending Paw
  [139329] = 194, -- Bloodthirsty Instinct
  [139330] = 20,  -- Heightened Senses
  [139333] = 20,  -- Horn of Cenarius
  [139334] = 67,  -- Nature's Call
  [139335] = 32,  -- Grotesque Statuette
  [139336] = 132, -- Bough of Corruption
  [140789] = 32,  -- Animated Exoskeleton
  [140790] = 65,  -- Claw of the Crystalline Scorpid
  [140791] = 32,  -- Royal Dagger Haft
  [140792] = 132, -- Erratic Metronome
  [140793] = 20,  -- Perfectly Preserved Cake
  [140794] = 66,  -- Arcanogolem Digit
  [140795] = 20,  -- Aluriel's Mirror
  [140796] = 195, -- Entwined Elemental Foci
  [140797] = 32,  -- Fang of Tichondrius
  [140798] = 134, -- Icon of Rot
  [140799] = 65,  -- Might of Krosus
  [140800] = 132, -- Pharamere's Forbidden Grimoire
  [140801] = 134, -- Fury of the Burning Sky
  [140802] = 194, -- Nightblooming Frond
  [140803] = 20,  -- Etraeus' Celestial Map
  [140804] = 132, -- Star Gate
  [140805] = 20,  -- Ephemeral Paradox
  [140806] = 195, -- Convergence of Fates
  [140807] = 32,  -- Infernal Contract
  [140808] = 67,  -- Draught of Souls
  [140809] = 132, -- Whispers in the Dark
  [141535] = 97,  -- Ettin Fingernail
  [141536] = 148, -- Padawsen's Unlucky Charm
  [141537] = 194, -- Thrice-Accursed Compass
  [142157] = 134, -- Aran's Relaxing Ruby
  [142158] = 20,  -- Faith's Crucible
  [142159] = 67,  -- Bloodstained Handkerchief
  [142160] = 134, -- Mrrgria's Favor
  [142161] = 32,  -- Inescapable Dread
  [142162] = 20,  -- Fluctuating Energy
  [142164] = 67,  -- Toe Knee's Promise
  [142165] = 134, -- Deteriorated Construct Core
  [142167] = 67,  -- Eye of Command
  [142168] = 32,  -- Majordomo's Dinner Bell
  [142169] = 32,  -- Raven Eidolon
  [142506] = 194, -- Eye of Guarm
  [142507] = 148, -- Brinewater Slime in a Bottle
  [142508] = 97,  -- Chains of the Valorous
  [144113] = 194, -- Windswept Pages
  [144119] = 148, -- Empty Fruit Barrel
  [144122] = 97,  -- Carbonic Carbuncle
  [144128] = 32,  -- Heart of Fire
  [144136] = 148, -- Vision of the Predator
  [144146] = 32,  -- Iron Protector Talisman
  [144156] = 148, -- Flashfrozen Resin Globule
  [144157] = 148, -- Vial of Ichorous Blood
  [144159] = 148, -- Price of Progress
  [144160] = 194, -- Searing Words
  [144161] = 97,  -- Lessons of the Darkmaster
  [144477] = 194, -- Splinters of Agronox
  [144480] = 148, -- Dreadstone of Endless Shadows
  [144482] = 97,  -- Fel-Oiled Infernal Machine
  [147002] = 148, -- Charm of the Rising Tide
  [147003] = 20,  -- Barbaric Mindslaver
  [147004] = 20,  -- Sea Star of the Depthmother
  [147005] = 20,  -- Chalice of Moonlight
  [147006] = 20,  -- Archive of Faith
  [147007] = 20,  -- The Deceiver's Grand Design
  [147009] = 67,  -- Infernal Cinders
  [147010] = 195, -- Cradle of Anguish
  [147011] = 67,  -- Vial of Ceaseless Toxins
  [147012] = 67,  -- Umbral Moonglaives
  [147015] = 195, -- Engine of Eradication
  [147016] = 134, -- Terror From Below
  [147017] = 134, -- Tarnished Sentinel Medallion
  [147018] = 134, -- Spectral Thurible
  [147019] = 134, -- Tome of Unraveling Sanity
  [147022] = 32,  -- Feverish Carapace
  [147023] = 32,  -- Leviathan's Hunger
  [147024] = 32,  -- Reliquary of the Damned
  [147025] = 32,  -- Recompiled Guardian Module
  [147026] = 32,  -- Shifting Cosmic Sliver
  [150522] = 132, -- The Skull of Gul'dan
  [150523] = 20,  -- Memento of Tyrande
  [150526] = 227, -- Shadowmoon Insignia
  [150527] = 227, -- Madness of the Betrayer
  [151190] = 67,  -- Specter of Betrayal
  [151307] = 195, -- Void Stalker's Contract
  [151310] = 132, -- Reality Breacher
  [151312] = 32,  -- Ampoule of Pure Void
  [151340] = 20,  -- Echo of L'ura
  [151955] = 132, -- Acrid Catalyst Injector
  [151956] = 20,  -- Garothi Feedback Conduit
  [151957] = 20,  -- Ishkar's Felshield Emitter
  [151958] = 20,  -- Tarratus Keystone
  [151960] = 20,  -- Carafe of Searing Light
  [151962] = 134, -- Prototype Personnel Decimator
  [151963] = 195, -- Forgefiend's Fabricator
  [151964] = 67,  -- Seeping Scourgewing
  [151968] = 195, -- Shadow-Singed Fang
  [151969] = 134, -- Terminus Signaling Beacon
  [151970] = 148, -- Vitality Resonator
  [151971] = 132, -- Sheath of Asara
  [151975] = 32,  -- Apocalypse Drive
  [151976] = 32,  -- Riftworld Codex
  [151977] = 32,  -- Diima's Glacial Aegis
  [151978] = 32,  -- Smoldering Titanguard
  [152093] = 67,  -- Gorshalach's Legacy
  [152289] = 20,  -- Highfather's Machination
  [152645] = 32,  -- Eye of Shatug
  [153544] = 32,  -- Eye of F'harg
  [154173] = 32,  -- Aggramar's Conviction
  [154174] = 194, -- Golganneth's Vitality
  [154175] = 20,  -- Eonar's Compassion
  [154176] = 65,  -- Khaz'goroth's Courage
  [154177] = 132, -- Norgannon's Prowess
  [155881] = 194, -- Harlan's Loaded Dice
  [155947] = 148, -- Living Flame
  [155952] = 32,  -- Heart of Iron
  [156000] = 195, -- Wrathstone
  [156016] = 195, -- Pyrite Infuser
  [156021] = 148, -- Energy Siphon
  [156036] = 148, -- Eye of the Broodmother
  [156041] = 32,  -- Furnace Stone
  [156187] = 148, -- Scale of Fates
  [156207] = 148, -- Pandora's Plea
  [156221] = 32,  -- The General's Heart
  [156230] = 132, -- Flare of the Heavens
  [156234] = 195, -- Blood of the Old God
  [156245] = 20,  -- Show of Faith
  [156277] = 20,  -- Spark of Hope
  [156288] = 132, -- Elemental Focus Stone
  [156308] = 20,  -- Sif's Remembrance
  [156310] = 195, -- Mjolnir Runestone
  [156345] = 32,  -- Royal Seal of King Llane
  [156458] = 192, -- Vanquished Clutches of Yogg-Saron
  [158319] = 194, -- My'das Talisman
  [158320] = 20,  -- Revitalizing Voodoo Totem
  [158367] = 97,  -- Merektha's Fang
  [158368] = 20,  -- Fangs of Intertwined Essence
  [158374] = 194, -- Tiny Electromental in a Jar
  [158712] = 97,  -- Rezan's Gleaming Eye
  [159610] = 132, -- Vessel of Skittering Shadows
  [159611] = 97,  -- Razdunk's Big Red Button
  [159612] = 194, -- Azerokk's Resonating Heart
  [159614] = 194, -- Galecaller's Boon
  [159615] = 148, -- Ignition Mage's Fuse
  [159616] = 97,  -- Gore-Crusted Butcher's Block
  [159617] = 194, -- Lustrous Golden Plumage
  [159618] = 32,  -- Mchimba's Ritual Bandages
  [159619] = 97,  -- Briny Barnacle
  [159620] = 148, -- Conch of Dark Whispers
  [159622] = 132, -- Hadal's Nautilus
  [159623] = 194, -- Dead-Eye Spyglass
  [159624] = 132, -- Rotcrusted Voodoo Doll
  [159625] = 97,  -- Vial of Animated Blood
  [159626] = 32,  -- Lingering Sporepods
  [159627] = 97,  -- Jes' Howler
  [159628] = 194, -- Kul Tiran Cannonball Runner
  [159630] = 148, -- Balefire Branch
  [159631] = 148, -- Lady Waycrest's Music Box
  [160648] = 194, -- Frenetic Corpuscle
  [160649] = 20,  -- Inoculating Extract
  [160650] = 97,  -- Disc of Systematic Regression
  [160651] = 132, -- Vigilant's Bloodshaper
  [160652] = 194, -- Construct Overcharger
  [160653] = 32,  -- Xalzaix's Veiled Eye
  [160654] = 224, -- Vanquished Tendril of G'huun
  [160655] = 97,  -- Syringe of Bloodborne Infirmity
  [160656] = 148, -- Twitching Tentacle of Xalzaix
  [161376] = 97,  -- Prism of Dark Intensity
  [161377] = 148, -- Azurethos' Singed Plumage
  [161378] = 194, -- Plume of the Seaborne Avian
  [161379] = 97,  -- Galecaller's Beak
  [161380] = 148, -- Drust-Runed Icicle
  [161381] = 194, -- Permafrost-Encrusted Heart
  [161411] = 148, -- T'zane's Barkspines
  [161412] = 194, -- Spiritbound Voodoo Burl
  [161419] = 97,  -- Kraulok's Claw
  [161461] = 148, -- Doom's Hatred
  [161462] = 194, -- Doom's Wake
  [161463] = 97,  -- Doom's Fury
  [165568] = 194, -- Invocation of Yu'lon
  [165569] = 20,  -- Ward of Envelopment
  [165570] = 65,  -- Everchill Anchor
  [165571] = 148, -- Incandescent Sliver
  [165572] = 194, -- Variable Intensity Gigavolt Oscillating Reactor
  [165573] = 32,  -- Diamond-Laced Refracting Prism
  [165574] = 65,  -- Grong's Primal Rage
  [165576] = 132, -- Tidestorm Codex
  [165577] = 32,  -- Bwonsamdi's Bargain
  [165578] = 20,  -- Mirror of Entwined Fate
  [165579] = 194, -- Kimbul's Razor Claw
  [165580] = 97,  -- Ramping Amplitude Gigavolt Engine
  [165581] = 148, -- Crest of Pa'ku
  [166793] = 148, -- Ancient Knot of Wisdom
  [166794] = 194, -- Forest Lord's Razorleaf
  [166795] = 97,  -- Knot of Ancient Fury
  [167865] = 20,  -- Void Stone
  [167866] = 195, -- Lurker's Insidious Gift
  [167867] = 132, -- Harbinger's Inscrutable Will
  [167868] = 227, -- Idol of Indiscriminate Consumption
  [168905] = 132, -- Shiver Venom Relic
  [168965] = 32,  -- Modular Platinum Plating
  [169304] = 132, -- Leviathan's Lure
  [169305] = 132, -- Aquipotent Nautilus
  [169306] = 148, -- Za'qul's Portal Key
  [169307] = 195, -- Vision of Demise
  [169308] = 32,  -- Chain of Suffering
  [169309] = 20,  -- Zoatroid Egg Sac
  [169310] = 32,  -- Bloodthirsty Urchin
  [169311] = 195, -- Ashvane's Razor Coral
  [169312] = 20,  -- Luminous Jellyweed
  [169313] = 67,  -- Phial of the Arcane Tempest
  [169315] = 32,  -- Edicts of the Faithless
  [169316] = 20,  -- Deferred Sentence
  [169319] = 195, -- Dribbling Inkpod
  [169344] = 148, -- Ingenious Mana Battery
  [169769] = 195, -- Remote Guidance Device
  [171640] = 148, -- Variable Pulse Lightning Capacitor
  [171641] = 148, -- Jaws of Defeat
  [171642] = 194, -- The Hungerer
  [171643] = 32,  -- Spidersilk Spindle
  [171644] = 148, -- Necromantic Focus
  [171645] = 148, -- Eye of Blazing Power
  [171646] = 194, -- Matrix Restabilizer
  [171647] = 97,  -- Vessel of Acceleration
  [173940] = 32,  -- Sigil of Warding
  [173943] = 195, -- Torment in a Jar
  [173944] = 148, -- Forbidden Obsidian Claw
  [173946] = 195, -- Writhing Segment of Drest'agath
  [174060] = 132, -- Psyche Shredder
  [174103] = 148, -- Manifesto of Madness
  [174180] = 20,  -- Oozing Coagulum
  [174277] = 32,  -- Lingering Psychic Shell
  [178708] = 148, -- Unbound Changeling
  [178715] = 194, -- Mistcaller Ocarina
  [178742] = 194, -- Bottled Flayedwing Toxin
  [178751] = 97,  -- Spare Meat Hook
  [178769] = 198, -- Infinitely Divisible Ooze
  [178770] = 32,  -- Slimy Consumptive Organ
  [178771] = 67,  -- Phial of Putrefaction
  [178772] = 132, -- Satchel of Misbegotten Minions
  [178783] = 20,  -- Siphoning Phylactery Shard
  [178808] = 97,  -- Viscera of Coalesced Hatred
  [178809] = 148, -- Soulletting Ruby
  [178810] = 20,  -- Vial of Spectral Essence
  [178811] = 67,  -- Grim Codex
  [178825] = 32,  -- Pulsating Stoneheart
  [178826] = 148, -- Sunblood Amethyst
  [178849] = 148, -- Overflowing Anima Cage
  [178850] = 20,  -- Lingering Sunmote
  [178861] = 99,  -- Decanter of Anima-Charged Winds
  [178862] = 32,  -- Bladedancer's Armor Kit
  [179331] = 32,  -- Blood-Spattered Scale
  [179342] = 97,  -- Overwhelming Power Crystal
  [179356] = 194, -- Shadowgrasp Totem
  [180116] = 194, -- Overcharged Anima Battery
  [180117] = 132, -- Empyreal Ordnance
  [180118] = 97,  -- Anima Field Emitter
  [180119] = 20,  -- Boon of the Archon
  [184016] = 67,  -- Skulker's Wing
  [184017] = 32,  -- Bargast's Leash
  [184018] = 32,  -- Splintered Heart of Al'ar
  [184019] = 132, -- Soul Igniter
  [184020] = 20,  -- Tuft of Smoldering Plumage
  [184021] = 132, -- Glyph of Assimilation
  [184022] = 20,  -- Consumptive Infusion
  [184023] = 97,  -- Gluttonous Spike
  [184025] = 195, -- Memory of Past Sins
  [184026] = 194, -- Hateful Chain
  [184027] = 227, -- Stone Legion Heraldry
  [184028] = 148, -- Cabalist's Hymnal
  [184029] = 20,  -- Manabound Mirror
  [184030] = 192, -- Dreadfire Vessel
  [184031] = 32,  -- Sanguine Vintage
  [185836] = 32,  -- Codex of the First Technique
  [185844] = 67,  -- Ticking Sack of Terror
  [185845] = 20,  -- First Class Healing Distributor
  [185846] = 134, -- Miniscule Mailemental in an Envelope
  [186421] = 132, -- Forbidden Necromantic Tome
  [186422] = 132, -- Tome of Monstrous Constructions
  [186424] = 32,  -- Shard of Annhylde's Aegis
  [186425] = 20,  -- Scrawled Word of Recall
  [186427] = 65,  -- Whispering Shard of Power
  [186428] = 148, -- Shadowed Orb of Torment
  [186429] = 227, -- Decanter of Endless Howling
  [186430] = 195, -- Tormented Rack Fragment
  [186431] = 132, -- Ebonsoul Vise
  [186432] = 195, -- Salvaged Fusion Amplifier
  [186433] = 32,  -- Reactive Defense Matrix
  [186434] = 32,  -- Weave of Warped Fates
  [186435] = 20,  -- Carved Ivory Keepsake
  [186436] = 20,  -- Resonant Silver Bell
  [186437] = 194, -- Relic of the Frozen Wastes
  [186438] = 97,  -- Old Warrior's Soul
  [188252] = 99,  -- Chains of Domination
  [188254] = 148, -- Grim Eclipse
  [188255] = 97,  -- Heart of the Swarm
  [188261] = 32,  -- Intrusive Thoughtcage
  [188262] = 20,  -- The Lion's Roar
  [188263] = 20,  -- Reclaimer's Intensity Core
  [188264] = 99,  -- Earthbreaker's Impact
  [188265] = 194, -- Cache of Acquired Treasures
  [188266] = 32,  -- Pulsating Riftshard
  [188267] = 227, -- Bells of the Endless Feast
  [188268] = 132, -- Architect's Ingenuity Core
  [188269] = 32,  -- Pocket Protoforge
  [188272] = 132, -- Resonant Reservoir
  [188273] = 20,  -- Auxiliary Attendant Chime
  [190652] = 67,  -- Ticking Sack of Terror
  [193628] = 148, -- Tome of Unstable Power
  [193634] = 32,  -- Burgeoning Seed
  [193639] = 148, -- Umbrelskul's Fractured Heart
  [193652] = 32,  -- Treemouth's Festering Splinter
  [193660] = 134, -- Idol of Pure Decay
  [193672] = 67,  -- Frenzying Signoll Flare
  [193677] = 132, -- Furious Ragefeather
  [193678] = 20,  -- Miniature Singing Stone
  [193679] = 65,  -- Idol of Trampling Hooves
  [193689] = 32,  -- Granyth's Enduring Scale
  [193697] = 194, -- Bottle of Spiraling Winds
  [193701] = 227, -- Algeth'ar Puzzle Box
  [193718] = 20,  -- Emerald Coach's Whistle
  [193719] = 97,  -- Dragon Games Equipment
  [193732] = 194, -- Globe of Jagged Ice
  [193736] = 20,  -- Water's Beating Heart
  [193748] = 20,  -- Kyrakka's Searing Embers
  [193762] = 97,  -- Blazebinder's Hoof
  [193769] = 214, -- Erupting Spear Fragment
  [193773] = 148, -- Spoils of Neltharus
  [193786] = 67,  -- Mutated Magmammoth Scale
  [193791] = 148, -- Time-Breaching Talon
  [193805] = 32,  -- Inexorable Resonator
  [193815] = 67,  -- Homeland Raid Horn
  [194299] = 227, -- Decoration of Flame
  [194300] = 148, -- Conjured Chillglobe
  [194302] = 227, -- Storm-Eater's Boon
  [194303] = 97,  -- Rumbling Ruby
  [194304] = 148, -- Iceblood Deathsnare
  [194305] = 194, -- Controlled Current Technique
  [194306] = 32,  -- All-Totem of the Master
  [194307] = 148, -- Broodkeeper's Promise
  [194308] = 227, -- Manic Grieftorch
  [194310] = 148, -- Desperate Invoker's Codex
}