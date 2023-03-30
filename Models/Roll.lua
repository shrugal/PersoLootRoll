---@type string, Addon
local Name, Addon = ...
---@type L
local L = LibStub("AceLocale-3.0"):GetLocale(Name)
local CB = LibStub("CallbackHandler-1.0")
local Comm, GUI, Item, Session, Trade, Unit, Util = Addon.Comm, Addon.GUI, Addon.Item, Addon.Session, Addon.Trade, Addon.Unit, Addon.Util

---@class Roll
local Self = Addon.Roll

local Meta = { __index = Self }

-- Default schedule delay (seconds)
Self.DELAY = 1
-- Clear rolls older than this (seconds)
Self.CLEAR = 20 * 60
-- Base timeout (seconds)
Self.TIMEOUT = 20
-- Timeout increase per item (seconds)
Self.TIMEOUT_PER_ITEM = 5
-- How much longer should rolls be when in chill mode (factor)
Self.TIMEOUT_CHILL_MODE = 2
-- Seconds after a roll ended when it's still considered "recently" ended (seconds)
Self.TIMEOUT_RECENT = 120
-- Max. # of people in a legacy loot group for concise announcements
Self.CONCISE_LEGACY_SIZE = 10

-- Status
Self.STATUS_CANCELED = -1
Self.STATUS_PENDING = 0
Self.STATUS_RUNNING = 1
Self.STATUS_DONE = 2
Self.STATUS = { Self.STATUS_CANCELED, Self.STATUS_PENDING, Self.STATUS_RUNNING, Self.STATUS_DONE }

-- Bids
Self.BID_PASS = LOOT_ROLL_TYPE_PASS --[[@as 0]]
Self.BID_NEED = LOOT_ROLL_TYPE_NEED --[[@as 1]]
Self.BID_GREED = LOOT_ROLL_TYPE_GREED --[[@as 2]]
Self.BID_DISENCHANT = LOOT_ROLL_TYPE_DISENCHANT --[[@as 3]]
Self.BIDS = { Self.BID_NEED, Self.BID_GREED, Self.BID_DISENCHANT, Self.BID_PASS }

-- Actions
Self.ACTION_TRADE = "TRADE"
Self.ACTION_AWARD = "AWARD"
Self.ACTION_VOTE = "VOTE"
Self.ACTION_ASK = "ASK"
Self.ACTION_WAIT = "WAIT"

-- Custom answers
Self.ANSWER_NEED = "NEED"
Self.ANSWER_GREED = "GREED"

-------------------------------------------------------
--                      Events                       --
-------------------------------------------------------

--- Fires when a new roll is added
-- @table roll The roll
Self.EVENT_ADD = "PLR_ROLL_ADD"

--- Fires when the player advertises a roll in chat
-- @table roll     The roll
-- @bool  manually Whether it was triggered manually by the player (e.g. through the UI)
-- @bool  silent   Whether a status update was send afterwards
Self.EVENT_ADVERTISE = "PLR_ROLL_ADVERTISE"

--- Fires when a roll winner (or no winner) is picked
-- @table  roll       The roll
-- @string winner     The winner (optional)
-- @string prevWinner The previous winner (optional)
Self.EVENT_AWARD = "PLR_ROLL_AWARD"

--- Fires when someone bids on a roll
-- @table     roll       The roll
-- @int|float bid        The bid value
-- @string    fromUnit   The unit the bid came from
-- @int       rollResult The random roll result (1-100)
-- @bool      isImport   Whether it was an import received from the roll owner
Self.EVENT_BID = "PLR_ROLL_BID"

--- Fires when a roll is canceled
-- @table roll The roll
Self.EVENT_CANCEL = "PLR_ROLL_CANCEL"

--- Fires when a whisper message is received from the owner/winner
-- @table  roll The roll
-- @string msg  The message
-- @string unit The sender
Self.EVENT_CHAT = "PLR_ROLL_CHAT"

--- Fires when a roll is cleared
-- @table roll The roll
Self.EVENT_CLEAR = "PLR_ROLL_CLEAR"

--- Fires whenever a roll item eligibility changes
-- @table  roll          The roll
-- @number player        The player
Self.EVENT_ELIGIBLE = "PLR_ROLL_ELIGIBLE"

--- Fires when a roll ends
-- @table roll  The roll
-- @int   ended The time when it ended
Self.EVENT_END = "PLR_ROLL_END"

--- Fires whenever a roll owner or item owner changes
-- @table  roll          The roll
-- @number owner         The new owner
-- @number itemOwner     The new itemOwner
-- @number prevOwner     The previous owner
-- @number prevItemOwner The previous itemOwner
Self.EVENT_OWNER = "PLR_ROLL_OWNER"

--- Fires when a roll is restarted
-- @table roll The roll
Self.EVENT_RESTART = "PLR_ROLL_RESTART"

--- Fires when a roll starts
-- @table roll    The roll
-- @int   started The time when it started
Self.EVENT_START = "PLR_ROLL_START"

--- Fires whenever a roll status changes
-- @table  roll   The roll
-- @number status The new status
-- @number prev   The previous status
Self.EVENT_STATUS = "PLR_ROLL_STATUS"

--- Fires whenever a roll timeout changes
-- @table  roll   The roll
-- @number status The new timeout
-- @number prev   The previous timeout
Self.EVENT_TIMEOUT = "PLR_ROLL_TIMEOUT"

--- Fires when a roll's visibility in GUIs is changed
-- @table roll   The roll
-- @bool  hidden Whether the roll is now hidden or not
Self.EVENT_TOGGLE = "PLR_ROLL_TOGGLE"

--- Fires when the roll item is traded
-- @table  roll   The roll
-- @string target The unit being traded to
Self.EVENT_TRADE = "PLR_ROLL_TRADE"

--- Fires when someone votes on a roll
-- @table     roll       The roll
-- @int|float bid        The unit being voted for
-- @string    fromUnit   The unit the vote came from
-- @bool      isImport   Whether it was an import received from the roll owner
Self.EVENT_VOTE = "PLR_ROLL_VOTE"

--- Catchall event that fires for all events in Self.EVENTS
-- @string event The original event
-- @param  ...   The original event parameters
Self.EVENT_CHANGE = "PLR_ROLL_CHANGE"

Self.EVENTS = {
    Self.EVENT_ADD,
    Self.EVENT_ADVERTISE,
    Self.EVENT_AWARD,
    Self.EVENT_BID,
    Self.EVENT_CANCEL,
    Self.EVENT_CHAT,
    Self.EVENT_CLEAR,
    Self.EVENT_ELIGIBLE,
    Self.EVENT_END,
    Self.EVENT_OWNER,
    Self.EVENT_RESTART,
    Self.EVENT_START,
    Self.EVENT_STATUS,
    Self.EVENT_TIMEOUT,
    Self.EVENT_TOGGLE,
    Self.EVENT_TRADE,
    Self.EVENT_VOTE,
}

local ChangeFn = function(...) Addon:SendMessage(Self.EVENT_CHANGE, ...) end
for _, e in pairs(Self.EVENTS) do Addon:RegisterMessage(e, ChangeFn) end

-------------------------------------------------------
--                   Award methods                   --
-------------------------------------------------------

Self.AWARD_VOTES = "VOTES"
Self.AWARD_BIDS = "BIDS"
Self.AWARD_ROLLS = "ROLLS"
Self.AWARD_RANDOM = "RANDOM"
Self.AWARD_METHODS = { Self.AWARD_VOTES, Self.AWARD_BIDS, Self.AWARD_ROLLS, Self.AWARD_RANDOM }

--- Add a custom method for picking a roll winner
---@param key string    A unique identifier
---@param fn function   A callback that removes everyone but the possible winners from the candidates list, with parameters: roll, candidates
---@param before string The custom method will be applied before this method (optional: defaults to Self.AWARD_RANDOM)
---@class AwardMethods: Registrar
---@field Add fun(self: self, key: string, fn: function, before?: string): table
Self.AwardMethods = Util.Registrar.New("ROLL_AWARD_METHOD", "key", function(key, fn, before)
    return Util.Tbl.Hash("key", key, "fn", fn), select(2, Self.AwardMethods:Get(before or Self.AWARD_RANDOM))
end)

-- VOTES
Self.AwardMethods:Add(Self.AWARD_VOTES, function(roll, candidates)
    Util.Tbl.Map(candidates, Util.Fn.Zero)
    for _, to in pairs(roll.votes) do candidates[to] = (candidates[to] or 0) + 1 end
    Util.Tbl.Only(candidates, Util.Tbl.Max(candidates))
end)

-- BIDS
Self.AwardMethods:Add(Self.AWARD_BIDS, function(roll, candidates)
    for unit in pairs(candidates) do candidates[unit] = roll.bids[unit] end
    Util.Tbl.Only(candidates, Util.Tbl.Min(candidates))
end)

-- ROLLS
Self.AwardMethods:Add(Self.AWARD_ROLLS, function(roll, candidates)
    for unit in pairs(candidates) do candidates[unit] = roll.rolls[unit] or random(100) end
    Util.Tbl.Only(candidates, Util.Tbl.Max(candidates))
end)

-- RANDOM
Self.AwardMethods:Add(Self.AWARD_RANDOM, function(_, candidates)
    Util.Tbl.Select(candidates, Util.Tbl.RandomKey(candidates))
end)

-------------------------------------------------------
--                       CRUD                        --
-------------------------------------------------------

---@type table<string|integer, integer>
Self.uidIndex = {}
---@type table<integer, integer>
Self.lootRollIdIndex = {}
---@type table<stringlib, integer[]>
Self.needGreedLinkIndex = {}

-- Get a roll by id or prefixed id
---@param id? number
---@return Roll?
function Self.Get(id)
    if not id then return end
    id = Self.IsPlrId(id) and Self.FromPlrId(id) or id
    return Addon.rolls[id]
end

-- Get a roll by loot roll id
---@param rollId? number
---@return Roll?
function Self.GetByLootRollId(rollId)
    if not rollId then return end
    local id = Self.IsPlrId(rollId) and Self.FromPlrId(rollId) or Self.lootRollIdIndex[rollId]
    return Addon.rolls[id]
end

-- Get a roll by uid
---@param uid? number|string
---@return Roll?
function Self.GetByUid(uid)
    if not uid then return end
    local id = Self.uidIndex[uid]
    return Addon.rolls[id]
end

local CheckAttrFn = function (a, b)
    return a == nil or Util.Select(a, true, b, false, not b, a == b)
end

---@param roll Roll
---@param uid? integer|string|boolean
---@param owner? string|boolean
---@param item? Item|integer|string
---@param itemOwner? string|boolean
---@param status? number
local CheckFn = function (roll, uid, owner, item, itemOwner, status)
    if not CheckAttrFn(uid, roll.uid) then return end
    if not CheckAttrFn(owner, roll.owner) then return end
    if not CheckAttrFn(itemOwner, roll.item.owner) then return end
    if not CheckAttrFn(status, roll.status) then return end
    local t = type(item)
    if t == "table" and item.link ~= roll.item.link then return end
    if t == "number" and item ~= roll.item.id then return end
    if t == "string" and item ~= roll.item.link then return end
    return true
end

-- Find a roll
---@param uid? integer|string|boolean
---@param owner? string|boolean
---@param item? Item|string|number
---@param itemOwner? string|boolean
---@param status? integer|boolean
function Self.Find(uid, owner, item, itemOwner, status)
    owner = Unit.Name(owner == true and "player" or owner) or owner ---@cast owner string?
    itemOwner = Unit.Name(itemOwner == true and "player" or itemOwner) or itemOwner ---@cast itemOwner string?

    -- Load item
    local t = type(item)
    if t == "table" then
        if not item.infoLevel then
            item = Item.FromLink(item.link, item.owner):GetBasicInfo()
        end
        if itemOwner == nil then
            itemOwner = item.owner or false
        end
    elseif t == "string" then
        item = Item.GetInfo(item, "link") or item
    end

    -- Shortcut if uid is provided
    if uid and uid ~= true then
        local roll = Self.GetByUid(uid)
        return roll and CheckFn(roll, uid, owner, item, itemOwner, status) and roll
    end

    return Util.Tbl.First(Addon.rolls, CheckFn, false, false, uid, owner, item, itemOwner, status)
end

-- Shortcut to search rolls by key-value pairs
---@return Roll
function Self.FindWhere(...)
    return Util.Tbl.FirstWhere(Addon.rolls, ...)
end

-- Create and add a roll to the list
---@param item Item|string
---@param owner? string
---@param uid? integer|string
---@param timeout? integer
---@param disenchant? boolean
function Self.Add(item, owner, uid, timeout, disenchant)
    owner = owner and Unit.Name(owner)

    Addon.rollNum = Addon.rollNum + 1
    local id = Addon.rollNum
    local isOwner = Unit.IsSelf(owner)

    -- Create item if its a link
    item = Item.FromLink(item, owner)

    -- Create the roll entry
    ---@class Roll
    local roll = setmetatable({
        id = id,
        created = time(),
        isOwner = isOwner,
        item = item,
        owner = owner,
        timeout = timeout or Self.CalculateTimeout(owner),
        disenchant = Util.Default(
            disenchant,
            not owner or isOwner and Util.Check(Session.GetMasterlooter(), Session.rules.allowDisenchant, Addon.db.profile.allowDisenchant)
        ),
        status = Self.STATUS_PENDING,
        ---@type table<string, number>
        bids = {},
        ---@type table<string, integer>
        rolls = {},
        ---@type table<string, string>
        votes = {},
        ---@type table<string, AceTimerObj>
        timers = {},
        whispers = 0,
        shown = nil,
        hidden = nil,
        posted = not owner and -1 or nil,
        traded = nil
    }, Meta)

    -- Add it to the lists
    Addon.rolls[id] = roll
    roll:SetUid(uid)

    -- Add to list of needgreed rolls with the same item
    if roll:IsNeedGreedRoll() then
        Self.needGreedLinkIndex[item.link] = Util.Tbl.Push(Self.needGreedLinkIndex[item.link] or Util.Tbl.New(), roll.id)
        roll.needGreedNum = #Self.needGreedLinkIndex[item.link]
    end

    Addon:Debug("Roll.Add", roll)

    Addon:SendMessage(Self.EVENT_ADD, roll)

    return roll
end

function Self.FromUpdate(data, unit)
    local item = Item.FromLink(data.item.link, data.item.owner, nil, nil, Util.Default(data.item.isTradable, true))
    local roll = Self.Add(item, data.owner, data.uid, data.timeout, data.disenchant or nil)

    if roll.isOwner then
        roll.item:OnLoaded(function()
            if roll.item:ShouldBeRolledFor() or roll:ShouldBeBidOn() then
                Addon:Debug("Roll.Update.Start")
                roll:Start()
            else
                Addon:Debug("Roll.Update.NotStart", Addon.db.profile.dontShare, roll.owner, roll.isOwner, roll.item.owner, roll.item.isOwner, roll.item:HasSufficientQuality(), roll.item.isEquippable, roll.item:GetFullInfo().isTradable, roll.item:GetNumEligible(true))

                if roll.item.isEquippable then
                    roll:Schedule():SendStatus()
                else
                    roll:Cancel()
                end
            end
        end)
    end

    return roll
end

-- Create a roll from a need-greed roll
---@param link string
---@param started number
---@param timeout number
---@param uid? number
---@param rollId? number
function Self.FromNotice(link, started, timeout, uid, rollId)
    local roll = Self.GetByUid(uid) or Self.GetByLootRollId(rollId)
    if roll then return roll end

    roll = Self.Add(Item.FromLink(link), Session.GetMasterlooter(), uid, timeout)

    if rollId then
        -- Set rollID and eligibility, hide the roll frame until we start the roll
        roll:SetLootRollId(rollId):SetEligible("player"):HideRollFrame()

        -- Make sure we roll on the item within the time limit
        roll.timers.needgreed = Addon:ScheduleTimer(function ()
            if roll.bid or roll.started and roll:GetTimeLeft() <= Self.DELAY then return end

            local canNeed, canGreed = select(6, GetLootRollItemInfo(rollId))
            local bid = canNeed and LOOT_ROLL_TYPE_NEED or canGreed and LOOT_ROLL_TYPE_GREED
            if not bid then return end

            local RollOnLoot = Addon.hooks.RollOnLoot or RollOnLoot
            RollOnLoot(rollId, bid)
        end, started + timeout - time() - Self.DELAY)
    end

    -- Sync or schedule the roll
    if roll.needGreedNum ~= 1 then
        local parent = Self.GetNeedGreedByLink(link, 1)
        if parent then parent:SyncNeedGreedRolls() end
    elseif roll.isOwner or not roll:GetOwnerAddon() then
        roll:Schedule(started)
    end

    return roll
end

-- Clear old rolls
---@param roll Roll
local ClearFn = function(roll)
    if roll.status < Self.STATUS_DONE then
        roll:Cancel()
    else
        roll:ClearTimers()
    end

    Addon.rolls[roll.id] = nil

    if roll.uid then Self.uidIndex[roll.uid] = nil end
    if roll.lootRollId then Self.lootRollIdIndex[roll.lootRollId] = nil end

    Addon:SendMessage(Self.EVENT_CLEAR, roll)
end
---@param self Roll
function Self.Clear(self)
    if self then
        ClearFn(self)
    else
        for i, roll in pairs(Addon.rolls) do
            if roll.created + Self.CLEAR < time() then
                ClearFn(roll)
            end
        end
    end
end

-- Create a test roll
function Self.Test()
    local slots = Util.Tbl.New()
    for i, v in pairs(Item.SLOTS) do
        for j, slot in pairs(v) do
            if GetInventoryItemLink("player", slot) then
                tinsert(slots, slot)
            end
        end
    end

    local slot = Util.Tbl.Random(slots)
    if not slot then return end

    local roll = Self.Add(Item.FromSlot(slot, "player", true), "player")
    roll.isTest = true

    roll.item:SetEligible("player")
    for i = 1, GetNumGroupMembers() do
        local name = GetRaidRosterInfo(i)
        if name then
            roll.item:SetEligible(name)
        end
    end

    roll:Start()
end

-- Check for and convert from/to PLR roll id
function Self.IsPlrId(id) return type(id) == "number" and id < 0 end

function Self.ToPlrId(id) return -id end

function Self.FromPlrId(id) return -id end

function Self.CreatePlrUid() return Util.Str.Random(16) end

function Self.IsPlrUid(uid) return type(uid) == "string" end

function Self:SetUid(uid)
    uid = uid or self.uid or self.isOwner and Self.CreatePlrUid() or nil
    if uid == self.uid then return end

    if self.uid then Self.uidIndex[self.uid] = nil end

    if uid then
        Self.uidIndex[uid] = self.id
        self:StartBids()
    end

    self.uid = uid
end

-------------------------------------------------------
--                     Rolling                       --
-------------------------------------------------------

-- Start a roll
---@param startedOrManually? integer|boolean
---@param silent? boolean
---@param isImport? boolean
---@return self
function Self:Start(startedOrManually, silent, isImport)
    Addon:Verbose(L["ROLL_START"], self.item.link, Comm.GetPlayerLink(self.item.owner))

    ---@type integer|false, boolean
    local started, manually = type(startedOrManually) == "number" and startedOrManually, type(startedOrManually) == "boolean" and startedOrManually
    Self.startedManually = Self.startedManually or self.isOwner and Addon.db.profile.masterloot.rules.startManually and manually

    self.item:OnLoaded(function()
        -- Check if we can start the roll
        local valid, msg = self:Validate(Self.STATUS_PENDING)
        if not valid then return Addon:Error(msg) end

        -- Update item anderes eligible players if not already done so
        self.item:GetFullInfo():GetEligible()

        -- Run the roll
        if isImport or self:CanBeRun(manually) then
            self.started = started or time()

            self:SetStatus(Self.STATUS_RUNNING)
            self:StartBids(self.started, true)

            Addon:SendMessage(Self.EVENT_START, self, self.started)

            if self.isTest or not (self:ShouldEnd() and self:End()) then
                -- Schedule timer to end the roll and/or hide the frame
                if self.timeout > 0 then
                    self.timers.bid = Addon:ScheduleTimer(Self.End, self:GetTimeLeft(), self, nil, true)
                elseif not Addon.db.profile.chillMode then
                    self.timers.bid = Addon:ScheduleTimer(Self.HideRollFrame, self:GetLootRollTimeLeft(), self)
                end

                -- Let everyone know
                self:Advertise(Util.Check(silent, false, nil), true)
            end
        end

        -- Let others know
        self:SendStatus()

        if not self.bid then
            if self.item.isOwner or self.item:ShouldBeBidOn() then
                if self.item.isOwner or self.status == Self.STATUS_RUNNING then
                    -- Show some UI
                    self:ShowRollFrame()
                end
            elseif self.disenchant and Addon.db.profile.filter.disenchant and Unit.IsEnchanter() then
                -- Bid disenchant
                self:RollOnLoot(Self.BID_DISENCHANT)
            end
        end
    end)

    return self
end

-- Add a roll now and start it later
---@param startedOrManually? integer|boolean
---@param silent? boolean
---@return self
function Self:Schedule(startedOrManually, silent)
    if not self.timers.schedule then
        self.item:GetBasicInfo()

        self.timers.schedule = Addon:ScheduleTimer(function()
            Addon:Debug("Roll.Schedule", self)

            self.timers.schedule = nil

            if self.status ~= Self.STATUS_PENDING then return end

            -- Start or cancel
            if self:IsNeedGreedRoll() or self.isOwner and self.item:ShouldBeRolledFor() or not self.isOwner and self:ShouldBeBidOn() then
                Addon:Debug("Roll.Schedule.Start")
                self:Start(startedOrManually, silent)
            else
                Addon:Debug("Roll.Schedule.Cancel", Addon.db.profile.dontShare, self.owner, self.isOwner, self.item.owner, self.item.isOwner, self.item:HasSufficientQuality(), self.item:GetBasicInfo().isEquippable, self.item:GetFullInfo().isTradable, self.item:GetNumEligible(true))
                self:Cancel()
            end
        end, Self.DELAY)
    end

    return self
end

-- Restart a roll
---@return self
function Self:Restart()
    Addon:Debug("Roll.Restart", self.id)

    self.started = nil
    self.startedBids = nil
    self.ended = nil
    self.bid = nil
    self.vote = nil
    self.winner = nil
    self.isWinner = nil
    self.shown = nil
    self.hidden = nil
    self.posted = nil
    self.traded = nil

    wipe(self.bids)
    wipe(self.rolls)
    wipe(self.votes)

    self:ClearTimers()
    self:HideRollFrame()

    Util.Tbl.Except(Addon.lastWhisperedRoll, self.id, true)

    self:SetStatus(Self.STATUS_PENDING)

    Addon:SendMessage(Self.EVENT_RESTART, self)

    return self
end

---@param owner? string|true
---@param itemOwner? string
---@param isImport? boolean
---@return self
function Self:SetOwners(owner, itemOwner, isImport)
    local prevOwner, prevItemOwner = self.owner, self.item.owner

    itemOwner = Unit.Name(itemOwner) or prevItemOwner

    local isSharing = itemOwner and Addon:UnitIsSharing(itemOwner)

    if owner == true then
        owner = isSharing and Session.GetMasterlooter(itemOwner) or itemOwner
    else
        owner = Unit.Name(owner) or prevOwner
    end

    if owner == prevOwner and itemOwner == prevItemOwner then return self end

    local isOwner, isItemOwner = Unit.IsSelf(owner), Unit.IsSelf(itemOwner)

    self.owner = owner
    self.isOwner = isOwner
    self.item.owner = itemOwner
    self.item.isOwner = isItemOwner

    Addon:SendMessage(Self.EVENT_OWNER, self, owner, itemOwner, prevOwner, prevItemOwner)

    if isImport then return self end

    -- Set UID if possible
    if isOwner and itemOwner and not self.uid then
        self:SetUid()
    end

    -- Item owner changed
    if itemOwner ~= prevItemOwner then
        -- Cancel if item owner doesn't share
        if itemOwner and not Addon:UnitIsSharing(itemOwner) then
            self:Cancel()
        -- Need-greed roll just got assigned
        elseif not prevItemOwner then
            self:ClearTimers("needgreed")
            self:StartBids()

            if isOwner or not self:GetOwnerAddon() then
                Addon:ScheduleTimer(self.End, Self.DELAY, self, nil, true, nil, true)
            end
        end
    end

    -- Owner changed
    if owner ~= prevOwner then
        -- Reset posted
        if self.posted ~= -1 then self.posted = nil end

        -- Update some owner-dependant things
        if isOwner or not self:GetOwnerAddon() then
            self.disenchant = Util.Check(Session.GetMasterlooter(), Session.rules.allowDisenchant, Addon.db.profile.allowDisenchant)
            self:SetTimeout(self:CalculateTimeout())
        end
    end

    return self
end

-- Set item eligibility
---@param unit string
---@param eligible? boolean
---@param silent? boolean
---@return self
function Self:SetEligible(unit, eligible, silent)
    if self.item.eligible and self.item.eligible[unit] ~= nil then return self end

    self.item:OnFullyLoaded(function ()
        self.item:UpdateEligible(unit, eligible or Item.ELIGIBLE)

        Addon:SendMessage(Self.EVENT_ELIGIBLE, self, unit)

        if not Unit.IsSelf(unit) then return end

        self:SendNotice()

        if self:IsNeedGreedRoll() and self.lootRollId and self.item:ShouldBeBidOn() == false then
            self:RollOnLoot(Self.BID_PASS)
        end
    end)

    return self
end

---@param started? number
---@param silent? boolean
function Self:StartBids(started, silent)
    if not self.started or self.startedBids or not (self.uid or self.item.owner) then return end

    self.startedBids = started or time()

    self:ClearNeedGreedRolls()

    if not silent and self.bid then self:SendNotice() end

    return self
end

-- Bid on a roll
---@param bid number
---@param fromUnit? string
---@param randomRoll? integer
---@param isImport? boolean
---@param silent? boolean
---@return self
function Self:Bid(bid, fromUnit, randomRoll, isImport, silent)
    Addon:Debug("Roll.Bid", self.id, bid, fromUnit, randomRoll, isImport)

    fromUnit = Unit.Name(fromUnit or "player")
    bid = self:GetBidValue(bid or Self.BID_NEED, fromUnit, isImport)
    randomRoll = randomRoll or self.rolls[fromUnit] or self.isOwner and bid ~= Self.BID_PASS and random(100) or nil

    local isSelf = Unit.IsSelf(fromUnit)

    -- Hide the roll frame
    if isSelf then self:HideRollFrame() end

    if bid == self.bids[fromUnit] then
        if not self.rolls[fromUnit] and randomRoll then
            self.rolls[fromUnit] = randomRoll
            Addon:SendMessage(Self.EVENT_BID, self, bid, fromUnit, randomRoll, isImport)
        end
    elseif self:ValidateBid(bid, fromUnit, randomRoll, isImport) then
        self.bids[fromUnit] = bid
        self.rolls[fromUnit] = randomRoll

        if isSelf then self.bid = bid end

        Addon:SendMessage(Self.EVENT_BID, self, bid, fromUnit, randomRoll, isImport)

        -- Let everyone know
        Comm.RollBid(self, bid, fromUnit, randomRoll, isImport, silent)

        -- Check if we should end the roll
        if not (self:ShouldEnd() and self:End()) and self.isOwner then
            -- or start if in chill mode
            if self.status == Self.STATUS_PENDING then
                self:Start(false, silent)
            -- or advertise to chat
            elseif self.status == Self.STATUS_RUNNING then
                self:Advertise(Util.Check(silent, false, nil))
            -- or if the winner just passed on the item
            elseif self.winner == fromUnit and bid == Self.BID_PASS and not self.traded then
                self:End(nil, false, true)
            end
        end

        self:SyncNeedGreedRolls()
    end

    return self
end

function Self:RollOnLoot(bid)
    RollOnLoot(self:GetLootRollId(), bid)

    self:ClearTimers("needgreed")

    return self
end

-- Vote for a unit
---@param vote? string
---@param fromUnit? string
---@param isImport? boolean
---@return self
function Self:Vote(vote, fromUnit, isImport)
    Addon:Debug("Roll.Vote", self.id, vote, fromUnit, isImport)

    vote = Unit.Name(vote)
    fromUnit = assert(Unit.Name(fromUnit or "player"))

    if self:ValidateVote(vote, fromUnit, isImport) then
        self.votes[fromUnit] = vote

        if Unit.IsSelf(fromUnit) then self.vote = vote end

        Addon:SendMessage(Self.EVENT_VOTE, self, vote, fromUnit, isImport)

        -- Let everyone know
        Comm.RollVote(self, vote, fromUnit, isImport)
    end

    return self
end

-- Check if we should end the roll prematurely
function Self:ShouldEnd()
    local ml = Session.GetMasterlooter()
    local allowKeep = not ml or Session.rules.allowKeep

    -- Don't end need-greed rolls before setting an item owner
    if self:IsNeedGreedRoll() then
        return false
    -- The item owner voted need
    elseif self.isOwner and allowKeep and floor(self.bids[self.item.owner] or 0) == Self.BID_NEED then
        return true
    -- The item owner hasn't voted yet
    elseif self.isOwner and allowKeep and not self.bids[self.item.owner] then
        return false
    -- The owner doesn't have the addon and we have bid
    elseif not self:GetOwnerAddon() and self.bid then
        return true
    -- Another owner
    elseif not self.isOwner then
        return false
    end

    -- Check if all eligible players have bid
    for unit, eligible in pairs(self.item:GetEligible() --[[@as table<string, ItemEligible>]]) do
        if not self.bids[unit] and (eligible == Item.ELIGIBLE_UPGRADE or ml or Addon.db.profile.awardSelf) then
            return false
        end
    end

    return true
end

-- End a roll
---@param winner? boolean|string
---@param cleanup? boolean
---@param force? boolean
---@param fullStatus? boolean
---@return self
function Self:End(winner, cleanup, force, fullStatus)
    Addon:Debug("Roll.End", self.id, winner, cleanup, force, fullStatus)

    winner = winner and winner ~= true and Unit.Name(winner) or winner
    local sendStatus = false

    -- Hide UI elements etc.
    if cleanup then
        self:ClearTimers("schedule", "bid")
        self:HideRollFrame()
    end

    -- End the roll
    if self.status < Self.STATUS_DONE then
        Addon:Verbose(L["ROLL_END"], self.item.link, Comm.GetPlayerLink(self.item.owner))

        -- Check if we can end the roll
        local valid, msg = self:Validate(Self.STATUS_RUNNING, Self.STATUS_PENDING, winner)
        if not valid then
            Addon:Error(msg)
            return self
        end

        -- Check if we should post it to chat first
        if self.isOwner and not winner and self:Advertise() then
            return self
        end

        -- Pass on need-greed rolls
        if self.lootRollId and not self.bid then
            self:RollOnLoot(Self.BID_PASS)
        end

        -- Update status
        self:SetStatus(Self.STATUS_DONE)
        self.ended = time()
        self.started = self.started or time()

        Addon:SendMessage(Self.EVENT_END, self, self.ended)
        sendStatus = true
    end

    -- Determine a winner
    if not self.winner or force then
        if (self.isOwner or not self:GetOwnerAddon()) and (not winner or winner == true) then
            local p = Addon.db.profile
            local r = Session.rules
            local ownerBid = self.bids[self.item.owner]

            if not self:GetOwnerAddon() and ownerBid or (not self:HasMasterlooter() or r.allowKeep) and floor(ownerBid or 0) == Self.BID_NEED then
                -- Give it to the item owner
                winner = self.item.owner
            elseif winner == true or not (p.awardSelf or self:IsMasterlooter()) then
                -- Pick a winner now
                winner = self:DetermineWinner()
            elseif self:IsMasterlooter() and p.masterloot.rules.autoAward and not self.timers.award then
                -- Schedule a timer to pick a winner
                local base = p.masterloot.rules.autoAwardTimeout or Self.TIMEOUT
                local perItem = p.masterloot.rules.autoAwardTimeoutPerItem or Self.TIMEOUT_PER_ITEM
                self.timers.award = Addon:ScheduleTimer(Self.End, base + Util.GetNumDroppedItems() * perItem, self, true)
            end
        end

        local prevWinner = self.winner

        -- Set winner
        if not Util.In(winner, self.winner, true) then ---@cast winner -boolean,-false
            self.winner = winner
            self.isWinner = Unit.IsSelf(self.winner)

            if self.winner then
                -- Cancel auto award timer
                if self.timers.award then
                    self:ClearTimers("award")
                    self.timers.award = nil
                end

                -- It has already been traded
                if self.winner == self.item.owner then
                    self:OnTraded(self.winner)
                end

                -- Let everyone know
                Comm.RollEnd(self)
            end

            Addon:SendMessage(Self.EVENT_AWARD, self, self.winner, prevWinner)
            sendStatus = true
        end
    end

    -- Send status if something changed
    if fullStatus or sendStatus then
        self:SendStatus(nil, nil, fullStatus)
    end

    return self
end

-- Cancel a roll
---@param silent? boolean
function Self:Cancel(silent)
    if self.status == Self.STATUS_CANCELED then return self end
    Addon:Verbose(L["ROLL_CANCEL"], self.item.link, Comm.GetPlayerLink(self.item.owner))

    self:ClearTimers()
    self:HideRollFrame()

    -- Update status
    self:SetStatus(Self.STATUS_CANCELED)

    -- Let everyone know
    Addon:SendMessage(Self.EVENT_CANCEL, self)
    if not silent then self:SendStatus() end

    return self
end

-- Trade with the owner or the winner of the roll
---@type function
function Self:Trade()
    local target = self:GetActionTarget()
    if target then
        Trade.Initiate(target)
    end

    return self
end

-- Called when the roll's item is traded
function Self:OnTraded(target)
    if not target or target == self.traded then return end

    self.traded = target
    Addon:SendMessage(Self.EVENT_TRADE, self, target)

    -- Update the status
    if self.isOwner and not self:HasMasterlooter() and self:IsActive() then
        self:Cancel(true)
    end

    self:SendStatus(self.item.isOwner or self.isWinner)
end

-- Change the roll status
---@param roll Roll
local OwnedActiveFn = function(roll)
    return roll.isOwner and roll:IsActive(true)
end

---@param status integer
function Self:SetStatus(status)
    if status == self.status then return end

    local prev = self.status
    self.status = status

    Self.startedManually = Self.startedManually and Util.Tbl.FindFn(Addon.rolls, OwnedActiveFn) ~= nil

    Addon:SendMessage(Self.EVENT_STATUS, self, self.status, prev)

    self:SyncNeedGreedRolls()
end

-------------------------------------------------------
--                     Awarding                      --
-------------------------------------------------------

-- Figure out a winner
function Self:DetermineWinner()
    local candidates = Util.Tbl.CopyExcept(self.bids, Self.BID_PASS, true)

    for i, method in Self.AwardMethods:Iter() do
        method.fn(self, candidates)

        if Util.Tbl.Count(candidates) == 1 then
            return next(candidates), Util.Tbl.Release(candidates)
        end
    end

    Util.Tbl.Release(candidates)

    -- Check for disenchanter
    if Session.GetMasterlooter() then
        local dis = Util.Tbl.CopyFilter(Addon.db.profile.masterloot.rules.disenchanter[GetRealmName()] or Util.Tbl.EMPTY, Unit.InGroup, true, true, true)
        if next(dis) then
            for unit in pairs(dis) do self:Bid(Self.BID_DISENCHANT, unit, nil, true) end
            return self:DetermineWinner()
        end
    end
end

-------------------------------------------------------
--                    Validation                     --
-------------------------------------------------------

-- Some common error checks for a loot roll
---@vararg integer|string
---@return boolean
---@return string|nil
function Self:Validate(...)
    if Addon.DEBUG or self.isTest or self.needGreedNum then
        return true
    elseif not self.item.isTradable then
        return false, L["ERROR_ITEM_NOT_TRADABLE"]
    elseif not IsInGroup() then
        return false, L["ERROR_NOT_IN_GROUP"]
    elseif self.owner and (not UnitExists(self.owner) or not Unit.InGroup(self.owner)) then
        return false, L["ERROR_PLAYER_NOT_FOUND"]:format(self.owner)
    else
        local status

        for i, v in Util.Each(...) do
            if type(v) == "number" then
                status = v == self.status and true or status or v
            elseif type(v) == "string" then
                if not UnitExists(v) or not Unit.InGroup(v) then
                    return false, L["ERROR_PLAYER_NOT_FOUND"]:format(v)
                end
            end
        end

        if status and status ~= true then
            return false, L["ERROR_ROLL_STATUS_NOT_" .. status]
        end

        return true
    end
end

-- Validate an incoming bid
---@param bid number
---@param fromUnit string
---@param randomRoll? integer
---@param isImport? boolean
function Self:ValidateBid(bid, fromUnit, randomRoll, isImport)
    local valid, msg = self:Validate(fromUnit)
    if not valid then return Addon:Error(msg) end

    local answer = Self.GetAnswerValue(bid)
    local answers = Session.rules["answers" .. floor(bid)] --[=[@as string[]]=]

    -- Don't validate imports any further
    if isImport then
        return true
    -- Check if it's a valid bid
    elseif not Util.Tbl.Find(Self.BIDS, floor(bid)) or Session.GetMasterlooter(self.owner) and answer > 0 and not (answers and answers[answer]) then
        if Unit.IsSelf(fromUnit) then
            Addon:Error(L["ERROR_ROLL_BID_UNKNOWN_SELF"])
        else
            Addon:Verbose(L["ERROR_ROLL_BID_UNKNOWN_OTHER"], fromUnit, self.item.link)
        end
    -- Check if the unit can bid
    elseif not self:UnitCanBid(fromUnit, bid, true) then
        if Unit.IsSelf(fromUnit) then
            Addon:Error(L["ERROR_ROLL_BID_IMPOSSIBLE_SELF"])
        else
            Addon:Verbose(L["ERROR_ROLL_BID_IMPOSSIBLE_OTHER"], fromUnit, self.item.link)
        end
    else
        return true
    end
end

-- Validate an incoming vote
---@param vote string
---@param fromUnit? string
---@param isImport? boolean
function Self:ValidateVote(vote, fromUnit, isImport)
    local valid, msg = self:Validate(vote, fromUnit)
    if not valid then return Addon:Error(msg) end

    -- Don't validate imports any further
    if isImport then
        return true
    -- Check if the unit can bid
    elseif not self:UnitCanVote(fromUnit) then
        if Unit.IsSelf(fromUnit) then
            Addon:Error(L["ERROR_ROLL_VOTE_IMPOSSIBLE_SELF"])
        else
            Addon:Verbose(L["ERROR_ROLL_VOTE_IMPOSSIBLE_OTHER"], fromUnit, self.item.link)
        end
    else
        return true
    end
end

-------------------------------------------------------
--                      GUI                       --
-------------------------------------------------------

---@param rollId number
function Self:SetLootRollId(rollId)
    if self.lootRollId then Self.lootRollIdIndex[self.lootRollId] = nil end
    if rollId then Self.lootRollIdIndex[rollId] = self.id end

    self.lootRollId = rollId

    return self
end

function Self:GetLootRollId()
    return self.lootRollId or Self.ToPlrId(self.id)
end

-- Get the loot frame for a loot id
---@return GroupRollFrame?
---@return integer?
function Self:GetRollFrame()
    local id = self:GetLootRollId()

    for i = 1, math.huge do
        local frame = _G["GroupLootFrame" .. i]
        if not frame then break end

        if frame.rollID == id then
            return frame, i
        end
    end
end

-- Show the roll frame
function Self:ShowRollFrame()
    if self.shown or not Addon.db.profile.ui.showRollFrames then return end

    local frame = self:GetRollFrame()
    if frame and frame:IsShown() then self.shown = true return end

    self.shown = false
    GroupLootContainer_OpenNewFrame(self:GetLootRollId(), self:GetLootRollRunTime())

    if not self.shown then return end

    -- This is required to circumvent a bug in ElvUI
    Util.Tbl.List(GroupLootContainer.rollFrames)
    GroupLootContainer_Update(GroupLootContainer)
end

-- Hide the roll frame
function Self:HideRollFrame()
    local frame = self:GetRollFrame()
    if not frame or not frame:IsShown() then return end

    GroupLootContainer_RemoveFrame(GroupLootContainer, frame)

    -- This is required to circumvent a bug in ElvUI
    Util.Tbl.List(GroupLootContainer.rollFrames)
    GroupLootContainer_Update(GroupLootContainer)
end

-- Show the alert frame for winning an item
function Self:ShowAlertFrame()
    if not self.item:GetBasicInfo().isEquippable then return end

    local unit = Unit.Name("player")
    local rollType = self.bid and floor(self.bid)
    local roll = self.rolls[unit]

    GUI.LootAlertSystem:AddAlert(
        self.id,        -- rollId
        self.item.link, -- itemLink
        1,              -- originalQuantity
        rollType,       -- rollType
        roll,           -- roll
        nil,            -- specID
        false,          -- isCurrency
        false,          -- showFactionBG
        nil,            -- lootSource
        false,          -- lessAwesome
        false,          -- isUpgraded
        false,          -- isCorrupted
        false,          -- wonRoll
        false,          -- showRatedBG
        false           -- isSecondaryResult
    )
end

-- Toggle the rolls visiblity in GUIs
---@param show boolean
function Self:ToggleVisibility(show)
    self.hidden = not Util.Default(show, self.hidden)
    Addon:SendMessage(Self.EVENT_TOGGLE, self, self.hidden)

    return self
end

-- Log a chat message about the roll
---@param msg string
---@param unit string
function Self:AddChat(msg, unit)
    unit = unit or "player"
    local colorTable = ChatTypeInfo[Unit.IsSelf(unit) and "WHISPER_INFORM" or "WHISPER"] or Util.Tbl.EMPTY
    local color = Util.Str.Color(colorTable.r, colorTable.g, colorTable.b)
    msg = ("|c%s[|r%s|c%s]: %s|r"):format(color, Unit.ColoredShortenedName(unit), color, msg)

    ---@type string[]
    self.chat = self.chat or Util.Tbl.New()
    tinsert(self.chat, msg)

    Addon:SendMessage(Self.EVENT_CHAT, self, msg, unit)

    return self
end

-------------------------------------------------------
--                       Comm                        --
-------------------------------------------------------

-- Check if we should advertise the roll to group chat.
function Self:ShouldAdvertise(manually)
    return (not self.posted or manually and self.posted == -1)
        and not self:IsNeedGreedRoll()
        and self:CanBeAwarded()
        and not self:ShouldEnd()
        and (manually or Comm.ShouldInitChat() and (self.bid or Session.GetMasterlooter()))
end

-- Check if we should use concise messages
function Self:ShouldBeConcise()
    return Addon.db.profile.messages.group.concise and not self:HasMasterlooter()
        and (
        Util.GetNumDroppedItems() <= 1
            or self.item:GetNumEligible(false, true) <= 1
            or Util.IsLegacyRun() and GetNumGroupMembers() <= Self.CONCISE_LEGACY_SIZE
        )
end

-- Advertise the roll to the group
---@param force? boolean
---@param silent? boolean
function Self:Advertise(force, silent)
    local manually = force == true

    if manually and self.posted == -1 then
        self.posted = nil
    elseif force == false and not self.posted then
        self.posted = -1
    end

    if not self:ShouldAdvertise(manually) then return false end

    -- Get the next free roll slot
    local slot
    for i = self:ShouldBeConcise() and 0 or 1, 49 do
        if not Self.FindWhere("status", Self.STATUS_RUNNING, "posted", i) then
            slot = i break
        end
    end

    if not slot then return false end

    self.posted = slot
    self:ExtendTimeLeft()

    Comm.RollAdvertise(self)

    if not silent then self:SendStatus() end

    Addon:SendMessage(Self.EVENT_ADVERTISE, self, force, silent)

    return true
end

-- Get roll update data
---@param target? string
---@param full? boolean
function Self:GetStatusData(target, full)
    local data = Util.Tbl.Tmp()

    data.uid = self.uid
    data.owner = Unit.FullName(self.owner)
    data.status = self.status
    data.started = self.started
    data.timeout = self.timeout
    data.disenchant = self.disenchant or nil
    data.posted = self.posted
    data.winner = self.winner and Unit.FullName(self.winner)
    data.traded = self.traded and Unit.FullName(self.traded)
    data.item = Util.Tbl.Hash(
        "link", self.item.link,
        "owner", Unit.FullName(self.item.owner),
        "isTradable", Util.Check(self.item.isTradable == false and not Addon.DEBUG, false, nil),
        "numEligible", self.item:GetNumEligible(true, true)
    )

    if full then
        if Util.Check(self:HasMasterlooter(), Session.rules.bidPublic, Addon.db.profile.bidPublic) or Session.IsOnCouncil(target) then
            data.bids = Util.Tbl.MapKeys(self.bids, Unit.FullName)
            data.rolls = Util.Tbl.MapKeys(self.rolls, Unit.FullName)
        end

        if Session.rules.votePublic or Session.IsOnCouncil(target) then
            data.votes = Util(self.votes):MapKeys(Unit.FullName):Map(Unit.FullName)()
        end
    end

    return data
end

-- Send the roll status to others
---@param force? boolean
---@param target? string
---@param full? boolean
function Self:SendStatus(force, target, full)
    if not force and not self.isOwner then return end
    if self.isTest or not (self.startedBids or self.needGreedNum == 1) then return end

    target = target or Comm.TYPE_GROUP
    full = self.startedBids and full

    Comm.SendData(Comm.EVENT_STATUS, self:GetStatusData(target, full), target)

    if not full or target ~= Comm.TYPE_GROUP then return end

    local council = self:HasMasterlooter() and Session.rules.council
    if not council then return end

    local bids = next(self.bids) and not Util.Check(self:HasMasterlooter(), Session.rules.bidPublic, Addon.db.profile.bidPublic)
    local votes = next(self.votes) and not Session.rules.votePublic
    if not bids and not votes then return end

    -- Send bid and vote details to council members
    for fullName,_ in pairs(council) do
        Comm.SendData(Comm.EVENT_STATUS, self:GetStatusData(fullName, full), fullName)
    end
end

-- Send a notice about a roll and our involvement
function Self:SendNotice()
    if not (self.startedBids or self.needGreedNum) then return end

    local eligible = self.item:GetEligible("player")
    if eligible == nil then return end

    local data = Util.Tbl.HashTmp(
        "uid", self.uid,
        "num", self.needGreedNum,
        "item", Util.Tbl.Hash(
            "link", self.item.link,
            "owner", Unit.FullName(self.item.owner)
        ),
        "started", self.started,
        "timeout", self.timeout
    )

    if self.startedBids then
        data.item.eligible = eligible
        data.bid = self.bid
    end

    Comm.SendData(Comm.EVENT_NOTICE, data)
end

-- Process a roll status or notice message
---@param data RollUpdateData
---@param unit string
---@return boolean?
function Self.Update(data, unit)
    local ml = Session.GetMasterlooter()
    local created = false

    local link, itemOwner = data.item.owner, data.item.link

    -- Get the roll
    local roll = Self.GetByUid(data.uid)
        or itemOwner and Self.Find(false, nil, data.item)
        or data.num and Self.GetNeedGreedByLink(link, not itemOwner and data.num)

    Addon:Debug("Roll.Update", unit, data, roll)

    -- or create the roll
    if not roll then
        -- Only the item owner and our ml can create owned rolls
        if itemOwner and not Util.In(unit, itemOwner, ml) then
            Addon:Debug("Roll.Update.Reject.SenderNotAllowed")
            return false
        -- Only accept items while having a masterlooter if enabled
        elseif Addon.db.profile.onlyMasterloot and not ml then
            Addon:Debug("Roll.Update.Reject.NoMasterlooter")
            return false
        end

        if itemOwner then
            roll = Self.FromUpdate(data, unit)
        else
            roll = Self.FromNotice(link, data.started, data.timeout, data.uid)
        end
    end

    -- The roll owner or ML can send detailed updates
    if Util.In(unit, roll.owner, ml) then
        -- UID
        if not roll.uid then roll:SetUid(data.uid) end

        -- Owner
        roll:SetOwners(data.owner, data.item.owner, true)

        -- Update basics
        roll.posted = data.posted
        roll.disenchant = data.disenchant
        roll.item.isTradable = Util.Default(data.item.isTradable, true)
        roll:SetTimeout(data.timeout)

        -- Cancel the roll if the owner has canceled it
        if data.status == Self.STATUS_CANCELED then
            roll:Cancel()
        else
            roll.item:OnLoaded(function()
                -- Declare our interest if the roll is pending and our interest might have been missed
                if Self.IsActive(data) and roll:ShouldBeBidOn() and (
                    (data.item.numEligible or 0) == 0
                    or not roll.declaredInterest and (roll.item:IsCollectibleMissing() or roll.item:GetEligible("player") ~= Item.ELIGIBLE_UPGRADE)
                ) then
                    roll.declaredInterest = true
                    roll:SetEligible("player", Item.ELIGIBLE_UPGRADE)
                end

                -- Restart and/or start the roll if necessary
                if data.status < roll.status or roll.started and data.started ~= roll.started then
                    roll:Restart()
                end
                if data.status >= Self.STATUS_RUNNING and roll.status < Self.STATUS_RUNNING then
                    roll:Start(data.started, nil, true)
                end

                -- Import bids
                if data.bids and next(data.bids) then
                    roll.bid = nil
                    wipe(roll.bids)

                    for fromUnit, bid in pairs(data.bids or {}) do
                        roll:Bid(bid, fromUnit, data.rolls and data.rolls[fromUnit], true)
                    end
                end

                -- Import votes
                if data.votes and next(data.votes) then
                    roll.vote = nil
                    wipe(roll.votes)

                    for fromUnit, forUnit in pairs(data.votes or {}) do
                        roll:Vote(forUnit, fromUnit, true)
                    end
                end

                -- End the roll if the owner has ended it
                if data.status >= Self.STATUS_DONE and roll.status < Self.STATUS_DONE or data.winner ~= roll.winner then
                    roll:End(data.winner, false, true)
                end

                -- Register when the roll has been traded
                if data.traded ~= roll.traded then
                    roll:OnTraded(data.traded)
                end
            end)
        end
    -- Others can inform us about changes we might have missed
    else
        -- Set item owner
        if data.item.owner and not roll.item.owner then
            roll:SetOwners(true, data.item.owner)
        end

        -- The winner can inform us that it has been traded, or the item owner if the winner doesn't have the addon or he traded it to someone else
        if roll.winner and (unit == roll.winner or unit == roll.item.owner and not Addon:UnitIsTracking(roll.winner) or data.traded ~= roll.winner) then
            roll.item:OnLoaded(Self.OnTraded, roll, data.traded)
        end
    end

    -- Sender can inform us about their own involvement
    if roll.uid or roll.item.owner then
        -- Set sender eligibility
        if data.item.eligible then
            roll:SetEligible(unit, data.item.eligible)
        end

        -- Set sender bid
        if data.bid then
            roll:Bid(data.bid, unit)
        end
    end

    return created
end

-------------------------------------------------------
--                      Timing                       --
-------------------------------------------------------

-- Calculate the total roll runtime
---@param selfOrOwner? Roll|string
function Self.CalculateTimeout(selfOrOwner)
    if not selfOrOwner then return 240 end

    local owner = type(selfOrOwner) == "table" and selfOrOwner.owner or selfOrOwner ---@cast owner string
    local isSelf = Unit.IsSelf(owner)
    local ml = Session.GetMasterlooter()
    local chillMode = not ml and Addon.db.profile.chillMode

    if chillMode and (isSelf and Addon.db.profile.awardSelf or not Addon:UnitIsTracking(owner)) then
        return 0
    end

    local base = ml and Session.rules.timeoutBase or Self.TIMEOUT
    local perItem = ml and Session.rules.timeoutPerItem or Self.TIMEOUT_PER_ITEM
    local factor = chillMode and isSelf and Self.TIMEOUT_CHILL_MODE or 1

    return (base + Util.GetNumDroppedItems() * perItem) * factor
end

-- Get the time that is left on a roll
function Self:GetTimeLeft()
    if self.timeout == 0 or self.status ~= Self.STATUS_RUNNING then return 0 end

    local started = self.started and (self.started - time()) or 0

    return max(0, started + self.timeout)
end

-- Get the total time for the loot roll frame
function Self:GetLootRollRunTime()
    local timeout = (self.timeout ~= 0 or Addon.db.profile.chillMode) and self.timeout or self:CalculateTimeout()
    if timeout == 0 then return timeout end

    return timeout + Self.DELAY
end

-- Get the time that is left on the loot roll frame
function Self:GetLootRollTimeLeft()
    local timeout = self:GetLootRollRunTime()
    if timeout == 0 then return timeout end

    local started = self.started and (self.started - time()) or 0

    return max(0, started + timeout)
end

-- Set the timeout
---@param to number
---@return self
function Self:SetTimeout(to)
    assert(to > 0, "Timeout must be positive")

    if self.timeout == 0 or to == self.timeout then return self end

    -- Change a running timer
    if self.status == Self.STATUS_RUNNING then
        self.timers.bid = Addon:ChangeTimerBy(self.timers.bid, to - self.timeout)
    end

    local prev = self.timeout
    self.timeout = to

    -- Update the roll frame
    local frame = self:GetRollFrame()
    if frame then frame.Timer:SetMinMaxValues(0, self.timeout) end

    Addon:SendMessage(Self.EVENT_TIMEOUT, self, self.timeout, prev)

    return self
end

-- Extend the remaining time to at least the given # of seconds
---@param to? number
---@return self
function Self:ExtendTimeLeft(to)
    to = to or Self.TIMEOUT

    local left = self:GetTimeLeft()
    if left > to then return self end

    return self:SetTimeout(self.timeout + (to - left))
end

---@vararg true|string
function Self:ClearTimers(...)
    for name,timer in pairs(self.timers) do
        if (...) == true or (...) and Util.In(name, ...) or not (...) and name ~= "needgreed" then
            Addon:CancelTimer(timer)
            self.timers[name] = nil
        end
    end
end

-------------------------------------------------------
--                    Need-Greed                     --
-------------------------------------------------------

-- Check if the roll is handled by the vanilla needbeforegreed system
function Self:IsNeedGreedRoll()
    return not Self.IsPlrUid(self.uid) and not self.item.owner
end

--- Get a need-greed roll or a list of need-greed roll ids
---@param link string
---@param allOrNum? number|boolean
---@return Roll?
---@overload fun(link: string, allOrNum: true): number[]?
function Self.GetNeedGreedByLink(link, allOrNum)
    local ids = Self.needGreedLinkIndex[link]

    -- Return ids
    if not ids or allOrNum == true then return ids end
    -- Return roll with given index
    if type(allOrNum) == "number" then return Addon.rolls[ids[allOrNum]] end
    -- Return roll without item owner
    for _,id in pairs(ids) do
        local roll = Self.Get(id)
        if roll and roll:IsNeedGreedRoll() then return roll end
    end
end

function Self:SyncNeedGreedRolls()
    if self.needGreedNum ~= 1 then return end

    local ids = Self.GetNeedGreedByLink(self.item.link, true)
    if not ids then return end

    for _,id in pairs(ids) do
        local roll = Self.Get(id)

        if roll and roll ~= self and roll:IsNeedGreedRoll() then
            -- Sync running status
            if self.status == Self.STATUS_RUNNING and roll.status == Self.STATUS_PENDING then
                roll.started = self.started

                roll:SetStatus(self.status)

                Addon:SendMessage(Self.EVENT_START, roll, roll.started)

                if roll.timeout > 0 then
                    roll.timers.bid = Addon:ScheduleTimer(Self.End, roll:GetTimeLeft(), roll, nil, true)
                end
            end

            -- Sync own bid
            if self.bid and not roll.bid then
                roll:RollOnLoot(self.bid)
            end
        end
    end
end

function Self:ClearNeedGreedRolls()
    if not self.needGreedNum then return end

    local ids = Self.GetNeedGreedByLink(self.item.link, true)
    if not ids then return end

    for _,id in pairs(ids) do
        local roll = Self.Get(id)
        if roll and roll:IsNeedGreedRoll() then return end
    end

    Util.Tbl.Release(ids)
    Self.needGreedLinkIndex[self.item.link] = nil
end

-------------------------------------------------------
--                      Helper                       --
-------------------------------------------------------

-- Check if we should bid on the roll
---@return boolean?
function Self:ShouldBeBidOn()
    return self.item:ShouldBeBidOn() or self.disenchant and Addon.db.profile.filter.disenchant and Unit.IsEnchanter()
end

-- Check if the given unit is eligible
---@param unit string
---@param atLeast ItemEligible
---@return boolean?
function Self:UnitIsEligible(unit, atLeast)
    unit = unit or "player"

    if not atLeast and Unit.IsUnit(unit, self.item.owner) then
        return true
    elseif not self.item:IsLoaded() then
        return
    end

    return Item.CompareEligible(self.item:GetEligible(unit), atLeast) >= 0
end

-- Check if the roll can still be won
function Self:CanBeWon(includeDone)
    return not self.traded and (self:IsActive() or includeDone and self.status == Self.STATUS_DONE and not self.winner)
end

-- Check if the given unit can win this roll
---@param unit string
function Self:UnitCanWin(unit, includeDone, checkInterest)
    return self:CanBeWon(includeDone) and self:UnitIsEligible(unit, checkInterest and Item.ELIGIBLE_UPGRADE or Item.ELIGIBLE)
end

-- Check if we can still award the roll
function Self:CanBeAwarded(includeDone)
    return self.isOwner and self.item.owner and self:CanBeWon(includeDone)
end

-- Check if we can still award the roll to the given unit
---@param unit string
---@param includeDone boolean
---@param checkInterest? boolean
function Self:CanBeAwardedTo(unit, includeDone, checkInterest)
    return self.isOwner and self:UnitCanWin(unit, includeDone, checkInterest)
end

-- Check if we can give the item to the given unit, now or in the future
---@param unit string
function Self:CanBeGivenTo(unit)
    return self:CanBeAwardedTo(unit, true) or self.item.isOwner and (self.isWinner or not self.traded)
end

-- Check if we can award the roll randomly
function Self:CanBeAwardedRandomly()
    if not (self.status == Self.STATUS_DONE and self:CanBeAwarded(true)) then
        return false
    elseif Util.Tbl.CountExcept(self.bids, Self.BID_PASS) > 0 then
        return true
    elseif self:HasMasterlooter() then
        local disenchanter = Addon.db.profile.masterloot.rules.disenchanter[GetRealmName()]
        for name in pairs(disenchanter or Util.Tbl.EMPTY) do
            if Unit.InGroup(disenchanter) then
                return true
            end
        end
    else
        return false
    end
end

-- Check if the given unit can bid on this roll
---@param unit? string The bidding unit
---@param bid? number The bid
---@param validating? boolean Just check if the bid is valid
function Self:UnitCanBid(unit, bid, validating)
    unit = Unit.Name(unit or "player")

    local needGreed = self:IsNeedGreedRoll()
    local customAnswer = bid and bid ~= floor(bid)
    local prevBid = self.bids[unit]
    local sameBidLevel = bid and prevBid and floor(bid) == floor(prevBid)
    local prevCustomAnwer = prevBid and prevBid ~= floor(prevBid)

    -- Obvious stuff
    if self.traded or self.status == Self.STATUS_CANCELED or not Unit.InGroup(unit) then
        return false
    -- Only need+pass for rolls from non-users
    elseif not (needGreed or self:GetOwnerAddon() or Util.In(bid, nil, Self.BID_NEED, Self.BID_PASS)) then
        return false
    -- Can't bid disenchant if it's not allowed
    elseif bid == Self.BID_DISENCHANT and not self.disenchant then
        return false
    -- Can't bid if "Don't share" is enabled
    elseif Addon.db.profile.dontShare and Unit.IsSelf(unit) then
        return false
    -- Trying to change a bid
    elseif bid and prevBid then
        return
            -- Convert a needbeforegreed roll to a custom answer
            validating and needGreed and sameBidLevel and not prevCustomAnwer and customAnswer
            -- We can always convert a previous non-pass bid into a pass
            or bid == Self.BID_PASS and not Util.In(self.bids[unit], nil, Self.BID_PASS)
    -- Hasn't bid but could win
    elseif not prevBid and self:UnitCanWin(unit, true) then
        -- Grace period after bids become syncable
        local insideWindow = validating and self.startedBids and self.startedBids + Self.DELAY > time()

        if self.status == Self.STATUS_DONE and not insideWindow then
            -- Only non-pass bids on done rolls, and only if there are only pass bids
            return bid ~= Self.BID_PASS and Util.Tbl.CountExcept(self.bids, Self.BID_PASS) == 0
        else
            return true
        end
    end

    return false
end

-- Check if the given unit can vote on this roll
---@param unit? string
function Self:UnitCanVote(unit)
    return self.status > Self.STATUS_CANCELED and not self.winner and Session.IsOnCouncil(unit or "player")
end

-- Check if the unit could have interest in the roll
---@param unit string
function Self:UnitIsInvolved(unit, eligible)
    unit = Unit.Name(unit or "player")
    return self.owner == unit or self.item.owner == unit or self.winner == unit
        or self.bids[unit]
        or self:UnitCanVote(unit)
        or self.item:IsLoaded() and self:UnitIsEligible(unit, eligible or Item.ELIGIBLE)
end

-- Check if the roll can be started
function Self:CanBeStarted()
    return self.isOwner and self.status == Self.STATUS_PENDING
end

---@param roll Roll
local RunningFn = function (roll)
    return roll.isOwner and roll.status == Self.STATUS_RUNNING and (not roll:IsNeedGreedRoll() or roll.needGreedNum == 1)
end

-- Check if we can run a roll
function Self:CanBeRun(manually)
    if self.status ~= Self.STATUS_PENDING then
        return false
    elseif self:IsNeedGreedRoll() and self.needGreedNum > 1 then
        return false
    elseif manually then
        return true
    elseif self.timers.schedule then
        return false
    elseif not self:GetOwnerAddon() then
        return true
    elseif not self.isOwner then
        return false
    end

    local ml = Session.GetMasterlooter()
    local waitForOwner = Util.Check(ml, Session.rules.allowKeep, Addon.db.profile.chillMode)
    local startManually = ml and Addon.db.profile.masterloot.rules.startManually
    local startLimit = ml and Addon.db.profile.masterloot.rules.startLimit or 0

    if waitForOwner and self.item.owner and not self.bids[self.item.owner] then
        return false
    elseif startManually and not (startLimit > 0 and Self.startedManually) then
        return false
    elseif startLimit > 0 and Util.Tbl.CountFn(Addon.rolls, RunningFn) >= startLimit then
        return false
    else
        return true
    end
end

-- Check if we can restart a roll
function Self:CanBeRestarted()
    return self.isOwner and self.item.owner
        and Util.In(self.status, Self.STATUS_CANCELED, Self.STATUS_DONE)
        and (not self.traded or UnitIsUnit(self.traded, self.item.owner))
end

-- Check if the roll is handled by a masterlooter
function Self:HasMasterlooter()
    return self.owner ~= self.item.owner or self.owner == Session.GetMasterlooter(self.item.owner)
end

-- Check if we are the masterlooter for this roll
function Self:IsMasterlooter()
    return self.isOwner and self:HasMasterlooter()
end

-- Check if the roll is from an addon user
function Self:GetOwnerAddon(exclCompAddons)
    return self.isOwner or Util.Bool(self.owner) and Addon:UnitIsTracking(self.owner, not exclCompAddons)
end

-- Check if the player has to take an action to complete the roll (e.g. trade)
---@return string?
function Self:GetActionRequired()
    if self.traded then return end

    -- Trade item we own or won
    if self.item.isOwner and self.winner or self.isWinner then
        return Self.ACTION_TRADE
    end

    if self.winner or Util.Tbl.CountExcept(self.bids, Self.BID_PASS) == 0 then return end

    -- Award or vote
    if self.status == Self.STATUS_DONE then
        if self:CanBeAwarded(true) then
            return Self.ACTION_AWARD
        elseif self:UnitCanVote() and not self.vote then
            return Self.ACTION_VOTE
        end
    end

    -- Wait or ask
    if self.item.isOwner or self.bid and self.bid ~= Self.BID_PASS then
        return (self:IsNeedGreedRoll() or self:GetOwnerAddon()) and Self.ACTION_WAIT or Self.ACTION_ASK
    end
end

-- Get the target for actions (e.g. trade, whisper)
---@return string?
function Self:GetActionTarget()
    local action = self:GetActionRequired()
    if action == Self.ACTION_TRADE then
        return Util.Check(self.item.isOwner, self.winner, self.item.owner)
    elseif Util.In(action, Self.ACTION_ASK, Self.ACTION_WAIT) then
        return self.owner
    end
end

-- Check if the roll is pending or running
---@param validate? boolean
function Self:IsActive(validate)
    return self.status == Self.STATUS_RUNNING or self.status == Self.STATUS_PENDING and (not validate or self:Validate())
end

-- Check if the roll is running or recently ended
---@param timeout number
function Self:IsRecent(timeout)
    return self.status == Self.STATUS_RUNNING or timeout ~= false and self.status == Self.STATUS_DONE and self.ended + (timeout or Self.TIMEOUT_RECENT) >= time()
end

-- Get the name for a bid
---@paran roll Roll
---@param bidOrUnit? number|string
function Self.GetBidName(roll, bidOrUnit)
    local bid = type(bidOrUnit) == "string" and roll.bids[Unit.Name(bidOrUnit)] or bidOrUnit ---@cast bid -string
    if not bid then return "-" end

    local ml = Session.GetMasterlooter()
    local answer, answers = Self.GetAnswerValue(bid), Session.rules["answers" .. floor(bid)]

    if not Session.IsMasterlooter(roll.owner or ml) or not answers or not answers[answer] or Util.In(answers[answer], Self.ANSWER_NEED, Self.ANSWER_GREED) then
        return L["ROLL_BID_" .. floor(bid)]
    else
        return answers[answer]
    end
end

---@param roll Roll
---@param bid number
---@param fromUnit string
---@return number
function Self.GetBidValue(roll, bid, fromUnit, isImport)
    if isImport then return bid end

    local ml = Session.GetMasterlooter()
    local answers = Session.rules["answers" .. floor(bid)] --[=[@as string[]]=]

    -- Bids from outside our ML group
    if not Session.SameMasterlooter(fromUnit) then bid = floor(bid) end

    -- Bids to rolls from our ML
    if bid == floor(bid) and answers and Session.IsMasterlooter(roll.owner or ml) then
        local i = Util.Tbl.Find(answers, bid == Self.BID_NEED and Self.ANSWER_NEED or Self.ANSWER_GREED)
        if i then bid = bid + (i / 10) end
    end

    return bid
end

function Self.GetAnswerValue(bid)
    return 10 * bid - 10 * floor(bid)
end

-- Compare two bids, returns -1 for a < b, 0 for a == b and 1 for a > b, lower meaning higher priority
function Self.CompareBids(a, b)
    if a == nil or b == nil or floor(a) == floor(b) then
        return Util.Compare(a, b)
    end

    a, b = floor(a), floor(b)
    for _,v in ipairs(Self.BIDS) do
        if a == v then return -1 elseif b == v then return 1 end
    end

    return 0
end

-------------------------------------------------------
--                      Events                       --
-------------------------------------------------------

-- Check if we can start other pending rolls after status updates
Self.OnStatus = Util.Fn.Debounce(function()
    for i, roll in pairs(Addon.rolls) do
        if roll.isOwner and roll:CanBeRun() and roll:Validate() then
            roll:Start()
        end
    end
end, 0)
Addon:RegisterMessage(Self.EVENT_STATUS, function(_, roll)
    if roll.isOwner then Self.OnStatus() end
end)