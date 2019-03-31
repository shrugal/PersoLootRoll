local Name, Addon = ...
local L = LibStub("AceLocale-3.0"):GetLocale(Name)
local RI = LibStub("LibRealmInfo")
local CB = LibStub("CallbackHandler-1.0")
local Comm, GUI, Inspect, Item, Options, Session, Roll, Trade, Unit, Util = Addon.Comm, Addon.GUI, Addon.Inspect, Addon.Item, Addon.Options, Addon.Session, Addon.Roll, Addon.Trade, Addon.Unit, Addon.Util
local Self = Addon

-- Logging
Self.ECHO_NONE = 0
Self.ECHO_ERROR = 1
Self.ECHO_INFO = 2
Self.ECHO_VERBOSE = 3
Self.ECHO_DEBUG = 4
Self.ECHO_LEVELS = {"ERROR", "INFO", "VERBOSE", "DEBUG"}

Self.LOG_MAX_ENTRIES = 1000
Self.LOG_MAX_ERRORS = 10

Self.log = {}
Self.errors = 0

-- Versioning
Self.CHANNEL_ALPHA = "alpha"
Self.CHANNEL_BETA = "beta"
Self.CHANNEL_STABLE = "stable"
Self.CHANNELS = Util.TblFlip({Self.CHANNEL_ALPHA, Self.CHANNEL_BETA, Self.CHANNEL_STABLE})

Self.versions = {}
Self.versionNoticeShown = false
Self.disabled = {}
Self.compAddonUsers = {}

-- State
Self.STATE_DISABLED = 0 -- Disabled in settings
Self.STATE_ENABLED = 1  -- Enabled but not in a group
Self.STATE_ACTIVE = 2   -- In a group but not tracking loot because of constraints from settings (e.g. "only masterloot" enabled and no masterlooter)
Self.STATE_TRACKING = 3 -- Actively tracking loot
Self.STATES = {"ENABLED", "ACTIVE", "TRACKING"}

Self.state = nil

-- Events

--- Fired when the addon state changes
-- @int toState The new state
-- @int fromState The previous state
Self.EVENT_STATE_CHANGE = "PLR_STATE_CHANGE"

--- Fired when the addon is enabled or disabled
-- @bool enabled Whether the addon is enabled
Self.EVENT_ENABLED_CHANGE = "PLR_STATE_ENABLED_CHANGE"

--- Fired when the addon is (de)activated
-- @bool active Whether the addon is active
Self.EVENT_ACTIVE_CHANGE = "PLR_STATE_ACTIVE_CHANGE"

--- Fired when the addon starts/stops loot tracking
-- @bool tracking Whether the addon is tracking
Self.EVENT_TRACKING_CHANGE = "PLR_STATE_TRACKING_CHANGE"

-- Other
Self.rolls = Util.TblCounter()
Self.timers = {}

-------------------------------------------------------
--                    Addon stuff                    --
-------------------------------------------------------

-- Called when the addon is loaded
function Self:OnInitialize()
    -- Debug info
    self:ToggleDebug(PersoLootRollDebug or self.DEBUG)
    self:RegisterErrorHandler()
    
    -- Load DB
    self.db = LibStub("AceDB-3.0"):New(Name .. "DB", Self.Options.DEFAULTS, true)

    -- Set enabled state
    self:SetEnabledState(self.db.profile.enabled)

    -- Migrate and register options
    Options.Migrate()
    Options.Register()
    Options.RegisterMinimapIcon()

    -- Register chat commands
    self:RegisterChatCommand(Name, "HandleChatCommand")
    self:RegisterChatCommand("plr", "HandleChatCommand")
end

-- Called when the addon is enabled
function Self:OnEnable()
    -- Enable hooks and events
    self:EnableHooks()
    self:RegisterEvents()

    -- Periodically clear old rolls
    self.timers.clearRolls = self:ScheduleRepeatingTimer(Roll.Clear, Roll.CLEAR)

    -- Update state
    self:CheckState(true)

    -- IsInGroup doesn't work correctly right after logging in, so check again a few seconds later
    if not self:IsActive() then
        self:ScheduleTimer(Self.CheckState, 10, self, true)
    end
end

function Self:OnDisable()
    -- Disable hooks and events
    self:UnregisterEvents()
    self:DisableHooks()
    
    -- Chancel timers
    self:CancelTimer(self.timers.clearRolls)

    -- Update state
    self:CheckState(true)
end

function Self:ToggleDebug(debug)
    if debug ~= nil then
        self.DEBUG = debug
    else
        self.DEBUG = not self.DEBUG
    end

    PersoLootRollDebug = self.DEBUG

    if self.DEBUG or self.db then
        self:Info("Debugging " .. (self.DEBUG and "en" or "dis") .. "abled")
    end
end

-------------------------------------------------------
--                   Chat command                    --
-------------------------------------------------------

-- Chat command handling
function Self:HandleChatCommand(msg)
    local args = Util.Tbl(Self:GetArgs(msg, 10))
    args[11] = nil
    local cmd = tremove(args, 1)

    -- Help
    if cmd == "help" then
        self:Help()
    -- Options
    elseif cmd == "options" then
        Options.Show()
    -- Config
    elseif cmd == "config" then
        local name, pre, line = Name, "plr config", msg:sub(cmd:len() + 2)

        -- Handle submenus
        local subs = Util.Tbl("messages", "masterloot", "profiles")
        if Util.In(args[1], subs) then
            name, pre, line = name .. " " .. Util.StrUcFirst(args[1]), pre .. " " .. args[1], line:sub(args[1]:len() + 2)
        end

        LibStub("AceConfigCmd-3.0").HandleCommand(Self, pre, name, line)

        -- Add submenus as additional options
        if Util.StrIsEmpty(args[1]) then
            for i,v in pairs(subs) do
                local name = Util.StrUcFirst(v)
                local getter = LibStub("AceConfigRegistry-3.0"):GetOptionsTable(Name .. " " .. name)
                print("  |cffffff78" .. v .. "|r - " .. (getter("cmd", "AceConfigCmd-3.0").name or name))
            end
        end

        Util.TblRelease(subs)
    -- Roll
    elseif cmd == "roll" then
        local ml, isML, items, itemOwner, timeout = Session.GetMasterlooter(), Session.IsMasterlooter(), Util.Tbl(), "player"

        for i,v in pairs(args) do
            if tonumber(v) then
                timeout = tonumber(v)
            elseif Item.IsLink(v) then
                tinsert(items, v)
            else
                itemOwner = v
            end
        end

        if not UnitExists(itemOwner) then
            self:Error(L["ERROR_PLAYER_NOT_FOUND"], itemOwner)
        elseif not Unit.IsSelf(itemOwner) and not isML then
            self:Error(L["ERROR_NOT_MASTERLOOTER_OTHER_OWNER"])
        elseif timeout and ml and not isML then
            self:Error(L["ERROR_NOT_MASTERLOOTER_TIMEOUT"])
        elseif not next(items) then
            self:Error(L["USAGE_ROLL"])
        else
            local ml = Session.GetMasterlooter()

            for i,item in pairs(items) do
                item = Item.FromLink(item, itemOwner)
                local roll = Roll.Add(item, ml or "player", nil, nil, timeout)

                if roll.isOwner then
                    roll:Start()
                else
                    roll:SendStatus(true)
                end
            end
        end
    -- Bid
    elseif cmd == "bid" then
        local item, owner, bid = unpack(args)

        -- Determine bid
        if Util.In(bid, NEED, "Need", "need", "100") then
            bid = Roll.BID_NEED
        elseif Util.In(bid, GREED, "Greed", "greed", "50") then
            bid = Roll.BID_GREED
        elseif Session.GetMasterlooter() then
            for i=1,2 do
                if Util.In(bid, Session.rules["answers" .. i]) then
                    bid = i + Util.TblFind(Session.rules["answers" .. i], bid) / 10
                end
            end
        end

        bid = bid or Roll.BID_NEED
        owner = Unit.Name(owner or "player")
        
        if not Item.IsLink(item) or Item.IsLink(owner) or not tonumber(bid) then
            self:Print(L["USAGE_BID"])
        elseif not UnitExists(owner) then
            self:Error(L["ERROR_PLAYER_NOT_FOUND"], args[2])
        else
            local roll = (Roll.Find(nil, owner, item) or Roll.Add(item, owner))
    
            if self.db.profile.messages.echo < Self.ECHO_VERBOSE then
                self:Info(L["BID_START"], roll:GetBidName(bid), item, Comm.GetPlayerLink(owner))
            end
            
            roll:Bid(bid or Roll.BID_NEED)
        end
    -- Trade
    elseif cmd == "trade" then
        Trade.Initiate(args[1] or "target")
    -- Create a test roll
    elseif cmd == "test" then
        Roll.Test()
    -- Rolls/None
    elseif cmd == "rolls" or not cmd then
        GUI.Rolls.Show()
    -- Toggle debug mode
    elseif cmd == "debug" then
        self:ToggleDebug()
    -- Export debug log
    elseif cmd == "log" then
        self:LogExport()
    -- Update and export trinket list
    elseif cmd == "trinkets" then
        Item.UpdateTrinkets()
    -- Update and export instance list
    elseif cmd == "instances" then
        Util.ExportInstances()
    -- Unknown
    else
        self:Error(L["ERROR_CMD_UNKNOWN"], cmd)
    end
end

function Self:Help()
    for i,v in Util.Each(("\n"):split(L["HELP"])) do
        if i == 1 then
            self:Print(v)
        else
            DEFAULT_CHAT_FRAME:AddMessage((v:gsub("(/[^:]+):", "|cffbbbbbb%1|r:")))
        end
    end
end

-------------------------------------------------------
--                       State                       --
-------------------------------------------------------

-- Get (and optionally refresh) the current addon state
function Self:CheckState(refresh)
    if self.state == nil or refresh then
        local state = self.state or Self.STATE_DISABLED
        local group, p = self.db.profile.activeGroups, Util.Push

        if not self.db.profile.enabled then
            self.state = Self.STATE_DISABLED
        elseif not IsInGroup() then
            self.state = Self.STATE_ENABLED
        elseif not (
            (not self.db.profile.onlyMasterloot or Session.GetMasterlooter())
            and Util.In(GetLootMethod(), "freeforall", "roundrobin", "personalloot", "group")
            and (
                IsInRaid(LE_PARTY_CATEGORY_INSTANCE)                 and p(group.lfr)
                or IsInGroup(LE_PARTY_CATEGORY_INSTANCE)             and p(group.lfd)
                or Util.IsGuildGroup(Unit.GuildName("player") or "") and p(group.guild)
                or Util.IsCommunityGroup()                           and p(group.community)
                or IsInRaid()                                        and p(group.raid)
                or p(group.party)
            ).Pop()
        ) then 
            self.state = Self.STATE_ACTIVE
        else
            self.state = Self.STATE_TRACKING
        end

        if self.state ~= state then
            Self:SendMessage(Self.STATE_CHANGE, to, from)

            local cmp = Util.Compare(self.state, state)

            for i=max(state, state+cmp), max(self.state, self.state-cmp), cmp do
                local s = Self.STATES[i]
                local fn = Self["On" .. Util.StrUcFirst(s:lower()) .. "Changed"]

                if fn then fn(Self, self.state >= i) end
                Self:SendMessage("STATE_" .. s .. "_CHANGE", self.state >= i)
            end
        end
    end

    return self.state
end

-- Check if the addon is currently active
function Self:IsActive(refresh)
    return Self:CheckState(refresh) >= Self.STATE_ACTIVE
end

-- Check if the addon is currently tracking loot etc.
function Self:IsTracking(refresh)
    return Self:CheckState(refresh) >= Self.STATE_TRACKING
end

-- Active state changed
function Self:OnActiveChanged(active)
    if active then
        -- Schedule version check
        if not Self.timers.versionCheck then
            Self.timers.versionCheck = Self:ScheduleTimer(Comm.SendData, Self.VERSION_CHECK_DELAY, Comm.EVENT_CHECK)
        end
    else
        -- Clear roll data
        Util.TblIter(self.rolls, Roll.Clear)

        -- Clear versions and disabled
        wipe(Self.versions)
        wipe(Self.disabled)
        wipe(Self.compAddonUsers)
    
        -- Clear lastXYZ stuff
        Self.lastPostedRoll = nil
        Self.lastVersionCheck = nil
        Self.lastSuppressed = nil
        wipe(Self.lastWhispered)
        wipe(Self.lastWhisperedRoll)
    end
end

-- Tracking state changed
function Self:OnTrackingChanged(tracking)
    Comm.Send(Comm["EVENT_" .. (tracking and "ENABLE" or "DISABLE")])

    if tracking then
        Comm.Send(Comm.EVENT_SYNC)
    end
end
Self.OnTrackingChanged = Util.FnDebounce(Self.OnTrackingChanged, 0.1)

-- Check if the given unit is tracking
function Self:UnitIsTracking(unit, inclCompAddons)
    if Unit.IsSelf(unit or "player") then
        return self:IsTracking()
    else
        unit = Unit.Name(unit)
        return self.versions[unit] and not self.disabled[unit] or inclCompAddons and self:GetCompAddonUser(unit)
    end
end

-------------------------------------------------------
--                    Versioning                     --
-------------------------------------------------------

-- Set a unit's version string
function Self:SetVersion(unit, version)
    version = tonumber(version) or version

    self.versions[unit] = version
    for _,t in pairs(self.compAddonUsers) do
        t[unit] = nil
    end

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
-- TODO: Automatically set TOC version to tag or revision starting with in v19
function Self:GetVersion(versionOrUnit)
    local version = (not versionOrUnit or Unit.IsSelf(versionOrUnit)) and self.VERSION
        or type(versionOrUnit) == "string" and self.versions[Unit.Name(versionOrUnit)]
        or versionOrUnit

    local n = tonumber(version)
    if n then
        return floor(n), Self.CHANNEL_STABLE, Util.NumRound((n - floor(n)) * 100), 0
    elseif type(version) == "string" then
        local major, channel, minor, revision = version:match("([%d%.]+)-(%a+)(%d+)-?(%d*)")
        if major and channel and minor then
            return tonumber(major), channel, tonumber(minor), tonumber(revision) or 0
        end
    end

    return version, Self.CHANNEL_ALPHA
end

-- Get 1 if the version is higher, -1 if the version is lower or 0 if they are the same or not comparable
function Self:CompareVersion(versionOrUnit)
    local major, channel, minor, revision = self:GetVersion(versionOrUnit)
    local majorSelf, channelSelf, minorSelf, myRevision = self:GetVersion()
    local channelNum, channelNumSelf = Self.CHANNELS[channel], Self.CHANNELS[channelSelf]

    if minor and minorSelf then
        if channel == channelSelf then
            return Util.Compare(
                4 * Util.Compare(major, myMajor) +
                2 * Util.Compare(minor, myMinor) +
                1 * Util.Compare(revision, myRevision),
                0
            )
        elseif channelNum and channelNumSelf then
            return major >= majorSelf and channelNum > channelNumSelf and 1
                or major <= majorSelf and channelNum < channelNumSelf and -1
                or 0
        end
    end

    return 0
end

function Self:SetCompAddonUser(unit, addon, version)
    unit = Unit.Name(unit)
    if not self.versions[unit] then
        Util.TblSet(self.compAddonUsers, addon, unit, version)
    end
end

function Self:GetCompAddonUser(unit, addon)
    unit = Unit.Name(unit)
    if addon then
        return Util.TblGet(Addon.compAddonUsers, addon, unit)
    else
        return Util.TblFindWhere(Addon.compAddonUsers, unit)
    end
end

-- Get the number of addon users in the group
function Self:GetNumAddonUsers(inclCompAddons)
    local n = Util.TblCount(self.versions) - Util.TblCount(self.disabled)

    if inclCompAddons then
        local users = Util.Tbl()
        for _,t in pairs(self.compAddonUsers) do
            for unit in pairs(t) do
                if not self.versions[unit] then
                    users[unit] = true
                end
            end
        end
        n = n + Util.TblCount(users)
        Util.TblRelease(users)
    end

    return n
end

-------------------------------------------------------
--                      Logging                      --
-------------------------------------------------------

-- Write to log and print if lvl is high enough
function Addon:Echo(lvl, line, ...)
    if lvl == self.ECHO_DEBUG then
        for i=1, select("#", ...) do
            line = line .. (i == 1 and " - " or ", ") .. Util.ToString((select(i, ...)))
        end
    else
        line = line:format(...)
    end

    self:Log(lvl, line)

    if not self.db or self.db.profile.messages.echo >= lvl then
        self:Print(line)
    end
end

-- Shortcuts for different log levels
function Self:Error(...) self:Echo(self.ECHO_ERROR, ...) end
function Self:Info(...) self:Echo(self.ECHO_INFO, ...) end
function Self:Verbose(...) self:Echo(self.ECHO_VERBOSE, ...) end
function Self:Debug(...) self:Echo(self.ECHO_DEBUG, ...) end

-- Add an entry to the debug log
function Self:Log(lvl, line)
    tinsert(self.log, ("[%.1f] %s: %s"):format(GetTime(), self.ECHO_LEVELS[lvl or self.ECHO_INFO], line or "-"))
    while #self.log > self.LOG_MAX_ENTRIES do
        Util.TblShift(self.log)
    end
end

-- Export the debug log
function Self:LogExport()
    local realm = GetRealmName()
    local _, name, _, _, lang, _, region = RI:GetRealmInfo(realm)    
    local txt = ("~ PersoLootRoll ~ Version: %s ~ Date: %s ~ Locale: %s ~ Realm: %s-%s (%s) ~"):format(self.VERSION or "?", date() or "?", GetLocale() or "?", region or "?", name or realm or "?", lang or "?")
    txt = txt .. "\n" .. Util.TblConcat(self.log, "\n")

    GUI.ShowExportWindow("Export log", txt)
end

-------------------------------------------------------
--                   Error handling                  --
-------------------------------------------------------

-- Register our error handler
function Self:RegisterErrorHandler()
    local s = function (s) return strtrim(tostring(s), "\n") end

    if BugGrabber and BugGrabber.RegisterCallback then
        BugGrabber.RegisterCallback(self, "BugGrabber_BugGrabbed", function (_, err)
            if Self.errors < Self.LOG_MAX_ERRORS then
                self:HandleError(s(err.message), s(err.stack), s(err.locals ~= "InCombatSkipped" and err.locals or ""))
            end
        end)
    else
        local origHandler = geterrorhandler()
        seterrorhandler(function (msg, simple, ...)
            if Self.errors < Self.LOG_MAX_ERRORS then
                local stack = not simple and debugstack(3) or ""
                local locals = not (simple or InCombatLockdown() or UnitAffectingCombat("player")) and debuglocals(3) or ""

                self:HandleError(s(msg), s(stack), s(locals))
            end

            return origHandler and origHandler(msg, simple, ...) or nil
        end)
    end
end

-- Check for PLR errors and log them
function Self:HandleError(msg, stack, locals)
    msg = "\"" .. msg:gsub("^Interface\\", ""):gsub("^AddOns\\", "") .. "\""
    stack = stack and ("\n" .. stack):gsub("\nInterface\\", "\n"):gsub("\nAddOns\\", "\n") or ""
    local txt = msg .. stack

    for v in txt:gmatch(Name .. "\\([^\\]+)") do
        if v ~= "Libs" then
            Self.errors = Self.errors + 1

            self:Log(Self.ECHO_ERROR, txt)

            if Self.errors == 1 and (not self.db or self.db.profile.messages.echo >= Self.ECHO_ERROR) then
                self:Print("|cffff0000[ERROR]|r " .. msg .. "\n\nPlease type in |cffbbbbbb/plr log|r, create a new ticket on Curse, WoWInterface or GitHub, copy & paste the log in there and add any additional info you might have. Thank you! =)")
            end
            break
        end
    end
end

-------------------------------------------------------
--                       Timer                       --
-------------------------------------------------------

function Self:ExtendTimerTo(timer, to, ...)
    if not timer.canceled and (select("#", ...) > 0 or timer.ends - GetTime() < to) then
        Self:CancelTimer(timer)
        local fn = timer.looping and Self.ScheduleRepeatingTimer or Self.ScheduleTimer

        if select("#", ...) > 0 then
            timer = fn(Self, timer.func, to, ...)
        else
            timer = fn(Self, timer.func, to, unpack(timer, 1, timer.argsCount))
        end

        return timer, true
    else
        return timer, false
    end
end

function Self:ExtendTimerBy(timer, by, ...)
    return self:ExtendTimerTo(timer, (timer.ends - GetTime()) + by, ...)
end

function Self:TimerIsRunning(timer)
    return timer and not timer.canceled and timer.ends > GetTime()
end