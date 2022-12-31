---@diagnostic disable: duplicate-set-field
---@meta

---
-- This class contains EmmyLua annotations to help
-- IDEs work with some external classes and types
---

-- WoW methods

---@class stringlib
---@field split fun(delimiter: string, str: string, pieces?: integer): ...: string
---@field trim fun(str: string): string

---@class string
---@field split fun(self: self, delimiter: string, pieces?: integer): ...: string
---@field trim fun(self: self): self

---@return integer
time = function() end

---@param text string
function SetGuildInfoText(text) end

---@param unit string
---@return boolean
function IsGuildMember(unit) end

-- WoW constants

RELIC_SLOT_TYPE_ARCANE = "Arcane"
RELIC_SLOT_TYPE_BLOOD = "Blood"
RELIC_SLOT_TYPE_FEL = "Fel"
RELIC_SLOT_TYPE_FIRE = "Fire"
RELIC_SLOT_TYPE_FROST = "Frost"
RELIC_SLOT_TYPE_HOLY = "Holy"
RELIC_SLOT_TYPE_IRON = "Iron"
RELIC_SLOT_TYPE_LIFE = "Life"
RELIC_SLOT_TYPE_SHADOW = "Shadow"
RELIC_SLOT_TYPE_WIND = "Wind"

---@class C_FriendList
---@field GetFriendInfo fun(friendIndex: number): FriendInfo
C_FriendList = {}

---@class DifficultyUtil
---@field GetDifficultyName function
---@field GetNextPrimaryRaidDifficultyID function
---@field GetMaxPlayers function
---@field IsPrimaryRaid function
DifficultyUtil = {
    ID = {
        DungeonNormal = 1,
        DungeonHeroic = 2,
        Raid10Normal = 3,
        Raid25Normal = 4,
        Raid10Heroic = 5,
        Raid25Heroic = 6,
        RaidLFR = 7,
        DungeonChallenge = 8,
        Raid40 = 9,
        PrimaryRaidNormal = 14,
        PrimaryRaidHeroic = 15,
        PrimaryRaidMythic = 16,
        PrimaryRaidLFR = 17,
        DungeonMythic = 23,
        DungeonTimewalker = 24,
        RaidTimewalker = 33,
    },
}

-- WoW frames

---@type Frame
EncounterJournal = {}

---@class GroupRollFrame: Frame
---@field rollID integer | string
---@field Timer unknown

-- Ace3 modules

---@class AceComm-3.0: AceModule
---@field callbacks table<string, function>
---@field SendCommMessage fun(prefix: string, text: string, distribution: string, target: string?, prio: string?, callbackFn: function?, callbackArg: any?)
---@field RegisterComm fun(self: self, prefix: string, method: function): unknown

---@class AceConfigCmd-3.0: AceModule
---@field HandleCommand fun(self: AceModule, slashcmd: string, appName: string, input: string)

---@class AceConfigDialog-3.0
---@field ConfigTableChanged fun(self: self, event: string, appName: string)

---@class AceConfigRegistry-3.0
---@field GetOptionsTable fun(self: self, appName: string): fun(...: string): table
---@field NotifyChange fun(self: self, appName: string)

---@class AceEvent-3.0
---@field messages CallbackHandlerRegistry
---@field UnregisterAllMessages fun()
---@field UnregisterAllEvents fun()

---@class AceGUI-3.0
---@field Create fun(self: self, type: AceGUIWidgetType|"Dropdown-Pullout")

---@class Frame
---@field obj? AceGUIWidget

---@class AceGUIWidget
---@field frame Frame
---@field userdata table<string, any>

---@class AceGUIContainer
---@field children table<integer, AceGUIWidget>
---@field content? Frame
---@field localstatus? table<string, any>
---@field status? table<string, any>

---@class AceGUIIcon
---@field frame Button
---@field image Texture

---@class AceGUILabel
---@field label FontString
---@field image Texture

---@class AceHook-3.0: AceModule
---@field hooks table<string, function>
---@field IsHooked (fun(self: self, method: string): boolean)|(fun(self: self, obj: table, method: string):boolean)
---@field HookScript fun(self: self, frame: Frame, script: string, handler: function)
---@field RawHook fun(self: self, method: string, handler: function, hookSecure?: boolean)|fun(self: self, object: table, method: string, handler: function, hookSecure?: boolean)
---@field RawHookScript fun(self: self, frame: Frame, script: string, handler: function)
---@field SecureHook fun(self: self, method: string, handler: function)
---@field SecureHookScript fun(self: self, frame: Frame, script: string, handler: function)
---@field Unhook fun(self: self, method: string)|fun(self: self, object: table, method: string)

---@class AceLocale-3.0
---@field apps table

-- CallbackHandler-1.0

---@class CallbackHandler-1.0
---@field RegisterCallback function
---@field UnregisterCallback function
---@field UnregisterAllCallbacks function

-- LibDBIcon-1.0

---@class LibDBIcon-1.0
---@field Register fun(self: self, name: string, plugin: table, db: table)

-- LibGearPoints-1.2

---@class LibGearPoints-1.2
---@field GetValue function

-- LibGuildStorage-1.2

---@class LibGuildStorage-1.2
---@field IsCurrentState function

-- LibRealmInfo

---@class LibRealmInfo
---@field GetCurrentRegion fun(self: self): string
---@field GetRealmInfo fun(self: self, name: string, region?: string): string, string, string, string, string, unknown, string, string, table<string>, string, string
---@field GetRealmInfoByID fun(self: self, id: number): string, string, string, string, string, unknown, string, string, table<string>, string, string
---@field GetRealmInfoByUnit fun(self: self, unit: string): string, string, string, string, string, unknown, string, string, table<string>, string, string

-- EPGP

---@class EPGPAddon: AceAddon, CallbackHandler-1.0
---@field db table
---@field GetEPGP function
---@field CanIncGPBy function
---@field IncGPBy function