local Name, Addon = ...
local L = LibStub("AceLocale-3.0"):GetLocale(Name)
local C = LibStub("AceConfig-3.0")
local CD = LibStub("AceConfigDialog-3.0")
local CR = LibStub("AceConfigRegistry-3.0")
local LDB = LibStub("LibDataBroker-1.1")
local LDBIcon = LibStub("LibDBIcon-1.0")
local Comm, GUI, Inspect, Item, Locale, Session, Roll, Unit, Util = Addon.Comm, Addon.GUI, Addon.Inspect, Addon.Item, Addon.Locale, Addon.Session, Addon.Roll, Addon.Unit, Addon.Util
local Self = Addon.Options

Self.WIDTH_FULL = "full"
Self.WIDTH_HALF = 1.7
Self.WIDTH_THIRD = 1.1
Self.WIDTH_QUARTER = 0.85
Self.WIDTH_HALF_SCROLL = Self.WIDTH_HALF - .1
Self.WIDTH_THIRD_SCROLL = Self.WIDTH_THIRD - .05
Self.WIDTH_QUARTER_SCROLL = Self.WIDTH_QUARTER - .05

Self.DIVIDER = "------ PersoLootRoll ------"

Self.it = Util.Iter()
Self.registered = false
Self.frames = {}

Self.groupKeys = {"party", "lfd", "guild", "raid", "lfr", "community"}
Self.groupValues = {PARTY, LOOKING_FOR_DUNGEON_PVEFRAME, GUILD_GROUP, RAID, RAID_FINDER_PVEFRAME, L["COMMUNITY_GROUP"]}

Self.groupKeysList = {"party", "raid", "lfd", "lfr", "guild", "community"}
Self.groupValuesList = {PARTY, RAID, LOOKING_FOR_DUNGEON_PVEFRAME, RAID_FINDER_PVEFRAME, GUILD_GROUP, L["COMMUNITY_GROUP"]}

Self.allowKeys = {"friend", "community", "guild", "raidleader", "raidassistant", "guildgroup"}
Self.allowValues = {FRIEND, L["COMMUNITY_MEMBER"], LFG_LIST_GUILD_MEMBER, L["RAID_LEADER"], L["RAID_ASSISTANT"], GUILD_GROUP}

Self.acceptKeys = {"friend", "guildmaster", "guildofficer"}
Self.acceptValues = {FRIEND, L["GUILD_MASTER"], L["GUILD_OFFICER"]}

Self.councilKeys = {"raidleader", "raidassistant"}
Self.councilValues = {L["RAID_LEADER"], L["RAID_ASSISTANT"]}

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
--                      General                      --
-------------------------------------------------------

function Self.RegisterGeneral()
    local it = Self.it

    return {
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
                    Addon:OnTrackingChanged(true)
                    Addon:Info(L[val and "ENABLED" or "DISABLED"])
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
                values = Self.groupValuesList,
                set = function (_, key, val)
                    Addon.db.profile.activeGroups[Self.groupKeysList[key]] = val
                    Addon:OnTrackingChanged()
                end,
                get = function (_, key) return Addon.db.profile.activeGroups[Self.groupKeysList[key]] end
            },
            onlyMasterloot = {
                name = L["OPT_ONLY_MASTERLOOT"],
                desc = L["OPT_ONLY_MASTERLOOT_DESC"],
                type = "toggle",
                order = it(),
                set = function (_, val)
                    Addon.db.profile.onlyMasterloot = val
                    Addon:OnTrackingChanged()
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
                width = Self.WIDTH_FULL
            },
            showRollFrames = {
                name = L["OPT_ROLL_FRAMES"],
                desc = L["OPT_ROLL_FRAMES_DESC"],
                type = "toggle",
                order = it(),
                set = function (_, val) Addon.db.profile.ui.showRollFrames = val end,
                get = function (_) return Addon.db.profile.ui.showRollFrames end,
                width = Self.WIDTH_HALF
            },
            showRollsWindow = {
                name = L["OPT_ROLLS_WINDOW"],
                desc = L["OPT_ROLLS_WINDOW_DESC"],
                type = "toggle",
                order = it(),
                set = function (_, val) Addon.db.profile.ui.showRollsWindow = val end,
                get = function (_) return Addon.db.profile.ui.showRollsWindow end,
                width = Self.WIDTH_HALF
            },
            showActionsWindow = {
                name = L["OPT_ACTIONS_WINDOW"],
                desc = L["OPT_ACTIONS_WINDOW_DESC"],
                type = "toggle",
                order = it(),
                set = function (_, val) Addon.db.profile.ui.showActionsWindow = val end,
                get = function (_) return Addon.db.profile.ui.showActionsWindow end,
                width = Self.WIDTH_HALF
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
            itemFilter = {type = "header", order = it(), name = L["OPT_ITEM_FILTER"]},
            itemFilterDesc = {type = "description", fontSize = "medium", order = it(), name = L["OPT_ITEM_FILTER_DESC"] .. "\n"},
            ilvlThreshold = {
                name = L["OPT_ILVL_THRESHOLD"],
                desc = L["OPT_ILVL_THRESHOLD_DESC"],
                type = "range",
                order = it(),
                min = -4 * Item.ILVL_THRESHOLD,
                max = 4 * Item.ILVL_THRESHOLD,
                step = 5,
                set = function (_, val) Addon.db.profile.filter.ilvlThreshold = val end,
                get = function () return Addon.db.profile.filter.ilvlThreshold end,
                width = Self.WIDTH_THIRD
            },
            ilvlThresholdTrinkets = {
                name = L["OPT_ILVL_THRESHOLD_TRINKETS"],
                desc = L["OPT_ILVL_THRESHOLD_TRINKETS_DESC"],
                type = "toggle",
                order = it(),
                set = function (_, val) Addon.db.profile.filter.ilvlThresholdTrinkets = val end,
                get = function () return Addon.db.profile.filter.ilvlThresholdTrinkets end,
                width = Self.WIDTH_THIRD
            },
            ilvlThresholdRings = {
                name = L["OPT_ILVL_THRESHOLD_RINGS"],
                desc = L["OPT_ILVL_THRESHOLD_RINGS_DESC"],
                type = "toggle",
                order = it(),
                set = function (_, val) Addon.db.profile.filter.ilvlThresholdRings = val end,
                get = function () return Addon.db.profile.filter.ilvlThresholdRings end,
                width = Self.WIDTH_THIRD
            },
            ["space" .. it()] = {type = "description", fontSize = "medium", order = it(0), name = " ", cmdHidden = true, dropdownHidden = true},
            specs = {
                name = L["OPT_SPECS"],
                desc = L["OPT_SPECS_DESC"],
                type = "multiselect",
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
                get = function (_, key) return Addon.db.char.specs[key] end
            },
            ["space" .. it()] = {type = "description", fontSize = "medium", order = it(0), name = " ", cmdHidden = true, dropdownHidden = true},
            pawn = {
                name = L["OPT_PAWN"],
                desc = L["OPT_PAWN_DESC"],
                type = "toggle",
                order = it(),
                set = function (_, val) Addon.db.profile.filter.pawn = val end,
                get = function () return Addon.db.profile.filter.pawn end,
                width = Self.WIDTH_THIRD,
                disabled = function () return not IsAddOnLoaded("Pawn") end
            },
            transmog = {
                name = L["OPT_TRANSMOG"],
                desc = L["OPT_TRANSMOG_DESC"],
                type = "toggle",
                order = it(),
                set = function (_, val) Addon.db.profile.filter.transmog = val end,
                get = function () return Addon.db.profile.filter.transmog end,
                width = Self.WIDTH_THIRD
            },
            disenchant = {
                name = L["OPT_DISENCHANT"],
                desc = L["OPT_DISENCHANT_DESC"],
                type = "toggle",
                order = it(),
                set = function (_, val) Addon.db.profile.filter.disenchant = val end,
                get = function () return Addon.db.profile.filter.disenchant end,
                width = Self.WIDTH_THIRD
            }
        }
    }
end

-------------------------------------------------------
--                     Messages                      --
-------------------------------------------------------

function Self.RegisterMessages()
    local it = Self.it
    local lang = Locale.GetRealmLanguage()

    return {
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
                    -- ShouldChatDesc = {type = "description", fontSize = "medium", order = it(), name = L["OPT_SHOULD_CHAT_DESC"] .. "\n"},
                    group = {type = "header", order = it(), name = L["OPT_GROUPCHAT"]},
                    groupAnnounce = {
                        name = L["OPT_GROUPCHAT_ANNOUNCE"],
                        desc = L["OPT_GROUPCHAT_ANNOUNCE_DESC"],
                        type = "toggle",
                        order = it(),
                        set = function (_, val)
                            local c = Addon.db.profile.messages.group
                            c.announce = val
                            local _ = not val or Util.TblFind(c.groupType, true) or Util.TblMap(c.groupType, Util.FnTrue)
                        end,
                        get = function () return Addon.db.profile.messages.group.announce end,
                        width = Self.WIDTH_FULL
                    },
                    groupGroupType = {
                        name = L["OPT_GROUPCHAT_GROUP_TYPE"],
                        desc = L["OPT_GROUPCHAT_GROUP_TYPE_DESC"]:format(Util.GROUP_THRESHOLD*100, Util.GROUP_THRESHOLD*100),
                        type = "multiselect",
                        order = it(),
                        values = Self.groupValues,
                        set = function (_, key, val)
                            local c = Addon.db.profile.messages.group
                            c.groupType[Self.groupKeys[key]] = val
                            c.announce = Util.TblFind(c.groupType, true) and c.announce or false
                        end,
                        get = function (_, key) return Addon.db.profile.messages.group.groupType[Self.groupKeys[key]] end,
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
                        desc = L["OPT_WHISPER_ASK_DESC"],
                        type = "toggle",
                        order = it(),
                        set = function (_, val)
                            local c = Addon.db.profile.messages.whisper
                            c.ask = val
                            local _ = not val or Util.TblFind(c.groupType, true) or Util.TblMap(c.groupType, Util.FnTrue)
                            local _ = not val or Util.TblFind(c.target, true) or Util.TblMap(c.target, Util.FnTrue)
                        end,
                        get = function () return Addon.db.profile.messages.whisper.ask end,
                        width = Self.WIDTH_THIRD
                    },
                    whisperAnswer = {
                        name = L["OPT_WHISPER_ANSWER"],
                        desc = L["OPT_WHISPER_ANSWER_DESC"],
                        type = "toggle",
                        order = it(),
                        set = function (_, val) Addon.db.profile.messages.whisper.answer = val end,
                        get = function () return Addon.db.profile.messages.whisper.answer end,
                        width = Self.WIDTH_THIRD
                    },
                    whisperSuppress = {
                        name = L["OPT_WHISPER_SUPPRESS"],
                        desc = L["OPT_WHISPER_SUPPRESS_DESC"],
                        type = "toggle",
                        order = it(),
                        set = function (_, val) Addon.db.profile.messages.whisper.suppress = val end,
                        get = function () return Addon.db.profile.messages.whisper.suppress end,
                        width = Self.WIDTH_THIRD
                    },
                    whisperGroupType = {
                        name = L["OPT_WHISPER_GROUP_TYPE"],
                        desc = L["OPT_WHISPER_GROUP_TYPE_DESC"]:format(Util.GROUP_THRESHOLD*100, Util.GROUP_THRESHOLD*100),
                        type = "multiselect",
                        order = it(),
                        values = Self.groupValues,
                        set = function (_, key, val)
                            local c = Addon.db.profile.messages.whisper
                            c.groupType[Self.groupKeys[key]] = val
                            c.ask = Util.TblFind(c.groupType, true) and c.ask or false
                        end,
                        get = function (_, key) return Addon.db.profile.messages.whisper.groupType[Self.groupKeys[key]] end
                    },
                    whisperTarget = {
                        name = L["OPT_WHISPER_TARGET"],
                        desc = L["OPT_WHISPER_TARGET_DESC"],
                        type = "multiselect",
                        order = it(),
                        values = {
                            friend = FRIEND,
                            guild = GUILD,
                            community = COMMUNITIES,
                            other = OTHER
                        },
                        set = function (_, key, val)
                            local c = Addon.db.profile.messages.whisper
                            c.target[key] = val
                            c.ask = Util.TblFind(c.target, true) and c.ask or false
                        end,
                        get = function (_, key) return Addon.db.profile.messages.whisper.target[key] end
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
        c[lang][line] = not (Util.StrIsEmpty(val) or val == locale[line]) and val or nil
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
        desc = ("%s: %q%s"):format(DEFAULT, locale[iLine], Util.StrPrefix(L["OPT_" .. line .. "_DESC"], "\n\n"))
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
        "MSG_ROLL_START_MASTERLOOT",
        "MSG_ROLL_WINNER",
        "MSG_ROLL_WINNER_MASTERLOOT",
        "MSG_ROLL_DISENCHANT",
        "MSG_ROLL_DISENCHANT_MASTERLOOT",
        "OPT_WHISPER",
        "MSG_ROLL_WINNER_WHISPER",
        "MSG_ROLL_WINNER_WHISPER_MASTERLOOT",
        "MSG_ROLL_DISENCHANT_WHISPER",
        "MSG_ROLL_DISENCHANT_WHISPER_MASTERLOOT",
        "OPT_WHISPER_ASK",
        "MSG_BID",
        "OPT_WHISPER_ANSWER",
        "MSG_ROLL_ANSWER_BID",
        "MSG_ROLL_ANSWER_YES",
        "MSG_ROLL_ANSWER_YES_MASTERLOOT",
        "MSG_ROLL_ANSWER_NO_SELF",
        "MSG_ROLL_ANSWER_NO_OTHER",
        "MSG_ROLL_ANSWER_NOT_TRADABLE",
        "MSG_ROLL_ANSWER_AMBIGUOUS"
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
        .ExceptWhere("clubType", Enum.ClubType.Other).SortBy("clubType", nil, true)
        .SortBy("clubType", nil, true)()
    local clubValues = Util(clubs).Copy()
        .Map(function (info) return info.name .. (info.clubType == Enum.ClubType.Guild and " (" .. GUILD .. ")" or "") end)()
    Addon.db.char.masterloot.council.clubId = Addon.db.char.masterloot.council.clubId or clubs[1] and clubs[1].clubId

    -- This fixes the spacing bug with AceConfigDialog
    CD:ConfigTableChanged("ConfigTableChanged", Name .. " Masterloot")
    
    return {
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
                    Addon.db.char.masterloot.council.clubId = clubs[val].clubId
                    Session.RefreshRules()
                end,
                get = function ()
                    return Util.TblFindWhere(clubs, "clubId", Addon.db.char.masterloot.council.clubId)
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
                    if Self.CanWriteToClub(Addon.db.char.masterloot.council.clubId) then
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
                            if w[r] then t = wipe(w[r]) else t = Util.Tbl() w[r] = t end
                            for v in val:gmatch("[^%s%d%c,;:_<>|/\\]+") do t[v] = true end
                        end,
                        get = function ()
                            return Util(Addon.db.profile.masterloot.whitelists[GetRealmName()] or Util.TBL_EMPTY).Keys().Sort().Concat(", ")()
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
                        width = Self.WIDTH_HALF_SCROLL
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
                        width = Self.WIDTH_HALF_SCROLL
                    },
                    ["space" .. it()] = {type = "description", fontSize = "medium", order = it(0), name = " ", cmdHidden = true, dropdownHidden = true},
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
                                if #t < 9 and not Util.StrIsEmpty(v) then
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
                                if #t < 9 and not Util.StrIsEmpty(v) then
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
                        get = function () return Addon.db.profile.masterloot.rules.allowDisenchant end
                    },
                    disenchanter = {
                        name = L["OPT_MASTERLOOT_RULES_DISENCHANTER"],
                        desc = L["OPT_MASTERLOOT_RULES_DISENCHANTER_DESC"],
                        type = "input",
                        order = it(),
                        set = function (_, val)
                            local r, w, t = GetRealmName(), Addon.db.profile.masterloot.rules.disenchanter
                            if w[r] then t = wipe(w[r]) else t = Util.Tbl() w[r] = t end
                            for v in val:gmatch("[^%s%d%c,;:_<>|/\\]+") do t[v] = true end
                        end,
                        get = function ()
                            return Util(Addon.db.profile.masterloot.rules.disenchanter[GetRealmName()] or Util.TBL_EMPTY).Keys().Sort().Concat(", ")()
                        end,
                        width = Self.WIDTH_FULL
                    },
                    ["space" .. it()] = {type = "description", fontSize = "medium", order = it(0), name = " ", cmdHidden = true, dropdownHidden = true},
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
                            return Util.GetClubRanks(Addon.db.char.masterloot.council.clubId)
                        end,
                        set = function (_, key, val)
                            local clubId = Addon.db.char.masterloot.council.clubId
                            Util.TblSet(Addon.db.profile.masterloot.council.clubs, clubId, "ranks", key, val)
                            Session.RefreshRules()
                        end,
                        get = function (_, key)
                            local clubId = Addon.db.char.masterloot.council.clubId
                            return Util.TblGet(Addon.db.profile.masterloot.council.clubs, clubId, "ranks", key)
                        end
                    },
                    whitelist = {
                        name = L["OPT_MASTERLOOT_COUNCIL_WHITELIST"],
                        desc = L["OPT_MASTERLOOT_COUNCIL_WHITELIST_DESC"],
                        type = "input",
                        order = it(),
                        set = function (_, val)
                            local r, w, t = GetRealmName(), Addon.db.profile.masterloot.council.whitelists
                            if w[r] then t = wipe(w[r]) else t = Util.Tbl() w[r] = t end
                            for v in val:gmatch("[^%s%d%c,;:_<>|/\\]+") do t[v] = true end
                            Session.RefreshRules()
                        end,
                        get = function ()
                            return Util(Addon.db.profile.masterloot.council.whitelists[GetRealmName()] or Util.TBL_EMPTY).Keys().Sort().Concat(", ")()
                        end,
                        width = Self.WIDTH_FULL
                    }
                }
            }
        }
    }
end

function Self.ImportRules()
    local clubId = Addon.db.char.masterloot.council.clubId
    local c = Addon.db.profile.masterloot
    local s = Self.ReadFromClub(clubId)

    -- Rules
    for i in pairs(c.rules) do
        if i ~= "disenchanter" then
            c.rules[i] = Util.Default(s[i], Addon.db.defaults.profile.masterloot.rules[i])
        end
    end

    c.rules.disenchanter[GetRealmName()] = Util.TblIsFilled(s.disenchanter) and Util.TblFlip(s.disenchanter, true)

    -- Council
    local ranks = Util.GetClubRanks(clubId)
    Util.TblSet(c.council.clubs, clubId, "ranks", Util(s.councilRanks or Util.TBL_EMPTY).Map(function (v)
        return tonumber(v) or Util.TblFind(ranks, v)
    end).Flip(true)())

    c.council.roles = Util.TblFlip(s.councilRoles or Util.TBL_EMPTY, true)
    c.council.whitelists[GetRealmName()] = Util.TblIsFilled(s.councilWhitelist) and Util.TblFlip(s.councilWhitelist, true)

    CR:NotifyChange(Name .. " Masterloot")
end

function Self.ExportRules()
    local clubId = Addon.db.char.masterloot.council.clubId
    local info = C_Club.GetClubInfo(clubId)
    local c = Addon.db.profile.masterloot
    local s = Util.Tbl()

    -- Rules
    for i,v in pairs(c.rules) do
        local d = Addon.db.defaults.profile.masterloot.rules[i]
        if i ~= "disenchanter" and v ~= d and not (type(v) == "table" and Util.TblEquals(v, d)) then
            s[i] = v
        end
    end

    local dis = Util.TblKeys(c.rules.disenchanter[GetRealmName()] or Util.TBL_EMPTY)
    if next(dis) then s.disenchanter = dis end

    -- Council
    local ranks = Util(Util.TblGet(c.council.clubs, clubId, "ranks") or Util.TBL_EMPTY).CopyOnly(true, true).Keys()()
    if next(ranks) then s.councilRanks = ranks end
    local roles = Util(c.council.roles).CopyOnly(true, true).Keys()()
    if next(roles) then s.councilRoles = roles end
    local wl = Util.TblKeys(c.council.whitelists[GetRealmName()] or Util.TBL_EMPTY)
    if next(wl) then s.councilWhitelist = wl end

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
function Self.ReadFromClub(clubId, key)
    local t, found = not key and Util.Tbl() or nil, false

    local info = C_Club.GetClubInfo(clubId)
    if info and not Util.StrIsEmpty(info.description) then
        for i,line in Util.Each(("\n"):split(info.description)) do
            local name, val = line:match("^PLR%-(.-): ?(.*)")
            if name then
                name = Util.StrToCamelCase(name)
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
function Self.WriteToClub(clubId, keyOrTbl, val)
    local isKey = type(keyOrTbl) ~= "table"

    local info = C_Club.GetClubInfo(clubId)
    if info then
        local desc, i, found = Util.StrSplit(info.description, "\n"), 1, Util.Tbl()

        -- Update or delete existing entries
        while desc[i] do
            local line = desc[i]

            local param = line:match("^PLR%-(.-):")
            if param then
                local name = Util.StrToCamelCase(param)
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
                tinsert(desc, found[Self.DIVIDER] + 1, ("PLR-%s: %s"):format(Util.StrFromCamelCase(name, "-", true), Self.EncodeParam(name, v)))
            end
        end

        local str = Util.TblConcat(desc, "\n")
        Util.TblRelease(desc, found)

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
function Self.DecodeParam(name, str)
    if Util.In(name, "bidPublic", "votePublic", "autoAward") then
        return Util.In(str:lower(), "true", "1", "yes")
    elseif Util.In(name, "timeoutBase", "timeoutPerItem", "autoAwardTimeout", "autoAwardTimeoutPerItem") then
        return tonumber(str)
    elseif Util.In(name, "needAnswers", "greedAnswers", "disenchanter", "councilRoles", "councilRanks", "councilWhitelist") then
        local val = Util.Tbl()
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
                if guildId and Util.TblGet(p, "masterlooter.council") then
                    if p.masterlooter.council.guildmaster then
                        Util.TblSet(p.masterloot.council.clubs, guildId, "ranks", 1, true)
                    end
                    if p.masterlooter.council.guildofficer then
                        Util.TblSet(p.masterloot.council.clubs, guildId, "ranks", 2, true)
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
        end
    end
    p.version = 7

    -- Factionrealm
    if f.version then
        if f.version < 4 then
            if Util.TblGet(f, "masterloot.whitelist") then
                for i in pairs(f.masterloot.whitelist) do
                    Util.TblSet(p.masterloot.whitelists, GetRealmName(), i, true)
                end
            end
            if Util.TblGet(f, "masterlooter.councilWhitelist") then
                for i in pairs(f.masterlooter.councilWhitelist) do
                    Util.TblSet(p.masterloot.council.whitelists, GetRealmName(), i, true)
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
                local guildRank = Util.TblGet(c, "masterloot.council.guildRank")
                if guildRank and guildRank > 0 then
                    Util.TblSet(p.masterloot.council.clubs, guildId, ranks, guildRank, true)
                end
                c.masterloot.council.clubId = guildId
            end
            c.masterloot.council.guildRank = nil
        end
    end
    c.version = 4
end

-- Migrate a single option
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