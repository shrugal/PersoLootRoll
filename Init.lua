local Name, Addon = ...
LibStub("AceAddon-3.0"):NewAddon(Addon, Name, "AceConsole-3.0", "AceComm-3.0", "AceSerializer-3.0", "AceEvent-3.0", "AceTimer-3.0", "AceHook-3.0")
Addon.PREFIX = "PLR"
Addon.PREFIX_CHAT = "[" .. Addon.PREFIX .. "]"
Addon.VERSION = 1
Addon.DEBUG = true

if Addon.DEBUG then
    PLR = Addon
end