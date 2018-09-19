local Name, Addon = ...
local Version = GetAddOnMetadata("PersoLootRoll", "Version")
LibStub("AceAddon-3.0"):NewAddon(Addon, Name, "AceConsole-3.0", "AceComm-3.0", "AceSerializer-3.0", "AceEvent-3.0", "AceTimer-3.0", "AceHook-3.0")

-- Constants
Addon.ABBR = "PLR"
Addon.VERSION = tonumber(Version) or Version
Addon.DEBUG = false

-- Core
Addon.GUI = {}
Addon.Options = {}
Addon.Roll = {}

-- Util
Addon.Comm = {}
Addon.Item = {}
Addon.Locale = {}
Addon.Unit = {}
Addon.Util = {}

-- Modules
Addon.Inspect = Addon:NewModule("Inspect", nil, "AceEvent-3.0")
Addon.Session = Addon:NewModule("Session", nil, "AceEvent-3.0")
Addon.Trade = Addon:NewModule("Trade", nil, "AceEvent-3.0")

-- Plugins
Addon.PLH = Addon:NewModule("PLH", nil, "AceEvent-3.0")

-- TODO: DEBUG
if true or Addon.DEBUG then
    PLR = Addon
end