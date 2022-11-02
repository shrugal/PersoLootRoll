---@type string
local Name = ...
---@type Addon
local Addon = select(2, ...)
---@type L
local L = LibStub("AceLocale-3.0"):GetLocale(Name)
local C = LibStub("AceConfig-3.0")
local CD = LibStub("AceConfigDialog-3.0")
local CR = LibStub("AceConfigRegistry-3.0")
local LDB = LibStub("LibDataBroker-1.1")
local LDBIcon = LibStub("LibDBIcon-1.0")
local GUI, Item, Locale, Session, Roll, Unit, Util = Addon.GUI, Addon.Item, Addon.Locale, Addon.Session, Addon.Roll, Addon.Unit, Addon.Util
---@class Options
local Self = Addon.Options

-- Config
Self.DEFAULTS = {
    -- VERSION 7
    profile = {
        -- General
        enabled = true,
        activeGroups = {lfd = true, party = true, lfr = true, raid = true, guild = true, community = true},
        onlyMasterloot = false,
        dontShare = false,
        awardSelf = false,
        bidPublic = false,
        chillMode = false,
        allowDisenchant = false,

        -- UI
        ui = {
            showRollFrames = true,
            showActionsWindow = true,
            showRollsWindow = false
        },

        -- Item filter
        filter = {
            enabled = true,
            lvlThreshold = Item.LVL_THRESHOLD,
            ilvlThreshold = Item.ILVL_THRESHOLD,
            ilvlThresholdTrinkets = true,
            ilvlThresholdRings = true,
            pawn = false,
            disenchant = false,
            transmog = false,
            transmogItem = false,
            pets = false
        },

        -- Messages
        messages = {
            echo = Addon.ECHO_INFO,
            group = {
                announce = true,
                groupType = {lfd = true, party = true, lfr = true, raid = true, legacy = true, guild = true, community = true},
                concise = true,
                roll = true
            },
            whisper = {
                ask = false,
                askPrompted = false,
                groupType = {lfd = true, party = true, lfr = true, raid = true, legacy = true},
                target = {friend = false, other = true},
                answer = true,
                suppress = false,
                variants = true
            },
            lines = {}
        },

        -- Masterloot
        masterloot = {
            allow = {friend = true, community = true, guild = true, raidleader = false, raidassistant = false, guildgroup = true},
            accept = {friend = false, guildmaster = false, guildofficer = false},
            allowAll = false,
            whitelists = {},
            rules = {
                timeoutBase = Roll.TIMEOUT,
                timeoutPerItem = Roll.TIMEOUT_PER_ITEM,
                startManually = false,
                startWhisper = false,
                startAll = false,
                startLimit = 0,
                bidPublic = false,
                votePublic = false,
                needAnswers = {},
                greedAnswers = {},
                allowDisenchant = false,
                disenchanter = {},
                allowKeep = false,
                autoAward = false,
                autoAwardTimeout = Roll.TIMEOUT,
                autoAwardTimeoutPerItem = Roll.TIMEOUT_PER_ITEM,
            },
            council = {
                roles = {raidleader = false, raidassistant = false},
                clubs = {},
                whitelists = {}
            }
        },

        -- GUI status
        gui = {
            actions = {anchor = "LEFT", v = 10, h = 0}
        },

        plugins = {}
    },
    -- VERSION 4
    factionrealm = {},
    -- VERSION 5
    char = {
        specs = {true, true, true, true},
        masterloot = {
            clubId = nil
        }
    }
}

-- Option widths
Self.WIDTH_FULL = "full"
Self.WIDTH_HALF = 1.7
Self.WIDTH_THIRD = 1.1
Self.WIDTH_QUARTER = 0.85
Self.WIDTH_FIFTH = 0.67
Self.WIDTH_HALF_SCROLL = Self.WIDTH_HALF - (0.2/2)
Self.WIDTH_THIRD_SCROLL = Self.WIDTH_THIRD - (0.2/3)
Self.WIDTH_QUARTER_SCROLL = Self.WIDTH_QUARTER - (0.2/4)
Self.WIDTH_FIFTH_SCROLL = Self.WIDTH_FIFTH - (0.2/5)

-- Divider for storage in club info
Self.DIVIDER = "------ PersoLootRoll ------"

-- Keys+values for multiselects/dropdowns
Self.groupKeys = {"party", "raid", "lfd", "lfr", "legacy", "guild", "community", "outdoor"}
Self.groupValues = {PARTY, RAID, LOOKING_FOR_DUNGEON_PVEFRAME, RAID_FINDER_PVEFRAME, LFG_LIST_LEGACY, GUILD_GROUP, L["COMMUNITY_GROUP"], BUG_CATEGORY2}

Self.targetKeys = {"friend", "guild", "community", "other"}
Self.targetValues = {FRIEND, GUILD, L["COMMUNITY_MEMBER"], OTHER}

Self.allowKeys = {"friend", "community", "guild", "raidleader", "raidassistant", "guildgroup"}
Self.allowValues = {FRIEND, L["COMMUNITY_MEMBER"], LFG_LIST_GUILD_MEMBER, L["RAID_LEADER"], L["RAID_ASSISTANT"], GUILD_GROUP}

Self.acceptKeys = {"friend", "guildmaster", "guildofficer"}
Self.acceptValues = {FRIEND, L["GUILD_MASTER"], L["GUILD_OFFICER"]}

Self.councilKeys = {"raidleader", "raidassistant"}
Self.councilValues = {L["RAID_LEADER"], L["RAID_ASSISTANT"]}

-- Custom options
Self.CAT_GENERAL = "GENERAL"
Self.CAT_MASTERLOOT = "MASTERLOOT"
Self.CAT_MESSAGES = "MESSAGES"

-- Add custom options for the given key
---@param key string                Unique indentifier
---@param cat string                The options category that should be extended
---@param path string               Dot-separated path inside the options data, ending with a new namespace for these custom options
---@param options table|function    Options data, either a table or a callback with parameters: cat, path
---@param sync function(data, isImport, cat, path)  Callback handling import/export operations
Self.CustomOptions = Util.Registrar.New("OPTION", nil, function (key, cat, path, options, sync)
    return Util.Tbl.Hash("key", key, "cat", cat, "path", path, "options", options, "sync", sync)
end)

-- Other
Self.it = Util.Iter()
Self.registered = false
Self.frames = {}

-------------------------------------------------------
--                Register and Show                  --
-------------------------------------------------------

-- Register options
function Self.Register()
    Self.registered = true

    -- General
    C:RegisterOptionsTable(Name, Self.RegisterGeneral)
    Self.frames.General = CD:AddToBlizOptions(Name)

    -- Messages
    C:RegisterOptionsTable(Name .. " Messages", Self.RegisterMessages)
    Self.frames.Messages = CD:AddToBlizOptions(Name .. " Messages", L["OPT_MESSAGES"], Name)

    -- Masterloot
    C:RegisterOptionsTable(Name .. " Masterloot", Self.RegisterMasterloot)
    Self.frames.Masterloot = CD:AddToBlizOptions(Name .. " Masterloot", L["OPT_MASTERLOOT"], Name)

    -- Profiles
    C:RegisterOptionsTable(Name .. " Profiles", LibStub("AceDBOptions-3.0"):GetOptionsTable(Addon.db))
    Self.frames.Profiles = CD:AddToBlizOptions(Name .. " Profiles", "Profiles", Name)
end

-- Show the options panel
function Self.Show(name)
    local panel = Self.frames[name or "General"]

    -- Have to call it twice because of a blizzard UI bug
    InterfaceOptionsFrame_OpenToCategory(panel)
    InterfaceOptionsFrame_OpenToCategory(panel)
end

-------------------------------------------------------
--                  Custom options                   --
-------------------------------------------------------

-- Apply custom options to an options table
function Self.ApplyCustomOptions(cat, options)
    for _,entry in Self.CustomOptions:Iter() do
        if entry.cat == cat then
            local data = Util.Fn.Val(entry.options, cat, entry.path)
            data.order = data.order or Self.it()
            Util.Tbl.Set(options, entry.path, data)
        end
    end
end

-- Call custom options for sync operation
function Self.SyncCustomOptions(data, isImport)
    for _,entry in Self.CustomOptions:Iter() do
        if entry.sync then
            entry.sync(data, isImport or false, entry.cat, entry.path)
        end
    end
end

-------------------------------------------------------
--                      General                      --
-------------------------------------------------------

function Self.RegisterGeneral()
    local it = Self.it

    local options = {
        name = Name,
        type = "group",
        args = {
            info = {
                type = "description",
                fontSize = "medium",
                order = it(),
                name = L["OPT_VERSION"]:format(Addon.VERSION) .. "  |cff999999-|r  " .. L["OPT_AUTHOR"] .. "  |cff999999-|r  " .. L["OPT_TRANSLATION"] .. "\n"
            },
            enable = {
                name = L["OPT_ENABLE"],
                desc = L["OPT_ENABLE_DESC"],
                type = "toggle",
                order = it(),
                set = function (_, val)
                    Addon.db.profile.enabled = val
                    Addon:Info(L[val and "ENABLED" or "DISABLED"])
                    Addon[val and "Enable" or "Disable"](Addon)
                end,
                get = function (_) return Addon.db.profile.enabled end,
                width = Self.WIDTH_HALF
            },
            activeGroups = {
                name = L["OPT_ACTIVE_GROUPS"],
                desc = L["OPT_ACTIVE_GROUPS_DESC"]:format(Util.GROUP_THRESHOLD*100, Util.GROUP_THRESHOLD*100),
                type = "multiselect",
                control = "Dropdown",
                order = it(),
                values = Self.groupValues,
                set = function (_, key, val)
                    Addon.db.profile.activeGroups[Self.groupKeys[key]] = val
                    Addon:CheckState(true)
                end,
                get = function (_, key) return Addon.db.profile.activeGroups[Self.groupKeys[key]] end
            },
            onlyMasterloot = {
                name = L["OPT_ONLY_MASTERLOOT"],
                desc = L["OPT_ONLY_MASTERLOOT_DESC"],
                type = "toggle",
                order = it(),
                set = function (_, val)
                    Addon.db.profile.onlyMasterloot = val
                    Addon:CheckState(true)
                end,
                get = function () return Addon.db.profile.onlyMasterloot end,
                width = Self.WIDTH_HALF
            },
            dontShare = {
                name = L["OPT_DONT_SHARE"],
                desc = L["OPT_DONT_SHARE_DESC"],
                type = "toggle",
                order = it(),
                set = function (_, val) Addon.db.profile.dontShare = val end,
                get = function () return Addon.db.profile.dontShare end,
                width = Self.WIDTH_HALF
            },
            chillMode = {
                name = L["OPT_CHILL_MODE"],
                desc = L["OPT_CHILL_MODE_DESC"],
                type = "toggle",
                order = it(),
                set = function (_, val) Addon.db.profile.chillMode = val end,
                get = function (_) return Addon.db.profile.chillMode end,
                width = Self.WIDTH_HALF
            },
            awardSelf = {
                name = L["OPT_AWARD_SELF"],
                desc = L["OPT_AWARD_SELF_DESC"],
                type = "toggle",
                order = it(),
                set = function (_, val) Addon.db.profile.awardSelf = val end,
                get = function () return Addon.db.profile.awardSelf end,
                width = Self.WIDTH_HALF
            },
            bidPublic = {
                name = L["OPT_BID_PUBLIC"],
                desc = L["OPT_BID_PUBLIC_DESC"],
                type = "toggle",
                order = it(),
                set = function (_, val) Addon.db.profile.bidPublic = val end,
                get = function () return Addon.db.profile.bidPublic end,
                width = Self.WIDTH_HALF
            },
            allowDisenchant = {
                name = L["OPT_ALLOW_DISENCHANT"],
                desc = L["OPT_ALLOW_DISENCHANT_DESC"],
                type = "toggle",
                order = it(),
                set = function (_, val) Addon.db.profile.allowDisenchant = val end,
                get = function () return Addon.db.profile.allowDisenchant end,
                width = Self.WIDTH_HALF
            },
            ["space" .. it()] = {type = "description", fontSize = "medium", order = it(0), name = " ", cmdHidden = true, dropdownHidden = true},
            ui = {type = "header", order = it(), name = L["OPT_UI"]},
            uiDesc = {type = "description", fontSize = "medium", order = it(), name = L["OPT_UI_DESC"]:format(Name) .. "\n"},
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
                width = Self.WIDTH_THIRD
            },
            showRollFrames = {
                name = L["OPT_ROLL_FRAMES"],
                desc = L["OPT_ROLL_FRAMES_DESC"],
                type = "toggle",
                order = it(),
                set = function (_, val) Addon.db.profile.ui.showRollFrames = val end,
                get = function (_) return Addon.db.profile.ui.showRollFrames end,
                width = Self.WIDTH_THIRD
            },
            showRollsWindow = {
                name = L["OPT_ROLLS_WINDOW"],
                desc = L["OPT_ROLLS_WINDOW_DESC"],
                type = "toggle",
                order = it(),
                set = function (_, val) Addon.db.profile.ui.showRollsWindow = val end,
                get = function (_) return Addon.db.profile.ui.showRollsWindow end,
                width = Self.WIDTH_THIRD
            },
            showActionsWindow = {
                name = L["OPT_ACTIONS_WINDOW"],
                desc = L["OPT_ACTIONS_WINDOW_DESC"],
                type = "toggle",
                order = it(),
                set = function (_, val) Addon.db.profile.ui.showActionsWindow = val end,
                get = function (_) return Addon.db.profile.ui.showActionsWindow end,
                width = Self.WIDTH_THIRD
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
                end,
                width = Self.WIDTH_THIRD
            },
            ["space" .. it()] = {type = "description", fontSize = "medium", order = it(0), name = " ", cmdHidden = true, dropdownHidden = true},
            itemFilter = {type = "header", order = it(), name = L["OPT_ITEM_FILTER"]},
            itemFilterDesc = {type = "description", fontSize = "medium", order = it(), name = L["OPT_ITEM_FILTER_DESC"] .. "\n"},
            itemFilterEnable = {
                name = L["OPT_ITEM_FILTER_ENABLE"],
                desc = L["OPT_ITEM_FILTER_ENABLE_DESC"],
                type = "toggle",
                order = it(),
                set = function (_, val) Addon.db.profile.filter.enabled = val end,
                get = function () return Addon.db.profile.filter.enabled end,
                width = Self.WIDTH_HALF
            },
            disenchant = {
                name = L["OPT_DISENCHANT"],
                desc = L["OPT_DISENCHANT_DESC"],
                type = "toggle",
                order = it(),
                set = function (_, val) Addon.db.profile.filter.disenchant = val end,
                get = function () return Addon.db.profile.filter.disenchant end,
                width = Self.WIDTH_HALF
            },
            lvlThreshold = {
                name = L["OPT_LVL_THRESHOLD"],
                desc = L["OPT_LVL_THRESHOLD_DESC"],
                type = "range",
                order = it(),
                min = -1,
                max = MAX_PLAYER_LEVEL,
                softMin = -1,
                softMax = 30,
                step = 1,
                set = function (_, val) Addon.db.profile.filter.lvlThreshold = val end,
                get = function () return Addon.db.profile.filter.lvlThreshold end,
                disabled = function ()
                    return not Addon.db.profile.filter.enabled
                        or (UnitLevel("player") >= MAX_PLAYER_LEVEL and GetExpansionLevel() == GetMaximumExpansionLevel())
                end,
                width = Self.WIDTH_THIRD
            },
            ilvlThreshold = {
                name = L["OPT_ILVL_THRESHOLD"],
                desc = L["OPT_ILVL_THRESHOLD_DESC"],
                type = "range",
                order = it(),
                min = -4 * Item.ILVL_THRESHOLD,
                max = 4 * Item.ILVL_THRESHOLD,
                step = 5,
                set = function (_, val) Addon.db.profile.filter.ilvlThreshold = -val end,
                get = function () return -Addon.db.profile.filter.ilvlThreshold end,
                disabled = function () return not Addon.db.profile.filter.enabled end,
                width = Self.WIDTH_THIRD
            },
            ilvlThresholdDouble = {
                name = L["OPT_ILVL_THRESHOLD_DOUBLE"],
                desc = L["OPT_ILVL_THRESHOLD_DOUBLE_DESC"],
                type = "multiselect",
                control = "Dropdown",
                order = it(),
                values = {
                    trinkets = L["TRINKETS"],
                    rings = L["RINGS"]
                },
                set = function (_, key, val) Addon.db.profile.filter["ilvlThreshold" .. Util.Str.UcFirst(key)] = val end,
                get = function (_, key) return Addon.db.profile.filter["ilvlThreshold" .. Util.Str.UcFirst(key)] end,
                disabled = function () return not Addon.db.profile.filter.enabled end,
                width = Self.WIDTH_THIRD
            },
            ["space" .. it()] = {type = "description", fontSize = "medium", order = it(0), name = " ", cmdHidden = true, dropdownHidden = true},
            specs = {
                name = L["OPT_SPECS"],
                desc = L["OPT_SPECS_DESC"],
                type = "multiselect",
                control = "Dropdown",
                order = it(),
                values = function ()
                    if not Self.specs then
                        Self.specs = Unit.Specs("player")
                    end
                    return Self.specs
                end,
                set = function (_, key, val)
                    Addon.db.char.specs[key] = val
                    wipe(Item.playerCache)
                end,
                get = function (_, key) return Addon.db.char.specs[key] end,
                disabled = function () return not Addon.db.profile.filter.enabled end,
                width = Self.WIDTH_HALF
            },
            collections = {
                name = COLLECTIONS,
                desc = L["OPT_COLLECTIONS"],
                type = "multiselect",
                control = "Dropdown",
                order = it(),
                values = {
                    transmog = L["OPT_MISSING_TRANSMOG"],
                    pets = L["OPT_MISSING_PETS"]
                },
                set = function (_, key, val) Addon.db.profile.filter[key] = val end,
                get = function (_, key) return Addon.db.profile.filter[key] end,
                disabled = function () return not Addon.db.profile.filter.enabled end,
                width = Self.WIDTH_HALF
            },
            pawn = {
                name = L["OPT_PAWN"],
                desc = L["OPT_PAWN_DESC"],
                type = "toggle",
                order = it(),
                set = function (_, val) Addon.db.profile.filter.pawn = val end,
                get = function () return Addon.db.profile.filter.pawn end,
                disabled = function () return not Addon.db.profile.filter.enabled or not IsAddOnLoaded("Pawn") end,
                width = Self.WIDTH_HALF
            },
            transmogItem = {
                name = L["OPT_MISSING_TRANSMOG_ITEM"],
                desc = L["OPT_MISSING_TRANSMOG_ITEM_DESC"],
                type = "toggle",
                order = it(),
                set = function (_, val) Addon.db.profile.filter.transmogItem = val end,
                get = function () return Addon.db.profile.filter.transmogItem end,
                disabled = function () return not Addon.db.profile.filter.enabled or not Addon.db.profile.filter.transmog end,
                width = Self.WIDTH_HALF
            }
        }
    }

    Self.ApplyCustomOptions(Self.CAT_GENERAL, options.args)

    return options
end

-------------------------------------------------------
--                     Messages                      --
-------------------------------------------------------

function Self.RegisterMessages()
    local it = Self.it
    local lang = Locale.GetRealmLanguage()

    local options = {
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
                set = function (info, val) Addon.db.profile.messages.echo = val end,
                get = function () return Addon.db.profile.messages.echo end
            },
            shouldChat = {
                name = L["OPT_SHOULD_CHAT"],
                type = "group",
                order = it(),
                args = {
                    shouldChatDesc = {type = "description", fontSize = "medium", order = it(), name = L["OPT_SHOULD_CHAT_DESC"] .. "\n"},
                    group = {type = "header", order = it(), name = L["OPT_GROUPCHAT"]},
                    groupAnnounce = {
                        name = L["OPT_GROUPCHAT_ANNOUNCE"],
                        desc = L["OPT_GROUPCHAT_ANNOUNCE_DESC"]  .. "\n\n" .. L["TIP_SUPPRESS_CHAT"],
                        type = "toggle",
                        order = it(),
                        set = function (_, val)
                            local c = Addon.db.profile.messages.group
                            c.announce = val
                            local _ = not val or Util.Tbl.Find(c.groupType, true) or Util.Tbl.Map(c.groupType, Util.Fn.True)
                        end,
                        get = function () return Addon.db.profile.messages.group.announce end,
                        width = Self.WIDTH_THIRD * 2
                    },
                    groupGroupType = {
                        name = L["OPT_GROUPCHAT_GROUP_TYPE"],
                        desc = L["OPT_GROUPCHAT_GROUP_TYPE_DESC"]:format(Util.GROUP_THRESHOLD*100, Util.GROUP_THRESHOLD*100),
                        type = "multiselect",
                        control = "Dropdown",
                        order = it(),
                        values = Self.groupValues,
                        set = function (_, key, val)
                            local c = Addon.db.profile.messages.group
                            c.groupType[Self.groupKeys[key]] = val
                            c.announce = Util.Tbl.Find(c.groupType, true) and c.announce or false
                        end,
                        get = function (_, key) return Addon.db.profile.messages.group.groupType[Self.groupKeys[key]] end,
                        width = Self.WIDTH_THIRD
                    },
                    groupConcise = {
                        name = L["OPT_GROUPCHAT_CONCISE"],
                        desc = L["OPT_GROUPCHAT_CONCISE_DESC"]:format(NEED, YES),
                        type = "toggle",
                        order = it(),
                        set = function (_, val) Addon.db.profile.messages.group.concise = val end,
                        get = function () return Addon.db.profile.messages.group.concise end,
                        width = Self.WIDTH_FULL
                    },
                    groupRoll = {
                        name = L["OPT_GROUPCHAT_ROLL"],
                        desc = L["OPT_GROUPCHAT_ROLL_DESC"],
                        type = "toggle",
                        order = it(),
                        set = function (_, val) Addon.db.profile.messages.group.roll = val end,
                        get = function () return Addon.db.profile.messages.group.roll end,
                        width = Self.WIDTH_FULL
                    },
                    whisper = {type = "header", order = it(), name = L["OPT_WHISPER"]},
                    whisperAsk = {
                        name = L["OPT_WHISPER_ASK"],
                        desc = L["OPT_WHISPER_ASK_DESC"]  .. "\n\n" .. L["TIP_SUPPRESS_CHAT"],
                        type = "toggle",
                        order = it(),
                        set = function (_, val)
                            local c = Addon.db.profile.messages.whisper
                            c.ask, c.askPrompted = val, true
                            if val and not Util.Tbl.Find(c.groupType, true) then Util.Tbl.Map(c.groupType, Util.Fn.True) end
                            if val and not Util.Tbl.Find(c.target, true) then Util.Tbl.Map(c.target, Util.Fn.True) end
                        end,
                        get = function () return Addon.db.profile.messages.whisper.ask end,
                        width = Self.WIDTH_THIRD
                    },
                    whisperTarget = {
                        name = L["OPT_WHISPER_TARGET"],
                        desc = L["OPT_WHISPER_TARGET_DESC"],
                        type = "multiselect",
                        control = "Dropdown",
                        order = it(),
                        values = Self.targetValues,
                        set = function (_, key, val)
                            local c = Addon.db.profile.messages.whisper
                            c.target[Self.targetKeys[key]] = val
                            c.ask = Util.Tbl.Find(c.target, true) and Util.Tbl.Find(c.groupType, true)
                        end,
                        get = function (_, key) return Addon.db.profile.messages.whisper.target[Self.targetKeys[key]] end,
                        width = Self.WIDTH_THIRD
                    },
                    whisperGroupType = {
                        name = L["OPT_WHISPER_GROUP_TYPE"],
                        desc = L["OPT_WHISPER_GROUP_TYPE_DESC"]:format(Util.GROUP_THRESHOLD*100, Util.GROUP_THRESHOLD*100),
                        type = "multiselect",
                        control = "Dropdown",
                        order = it(),
                        values = Self.groupValues,
                        set = function (_, key, val)
                            local c = Addon.db.profile.messages.whisper
                            c.groupType[Self.groupKeys[key]] = val
                            c.ask = Util.Tbl.Find(c.target, true) and Util.Tbl.Find(c.groupType, true)
                        end,
                        get = function (_, key) return Addon.db.profile.messages.whisper.groupType[Self.groupKeys[key]] end,
                        width = Self.WIDTH_THIRD
                    },
                    whisperAnswer = {
                        name = L["OPT_WHISPER_ANSWER"],
                        desc = L["OPT_WHISPER_ANSWER_DESC"],
                        type = "toggle",
                        order = it(),
                        set = function (_, val) Addon.db.profile.messages.whisper.answer = val end,
                        get = function () return Addon.db.profile.messages.whisper.answer end,
                        width = Self.WIDTH_FULL
                    },
                    whisperSuppress = {
                        name = L["OPT_WHISPER_SUPPRESS"],
                        desc = L["OPT_WHISPER_SUPPRESS_DESC"],
                        type = "toggle",
                        order = it(),
                        set = function (_, val) Addon.db.profile.messages.whisper.suppress = val end,
                        get = function () return Addon.db.profile.messages.whisper.suppress end,
                        width = Self.WIDTH_FULL
                    },
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
                        name = L["OPT_CUSTOM_MESSAGES_LOCALIZED"]:format(Locale.GetLanguageName(lang)),
                        type = "group",
                        order = it(),
                        hidden = Locale.GetRealmLanguage() == Locale.DEFAULT,
                        args = Self.GetCustomMessageOptions(false)
                    },
                    default = {
                        name = L["OPT_CUSTOM_MESSAGES_DEFAULT"]:format(Locale.GetLanguageName(Locale.DEFAULT)),
                        type = "group",
                        order = it(),
                        args = Self.GetCustomMessageOptions(true)
                    }
                }
            }
        }
    }

    Self.ApplyCustomOptions(Self.CAT_MESSAGES, options.args)

    return options
end

-- Build options structure for custom messages
function Self.GetCustomMessageOptions(isDefault)
    local realm = Locale.GetRealmLanguage()
    local lang = isDefault and Locale.DEFAULT or realm
    local locale = Locale.GetLocale(lang)
    local default = Locale.GetLocale(Locale.DEFAULT)

    local it = Self.it
    local desc = isDefault and L["OPT_CUSTOM_MESSAGES_DEFAULT_DESC"]:format(Locale.GetLanguageName(Locale.DEFAULT), Locale.GetLanguageName(realm))
                            or L["OPT_CUSTOM_MESSAGES_LOCALIZED_DESC"]:format(Locale.GetLanguageName(realm))
    local t = {
        desc = {type = "description", fontSize = "medium", order = it(), name = desc .. "\n"},
        groupchat = {type = "header", order = it(), name = L["OPT_GROUPCHAT"]},
    }

    local set = function (info, val)
        local line, c = info[3], Addon.db.profile.messages.lines
        if not c[lang] then c[lang] = {} end
        c[lang][line] = not (Util.Str.IsEmpty(val) or val == locale[line]) and val or nil
    end
    local get = function (info)
        local line, c = info[3], Addon.db.profile.messages.lines
        return c[lang] and c[lang][line] or locale[line]
    end
    local validate = function (info, val)
        local line, args = default[info[3]], {}
        for v in line:gmatch("%%[sd]") do
            tinsert(args, v == "%s" and "a" or 1)
        end
        return (pcall(string.format, val, unpack(args)))
    end
    local add = function (line, i)
        local iLine = i and line .. "_" .. i or line
        desc = ("%s: %q%s"):format(DEFAULT, locale[iLine], Util.Str.Prefix(L["OPT_" .. line .. "_DESC"], "\n\n"))
        t[iLine] = {
            name = L["OPT_" .. line]:format(i),
            desc = desc:gsub("(%%.)", "|cffffff78%1|r"):gsub("%d:", "|cffffff78%1|r"),
            type = "input",
            order = it(),
            validate = validate,
            set = set,
            get = get,
            width = Self.WIDTH_FULL
        }
    end

    for _,line in Util.Each(
        "MSG_ROLL_START",
        "MSG_ROLL_START_CONCISE",
        "MSG_ROLL_START_MASTERLOOT",
        "MSG_ROLL_WINNER",
        "MSG_ROLL_WINNER_CONCISE",
        "MSG_ROLL_WINNER_MASTERLOOT",
        "MSG_ROLL_WINNER_MASTERLOOT_OWN",
        "MSG_ROLL_DISENCHANT",
        "MSG_ROLL_DISENCHANT_MASTERLOOT",
        "MSG_ROLL_DISENCHANT_MASTERLOOT_OWN",
        "OPT_WHISPER",
        "MSG_ROLL_WINNER_WHISPER",
        "MSG_ROLL_WINNER_WHISPER_CONCISE",
        "MSG_ROLL_WINNER_WHISPER_MASTERLOOT",
        "MSG_ROLL_WINNER_WHISPER_MASTERLOOT_OWN",
        "MSG_ROLL_DISENCHANT_WHISPER",
        "MSG_ROLL_DISENCHANT_WHISPER_MASTERLOOT",
        "MSG_ROLL_DISENCHANT_WHISPER_MASTERLOOT_OWN",
        "OPT_WHISPER_ASK",
        "MSG_BID",
        "OPT_WHISPER_ANSWER",
        "MSG_ROLL_ANSWER_BID",
        "MSG_ROLL_ANSWER_YES",
        "MSG_ROLL_ANSWER_YES_MASTERLOOT",
        "MSG_ROLL_ANSWER_NO",
        "MSG_ROLL_ANSWER_NO_SELF",
        "MSG_ROLL_ANSWER_NO_OTHER",
        "MSG_ROLL_ANSWER_NOT_ELIGIBLE",
        "MSG_ROLL_ANSWER_NOT_TRADABLE",
        "MSG_ROLL_ANSWER_AMBIGUOUS",
        "MSG_ROLL_ANSWER_STARTED"
    ) do
        if line:sub(1, 3) == "OPT" then
            t[line] = {type = "header", order = it(), name = L[line]}
        elseif line == "MSG_BID" then
            add(line, 1)

            t["OPT_WHISPER_ASK_VARIANTS"] = {
                name = L["OPT_WHISPER_ASK_VARIANTS"],
                desc = L["OPT_WHISPER_ASK_VARIANTS_DESC"],
                type = "toggle",
                order = it(),
                set = function (_, val) Addon.db.profile.messages.whisper.variants = val end,
                get = function () return Addon.db.profile.messages.whisper.variants end
            }

            for i=2,5 do
                add(line, i)
                t[line .. "_" .. i].disabled = function () return not Addon.db.profile.messages.whisper.variants end
            end
        else
            add(line)
        end
    end

    return t
end

-------------------------------------------------------
--                    Masterloot                     --
-------------------------------------------------------

function Self.RegisterMasterloot()
    local it = Self.it

    -- Clubs
    local clubs = Util(C_Club.GetSubscribedClubs())
        :ExceptWhere(false, "clubType", Enum.ClubType.Other)
        :SortBy("clubType", nil, true)()
    local clubValues = Util(clubs)
        :Copy()
        :Map(function (info) return info.name .. (info.clubType == Enum.ClubType.Guild and " (" .. GUILD .. ")" or "") end)()
    Addon.db.char.masterloot.clubId = Addon.db.char.masterloot.clubId or clubs[1] and clubs[1].clubId

    -- This fixes the spacing bug with AceConfigDialog
    CD:ConfigTableChanged("ConfigTableChanged", Name .. " Masterloot")

    local options = {
        name = L["OPT_MASTERLOOT"],
        type = "group",
        childGroups = "tab",
        args = {
            desc = {type = "description", fontSize = "medium", order = it(), name = L["OPT_MASTERLOOT_DESC"] .. "\n"},
            club = {
                name = L["OPT_MASTERLOOT_CLUB"],
                desc = L["OPT_MASTERLOOT_CLUB_DESC"],
                type = "select",
                order = it(),
                values = clubValues,
                set = function (_, val)
                    Addon.db.char.masterloot.clubId = clubs[val].clubId
                    Session.RefreshRules()
                end,
                get = function ()
                    return Util.Tbl.FindWhere(clubs, "clubId", Addon.db.char.masterloot.clubId)
                end,
                width = Self.WIDTH_HALF
            },
            load = {
                name = L["OPT_MASTERLOOT_LOAD"],
                desc = L["OPT_MASTERLOOT_LOAD_DESC"],
                type = "execute",
                order = it(),
                func = function () StaticPopup_Show(GUI.DIALOG_OPT_MASTERLOOT_LOAD) end,
                width = Self.WIDTH_QUARTER
            },
            save = {
                name = L["OPT_MASTERLOOT_SAVE"],
                desc = L["OPT_MASTERLOOT_SAVE_DESC"],
                type = "execute",
                order = it(),
                func = function ()
                    if Self.CanWriteToClub(Addon.db.char.masterloot.clubId) then
                        StaticPopup_Show(GUI.DIALOG_OPT_MASTERLOOT_SAVE)
                    else
                        Self.ExportRules()
                    end
                end,
                width = Self.WIDTH_QUARTER
            },
            approval = {
                name = L["OPT_MASTERLOOT_APPROVAL"],
                type = "group",
                order = it(),
                args = {
                    desc = {type = "description", fontSize = "medium", order = it(), name = L["OPT_MASTERLOOT_APPROVAL_DESC"] .. "\n"},
                    allow = {
                        name = L["OPT_MASTERLOOT_APPROVAL_ALLOW"],
                        desc = L["OPT_MASTERLOOT_APPROVAL_ALLOW_DESC"]:format(Util.GROUP_THRESHOLD*100, Util.GROUP_THRESHOLD*100),
                        type = "multiselect",
                        order = it(),
                        values = Self.allowValues,
                        set = function (_, key, val) Addon.db.profile.masterloot.allow[Self.allowKeys[key]] = val end,
                        get = function (_, key) return Addon.db.profile.masterloot.allow[Self.allowKeys[key]] end
                    },
                    whitelist = {
                        name = L["OPT_MASTERLOOT_APPROVAL_WHITELIST"],
                        desc = L["OPT_MASTERLOOT_APPROVAL_WHITELIST_DESC"],
                        type = "input",
                        order = it(),
                        set = function (_, val)
                            local r, w, t = GetRealmName(), Addon.db.profile.masterloot.whitelists
                            if w[r] then t = wipe(w[r]) else t = Util.Tbl.New() w[r] = t end
                            for v in val:gmatch("[^%s%d%c,;:_<>|/\\]+") do t[v] = true end
                        end,
                        get = function ()
                            return Util(Addon.db.profile.masterloot.whitelists[GetRealmName()] or Util.Tbl.EMPTY):Keys():Sort():Concat(", ")()
                        end,
                        width = Self.WIDTH_FULL
                    },
                    ["space" .. it()] = {type = "description", fontSize = "medium", order = it(0), name = " ", cmdHidden = true, dropdownHidden = true},
                    allowAll = {
                        name = L["OPT_MASTERLOOT_APPROVAL_ALLOW_ALL"],
                        desc = L["OPT_MASTERLOOT_APPROVAL_ALLOW_ALL_DESC"],
                        descStyle = "inline",
                        type = "toggle",
                        order = it(),
                        set = function (_, val) Addon.db.profile.masterloot.allowAll = val end,
                        get = function () return Addon.db.profile.masterloot.allowAll end,
                        width = Self.WIDTH_FULL
                    },
                    ["space" .. it()] = {type = "description", fontSize = "medium", order = it(0), name = " ", cmdHidden = true, dropdownHidden = true},
                    accept = {
                        name = L["OPT_MASTERLOOT_APPROVAL_ACCEPT"],
                        desc = L["OPT_MASTERLOOT_APPROVAL_ACCEPT_DESC"],
                        type = "multiselect",
                        order = it(),
                        values = Self.acceptValues,
                        set = function (_, key, val) Addon.db.profile.masterloot.accept[Self.acceptKeys[key]] = val end,
                        get = function (_, key) return Addon.db.profile.masterloot.accept[Self.acceptKeys[key]] end
                    }
                }
            },
            rules = {
                name = L["OPT_MASTERLOOT_RULES"],
                type = "group",
                order = it(),
                args = {
                    desc = {type = "description", fontSize = "medium", order = it(), name = L["OPT_MASTERLOOT_RULES_DESC"] .. "\n"},
                    timeoutBase = {
                        name = L["OPT_MASTERLOOT_RULES_TIMEOUT_BASE"],
                        desc = L["OPT_MASTERLOOT_RULES_TIMEOUT_BASE_DESC"],
                        type = "range",
                        order = it(),
                        min = 5,
                        max = 300,
                        step = 5,
                        set = function (_, val)
                            Addon.db.profile.masterloot.rules.timeoutBase = val
                            Session.RefreshRules()
                        end,
                        get = function () return Addon.db.profile.masterloot.rules.timeoutBase end,
                        width = Self.WIDTH_THIRD_SCROLL
                    },
                    timeoutPerItem = {
                        name = L["OPT_MASTERLOOT_RULES_TIMEOUT_PER_ITEM"],
                        desc = L["OPT_MASTERLOOT_RULES_TIMEOUT_PER_ITEM_DESC"],
                        type = "range",
                        order = it(),
                        min = 0,
                        max = 60,
                        step = 1,
                        set = function (_, val)
                            Addon.db.profile.masterloot.rules.timeoutPerItem = val
                            Session.RefreshRules()
                        end,
                        get = function () return Addon.db.profile.masterloot.rules.timeoutPerItem end,
                        width = Self.WIDTH_THIRD_SCROLL
                    },
                    startLimit = {
                        name = L["OPT_MASTERLOOT_RULES_START_LIMIT"],
                        desc = L["OPT_MASTERLOOT_RULES_START_LIMIT_DESC"] .. "\n",
                        type = "range",
                        min = 0,
                        max = 10,
                        step = 1,
                        order = it(),
                        set = function (_, val) Addon.db.profile.masterloot.rules.startLimit = val end,
                        get = function () return Addon.db.profile.masterloot.rules.startLimit end,
                        width = Self.WIDTH_THIRD_SCROLL
                    },
                    startManually = {
                        name = L["OPT_MASTERLOOT_RULES_START_MANUALLY"],
                        desc = L["OPT_MASTERLOOT_RULES_START_MANUALLY_DESC"] .. "\n",
                        type = "toggle",
                        order = it(),
                        set = function (_, val) Addon.db.profile.masterloot.rules.startManually = val end,
                        get = function () return Addon.db.profile.masterloot.rules.startManually end,
                        width = Self.WIDTH_THIRD_SCROLL
                    },
                    startWhisper = {
                        name = L["OPT_MASTERLOOT_RULES_START_WHISPER"],
                        desc = L["OPT_MASTERLOOT_RULES_START_WHISPER_DESC"]:format(Locale.GetCommLine("MSG_ROLL"):match("[^,]*")) .. "\n",
                        type = "toggle",
                        order = it(),
                        set = function (_, val) Addon.db.profile.masterloot.rules.startWhisper = val end,
                        get = function () return Addon.db.profile.masterloot.rules.startWhisper end,
                        width = Self.WIDTH_THIRD_SCROLL
                    },
                    startAll = {
                        name = L["OPT_MASTERLOOT_RULES_START_ALL"],
                        desc = L["OPT_MASTERLOOT_RULES_START_ALL_DESC"] .. "\n",
                        type = "toggle",
                        order = it(),
                        set = function (_, val) Addon.db.profile.masterloot.rules.startAll = val end,
                        get = function () return Addon.db.profile.masterloot.rules.startAll end,
                        width = Self.WIDTH_THIRD_SCROLL
                    },
                    ["space" .. it()] = {type = "description", fontSize = "medium", order = it(0), name = " ", cmdHidden = true, dropdownHidden = true},
                    bidsAndVotes = {type = "header", order = it(), name = L["OPT_MASTERLOOT_BIDS_AND_VOTES"]},
                    bidPublic = {
                        name = L["OPT_MASTERLOOT_RULES_BID_PUBLIC"],
                        desc = L["OPT_MASTERLOOT_RULES_BID_PUBLIC_DESC"] .. "\n",
                        type = "toggle",
                        order = it(),
                        set = function (_, val)
                            Addon.db.profile.masterloot.rules.bidPublic = val
                            Session.RefreshRules()
                        end,
                        get = function () return Addon.db.profile.masterloot.rules.bidPublic end,
                        width = Self.WIDTH_HALF_SCROLL
                    },
                    votePublic = {
                        name = L["OPT_MASTERLOOT_RULES_VOTE_PUBLIC"],
                        desc = L["OPT_MASTERLOOT_RULES_VOTE_PUBLIC_DESC"],
                        type = "toggle",
                        order = it(),
                        set = function (_, val)
                            Addon.db.profile.masterloot.rules.votePublic = val
                            Session.RefreshRules()
                        end,
                        get = function () return Addon.db.profile.masterloot.rules.votePublic end,
                        width = Self.WIDTH_HALF_SCROLL
                    },
                    ["space" .. it()] = {type = "description", fontSize = "medium", order = it(0), name = " ", cmdHidden = true, dropdownHidden = true},
                    needAnswers = {
                        name = L["OPT_MASTERLOOT_RULES_NEED_ANSWERS"],
                        desc = L["OPT_MASTERLOOT_RULES_NEED_ANSWERS_DESC"]:format(NEED),
                        type = "input",
                        order = it(),
                        set = function (_, val)
                            local t = wipe(Addon.db.profile.masterloot.rules.needAnswers)
                            for v in val:gmatch("[^,]+") do
                                v = v:gsub("^%s*(.*)%s*$", "%1")
                                if #t < 9 and not Util.Str.IsEmpty(v) then
                                    tinsert(t, v == NEED and Roll.ANSWER_NEED or v)
                                end
                            end
                            Session.RefreshRules()
                        end,
                        get = function ()
                            local s = ""
                            for i,v in pairs(Addon.db.profile.masterloot.rules.needAnswers) do
                                s = s .. (i > 1 and ", " or "") .. (v == Roll.ANSWER_NEED and NEED or v)
                            end
                            return s
                        end,
                        width = Self.WIDTH_FULL
                    },
                    greedAnswers = {
                        name = L["OPT_MASTERLOOT_RULES_GREED_ANSWERS"],
                        desc = L["OPT_MASTERLOOT_RULES_GREED_ANSWERS_DESC"]:format(GREED),
                        type = "input",
                        order = it(),
                        set = function (_, val)
                            local t = wipe(Addon.db.profile.masterloot.rules.greedAnswers)
                            for v in val:gmatch("[^,]+") do
                                v = v:gsub("^%s*(.*)%s*$", "%1")
                                if #t < 9 and not Util.Str.IsEmpty(v) then
                                    tinsert(t, v == GREED and Roll.ANSWER_GREED or v)
                                end
                            end
                            Session.RefreshRules()
                        end,
                        get = function ()
                            local s = ""
                            for i,v in pairs(Addon.db.profile.masterloot.rules.greedAnswers) do
                                s = s .. (i > 1 and ", " or "") .. (v == Roll.ANSWER_GREED and GREED or v)
                            end
                            return s
                        end,
                        width = Self.WIDTH_FULL
                    },
                    ["space" .. it()] = {type = "description", fontSize = "medium", order = it(0), name = " ", cmdHidden = true, dropdownHidden = true},
                    allowDisenchant = {
                        name = L["OPT_ALLOW_DISENCHANT"],
                        desc = L["OPT_MASTERLOOT_RULES_ALLOW_DISENCHANT_DESC"],
                        type = "toggle",
                        order = it(),
                        set = function (_, val) Addon.db.profile.masterloot.rules.allowDisenchant = val end,
                        get = function () return Addon.db.profile.masterloot.rules.allowDisenchant end,
                        width = Self.WIDTH_FULL
                    },
                    disenchanter = {
                        name = L["OPT_MASTERLOOT_RULES_DISENCHANTER"],
                        desc = L["OPT_MASTERLOOT_RULES_DISENCHANTER_DESC"],
                        type = "input",
                        order = it(),
                        set = function (_, val)
                            local r, w, t = GetRealmName(), Addon.db.profile.masterloot.rules.disenchanter
                            if w[r] then t = wipe(w[r]) else t = Util.Tbl.New() w[r] = t end
                            for v in val:gmatch("[^%s%d%c,;:_<>|/\\]+") do t[v] = true end
                        end,
                        get = function ()
                            return Util(Addon.db.profile.masterloot.rules.disenchanter[GetRealmName()] or Util.Tbl.EMPTY):Keys():Sort():Concat(", ")()
                        end,
                        width = Self.WIDTH_FULL
                    },
                    ["space" .. it()] = {type = "description", fontSize = "medium", order = it(0), name = " ", cmdHidden = true, dropdownHidden = true},
                    award = {type = "header", order = it(), name = L["OPT_MASTERLOOT_AWARD"]},
                    allowKeep = {
                        name = L["OPT_MASTERLOOT_RULES_ALLOW_KEEP"],
                        desc = L["OPT_MASTERLOOT_RULES_ALLOW_KEEP_DESC"],
                        type = "toggle",
                        order = it(),
                        set = function (_, val)
                            Addon.db.profile.masterloot.rules.allowKeep = val
                            Session.RefreshRules()
                        end,
                        get = function () return Addon.db.profile.masterloot.rules.allowKeep end
                    },
                    autoAward = {
                        name = L["OPT_MASTERLOOT_RULES_AUTO_AWARD"],
                        desc = L["OPT_MASTERLOOT_RULES_AUTO_AWARD_DESC"],
                        type = "toggle",
                        order = it(),
                        set = function (_, val) Addon.db.profile.masterloot.rules.autoAward = val end,
                        get = function () return Addon.db.profile.masterloot.rules.autoAward end,
                        width = Self.WIDTH_FULL
                    },
                    autoAwardTimeout = {
                        name = L["OPT_MASTERLOOT_RULES_AUTO_AWARD_TIMEOUT"],
                        desc = L["OPT_MASTERLOOT_RULES_AUTO_AWARD_TIMEOUT_DESC"],
                        type = "range",
                        order = it(),
                        min = 5,
                        max = 120,
                        step = 5,
                        set = function (_, val) Addon.db.profile.masterloot.rules.autoAwardTimeout = val end,
                        get = function () return Addon.db.profile.masterloot.rules.autoAwardTimeout end,
                        width = Self.WIDTH_HALF_SCROLL
                    },
                    autoAwardTimeoutPerItem = {
                        name = L["OPT_MASTERLOOT_RULES_AUTO_AWARD_TIMEOUT_PER_ITEM"],
                        desc = L["OPT_MASTERLOOT_RULES_AUTO_AWARD_TIMEOUT_PER_ITEM_DESC"],
                        type = "range",
                        order = it(),
                        min = 0,
                        max = 30,
                        step = 1,
                        set = function (_, val) Addon.db.profile.masterloot.rules.autoAwardTimeoutPerItem = val end,
                        get = function () return Addon.db.profile.masterloot.rules.autoAwardTimeoutPerItem end,
                        width = Self.WIDTH_HALF_SCROLL
                    },
                }
            },
            council = {
                name = L["OPT_MASTERLOOT_COUNCIL"],
                type = "group",
                order = it(),
                args = {
                    desc = {type = "description", fontSize = "medium", order = it(), name = L["OPT_MASTERLOOT_COUNCIL_DESC"] .. "\n"},
                    roles = {
                        name = L["OPT_MASTERLOOT_COUNCIL_ROLES"],
                        desc = L["OPT_MASTERLOOT_COUNCIL_ROLES_DESC"],
                        type = "multiselect",
                        order = it(),
                        values = Self.councilValues,
                        set = function (_, key, val)
                            Addon.db.profile.masterloot.council.roles[Self.councilKeys[key]] = val
                            Session.RefreshRules()
                        end,
                        get = function (_, key) return Addon.db.profile.masterloot.council.roles[Self.councilKeys[key]] end
                    },
                    ranks = {
                        name = L["OPT_MASTERLOOT_COUNCIL_CLUB_RANK"],
                        desc = L["OPT_MASTERLOOT_COUNCIL_CLUB_RANK_DESC"],
                        type = "multiselect",
                        order = it(),
                        values = function ()
                            return Util.GetClubRanks(Addon.db.char.masterloot.clubId)
                        end,
                        set = function (_, key, val)
                            local clubId = Addon.db.char.masterloot.clubId
                            Util.Tbl.Set(Addon.db.profile.masterloot.council.clubs, clubId, "ranks", key, val)
                            Session.RefreshRules()
                        end,
                        get = function (_, key)
                            local clubId = Addon.db.char.masterloot.clubId
                            return Util.Tbl.Get(Addon.db.profile.masterloot.council.clubs, clubId, "ranks", key)
                        end
                    },
                    whitelist = {
                        name = L["OPT_MASTERLOOT_COUNCIL_WHITELIST"],
                        desc = L["OPT_MASTERLOOT_COUNCIL_WHITELIST_DESC"],
                        type = "input",
                        order = it(),
                        set = function (_, val)
                            local r, w, t = GetRealmName(), Addon.db.profile.masterloot.council.whitelists
                            if w[r] then t = wipe(w[r]) else t = Util.Tbl.New() w[r] = t end
                            for v in val:gmatch("[^%s%d%c,;:_<>|/\\]+") do t[v] = true end
                            Session.RefreshRules()
                        end,
                        get = function ()
                            return Util(Addon.db.profile.masterloot.council.whitelists[GetRealmName()] or Util.Tbl.EMPTY):Keys():Sort():Concat(", ")()
                        end,
                        width = Self.WIDTH_FULL
                    }
                }
            }
        }
    }

    -- Add custom options
    Self.ApplyCustomOptions(Self.CAT_MASTERLOOT, options.args)

    return options
end

function Self.ImportRules()
    local clubId = Addon.db.char.masterloot.clubId
    if not clubId then return end

    local c = Addon.db.profile.masterloot
    local s = Self.ReadFromClub(clubId)

    -- Rules
    for i in pairs(c.rules) do
        if i ~= "disenchanter" then
            Self.SetValOrDefault("profile.masterloot.rules." .. i, s[i])
        end
    end

    c.rules.disenchanter[GetRealmName()] = Util.Tbl.IsSet(s.disenchanter) and Util(s.disenchanter):Map(Unit.FullName):Flip(true)()

    -- Council
    local ranks = Util.GetClubRanks(clubId)
    Util.Tbl.Set(c.council.clubs, clubId, "ranks", s.councilRanks and Util(s.councilRanks):Map(function (v) return tonumber(v) or Util.Tbl.Find(ranks, v) end):Flip(true)() or {})
    c.council.roles = s.councilRoles and Util.Tbl.Flip(s.councilRoles, true) or {}
    c.council.whitelists[GetRealmName()] = Util.Tbl.IsSet(s.councilWhitelist) and Util(s.councilWhitelist):Map(Unit.FullName):Flip(true)()

    -- Custom
    Self.SyncCustomOptions(s, true)

    CR:NotifyChange(Name .. " Masterloot")
end

function Self.ExportRules()
    local clubId = Addon.db.char.masterloot.clubId
    if not clubId then return end

    local info = C_Club.GetClubInfo(clubId)
    local c = Addon.db.profile.masterloot
    local s = Util.Tbl.New()

    -- Rules
    for i,v in pairs(c.rules) do
        local d = Addon.db.defaults.profile.masterloot.rules[i]
        if i ~= "disenchanter" and v ~= d and not (type(v) == "table" and Util.Tbl.Equals(v, d)) then
            s[i] = v
        end
    end

    local dis = Util.Tbl.Keys(c.rules.disenchanter[GetRealmName()] or Util.Tbl.EMPTY)
    if next(dis) then s.disenchanter = dis end

    -- Council
    local ranks = Util(Util.Tbl.Get(c.council.clubs, clubId, "ranks") or Util.Tbl.EMPTY):CopyOnly(true, true):Keys()()
    if next(ranks) then s.councilRanks = ranks end
    local roles = Util(c.council.roles):CopyOnly(true, true):Keys()()
    if next(roles) then s.councilRoles = roles end
    local wl = Util.Tbl.Keys(c.council.whitelists[GetRealmName()] or Util.Tbl.EMPTY)
    if next(wl) then s.councilWhitelist = wl end

    -- Custom
    Self.SyncCustomOptions(s, false)

    -- Export
    local r, canWrite = Self.WriteToClub(clubId, s)
    if r and type(r) == "string" then
        local f = GUI("Frame")
            .SetLayout("Fill")
            .SetTitle(Name .. " - " .. L["OPT_MASTERLOOT_EXPORT_WINDOW"])
            .SetCallback("OnClose", function (self) self:Release() end)
            .Show()()
        GUI("MultiLineEditBox")
            .DisableButton(true)
            .SetLabel(canWrite and L["OPT_MASTERLOOT_EXPORT_GUILD_ONLY"] or L["OPT_MASTERLOOT_EXPORT_NO_PRIV"])
            .SetText(r)
            .AddTo(f)
    elseif r then
        Addon:Info(L["OPT_MASTERLOOT_EXPORT_DONE"]:format(info.name))
    else
        Addon:Error(L["ERROR_OPT_MASTERLOOT_EXPORT_FAILED"]:format(info.name))
    end
end

-------------------------------------------------------
--             Community import/export               --
-------------------------------------------------------

-- Read one or all params from a communities' description
---@param clubId string
---@param key string?
---@return any
function Self.ReadFromClub(clubId, key)
    local t, found = not key and Util.Tbl.New() or nil, false

    local info = C_Club.GetClubInfo(clubId)
    if info and not Util.Str.IsEmpty(info.description) then
        for i,line in Util.Each(("\n"):split(info.description)) do
            local name, val = line:match("^PLR%-(.-): ?(.*)")
            if name then
                name = Util.Str.ToCamelCase(name)
                if not key then
                    t[name] = Self.DecodeParam(name, val)
                elseif key == name then
                    return Self.DecodeParam(name, val)
                end
            end
        end
    end

    return t
end

-- Check if we can write to the given club
---@param clubId integer
function Self.CanWriteToClub(clubId)
    local info = C_Club.GetClubInfo(clubId)
    local priv = info and C_Club.GetClubPrivileges(clubId)

    if not info or not priv then
        return
    elseif not priv.canSetDescription then
        return false, false
    elseif info.clubType ~= Enum.ClubType.Guild then
        return false, true
    else
        return true, true
    end
end

-- Read one or all params to a communities' description
---@param keyOrTbl string|table
function Self.WriteToClub(clubId, keyOrTbl, val)
    local isKey = type(keyOrTbl) ~= "table"

    local info = C_Club.GetClubInfo(clubId)
    if info then
        local desc, i, found = Util.Str.Split(info.description, "\n"), 1, Util.Tbl.New()

        -- Update or delete existing entries
        while desc[i] do
            local line = desc[i]

            local param = line:match("^PLR%-(.-):")
            if param then
                local name = Util.Str.ToCamelCase(param)
                found[name] = true

                if not isKey or isKey == name then
                    local v
                    if isKey then v = val else v = keyOrTbl[name] end

                    if v ~= nil then
                        desc[i] = ("PLR-%s: %s"):format(param, Self.EncodeParam(name, v))
                    else
                        tremove(desc, i)
                        i = i - 1
                    end

                    if isKey then break end
                end
            elseif line == Self.DIVIDER then
                found[Self.DIVIDER] = i
            end

            i = i + 1
        end

        -- Add new entries
        for name,v in Util.Each(keyOrTbl) do
            if isKey then name, v = v, val end

            if not found[name] and v ~= nil then
                if not found[Self.DIVIDER] then
                    tinsert(desc, "\n" .. Self.DIVIDER)
                    found[Self.DIVIDER] = #desc
                end

                found[name] = true
                tinsert(desc, found[Self.DIVIDER] + 1, ("PLR-%s: %s"):format(Util.Str.FromCamelCase(name, "-", true), Self.EncodeParam(name, v)))
            end
        end

        local str = Util.Tbl.Concat(desc, "\n")
        Util.Tbl.Release(desc, found)

        -- We can only write to guild communities, and only when we have the rights to do so
        if str == info.description then
            return true
        elseif not C_Club.GetClubPrivileges(clubId).canSetDescription then
            return str, false
        elseif info.clubType ~= Enum.ClubType.Guild then
            return str, true
        else
            SetGuildInfoText(str)
            return true
        end
    end
end

-- Encode a param to its string representation
---@param val any
function Self.EncodeParam(name, val)
    local t = type(val)
    if Util.In(t, "string", "number") then
        return val
    elseif t == "boolean" then
        return val and "true" or "false"
    elseif t == "table" then
        return table.concat(val, ", ")
    else
        return ""
    end
end

-- Decode a param from its string representation
---@param str string
---@return any
function Self.DecodeParam(name, str)
    local t = Util.Str.StartsWith(name, "council") and "table" or type(Addon.db.defaults.profile.masterloot.rules[name])
    if t == "boolean" then
        return Util.In(str:lower(), "true", "1", "yes")
    elseif t == "number" then
        return tonumber(str)
    elseif t == "table" then
        local val = Util.Tbl.New()
        for v in str:gmatch("[^,]+") do
            v = v:gsub("^%s*(.*)%s*$", "%1")
            tinsert(val, tonumber(v) or v)
        end
        return val
    elseif str ~= "" then
        return str
    end
end

-------------------------------------------------------
--                    Migration                      --
-------------------------------------------------------

-- Migrate options from an older version to the current one
function Self.Migrate()
    local p, f, c = Addon.db.profile, Addon.db.factionrealm, Addon.db.char

    -- Profile
    if p.version then
        if p.version < 5 then
            Self.MigrateOption("echo", p, p.messages)
            Self.MigrateOption("announce", p, p.messages.group, true, "groupType")
            Self.MigrateOption("roll", p, p.messages.group)
            p.messages.whisper.ask = true
            Self.MigrateOption("answer", p, p.messages.whisper)
            Self.MigrateOption("suppress", p, p.messages.whisper)
            Self.MigrateOption("group", p.whisper, p.messages.whisper, true, "groupType")
            Self.MigrateOption("target", p.whisper, p.messages.whisper, true)
            p.whisper = nil
            Self.MigrateOption("messages", p, p.messages, true, "lines", "^%l%l%u%u$", true)
            p.version = 5
        end
        if p.version < 6 then
            p.messages.group.groupType.community = p.messages.group.groupType.guild
            p.messages.whisper.groupType.community = p.messages.whisper.groupType.guild
            p.messages.whisper.target.community = p.messages.whisper.target.guild
            if p.masterlooter then
                Self.MigrateOption("timeoutBase", p.masterlooter, p.masterloot.rules)
                Self.MigrateOption("timeoutPerItem", p.masterlooter, p.masterloot.rules)
                Self.MigrateOption("bidPublic", p.masterlooter, p.masterloot.rules)
                Self.MigrateOption("votePublic", p.masterlooter, p.masterloot.rules)
                Self.MigrateOption("answers1", p.masterlooter, p.masterloot.rules, nil, "needAnswers")
                Self.MigrateOption("answers2", p.masterlooter, p.masterloot.rules, nil, "greedAnswers")
                Self.MigrateOption("raidleader", p.masterlooter.council, p.masterloot.council.roles)
                Self.MigrateOption("raidassistant", p.masterlooter.council, p.masterloot.council.roles)

                local guildId = C_Club.GetGuildClubId()
                if guildId and Util.Tbl.Get(p, "masterlooter.council") then
                    if p.masterlooter.council.guildmaster then
                        Util.Tbl.Set(p.masterloot.council.clubs, guildId, "ranks", 1, true)
                    end
                    if p.masterlooter.council.guildofficer then
                        Util.Tbl.Set(p.masterloot.council.clubs, guildId, "ranks", 2, true)
                    end
                end

                p.masterlooter = nil
            end
            p.version = 6
        end
        if p.version < 7 then
            Self.MigrateOption("ilvlThreshold", p, p.filter)
            Self.MigrateOption("ilvlThresholdTrinkets", p, p.filter)
            Self.MigrateOption("ilvlThresholdRings", p, p.filter)
            Self.MigrateOption("pawn", p, p.filter)
            Self.MigrateOption("transmog", p, p.filter)
            p.version = 7
        end
        if p.version < 8 then
            p.messages.whisper.askPrompted = p.messages.whisper.ask
            p.version = 8
        end
        if p.version < 9 then
            p.messages.group.groupType.legacy = p.messages.group.groupType.raid
            p.messages.whisper.groupType.legacy = p.messages.whisper.groupType.raid
        end
    end
    p.version = 9

    -- Factionrealm
    if f.version then
        if f.version < 4 then
            if Util.Tbl.Get(f, "masterloot.whitelist") then
                for i in pairs(f.masterloot.whitelist) do
                    Util.Tbl.Set(p.masterloot.whitelists, GetRealmName(), i, true)
                end
            end
            if Util.Tbl.Get(f, "masterlooter.councilWhitelist") then
                for i in pairs(f.masterlooter.councilWhitelist) do
                    Util.Tbl.Set(p.masterloot.council.whitelists, GetRealmName(), i, true)
                end
            end
            f.masterloot, f.masterlooter = nil
        end
    end
    f.version = 4

    -- Char
    if c.version then
        if c.version < 4 then
            local guildId = C_Club.GetGuildClubId()
            if guildId then
                local guildRank = Util.Tbl.Get(c, "masterloot.council.guildRank")
                if guildRank and guildRank > 0 then
                    Util.Tbl.Set(p.masterloot.council.clubs, guildId, "ranks", guildRank, true)
                end
                c.masterloot.clubId = guildId
            end
            c.masterloot.council.guildRank = nil
            c.version = 4
        end
        if c.version < 5 then
            Self.MigrateOption("clubId", c.masterloot.council, c.masterloot)
            c.masterloot.council = nil
        end
    end
    c.version = 5
end

-- Migrate a single option
---@param key string
---@param source table?
---@param dest string
---@param depth integer|boolean?
---@param destKey string?
---@param filter table|string|function?
---@param keep boolean?
function Self.MigrateOption(key, source, dest, depth, destKey, filter, keep)
    if source then
        depth = type(depth) == "number" and depth or depth and 10 or 0
        destKey = destKey or key
        local val = source[key]

        if type(val) == "table" and depth > 0 then
            for i,v in pairs(val) do
                local filterType = type(filter)
                if not filter or filterType == "table" and Util.In(i, filter) or filterType == "string" and i:match(filter) or filterType == "function" and filter(i, v, depth) then
                    dest[destKey] = dest[destKey] or {}
                    Self.MigrateOption(i, val, dest[destKey], depth - 1)
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
--                   Minimap Icon                    --
-------------------------------------------------------

function Self.RegisterMinimapIcon()
    local plugin = LDB:NewDataObject(Name, {
        type = "data source",
        text = Name,
        icon = "Interface\\Buttons\\UI-GroupLoot-Dice-Up"
    })

    -- OnClick
    plugin.OnClick = function (_, btn)
        if btn == "RightButton" then
            Self.Show()
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
--                      Helper                       --
-------------------------------------------------------

function Self.SetValOrDefault(path, val)
    if val == nil then
        local d = Util.Tbl.Get(Addon.db, "defaults." .. path)
        Util.Tbl.Set(Addon.db, path, type(d) == "table" and Util.Tbl.Copy(d) or d)
    else
        Util.Tbl.Set(Addon.db, path, val)
    end
end