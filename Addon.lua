--[[
TODO:
- Block all trades and whispers
- Custom messages
- Masterloot
  * Custom answers

Internal
- Roll.traded should be uncoupled from the rest of the roll lifecycle
]]

local Name, Addon = ...
local LDB = LibStub("LibDataBroker-1.1")
local LDBIcon = LibStub("LibDBIcon-1.0")
local L = LibStub("AceLocale-3.0"):GetLocale(Name)
local GUI, Item, Masterloot, Roll, Trade, Util = Addon.GUI, Addon.Item, Addon.Masterloot, Addon.Roll, Addon.Trade, Addon.Util

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
            enabled = true,
            ui = {showRollFrames = true, showRollsWindow = false},
            echo = Addon.ECHO_INFO,
            announce = {lfd = true, party = true, lfr = true, raid = true, guild = true},
            roll = true,
            whisper = {
                group = {lfd = true, party = true, lfr = true, raid = true, guild = false},
                target = {friend = false, guild = false, other = true}
            },
            awardSelf = false,
            ilvlThreshold = 30,
            transmog = false,
            masterloot = {
                allow = {friend = true, guild = true, guildgroup = true, raidleader = false, raidassistant = false},
                accept = {friend = false, guildmaster = false, guildofficer = false},
                allowAll = false,
                bidPublic = false,
                timeoutBase = Roll.TIMEOUT,
                timeoutPerItem = Roll.TIMEOUT_PER_ITEM,
                council = {guildmaster = false, guildofficer = false, raidleader = false, raidassistant = false},
                votePublic = false
            },
            answer = true
        },
        factionrealm = {
            masterloot = {
                whitelist = {},
                councilWhitelist = {},
            }
        },
        char = {
            specs = {true, true, true, true},
            masterloot = {
                guildRank = 0
            }
        }
    }, true)
    
    -- Register options
    self:RegisterOptions()

    -- Minimap icon
    self:RegisterMinimapIcon()
end

-- Called when the addon is enabled
function Addon:OnEnable()
    -- Enable hooks
    self.Hooks.EnableGroupLootRoll()
    self.Hooks.EnableChatLinks()
    self.Hooks.EnableUnitMenus()

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
    self.Hooks.DisableUnitMenus()

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
                self.Roll.Add(item, owner or Masterloot.GetMasterlooter() or "player", timeout):Start()
            end
        end
    -- Bid
    elseif cmd == "bid" then
        local owner, item, bid = select(2, unpack(args))
        
        if Util.StrIsEmpty(owner) or Item.IsLink(owner)                   -- owner
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

    -- General
    local it = Util.Iter()
    config:RegisterOptionsTable(Name, {
        type = "group",
        args = {
            version = {type = "description", fontSize = "medium", order = it(), name = L["OPT_VERSION"]},
            author = {type = "description", fontSize = "medium", order = it(), name = L["OPT_AUTHOR"]},
            translation = {type = "description", fontSize = "medium", order = it(), name = L["OPT_TRANSLATION"] .. "\n"},
            enable = {
                name = L["OPT_ENABLE"],
                desc = L["OPT_ENABLE_DESC"],
                descStyle = "inline",
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
                descStyle = "inline",
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
                descStyle = "inline",
                type = "toggle",
                order = it(),
                set = function (_, val) self.db.profile.ui.showRollFrames = val end,
                get = function (_) return self.db.profile.ui.showRollFrames end,
                width = "full"
            },
            showRollsWindow = {
                name = L["OPT_ROLLS_WINDOW"],
                desc = L["OPT_ROLLS_WINDOW_DESC"],
                descStyle = "inline",
                type = "toggle",
                order = it(),
                set = function (_, val) self.db.profile.ui.showRollsWindow = val end,
                get = function (_) return self.db.profile.ui.showRollsWindow end,
                width = "full"
            },
        }
    })
    self.configFrame = dialog:AddToBlizOptions(Name)

    local specs

    -- Loot method
    it(1, true)
    config:RegisterOptionsTable(Name .. "_lootmethod", {
        name = L["OPT_LOOT_RULES"],
        type = "group",
        args = {
            awardSelf = {
                name = L["OPT_AWARD_SELF"],
                desc = L["OPT_AWARD_SELF_DESC"] .. "\n",
                descStyle = "inline",
                type = "toggle",
                order = it(),
                set = function (_, val) self.db.profile.awardSelf = val end,
                get = function () return self.db.profile.awardSelf end,
                width = "full"
            },
            itemFilter = {type = "header", order = it(), name = L["OPT_ITEM_FILTER"]},
            itemFilterDesc = {type = "description", fontSize = "medium", order = it(), name = L["OPT_ITEM_FILTER_DESC"] .. "\n"},
            ilvlThreshold = {
                name = L["OPT_ILVL_THRESHOLD"],
                desc = L["OPT_ILVL_THRESHOLD_DESC"],
                type = "range",
                min = -2 * Item.ILVL_THRESHOLD,
                max = 2 * Item.ILVL_THRESHOLD,
                softMin = 0,
                softMax = Item.ILVL_THRESHOLD,
                step = 5,
                order = it(),
                set = function (_, val) self.db.profile.ilvlThreshold = val end,
                get = function () return self.db.profile.ilvlThreshold end,
                width = "full"
            },
            ilvlThresholdDesc = {type = "description", fontSize = "medium", order = it(), name = L["OPT_ILVL_THRESHOLD_DESC"] .. "\n", cmdHidden = true, dropdownHidden = true},
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
                descStyle = "inline",
                type = "toggle",
                order = it(),
                set = function (_, val) self.db.profile.transmog = val end,
                get = function () return self.db.profile.transmog end,
                width = "full"
            }
        }
    })
    dialog:AddToBlizOptions(Name .. "_lootmethod", L["OPT_LOOT_RULES"], Name)

    local allowKeys = {"friend", "guild", "guildgroup", "raidleader", "raidassistant"}
    local allowValues = {FRIEND, LFG_LIST_GUILD_MEMBER, GUILD_GROUP, L["RAID_LEADER"], L["RAID_ASSISTANT"]}

    local acceptKeys = {"friend", "guildmaster", "guildofficer"}
    local acceptValues = {FRIEND, L["GUILD_MASTER"], L["GUILD_OFFICER"]}
    
    -- Masterloot
    it(1, true)
    config:RegisterOptionsTable(Name .. "_masterloot", {
        name = L["OPT_MASTERLOOT"],
        type = "group",
        args = {
            masterlootDesc = {type = "description", fontSize = "medium", order = it(), name = L["OPT_MASTERLOOT_DESC"] .. "\n"},
            masterlootSearch = {
                name = L["OPT_MASTERLOOT_SEARCH"],
                type = "execute",
                order = it(),
                func = function () self.Comm.Send(self.Comm.EVENT_MASTERLOOT_ASK) end
            },
            masterlootStop = {
                name = L["OPT_MASTERLOOT_STOP"],
                type = "execute",
                order = it(),
                func = function () Masterloot.SetMasterlooter(nil) end
            },
            ["space" .. it()] = {type = "description", fontSize = "medium", order = it(0), name = " ", cmdHidden = true, dropdownHidden = true},
            masterlootAllow = {
                name = L["OPT_MASTERLOOT_ALLOW"],
                desc = L["OPT_MASTERLOOT_ALLOW_DESC"],
                type = "multiselect",
                order = it(),
                values = allowValues,
                set = function (_, key, val) self.db.profile.masterloot.allow[allowKeys[key]] = val end,
                get = function (_, key) return self.db.profile.masterloot.allow[allowKeys[key]] end
            },
            masterlootWhitelist = {
                name = L["OPT_MASTERLOOT_WHITELIST"],
                desc = L["OPT_MASTERLOOT_WHITELIST_DESC"],
                type = "input",
                order = it(),
                set = function (_, val)
                    local t = {} for v in val:gmatch("[^%s%d%c,;:_<>|/\\]+") do t[v] = true end
                    self.db.factionrealm.masterloot.whitelist = t
                end,
                get = function () return Util(self.db.factionrealm.masterloot.whitelist).Keys().Sort().Concat(", ")() end,
                width = "full"
            },
            masterlootAllowAll = {
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
            masterlootAccept = {
                name = L["OPT_MASTERLOOT_ACCEPT"],
                desc = L["OPT_MASTERLOOT_ACCEPT_DESC"],
                type = "multiselect",
                order = it(),
                values = acceptValues,
                set = function (_, key, val) self.db.profile.masterloot.accept[acceptKeys[key]] = val end,
                get = function (_, key) return self.db.profile.masterloot.accept[acceptKeys[key]] end
            }
        }
    })
    dialog:AddToBlizOptions(Name .. "_masterloot", L["OPT_MASTERLOOT"], Name)
    
    local councilKeys = {"guildmaster", "guildofficer", "raidleader", "raidassistant"}
    local councilValues = {L["GUILD_MASTER"], L["GUILD_OFFICER"], L["RAID_LEADER"], L["RAID_ASSISTANT"]}

    local guildRanks = Util.GetGuildRanks()
    guildRanks[0], guildRanks[1], guildRanks[2] = "(" .. NONE .. ")", nil, nil

    -- Masterlooter
    it(1, true)
    config:RegisterOptionsTable(Name .. "_masterlooter", {
        name = L["OPT_MASTERLOOTER"],
        type = "group",
        args = {
            masterlooterDesc = {type = "description", fontSize = "medium", order = it(), name = L["OPT_MASTERLOOTER_DESC"] .. "\n"},
            masterlooterStart = {
                name = L["OPT_MASTERLOOT_START"],
                type = "execute",
                order = it(),
                func = function () Masterloot.SetMasterlooter("player") end
            },
            masterlooterStop = {
                name = L["OPT_MASTERLOOT_STOP"],
                type = "execute",
                order = it(),
                func = function () Masterloot.SetMasterlooter(nil) end
            },
            masterlooterTimeoutBase = {
                name = L["OPT_MASTERLOOTER_TIMEOUT_BASE"],
                desc = L["OPT_MASTERLOOTER_TIMEOUT_BASE_DESC"],
                type = "range",
                min = Roll.TIMEOUT,
                max = 120,
                step = 5,
                order = it(),
                set = function (_, val)
                    self.db.profile.masterloot.timeoutBase = val
                    Masterloot.RefreshSession()
                end,
                get = function () return self.db.profile.masterloot.timeoutBase end,
                width = 1.75
            },
            masterlooterTimeoutPerItem = {
                name = L["OPT_MASTERLOOTER_TIMEOUT_PER_ITEM"],
                desc = L["OPT_MASTERLOOTER_TIMEOUT_PER_ITEM_DESC"],
                type = "range",
                min = Roll.TIMEOUT_PER_ITEM,
                max = 60,
                step = 1,
                order = it(),
                set = function (_, val)
                    self.db.profile.masterloot.timeoutPerItem = val
                    Masterloot.RefreshSession()
                end,
                get = function () return self.db.profile.masterloot.timeoutPerItem end,
                width = 1.75
            },
            masterlooterBidPublic = {
                name = L["OPT_MASTERLOOTER_BID_PUBLIC"],
                desc = L["OPT_MASTERLOOTER_BID_PUBLIC_DESC"],
                descStyle = "inline",
                type = "toggle",
                order = it(),
                set = function (_, val)
                    self.db.profile.masterloot.bidPublic = val
                    Masterloot.RefreshSession()
                end,
                get = function () return self.db.profile.masterloot.bidPublic end,
                width = "full"
            },
            masterlooterCouncil = {type = "header", order = it(), name = L["OPT_MASTERLOOTER_COUNCIL"]},
            masterlooterCouncilDesc = {type = "description", fontSize = "medium", order = it(), name = L["OPT_MASTERLOOTER_COUNCIL_DESC"] .. "\n"},
            masterlooterCouncilAllow = {
                name = L["OPT_MASTERLOOTER_COUNCIL_ALLOW"],
                desc = L["OPT_MASTERLOOTER_COUNCIL_ALLOW_DESC"],
                type = "multiselect",
                order = it(),
                values = councilValues,
                set = function (_, key, val)
                    self.db.profile.masterloot.council[councilKeys[key]] = val
                    Masterloot.RefreshSession()
                end,
                get = function (_, key) return self.db.profile.masterloot.council[councilKeys[key]] end
            },
            masterlooterCouncilGuildRank = {
                name = L["OPT_MASTERLOOTER_COUNCIL_GUILD_RANK"],
                desc = L["OPT_MASTERLOOTER_COUNCIL_GUILD_RANK_DESC"],
                type = "select",
                order = it(),
                values = guildRanks,
                set = function (_, val) self.db.char.masterloot.guildRank = val end,
                get = function () return self.db.char.masterloot.guildRank end
            },
            masterlooterCouncilWhitelist = {
                name = L["OPT_MASTERLOOTER_COUNCIL_WHITELIST"],
                desc = L["OPT_MASTERLOOTER_COUNCIL_WHITELIST_DESC"],
                type = "input",
                order = it(),
                set = function (_, val)
                    local t = {} for v in val:gmatch("[^%s%d%c,;:_<>|/\\]+") do t[v] = true end
                    self.db.factionrealm.masterloot.councilWhitelist = t
                    Masterloot.RefreshSession()
                end,
                get = function () return Util(self.db.factionrealm.masterloot.councilWhitelist).Keys().Sort().Concat(", ")() end,
                width = "full"
            },
            masterlooterVotePublic = {
                name = L["OPT_MASTERLOOTER_VOTE_PUBLIC"],
                desc = L["OPT_MASTERLOOTER_VOTE_PUBLIC_DESC"],
                descStyle = "inline",
                type = "toggle",
                order = it(),
                set = function (_, val)
                    self.db.profile.masterloot.votePublic = val
                    Masterloot.RefreshSession()
                end,
                get = function () return self.db.profile.masterloot.votePublic end,
                width = "full"
            }
        }
    })
    dialog:AddToBlizOptions(Name .. "_masterlooter", L["OPT_MASTERLOOTER"], Name)

    local groupKeys = {"party", "raid", "guild", "lfd", "lfr"}
    local groupValues = {PARTY, RAID, GUILD_GROUP, LOOKING_FOR_DUNGEON_PVEFRAME, RAID_FINDER_PVEFRAME}

    -- Messages
    it(1, true)
    config:RegisterOptionsTable(Name .. "_messages", {
        name = L["OPT_MESSAGES"],
        type = "group",
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
            groupchat = {type = "header", order = it(), name = L["OPT_GROUPCHAT"]},
            groupchatDesc = {type = "description", fontSize = "medium", order = it(), name = L["OPT_GROUPCHAT_DESC"] .. "\n"},
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
                descStyle = "inline",
                type = "toggle",
                order = it(),
                set = function (_, val) self.db.profile.roll = val end,
                get = function () return self.db.profile.roll end,
                width = "full"
            },
            whisper = {type = "header", order = it(), name = L["OPT_WHISPER"]},
            whisperDesc = {type = "description", fontSize = "medium", order = it(), name = L["OPT_WHISPER_DESC"] .. "\n"},
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
                descStyle = "inline",
                type = "toggle",
                order = it(),
                set = function (_, val) self.db.profile.answer = val end,
                get = function () return self.db.profile.answer end,
                width = "full"
            }
        }
    })
    dialog:AddToBlizOptions(Name .. "_messages", L["OPT_MESSAGES"], Name)

    -- Profiles
    config:RegisterOptionsTable(Name .. "_profiles", LibStub("AceDBOptions-3.0"):GetOptionsTable(self.db))
    dialog:AddToBlizOptions(Name .. "_profiles", "Profiles", Name)

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
    local methods = {freeforall = true, roundrobin = true, personalloot = true}
    return self.db.profile.enabled and IsInGroup() and methods[GetLootMethod()]
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