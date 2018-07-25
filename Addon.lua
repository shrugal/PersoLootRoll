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
local Comm, GUI, Inspect, Item, Locale, Masterloot, Roll, Trade, Unit, Util = Addon.Comm, Addon.GUI, Addon.Inspect, Addon.Item, Addon.Locale, Addon.Masterloot, Addon.Roll, Addon.Trade, Addon.Unit, Addon.Util

-- Echo levels
Addon.ECHO_NONE = 0
Addon.ECHO_ERROR = 1
Addon.ECHO_INFO = 2
Addon.ECHO_VERBOSE = 3
Addon.ECHO_DEBUG = 4

-- Channels
Addon.CHANNEL_ALPHA = "alpha"
Addon.CHANNEL_BETA = "beta"
Addon.CHANNEL_STABLE = "stable"
Addon.CHANNELS = Util.TblFlip({Addon.CHANNEL_ALPHA, Addon.CHANNEL_BETA, Addon.CHANNEL_STABLE})

Addon.rolls = Util.TblCounter()
Addon.timers = {}

-- Versions
Addon.versions = {}
Addon.versionNoticeShown = false
Addon.disabled = {}

-------------------------------------------------------
--                    Addon stuff                    --
-------------------------------------------------------

-- Called when the addon is loaded
function Addon:OnInitialize()
    self.db = LibStub("AceDB-3.0"):New(Name .. "DB", {
        -- VERSION 5
        profile = {
            -- General
            enabled = true,
            onlyMasterloot = false,
            dontShare = false,
            awardSelf = false,
            bidPublic = false,
            ui = {showRollFrames = true, showActionsWindow = true, showRollsWindow = false},
            
            -- Item filter
            ilvlThreshold = 30,
            ilvlThresholdTrinkets = true,
            transmog = false,

            -- Messages
            messages = {
                echo = Addon.ECHO_INFO,
                group = {
                    announce = true,
                    groupType = {lfd = true, party = true, lfr = true, raid = true, guild = true},
                    roll = true
                },
                whisper = {
                    ask = false,
                    groupType = {lfd = true, party = true, lfr = true, raid = true, guild = false},
                    target = {friend = false, guild = false, other = true},
                    answer = true,
                    suppress = false,
                },
                lines = {}
            },

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

            -- GUI status
            gui = {
                actions = {anchor = "LEFT", v = 10, h = 0}
            }
        },
        -- VERSION 3
        factionrealm = {
            masterloot = {
                whitelist = {}
            },
            masterlooter = {
                councilWhitelist = {},
            }
        },
        -- VERSION 3
        char = {
            specs = {true, true, true, true},
            masterloot = {
                guildRank = 0
            }
        }
    }, true)
    
    -- Migrate options
    self:MigrateOptions()

    -- Register chat commands
    self:RegisterChatCommand(Name, "HandleChatCommand")
    self:RegisterChatCommand("plr", "HandleChatCommand")

    -- Minimap icon
    self:RegisterMinimapIcon()
end

-- Called when the addon is enabled
function Addon:OnEnable()
    -- Register options table
    if not self.configFrames then
        self:RegisterOptions()
    end

    -- Enable hooks
    self.Hooks.EnableGroupLootRoll()
    self.Hooks.EnableChatLinks()
    self.Hooks.EnableUnitMenus()

    -- Register events
    self.Events.RegisterEvents()

    -- Periodically clear old rolls
    self.timers.clearRolls = self:ScheduleRepeatingTimer(Roll.Clear, Roll.CLEAR)

    -- Start inspecting
    Inspect.Start()
    if not Inspect.timer then
        -- IsInGroup doesn't work right after logging in, so check again after waiting a bit.
        self.timers.inspectStart = self:ScheduleTimer(Inspect.Start, 10)
    end

    -- Update state
    if IsInGroup() then
        self.Events.GROUP_JOINED()
    end
end

-- Called when the addon is disabled
function Addon:OnDisable()
    -- Disable hooks
    self.Hooks.DisableGroupLootRoll()
    self.Hooks.DisableChatLinks()
    self.Hooks.DisableUnitMenus()

    -- Unregister events
    self.Events.UnregisterEvents()

    -- Stop clear timer
    if self.timers.clearRolls then
        self:CancelTimer(self.timers.clearRolls)
    end
    self.timers.clearRolls = nil

    -- Stop inspecting
    if self.timers.inspectStart then
        self:CancelTimer(self.timers.inspectStart)
        self.timers.inspectStart = nil
    end

    -- Update state
    if IsInGroup() then
        self.Events.GROUP_LEFT()
    else
        self:OnTrackingChanged(true)
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
        local name, pre, line = Name, "plr config", msg:sub(cmd:len() + 2)

        -- Handle submenus
        local subs = Util.Tbl(false, "messages", "masterloot", "profiles")
        if Util.In(args[2], subs) then
            name, pre, line = name .. " " .. Util.StrUcFirst(args[2]), pre .. " " .. args[2], line:sub(args[2]:len() + 2)
        end

        LibStub("AceConfigCmd-3.0").HandleCommand(Addon, pre, name, line)

        -- Add submenus as additional options
        if Util.StrIsEmpty(args[2]) then
            for i,v in pairs(subs) do
                local name = Util.StrUcFirst(v)
                local getter = LibStub("AceConfigRegistry-3.0"):GetOptionsTable(Name .. " " .. name)
                print("  |cffffff78" .. v .. "|r - " .. (getter("cmd", "AceConfigCmd-3.0").name or name))
            end
        end

        Util.TblRelease(subs)
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
                local roll = Roll.Add(item, owner or Masterloot.GetMasterlooter() or "player", timeout)
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
        or bid and not Util.TblFind(Roll.BIDS, tonumber(bid)) then -- answer
            self:Print(L["USAGE_BID"])
        else
            local roll = Roll.Find(nil, owner, item)
            if roll then
                roll:Bid(bid)
            end
        end
    -- Trade
    elseif cmd == "trade" then
        Trade.Initiate(args[2] or "target")
    -- Rolls/None
    elseif cmd == "rolls" or not cmd then
        GUI.Rolls.Show()
    -- Update and export trinket list
    elseif cmd == "updatetrinkets" and Item.UpdateTrinkets then
        Item.UpdateTrinkets()
    -- Unknown
    else
        self:Err(L["ERROR_CMD_UNKNOWN"], cmd)
    end
end

function Addon:Help()
    self:Print(L["HELP"])
end

-------------------------------------------------------
--                      Options                      --
-------------------------------------------------------

function Addon:ShowOptions(name)
    local panel = self.configFrames[name or "General"]

    -- Have to call it twice because of a blizzard UI bug
    InterfaceOptionsFrame_OpenToCategory(panel)
    InterfaceOptionsFrame_OpenToCategory(panel)
end

function Addon:RegisterOptions()
    local config = LibStub("AceConfig-3.0")
    local dialog = LibStub("AceConfigDialog-3.0")
    local it = Util.Iter()
    local half, third, quarter = 1.7, 1.1, 0.85

    self.configFrames = {}

    -- GENERAL

    local specs

    config:RegisterOptionsTable(Name, {
        type = "group",
        args = {
            info = {
                type = "description",
                fontSize = "medium",
                order = it(),
                name = Util.StrFormat(L["OPT_VERSION"], Addon.VERSION) .. "  |cff999999-|r  " .. L["OPT_AUTHOR"] .. "  |cff999999-|r  " .. L["OPT_TRANSLATION"] .. "\n"
            },
            enable = {
                name = L["OPT_ENABLE"],
                desc = L["OPT_ENABLE_DESC"],
                type = "toggle",
                order = it(),
                set = function (_, val)
                    self.db.profile.enabled = val
                    self:OnTrackingChanged(true)
                    self:Info(L[val and "ENABLED" or "DISABLED"])
                end,
                get = function (_) return self.db.profile.enabled end,
                width = half
            },
            awardSelf = {
                name = L["OPT_AWARD_SELF"],
                desc = L["OPT_AWARD_SELF_DESC"],
                type = "toggle",
                order = it(),
                set = function (_, val) self.db.profile.awardSelf = val end,
                get = function () return self.db.profile.awardSelf end,
                width = half
            },
            onlyMasterloot = {
                name = L["OPT_ONLY_MASTERLOOT"],
                desc = L["OPT_ONLY_MASTERLOOT_DESC"],
                type = "toggle",
                order = it(),
                set = function (_, val)
                    self.db.profile.onlyMasterloot = val
                    self:OnTrackingChanged(not val)
                end,
                get = function () return self.db.profile.onlyMasterloot end,
                width = half
            },
            bidPublic = {
                name = L["OPT_BID_PUBLIC"],
                desc = L["OPT_BID_PUBLIC_DESC"],
                type = "toggle",
                order = it(),
                set = function (_, val) self.db.profile.bidPublic = val end,
                get = function () return self.db.profile.bidPublic end,
                width = half
            },
            dontShare = {
                name = L["OPT_DONT_SHARE"],
                desc = L["OPT_DONT_SHARE_DESC"],
                type = "toggle",
                order = it(),
                set = function (_, val) self.db.profile.dontShare = val end,
                get = function () return self.db.profile.dontShare end,
                width = half
            },
            ui = {type = "header", order = it(), name = L["OPT_UI"]},
            uiDesc = {type = "description", fontSize = "medium", order = it(), name = Util.StrFormat(L["OPT_UI_DESC"], Name) .. "\n"},
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
            showActionsWindow = {
                name = L["OPT_ACTIONS_WINDOW"],
                desc = L["OPT_ACTIONS_WINDOW_DESC"],
                type = "toggle",
                order = it(),
                set = function (_, val) self.db.profile.ui.showActionsWindow = val end,
                get = function (_) return self.db.profile.ui.showActionsWindow end
            },
            moveActionsWindow = {
                name = L["OPT_ACTIONS_WINDOW_MOVE"],
                desc = L["OPT_ACTIONS_WINDOW_MOVE_DESC"],
                type = "execute",
                order = it(),
                func = function ()
                    HideUIPanel(InterfaceOptionsFrame)
                    HideUIPanel(GameMenuFrame)
                    GUI.Actions.Show(true)
                end
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
                width = half
            },
            ilvlThresholdTrinkets = {
                name = L["OPT_ILVL_THRESHOLD_TRINKETS"],
                desc = L["OPT_ILVL_THRESHOLD_TRINKETS_DESC"],
                type = "toggle",
                order = it(),
                set = function (_, val) self.db.profile.ilvlThresholdTrinkets = val end,
                get = function () return self.db.profile.ilvlThresholdTrinkets end,
                width = half
            },
            ["space" .. it()] = {type = "description", fontSize = "medium", order = it(0), name = " ", cmdHidden = true, dropdownHidden = true},
            specs = {
                name = L["OPT_SPECS"],
                desc = L["OPT_SPECS_DESC"],
                type = "multiselect",
                order = it(),
                values = function ()
                    if not specs then
                        specs = Unit.Specs("player")
                    end
                    return specs
                end,
                set = function (_, key, val)
                    self.db.char.specs[key] = val
                    wipe(Item.playerCache)
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
    self.configFrames["General"] = dialog:AddToBlizOptions(Name)

    -- MESSAGES

    local groupKeys = {"party", "raid", "guild", "lfd", "lfr"}
    local groupValues = {PARTY, RAID, GUILD_GROUP, LOOKING_FOR_DUNGEON_PVEFRAME, RAID_FINDER_PVEFRAME}

    local lang = Locale.GetRealmLanguage()

    it(1, true)
    config:RegisterOptionsTable(Name .. " Messages", {
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
                set = function (info, val) self.db.profile.messages.echo = val end,
                get = function () return self.db.profile.messages.echo end
            },
            shouldChat = {
                name = L["OPT_SHOULD_CHAT"],
                type = "group",
                order = it(),
                args = {
                    ShouldChatDesc = {type = "description", fontSize = "medium", order = it(), name = L["OPT_SHOULD_CHAT_DESC"] .. "\n"},
                    group = {type = "header", order = it(), name = L["OPT_GROUPCHAT"]},
                    groupAnnounce = {
                        name = L["OPT_GROUPCHAT_ANNOUNCE"],
                        desc = L["OPT_GROUPCHAT_ANNOUNCE_DESC"],
                        type = "toggle",
                        order = it(),
                        set = function (_, val)
                            local c = self.db.profile.messages.group
                            c.announce = val
                            local _ = not val or Util.TblFind(c.groupType, true) or Util.TblMap(c.groupType, Util.FnTrue)
                        end,
                        get = function () return self.db.profile.messages.group.announce end,
                        width = "full"
                    },
                    groupGroupType = {
                        name = L["OPT_GROUPCHAT_GROUP_TYPE"],
                        desc = L["OPT_GROUPCHAT_GROUP_TYPE_DESC"],
                        type = "multiselect",
                        order = it(),
                        values = groupValues,
                        set = function (_, key, val)
                            local c = self.db.profile.messages.group
                            c.groupType[groupKeys[key]] = val
                            c.announce = Util.TblFind(c.groupType, true) and c.announce or false
                        end,
                        get = function (_, key) return self.db.profile.messages.group.groupType[groupKeys[key]] end,
                    },
                    groupRoll = {
                        name = L["OPT_GROUPCHAT_ROLL"],
                        desc = L["OPT_GROUPCHAT_ROLL_DESC"],
                        type = "toggle",
                        order = it(),
                        set = function (_, val) self.db.profile.messages.group.roll = val end,
                        get = function () return self.db.profile.messages.group.roll end,
                        width = "full"
                    },
                    whisper = {type = "header", order = it(), name = L["OPT_WHISPER"]},
                    whisperAsk = {
                        name = L["OPT_WHISPER_ASK"],
                        desc = L["OPT_WHISPER_ASK_DESC"],
                        type = "toggle",
                        order = it(),
                        set = function (_, val)
                            local c = self.db.profile.messages.whisper
                            c.ask = val
                            local _ = not val or Util.TblFind(c.groupType, true) or Util.TblMap(c.groupType, Util.FnTrue)
                            local _ = not val or Util.TblFind(c.target, true) or Util.TblMap(c.target, Util.FnTrue)
                        end,
                        get = function () return self.db.profile.messages.whisper.ask end,
                        width = third
                    },
                    whisperAnswer = {
                        name = L["OPT_WHISPER_ANSWER"],
                        desc = L["OPT_WHISPER_ANSWER_DESC"],
                        type = "toggle",
                        order = it(),
                        set = function (_, val) self.db.profile.messages.whisper.answer = val end,
                        get = function () return self.db.profile.messages.whisper.answer end,
                        width = third
                    },
                    whisperSuppress = {
                        name = L["OPT_WHISPER_SUPPRESS"],
                        desc = L["OPT_WHISPER_SUPPRESS_DESC"],
                        type = "toggle",
                        order = it(),
                        set = function (_, val) self.db.profile.messages.whisper.suppress = val end,
                        get = function () return self.db.profile.messages.whisper.suppress end,
                        width = third
                    },
                    whisperGroupType = {
                        name = L["OPT_WHISPER_GROUP_TYPE"],
                        desc = L["OPT_WHISPER_GROUP_TYPE_DESC"],
                        type = "multiselect",
                        order = it(),
                        values = groupValues,
                        set = function (_, key, val)
                            local c = self.db.profile.messages.whisper
                            c.groupType[groupKeys[key]] = val
                            c.ask = Util.TblFind(c.groupType, true) and c.ask or false
                        end,
                        get = function (_, key) return self.db.profile.messages.whisper.groupType[groupKeys[key]] end
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
                        set = function (_, key, val)
                            local c = self.db.profile.messages.whisper
                            c.target[key] = val
                            c.ask = Util.TblFind(c.target, true) and c.ask or false
                        end,
                        get = function (_, key) return self.db.profile.messages.whisper.target[key] end
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
                        name = Util.StrFormat(L["OPT_CUSTOM_MESSAGES_LOCALIZED"], Locale.GetLanguageName(lang)),
                        type = "group",
                        order = it(),
                        hidden = Locale.GetRealmLanguage() == Locale.DEFAULT,
                        args = Addon:GetCustomMessageOptions(false)
                    },
                    default = {
                        name = Util.StrFormat(L["OPT_CUSTOM_MESSAGES_DEFAULT"], Locale.GetLanguageName(Locale.DEFAULT)),
                        type = "group",
                        order = it(),
                        args = Addon:GetCustomMessageOptions(true)
                    }
                }
            }
        }
    })
    self.configFrames["Messages"] = dialog:AddToBlizOptions(Name .. " Messages", L["OPT_MESSAGES"], Name)
    
    -- MASTERLOOT

    local allowKeys = {"friend", "guild", "guildgroup", "raidleader", "raidassistant"}
    local allowValues = {FRIEND, LFG_LIST_GUILD_MEMBER, GUILD_GROUP, L["RAID_LEADER"], L["RAID_ASSISTANT"]}

    local acceptKeys = {"friend", "guildmaster", "guildofficer"}
    local acceptValues = {FRIEND, L["GUILD_MASTER"], L["GUILD_OFFICER"]}
    
    local councilKeys = {"guildmaster", "guildofficer", "raidleader", "raidassistant"}
    local councilValues = {L["GUILD_MASTER"], L["GUILD_OFFICER"], L["RAID_LEADER"], L["RAID_ASSISTANT"]}

    local guildRanks

    it(1, true)
    config:RegisterOptionsTable(Name .. " Masterloot", {
        name = L["OPT_MASTERLOOT"],
        type = "group",
        childGroups = "tab",
        args = {
            desc = {type = "description", fontSize = "medium", order = it(), name = L["OPT_MASTERLOOT_DESC"] .. "\n"},
            search = {
                name = L["OPT_MASTERLOOT_SEARCH"],
                type = "execute",
                order = it(),
                func = function () Comm.Send(Comm.EVENT_MASTERLOOT_ASK) end
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
                        width = half
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
                        width = half
                    },
                    ["space" .. it()] = {type = "description", fontSize = "medium", order = it(0), name = " ", cmdHidden = true, dropdownHidden = true},
                    needAnswers = {
                        name = L["OPT_MASTERLOOTER_NEED_ANSWERS"],
                        desc = Util.StrFormat(L["OPT_MASTERLOOTER_NEED_ANSWERS_DESC"], NEED),
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
                        desc = Util.StrFormat(L["OPT_MASTERLOOTER_GREED_ANSWERS_DESC"], GREED),
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
    self.configFrames["Masterloot"] = dialog:AddToBlizOptions(Name .. " Masterloot", L["OPT_MASTERLOOT"], Name)

    -- PROFILES

    config:RegisterOptionsTable(Name .. " Profiles", LibStub("AceDBOptions-3.0"):GetOptionsTable(self.db))
    self.configFrames["Profiles"] = dialog:AddToBlizOptions(Name .. " Profiles", "Profiles", Name)
end

function Addon:GetCustomMessageOptions(isDefault)
    local realm = Locale.GetRealmLanguage()
    local lang = isDefault and Locale.DEFAULT or realm
    local locale = Locale.GetLocale(lang)
    local default = Locale.GetLocale(Locale.DEFAULT)

    local set = function (info, val)
        local line, c = info[3], self.db.profile.messages.lines
        if not c[lang] then c[lang] = {} end
        c[lang][line] = not (Util.StrIsEmpty(val) or val == locale[line]) and val or nil
    end
    local get = function (info)
        local line, c = info[3], self.db.profile.messages.lines
        return c[lang] and c[lang][line] or locale[line]
    end
    local validate = function (info, val)
        local line, args = default[info[3]], {}
        for v in line:gmatch("%%[sd]") do
            tinsert(args, v == "%s" and "a" or 1)
        end
        return (pcall(Util.StrFormat, val, unpack(args)))
    end

    local it = Util.Iter()
    local desc = isDefault and L["OPT_CUSTOM_MESSAGES_DEFAULT_DESC"]:format(Locale.GetLanguageName(Locale.DEFAULT), Locale.GetLanguageName(realm))
                            or L["OPT_CUSTOM_MESSAGES_LOCALIZED_DESC"]:format(Locale.GetLanguageName(realm))
    local t = {
        desc = {type = "description", fontSize = "medium", order = it(), name = desc .. "\n"},
        groupchat = {type = "header", order = it(), name = L["OPT_GROUPCHAT"]},
    }

    for i,line in pairs({"MSG_ROLL_START", "MSG_ROLL_START_MASTERLOOT", "MSG_ROLL_WINNER", "MSG_ROLL_WINNER_MASTERLOOT", "whisper", "MSG_BID", "MSG_ROLL_WINNER_WHISPER", "MSG_ROLL_WINNER_WHISPER_MASTERLOOT", "MSG_ROLL_ANSWER_BID", "MSG_ROLL_ANSWER_YES", "MSG_ROLL_ANSWER_YES_MASTERLOOT", "MSG_ROLL_ANSWER_NO_SELF", "MSG_ROLL_ANSWER_NO_OTHER", "MSG_ROLL_ANSWER_NOT_TRADABLE", "MSG_ROLL_ANSWER_AMBIGUOUS"}) do
        if line == "whisper" then
            t[line] = {type = "header", order = it(), name = L["OPT_WHISPER"]}
        else
            desc = DEFAULT .. ": \"" .. locale[line] .. "\"" .. Util.StrPrefix(L["OPT_" .. line .. "_DESC"], "\n\n")
            t[line] = {
                name = L["OPT_" .. line],
                desc = desc:gsub("(%%.)", "|cffffff78%1|r"):gsub("%d:", "|cffffff78%1|r"),
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
    if not c.version or c.version < 5 then -- TODO: Change for the next version
        self:MigrateOption("echo", c, c.messages)
        self:MigrateOption("announce", c, c.messages.group, true, "groupType")
        self:MigrateOption("roll", c, c.messages.group)
        c.messages.whisper.ask = true
        self:MigrateOption("answer", c, c.messages.whisper)
        self:MigrateOption("suppress", c, c.messages.whisper)
        self:MigrateOption("group", c.whisper, c.messages.whisper, true, "groupType")
        self:MigrateOption("target", c.whisper, c.messages.whisper, true)
        c.whisper = nil
        self:MigrateOption("messages", c, c.messages, true, "lines", "^%l%l%u%u$", true)
        c.version = 5
    end

    -- Factionrealm
    local c = Addon.db.factionrealm
    c.version = 3 -- TODO: Change for the next version
    
    -- Char
    local c = Addon.db.char
    c.version = 3 -- TODO: Change for the next version
end

-- Migrate a single option
function Addon:MigrateOption(key, source, dest, depth, destKey, filter, keep)
    if source then
        depth = type(depth) == "number" and depth or depth and 10 or 0
        destKey = destKey or key
        local val = source[key]

        if type(val) == "table" and depth > 0 then
            for i,v in pairs(val) do
                local filterType = type(filter)
                if not filter or filterType == "table" and Util.In(i, filter) or filterType == "string" and i:match(filter) or filterType == "function" and filter(i, v, depth) then
                    dest[destKey] = dest[destKey] or {}
                    self:MigrateOption(i, val, dest[destKey], depth - 1)
                end
            end
        else
            dest[destKey] = Util.Default(val, dest[destKey])
        end

        if not keep then
            source[key] = nil
        end
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
--                       State                       --
-------------------------------------------------------

-- Check if we should currently track loot etc.
function Addon:IsTracking(unit)
    if not unit or Unit.IsSelf(unit) then
        return self.db.profile.enabled
           and (not self.db.profile.onlyMasterloot or Masterloot.GetMasterlooter())
           and IsInGroup()
           and Util.In(GetLootMethod(), "freeforall", "roundrobin", "personalloot", "group")
    else
        unit = Unit.Name(unit)
        return self.versions[unit] and not self.disabled[unit]
    end
end

-- Tracking state potentially changed
function Addon:OnTrackingChanged(sync)
    local isTracking = self:IsTracking()

    -- Let others know
    if not Util.BoolXor(isTracking, self.disabled[UnitName("player")]) then
        Comm.Send(Comm["EVENT_" .. (isTracking and "ENABLE" or "DISABLE")])
    end

    -- Start/Stop tracking process
    if sync then
        if isTracking then
            Comm.Send(Comm.EVENT_SYNC)
            Inspect.Queue()
        else
            Util.TblIter(self.rolls, Roll.Clear)
            Inspect.Clear()
        end
    end

    Inspect[isTracking and "Start" or "Stop"]()
end

-- Set a unit's version string
function Addon:SetVersion(unit, version)
    self.versions[unit] = version

    if not version then
        self.disabled[unit] = nil
    elseif not self.versionNoticeShown then
        if self:CompareVersion(version) == 1 then
            self:Info(L["VERSION_NOTICE"])
            self.versionNoticeShown = true
        end
    end
end

-- Get major, channel and minor versions for the given version string or unit
function Addon:GetVersion(versionOrUnit)
    local t = type(versionOrUnit)
    local version = (not versionOrUnit or UnitIsUnit(versionOrUnit, "player")) and self.VERSION
                 or (t == "number" or t == "string" and tonumber(versionOrUnit:sub(1, 1))) and versionOrUnit
                 or self.versions[Unit.Name(versionOrUnit)]

    t = type(version)
    if t == "number" then
        return version, Addon.CHANNEL_STABLE, 0
    elseif t == "string" then
        local version, channel, revision = version:match("([%d.]+)-(%a+)(%d+)")
        return tonumber(version), channel, tonumber(revision)
    end
end

-- Get 1 if the version is higher, -1 if the version is lower or 0 if they are the same or on non-comparable channels
function Addon:CompareVersion(versionOrUnit)
    local version, channel, revision = self:GetVersion(versionOrUnit)
    if version then
        local myVersion, myChannel, myRevision = self:GetVersion()
        local channelNum, myChannelNum = Addon.CHANNELS[channel], Addon.CHANNELS[myChannel]

        if channel == myChannel then
            return version == myVersion and Util.Compare(revision, myRevision) or Util.Compare(version, myVersion)
        elseif channelNum and myChannelNum then
            return version >= myVersion and channelNum > myChannelNum and 1
                or version <= myVersion and channelNum < myChannelNum and -1
                or 0
        else
            return 0
        end
    end
end

-------------------------------------------------------
--                      Console                      --
-------------------------------------------------------

function Addon:Echo(lvl, line, ...)
    if self.db.profile.messages.echo >= lvl then
        if lvl == self.ECHO_DEBUG then
            local args = Util.Tbl(false, line, ...)
            for i,v in pairs(args) do
                if Util.In(type(v), "table", "function") then args[i] = Util.ToString(v) end
            end
            self:Print(unpack(args))
            Util.TblRelease(args)
        else
            self:Print(Util.StrFormat(line, ...))
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
    if not cond and self.db.profile.messages.echo >= self.ECHO_DEBUG then
        if type(...) == "function" then
            self:Echo(self.ECHO_DEBUG, (...)(select(2, ...)))
        else
            self:Echo(self.ECHO_DEBUG, ...)
        end
    end
end

-------------------------------------------------------
--                       Timer                       --
-------------------------------------------------------

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