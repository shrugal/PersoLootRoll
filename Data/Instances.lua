---@type Addon
local Addon = select(2, ...)
local GUI = Addon.GUI

---@class Util
local Self = Addon.Util

-- Export the instance list
function Self.ExportInstances()
    local instances = {}

    for tier=1,EJ_GetNumTiers()-1 do
        EJ_SelectTier(tier)
        for isRaid=0,1 do
            local instance = 1
            while EJ_GetInstanceByIndex(instance, isRaid == 1) do
                local id, name = EJ_GetInstanceByIndex(instance, isRaid == 1)                
                instances[id] = { name, tier }
                instance = instance + 1
            end
        end
    end

    local ids = Self(instances):Keys():Sort()()
    local txt = ""

    for _,id in ipairs(ids) do
        local name, tier = unpack(instances[id])
        local pad = ("0"):rep(4 - strlen(id))
        local space = (" "):rep(2 - strlen(tier))
        txt = txt .. ("\n    [%s%d] = %d, %s-- %s"):format(pad, id, tier, space, name or "?")
    end

    GUI.ShowExportWindow("Export instances", "Self.INSTANCES = {" .. txt .. "\n}")
end

Self.INSTANCES = {
    [0063] = 4,  -- Deadmines
    [0064] = 4,  -- Shadowfang Keep
    [0065] = 4,  -- Throne of the Tides
    [0066] = 4,  -- Blackrock Caverns
    [0067] = 4,  -- The Stonecore
    [0068] = 4,  -- The Vortex Pinnacle
    [0069] = 4,  -- Lost City of the Tol'vir
    [0070] = 4,  -- Halls of Origination
    [0071] = 4,  -- Grim Batol
    [0072] = 4,  -- The Bastion of Twilight
    [0073] = 4,  -- Blackwing Descent
    [0074] = 4,  -- Throne of the Four Winds
    [0075] = 4,  -- Baradin Hold
    [0076] = 4,  -- Zul'Gurub
    [0077] = 4,  -- Zul'Aman
    [0078] = 4,  -- Firelands
    [0184] = 4,  -- End Time
    [0185] = 4,  -- Well of Eternity
    [0186] = 4,  -- Hour of Twilight
    [0187] = 4,  -- Dragon Soul
    [0226] = 1,  -- Ragefire Chasm
    [0227] = 1,  -- Blackfathom Deeps
    [0228] = 1,  -- Blackrock Depths
    [0229] = 1,  -- Lower Blackrock Spire
    [0230] = 1,  -- Dire Maul
    [0231] = 1,  -- Gnomeregan
    [0232] = 1,  -- Maraudon
    [0233] = 1,  -- Razorfen Downs
    [0234] = 1,  -- Razorfen Kraul
    [0236] = 1,  -- Stratholme
    [0237] = 1,  -- The Temple of Atal'hakkar
    [0238] = 1,  -- The Stockade
    [0239] = 1,  -- Uldaman
    [0240] = 1,  -- Wailing Caverns
    [0241] = 1,  -- Zul'Farrak
    [0246] = 5,  -- Scholomance
    [0247] = 2,  -- Auchenai Crypts
    [0248] = 2,  -- Hellfire Ramparts
    [0249] = 2,  -- Magisters' Terrace
    [0250] = 2,  -- Mana-Tombs
    [0251] = 2,  -- Old Hillsbrad Foothills
    [0252] = 2,  -- Sethekk Halls
    [0253] = 2,  -- Shadow Labyrinth
    [0254] = 2,  -- The Arcatraz
    [0255] = 2,  -- The Black Morass
    [0256] = 2,  -- The Blood Furnace
    [0257] = 2,  -- The Botanica
    [0258] = 2,  -- The Mechanar
    [0259] = 2,  -- The Shattered Halls
    [0260] = 2,  -- The Slave Pens
    [0261] = 2,  -- The Steamvault
    [0262] = 2,  -- The Underbog
    [0271] = 3,  -- Ahn'kahet: The Old Kingdom
    [0272] = 3,  -- Azjol-Nerub
    [0273] = 3,  -- Drak'Tharon Keep
    [0274] = 3,  -- Gundrak
    [0275] = 3,  -- Halls of Lightning
    [0276] = 3,  -- Halls of Reflection
    [0277] = 3,  -- Halls of Stone
    [0278] = 3,  -- Pit of Saron
    [0279] = 3,  -- The Culling of Stratholme
    [0280] = 3,  -- The Forge of Souls
    [0281] = 3,  -- The Nexus
    [0282] = 3,  -- The Oculus
    [0283] = 3,  -- The Violet Hold
    [0284] = 3,  -- Trial of the Champion
    [0285] = 3,  -- Utgarde Keep
    [0286] = 3,  -- Utgarde Pinnacle
    [0302] = 5,  -- Stormstout Brewery
    [0303] = 5,  -- Gate of the Setting Sun
    [0311] = 5,  -- Scarlet Halls
    [0312] = 5,  -- Shado-Pan Monastery
    [0313] = 5,  -- Temple of the Jade Serpent
    [0316] = 5,  -- Scarlet Monastery
    [0317] = 5,  -- Mogu'shan Vaults
    [0320] = 5,  -- Terrace of Endless Spring
    [0321] = 5,  -- Mogu'shan Palace
    [0322] = 5,  -- Pandaria
    [0324] = 5,  -- Siege of Niuzao Temple
    [0330] = 5,  -- Heart of Fear
    [0362] = 5,  -- Throne of Thunder
    [0369] = 5,  -- Siege of Orgrimmar
    [0385] = 6,  -- Bloodmaul Slag Mines
    [0457] = 6,  -- Blackrock Foundry
    [0476] = 6,  -- Skyreach
    [0477] = 6,  -- Highmaul
    [0536] = 6,  -- Grimrail Depot
    [0537] = 6,  -- Shadowmoon Burial Grounds
    [0547] = 6,  -- Auchindoun
    [0556] = 6,  -- The Everbloom
    [0557] = 6,  -- Draenor
    [0558] = 6,  -- Iron Docks
    [0559] = 6,  -- Upper Blackrock Spire
    [0669] = 6,  -- Hellfire Citadel
    [0707] = 7,  -- Vault of the Wardens
    [0716] = 7,  -- Eye of Azshara
    [0721] = 7,  -- Halls of Valor
    [0726] = 7,  -- The Arcway
    [0727] = 7,  -- Maw of Souls
    [0740] = 7,  -- Black Rook Hold
    [0741] = 1,  -- Molten Core
    [0742] = 1,  -- Blackwing Lair
    [0743] = 1,  -- Ruins of Ahn'Qiraj
    [0744] = 1,  -- Temple of Ahn'Qiraj
    [0745] = 2,  -- Karazhan
    [0746] = 2,  -- Gruul's Lair
    [0747] = 2,  -- Magtheridon's Lair
    [0748] = 2,  -- Serpentshrine Cavern
    [0749] = 2,  -- The Eye
    [0750] = 2,  -- The Battle for Mount Hyjal
    [0751] = 2,  -- Black Temple
    [0752] = 2,  -- Sunwell Plateau
    [0753] = 3,  -- Vault of Archavon
    [0754] = 3,  -- Naxxramas
    [0755] = 3,  -- The Obsidian Sanctum
    [0756] = 3,  -- The Eye of Eternity
    [0757] = 3,  -- Trial of the Crusader
    [0758] = 3,  -- Icecrown Citadel
    [0759] = 3,  -- Ulduar
    [0760] = 3,  -- Onyxia's Lair
    [0761] = 3,  -- The Ruby Sanctum
    [0762] = 7,  -- Darkheart Thicket
    [0767] = 7,  -- Neltharion's Lair
    [0768] = 7,  -- The Emerald Nightmare
    [0777] = 7,  -- Assault on Violet Hold
    [0786] = 7,  -- The Nighthold
    [0800] = 7,  -- Court of Stars
    [0822] = 7,  -- Broken Isles
    [0860] = 7,  -- Return to Karazhan
    [0861] = 7,  -- Trial of Valor
    [0875] = 7,  -- Tomb of Sargeras
    [0900] = 7,  -- Cathedral of Eternal Night
    [0945] = 7,  -- Seat of the Triumvirate
    [0946] = 7,  -- Antorus, the Burning Throne
    [0959] = 7,  -- Invasion Points
    [0968] = 8,  -- Atal'Dazar
    [1001] = 8,  -- Freehold
    [1002] = 8,  -- Tol Dagor
    [1012] = 8,  -- The MOTHERLODE!!
    [1021] = 8,  -- Waycrest Manor
    [1022] = 8,  -- The Underrot
    [1023] = 8,  -- Siege of Boralus
    [1028] = 8,  -- Azeroth
    [1030] = 8,  -- Temple of Sethraliss
    [1031] = 8,  -- Uldir
    [1036] = 8,  -- Shrine of the Storm
    [1041] = 8,  -- Kings' Rest
    [1176] = 8,  -- Battle of Dazar'alor
    [1177] = 8,  -- Crucible of Storms
    [1178] = 8,  -- Operation: Mechagon
    [1179] = 8,  -- The Eternal Palace
    [1180] = 8,  -- Ny'alotha, the Waking City
    [1182] = 9,  -- The Necrotic Wake
    [1183] = 9,  -- Plaguefall
    [1184] = 9,  -- Mists of Tirna Scithe
    [1185] = 9,  -- Halls of Atonement
    [1186] = 9,  -- Spires of Ascension
    [1187] = 9,  -- Theater of Pain
    [1188] = 9,  -- De Other Side
    [1189] = 9,  -- Sanguine Depths
    [1190] = 9,  -- Castle Nathria
    [1192] = 9,  -- Shadowlands
    [1193] = 9,  -- Sanctum of Domination
    [1194] = 9,  -- Tazavesh, the Veiled Market
    [1195] = 9,  -- Sepulcher of the First Ones
    [1196] = 10, -- Brackenhide Hollow
    [1197] = 10, -- Uldaman: Legacy of Tyr
    [1198] = 10, -- The Nokhud Offensive
    [1199] = 10, -- Neltharus
    [1200] = 10, -- Vault of the Incarnates
    [1201] = 10, -- Algeth'ar Academy
    [1202] = 10, -- Ruby Life Pools
    [1203] = 10, -- The Azure Vault
    [1204] = 10, -- Halls of Infusion
    [1205] = 10, -- Dragon Isles
    [1207] = 10, -- Amirdrassil, the Dream's Hope
    [1208] = 10, -- Aberrus, the Shadowed Crucible
    [1209] = 10, -- Dawn of the Infinite
    [1210] = 11, -- Darkflame Cleft
    [1267] = 11, -- Priory of the Sacred Flame
    [1268] = 11, -- The Rookery
    [1269] = 11, -- The Stonevault
    [1270] = 11, -- The Dawnbreaker
    [1271] = 11, -- Ara-Kara, City of Echoes
    [1272] = 11, -- Cinderbrew Meadery
    [1273] = 11, -- Nerub-ar Palace
    [1274] = 11, -- City of Threads
    [1278] = 11, -- Khaz Algar
}