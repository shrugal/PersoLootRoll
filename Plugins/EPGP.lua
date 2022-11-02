---@type string
local Name = ...
---@type Addon
local Addon = select(2, ...)
---@type L
local L = LibStub("AceLocale-3.0"):GetLocale(Name)
local EPGP = LibStub("AceAddon-3.0"):GetAddon("EPGP", true)
local LGP = LibStub("LibGearPoints-1.2", true)
local GS = LibStub("LibGuildStorage-1.2", true)
local GUI, Options, Roll, Session, Unit, Util = Addon.GUI, Addon.Options, Addon.Roll, Addon.Session, Addon.Unit, Addon.Util
---@class EPGP : Module
local Self = Addon.EPGP

Self.NAME = "EPGP"

-- How often GP credit operations should be retried by default
Self.CREDIT_MAX_TRYS = 5

-- Config
Options.DEFAULTS.profile.plugins.EPGP = {
    enabled = false,
    onlyGuildRaid = true,
    awardBefore = Roll.AWARD_BIDS,
    bidWeights = {
        [Roll.BID_NEED] = 1,
        [Roll.BID_GREED] = 1,
        [Roll.BID_DISENCHANT] = 0
    }
}

-- Remember GPs we credited, so we can undo them if necessary
Self.credited = {}

-------------------------------------------------------
--                      Get info                     --
-------------------------------------------------------

-- Get a unit's EP
---@param unit string
---@return number
function Self.UnitEP(unit)
    return (EPGP:GetEPGP(Unit.FullName(unit)))
end

-- Get a unit's GP
---@param unit string
---@return number
function Self.UnitGP(unit)
    return (select(2, EPGP:GetEPGP(Unit.FullName(unit))))
end

-- Get a unit's PR
---@param unit string
---@return number?
function Self.UnitPR(unit)
    local ep, gp = EPGP:GetEPGP(Unit.FullName(unit))
    return ep and gp and gp ~= 0 and Util.Num.Round(ep/gp, 2) or nil
end

-- Check if a unit has enough EP
function Self.UnitHasMinEP(unit)
    local ep, minEp = Self.UnitEP(unit), EPGP.db.profile.min_ep
    return not minEp or ep and ep >= minEp or false
end

-- Get the GP value for a roll
---@param roll Roll
---@return number
function Self.RollGP(roll)
    if not roll.winner or not roll.bids[roll.winner] then
        return 0
    else
        local bid, weights = roll.bids[roll.winner], Self.db.profile.bidWeights
        return Util.Num.Round((LGP:GetValue(roll.item.link) or 0) * (weights[bid] or weights[floor(bid)] or 0))
    end
end

-------------------------------------------------------
--                       Award                       --
-------------------------------------------------------

-- Pick the player with the highest PR value
---@param candidates table
function Self.DetermineWinner(_, candidates)
    Util(candidates)
        :Map(function (unit) return Self.UnitHasMinEP(unit) and 1 or 0 end, true, true)
        :Only(Util.Tbl.Max(candidates))
        :Map(function (unit) return Self.UnitPR(unit) or 0 end, true, true)
        :Only(Util.Tbl.Max(candidates))
end

-- Add EP to the unit's account
---@param roll Roll
---@param unit string
---@param amount integer
---@param undo boolean?
---@param trys integer?
function Self.CreditGP(roll, unit, amount, undo, trys)
    local link, gp = roll.item.link, undo and -amount or amount

    if trys == 0 then
        Addon:Error(L["EPGP_ERROR_CREDIT_GP_FAILED"], gp, unit, link)
    elseif not GS:IsCurrentState() then
        Self:ScheduleTimer(Self.UnitCreditEP, 0.5, roll, unit, amount, undo, (trys or Self.CREDIT_MAX_TRYS) - 1)
    elseif not EPGP:CanIncGPBy(link, gp) then
        Addon:Error(L["EPGP_ERROR_CREDIT_GP_FAILED"], gp, unit, link)
    else
        Addon:Verbose(L["EPGP_CREDIT_GP"], gp, unit, link)
        EPGP:IncGPBy(Unit.FullName(unit), link, gp, false, undo)
        Self.credited[roll.id] = not undo and unit .. ":" .. amount or nil
    end
end

-- Try undoing a previous GP credit for the given roll
function Self.UndoGPCredit(roll)
    if Self.credited[roll.id] then
        local prevWinner, gp = (":"):split(Self.credited[roll.id])
        Self.CreditGP(roll, prevWinner, gp, true)
    end
end

-------------------------------------------------------
--                      Options                      --
-------------------------------------------------------

function Self.GetBidWeightOptions(bid, it)
    local rules = Addon.db.profile.masterloot.rules
    local answer = Util.Select(bid, Roll.BID_NEED, Roll.ANSWER_NEED, Roll.BID_GREED, Roll.ANSWER_GREED)
    local answers = Util.Select(bid, Roll.BID_NEED, rules.needAnswers, Roll.BID_GREED, rules.greedAnswers)

    local options = {
        name = L["ROLL_BID_" .. bid],
        type = "group",
        order = it(),
        inline = true,
        args = {}
    }

    local name = function (info)
        if answers and answers[info.arg] and answers[info.arg] ~= answer then
            return answers[info.arg]
        else
            return Util.Str.Join(" ", not (info.arg == 0 and answers and Util.Tbl.Find(answers, answer)) and L["ROLL_BID_" .. bid], info.arg == 0 and "(" .. DEFAULT .. ")")
        end
    end
    local get = function (info)
        return "" .. (Self.db.profile.bidWeights[bid + info.arg/10] or Self.db.profile.bidWeights[bid] or "")
    end
    local set = function (info, val)
        local i = bid + info.arg/10
        Self.db.profile.bidWeights[i] = tonumber(val) or Self.db.defaults.bidWeights[i] or nil
    end
    local hidden = function (info)
        return not answers or not answers[info.arg]
    end

    for i=0, answers and 9 or 0 do
        options.args["weight" .. i] = {
            name = name,
            type = "input",
            order = it(),
            arg = i,
            get = get,
            set = set,
            hidden = i ~= 0 and hidden,
            width = Options.WIDTH_FIFTH_SCROLL
        }
    end

    return options
end

-- Register module options
function Self.RegisterOptions()
    Options.CustomOptions:Add("epgp", Options.CAT_MASTERLOOT, "epgp", function ()
        local it = Util.Iter()

        return {
            name = L["EPGP"],
            type = "group",
            args = {
                desc = {type = "description", fontSize = "medium", order = it(), name = L["EPGP_OPT_DESC"] .. "\n"},
                warningNoAddon = {type = "description", fontSize = "medium", order = it(), name = L["EPGP_OPT_WARNING_NO_ADDON"] .. "\n", hidden = function () return IsAddOnLoaded("EPGP") end},
                warningNoOfficer = {type = "description", fontSize = "medium", order = it(), name = L["EPGP_OPT_WARNING_NO_OFFICER"] .. "\n", hidden = CanEditOfficerNote},
                enable = {
                    name = L["OPT_ENABLE"],
                    desc = L["OPT_ENABLE_MODULE_DESC"],
                    type = "toggle",
                    order = it(),
                    set = function (_, val)
                        Self.db.profile.enabled = val
                        Self:CheckState()
                    end,
                    get = function (_) return Self.db.profile.enabled end,
                    width = Options.WIDTH_THIRD_SCROLL
                },
                onlyGuildRaid = {
                    name = L["EPGP_OPT_ONLY_GUILD_RAID"],
                    desc = L["EPGP_OPT_ONLY_GUILD_RAID_DESC"]:format(Util.GROUP_THRESHOLD*100),
                    type = "toggle",
                    order = it(),
                    set = function (_, val)
                        Self.db.profile.onlyGuildRaid = val
                        Self:CheckState()
                    end,
                    get = function (_, key) return Self.db.profile.onlyGuildRaid end,
                    width = Options.WIDTH_THIRD_SCROLL
                },
                awardBefore = {
                    name = L["EPGP_OPT_AWARD_BEFORE"],
                    desc = L["EPGP_OPT_AWARD_BEFORE_DESC"],
                    type = "select",
                    order = it(),
                    values = Util.Tbl.Copy(Roll.AWARD_METHODS, function (v) return L["ROLL_AWARD_" .. v] end),
                    get = function () return Util.Tbl.Find(Roll.AWARD_METHODS, Self.db.profile.awardBefore) end,
                    set = function (_, val)
                        val = Roll.AWARD_METHODS[val] or Roll.AWARD_BIDS

                        Self.db.profile.awardBefore = val
                        Roll.AwardMethods:Add("epgp", Self.DetermineWinner, val)
                        GUI.PlayerColumns:Update("epgp", "sortBefore", Util.Select(val, Roll.AWARD_VOTES, "votes", Roll.AWARD_BIDS, "bid", Roll.AWARD_ROLLS, "roll", "ilvl"))
                    end,
                    width = Options.WIDTH_THIRD_SCROLL
                },
                ["space" .. it()] = {type = "description", fontSize = "medium", order = it(0), name = " ", cmdHidden = true, dropdownHidden = true},
                bidWeights = {type = "header", order = it(), name = L["EPGP_OPT_BID_WEIGHTS"]},
                bidWeightsDesc = {type = "description", fontSize = "medium", order = it(), name = L["EPGP_OPT_BID_WEIGHTS_DESC"] .. "\n"},
                bidWeightsNeed = Self.GetBidWeightOptions(Roll.BID_NEED, it),
                bidWeightsGreed = Self.GetBidWeightOptions(Roll.BID_GREED, it),
                bidWeightsDisenchant = Self.GetBidWeightOptions(Roll.BID_DISENCHANT, it)
            }
        }
    end, function (data, isImport)
        if isImport then
            -- Import
            Self.db.profile.awardBefore = Util.Default(data.epgpAwardBefore, Self.db.defaults.awardBefore)

            Self.db.profile.bidWeights = Util.Tbl.Copy(Self.db.defaults.bidWeights)
            if data.epgpBidWeights then
                for i,v in data.epgpBidWeights:gmatch("(-?%d*%.?%d*) ?= ?(-?%d*%.?%d*)") do
                    i, v = tonumber(i), tonumber(v)
                    if i and v then Self.db.profile.bidWeights[i] = v end
                end
            end
        else
            -- Export
            if Self.db.profile.awardBefore ~= Self.db.defaults.awardBefore then
                data.epgpAwardBefore = Self.db.profile.awardBefore
            end

            if not Util.Tbl.Equals(Self.db.profile.bidWeights, Self.db.defaults.bidWeights) then
                data.epgpBidWeights = Util(Self.db.profile.bidWeights)
                    :Copy(function (v, i) return v ~= Self.db.defaults.bidWeights[i] and ("%s=%s"):format(i, v) or nil end, true)
                    :Concat(", ")()
            end
        end
    end)
end

-------------------------------------------------------
--                    Events/Hooks                   --
-------------------------------------------------------

function Self:ShouldBeEnabled()
    return IsAddOnLoaded(Self.NAME)
        and Self.db.profile.enabled
        and IsInRaid()
        and Addon:IsTracking()
        and (not Self.db.profile.onlyGuildRaid or IsInGuild() and Util.IsGuildGroup((GetGuildInfo("player"))))
end

function Self:OnInitialize()
    -- DB and options
    Self.db = {profile = Addon.db.profile.plugins.EPGP, defaults = Addon.db.defaults.profile.plugins.EPGP}
    Self.RegisterOptions()

    -- State
    Self:CheckState()
    Self:RegisterEvent("RAID_ROSTER_UPDATE", Self.CheckState)
    Self:RegisterMessage(Addon.EVENT_TRACKING_CHANGE, Self.CheckState)
end

function Self:OnEnable()
    -- Add custom player columns
    GUI.PlayerColumns:Add("epgpEP", Self.UnitEP, L["EPGP_EP"])
    GUI.PlayerColumns:Add("epgpGP", Self.UnitGP, L["EPGP_GP"])
    GUI.PlayerColumns:Add("epgpPR", Self.UnitPR, L["EPGP_PR"], nil, nil, "bid", 0, true)
    GUI.PlayerColumns:Add("epgpMinEP", Self.UnitHasMinEP, nil, nil, nil, "epgpPR", nil, true)

    -- Add custom award method
    Roll.AwardMethods:Add("epgp", Self.DetermineWinner, Self.db.profile.awardBefore)

    -- Register events
    Self:RegisterMessage(Roll.EVENT_AWARD, "ROLL_AWARD")
    Self:RegisterMessage(Roll.EVENT_RESTART, "ROLL_RESTART")
    Self:RegisterMessage(Roll.EVENT_CLEAR, "ROLL_CLEAR")
    EPGP.RegisterCallback(Self, "StandingsChanged", "EPGP_STANDINGS_CHANGED")
end

function Self:OnDisable()
    -- Remove custom player colums
    GUI.PlayerColumns:Remove("epgpEP", "epgpGP", "epgpPR", "epgpMinEP")

    -- Remove custom award method
    Roll.AwardMethods:Remove("epgp")

    -- Unregister events
    Self:UnregisterMessage(Roll.EVENT_AWARD)
    Self:UnregisterMessage(Roll.EVENT_RESTART)
    Self:UnregisterMessage(Roll.EVENT_CLEAR)
    EPGP.UnregisterCallback(Self, "StandingsChanged")
end

---@param roll Roll
---@param winner string
function Self:ROLL_AWARD(_, roll, winner)
    if Session.IsMasterlooter() and roll.isOwner and not roll.isTest then
        Self.UndoGPCredit(roll)

        -- Credit the winner
        local gp = Self.RollGP(roll)
        if gp > 0 and winner and IsGuildMember(winner) then
            Self.CreditGP(roll, winner, gp)
        end
    end
end

---@param roll Roll
function Self:ROLL_RESTART(_, roll)
    Self.UndoGPCredit(roll)
end

---@param roll Roll
function Self:ROLL_CLEAR(_, roll)
    Self.credited[roll.id] = nil
end

function Self:EPGP_STANDINGS_CHANGED()
    GUI.Rolls.Update()
end