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

Self.log = {}

-- Versioning
Self.CHANNEL_ALPHA = "alpha"
Self.CHANNEL_BETA = "beta"
Self.CHANNEL_STABLE = "stable"
Self.CHANNELS = Util.TblFlip({Self.CHANNEL_ALPHA, Self.CHANNEL_BETA, Self.CHANNEL_STABLE})

Self.versions = {}
Self.versionNoticeShown = false
Self.disabled = {}

-- Users of compatible addons
Self.compAddonUsers = {}

-- Events
Self.events = CB:New(Self, "On", "Off", "Unsubscribe")

--- Fired when loot and roll tracking starts
Self.EVENT_TRACKING_START = "TRACKING_START"

--- Fired when loot and roll tracking stops
-- @bool clear Whether to clear data
Self.EVENT_TRACKING_STOP = "TRACKING_STOP"

-- Other
Self.rolls = Util.TblCounter()
Self.timers = {}
Self.tracking = nil

-------------------------------------------------------
--                    Addon stuff                    --
-------------------------------------------------------

-- Called when the addon is loaded
function Self:OnInitialize()
    self:ToggleDebug(PersoLootRollDebug or self.DEBUG)
    
    self.db = LibStub("AceDB-3.0"):New(Name .. "DB", Self.Options.DEFAULTS, true)
    
    -- Migrate options
    Options.Migrate()

    -- Register chat commands
    self:RegisterChatCommand(Name, "HandleChatCommand")
    self:RegisterChatCommand("plr", "HandleChatCommand")

    -- Minimap icon
    Options.RegisterMinimapIcon()
end

-- Called when the addon is enabled
function Self:OnEnable()
    -- Register options table
    if not Options.registered then
        Options.Register()
    end

    -- Enable hooks and events
    self:EnableHooks()
    self:RegisterEvents()

    -- Periodically clear old rolls
    self.timers.clearRolls = self:ScheduleRepeatingTimer(Roll.Clear, Roll.CLEAR)

    -- Start inspecting
    Inspect.Start()
    if not Inspect.timer then
        -- IsInGroup doesn't work right after logging in, so check again after waiting a bit.
        self.timers.inspectStart = self:ScheduleTimer(Inspect.Start, 10)
    end

    -- Update state
    self:OnTrackingChanged(true)
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
    elseif cmd == "trinkets" and Item.UpdateTrinkets then
        Item.UpdateTrinkets()
    -- Update and export instance list
    elseif cmd == "instances" and Util.ExportInstances then
        Util.ExportInstances()
    -- Unknown
    else
        self:Error(L["ERROR_CMD_UNKNOWN"], cmd)
    end
end

function Self:Help()
    self:Print(L["HELP"])
end

-------------------------------------------------------
--                       State                       --
-------------------------------------------------------

-- Check if we should currently track loot etc.
function Self:IsTracking(refresh)
    if self.tracking == nil or refresh then
        local group, p = self.db.profile.activeGroups, Util.Push

        self.tracking = self.db.profile.enabled
            and (not self.db.profile.onlyMasterloot or Session.GetMasterlooter())
            and IsInGroup()
            and Util.In(GetLootMethod(), "freeforall", "roundrobin", "personalloot", "group")
            and (
                IsInRaid(LE_PARTY_CATEGORY_INSTANCE)                 and p(group.lfr)
                or IsInGroup(LE_PARTY_CATEGORY_INSTANCE)             and p(group.lfd)
                or Util.IsGuildGroup(Unit.GuildName("player") or "") and p(group.guild)
                or Util.IsCommunityGroup()                           and p(group.community)
                or IsInRaid()                                        and p(group.raid)
                or p(group.party)
            ).Pop()
            or false
    end

    return self.tracking
end

-- Check if the given unit is tracking
function Self:UnitIsTracking(unit, inclCompAddons)
    if not unit or Unit.IsSelf(unit) then
        return self:IsTracking()
    else
        unit = Unit.Name(unit)
        return self.versions[unit] and not self.disabled[unit] or inclCompAddons and self.compAddonUsers[unit]
    end
end

-- Tracking state potentially changed
function Self:OnTrackingChanged(clear)
    local wasTracking, isTracking = self.tracking, self:IsTracking(true)

    -- Start/Stop tracking process
    if wasTracking ~= isTracking then
        Comm.Send(Comm["EVENT_" .. (isTracking and "ENABLE" or "DISABLE")])

        if isTracking then
            -- Schedule version check
            Self.timers.versionCheck = Self:ScheduleTimer(function ()
                Comm.SendData(Comm.EVENT_CHECK)
            end, Self.VERSION_CHECK_DELAY)

            -- Send sync request
            Comm.Send(Comm.EVENT_SYNC)

            -- Fire event
            Self.events:Fire(Self.EVENT_TRACKING_START)
        else
            -- Clear data
            if clear then
                Util.TblIter(self.rolls, Roll.Clear)
            end

            -- Fire event
            Self.events:Fire(Self.EVENT_TRACKING_STOP, clear)
        end
    end
end

-- Set a unit's version string
function Self:SetVersion(unit, version)
    version = tonumber(version) or version

    self.versions[unit] = version
    self.compAddonUsers[unit] = nil

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
function Self:GetVersion(versionOrUnit)
    local t = type(versionOrUnit)
    local version = (not versionOrUnit or UnitIsUnit(versionOrUnit, "player")) and self.VERSION
                 or (t == "number" or t == "string" and tonumber(versionOrUnit:sub(1, 1))) and versionOrUnit
                 or self.versions[Unit.Name(versionOrUnit)]

    t = type(version)
    if t == "number" then
        return version, Self.CHANNEL_STABLE, 0
    elseif t == "string" then
        local version, channel, revision = version:match("([%d.]+)-(%a+)(%d+)")
        return tonumber(version), channel, tonumber(revision)
    end
end

-- Get 1 if the version is higher, -1 if the version is lower or 0 if they are the same or on non-comparable channels
function Self:CompareVersion(versionOrUnit)
    local version, channel, revision = self:GetVersion(versionOrUnit)
    if version then
        local myVersion, myChannel, myRevision = self:GetVersion()
        local channelNum, myChannelNum = Self.CHANNELS[channel], Self.CHANNELS[myChannel]

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

-- Get the number of addon users in the group
function Self:GetNumAddonUsers(inclCompAddons)
    local n = Util.TblCount(self.versions) - Util.TblCount(self.disabled)
    if inclCompAddons then
        n = n + Util.TblCount(Self.compAddonUsers)
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
    local _, name, _, _, lang, _, region = RI:GetRealmInfo(realm or GetRealmName())    
    local txt = ("~ PersoLootRoll ~ Version: %s ~ Date: %s ~ Locale: %s ~ Realm: %s-%s (%s) ~"):format(self.VERSION, date(), GetLocale(), region, name, lang)
    txt = txt .. "\n" .. Util.TblConcat(self.log, "\n")

    GUI.ShowExportWindow("Export log", txt)
end

-------------------------------------------------------
--                       Timer                       --
-------------------------------------------------------

function Self:ExtendTimerTo(timer, to)
    if not timer.canceled and timer.ends - GetTime() < to then
        Self:CancelTimer(timer)
        local fn = timer.looping and Self.ScheduleRepeatingTimer or Self.ScheduleTimer
        timer = fn(Self, timer.func, to, unpack(timer, 1, timer.argsCount))
        return timer, true
    else
        return timer, false
    end
end

function Self:ExtendTimerBy(timer, by)
    return self:ExtendTimerTo(timer, (timer.ends - GetTime()) + by)
end

function Self:TimerIsRunning(timer)
    return timer and not timer.canceled and timer.ends > GetTime()
end