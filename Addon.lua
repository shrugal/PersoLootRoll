--[[
TODO:
- Only specific specs
- Transmog mode: Check appearance, don't cancel rolls for items that some ppl could wear but have a higher ilvl, prompt to answer only when someone asks for the item
- Block all trades and whispers
- Custom messages
]]

local Addon = LibStub("AceAddon-3.0"):GetAddon(PLR_NAME)
local L = LibStub("AceLocale-3.0"):GetLocale(PLR_NAME)
local Util = Addon.Util
local Item = Addon.Item

-------------------------------------------------------
--                     Constants                     --
-------------------------------------------------------

-- Enable or disable debug stuff
Addon.DEBUG = true

-- Echo levels
Addon.ECHO_NONE = 0
Addon.ECHO_ERROR = 1
Addon.ECHO_INFO = 2
Addon.ECHO_VERBOSE = 3
Addon.ECHO_DEBUG = 4

Addon.rolls = Util.TblCounter()
Addon.timers = {}

-------------------------------------------------------
--                    Addon stuff                    --
-------------------------------------------------------

-- Called when the addon is loaded
function Addon:OnInitialize()
    self.db = LibStub("AceDB-3.0"):New(PLR_NAME .. "DB", {
        profile = {
            enabled = true,
            echo = Addon.ECHO_INFO,
            announce = {lfd = true, party = true, lfr = true, raid = true, guild = true},
            roll = true,
            whisper = {
                group = {lfd = true, party = true, lfr = true, raid = true, guild = false},
                target = {friend = false, guild = false, other = true}
            },
            answer = true
        }
    }, true)
    
    -- Register options
    local config = LibStub("AceConfig-3.0")
    local dialog = LibStub("AceConfigDialog-3.0")

    -- We need this to be able to define the order of these options
    local groupKeys = {"party", "raid", "guild", "lfd", "lfr"}
    local groupValues = {PARTY, RAID, GUILD_GROUP, LOOKING_FOR_DUNGEON_PVEFRAME, RAID_FINDER_PVEFRAME}

    config:RegisterOptionsTable(PLR_NAME, {
        type = "group",
        args = {
            -- General
            general = {type = "header", name = L["OPT_GENERAL"], order = 0},
            enable = {
                name = L["OPT_ENABLE"],
                desc = L["OPT_ENABLE_DESC"],
                type = "toggle",
                order = 1,
                set = function (_, val)
                    self.db.profile.enabled = val
                    self:Print(L[val and "ENABLED" or "DISABLED"])
                end,
                get = function (_) return self.db.profile.enabled end
            },
            echo = {
                name = L["OPT_ECHO"],
                desc = L["OPT_ECHO_DESC"],
                type = "select",
                order = 2,
                values = {
                    [Addon.ECHO_NONE] = L["OPT_ECHO_NONE"],
                    [Addon.ECHO_ERROR] = L["OPT_ECHO_ERROR"],
                    [Addon.ECHO_INFO] = L["OPT_ECHO_INFO"],
                    [Addon.ECHO_VERBOSE] = L["OPT_ECHO_VERBOSE"],
                    [Addon.ECHO_DEBUG] = L["OPT_ECHO_DEBUG"]
                },
                set = function (info, val) self.db.profile.echo = val end,
                get = function () return self.db.profile.echo end
            },
            -- Chat
            chat = {type = "header", order = 3, name = L["OPT_CHAT"]},
            chatDesc = {type = "description", order = 4, name = L["OPT_CHAT_DESC"]},
            announce = {
                name = L["OPT_ANNOUNCE"],
                desc = L["OPT_ANNOUNCE_DESC"],
                type = "multiselect",
                order = 5,
                values = groupValues,
                set = function (_, key, val) self.db.profile.announce[groupKeys[key]] = val end,
                get = function (_, key) return self.db.profile.announce[groupKeys[key]] end,
            },
            roll = {
                name = L["OPT_ROLL"],
                desc = L["OPT_ROLL_DESC"],
                type = "toggle",
                order = 6,
                set = function (_, val) self.db.profile.roll = val end,
                get = function () return self.db.profile.roll end,
                width = "full"
            },
            whisperGroup = {
                name = L["OPT_WHISPER_GROUP"],
                desc = L["OPT_WHISPER_GROUP_DESC"],
                type = "multiselect",
                order = 7,
                values = groupValues,
                set = function (_, key, val) self.db.profile.whisper.group[groupKeys[key]] = val end,
                get = function (_, key) return self.db.profile.whisper.group[groupKeys[key]] end
            },
            whisperTarget = {
                name = L["OPT_WHIPSER_TARGET"],
                desc = L["OPT_WHISPER_TARGET_DESC"],
                type = "multiselect",
                order = 8,
                values = {
                    friend = FRIEND,
                    guild = GUILD,
                    other = OTHER
                },
                set = function (_, key, val) self.db.profile.whisper.target[key] = val end,
                get = function (_, key) return self.db.profile.whisper.target[key] end
            },
            answer = {
                name = L["OPT_ANSWER"],
                desc = L["OPT_ANSWER_DESC"],
                type = "toggle",
                order = 9,
                set = function (_, val) self.db.profile.answer = val end,
                get = function () return self.db.profile.answer end,
                width = "full"
            }
        }
    })
    self.configFrame = dialog:AddToBlizOptions(PLR_NAME)
    

    -- Profile options
    config:RegisterOptionsTable(PLR_NAME .. "_profiles", LibStub("AceDBOptions-3.0"):GetOptionsTable(self.db))
    dialog:AddToBlizOptions(PLR_NAME .. "_profiles", "Profiles", PLR_NAME)
end

-- Called when the addon is enabled
function Addon:OnEnable()
    -- Enable hooks
    self.Hooks.EnableGroupLootRoll()
    self.Hooks.EnableChatLinks()
    self.Hooks.EnableUnitMenus()

    -- Register chat commands
    self:RegisterChatCommand(PLR_NAME, "HandleChatCommand")
    self:RegisterChatCommand("plr", "HandleChatCommand")

    -- Periodically clear old rolls
    self.timers.clearRolls = self:ScheduleRepeatingTimer(self.Roll.Clear, self.Roll.CLEAR)

    -- Start inspecting
    self.Inspect.Start()
    if not self.Inspect.timer then
        -- IsInGroup doesn't work right after logging in, so check again after waiting a bit.
        self.timers.inspectStart = self:ScheduleTimer(self.Inspect.Start, 10)
    end
end

-- Called when the addon is disabled
function Addon:OnDisable()
    -- Disable hooks
    self.Hooks.DisableGroupLootRoll()
    self.Hooks.DisableChatLinks()
    self.Hooks.DisableUnitMenus()

    -- Stop clear timer
    if self.timers.clearRolls then
        self:CancelTimer(self.timers.clearRolls)
    end
    self.timers.clearRolls = nil

    -- Start inspecting
    self.Inspect.Clear()
    if self.timers.inspectStart then
        self:CancelTimer(self.timers.inspectStart)
        self.timers.inspectStart = nil
    end
end

-- Check if we should currently track loot etc.
function Addon:IsTracking()
    local methods = {freeforall = true, roundrobin = true, personalloot = true}
    return self.db.profile.enabled and IsInGroup() and methods[GetLootMethod()]
end

-------------------------------------------------------
--                   Chat command                    --
-------------------------------------------------------

-- Chat command handling
function Addon:HandleChatCommand (msg)
    local args = {Addon:GetArgs(msg, 10)}
    local cmd = args[1]

    Util.Switch(cmd) {
        ["help"] = function () self:Help() end,
        ["options"] = function () self:ShowOptions() end,
        ["config"] = function () LibStub("AceConfigCmd-3.0").HandleCommand(Addon, "plr config", PLR_NAME, msg:sub(7)) end,
        ["rolls"] = self.GUI.Rolls.Show,
        ["roll"] = function  ()
            local items, i, item = {}, 1
    
            while i do
                i, item = next(args, i)
                if i and Item.IsLink(item) then
                    tinsert(items, item)
                end
            end
    
            if not next(items) then
                self:Print(L["USAGE_ROLL"])
            else
                i = table.getn(items) + 2
                local timeout, owner = tonumber(args[i]), args[i+1]
                
                for i,item in pairs(items) do
                    self.Roll.Add(item, owner, nil, timeout):Start()
                end
            end
        end,
        ["bid"] = function ()
            local owner, item, answer = select(2, unpack(args))
            
            if Util.StrEmpty(owner) or Item.IsLink(owner)                            -- owner
            or item and not Item.IsLink(item)                                        -- item
            or answer and not Util.TblFind(self.Roll.ANSWERS, tonumber(answer)) then -- answer
                self:Print(L["USAGE_BID"])
            else
                local roll = self.Roll.Find(nil, owner, item)
                if roll then
                    roll:Bid(answer)
                else
                    self.Comm.ChatBid(owner, item)
                end
            end
        end,
        -- TODO
        ["trade"] = function ()
            local target = args[2]
            Addon.Trade.Initiate(target or "target")
        end,
        -- TODO: DEBUG
        ["test"] = function ()
            local link = "|cffa335ee|Hitem:152412::::::::110:105::4:3:3613:1457:3528:::|h[Depraved Machinist's Footpads]|h|r"
            local roll = Addon.Roll.Add(link):Start():Bid(Addon.Roll.ANSWER_PASS):Bid(Addon.Roll.ANSWER_NEED, "Zhael", true)
        end,
        default = self.GUI.Rolls.Show
    }
end

function Addon:ShowOptions()
    -- Have to call it twice because of a blizzard UI bug
    InterfaceOptionsFrame_OpenToCategory(self.configFrame)
    InterfaceOptionsFrame_OpenToCategory(self.configFrame)
end

function Addon:Help()
    self:Print(L["HELP"])
end

-------------------------------------------------------
--                       Other                       --
-------------------------------------------------------

-- Console output

function Addon:Echo(lvl, ...)
    if self.db.profile.echo >= lvl then
        self:Print(...)
    end
end

function Addon:Err(...)
    self:Echo(self.ECHO_ERROR, ...)
end

function Addon:Info(...)
    self:Echo(self.ECHO_INFO, ...)
end

function Addon:Verbose(...)
    self:Echo(self.ECHO_VERBOSE, ...)
end

function Addon:Debug(...)
    self:Echo(self.ECHO_DEBUG, ...)
end

-- Timer

function Addon:ExtendTimerTo(timer, to)
    if not timer.canceled and timer.ends - GetTime() < to then
        Addon:CancelTimer(timer)
        local fn = timer.looping and Addon.ScheduleRepeatingTimer or Addon.ScheduleTimer
        timer = fn(Addon, timer.func, to, unpack(timer, 1, timer.argsCount))
    end

    return timer
end

function Addon:ExtendTimerBy(timer, by)
    return self:ExtendTimerTo(timer, (timer.ends - GetTime()) + by)
end

function Addon:TimerIsRunning(timer)
    return timer and not timer.canceled and timer.ends > GetTime()
end