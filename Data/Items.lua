local Name, Addon = ...
local GUI, Unit, Util = Addon.GUI, Addon.Unit, Addon.Util
local Self = Addon.Item

-- Expac IDs
Self.EXPAC_CLASSIC = 0
Self.EXPAC_BC = 1
Self.EXPAC_WOTLK = 2
Self.EXPAC_CATA = 3
Self.EXPAC_MOP = 4
Self.EXPAC_WOD = 5
Self.EXPAC_LEGION = 6
Self.EXPAC_BFA = 7

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

-- All types that get special treatment for being a weapon
Self.TYPES_WEAPON = {Self.TYPE_WEAPON, Self.TYPE_2HWEAPON, Self.TYPE_WEAPONMAINHAND, Self.TYPE_WEAPONOFFHAND, Self.TYPE_HOLDABLE}
Self.TYPES_1HWEAPON = {Self.TYPE_WEAPON, Self.TYPE_WEAPONMAINHAND, Self.TYPE_WEAPONOFFHAND, Self.TYPE_HOLDABLE}
Self.TYPES_2HWEAPON = {Self.TYPE_2HWEAPON}

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

-- Primary stats
Self.ATTRIBUTES = {
    LE_UNIT_STAT_STRENGTH, -- 1
    LE_UNIT_STAT_AGILITY,  -- 2
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
        armor = {LE_ITEM_ARMOR_GENERIC, LE_ITEM_ARMOR_PLATE},
        weapons = {LE_ITEM_WEAPON_AXE1H, LE_ITEM_WEAPON_MACE1H, LE_ITEM_WEAPON_SWORD1H, LE_ITEM_WEAPON_AXE2H, LE_ITEM_WEAPON_MACE2H, LE_ITEM_WEAPON_SWORD2H, LE_ITEM_WEAPON_POLEARM},
        specs = {
            {   -- Blood
                role = Self.ROLE_TANK,
                attribute = LE_UNIT_STAT_STRENGTH,
                weapons = Self.TYPES_2HWEAPON,
                artifact = {id = 128402, relics = {RELIC_SLOT_TYPE_BLOOD, RELIC_SLOT_TYPE_SHADOW, RELIC_SLOT_TYPE_IRON}}
            },{ -- Frost
                role = Self.ROLE_MELEE,
                attribute = LE_UNIT_STAT_STRENGTH,
                weapons = Self.TYPES_1HWEAPON,
                artifact = {id = 128292, relics = {RELIC_SLOT_TYPE_FROST, RELIC_SLOT_TYPE_SHADOW, RELIC_SLOT_TYPE_FROST}, twinId = 128293}
            },{ -- Unholy
                role = Self.ROLE_MELEE,
                attribute = LE_UNIT_STAT_STRENGTH,
                weapons = Self.TYPES_2HWEAPON,
                artifact = {id = 128403, relics = {RELIC_SLOT_TYPE_FIRE, RELIC_SLOT_TYPE_SHADOW, RELIC_SLOT_TYPE_BLOOD}}
            }
        }
    },
    [Unit.DEMON_HUNTER] = {
        armor = {LE_ITEM_ARMOR_GENERIC, LE_ITEM_ARMOR_LEATHER},
        weapons = {LE_ITEM_WEAPON_AXE1H, LE_ITEM_WEAPON_SWORD1H, LE_ITEM_WEAPON_WARGLAIVE, LE_ITEM_WEAPON_DAGGER, LE_ITEM_WEAPON_UNARMED},
        specs = {
            {   -- Havoc
                role = Self.ROLE_MELEE,
                attribute = LE_UNIT_STAT_AGILITY,
                artifact = {id = 127829, relics = {RELIC_SLOT_TYPE_FEL, RELIC_SLOT_TYPE_SHADOW, RELIC_SLOT_TYPE_FEL}, twinId = 127830}
            },{ -- Vengeance
                role = Self.ROLE_TANK,
                attribute = LE_UNIT_STAT_AGILITY,
                artifact = {id = 128832, relics = {RELIC_SLOT_TYPE_IRON, RELIC_SLOT_TYPE_ARCANE, RELIC_SLOT_TYPE_FEL}, twinId = 128831}
            }
        }
    },
    [Unit.DRUID] = {
        armor = {LE_ITEM_ARMOR_GENERIC, LE_ITEM_ARMOR_LEATHER},
        weapons = {LE_ITEM_WEAPON_MACE1H, LE_ITEM_WEAPON_DAGGER, LE_ITEM_WEAPON_UNARMED, LE_ITEM_WEAPON_POLEARM, LE_ITEM_WEAPON_STAFF},
        specs = {
            {   -- Balance
                role = Self.ROLE_RANGED,
                attribute = LE_UNIT_STAT_INTELLECT,
                artifact = {id = 128858, relics = {RELIC_SLOT_TYPE_ARCANE, RELIC_SLOT_TYPE_LIFE, RELIC_SLOT_TYPE_ARCANE}}
            },{ -- Feral
                role = Self.ROLE_MELEE,
                attribute = LE_UNIT_STAT_AGILITY,
                artifact = {id = 128860, relics = {RELIC_SLOT_TYPE_FROST, RELIC_SLOT_TYPE_BLOOD, RELIC_SLOT_TYPE_LIFE}, twinId = 128859}
            },{ -- Guardian
                role = Self.ROLE_TANK,
                attribute = LE_UNIT_STAT_AGILITY,
                artifact = {id = 128821, relics = {RELIC_SLOT_TYPE_FIRE, RELIC_SLOT_TYPE_BLOOD, RELIC_SLOT_TYPE_LIFE}, twinId = 128822}
            },{ -- Restoration
                role = Self.ROLE_HEAL,
                attribute = LE_UNIT_STAT_INTELLECT,
                artifact = {id = 128306, relics = {RELIC_SLOT_TYPE_LIFE, RELIC_SLOT_TYPE_FROST, RELIC_SLOT_TYPE_LIFE}}
            }
        }
    },
    [Unit.HUNTER] = {
        armor = {LE_ITEM_ARMOR_GENERIC, LE_ITEM_ARMOR_MAIL},
        weapons = {LE_ITEM_WEAPON_AXE1H, LE_ITEM_WEAPON_SWORD1H, LE_ITEM_WEAPON_DAGGER, LE_ITEM_WEAPON_UNARMED, LE_ITEM_WEAPON_POLEARM, LE_ITEM_WEAPON_STAFF, LE_ITEM_WEAPON_BOWS, LE_ITEM_WEAPON_CROSSBOW, LE_ITEM_WEAPON_GUNS},
        specs = {
            {   -- Beast Mastery
                role = Self.ROLE_RANGED,
                attribute = LE_UNIT_STAT_AGILITY,
                artifact = {id = 128861, relics = {RELIC_SLOT_TYPE_WIND, RELIC_SLOT_TYPE_ARCANE, RELIC_SLOT_TYPE_IRON}}
            },{ -- Marksmanship
                role = Self.ROLE_RANGED,
                attribute = LE_UNIT_STAT_AGILITY,
                artifact = {id = 128826, relics = {RELIC_SLOT_TYPE_WIND, RELIC_SLOT_TYPE_BLOOD, RELIC_SLOT_TYPE_LIFE}}
            },{ -- Survival
                role = Self.ROLE_MELEE,
                attribute = LE_UNIT_STAT_AGILITY,
                artifact = {id = 128808, relics = {RELIC_SLOT_TYPE_WIND, RELIC_SLOT_TYPE_IRON, RELIC_SLOT_TYPE_BLOOD}}
            }
        }
    },
    [Unit.MAGE] = {
        armor = {LE_ITEM_ARMOR_GENERIC, LE_ITEM_ARMOR_CLOTH},
        weapons = {LE_ITEM_WEAPON_SWORD1H, LE_ITEM_WEAPON_DAGGER, LE_ITEM_WEAPON_WAND, LE_ITEM_WEAPON_STAFF},
        specs = {
            {   -- Arcane
                role = Self.ROLE_RANGED,
                attribute = LE_UNIT_STAT_INTELLECT,
                artifact = {id = 127857, relics = {RELIC_SLOT_TYPE_ARCANE, RELIC_SLOT_TYPE_FROST, RELIC_SLOT_TYPE_ARCANE}}
            },{ -- Fire
                role = Self.ROLE_RANGED,
                attribute = LE_UNIT_STAT_INTELLECT,
                artifact = {id = 128820, relics = {RELIC_SLOT_TYPE_FIRE, RELIC_SLOT_TYPE_ARCANE, RELIC_SLOT_TYPE_FIRE}, twinId = 133959}
            },{ -- Frost
                role = Self.ROLE_RANGED,
                attribute = LE_UNIT_STAT_INTELLECT,
                artifact = {id = 128862, relics = {RELIC_SLOT_TYPE_FROST, RELIC_SLOT_TYPE_ARCANE, RELIC_SLOT_TYPE_FROST}}
            }
        }
    },
    [Unit.MONK] = {
        armor = {LE_ITEM_ARMOR_GENERIC, LE_ITEM_ARMOR_LEATHER},
        weapons = {LE_ITEM_WEAPON_AXE1H, LE_ITEM_WEAPON_MACE1H, LE_ITEM_WEAPON_SWORD1H, LE_ITEM_WEAPON_UNARMED, LE_ITEM_WEAPON_POLEARM, LE_ITEM_WEAPON_STAFF},
        specs = {
            {   -- Brewmaster
                role = Self.ROLE_TANK,
                attribute = LE_UNIT_STAT_AGILITY,
                weapons = Self.TYPES_2HWEAPON,
                artifact = {id = 128938, relics = {RELIC_SLOT_TYPE_LIFE, RELIC_SLOT_TYPE_WIND, RELIC_SLOT_TYPE_IRON}}
            },{ -- Mistweaver
                role = Self.ROLE_HEAL,
                attribute = LE_UNIT_STAT_INTELLECT,
                artifact = {id = 128937, relics = {RELIC_SLOT_TYPE_FROST, RELIC_SLOT_TYPE_LIFE, RELIC_SLOT_TYPE_WIND}}
            },{ -- Windwalker
                role = Self.ROLE_MELEE,
                attribute = LE_UNIT_STAT_AGILITY,
                weapons = Self.TYPES_1HWEAPON,
                artifact = {id = 128940, relics = {RELIC_SLOT_TYPE_WIND, RELIC_SLOT_TYPE_IRON, RELIC_SLOT_TYPE_WIND}, twinId = 0}
            }
        }
    },
    [Unit.PALADIN] = {
        armor = {LE_ITEM_ARMOR_GENERIC, LE_ITEM_ARMOR_PLATE, LE_ITEM_ARMOR_SHIELD},
        weapons = {LE_ITEM_WEAPON_AXE1H, LE_ITEM_WEAPON_MACE1H, LE_ITEM_WEAPON_SWORD1H, LE_ITEM_WEAPON_AXE2H, LE_ITEM_WEAPON_MACE2H, LE_ITEM_WEAPON_SWORD2H, LE_ITEM_WEAPON_POLEARM},
        specs = {
            {   -- Holy
                role = Self.ROLE_HEAL,
                attribute = LE_UNIT_STAT_INTELLECT,
                artifact = {id = 128823, relics = {RELIC_SLOT_TYPE_HOLY, RELIC_SLOT_TYPE_LIFE, RELIC_SLOT_TYPE_HOLY}}
            },{ -- Protection
                role = Self.ROLE_TANK,
                attribute = LE_UNIT_STAT_STRENGTH,
                weapons = Self.TYPES_1HWEAPON,
                artifact = {id = 128866, relics = {RELIC_SLOT_TYPE_HOLY, RELIC_SLOT_TYPE_IRON, RELIC_SLOT_TYPE_ARCANE}, twinId = 0}
            },{ -- Retribution
                role = Self.ROLE_MELEE,
                attribute = LE_UNIT_STAT_STRENGTH,
                weapons = Self.TYPES_2HWEAPON,
                artifact = {id = 120978, relics = {RELIC_SLOT_TYPE_HOLY, RELIC_SLOT_TYPE_FIRE, RELIC_SLOT_TYPE_HOLY}}
            }
        }
    },
    [Unit.PRIEST] = {
        armor = {LE_ITEM_ARMOR_GENERIC, LE_ITEM_ARMOR_CLOTH},
        weapons = {LE_ITEM_WEAPON_MACE1H, LE_ITEM_WEAPON_DAGGER, LE_ITEM_WEAPON_WAND, LE_ITEM_WEAPON_STAFF},
        specs = {
            {   -- Discipline
                role = Self.ROLE_HEAL,
                attribute = LE_UNIT_STAT_INTELLECT,
                artifact = {id = 128868, relics = {RELIC_SLOT_TYPE_HOLY, RELIC_SLOT_TYPE_SHADOW, RELIC_SLOT_TYPE_HOLY}}
            },{ -- Holy
                role = Self.ROLE_HEAL,
                attribute = LE_UNIT_STAT_INTELLECT,
                artifact = {id = 128825, relics = {RELIC_SLOT_TYPE_HOLY, RELIC_SLOT_TYPE_LIFE, RELIC_SLOT_TYPE_HOLY}}
            },{ -- Shadow
                role = Self.ROLE_RANGED,
                attribute = LE_UNIT_STAT_INTELLECT,
                artifact = {id = 128827, relics = {RELIC_SLOT_TYPE_SHADOW, RELIC_SLOT_TYPE_BLOOD, RELIC_SLOT_TYPE_SHADOW}, twinId = 0}
            }
        }
    },
    [Unit.ROGUE] = {
        armor = {LE_ITEM_ARMOR_GENERIC, LE_ITEM_ARMOR_LEATHER},
        weapons = {LE_ITEM_WEAPON_AXE1H, LE_ITEM_WEAPON_MACE1H, LE_ITEM_WEAPON_SWORD1H, LE_ITEM_WEAPON_DAGGER, LE_ITEM_WEAPON_UNARMED, LE_ITEM_WEAPON_THROWN},
        specs = {
            {   -- Assassination
                role = Self.ROLE_MELEE,
                attribute = LE_UNIT_STAT_AGILITY,
                artifact = {id = 128870, relics = {RELIC_SLOT_TYPE_SHADOW, RELIC_SLOT_TYPE_IRON, RELIC_SLOT_TYPE_BLOOD}, twinId = 0}
            },{ -- Outlaw
                role = Self.ROLE_MELEE,
                attribute = LE_UNIT_STAT_AGILITY,
                artifact = {id = 128872, relics = {RELIC_SLOT_TYPE_BLOOD, RELIC_SLOT_TYPE_IRON, RELIC_SLOT_TYPE_WIND}, twinId = 0}
            },{ -- Subtlety
                role = Self.ROLE_MELEE,
                attribute = LE_UNIT_STAT_AGILITY,
                artifact = {id = 128476, relics = {RELIC_SLOT_TYPE_FEL, RELIC_SLOT_TYPE_SHADOW, RELIC_SLOT_TYPE_FEL}, twinId = 0}
            }
        }
    },
    [Unit.SHAMAN] = {
        armor = {LE_ITEM_ARMOR_GENERIC, LE_ITEM_ARMOR_MAIL, LE_ITEM_ARMOR_SHIELD},
        weapons = {LE_ITEM_WEAPON_AXE1H, LE_ITEM_WEAPON_MACE1H, LE_ITEM_WEAPON_DAGGER, LE_ITEM_WEAPON_UNARMED, LE_ITEM_WEAPON_AXE2H, LE_ITEM_WEAPON_MACE2H, LE_ITEM_WEAPON_STAFF},
        specs = {
            {   -- Elemental
                role = Self.ROLE_RANGED,
                attribute = LE_UNIT_STAT_INTELLECT,
                artifact = {id = 128935, relics = {RELIC_SLOT_TYPE_WIND, RELIC_SLOT_TYPE_FROST, RELIC_SLOT_TYPE_WIND}, twinId = 0}
            },{ -- Enhancement
                role = Self.ROLE_MELEE,
                attribute = LE_UNIT_STAT_AGILITY,
                weapons = Self.TYPES_1HWEAPON,
                artifact = {id = 128819, relics = {RELIC_SLOT_TYPE_FIRE, RELIC_SLOT_TYPE_IRON, RELIC_SLOT_TYPE_WIND}}
            },{ -- Restoration
                role = Self.ROLE_HEAL,
                attribute = LE_UNIT_STAT_INTELLECT,
                artifact = {id = 128911, relics = {RELIC_SLOT_TYPE_LIFE, RELIC_SLOT_TYPE_FROST, RELIC_SLOT_TYPE_LIFE}}
            }
        }
    },
    [Unit.WARLOCK] = {
        armor = {LE_ITEM_ARMOR_GENERIC, LE_ITEM_ARMOR_CLOTH},
        weapons = {LE_ITEM_WEAPON_SWORD1H, LE_ITEM_WEAPON_DAGGER, LE_ITEM_WEAPON_WAND, LE_ITEM_WEAPON_STAFF},
        specs = {
            {   -- Affliction
                role = Self.ROLE_RANGED,
                attribute = LE_UNIT_STAT_INTELLECT,
                artifact = {id = 128942, relics = {RELIC_SLOT_TYPE_SHADOW, RELIC_SLOT_TYPE_BLOOD, RELIC_SLOT_TYPE_SHADOW}}
            },{ -- Demonology
                role = Self.ROLE_RANGED,
                attribute = LE_UNIT_STAT_INTELLECT,
                artifact = {id = 128943, relics = {RELIC_SLOT_TYPE_SHADOW, RELIC_SLOT_TYPE_FIRE, RELIC_SLOT_TYPE_FEL}}
            },{ -- Destruction
                role = Self.ROLE_RANGED,
                attribute = LE_UNIT_STAT_INTELLECT,
                artifact = {id = 128941, relics = {RELIC_SLOT_TYPE_FEL, RELIC_SLOT_TYPE_FIRE, RELIC_SLOT_TYPE_FEL}}
            }
        }
    },
    [Unit.WARRIOR] = {
        armor = {LE_ITEM_ARMOR_GENERIC, LE_ITEM_ARMOR_PLATE, LE_ITEM_ARMOR_SHIELD},
        weapons = {LE_ITEM_WEAPON_AXE1H, LE_ITEM_WEAPON_MACE1H, LE_ITEM_WEAPON_SWORD1H, LE_ITEM_WEAPON_DAGGER, LE_ITEM_WEAPON_UNARMED, LE_ITEM_WEAPON_AXE2H, LE_ITEM_WEAPON_MACE2H, LE_ITEM_WEAPON_SWORD2H, LE_ITEM_WEAPON_POLEARM, LE_ITEM_WEAPON_STAFF, LE_ITEM_WEAPON_BOWS, LE_ITEM_WEAPON_CROSSBOW, LE_ITEM_WEAPON_GUNS, LE_ITEM_WEAPON_THROWN},
        specs = {
            {   -- Arms
                role = Self.ROLE_MELEE,
                attribute = LE_UNIT_STAT_STRENGTH,
                weapons = Self.TYPES_2HWEAPON,
                artifact = {id = 128910, relics = {RELIC_SLOT_TYPE_IRON, RELIC_SLOT_TYPE_BLOOD, RELIC_SLOT_TYPE_SHADOW}}
            },{ -- Fury
                role = Self.ROLE_MELEE,
                attribute = LE_UNIT_STAT_STRENGTH,
                weapons = Self.TYPES_2HWEAPON,
                artifact = {id = 128908, relics = {RELIC_SLOT_TYPE_FIRE, RELIC_SLOT_TYPE_WIND, RELIC_SLOT_TYPE_IRON}}
            },{ -- Protection
                role = Self.ROLE_TANK,
                attribute = LE_UNIT_STAT_STRENGTH,
                weapons = Self.TYPES_1HWEAPON,
                artifact = {id = 128289, relics = {RELIC_SLOT_TYPE_IRON, RELIC_SLOT_TYPE_BLOOD, RELIC_SLOT_TYPE_FIRE}}
            }
        }
    }
}

-------------------------------------------------------
--                     Trinkets                      --
-------------------------------------------------------

-- Trinket types
Self.TRINKET_STR = LE_UNIT_STAT_STRENGTH    -- 1
Self.TRINKET_AGI = LE_UNIT_STAT_AGILITY     -- 2
Self.TRINKET_INT = LE_UNIT_STAT_INTELLECT   -- 4
Self.TRINKET_HEAL = Self.ROLE_HEAL          -- 16
Self.TRINKET_TANK = Self.ROLE_TANK          -- 32
Self.TRINKET_MELEE = Self.ROLE_MELEE        -- 64
Self.TRINKET_RANGED = Self.ROLE_RANGED      -- 128

-- Bit mask to check trinket list entries
Self.MASK_ATTR = 0x0f
Self.MASK_ROLE = 0xf0

if Addon.DEBUG then
    -- The specs we use to scan for trinket types
    Self.TRINKET_SPECS = {
        [Self.TRINKET_STR] =    {Unit.WARRIOR, 1},  -- Arms Warrior
        [Self.TRINKET_AGI] =    {Unit.ROGUE, 1},    -- Assasination Rogue
        [Self.TRINKET_INT] =    {Unit.MAGE, 1},     -- Arcane Mage
        [Self.TRINKET_RANGED] = {Unit.HUNTER, 2},   -- Marksmanship Hunter
        [Self.TRINKET_HEAL] =   {Unit.PRIEST, 2},   -- Holy Priest
        [Self.TRINKET_TANK] =   {Unit.WARRIOR, 3}   -- Protection Warrior
    }

    Self.TRINKET_UPDATE_TRIES = 2
    Self.TRINKET_UPDATE_PER_TRY = 1

    -- Completely rebuild the trinket list
    function Self.UpdateTrinkets(tier, isRaid, instance, difficulty)
        tier = tier or 1
        isRaid = (isRaid == true or isRaid == 1) and 1 or 0
        instance = instance or 1
        difficulty = difficulty or 1

        local timeout = Self.TRINKET_UPDATE_TRIES * Self.TRINKET_UPDATE_PER_TRY

        -- First run
        if tier == 1 and isRaid == 0 and instance == 1 and difficulty == 1 then
            Addon:Info("Updating trinket list from Dungeon Journal ...")
            wipe(Self.TRINKETS)
            Util.TblInspect(Self.TRINKETS)
        end
        
        -- Go through all tiers, dungeon/raid, instances and difficulties
        for t=tier,EJ_GetNumTiers() do
            EJ_SelectTier(t)
            for r=isRaid,1 do
                while EJ_GetInstanceByIndex(instance, r == 1) do
                    local i, name = EJ_GetInstanceByIndex(instance, r == 1)
                    EJ_SelectInstance(i)
                    for d=difficulty,99 do
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

    -- Update trinkets for once instance+difficulty
    function Self.UpdateInstanceTrinkets(tier, instance, difficulty, timeLeft)
        timeLeft = timeLeft or Self.TRINKET_UPDATE_TRIES * Self.TRINKET_UPDATE_PER_TRY
        if timeLeft < Self.TRINKET_UPDATE_PER_TRY then return end
    
        -- Prevent the encounter journal to interfere
        if _G.EncounterJournal then _G.EncounterJournal:UnregisterAllEvents() end

        EJ_SelectTier(tier)
        EJ_SelectInstance(instance)
        EJ_SetDifficulty(difficulty)
        EJ_SetSlotFilter(LE_ITEM_FILTER_TYPE_TRINKET)
        
        -- Get trinkets for all the reference specs
        local t = {}
        for n,info in pairs(Self.TRINKET_SPECS) do
            EJ_SetLootFilter(info[1], GetSpecializationInfoForClassID(unpack(info)))
            for i=1,EJ_GetNumLoot() do
                local id, _, _, _, _, _, link = EJ_GetLootInfoByIndex(i)
                t[id] = (t[id] or 0) + n
            end
        end

        -- Determine the least specific category for each trinket
        for id,v in pairs(t) do
            local str =     bit.band(v, Self.TRINKET_STR)
            local agi =    (bit.band(v, Self.TRINKET_AGI) > 0    or bit.band(v, Self.TRINKET_RANGED) > 0) and Self.TRINKET_AGI or 0
            local int =    (bit.band(v, Self.TRINKET_INT) > 0    or bit.band(v, Self.TRINKET_HEAL) > 0)   and Self.TRINKET_INT or 0
            local tank =    bit.band(v, Self.TRINKET_TANK)
            local heal =    bit.band(v, Self.TRINKET_HEAL)
            local melee =  (bit.band(v, Self.TRINKET_STR) > 0    or bit.band(v, Self.TRINKET_AGI) > 0)    and Self.TRINKET_MELEE or 0
            local ranged = (bit.band(v, Self.TRINKET_RANGED) > 0 or bit.band(v, Self.TRINKET_INT) > 0)    and Self.TRINKET_RANGED or 0

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
    function Self.ExportTrinkets(loaded)
        if not loaded and next(Self.TRINKETS) then
            for id in pairs(Self.TRINKETS) do GetItemInfo(id) end
            Addon:ScheduleTimer(Self.ExportTrinkets, 1, true)
        else
            local txt = "Self.TRINKETS = {"
            for id,cat in pairs(Self.TRINKETS) do
                local space1 = (" "):rep(6 - strlen(id))
                local space2 = (" "):rep(3 - strlen(cat))
                txt = txt .. ("\n    [%d] = %s%d, %s-- %s"):format(id, space1, cat, space2, GetItemInfo(id) or "?")
            end

            GUI.ShowExportWindow("Export trinkets", txt .. "\n}")
        end
    end
end

Self.TRINKETS = {
    [24376] =  32,  -- Runed Fungalcap
    [78003] =  32,  -- Indomitable Pride
    [112849] = 20,  -- Thok's Acid-Grooved Tooth
    [112913] = 65,  -- Skeer's Bloodsoaked Talisman
    [124230] = 132, -- Prophecy of Fear
    [37723] =  195, -- Incisor Fragment
    [140790] = 65,  -- Claw of the Crystalline Scorpid
    [161378] = 194, -- Plume of the Seaborne Avian
    [56393] =  65,  -- Heart of Solace
    [112850] = 65,  -- Thok's Tail Tip
    [68925] =  148, -- Variable Pulse Lightning Capacitor
    [124231] = 20,  -- Flickering Felspark
    [155881] = 194, -- Harlan's Loaded Dice
    [140792] = 132, -- Erratic Metronome
    [161380] = 148, -- Drust-Runed Icicle
    [127173] = 148, -- Shiffar's Nexus-Horn
    [140793] = 20,  -- Perfectly Preserved Cake
    [124232] = 20,  -- Intuition's Gift
    [37660] =  148, -- Forge Ember
    [127493] = 195, -- Meteorite Whetstone
    [26055] =  20,  -- Oculus of the Hidden Eye
    [140794] = 66,  -- Arcanogolem Digit
    [144119] = 148, -- Empty Fruit Barrel
    [56394] =  194, -- Tia's Grace
    [56458] =  97,  -- Mark of Khardros
    [68927] =  194, -- The Hungerer
    [124233] = 20,  -- Demonic Phylactery
    [140796] = 195, -- Entwined Elemental Foci
    [65026] =  194, -- Prestor's Talisman of Machination
    [137344] = 32,  -- Talisman of the Cragshaper
    [96421] =  32,  -- Fortitude of the Zandalari
    [140797] = 32,  -- Fang of Tichondrius
    [124234] = 20,  -- Unstable Felshadow Emulsion
    [144122] = 97,  -- Carbonic Carbuncle
    [70399] =  194, -- Ruthless Gladiator's Badge of Conquest
    [140798] = 134, -- Icon of Rot
    [56427] =  194, -- Left Eye of Rajh
    [156016] = 195, -- Pyrite Infuser
    [140799] = 65,  -- Might of Krosus
    [28789] =  148, -- Eye of Magtheridon
    [54573] =  148, -- Glowing Twilight Scale
    [70400] =  97,  -- Ruthless Gladiator's Badge of Victory
    [140800] = 132, -- Pharamere's Forbidden Grimoire
    [158319] = 194, -- My'das Talisman
    [140801] = 134, -- Fury of the Burning Sky
    [68994] =  194, -- Matrix Restabilizer
    [137349] = 134, -- Naraxas' Spiked Tongue
    [70401] =  148, -- Ruthless Gladiator's Badge of Dominance
    [133641] = 134, -- Eye of Skovald
    [46038] =  227, -- Dark Matter
    [112792] = 32,  -- Vial of Living Corruption
    [140803] = 20,  -- Etraeus' Celestial Map
    [68995] =  97,  -- Vessel of Acceleration
    [144128] = 32,  -- Heart of Fire
    [39229] =  148, -- Embrace of the Spider
    [47477] =  148, -- Reign of the Dead
    [156021] = 148, -- Energy Siphon
    [140804] = 132, -- Star Gate
    [156277] = 20,  -- Spark of Hope
    [150523] = 20,  -- Memento of Tyrande
    [86131] =  32,  -- Vial of Dragon's Blood
    [65124] =  148, -- Fall of Mortality
    [86323] =  32,  -- Stuff of Nightmares
    [124238] = 65,  -- Empty Drinking Horn
    [70403] =  97,  -- Ruthless Gladiator's Insignia of Victory
    [136714] = 20,  -- Amalgam's Seventh Spine
    [50259] =  148, -- Nevermelting Ice Crystal
    [72897] =  194, -- Arrow of Time
    [133646] = 20,  -- Mote of Sanctification
    [124239] = 32,  -- Imbued Stone Sigil
    [150526] = 227, -- Shadowmoon Insignia
    [70404] =  194, -- Ruthless Gladiator's Insignia of Conquest
    [136716] = 134, -- Caged Horror
    [65029] =  20,  -- Jar of Ancient Remedies
    [150527] = 227, -- Madness of the Betrayer
    [86133] =  132, -- Light of the Cosmos
    [72898] =  148, -- Foul Gift of the Demon Lord
    [96555] =  32,  -- Soul Barrier
    [124240] = 32,  -- Warlord's Unseeing Eye
    [158712] = 97,  -- Rezan's Gleaming Eye
    [137357] = 67,  -- Mark of Dargrul
    [137485] = 132, -- Infernal Writ
    [112476] = 32,  -- Rook's Unlucky Talisman
    [50260] =  20,  -- Ephemeral Snowflake
    [36993] =  32,  -- Seal of the Pantheon
    [56462] =  148, -- Gale of Shadows
    [112924] = 32,  -- Curse of Hubris
    [124241] = 32,  -- Anzu's Cursed Plume
    [144136] = 148, -- Vision of the Predator
    [32483] =  148, -- The Skull of Gul'dan
    [27416] =  32,  -- Fetish of the Fallen
    [133268] = 65,  -- Heart of Solace
    [72900] =  32,  -- Veil of Lies
    [86327] =  20,  -- Spirits of the Sun
    [124242] = 32,  -- Tyrant's Decree
    [159611] = 97,  -- Razdunk's Big Red Button
    [133269] = 194, -- Tia's Grace
    [136978] = 32,  -- Ember of Nullification
    [159612] = 194, -- Azerokk's Resonating Heart
    [137362] = 32,  -- Parjesh's Medallion
    [56431] =  65,  -- Right Eye of Rajh
    [56463] =  20,  -- Corrupted Egg Shell
    [96558] =  132, -- Unerring Vision of Lei Shen
    [156288] = 132, -- Elemental Focus Stone
    [119192] = 20,  -- Ironspike Chew Toy
    [28823] =  148, -- Eye of Gruul
    [116315] = 132, -- Furyheart Talisman
    [45466] =  148, -- Scale of Fates
    [27896] =  20,  -- Alembic of Infernal Power
    [159614] = 194, -- Galecaller's Boon
    [87160] =  32,  -- Stuff of Nightmares
    [128144] = 227, -- Vial of Vile Viscera
    [94513] =  132, -- Wushoolay's Final Choice
    [119193] = 65,  -- Horn of Screaming Spirits
    [127441] = 195, -- Hourglass of the Unraveller
    [116316] = 20,  -- Captured Flickerspark
    [50198] =  195, -- Needle-Encrusted Scorpion
    [56400] =  132, -- Sorrowsong
    [128145] = 194, -- Howling Soul Gem
    [156036] = 148, -- Eye of the Broodmother
    [94514] =  20,  -- Horridon's Last Gasp
    [119194] = 132, -- Goren Soul Repository
    [159617] = 194, -- Lustrous Golden Plumage
    [137367] = 134, -- Stormsinger Fulmination Charge
    [159618] = 32,  -- Mchimba's Ritual Bandages
    [96369] =  194, -- Renataki's Soul Charm
    [128146] = 148, -- Ensnared Orb of the Sky
    [34470] =  148, -- Timbal's Focusing Crystal
    [96561] =  20,  -- Lightning-Imbued Chalice
    [27529] =  32,  -- Figurine of the Colossus
    [159619] = 97,  -- Briny Barnacle
    [137369] = 67,  -- Giant Ornamental Pearl
    [159620] = 148, -- Conch of Dark Whispers
    [45148] =  148, -- Living Flame
    [128147] = 148, -- Teardrop of Blood
    [113889] = 20,  -- Elementalist's Shielding Talisman
    [50359] =  148, -- Althor's Abacus
    [161411] = 148, -- T'zane's Barkspines
    [45308] =  148, -- Eye of the Broodmother
    [37220] =  32,  -- Essence of Gossamer
    [156041] = 32,  -- Furnace Stone
    [161412] = 194, -- Spiritbound Voodoo Burl
    [151310] = 132, -- Reality Breacher
    [159622] = 132, -- Hadal's Nautilus
    [123992] = 32,  -- Figurine of the Colossus
    [128148] = 97,  -- Fetid Salivation
    [34471] =  20,  -- Vial of the Sunwell
    [159623] = 194, -- Dead-Eye Spyglass
    [137373] = 194, -- Tempered Egg of Serpentrix
    [151312] = 32,  -- Ampoule of Pure Void
    [159624] = 132, -- Rotcrusted Voodoo Doll
    [56370] =  32,  -- Heart of Thunder
    [133282] = 194, -- Skardyn's Grace
    [128149] = 227, -- Accusation of Inferiority
    [94518] =  32,  -- Delicate Vial of the Sanguinaire
    [159625] = 97,  -- Vial of Animated Blood
    [40258] =  148, -- Forethought Talisman
    [159626] = 32,  -- Lingering Sporepods
    [128150] = 194, -- Pressure-Compressed Loop
    [34472] =  195, -- Shard of Contempt
    [94519] =  65,  -- Primordius' Talisman of Rage
    [159627] = 97,  -- Jes' Howler
    [151955] = 132, -- Acrid Catalyst Injector
    [56339] =  148, -- Tendrils of Burrowing Dark
    [11815] =  227, -- Hand of Justice
    [128151] = 148, -- Portent of Disaster
    [113893] = 32,  -- Blast Furnace Door
    [94520] =  20,  -- Inscribed Bag of Hydra-Spawn
    [27770] =  32,  -- Argussian Compass
    [144156] = 148, -- Flashfrozen Resin Globule
    [127448] = 20,  -- Scarab of the Infinite Cycle
    [127512] = 148, -- Winged Talisman
    [151957] = 20,  -- Ishkar's Felshield Emitter
    [151190] = 67,  -- Specter of Betrayal
    [144157] = 148, -- Vial of Ichorous Blood
    [159630] = 148, -- Balefire Branch
    [128152] = 148, -- Decree of Demonic Sovereignty
    [34473] =  32,  -- Commendation of Kael'thas
    [94521] =  132, -- Breath of the Hydra
    [118114] = 194, -- Meaty Dragonspine Trophy
    [37638] =  32,  -- Offering of Sacrifice
    [69138] =  32,  -- Spidersilk Spindle
    [37734] =  20,  -- Talisman of Troll Divinity
    [144159] = 148, -- Price of Progress
    [160655] = 97,  -- Syringe of Bloodborne Infirmity
    [59441] =  194, -- Prestor's Talisman of Machination
    [59473] =  194, -- Essence of the Cyclone
    [128153] = 97,  -- Unquenchable Doomfire Censer
    [151960] = 20,  -- Carafe of Searing Light
    [94522] =  194, -- Talisman of Bloodlust
    [156308] = 20,  -- Sif's Remembrance
    [109995] = 194, -- Blood Seal of Azzakel
    [69139] =  148, -- Necromantic Focus
    [133291] = 32,  -- Throngus's Finger
    [45535] =  148, -- Show of Faith
    [144161] = 97,  -- Lessons of the Darkmaster
    [86147] =  20,  -- Qin-xi's Polarizing Seal
    [133420] = 194, -- Arrow of Time
    [151962] = 134, -- Prototype Personnel Decimator
    [94523] =  194, -- Bad Juju
    [156310] = 195, -- Mjolnir Runestone
    [109996] = 194, -- Thundertower's Targeting Reticle
    [151963] = 195, -- Forgefiend's Fabricator
    [112426] = 132, -- Purified Bindings of Immerseus
    [50235] =  32,  -- Ick's Rotting Thumb
    [59506] =  97,  -- Crushing Weight
    [151964] = 67,  -- Seeping Scourgewing
    [37064] =  195, -- Vestige of Haldor
    [77197] =  194, -- Wrath of Unchaining
    [109997] = 194, -- Kihra's Adrenaline Injector
    [152093] = 67,  -- Gorshalach's Legacy
    [87172] =  65,  -- Darkmist Vortex
    [113834] = 32,  -- Pol's Blinded Eye
    [96507] =  20,  -- Stolen Relic of Zuldazar
    [94525] =  20,  -- Stolen Relic of Zuldazar
    [77198] =  132, -- Will of Unbinding
    [109998] = 194, -- Gor'ashan's Lodestone Spike
    [156187] = 148, -- Scale of Fates
    [113835] = 132, -- Shards of Nothing
    [151968] = 195, -- Shadow-Singed Fang
    [94526] =  65,  -- Spark of Zandalar
    [77199] =  148, -- Heart of Unliving
    [45313] =  32,  -- Furnace Stone
    [142506] = 194, -- Eye of Guarm
    [73491] =  97,  -- Cataclysmic Gladiator's Insignia of Victory
    [22321] =  227, -- Heart of Wyrmthalak
    [142507] = 148, -- Brinewater Slime in a Bottle
    [112877] = 20,  -- Dysmorphic Samophlange of Discontinuity
    [94527] =  32,  -- Ji-Kun's Rising Winds
    [77200] =  97,  -- Eye of Unmaking
    [110000] = 132, -- Crushto's Runic Alarm
    [142508] = 97,  -- Chains of the Valorous
    [30665] =  20,  -- Earring of Soulful Meditation
    [151971] = 132, -- Sheath of Asara
    [113645] = 65,  -- Tectus' Beating Heart
    [87175] =  132, -- Essence of Terror
    [11832] =  20,  -- Burst of Knowledge
    [94528] =  32,  -- Soul Barrier
    [77201] =  32,  -- Resolve of Undying
    [110001] = 132, -- Tovra's Lightning Repository
    [124515] = 130, -- Talisman of the Master Tracker
    [158367] = 97,  -- Merektha's Fang
    [133304] = 148, -- Gale of Shadows
    [112815] = 132, -- Frenzied Crystal of Rage
    [127201] = 132, -- Quagmirran's Eye
    [94529] =  65,  -- Gaze of the Twins
    [77202] =  194, -- Starcatcher Compass
    [110002] = 132, -- Fleshrender's Meathook
    [124516] = 132, -- Tome of Shifting Words
    [151975] = 32,  -- Apocalypse Drive
    [56280] =  32,  -- Porcelain Crab
    [137398] = 132, -- Portable Manacracker
    [56440] =  194, -- Skardyn's Grace
    [151976] = 32,  -- Riftworld Codex
    [94530] =  20,  -- Lightning-Imbued Chalice
    [77203] =  148, -- Insignia of the Corrupted Mind
    [110003] = 132, -- Ragewing's Firefang
    [151977] = 32,  -- Diima's Glacial Aegis
    [45507] =  32,  -- The General's Heart
    [65072] =  97,  -- Heart of Rage
    [96385] =  20,  -- Horridon's Last Gasp
    [151978] = 32,  -- Smoldering Titanguard
    [94531] =  132, -- Cha-Ye's Essence of Brilliance
    [77204] =  148, -- Seal of the Seven Signs
    [110004] = 132, -- Coagulated Genesaur Blood
    [73496] =  97,  -- Cataclysmic Gladiator's Badge of Victory
    [46051] =  148, -- Meteorite Crystal
    [151340] = 20,  -- Echo of L'ura
    [56345] =  65,  -- Magnetite Mirror
    [139320] = 67,  -- Ravaged Seed Pod
    [112754] = 194, -- Haromm's Talisman
    [113905] = 32,  -- Tablet of Turnbuckle Teamwork
    [94532] =  194, -- Rune of Re-Origination
    [158374] = 194, -- Tiny Electromental in a Jar
    [110005] = 20,  -- Crystalline Blood Drop
    [69149] =  148, -- Eye of Blazing Power
    [139321] = 132, -- Swarming Plaguehive
    [124519] = 20,  -- Repudiation of War
    [73497] =  148, -- Cataclysmic Gladiator's Insignia of Dominance
    [113650] = 32,  -- Pillar of the Earth
    [139322] = 20,  -- Cocoon of Enforced Solitude
    [65105] =  148, -- Theralion's Mirror
    [113842] = 20,  -- Emblem of Caustic Healing
    [112947] = 194, -- Assurance of Consequence
    [77206] =  32,  -- Soulshifter Vortex
    [156458] = 192, -- Vanquished Clutches of Yogg-Saron
    [69150] =  194, -- Matrix Restabilizer
    [139323] = 134, -- Twisting Wind
    [124520] = 66,  -- Bleeding Hollow Toxin Vessel
    [155947] = 148, -- Living Flame
    [73498] =  148, -- Cataclysmic Gladiator's Badge of Dominance
    [139324] = 32,  -- Goblet of Nightmarish Ichor
    [137406] = 67,  -- Terrorbound Nexus
    [96516] =  132, -- Cha-Ye's Essence of Brilliance
    [112948] = 20,  -- Prismatic Prison of Pride
    [77207] =  194, -- Vial of Shadows
    [110007] = 20,  -- Voidmender's Shadowgem
    [139325] = 67,  -- Spontaneous Appendages
    [32505] =  227, -- Madness of the Betrayer
    [139326] = 132, -- Wriggling Sinew
    [77208] =  132, -- Cunning of the Cruel
    [110008] = 20,  -- Tharbek's Lucky Pebble
    [139327] = 32,  -- Unbridled Fury
    [59224] =  97,  -- Heart of Rage
    [137537] = 194, -- Tirathon's Betrayal
    [46021] =  32,  -- Royal Seal of King Llane
    [56347] =  32,  -- Leaden Despair
    [139328] = 65,  -- Ursoc's Rending Paw
    [45158] =  32,  -- Heart of Iron
    [155952] = 32,  -- Heart of Iron
    [45286] =  195, -- Pyrite Infuser
    [110009] = 20,  -- Leaf of the Ancient Protectors
    [37166] =  195, -- Sphere of Red Dragon's Blood
    [54589] =  148, -- Glowing Twilight Scale
    [124523] = 97,  -- Worldbreaker's Resolve
    [137539] = 67,  -- Faulty Countermeasure
    [147002] = 148, -- Charm of the Rising Tide
    [112503] = 65,  -- Fusion-Fire Core
    [37390] =  195, -- Meteorite Whetstone
    [133192] = 99,  -- Porcelain Crab
    [61047] =  194, -- Vicious Gladiator's Insignia of Conquest
    [147003] = 20,  -- Barbaric Mindslaver
    [77210] =  97,  -- Bone-Link Fetish
    [110010] = 65,  -- Mote of Corruption
    [137541] = 134, -- Moonlit Prism
    [147004] = 20,  -- Sea Star of the Depthmother
    [87057] =  194, -- Bottle of Infinite Stars
    [96456] =  20,  -- Inscribed Bag of Hydra-Spawn
    [147005] = 20,  -- Chalice of Moonlight
    [77211] =  32,  -- Indomitable Pride
    [110011] = 65,  -- Fires of the Sun
    [139333] = 20,  -- Horn of Cenarius
    [127594] = 195, -- Sphere of Red Dragon's Blood
    [147006] = 20,  -- Archive of Faith
    [139334] = 67,  -- Nature's Call
    [45703] =  148, -- Spark of Hope
    [147007] = 20,  -- The Deceiver's Grand Design
    [110012] = 65,  -- Bonemaw's Big Toe
    [28590] =  148, -- Ribbon of Sacrifice
    [56285] =  65,  -- Might of the Ocean
    [139336] = 132, -- Bough of Corruption
    [50339] =  148, -- Sliver of Pure Ice
    [147009] = 67,  -- Infernal Cinders
    [110013] = 65,  -- Emberscale Talisman
    [28830] =  227, -- Dragonspine Trophy
    [37264] =  132, -- Pendulum of Telluric Currents
    [147010] = 195, -- Cradle of Anguish
    [156345] = 32,  -- Royal Seal of King Llane
    [113658] = 65,  -- Bottle of Infesting Spores
    [96523] =  32,  -- Delicate Vial of the Sanguinaire
    [147011] = 67,  -- Vial of Ceaseless Toxins
    [161461] = 148, -- Doom's Hatred
    [110014] = 65,  -- Spores of Alacrity
    [133201] = 148, -- Sea Star
    [147012] = 67,  -- Umbral Moonglaives
    [37872] =  32,  -- Lavanthor's Talisman
    [56414] =  20,  -- Blood of Isiset
    [47271] =  148, -- Solace of the Fallen
    [47303] =  227, -- Death's Choice
    [46312] =  192, -- Vanquished Clutches of Yogg-Saron
    [110015] = 32,  -- Toria's Unseeing Eye
    [154175] = 20,  -- Eonar's Compassion
    [45609] =  227, -- Comet's Trail
    [147015] = 195, -- Engine of Eradication
    [110016] = 32,  -- Solar Containment Unit
    [45929] =  20,  -- Sif's Remembrance
    [133461] = 132, -- Timbal's Focusing Crystal
    [147016] = 134, -- Terror From Below
    [37873] =  148, -- Mark of the War Prisoner
    [142157] = 134, -- Aran's Relaxing Ruby
    [56351] =  20,  -- Tear of Blood
    [133206] = 194, -- Key to the Endless Chamber
    [96398] =  65,  -- Spark of Zandalar
    [113853] = 194, -- Captive Micro-Aberration
    [147017] = 134, -- Tarnished Sentinel Medallion
    [110017] = 32,  -- Enforcer's Stun Grenade
    [47432] =  148, -- Solace of the Fallen
    [47464] =  227, -- Death's Choice
    [133463] = 195, -- Shard of Contempt
    [147018] = 134, -- Spectral Thurible
    [142159] = 67,  -- Bloodstained Handkerchief
    [112703] = 65,  -- Evil Eye of Galakras
    [133464] = 32,  -- Commendation of Kael'thas
    [147019] = 134, -- Tome of Unraveling Sanity
    [110018] = 32,  -- Kyrak's Vileblood Serum
    [45866] =  132, -- Elemental Focus Stone
    [137301] = 132, -- Corrupted Starlight
    [142161] = 32,  -- Inescapable Dread
    [87065] =  132, -- Light of the Cosmos
    [137430] = 32,  -- Impenetrable Nerubian Husk
    [113983] = 65,  -- Forgemaster's Insignia
    [28288] =  195, -- Abacus of Violent Odds
    [110019] = 32,  -- Xeri'tac's Unhatched Egg Sac
    [127474] = 195, -- Vestige of Haldor
    [160654] = 224, -- Vanquished Tendril of G'huun
    [147022] = 32,  -- Feverish Carapace
    [159616] = 97,  -- Gore-Crusted Butcher's Block
    [159615] = 148, -- Ignition Mage's Fuse
    [153544] = 32,  -- Eye of F'harg
    [154176] = 65,  -- Khaz'goroth's Courage
    [154174] = 194, -- Golganneth's Vitality
    [140806] = 195, -- Convergence of Fates
    [139330] = 20,  -- Heightened Senses
    [147023] = 32,  -- Leviathan's Hunger
    [137400] = 32,  -- Coagulated Nightwell Residue
    [142164] = 67,  -- Toe Knee's Promise
    [151307] = 195, -- Void Stalker's Contract
    [137378] = 20,  -- Bottled Hurricane
    [45931] =  195, -- Mjolnir Runestone
    [137433] = 150, -- Obelisk of the Void
    [128154] = 227, -- Grasp of the Defiler
    [147024] = 32,  -- Reliquary of the Damned
    [113986] = 20,  -- Auto-Repairing Autoclave
    [142165] = 134, -- Deteriorated Construct Core
    [112778] = 20,  -- Nazgrim's Burnished Insignia
    [137306] = 134, -- Oakheart's Gnarled Root
    [112938] = 132, -- Black Blood of Y'Shaarj
    [56449] =  32,  -- Throngus's Finger
    [96501] =  65,  -- Primordius' Talisman of Rage
    [147025] = 32,  -- Recompiled Guardian Module
    [45292] =  148, -- Energy Siphon
    [144146] = 32,  -- Iron Protector Talisman
    [78000] =  148, -- Cunning of the Cruel
    [77209] =  20,  -- Windward Heart
    [156000] = 195, -- Wrathstone
    [34430] =  148, -- Glimmering Naaru Sliver
    [160653] = 32,  -- Xalzaix's Veiled Eye
    [147026] = 32,  -- Shifting Cosmic Sliver
    [161463] = 97,  -- Doom's Fury
    [142167] = 67,  -- Eye of Command
    [32496] =  148, -- Memento of Tyrande
    [133216] = 148, -- Tendrils of Burrowing Dark
    [77989] =  148, -- Seal of the Seven Signs
    [160652] = 194, -- Construct Overcharger
    [160650] = 97,  -- Disc of Systematic Regression
    [156234] = 195, -- Blood of the Old God
    [160648] = 194, -- Frenetic Corpuscle
    [142168] = 32,  -- Majordomo's Dinner Bell
    [161462] = 194, -- Doom's Wake
    [161381] = 194, -- Permafrost-Encrusted Heart
    [161379] = 97,  -- Galecaller's Beak
    [161377] = 148, -- Azurethos' Singed Plumage
    [154173] = 32,  -- Aggramar's Conviction
    [37844] =  148, -- Winged Talisman
    [56290] =  148, -- Sea Star
    [142169] = 32,  -- Raven Eidolon
    [137540] = 20,  -- Concave Reflecting Lens
    [137462] = 20,  -- Jewel of Insatiable Desire
    [77990] =  32,  -- Soulshifter Vortex
    [59519] =  148, -- Theralion's Mirror
    [59354] =  20,  -- Jar of Ancient Remedies
    [113987] = 32,  -- Battering Talisman
    [133224] = 32,  -- Leaden Despair
    [139335] = 32,  -- Grotesque Statuette
    [69167] =  97,  -- Vessel of Acceleration
    [116289] = 194, -- Bloodmaw's Tooth
    [137439] = 67,  -- Tiny Oozeling in a Jar
    [113948] = 132, -- Darmac's Unstable Talisman
    [28727] =  148, -- Pendant of the Violet Eye
    [86132] =  194, -- Bottle of Infinite Stars
    [73643] =  194, -- Cataclysmic Gladiator's Insignia of Conquest
    [133300] = 65,  -- Mark of Khardros
    [133246] = 32,  -- Heart of Thunder
    [137312] = 67,  -- Nightmare Egg Shell
    [137440] = 32,  -- Shivermaw's Jawbone
    [158368] = 20,  -- Fangs of Intertwined Essence
    [86388] =  132, -- Essence of Terror
    [94512] =  194, -- Renataki's Soul Charm
    [144160] = 194, -- Searing Words
    [96492] =  194, -- Talisman of Bloodlust
    [96546] =  194, -- Rune of Re-Origination
    [116290] = 132, -- Emblem of Gushing Wounds
    [96455] =  132, -- Breath of the Hydra
    [77991] =  148, -- Insignia of the Corrupted Mind
    [133766] = 20,  -- Nether Anti-Toxin
    [156230] = 132, -- Flare of the Heavens
    [109999] = 194, -- Witherbark's Branch
    [160651] = 132, -- Vigilant's Bloodshaper
    [151956] = 20,  -- Garothi Feedback Conduit
    [133222] = 65,  -- Magnetite Mirror
    [11819] =  20,  -- Second Wind
    [113861] = 32,  -- Evergaze Arcane Eidolon
    [65048] =  32,  -- Symbiotic Worm
    [28223] =  148, -- Arcanist's Stone
    [156221] = 32,  -- The General's Heart
    [96470] =  65,  -- Fabled Feather of Ji-Kun
    [142162] = 20,  -- Fluctuating Energy
    [137315] = 32,  -- Writhing Heart of Darkness
    [141535] = 97,  -- Ettin Fingernail
    [28190] =  20,  -- Scarab of the Infinite Cycle
    [40371] =  227, -- Bandit's Insignia
    [45518] =  132, -- Flare of the Heavens
    [133462] = 20,  -- Vial of the Sunwell
    [158320] = 20,  -- Revitalizing Voodoo Totem
    [87072] =  65,  -- Lei Shen's Final Orders
    [144477] = 194, -- Splinters of Agronox
    [141536] = 148, -- Padawsen's Unlucky Charm
    [96471] =  32,  -- Ji-Kun's Rising Winds
    [56320] =  148, -- Witching Hourglass
    [110006] = 20,  -- Rukhran's Quill
    [28034] =  195, -- Hourglass of the Unraveller
    [87063] =  32,  -- Vial of Dragon's Blood
    [159610] = 132, -- Vessel of Skittering Shadows
    [116292] = 65,  -- Mote of the Mountain
    [141537] = 194, -- Thrice-Accursed Compass
    [133275] = 132, -- Sorrowsong
    [56407] =  148, -- Anhuur's Hymnal
    [69112] =  194, -- The Hungerer
    [116318] = 32,  -- Stoneheart Idol
    [113854] = 20,  -- Mark of Rapid Replication
    [152645] = 32,  -- Eye of Shatug
    [59500] =  148, -- Fall of Mortality
    [137446] = 134, -- Elementium Bomb Squirrel Generator
    [96413] =  132, -- Wushoolay's Final Choice
    [50346] =  148, -- Sliver of Pure Ice
    [45263] =  195, -- Wrathstone
    [37111] =  20,  -- Soul Preserver
    [47316] =  148, -- Reign of the Dead
    [94516] =  32,  -- Fortitude of the Zandalari
    [133227] = 20,  -- Tear of Blood
    [137484] = 20,  -- Flask of the Solemn Night
    [28370] =  20,  -- Bangle of Endless Blessings
    [133645] = 20,  -- Naglfar Fare
    [156245] = 20,  -- Show of Faith
    [28418] =  148, -- Shiffar's Nexus-Horn
    [140795] = 20,  -- Aluriel's Mirror
    [27683] =  148, -- Quagmirran's Eye
    [133305] = 20,  -- Corrupted Egg Shell
    [96409] =  194, -- Bad Juju
    [124235] = 65,  -- Rumbling Pebble
    [94515] =  65,  -- Fabled Feather of Ji-Kun
    [86332] =  194, -- Terror in the Mists
    [68983] =  148, -- Eye of Blazing Power
    [133644] = 67,  -- Memento of Angerboda
    [77992] =  97,  -- Creche of the Final Dragon
    [144482] = 97,  -- Fel-Oiled Infernal Machine
    [47215] =  20,  -- Tears of the Vanquished
    [137338] = 32,  -- Shard of Rokmora
    [77999] =  194, -- Vial of Shadows
    [127184] = 32,  -- Runed Fungalcap
    [73648] =  194, -- Cataclysmic Gladiator's Badge of Conquest
    [127245] = 148, -- Warp-Scarab Brooch
    [87075] =  20,  -- Qin-xi's Polarizing Seal
    [68926] =  148, -- Jaws of Defeat
    [47214] =  195, -- Banner of Victory
    [133252] = 20,  -- Rainsong
    [140789] = 32,  -- Animated Exoskeleton
    [124223] = 194, -- Fel-Spring Coil
    [77996] =  20,  -- Heart of Unliving
    [124237] = 65,  -- Discordant Chorus
    [77993] =  194, -- Starcatcher Compass
    [68982] =  148, -- Necromantic Focus
    [86336] =  65,  -- Darkmist Vortex
    [77995] =  132, -- Will of Unbinding
    [77997] =  97,  -- Eye of Unmaking
    [128141] = 148, -- Crackling Fel-Spark Plug
    [137538] = 32,  -- Orb of Torment
    [87167] =  194, -- Terror in the Mists
    [11810] =  32,  -- Force of Will
    [36972] =  148, -- Tome of Arcane Phenomena
    [137452] = 20,  -- Thrumming Gossamer
    [86144] =  65,  -- Lei Shen's Final Orders
    [88355] =  194, -- Searing Words
    [124224] = 194, -- Mirror of the Blademaster
    [139329] = 194, -- Bloodthirsty Instinct
    [69110] =  148, -- Variable Pulse Lightning Capacitor
    [113985] = 194, -- Humming Blackiron Trigger
    [133197] = 65,  -- Might of the Ocean
    [133647] = 32,  -- Gift of Radiance
    [68981] =  32,  -- Spidersilk Spindle
    [116291] = 20,  -- Immaculate Living Mushroom
    [50366] =  148, -- Althor's Abacus
    [116317] = 65,  -- Storage House Key
    [136715] = 67,  -- Spiked Counterweight
    [133281] = 32,  -- Impetuous Query
    [142158] = 20,  -- Faith's Crucible
    [77998] =  32,  -- Resolve of Undying
    [113984] = 132, -- Blackiron Micro Crucible
    [113931] = 194, -- Beating Heart of the Mountain
    [124225] = 66,  -- Soul Capacitor
    [77205] =  97,  -- Creche of the Final Dragon
    [69111] =  148, -- Jaws of Defeat
    [138222] = 20,  -- Vial of Nightmare Fog
    [127550] = 32,  -- Offering of Sacrifice
    [24390] =  20,  -- Auslese's Light Channeler
    [124236] = 65,  -- Unending Hunger
    [140805] = 20,  -- Ephemeral Paradox
    [116293] = 32,  -- Idol of Suppression
    [152289] = 20,  -- Highfather's Machination
    [113612] = 194, -- Scales of Doom
    [144480] = 148, -- Dreadstone of Endless Shadows
    [140807] = 32,  -- Infernal Contract
    [65118] =  97,  -- Crushing Weight
    [136975] = 67,  -- Hunger of the Pack
    [77994] =  194, -- Wrath of Unchaining
    [124226] = 194, -- Malicious Censer
    [112768] = 132, -- Kardris' Toxic Totem
    [37657] =  148, -- Spark of Life
    [138224] = 134, -- Unstable Horrorslime
    [137329] = 134, -- Figurehead of the Naglfar
    [150522] = 132, -- The Skull of Gul'dan
    [112729] = 32,  -- Juggernaut's Focusing Crystal
    [72899] =  97,  -- Varo'then's Brooch
    [59332] =  32,  -- Symbiotic Worm
    [56295] =  194, -- Grace of the Herald
    [137486] = 67,  -- Windscar Whetstone
    [138225] = 32,  -- Phantasmal Echo
    [140802] = 194, -- Nightblooming Frond
    [47216] =  32,  -- The Black Heart
    [88294] =  194, -- Flashing Steel Talisman
    [88358] =  97,  -- Lessons of the Darkmaster
    [124227] = 132, -- Iron Reaver Piston
    [94524] =  132, -- Unerring Vision of Lei Shen
    [47213] =  132, -- Abyssal Rune
    [72901] =  65,  -- Rosary of Light
    [27828] =  20,  -- Warp-Scarab Brooch
    [137459] = 67,  -- Chaos Talisman
    [160649] = 20,  -- Inoculating Extract
    [45490] =  148, -- Pandora's Plea
    [45522] =  195, -- Blood of the Old God
    [156207] = 148, -- Pandora's Plea
    [70402] =  148, -- Ruthless Gladiator's Insignia of Dominance
    [61033] =  194, -- Vicious Gladiator's Badge of Conquest
    [65140] =  194, -- Essence of the Cyclone
    [78001] =  20,  -- Windward Heart
    [87163] =  20,  -- Spirits of the Sun
    [96543] =  65,  -- Gaze of the Twins
    [124228] = 132, -- Desecrated Shadowmoon Insignia
    [112879] = 194, -- Ticking Ebon Detonator
    [112825] = 194, -- Sigil of Rampage
    [113859] = 132, -- Quiescent Runestone
    [113969] = 65,  -- Vial of Convulsive Shadows
    [116314] = 194, -- Blackheart Enforcer's Medallion
    [128142] = 148, -- Pledge of Iron Loyalty
    [128143] = 97,  -- Fragmented Runestone Etching
    [128140] = 194, -- Smoldering Felblade Remnant
    [142160] = 134, -- Mrrgria's Favor
    [56328] =  194, -- Key to the Endless Chamber
    [140808] = 67,  -- Draught of Souls
    [140809] = 132, -- Whispers in the Dark
    [78002] =  97,  -- Bone-Link Fetish
    [140791] = 32,  -- Royal Dagger Haft
    [88360] =  20,  -- Price of Progress
    [124229] = 132, -- Unblinking Gaze of Sethe
    [151958] = 20,  -- Tarratus Keystone
    [154177] = 132, -- Norgannon's Prowess
    [151970] = 148, -- Vitality Resonator
    [151969] = 134, -- Terminus Signaling Beacon
    [159628] = 194, -- Kul Tiran Cannonball Runner
    [159631] = 148, -- Lady Waycrest's Music Box
    [161419] = 97,  -- Kraulok's Claw
    [161376] = 97,  -- Prism of Dark Intensity
    [144113] = 194, -- Windswept Pages
    [160656] = 148, -- Twitching Tentacle of Xalzaix
}