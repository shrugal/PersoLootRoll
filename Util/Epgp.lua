local Name, Addon = ...
local Self = Addon.Epgp

local EPGP = LibStub("AceAddon-3.0"):GetAddon("EPGP", true)
local LGP = LibStub:GetLibrary("LibGearPoints-1.2", true)
local GS = LibStub:GetLibrary("LibGuildStorage-1.2", true)

function Self.IsEpgpEnabled()
    return EPGP and Addon.db.profile.masterloot.epgp.enabled
end

function Self.GetValue(item)
    return LGP:GetValue(item)
end

function Self.GetEpgp(name)
    local name = Self.GetEpgpName(name)
    local ep, gp, main = EPGP:GetEPGP(name)
    return ep, gp, main
end

function Self.GetMinEp()
    return EPGP.db.profile.min_ep
end

-- These utilities are borrowed, in whole or in part, from `RCLootCouncil - EPGP` by Safetee - LGPLv3

function Self.GetEpgpName(inputName)
    if not inputName then return nil end

    --------- First try to find name in the raid ------------------------------
    local name, realm
    name = Ambiguate(inputName, "short") -- Convert to short name to be used as the argument to UnitFullName
    local _, ourRealmName = UnitFullName("player") -- Get the name of our realm WITHOUT SPACE.

    name, realm = UnitFullName(name) -- In order to return a name with correct capitialization, and the realm name WITHOUT SPACE.
    if name then -- Found the name in the raid
        if realm and realm ~= "" then
            return name.."-"..realm
        else
            return name.."-"..ourRealmName
        end
    else -- Name not found in raid, fix capitialiation and space in realm name manually.
        local shortName, realmName = strsplit("-", inputName)
        if not realmName then
            realmName = ourRealmName
        end
        shortName = UpperFirstLowerRest(shortName)
        realmName = realmName:gsub(" ", "") -- Eliminate space in the name
        return shortName.."-"..realmName
    end
end

function Self.IncGPSecure(name, reason, amount)
    name = Self.GetEpgpName(name)
    if not GS:IsCurrentState() then
        return Addon:ScheduleTimer("Epgp:IncGPSecure", 0.5, name, reason, amount)
    end
    if not EPGP:CanIncGPBy(reason, amount) then
        Addon:Err("IncGPSecure fails CanIncGPBy" .. "," .. name .. "," .. reason .."," .. amount)
        return
    end
    EPGP:IncGPBy(name, reason, amount)
end

