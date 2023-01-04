---@type string, Addon
local Name, Addon = ...
local Version = GetAddOnMetadata("PersoLootRoll", "Version")

---@class Addon: AceAddon-3.0, AceConsole-3.0, AceComm-3.0, AceSerializer-3.0, AceEvent-3.0, AceTimer-3.0, AceHook-3.0
---@field db AddonOptionsData
---@field Test Tests
local Self = LibStub("AceAddon-3.0"):NewAddon(Addon, Name, "AceConsole-3.0", "AceComm-3.0", "AceSerializer-3.0", "AceEvent-3.0", "AceTimer-3.0", "AceHook-3.0")

-- Constants
Self.ABBR = "PLR"
Self.VERSION = tonumber(Version) or Version
Self.DEBUG = false

-- Modules
---@class Module: AceModule
local Module = {}
---@type Module
Self.Module = {}

---@param self self
---@return boolean
function Module:ShouldBeEnabled(...) return self.enableState end

function Module:CheckState(...)
    if Self.Util.Bool.XOR(self:ShouldBeEnabled(...), self.enabledState) then
        if not self.initialized then
            self:SetEnabledState(not self.enabledState)
        else
            self[self.enabledState and "Disable" or "Enable"](self)
        end
    end
    self.initialized = true
end

-- Core

---@type Options
Self.Options = {}
---@type Roll
Self.Roll = {}

-- Util

---@type Comm
Self.Comm = {}
---@type Item
Self.Item = {}
---@type Locale
Self.Locale = {}
---@type Unit
Self.Unit = {}
---@type Util
Self.Util = {}

-- Modules

---@class GUI: Module, AceEvent-3.0
Self.GUI = Self:NewModule("GUI", Module, "AceEvent-3.0")
---@class Inspect: Module, AceEvent-3.0, AceTimer-3.0
Self.Inspect = Self:NewModule("Inspect", Module, "AceEvent-3.0", "AceTimer-3.0")
---@class Session: Module, AceEvent-3.0
Self.Session = Self:NewModule("Session", Module, "AceEvent-3.0")
---@class Trade: Module, AceEvent-3.0
Self.Trade = Self:NewModule("Trade", Module, "AceEvent-3.0")

-- Plugins

---@class EPGP: Module, AceEvent-3.0, AceTimer-3.0
Self.EPGP = Self:NewModule("EPGP", Module, "AceEvent-3.0", "AceTimer-3.0")
---@class PLH: Module, AceEvent-3.0
Self.PLH = Self:NewModule("PLH", Module, "AceEvent-3.0")
---@class RCLC: Module, AceEvent-3.0, AceTimer-3.0, AceSerializer-3.0
Self.RCLC = Self:NewModule("RCLC", Module, "AceEvent-3.0", "AceTimer-3.0", "AceSerializer-3.0")

-- TODO: DEBUG
if true or Self.DEBUG then
    PLR = Self
end