local Name, Addon = ...
local L = LibStub("AceLocale-3.0"):GetLocale(Name)
local EPGP = LibStub("AceAddon-3.0"):GetAddon("EPGP", true)
local LGP = LibStub:GetLibrary("LibGearPoints-1.2", true)
local GS = LibStub:GetLibrary("LibGuildStorage-1.2", true)
local GUI, Options, Roll, Util = Addon.GUI, Addon.Options, Addon.Roll, Addon.Util
local Self = Addon.EPGP

-- How often GP credit operations should be retried by default
Self.CREDIT_MAX_TRYS = 5

-- Config
Options.DEFAULTS.profile.modules.EPGP = {
    enabled = false,
    onlyGuildRaid = true
}

-------------------------------------------------------
--                      Get info                     --
-------------------------------------------------------

-- Get a unit's EP
function Self.UnitEP(unit)
    return (EPGP:GetEPGP(unit))
end

-- Get a unit's GP
function Self.UnitGP(unit)
    return (select(2, EPGP:GetEPGP(unit)))
end

-- Get a unit's PR
function Self.UnitPR(unit)
    local ep, gp = EPGP:GetEPGP(unit)
    return ep and gp and gp ~= 0 and ep/gp or nil
end

-- Check if a unit has enough EP
function Self.UnitHasMinEP(unit)
    local ep, minEp = Self.UnitEP(unit), EPGP.db.profile.min_ep
    return not minEp or ep and ep >= minEp or false
end

-------------------------------------------------------
--                     Awarding                      --
-------------------------------------------------------

-- Pick the player with the highest PR value
function Self.DetermineWinner(roll, candidates)
    if Addon.db.profile.module.EPGP.onlyGuildRaid and not (IsInRaid() and IsInGuild() and Util.IsGuildGroup(Unit.GuildName("player"))) then
        return
    end

    Util(candidates)
        .Map(function (_, unit) return Self.UnitPR(unit) or 0 end)
        .Only(Util.TblMax(candidates))
end

-- Get the GP value for an item and bid
function Self.ItemGP(link, bid)
    return bid and floor(bid) == Roll.BID_NEED and LGP:GetValue(link) or 0
end

-- Add EP to the unit's account
function Self.UnitCreditGP(unit, link, amount, undo, trys)
    if trys == 0 then
        Addon:Error("EPGP_CREDIT_EP_FAILED", unit, link, amount, undo)
    elseif not GS:IsCurrentState() then
        Self:ScheduleTimer(Self.UnitCreditEP, 0.5, unit, link, amount, undo, (trys or Self.CREDIT_MAX_TRYS) - 1)
    elseif not EPGP:CanIncGPBy(link, amount) then
        Addon:Error("EPGP_CREDIT_EP_FAILED", unit, link, amount)
    else
        EPGP:IncGPBy(unit, link, amount, false, undo)
    end
end

-------------------------------------------------------
--                    Events/Hooks                   --
-------------------------------------------------------

function Self:OnInitialize()
    Self:SetEnabledState(Addon.db.profile.modules.EPGP.enabled)

    Options.AddCustomOptions(Options.CUSTOM_MASTERLOOT, "epgp", function ()
        local it = Util.Iter()
        local config = Addon.db.profile.modules.EPGP

        return {
            name = L["EPGP"],
            type = "group",
            args = {
                desc = {type = "description", fontSize = "medium", order = it(), name = L["EPGP_OPT_DESC"] .. "\n"},
                enable = {
                    name = L["OPT_ENABLE"],
                    desc = L["OPT_ENABLE_MODULE_DESC"],
                    type = "toggle",
                    order = it(),
                    set = function (_, val)
                        config.enabled = val
                        Self[val and "Enable" or "Disable"](Self)
                    end,
                    get = function (_) return config.enabled end,
                    width = Options.WIDTH_HALF
                },
                onlyGuildRaid = {
                    name = L["EPGP_OPT_ONLY_GUILD_RAID"],
                    desc = L["EPGP_OPT_ONLY_GUILD_RAID_DESC"]:format(Util.GROUP_THRESHOLD*100),
                    type = "toggle",
                    order = it(),
                    set = function (_, val) config.onlyGuildRaid = val end,
                    get = function (_, key) return config.onlyGuildRaid end,
                    width = Options.WIDTH_HALF
                },
                -- TODO: Bid GP weights
            },
            hidden = function () return not IsAddOnLoaded("EPGP") end
        }
    end)
end

function Self:OnEnable()
    if not IsAddOnLoaded("EPGP") then return end

    GUI.AddPlayerColumn("epgpPr", Self.UnitEP, L["EPGP_PR"], nil, nil, "bid", 0, true)
    GUI.AddPlayerColumn("epgpMinEp", Self.UnitHasMinEP, nil, nil, nil, "epgpPr", nil, true)
    Roll.AddCustomAwardMethod("epgp", Self.DetermineWinner, Roll.AWARD_BIDS) -- TODO: Add option to let bids take precedence

    -- Register events
    Roll.On(Self, Roll.EVENT_AWARD, "ROLL_AWARD")
end

function Self:OnDisable()
    GUI.RemovePlayerColumns("epgpPr", "epgpMinEp")
    Roll.RemoveCustomAwardMethod("epgp", Roll.AWARD_BIDS)

    -- Unregister events
    Roll.Unsubscribe(Self)
end

function Self.ROLL_AWARD(_, _, roll, winner, prevWinner)
    if Session.IsMasterlooter() then
        -- Undo a previous credit if necessary
        if prevWinner and IsGuildMember(prevWinner) then
            local gp = Self.ItemGP(roll.item.link, roll.bids[prevWinner])
            if gp and gp > 0 then
                Self.UnitCreditGP(winner, roll.item.link, -gp, true)
            end
        end

        -- Credit the winner
        if winner and IsGuildMember(winner) then
            local gp = Self.ItemGP(roll.item.link, roll.bids[winner])
            if gp and gp > 0 then
                Self.UnitCreditGP(winner, roll.item.link, gp)
            end
        end
    end
end