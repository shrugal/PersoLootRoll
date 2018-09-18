local Name, Addon = ...
local Version = GetAddOnMetadata("PersoLootRoll", "Version")
LibStub("AceAddon-3.0"):NewAddon(Addon, Name, "AceConsole-3.0", "AceComm-3.0", "AceSerializer-3.0", "AceEvent-3.0", "AceTimer-3.0", "AceHook-3.0")

-- Constants
Addon.ABBR = "PLR"
Addon.VERSION = tonumber(Version) or Version
Addon.DEBUG = false

Addon.GUI = {}

-- Util
Addon.Comm = {}
Addon.Locale = {}
Addon.Unit = {}
Addon.Util = {}

-- Modules
Addon.Inspect = Addon:NewModule("Inspect", nil, "AceEvent-3.0")
Addon.Item = Addon:NewModule("Item", nil, "AceEvent-3.0", "AceTimer-3.0")
Addon.Options = Addon:NewModule("Options", nil)
Addon.Session = Addon:NewModule("Session", nil, "AceEvent-3.0")
Addon.Roll = Addon:NewModule("Roll", nil)
Addon.Trade = Addon:NewModule("Trade", nil, "AceEvent-3.0")

-- Plugins
Addon.PersonalLootHelper = Addon:NewModule("PersonalLootHelper", nil, "AceEvent-3.0")

-- TODO: DEBUG
if true or Addon.DEBUG then
    PLR = Addon
end