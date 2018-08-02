local Name, Addon = ...
local L = LibStub("AceLocale-3.0"):GetLocale(Name)
local C = LibStub("AceConfig-3.0")
local CD = LibStub("AceConfigDialog-3.0")
local LDB = LibStub("LibDataBroker-1.1")
local LDBIcon = LibStub("LibDBIcon-1.0")
local Comm, GUI, Inspect, Item, Locale, Session, Roll, Unit, Util = Addon.Comm, Addon.GUI, Addon.Inspect, Addon.Item, Addon.Locale, Addon.Session, Addon.Roll, Addon.Unit, Addon.Util
local Self = Addon.Options

Self.WIDTH_FULL = 3.4
Self.WIDTH_HALF = Self.WIDTH_FULL / 2
Self.WIDTH_THIRD = Self.WIDTH_FULL / 3
Self.WIDTH_QUARTER = Self.WIDTH_FULL / 4

Self.it = Util.Iter()
Self.registered = false
Self.frames = {}

Self.groupKeys = {"party", "lfd", "guild", "raid", "lfr", "community"}
Self.groupValues = {PARTY, LOOKING_FOR_DUNGEON_PVEFRAME, GUILD_GROUP, RAID, RAID_FINDER_PVEFRAME, L["COMMUNITY_GROUP"]}

Self.allowKeys = {"friend", "community", "guild", "raidleader", "raidassistant", "guildgroup"}
Self.allowValues = {FRIEND, L["COMMUNITY_MEMBER"], LFG_LIST_GUILD_MEMBER, L["RAID_LEADER"], L["RAID_ASSISTANT"], GUILD_GROUP}

Self.acceptKeys = {"friend", "guildmaster", "guildofficer"}
Self.acceptValues = {FRIEND, L["GUILD_MASTER"], L["GUILD_OFFICER"]}

Self.councilKeys = {"guildmaster", "guildofficer", "raidleader", "raidassistant"}
Self.councilValues = {L["GUILD_MASTER"], L["GUILD_OFFICER"], L["RAID_LEADER"], L["RAID_ASSISTANT"]}

-- Register options
function Self.Register()
    Self.registered = true

    Self.RegisterGeneral()
    Self.RegisterMessages()
    Self.RegisterRules()

    -- Profiles
    C:RegisterOptionsTable(Name .. " Profiles", LibStub("AceDBOptions-3.0"):GetOptionsTable(Addon.db))
    Self.frames["Profiles"] = CD:AddToBlizOptions(Name .. " Profiles", "Profiles", Name)
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

    C:RegisterOptionsTable(Name, {
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
            awardSelf = {
                name = L["OPT_AWARD_SELF"],
                desc = L["OPT_AWARD_SELF_DESC"],
                type = "toggle",
                order = it(),
                set = function (_, val) Addon.db.profile.awardSelf = val end,
                get = function () return Addon.db.profile.awardSelf end,
                width = Self.WIDTH_HALF
            },
            onlyMasterloot = {
                name = L["OPT_ONLY_MASTERLOOT"],
                desc = L["OPT_ONLY_MASTERLOOT_DESC"],
                type = "toggle",
                order = it(),
                set = function (_, val)
                    Addon.db.profile.onlyMasterloot = val
                    Addon:OnTrackingChanged(not val)
                end,
                get = function () return Addon.db.profile.onlyMasterloot end,
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
            dontShare = {
                name = L["OPT_DONT_SHARE"],
                desc = L["OPT_DONT_SHARE_DESC"],
                type = "toggle",
                order = it(),
                set = function (_, val) Addon.db.profile.dontShare = val end,
                get = function () return Addon.db.profile.dontShare end,
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
                width = "full"
            },
            showRollFrames = {
                name = L["OPT_ROLL_FRAMES"],
                desc = L["OPT_ROLL_FRAMES_DESC"],
                type = "toggle",
                order = it(),
                set = function (_, val) Addon.db.profile.ui.showRollFrames = val end,
                get = function (_) return Addon.db.profile.ui.showRollFrames end,
                width = "full"
            },
            showActionsWindow = {
                name = L["OPT_ACTIONS_WINDOW"],
                desc = L["OPT_ACTIONS_WINDOW_DESC"],
                type = "toggle",
                order = it(),
                set = function (_, val) Addon.db.profile.ui.showActionsWindow = val end,
                get = function (_) return Addon.db.profile.ui.showActionsWindow end
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
                set = function (_, val) Addon.db.profile.ui.showRollsWindow = val end,
                get = function (_) return Addon.db.profile.ui.showRollsWindow end,
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
                set = function (_, val) Addon.db.profile.ilvlThreshold = val end,
                get = function () return Addon.db.profile.ilvlThreshold end,
                width = Self.WIDTH_HALF
            },
            ilvlThresholdTrinkets = {
                name = L["OPT_ILVL_THRESHOLD_TRINKETS"],
                desc = L["OPT_ILVL_THRESHOLD_TRINKETS_DESC"],
                type = "toggle",
                order = it(),
                set = function (_, val) Addon.db.profile.ilvlThresholdTrinkets = val end,
                get = function () return Addon.db.profile.ilvlThresholdTrinkets end,
                width = Self.WIDTH_HALF
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
            transmog = {
                name = L["OPT_TRANSMOG"],
                desc = L["OPT_TRANSMOG_DESC"],
                type = "toggle",
                order = it(),
                set = function (_, val) Addon.db.profile.transmog = val end,
                get = function () return Addon.db.profile.transmog end,
                width = "full"
            }
        }
    })
    Self.frames["General"] = CD:AddToBlizOptions(Name)
end

-------------------------------------------------------
--                     Messages                      --
-------------------------------------------------------

function Self.RegisterMessages()
    local it = Self.it
    local lang = Locale.GetRealmLanguage()

    it(1, true)
    C:RegisterOptionsTable(Name .. " Messages", {
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
                        width = "full"
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
                        width = "full"
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
    })
    Self.frames["Messages"] = CD:AddToBlizOptions(Name .. " Messages", L["OPT_MESSAGES"], Name)
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
            width = "full"
        }
    end

    for _,line in Util.Each(
        "MSG_ROLL_START",
        "MSG_ROLL_START_MASTERLOOT",
        "MSG_ROLL_WINNER",
        "MSG_ROLL_WINNER_MASTERLOOT",
        "OPT_WHISPER",
        "MSG_ROLL_WINNER_WHISPER",
        "MSG_ROLL_WINNER_WHISPER_MASTERLOOT",
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
            for i=1,5 do add(line, i) end
        else
            add(line)
        end
    end

    return t
end

-------------------------------------------------------
--                      Rules                        --
-------------------------------------------------------

function Self.RegisterRules()
    local it = Self.it
    
    local guild = Util.TblFirstWhere(C_Club.GetSubscribedClubs(), "clubType", Enum.ClubType.Guild)
    local canSave = guild and C_Club.GetClubPrivileges(guild.clubId).canSetDescription
    
    local options = {
        name = L["OPT_MASTERLOOT"],
        type = "group",
        childGroups = "tab",
        args = {
            desc = {type = "description", fontSize = "medium", order = it(), name = L["OPT_MASTERLOOT_DESC"] .. "\n"},
            save = {
                name = L["OPT_MASTERLOOT_SAVE"],
                desc = L["OPT_MASTERLOOT_SAVE_DESC"],
                type = "execute",
                order = it(),
                func = function ()
                    print("saving") -- TODO
                end,
                hidden = not guild,
                disabled = not canSave
            },
            load = {
                name = L["OPT_MASTERLOOT_LOAD"],
                desc = L["OPT_MASTERLOOT_LOAD_DESC"],
                type = "execute",
                order = it(),
                func = function ()
                    print("loading") -- TODO
                end,
                hidden = not guild
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
                            local t = wipe(Addon.db.factionrealm.masterloot.whitelist)
                            for v in val:gmatch("[^%s%d%c,;:_<>|/\\]+") do
                                t[v] = true
                            end
                        end,
                        get = function () return Util(Addon.db.factionrealm.masterloot.whitelist).Keys().Sort().Concat(", ")() end,
                        width = "full"
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
                        width = "full"
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
                        max = 120,
                        step = 5,
                        set = function (_, val)
                            Addon.db.profile.masterlooter.timeoutBase = val
                            Session.Refresh()
                        end,
                        get = function () return Addon.db.profile.masterlooter.timeoutBase end,
                        width = Self.WIDTH_HALF
                    },
                    timeoutPerItem = {
                        name = L["OPT_MASTERLOOT_RULES_TIMEOUT_PER_ITEM"],
                        desc = L["OPT_MASTERLOOT_RULES_TIMEOUT_PER_ITEM_DESC"],
                        type = "range",
                        order = it(),
                        min = 0,
                        max = 30,
                        step = 1,
                        set = function (_, val)
                            Addon.db.profile.masterlooter.timeoutPerItem = val
                            Session.Refresh()
                        end,
                        get = function () return Addon.db.profile.masterlooter.timeoutPerItem end,
                        width = Self.WIDTH_HALF
                    },
                    ["space" .. it()] = {type = "description", fontSize = "medium", order = it(0), name = " ", cmdHidden = true, dropdownHidden = true},
                    needAnswers = {
                        name = L["OPT_MASTERLOOT_RULES_NEED_ANSWERS"],
                        desc = L["OPT_MASTERLOOT_RULES_NEED_ANSWERS_DESC"]:format(NEED),
                        type = "input",
                        order = it(),
                        set = function (_, val)
                            local t = wipe(Addon.db.profile.masterlooter.answers1)
                            for v in val:gmatch("[^,]+") do
                                v = v:gsub("^%s*(.*)%s*$", "%1")
                                if #t < 9 and not Util.StrIsEmpty(v) then
                                    tinsert(t, v == NEED and Roll.ANSWER_NEED or v)
                                end
                            end
                            Session.Refresh()
                        end,
                        get = function ()
                            local s = ""
                            for i,v in pairs(Addon.db.profile.masterlooter.answers1) do
                                s = s .. (i > 1 and ", " or "") .. (v == Roll.ANSWER_NEED and NEED or v)
                            end
                            return s
                        end,
                        width = "full"
                    },
                    greedAnswers = {
                        name = L["OPT_MASTERLOOT_RULES_GREED_ANSWERS"],
                        desc = L["OPT_MASTERLOOT_RULES_GREED_ANSWERS_DESC"]:format(GREED),
                        type = "input",
                        order = it(),
                        set = function (_, val)
                            local t = wipe(Addon.db.profile.masterlooter.answers2)
                            for v in val:gmatch("[^,]+") do
                                v = v:gsub("^%s*(.*)%s*$", "%1")
                                if #t < 9 and not Util.StrIsEmpty(v) then
                                    tinsert(t, v == GREED and Roll.ANSWER_GREED or v)
                                end
                            end
                            Session.Refresh()
                        end,
                        get = function ()
                            local s = ""
                            for i,v in pairs(Addon.db.profile.masterlooter.answers2) do
                                s = s .. (i > 1 and ", " or "") .. (v == Roll.ANSWER_GREED and GREED or v)
                            end
                            return s
                        end,
                        width = "full"
                    },
                    ["space" .. it()] = {type = "description", fontSize = "medium", order = it(0), name = " ", cmdHidden = true, dropdownHidden = true},
                    bidPublic = {
                        name = L["OPT_MASTERLOOT_RULES_BID_PUBLIC"],
                        desc = L["OPT_MASTERLOOT_RULES_BID_PUBLIC_DESC"] .. "\n",
                        type = "toggle",
                        order = it(),
                        set = function (_, val)
                            Addon.db.profile.masterlooter.bidPublic = val
                            Session.Refresh()
                        end,
                        get = function () return Addon.db.profile.masterlooter.bidPublic end,
                        width = "full"
                    },
                    autoAward = {
                        name = L["OPT_MASTERLOOT_RULES_AUTO_AWARD"],
                        desc = L["OPT_MASTERLOOT_RULES_AUTO_AWARD_DESC"],
                        type = "toggle",
                        order = it(),
                        set = function (_, val) Addon.db.profile.masterlooter.autoAward = val end,
                        get = function () return Addon.db.profile.masterlooter.autoAward end,
                        width = "full"
                    },
                    autoAwardVoteTimeout = {
                        name = L["OPT_MASTERLOOT_RULES_AUTO_AWARD_TIMEOUT"],
                        desc = L["OPT_MASTERLOOT_RULES_AUTO_AWARD_TIMEOUT_DESC"],
                        type = "range",
                        order = it(),
                        min = 5,
                        max = 120,
                        step = 5,
                        set = function (_, val) Addon.db.profile.masterlooter.autoAwardTimeout = val end,
                        get = function () return Addon.db.profile.masterlooter.autoAwardTimeout end,
                        width = Self.WIDTH_HALF
                    },
                    autoAwardVoteTimeoutPerItem = {
                        name = L["OPT_MASTERLOOT_RULES_AUTO_AWARD_TIMEOUT_PER_ITEM"],
                        desc = L["OPT_MASTERLOOT_RULES_AUTO_AWARD_TIMEOUT_PER_ITEM_DESC"],
                        type = "range",
                        order = it(),
                        min = 0,
                        max = 30,
                        step = 1,
                        set = function (_, val) Addon.db.profile.masterlooter.autoAwardTimeoutPerItem = val end,
                        get = function () return Addon.db.profile.masterlooter.autoAwardTimeoutPerItem end,
                        width = Self.WIDTH_HALF
                    },
                }
            },
            council = {
                name = L["OPT_MASTERLOOT_COUNCIL"],
                type = "group",
                order = it(),
                args = {
                    desc = {type = "description", fontSize = "medium", order = it(), name = L["OPT_MASTERLOOT_COUNCIL_DESC"] .. "\n"},
                    allow = {
                        name = L["OPT_MASTERLOOT_COUNCIL_ALLOW"],
                        desc = L["OPT_MASTERLOOT_COUNCIL_ALLOW_DESC"],
                        type = "multiselect",
                        order = it(),
                        values = Self.councilValues,
                        set = function (_, key, val)
                            Addon.db.profile.masterlooter.council[Self.councilKeys[key]] = val
                            Session.Refresh()
                        end,
                        get = function (_, key) return Addon.db.profile.masterlooter.council[Self.councilKeys[key]] end
                    },
                    guildRank = {
                        name = L["OPT_MASTERLOOT_COUNCIL_GUILD_RANK"],
                        desc = L["OPT_MASTERLOOT_COUNCIL_GUILD_RANK_DESC"],
                        type = "select",
                        order = it(),
                        values = function ()
                            if not Self.guildRanks then
                                Self.guildRanks = Util.GetGuildRanks()
                                Self.guildRanks[0], Self.guildRanks[1], Self.guildRanks[2] = "(" .. NONE .. ")", nil, nil
                            end
                            return Self.guildRanks
                        end,
                        set = function (_, val)
                            Addon.db.char.masterloot.guildRank = val
                            Session.Refresh()
                        end,
                        get = function () return Addon.db.char.masterloot.guildRank end
                    },
                    guildRankUp = {
                        name = L["OPT_MASTERLOOT_COUNCIL_GUILD_RANK_UP"],
                        desc = L["OPT_MASTERLOOT_COUNCIL_GUILD_RANK_UP_DESC"],
                        type = "toggle",
                        order = it(),
                        set = function (_, val) Addon.db.char.masterloot.guildRankUp = val end,
                        get = function () return Addon.db.char.masterloot.guildRankUp end,
                    },
                    whitelist = {
                        name = L["OPT_MASTERLOOT_COUNCIL_WHITELIST"],
                        desc = L["OPT_MASTERLOOT_COUNCIL_WHITELIST_DESC"],
                        type = "input",
                        order = it(),
                        set = function (_, val)
                            local t = wipe(Addon.db.factionrealm.masterlooter.councilWhitelist)
                            for v in val:gmatch("[^%s%d%c,;:_<>|/\\]+") do
                                t[v] = true
                            end
                            Session.Refresh()
                        end,
                        get = function () return Util(Addon.db.factionrealm.masterlooter.councilWhitelist).Keys().Sort().Concat(", ")() end,
                        width = "full"
                    },
                    ["space" .. it()] = {type = "description", fontSize = "medium", order = it(0), name = " ", cmdHidden = true, dropdownHidden = true},
                    votePublic = {
                        name = L["OPT_MASTERLOOT_COUNCIL_VOTE_PUBLIC"],
                        desc = L["OPT_MASTERLOOT_COUNCIL_VOTE_PUBLIC_DESC"],
                        type = "toggle",
                        order = it(),
                        set = function (_, val)
                            Addon.db.profile.masterlooter.votePublic = val
                            Session.Refresh()
                        end,
                        get = function () return Addon.db.profile.masterlooter.votePublic end,
                        width = "full"
                    }
                }
            }
        }
    }

    C:RegisterOptionsTable(Name .. " Masterloot", options)
    Self.frames["Rules"] = CD:AddToBlizOptions(Name .. " Masterloot", L["OPT_MASTERLOOT"], Name)
end

-------------------------------------------------------
--                    Migration                      --
-------------------------------------------------------

-- Migrate options from an older version to the current one
function Self.Migrate()
    -- Profile
    local c = Addon.db.profile
    if c.version then
        if c.version < 5 then
            Self.MigrateOption("echo", c, c.messages)
            Self.MigrateOption("announce", c, c.messages.group, true, "groupType")
            Self.MigrateOption("roll", c, c.messages.group)
            c.messages.whisper.ask = true
            Self.MigrateOption("answer", c, c.messages.whisper)
            Self.MigrateOption("suppress", c, c.messages.whisper)
            Self.MigrateOption("group", c.whisper, c.messages.whisper, true, "groupType")
            Self.MigrateOption("target", c.whisper, c.messages.whisper, true)
            c.whisper = nil
            Self.MigrateOption("messages", c, c.messages, true, "lines", "^%l%l%u%u$", true)
        end
        if c.version < 6 then
            c.messages.group.groupType.community = c.messages.group.groupType.guild
            c.messages.whisper.groupType.community = c.messages.whisper.groupType.guild
            c.messages.whisper.target.community = c.messages.whisper.target.guild
        end
    end
    c.version = 6

    -- Factionrealm
    local c = Addon.db.factionrealm
    c.version = 3
    
    -- Char
    local c = Addon.db.char
    c.version = 3
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