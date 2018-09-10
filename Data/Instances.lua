local Name, Addon = ...
local GUI = Addon.GUI
local Self = Addon.Util

if Addon.DEBUG then
    -- Export the instance list
    function Self.ExportInstances()
        local txt = "Self.INSTANCES = {"

        for tier=1,EJ_GetNumTiers() do
            EJ_SelectTier(tier)
            for isRaid=0,1 do
                local instance = 1
                while EJ_GetInstanceByIndex(instance, isRaid == 1) do
                    local id, name = EJ_GetInstanceByIndex(instance, isRaid == 1)
                    local space1 = (" "):rep(4 - strlen(id))
                    local space2 = (" "):rep(1 - strlen(tier))
                    txt = txt .. ("\n    [%d] = %s%d, %s-- %s"):format(id, space1, tier, space2, name or "?")
                    instance = instance + 1
                end
            end
        end

        GUI.ShowExportWindow("Export instances", txt .. "\n}")
    end
end

Self.INSTANCES = {
    [227] =  1, -- Blackfathom Deeps
    [228] =  1, -- Blackrock Depths
    [63] =   1, -- Deadmines
    [230] =  1, -- Dire Maul
    [231] =  1, -- Gnomeregan
    [229] =  1, -- Lower Blackrock Spire
    [232] =  1, -- Maraudon
    [226] =  1, -- Ragefire Chasm
    [233] =  1, -- Razorfen Downs
    [234] =  1, -- Razorfen Kraul
    [311] =  1, -- Scarlet Halls
    [316] =  1, -- Scarlet Monastery
    [246] =  1, -- Scholomance
    [64] =   1, -- Shadowfang Keep
    [236] =  1, -- Stratholme
    [238] =  1, -- The Stockade
    [237] =  1, -- The Temple of Atal'hakkar
    [239] =  1, -- Uldaman
    [240] =  1, -- Wailing Caverns
    [241] =  1, -- Zul'Farrak
    [741] =  1, -- Molten Core
    [742] =  1, -- Blackwing Lair
    [743] =  1, -- Ruins of Ahn'Qiraj
    [744] =  1, -- Temple of Ahn'Qiraj
    [247] =  2, -- Auchenai Crypts
    [248] =  2, -- Hellfire Ramparts
    [249] =  2, -- Magisters' Terrace
    [250] =  2, -- Mana-Tombs
    [251] =  2, -- Old Hillsbrad Foothills
    [252] =  2, -- Sethekk Halls
    [253] =  2, -- Shadow Labyrinth
    [254] =  2, -- The Arcatraz
    [255] =  2, -- The Black Morass
    [256] =  2, -- The Blood Furnace
    [257] =  2, -- The Botanica
    [258] =  2, -- The Mechanar
    [259] =  2, -- The Shattered Halls
    [260] =  2, -- The Slave Pens
    [261] =  2, -- The Steamvault
    [262] =  2, -- The Underbog
    [745] =  2, -- Karazhan
    [746] =  2, -- Gruul's Lair
    [747] =  2, -- Magtheridon's Lair
    [748] =  2, -- Serpentshrine Cavern
    [749] =  2, -- The Eye
    [750] =  2, -- The Battle for Mount Hyjal
    [751] =  2, -- Black Temple
    [752] =  2, -- Sunwell Plateau
    [271] =  3, -- Ahn'kahet: The Old Kingdom
    [272] =  3, -- Azjol-Nerub
    [273] =  3, -- Drak'Tharon Keep
    [274] =  3, -- Gundrak
    [275] =  3, -- Halls of Lightning
    [276] =  3, -- Halls of Reflection
    [277] =  3, -- Halls of Stone
    [278] =  3, -- Pit of Saron
    [279] =  3, -- The Culling of Stratholme
    [280] =  3, -- The Forge of Souls
    [281] =  3, -- The Nexus
    [282] =  3, -- The Oculus
    [283] =  3, -- The Violet Hold
    [284] =  3, -- Trial of the Champion
    [285] =  3, -- Utgarde Keep
    [286] =  3, -- Utgarde Pinnacle
    [753] =  3, -- Vault of Archavon
    [754] =  3, -- Naxxramas
    [755] =  3, -- The Obsidian Sanctum
    [756] =  3, -- The Eye of Eternity
    [759] =  3, -- Ulduar
    [757] =  3, -- Trial of the Crusader
    [760] =  3, -- Onyxia's Lair
    [758] =  3, -- Icecrown Citadel
    [761] =  3, -- The Ruby Sanctum
    [66] =   4, -- Blackrock Caverns
    [63] =   4, -- Deadmines
    [184] =  4, -- End Time
    [71] =   4, -- Grim Batol
    [70] =   4, -- Halls of Origination
    [186] =  4, -- Hour of Twilight
    [69] =   4, -- Lost City of the Tol'vir
    [64] =   4, -- Shadowfang Keep
    [67] =   4, -- The Stonecore
    [68] =   4, -- The Vortex Pinnacle
    [65] =   4, -- Throne of the Tides
    [185] =  4, -- Well of Eternity
    [77] =   4, -- Zul'Aman
    [76] =   4, -- Zul'Gurub
    [75] =   4, -- Baradin Hold
    [73] =   4, -- Blackwing Descent
    [72] =   4, -- The Bastion of Twilight
    [74] =   4, -- Throne of the Four Winds
    [78] =   4, -- Firelands
    [187] =  4, -- Dragon Soul
    [303] =  5, -- Gate of the Setting Sun
    [321] =  5, -- Mogu'shan Palace
    [311] =  5, -- Scarlet Halls
    [316] =  5, -- Scarlet Monastery
    [246] =  5, -- Scholomance
    [312] =  5, -- Shado-Pan Monastery
    [324] =  5, -- Siege of Niuzao Temple
    [302] =  5, -- Stormstout Brewery
    [313] =  5, -- Temple of the Jade Serpent
    [322] =  5, -- Pandaria
    [317] =  5, -- Mogu'shan Vaults
    [330] =  5, -- Heart of Fear
    [320] =  5, -- Terrace of Endless Spring
    [362] =  5, -- Throne of Thunder
    [369] =  5, -- Siege of Orgrimmar
    [547] =  6, -- Auchindoun
    [385] =  6, -- Bloodmaul Slag Mines
    [536] =  6, -- Grimrail Depot
    [558] =  6, -- Iron Docks
    [537] =  6, -- Shadowmoon Burial Grounds
    [476] =  6, -- Skyreach
    [556] =  6, -- The Everbloom
    [559] =  6, -- Upper Blackrock Spire
    [557] =  6, -- Draenor
    [477] =  6, -- Highmaul
    [457] =  6, -- Blackrock Foundry
    [669] =  6, -- Hellfire Citadel
    [777] =  7, -- Assault on Violet Hold
    [740] =  7, -- Black Rook Hold
    [900] =  7, -- Cathedral of Eternal Night
    [800] =  7, -- Court of Stars
    [762] =  7, -- Darkheart Thicket
    [716] =  7, -- Eye of Azshara
    [721] =  7, -- Halls of Valor
    [727] =  7, -- Maw of Souls
    [767] =  7, -- Neltharion's Lair
    [860] =  7, -- Return to Karazhan
    [945] =  7, -- Seat of the Triumvirate
    [726] =  7, -- The Arcway
    [707] =  7, -- Vault of the Wardens
    [822] =  7, -- Broken Isles
    [768] =  7, -- The Emerald Nightmare
    [861] =  7, -- Trial of Valor
    [786] =  7, -- The Nighthold
    [875] =  7, -- Tomb of Sargeras
    [946] =  7, -- Antorus, the Burning Throne
    [959] =  7, -- Invasion Points
    [968] =  8, -- Atal'Dazar
    [1001] = 8, -- Freehold
    [1041] = 8, -- Kings' Rest
    [1036] = 8, -- Shrine of the Storm
    [1023] = 8, -- Siege of Boralus
    [1030] = 8, -- Temple of Sethraliss
    [1012] = 8, -- The MOTHERLODE!!
    [1022] = 8, -- The Underrot
    [1002] = 8, -- Tol Dagor
    [1021] = 8, -- Waycrest Manor
    [1028] = 8, -- Azeroth
    [1031] = 8, -- Uldir
}