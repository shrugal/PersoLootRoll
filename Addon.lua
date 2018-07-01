--[[
TODO:
- Better trade/disenchant tracking

Internal
- Roll.traded should be uncoupled from the rest of the roll lifecycle
]]

local Name, Addon = ...
local LDB = LibStub("LibDataBroker-1.1")
local LDBIcon = LibStub("LibDBIcon-1.0")
local L = LibStub("AceLocale-3.0"):GetLocale(Name)
local GUI, Item, Locale, Masterloot, Roll, Trade, Util = Addon.GUI, Addon.Item, Addon.Locale, Addon.Masterloot, Addon.Roll, Addon.Trade, Addon.Util

-- Echo levels
Addon.ECHO_NONE = 0
Addon.ECHO_ERROR = 1
Addon.ECHO_INFO = 2
Addon.ECHO_VERBOSE = 3
Addon.ECHO_DEBUG = 4

Addon.rolls = Util.TblCounter()
Addon.timers = {}

-- Versions
Addon.versions = {}
Addon.versionNoticeShown = false

-------------------------------------------------------
--                    Addon stuff                    --
-------------------------------------------------------

-- Called when the addon is loaded
function Addon:OnInitialize()
    self.db = LibStub("AceDB-3.0"):New(Name .. "DB", {
        profile = {
            -- General
            enabled = true,
            ui = {showRollFrames = true, showRollsWindow = false},
            awardSelf = false,
            ilvlThreshold = 30,
            ilvlThresholdTrinkets = true,
            transmog = false,

            -- Messages
            echo = Addon.ECHO_INFO,
            announce = {lfd = true, party = true, lfr = true, raid = true, guild = true},
            roll = true,
            whisper = {
                group = {lfd = true, party = true, lfr = true, raid = true, guild = false},
                target = {friend = false, guild = false, other = true}
            },
            answer = true,
            suppress = false,
            messages = {},

            -- Masterloot
            masterloot = {
                allow = {friend = true, guild = true, guildgroup = true, raidleader = false, raidassistant = false},
                accept = {friend = false, guildmaster = false, guildofficer = false},
                allowAll = false
            },
            masterlooter = {
                timeoutBase = Roll.TIMEOUT,
                timeoutPerItem = Roll.TIMEOUT_PER_ITEM,
                bidPublic = false,
                answers1 = {}, -- Need
                answers2 = {}, -- Greed
                council = {guildmaster = false, guildofficer = false, raidleader = false, raidassistant = false},
                votePublic = false
            },
            version = 3
        },
        factionrealm = {
            masterloot = {
                whitelist = {}
            },
            masterlooter = {
                councilWhitelist = {},
            },
            version = 3
        },
        char = {
            specs = {true, true, true, true},
            masterloot = {
                guildRank = 0
            },
            version = 3
        }
    }, true)
    
    -- Migrate and register options
    self:MigrateOptions()
    self:RegisterOptions()

    -- Minimap icon
    self:RegisterMinimapIcon()
end

-- Called when the addon is enabled
function Addon:OnEnable()
    -- Enable hooks
    self.Hooks.EnableGroupLootRoll()
    self.Hooks.EnableChatLinks()
    -- self.Hooks.EnableUnitMenus()

    -- Register events
    self.Events.RegisterEvents()

    -- Register chat commands
    self:RegisterChatCommand(Name, "HandleChatCommand")
    self:RegisterChatCommand("plr", "HandleChatCommand")

    -- Periodically clear old rolls
    self.timers.clearRolls = self:ScheduleRepeatingTimer(self.Roll.Clear, self.Roll.CLEAR)

    -- Start inspecting
    self.Inspect.Start()
    if not self.Inspect.timer then
        -- IsInGroup doesn't work right after logging in, so check again after waiting a bit.
        self.timers.inspectStart = self:ScheduleTimer(self.Inspect.Start, 10)
    end

    -- Trigger GROUP_JOINED or GROUP_LEFT
    local event = IsInGroup() and "GROUP_JOINED" or "GROUP_LEFT"
    self.Events[event](event)
end

-- Called when the addon is disabled
function Addon:OnDisable()
    -- Disable hooks
    self.Hooks.DisableGroupLootRoll()
    self.Hooks.DisableChatLinks()
    -- self.Hooks.DisableUnitMenus()

    -- Unregister events
    self.Events.UnregisterEvents()

    -- Stop clear timer
    if self.timers.clearRolls then
        self:CancelTimer(self.timers.clearRolls)
    end
    self.timers.clearRolls = nil

    -- Stop inspecting
    self.Inspect.Clear()
    if self.timers.inspectStart then
        self:CancelTimer(self.timers.inspectStart)
        self.timers.inspectStart = nil
    end
end

-------------------------------------------------------
--                   Chat command                    --
-------------------------------------------------------

-- Chat command handling
function Addon:HandleChatCommand(msg)
    local args = {Addon:GetArgs(msg, 10)}
    local cmd = args[1]

    -- Help
    if cmd == "help" then
        self:Help()
    -- Options
    elseif cmd == "options" then
        self:ShowOptions()
    -- Config
    elseif cmd == "config" then
        LibStub("AceConfigCmd-3.0").HandleCommand(Addon, "plr config", Name, msg:sub(7))
    -- Roll
    elseif cmd == "roll" then
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
                item = Item.FromLink(item, owner or "player")
                local roll = self.Roll.Add(item, owner or Masterloot.GetMasterlooter() or "player", timeout)
                if roll.isOwner then
                    roll:Start()
                else
                    roll:SendStatus(true)
                end
            end
        end
    -- Bid
    elseif cmd == "bid" then
        local owner, item, bid = select(2, unpack(args))
        
        if Util.StrIsEmpty(owner) or Item.IsLink(owner)                 -- owner
        or item and not Item.IsLink(item)                               -- item
        or bid and not Util.TblFind(self.Roll.BIDS, tonumber(bid)) then -- answer
            self:Print(L["USAGE_BID"])
        else
            local roll = self.Roll.Find(nil, owner, item)
            if roll then
                roll:Bid(bid)
            else
                self.Comm.RollBid(owner, item, true)
            end
        end
    -- Trade
    elseif cmd == "trade" then
        Trade.Initiate(args[2] or "target")
    -- Rolls/None
    elseif cmd == "rolls" or not cmd then
        self.GUI.Rolls.Show()
    -- Unknown
    else
        self:Err(L["ERROR_CMD_UNKNOWN"]:format(cmd))
    end
end

function Addon:Help()
    self:Print(L["HELP"])
end

-------------------------------------------------------
--                      Options                      --
-------------------------------------------------------

function Addon:ShowOptions()
    -- Have to call it twice because of a blizzard UI bug
    InterfaceOptionsFrame_OpenToCategory(self.configFrame)
    InterfaceOptionsFrame_OpenToCategory(self.configFrame)
end

function Addon:RegisterOptions()
    local config = LibStub("AceConfig-3.0")
    local dialog = LibStub("AceConfigDialog-3.0")
    local it = Util.Iter()

    -- GENERAL

    local specs

    config:RegisterOptionsTable(Name, {
        type = "group",
        args = {
            version = {type = "description", fontSize = "medium", order = it(), name = L["OPT_VERSION"]},
            author = {type = "description", fontSize = "medium", order = it(), name = L["OPT_AUTHOR"]},
            translation = {type = "description", fontSize = "medium", order = it(), name = L["OPT_TRANSLATION"] .. "\n"},
            enable = {
                name = L["OPT_ENABLE"],
                desc = L["OPT_ENABLE_DESC"],
                type = "toggle",
                order = it(),
                set = function (_, val)
                    self.db.profile.enabled = val
                    self:Info(L[val and "ENABLED" or "DISABLED"])
                end,
                get = function (_) return self.db.profile.enabled end,
                width = "full"
            },
            ui = {type = "header", order = it(), name = L["OPT_UI"]},
            uiDesc = {type = "description", fontSize = "medium", order = it(), name = L["OPT_UI_DESC"] .. "\n"},
            minimapIcon = {
                name = L["OPT_MINIMAP_ICON"],
                desc = L["OPT_MINIMAP_ICON_DESC"],
                type = "toggle",
                order = it(),
                set = function (_, val)
                    PersoLootRollIconDB.hide = not val or nil
                    if val then
                        LDBIcon:Show(Name)
                    else
                        LDBIcon:Hide(Name)
                    end
                end,
                get = function (_) return not PersoLootRollIconDB.hide end,
                width = "full"
            },
            showRollFrames = {
                name = L["OPT_ROLL_FRAMES"],
                desc = L["OPT_ROLL_FRAMES_DESC"],
                type = "toggle",
                order = it(),
                set = function (_, val) self.db.profile.ui.showRollFrames = val end,
                get = function (_) return self.db.profile.ui.showRollFrames end,
                width = "full"
            },
            showRollsWindow = {
                name = L["OPT_ROLLS_WINDOW"],
                desc = L["OPT_ROLLS_WINDOW_DESC"],
                type = "toggle",
                order = it(),
                set = function (_, val) self.db.profile.ui.showRollsWindow = val end,
                get = function (_) return self.db.profile.ui.showRollsWindow end,
                width = "full"
            },
            awardSelf = {
                name = L["OPT_AWARD_SELF"],
                desc = L["OPT_AWARD_SELF_DESC"] .. "\n",
                type = "toggle",
                order = it(),
                set = function (_, val) self.db.profile.awardSelf = val end,
                get = function () return self.db.profile.awardSelf end,
                width = "full"
            },
            ["space" .. it()] = {type = "description", fontSize = "medium", order = it(0), name = " ", cmdHidden = true, dropdownHidden = true},
            itemFilter = {type = "header", order = it(), name = L["OPT_ITEM_FILTER"]},
            itemFilterDesc = {type = "description", fontSize = "medium", order = it(), name = L["OPT_ITEM_FILTER_DESC"] .. "\n"},
            ilvlThreshold = {
                name = L["OPT_ILVL_THRESHOLD"],
                desc = L["OPT_ILVL_THRESHOLD_DESC"],
                type = "range",
                order = it(),
                min = -2 * Item.ILVL_THRESHOLD,
                max = 2 * Item.ILVL_THRESHOLD,
                softMin = 0,
                softMax = Item.ILVL_THRESHOLD,
                step = 5,
                set = function (_, val) self.db.profile.ilvlThreshold = val end,
                get = function () return self.db.profile.ilvlThreshold end,
            },
            ilvlThresholdTrinkets = {
                name = L["OPT_ILVL_THRESHOLD_TRINKETS"],
                desc = L["OPT_ILVL_THRESHOLD_TRINKETS_DESC"],
                type = "toggle",
                order = it(),
                set = function (_, val) self.db.profile.ilvlThresholdTrinkets = val end,
                get = function () return self.db.profile.ilvlThresholdTrinkets end,
            },
            ["space" .. it()] = {type = "description", fontSize = "medium", order = it(0), name = " ", cmdHidden = true, dropdownHidden = true},
            specs = {
                name = L["OPT_SPECS"],
                desc = L["OPT_SPECS_DESC"],
                type = "multiselect",
                order = it(),
                values = function ()
                    if not specs then
                        local classId = select(3, UnitClass("player"))
                        specs = Util.TblCopy(Item.CLASS_INFO[classId].specs, function (_, i) return select(2, GetSpecializationInfo(i)) end, true)
                    end
                    return specs
                end,
                set = function (_, key, val)
                    self.db.char.specs[key] = val
                    wipe(Item.playerSlotLevels)
                end,
                get = function (_, key) return self.db.char.specs[key] end
            },
            ["space" .. it()] = {type = "description", fontSize = "medium", order = it(0), name = " ", cmdHidden = true, dropdownHidden = true},
            transmog = {
                name = L["OPT_TRANSMOG"],
                desc = L["OPT_TRANSMOG_DESC"],
                type = "toggle",
                order = it(),
                set = function (_, val) self.db.profile.transmog = val end,
                get = function () return self.db.profile.transmog end,
                width = "full"
            }
        }
    })
    self.configFrame = dialog:AddToBlizOptions(Name)

    -- MESSAGES

    local groupKeys = {"party", "raid", "guild", "lfd", "lfr"}
    local groupValues = {PARTY, RAID, GUILD_GROUP, LOOKING_FOR_DUNGEON_PVEFRAME, RAID_FINDER_PVEFRAME}

    local lang = Locale.GetLanguage()

    it(1, true)
    config:RegisterOptionsTable(Name .. "_messages", {
        name = L["OPT_MESSAGES"],
        type = "group",
        childGroups = "tab",
        args = {
            -- Chat
            echo = {
                name = L["OPT_ECHO"],
                desc = L["OPT_ECHO_DESC"],
                type = "select",
                order = it(),
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
            shouldChat = {
                name = L["OPT_SHOULD_CHAT"],
                type = "group",
                order = it(),
                args = {
                    ShouldChatDesc = {type = "description", fontSize = "medium", order = it(), name = L["OPT_SHOULD_CHAT_DESC"] .. "\n"},
                    groupchat = {type = "header", order = it(), name = L["OPT_GROUPCHAT"]},
                    groupchatAnnounce = {
                        name = L["OPT_GROUPCHAT_ANNOUNCE"],
                        desc = L["OPT_GROUPCHAT_ANNOUNCE_DESC"],
                        type = "multiselect",
                        order = it(),
                        values = groupValues,
                        set = function (_, key, val) self.db.profile.announce[groupKeys[key]] = val end,
                        get = function (_, key) return self.db.profile.announce[groupKeys[key]] end,
                    },
                    groupchatRoll = {
                        name = L["OPT_GROUPCHAT_ROLL"],
                        desc = L["OPT_GROUPCHAT_ROLL_DESC"],
                        type = "toggle",
                        order = it(),
                        set = function (_, val) self.db.profile.roll = val end,
                        get = function () return self.db.profile.roll end,
                        width = "full"
                    },
                    whisper = {type = "header", order = it(), name = L["OPT_WHISPER"]},
                    whisperGroup = {
                        name = L["OPT_WHISPER_GROUP"],
                        desc = L["OPT_WHISPER_GROUP_DESC"],
                        type = "multiselect",
                        order = it(),
                        values = groupValues,
                        set = function (_, key, val) self.db.profile.whisper.group[groupKeys[key]] = val end,
                        get = function (_, key) return self.db.profile.whisper.group[groupKeys[key]] end
                    },
                    whisperTarget = {
                        name = L["OPT_WHISPER_TARGET"],
                        desc = L["OPT_WHISPER_TARGET_DESC"],
                        type = "multiselect",
                        order = it(),
                        values = {
                            friend = FRIEND,
                            guild = GUILD,
                            other = OTHER
                        },
                        set = function (_, key, val) self.db.profile.whisper.target[key] = val end,
                        get = function (_, key) return self.db.profile.whisper.target[key] end
                    },
                    whisperAnswer = {
                        name = L["OPT_WHISPER_ANSWER"],
                        desc = L["OPT_WHISPER_ANSWER_DESC"],
                        type = "toggle",
                        order = it(),
                        set = function (_, val) self.db.profile.answer = val end,
                        get = function () return self.db.profile.answer end,
                        width = "full"
                    },
                    whisperSuppress = {
                        name = L["OPT_WHISPER_SUPPRESS"],
                        desc = L["OPT_WHISPER_SUPPRESS_DESC"],
                        type = "toggle",
                        order = it(),
                        set = function (_, val) self.db.profile.suppress = val end,
                        get = function () return self.db.profile.suppress end,
                        width = "full"
                    }
                }
            },
            customMessages = {
                name = L["OPT_CUSTOM_MESSAGES"],
                type = "group",
                order = it(),
                childGroups = "select",
                args = {
                    desc = {type = "description", fontSize = "medium", order = it(), name = L["OPT_CUSTOM_MESSAGES_DESC"] .. "\n"},
                    localized = {
                        name = L["OPT_CUSTOM_MESSAGES_LOCALIZED"]:format(lang),
                        type = "group",
                        order = it(),
                        hidden = Locale.GetLanguage() == Locale.DEFAULT,
                        args = Addon:GetCustomMessageOptions(false)
                    },
                    default = {
                        name = L["OPT_CUSTOM_MESSAGES_DEFAULT"]:format(Locale.DEFAULT),
                        type = "group",
                        order = it(),
                        args = Addon:GetCustomMessageOptions(true)
                    }
                }
            }
        }
    })
    dialog:AddToBlizOptions(Name .. "_messages", L["OPT_MESSAGES"], Name)
    
    -- MASTERLOOT

    local allowKeys = {"friend", "guild", "guildgroup", "raidleader", "raidassistant"}
    local allowValues = {FRIEND, LFG_LIST_GUILD_MEMBER, GUILD_GROUP, L["RAID_LEADER"], L["RAID_ASSISTANT"]}

    local acceptKeys = {"friend", "guildmaster", "guildofficer"}
    local acceptValues = {FRIEND, L["GUILD_MASTER"], L["GUILD_OFFICER"]}
    
    local councilKeys = {"guildmaster", "guildofficer", "raidleader", "raidassistant"}
    local councilValues = {L["GUILD_MASTER"], L["GUILD_OFFICER"], L["RAID_LEADER"], L["RAID_ASSISTANT"]}

    local guildRanks

    it(1, true)
    config:RegisterOptionsTable(Name .. "_masterloot", {
        name = L["OPT_MASTERLOOT"],
        type = "group",
        childGroups = "tab",
        args = {
            desc = {type = "description", fontSize = "medium", order = it(), name = L["OPT_MASTERLOOT_DESC"] .. "\n"},
            search = {
                name = L["OPT_MASTERLOOT_SEARCH"],
                type = "execute",
                order = it(),
                func = function () self.Comm.Send(self.Comm.EVENT_MASTERLOOT_ASK) end
            },
            start = {
                name = L["OPT_MASTERLOOT_START"],
                type = "execute",
                order = it(),
                func = function () Masterloot.SetMasterlooter("player") end
            },
            stop = {
                name = L["OPT_MASTERLOOT_STOP"],
                type = "execute",
                order = it(),
                func = function () Masterloot.SetMasterlooter(nil) end
            },
            approval = {
                name = L["OPT_MASTERLOOT_APPROVAL"],
                type = "group",
                order = it(),
                args = {
                    desc = {type = "description", fontSize = "medium", order = it(), name = L["OPT_MASTERLOOT_APPROVAL_DESC"] .. "\n"},
                    allow = {
                        name = L["OPT_MASTERLOOT_ALLOW"],
                        desc = L["OPT_MASTERLOOT_ALLOW_DESC"],
                        type = "multiselect",
                        order = it(),
                        values = allowValues,
                        set = function (_, key, val) self.db.profile.masterloot.allow[allowKeys[key]] = val end,
                        get = function (_, key) return self.db.profile.masterloot.allow[allowKeys[key]] end
                    },
                    whitelist = {
                        name = L["OPT_MASTERLOOT_WHITELIST"],
                        desc = L["OPT_MASTERLOOT_WHITELIST_DESC"],
                        type = "input",
                        order = it(),
                        set = function (_, val)
                            local t = wipe(self.db.factionrealm.masterloot.whitelist)
                            for v in val:gmatch("[^%s%d%c,;:_<>|/\\]+") do
                                t[v] = true
                            end
                        end,
                        get = function () return Util(self.db.factionrealm.masterloot.whitelist).Keys().Sort().Concat(", ")() end,
                        width = "full"
                    },
                    ["space" .. it()] = {type = "description", fontSize = "medium", order = it(0), name = " ", cmdHidden = true, dropdownHidden = true},
                    allowAll = {
                        name = L["OPT_MASTERLOOT_ALLOW_ALL"],
                        desc = L["OPT_MASTERLOOT_ALLOW_ALL_DESC"],
                        descStyle = "inline",
                        type = "toggle",
                        order = it(),
                        set = function (_, val) self.db.profile.masterloot.allowAll = val end,
                        get = function () return self.db.profile.masterloot.allowAll end,
                        width = "full"
                    },
                    ["space" .. it()] = {type = "description", fontSize = "medium", order = it(0), name = " ", cmdHidden = true, dropdownHidden = true},
                    accept = {
                        name = L["OPT_MASTERLOOT_ACCEPT"],
                        desc = L["OPT_MASTERLOOT_ACCEPT_DESC"],
                        type = "multiselect",
                        order = it(),
                        values = acceptValues,
                        set = function (_, key, val) self.db.profile.masterloot.accept[acceptKeys[key]] = val end,
                        get = function (_, key) return self.db.profile.masterloot.accept[acceptKeys[key]] end
                    }
                }
            },
            masterlooter = {
                name = L["OPT_MASTERLOOTER"],
                type = "group",
                order = it(),
                args = {
                    desc = {type = "description", fontSize = "medium", order = it(), name = L["OPT_MASTERLOOTER_DESC"] .. "\n"},
                    timeoutBase = {
                        name = L["OPT_MASTERLOOTER_TIMEOUT_BASE"],
                        desc = L["OPT_MASTERLOOTER_TIMEOUT_BASE_DESC"],
                        type = "range",
                        min = Roll.TIMEOUT,
                        max = 120,
                        step = 5,
                        order = it(),
                        set = function (_, val)
                            self.db.profile.masterlooter.timeoutBase = val
                            Masterloot.RefreshSession()
                        end,
                        get = function () return self.db.profile.masterlooter.timeoutBase end,
                        -- width = 1.7 TODO: Can't use that yet
                    },
                    timeoutPerItem = {
                        name = L["OPT_MASTERLOOTER_TIMEOUT_PER_ITEM"],
                        desc = L["OPT_MASTERLOOTER_TIMEOUT_PER_ITEM_DESC"],
                        type = "range",
                        min = Roll.TIMEOUT_PER_ITEM,
                        max = 60,
                        step = 1,
                        order = it(),
                        set = function (_, val)
                            self.db.profile.masterlooter.timeoutPerItem = val
                            Masterloot.RefreshSession()
                        end,
                        get = function () return self.db.profile.masterlooter.timeoutPerItem end,
                        -- width = 1.7 TODO: Can't use that yet
                    },
                    ["space" .. it()] = {type = "description", fontSize = "medium", order = it(0), name = " ", cmdHidden = true, dropdownHidden = true},
                    needAnswers = {
                        name = L["OPT_MASTERLOOTER_NEED_ANSWERS"],
                        desc = L["OPT_MASTERLOOTER_NEED_ANSWERS_DESC"],
                        type = "input",
                        order = it(),
                        set = function (_, val)
                            local t = wipe(self.db.profile.masterlooter.answers1)
                            for v in val:gmatch("[^,]+") do
                                v = v:gsub("^%s*(.*)%s*$", "%1")
                                if #t < 9 and not Util.StrIsEmpty(v) then
                                    tinsert(t, v == NEED and Roll.ANSWER_NEED or v)
                                end
                            end
                            Masterloot.RefreshSession()
                        end,
                        get = function ()
                            local s = ""
                            for i,v in pairs(self.db.profile.masterlooter.answers1) do
                                s = s .. (i > 1 and ", " or "") .. (v == Roll.ANSWER_NEED and NEED or v)
                            end
                            return s
                        end,
                        width = "full"
                    },
                    greedAnswers = {
                        name = L["OPT_MASTERLOOTER_GREED_ANSWERS"],
                        desc = L["OPT_MASTERLOOTER_GREED_ANSWERS_DESC"],
                        type = "input",
                        order = it(),
                        set = function (_, val)
                            local t = wipe(self.db.profile.masterlooter.answers2)
                            for v in val:gmatch("[^,]+") do
                                v = v:gsub("^%s*(.*)%s*$", "%1")
                                if #t < 9 and not Util.StrIsEmpty(v) then
                                    tinsert(t, v == GREED and Roll.ANSWER_GREED or v)
                                end
                            end
                            Masterloot.RefreshSession()
                        end,
                        get = function ()
                            local s = ""
                            for i,v in pairs(self.db.profile.masterlooter.answers2) do
                                s = s .. (i > 1 and ", " or "") .. (v == Roll.ANSWER_GREED and GREED or v)
                            end
                            return s
                        end,
                        width = "full"
                    },
                    ["space" .. it()] = {type = "description", fontSize = "medium", order = it(0), name = " ", cmdHidden = true, dropdownHidden = true},
                    bidPublic = {
                        name = L["OPT_MASTERLOOTER_BID_PUBLIC"],
                        desc = L["OPT_MASTERLOOTER_BID_PUBLIC_DESC"] .. "\n",
                        descStyle = "inline",
                        type = "toggle",
                        order = it(),
                        set = function (_, val)
                            self.db.profile.masterlooter.bidPublic = val
                            Masterloot.RefreshSession()
                        end,
                        get = function () return self.db.profile.masterlooter.bidPublic end,
                        width = "full"
                    }
                }
            },
            council = {
                name = L["OPT_MASTERLOOTER_COUNCIL"],
                type = "group",
                order = it(),
                args = {
                    desc = {type = "description", fontSize = "medium", order = it(), name = L["OPT_MASTERLOOTER_COUNCIL_DESC"] .. "\n"},
                    allow = {
                        name = L["OPT_MASTERLOOTER_COUNCIL_ALLOW"],
                        desc = L["OPT_MASTERLOOTER_COUNCIL_ALLOW_DESC"],
                        type = "multiselect",
                        order = it(),
                        values = councilValues,
                        set = function (_, key, val)
                            self.db.profile.masterlooter.council[councilKeys[key]] = val
                            Masterloot.RefreshSession()
                        end,
                        get = function (_, key) return self.db.profile.masterlooter.council[councilKeys[key]] end
                    },
                    guildRank = {
                        name = L["OPT_MASTERLOOTER_COUNCIL_GUILD_RANK"],
                        desc = L["OPT_MASTERLOOTER_COUNCIL_GUILD_RANK_DESC"],
                        type = "select",
                        order = it(),
                        values = function ()
                            if not guildRanks then
                                guildRanks = Util.GetGuildRanks()
                                guildRanks[0], guildRanks[1], guildRanks[2] = "(" .. NONE .. ")", nil, nil
                            end
                            return guildRanks
                        end,
                        set = function (_, val)
                            self.db.char.masterloot.guildRank = val
                            Masterloot.RefreshSession()
                        end,
                        get = function () return self.db.char.masterloot.guildRank end
                    },
                    whitelist = {
                        name = L["OPT_MASTERLOOTER_COUNCIL_WHITELIST"],
                        desc = L["OPT_MASTERLOOTER_COUNCIL_WHITELIST_DESC"],
                        type = "input",
                        order = it(),
                        set = function (_, val)
                            local t = wipe(self.db.factionrealm.masterlooter.councilWhitelist)
                            for v in val:gmatch("[^%s%d%c,;:_<>|/\\]+") do
                                t[v] = true
                            end
                            Masterloot.RefreshSession()
                        end,
                        get = function () return Util(self.db.factionrealm.masterlooter.councilWhitelist).Keys().Sort().Concat(", ")() end,
                        width = "full"
                    },
                    ["space" .. it()] = {type = "description", fontSize = "medium", order = it(0), name = " ", cmdHidden = true, dropdownHidden = true},
                    votePublic = {
                        name = L["OPT_MASTERLOOTER_VOTE_PUBLIC"],
                        desc = L["OPT_MASTERLOOTER_VOTE_PUBLIC_DESC"],
                        descStyle = "inline",
                        type = "toggle",
                        order = it(),
                        set = function (_, val)
                            self.db.profile.masterlooter.votePublic = val
                            Masterloot.RefreshSession()
                        end,
                        get = function () return self.db.profile.masterlooter.votePublic end,
                        width = "full"
                    }
                }
            }
        }
    })
    dialog:AddToBlizOptions(Name .. "_masterloot", L["OPT_MASTERLOOT"], Name)

    -- PROFILES

    config:RegisterOptionsTable(Name .. "_profiles", LibStub("AceDBOptions-3.0"):GetOptionsTable(self.db))
    dialog:AddToBlizOptions(Name .. "_profiles", "Profiles", Name)
end

function Addon:GetCustomMessageOptions(isDefault)
    local lang = isDefault and Locale.DEFAULT or Locale.GetLanguage()
    local locale = Locale.GetLocale(lang)
    local desc = L["OPT_CUSTOM_MESSAGES_" .. (isDefault and "DEFAULT" or "LOCALIZED") .. "_DESC"]
    local it = Util.Iter()

    local set = function (info, val)
        local line, c = info[3], self.db.profile.messages
        if not c[lang] then c[lang] = {} end
        c[lang][line] = not (Util.StrIsEmpty(val) or val == locale[line]) and val or nil
    end
    local get = function (info)
        local line, c = info[3], self.db.profile.messages
        return c[lang] and c[lang][line] or locale[line]
    end
    local validate = function (info, val)
        local line, pattern = info[3], ""
        for v in locale[line]:gmatch("%%[sd]") do
            pattern = pattern == "" and "%" .. v or pattern .. ".*%" .. v
        end
        return val == "" or val:match(pattern) ~= nil and select(2, val:gsub("%%[sd]", "")) == select(2, locale[line]:gsub("%%[sd]", ""))
    end

    local t = {
        desc = {type = "description", fontSize = "medium", order = it(), name = desc:format(Locale.GetLanguage()) .. "\n"},
        groupchat = {type = "header", order = it(), name = L["OPT_GROUPCHAT"]},
    }

    for i,line in pairs({"ROLL_START", "ROLL_START_MASTERLOOT", "ROLL_WINNER", "ROLL_WINNER_MASTERLOOT", "whisper", "BID", "ROLL_WINNER_WHISPER", "ROLL_WINNER_WHISPER_MASTERLOOT", "ROLL_ANSWER_BID", "ROLL_ANSWER_YES", "ROLL_ANSWER_YES_MASTERLOOT", "ROLL_ANSWER_NO_SELF", "ROLL_ANSWER_NO_OTHER", "ROLL_ANSWER_NOT_TRADABLE", "ROLL_ANSWER_AMBIGUOUS"}) do
        if line == "whisper" then
            t[line] = {type = "header", order = it(), name = L["OPT_WHISPER"]}
        else
            desc = DEFAULT .. ": \"" .. locale[line] .. "\"" .. Util.StrPrefix(L["OPT_MSG_" .. line .. "_DESC"], "\n\n")
            t[line] = {
                name = L["OPT_MSG_" .. line],
                desc = desc:gsub("(%%.)", "|cffffff00%1|r"),
                type = "input",
                order = it(),
                validate = validate,
                set = set,
                get = get,
                width = "full"
            }
        end
    end

    return t
end

-- Migrate options from an older version to the current one
function Addon:MigrateOptions()
    -- Profile
    local c = Addon.db.profile
    if not c.version or c.version < 3 then
        c.masterlooter.timeoutBase = c.masterloot.timeoutBase or c.masterlooter.timeoutBase
        c.masterlooter.timeoutPerItem = c.masterloot.timeoutPerItem or c.masterlooter.timeoutPerItem
        c.masterlooter.bidPublic = c.masterloot.bidPublic or c.masterlooter.bidPublic or false
        c.masterlooter.council = not next(c.masterlooter.council) and c.masterloot.council or c.masterlooter.council
        c.masterlooter.votePublic = c.masterloot.votePublic or c.masterlooter.votePublic or false
        c.masterloot.timeoutBase, c.masterloot.timeoutPerItem, c.masterloot.bidPublic, c.masterloot.council, c.masterloot.votePublic, c.masterloot.whitelist, c.masterloot.councilWhitelist = nil
        c.version = 3
    end

    -- Factionrealm
    local c = Addon.db.factionrealm
    if not c.version or c.version < 3 then
        c.masterlooter.councilWhitelist = not next(c.masterlooter.councilWhitelist) and c.masterloot.councilWhitelist or c.masterlooter.councilWhitelist
        c.masterloot.councilWhitelist = nil
        c.version = 3
    end

    -- Char
    local c = Addon.db.char
    if not c.version or c.version < 3 then
        c.version = 3
    end
end

-------------------------------------------------------
--                        LDB                        --
-------------------------------------------------------

function Addon:RegisterMinimapIcon()
    local plugin = LDB:NewDataObject(Name, {
        type = "data source",
        text = Name,
        icon = "Interface\\Buttons\\UI-GroupLoot-Dice-Up"
    })

    -- OnClick
    plugin.OnClick = function (self, btn)
        if btn == "RightButton" then
            Addon:ShowOptions()
        else
            GUI.Rolls.Toggle()
        end
    end

    -- OnTooltip
    plugin.OnTooltipShow = function (ToolTip)
        ToolTip:AddLine(Name)
        ToolTip:AddLine(L["TIP_MINIMAP_ICON"], 1, 1, 1)
    end

    -- Icon
    if not PersoLootRollIconDB then PersoLootRollIconDB = {} end
    LDBIcon:Register(Name, plugin, PersoLootRollIconDB)
end

-------------------------------------------------------
--                       Other                       --
-------------------------------------------------------

-- Check if we should currently track loot etc.
function Addon:IsTracking()
    return self.db.profile.enabled and IsInGroup() and Util.In(GetLootMethod(), "freeforall", "roundrobin", "personalloot", "group")
end

function Addon:SetVersion(unit, version)
    self.versions[unit] = version

    if version and version > self.VERSION and not self.versionNoticeShown then
        self:Info(L["VERSION_NOTICE"])
        self.versionNoticeShown = true
    end
end

-- Console output

function Addon:Echo(lvl, ...)
    if self.db.profile.echo >= lvl then
        if lvl == self.ECHO_DEBUG then
            local args = {...}
            for i,v in pairs(args) do
                if Util.In(type(v), "table", "function") then args[i] = Util.ToString(v) end
            end
            self:Print(unpack(args))
        else
            self:Print(...)
        end
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

function Addon:Assert(cond, ...)
    if not cond and self.db.profile.echo >= self.ECHO_DEBUG then
        if type(...) == "function" then
            self:Echo(self.ECHO_DEBUG, (...)(select(2, ...)))
        else
            self:Echo(self.ECHO_DEBUG, ...)
        end
    end
end

-- Timer

function Addon:ExtendTimerTo(timer, to)
    if not timer.canceled and timer.ends - GetTime() < to then
        Addon:CancelTimer(timer)
        local fn = timer.looping and Addon.ScheduleRepeatingTimer or Addon.ScheduleTimer
        timer = fn(Addon, timer.func, to, unpack(timer, 1, timer.argsCount))
        return timer, true
    else
        return timer, false
    end
end

function Addon:ExtendTimerBy(timer, by)
    return self:ExtendTimerTo(timer, (timer.ends - GetTime()) + by)
end

function Addon:TimerIsRunning(timer)
    return timer and not timer.canceled and timer.ends > GetTime()
end