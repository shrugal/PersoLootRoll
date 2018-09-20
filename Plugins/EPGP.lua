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

-- Get the GP value for a roll
function Self.RollGP(roll)
    if not roll.winner or not roll.bids[roll.winner] then
        return 0
    else
        local bid, weights = roll.bids[roll.winner], Addon.db.profile.plugins.EPGP.bidWeights
        return (LGP:GetValue(roll.item.link) or 0) * (weights[bid] or weights[floor(bid)] or 0)
    end
end

-------------------------------------------------------
--                       Award                       --
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
--                       Helper                      --
-------------------------------------------------------

function Self.GetBidWeightOptions(bid, it)
    local config = Addon.db.profile.plugins.EPGP
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
            return Util.StrJoin(" ", not (info.arg == 0 and answers and Util.TblFind(answers, answer)) and L["ROLL_BID_" .. bid], info.arg == 0 and "(" .. DEFAULT .. ")")
        end
    end
    local get = function (info)
        return "" .. (config.bidWeights[bid + info.arg/10] or config.bidWeights[bid] or "")
    end
    local set = function (info, val)
        config.bidWeights[bid + info.arg/10] = tonumber(val) or info.arg == 0 and 0 or nil
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

-------------------------------------------------------
--                    Events/Hooks                   --
-------------------------------------------------------

function Self:OnInitialize()
    -- Set enabled state
    Self:SetEnabledState(Addon.db.profile.plugins.EPGP.enabled)

    -- Register options
    Options.AddCustomOptions(Options.CUSTOM_MASTERLOOT, "epgp", function ()
        local it = Util.Iter()
        local config = Addon.db.profile.plugins.EPGP

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
                    width = Options.WIDTH_THIRD_SCROLL
                },
                onlyGuildRaid = {
                    name = L["EPGP_OPT_ONLY_GUILD_RAID"],
                    desc = L["EPGP_OPT_ONLY_GUILD_RAID_DESC"]:format(Util.GROUP_THRESHOLD*100),
                    type = "toggle",
                    order = it(),
                    set = function (_, val) config.onlyGuildRaid = val end,
                    get = function (_, key) return config.onlyGuildRaid end,
                    width = Options.WIDTH_THIRD_SCROLL
                },
                awardBefore = {
                    name = L["EPGP_OPT_AWARD_BEFORE"],
                    desc = L["EPGP_OPT_AWARD_BEFORE_DESC"],
                    type = "select",
                    order = it(),
                    values = Util.TblCopy(Roll.AWARD_METHODS, function (v) return L["ROLL_AWARD_" .. v] end),
                    get = function () return Util.TblFind(Roll.AWARD_METHODS, config.awardBefore) end,
                    set = function (_, val)
                        val = Roll.AWARD_METHODS[val] or Roll.AWARD_BIDS

                        config.awardBefore = val
                        Roll.UpdateCustomAwardMethod("epgp", "before", val)
                        GUI.UpdateCustomPlayerColumn("epgp", "sortBefore", Util.Select(val, Roll.AWARD_VOTES, "votes", Roll.AWARD_BIDS, "bid", Roll.AWARD_ROLLS, "roll", "ilvl"))
                    end,
                    width = Options.WIDTH_THIRD_SCROLL
                },
                ["space" .. it()] = {type = "description", fontSize = "medium", order = it(0), name = " ", cmdHidden = true, dropdownHidden = true},
                bidWeights = {type = "header", order = it(), name = L["EPGP_OPT_BID_WEIGHTS"]},
                bidWeightsDesc = {type = "description", fontSize = "medium", order = it(), name = L["EPGP_OPT_BID_WEIGHTS_DESC"] .. "\n"},
                bidWeightsNeed = Self.GetBidWeightOptions(Roll.BID_NEED, it),
                bidWeightsGreed = Self.GetBidWeightOptions(Roll.BID_GREED, it),
                bidWeightsDisenchant = Self.GetBidWeightOptions(Roll.BID_DISENCHANT, it)
            },
            hidden = function () return not IsAddOnLoaded("EPGP") end
        }
    end)
end

function Self:OnEnable()
    if not IsAddOnLoaded("EPGP") then return end

    GUI.AddCustomPlayerColumn("epgpPr", Self.UnitEP, L["EPGP_PR"], nil, nil, "bid", 0, true)
    GUI.AddCustomPlayerColumn("epgpMinEp", Self.UnitHasMinEP, nil, nil, nil, "epgpPr", nil, true)
    Roll.AddCustomAwardMethod("epgp", Self.DetermineWinner, Addon.db.profile.plugins.EPGP.awardBefore)

    -- Register events
    Roll.On(Self, Roll.EVENT_AWARD, "ROLL_AWARD")
    Roll.On(Self, Roll.EVENT_CLEAR, "ROLL_CLEAR")
end

function Self:OnDisable()
    GUI.RemoveCustomPlayerColumns("epgpPr", "epgpMinEp")
    Roll.RemoveCustomAwardMethod("epgp")

    -- Unregister events
    Roll.Unsubscribe(Self)
end

function Self.ROLL_AWARD(_, _, roll, winner, prevWinner)
    if Session.IsMasterlooter() then
        -- Undo a previous credit if necessary
        if prevWinner and Self.credited[roll.id] then
            Self.UnitCreditGP(prevWinner, roll.item.link, -Self.credited[roll.id], true)
        end

        -- Credit the winner
        local gp = Self.RollGP(roll)
        if gp > 0 and winner and IsGuildMember(winner) then
            Self.UnitCreditGP(winner, roll.item.link, gp)
            Self.credited[roll.id] = gp
        else
            Self.credited[roll.id] = nil
        end
    end
end

function Self.ROLL_CLEAR(_, _, roll)
    Self.credited[roll.id] = nil
end