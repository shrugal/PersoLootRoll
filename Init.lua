local Name, Addon = ...
LibStub("AceAddon-3.0"):NewAddon(Addon, Name, "AceConsole-3.0", "AceComm-3.0", "AceSerializer-3.0", "AceEvent-3.0", "AceTimer-3.0", "AceHook-3.0")

-- Constants
Addon.ABBR = "PLR"
Addon.VERSION = 6
Addon.DEBUG = false

-- Modules
Addon.Comm = {}
Addon.Events = {}
Addon.GUI = {}
Addon.Hooks = {}
Addon.Inspect = {}
Addon.Item = {}
Addon.Locale = {}
Addon.Masterloot = {}
Addon.Roll = {}
Addon.Trade = {}
Addon.Unit = {}
Addon.Util = {}

-- TODO: DEBUG
if true or Addon.DEBUG then
    PLR = Addon
end