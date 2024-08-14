---@type string
local Name = ...
---@class Addon: AceAddon, AceConsole-3.0, AceComm-3.0, AceSerializer-3.0, AceEvent-3.0, AceTimer-3.0, AceHook-3.0
local Addon = select(2, ...)
local Version = C_AddOns.GetAddOnMetadata("PersoLootRoll", "Version")
LibStub("AceAddon-3.0"):NewAddon(Addon, Name, "AceConsole-3.0", "AceComm-3.0", "AceSerializer-3.0", "AceEvent-3.0", "AceTimer-3.0", "AceHook-3.0")

-- Constants
Addon.ABBR = "PLR"
Addon.VERSION = tonumber(Version) or Version
Addon.DEBUG = false

-- Modules
---@class Module: AceModule
local Module = {}
Addon.Module = Module

---@return boolean
function Module:ShouldBeEnabled() return self.enabledState end

function Module:CheckState(...)
    if Addon.Util.Bool.XOR(self:ShouldBeEnabled(...), self.enabledState) then
        if not self.initialized then
            self:SetEnabledState(not self.enabledState)
        else
            self[self.enabledState and "Disable" or "Enable"](self)
        end
    end
    self.initialized = true
end

-- Core
---@class GUI: AceModule, AceEvent-3.0
Addon.GUI = Addon:NewModule("GUI", Module, "AceEvent-3.0")
Addon.Options = {}
Addon.Roll = {}

-- Util
Addon.Comm = {}
Addon.Item = {}
Addon.Locale = {}
Addon.Unit = {}
Addon.Util = {}

-- Modules
---@class Inspect: AceModule, AceEvent-3.0, AceTimer-3.0
Addon.Inspect = Addon:NewModule("Inspect", Module, "AceEvent-3.0", "AceTimer-3.0")
---@class Session: AceModule, AceEvent-3.0
Addon.Session = Addon:NewModule("Session", Module, "AceEvent-3.0")
---@class Trade: AceModule, AceEvent-3.0
Addon.Trade = Addon:NewModule("Trade", Module, "AceEvent-3.0")

-- Plugins
---@class EPGP: AceModule, AceEvent-3.0, AceTimer-3.0
Addon.EPGP = Addon:NewModule("EPGP", Module, "AceEvent-3.0", "AceTimer-3.0")
---@class PLH: AceModule, AceEvent-3.0
Addon.PLH = Addon:NewModule("PLH", Module, "AceEvent-3.0")
---@class RCLC: AceModule, AceEvent-3.0, AceTimer-3.0, AceSerializer-3.0
Addon.RCLC = Addon:NewModule("RCLC", Module, "AceEvent-3.0", "AceTimer-3.0", "AceSerializer-3.0")

-- TODO: DEBUG
if true or Addon.DEBUG then
    PLR = Addon
end