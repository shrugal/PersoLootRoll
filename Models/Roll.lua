---@type string
local Name = ...
---@type Addon
local Addon = select(2, ...)
---@type L
local L = LibStub("AceLocale-3.0"):GetLocale(Name)
local CB = LibStub("CallbackHandler-1.0")
local Comm, GUI, Item, Session, Trade, Unit, Util = Addon.Comm, Addon.GUI, Addon.Item, Addon.Session, Addon.Trade, Addon.Unit, Addon.Util
---@class Roll
---@field item Item
local Self = Addon.Roll

local Meta = { __index = Self }

-- Default schedule delay
Self.DELAY = 1
-- Clear rolls older than this
Self.CLEAR = 1200
-- Base timeout
Self.TIMEOUT = 20
-- Timeout increase per item
Self.TIMEOUT_PER_ITEM = 5
-- How much longer should rolls be when in chill mode
Self.TIMEOUT_CHILL_MODE = 2
-- Seconds after a roll ended when it's still considered "recently" ended
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
Self.BID_NEED = 1
Self.BID_GREED = 2
Self.BID_DISENCHANT = 3
Self.BID_PASS = 4
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

--- Fires when a roll is cleared
-- @table roll The roll
Self.EVENT_CLEAR = "PLR_ROLL_CLEAR"

--- Fires when a roll starts
-- @table roll    The roll
-- @int   started The time when it started
Self.EVENT_START = "PLR_ROLL_START"

--- Fires when a roll is restarted
-- @table roll The roll
Self.EVENT_RESTART = "PLR_ROLL_RESTART"

--- Fires when a roll is canceled
-- @table roll The roll
Self.EVENT_CANCEL = "PLR_ROLL_CANCEL"

--- Fires when the player advertises a roll in chat
-- @table roll     The roll
-- @bool  manually Whether it was triggered manually by the player (e.g. through the UI)
-- @bool  silent   Whether a status update was send afterwards
Self.EVENT_ADVERTISE = "PLR_ROLL_ADVERTISE"

--- Fires when someone bids on a roll
-- @table     roll       The roll
-- @int|float bid        The bid value
-- @string    fromUnit   The unit the bid came from
-- @int       rollResult The random roll result (1-100)
-- @bool      isImport   Whether it was an import received from the roll owner
Self.EVENT_BID = "PLR_ROLL_BID"

--- Fires when someone votes on a roll
-- @table     roll       The roll
-- @int|float bid        The unit being voted for
-- @string    fromUnit   The unit the vote came from
-- @bool      isImport   Whether it was an import received from the roll owner
Self.EVENT_VOTE = "PLR_ROLL_VOTE"

--- Fires when a roll ends
-- @table roll  The roll
-- @int   ended The time when it ended
Self.EVENT_END = "PLR_ROLL_END"

--- Fires when a roll winner (or no winner) is picked
-- @table  roll       The roll
-- @string winner     The winner (optional)
-- @string prevWinner The previous winner (optional)
Self.EVENT_AWARD = "PLR_ROLL_AWARD"

--- Fires when the roll item is traded
-- @table  roll   The roll
-- @string target The unit being traded to
Self.EVENT_TRADE = "PLR_ROLL_TRADE"

--- Fires when a roll's visibility in GUIs is changed
-- @table roll   The roll
-- @bool  hidden Whether the roll is now hidden or not
Self.EVENT_TOGGLE = "PLR_ROLL_TOGGLE"

--- Fires when a whisper message is received from the owner/winner
-- @table  roll The roll
-- @string msg  The message
-- @string unit The sender
Self.EVENT_CHAT = "PLR_ROLL_CHAT"

--- Fires whenever a roll status changes
-- @table  roll   The roll
-- @number status The new status
-- @number prev   The previous status
Self.EVENT_STATUS = "PLR_ROLL_STATUS"

--- Catchall event that fires for all events in Self.EVENTS
-- @string event The original event
-- @param  ...   The original event parameters
Self.EVENT_CHANGE = "PLR_ROLL_CHANGE"

Self.EVENTS = { Self.EVENT_ADD, Self.EVENT_CLEAR, Self.EVENT_START, Self.EVENT_RESTART, Self.EVENT_CANCEL, Self.EVENT_ADVERTISE, Self.EVENT_BID, Self.EVENT_VOTE, Self.EVENT_END, Self.EVENT_AWARD, Self.EVENT_TRADE, Self.EVENT_TOGGLE, Self.EVENT_CHAT, Self.EVENT_STATUS }

local changeFn = function(...) Addon:SendMessage(Self.EVENT_CHANGE, ...) end
for _, e in pairs(Self.EVENTS) do Addon:RegisterMessage(e, changeFn) end

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

-- Get a roll by id or prefixed id
---@param id integer
---@return Roll|nil
function Self.Get(id)
    return id and Addon.rolls[Self.IsPlrId(id) and Self.FromPlrId(id) or id] or nil
end

-- Find a roll
---@param ownerId integer?
---@param owner string?
---@param item Item|string|number
---@param itemOwnerId integer
---@param itemOwner string
---@param status integer?
function Self.Find(ownerId, owner, item, itemOwnerId, itemOwner, status)
    owner = Unit.Name(owner == true and "player" or owner) or owner
    itemOwner = Unit.Name(itemOwner == true and "player" or itemOwner) or itemOwner

    -- Shortcut for our own items
    if ownerId and Unit.IsSelf(owner or "player") and not (item or itemOwnerId or itemOwner or status) then
        return Addon.rolls[ownerId]
    end

    local t = type(item)
    if t == "table" then
        if not item.infoLevel then
            item = Item.FromLink(item.link, item.owner):GetBasicInfo()
        end
        itemOwner = itemOwner or item.owner
    elseif t == "string" then
        item = Item.GetInfo(item, "link") or item
    end

    for id, roll in pairs(Addon.rolls) do
        if (
            owner and ownerId and owner == roll.owner and ownerId == roll.ownerId and (not itemOwner or not roll.item.owner or itemOwner == roll.item.owner)
                or itemOwner and itemOwnerId and itemOwner == roll.item.owner and itemOwnerId == roll.itemOwnerId and (not owner or not roll.owner or owner == roll.owner)
                or (
                (not owner or roll.owner == owner)
                    and (not ownerId or roll.ownerId == ownerId)
                    and (not itemOwner or roll.item.owner == itemOwner)
                    and (not itemOwnerId or roll.itemOwnerId == itemOwnerId)
                )
            )
            and (not status or roll.status == status)
            and (
            not item
                or t == "table" and item.link == roll.item.link
                or t == "number" and item == roll.item.id
                or t == "string" and item == roll.item.link
            ) then
            return roll
        end
    end
end

-- Shortcut to search rolls by key-value pairs
---@return Roll
function Self.FindWhere(...)
    return Util.Tbl.FirstWhere(Addon.rolls, ...)
end

-- Create and add a roll to the list
---@param item Item|string
---@param owner string?
---@param ownerId integer?
---@param itemOwnerId integer?
---@param timeout integer?
---@param disenchant boolean?
function Self.Add(item, owner, ownerId, itemOwnerId, timeout, disenchant)
    owner = Unit.Name(owner or "player")
    local isOwner = Unit.IsSelf(owner)

    -- Create the roll entry
    local roll = setmetatable({
        created = time(),
        isOwner = isOwner,
        item = Item.FromLink(item, owner),
        owner = owner,
        ownerId = ownerId,
        itemOwnerId = itemOwnerId,
        timeout = timeout or Self.CalculateTimeout(owner, true),
        disenchant = Util.Default(disenchant, isOwner and Util.Check(Session.GetMasterlooter(), Addon.db.profile.masterloot.rules.allowDisenchant, Addon.db.profile.allowDisenchant)),
        status = Self.STATUS_PENDING,
        bids = {},
        rolls = {},
        votes = {},
        timers = {},
        whispers = 0,
        shown = nil,
        hidden = nil,
        posted = nil,
        traded = nil
    }, Meta)

    -- Add it to the list
    roll.id = Addon.rolls.Add(roll)

    -- Set ownerId/itemOwnerId
    if roll.isOwner then
        roll.ownerId = roll.id
    end
    if roll.item.isOwner then
        roll.itemOwnerId = roll.id
    end

    Addon:Debug("Roll.Add", roll)

    Addon:SendMessage(Self.EVENT_ADD, roll)

    return roll
end

-- Process a roll update message
---@param data table
---@param unit string
function Self.Update(data, unit)
    local ml = Session.GetMasterlooter()

    -- Get the roll
    local created = false
    local roll = Self.Find(data.ownerId, data.owner, data.item, data.itemOwnerId, data.item.owner)
        or ml and unit == ml and Self.Find(nil, nil, data.item, data.itemOwnerId, data.item.owner)

    Addon:Debug("Roll.Update", unit, data, roll)

    -- or create the roll
    if not roll then
        -- Only the item owner and our ml can create rolls
        if not (unit == data.item.owner or ml and unit == ml) then
            Addon:Debug("Roll.Update.Reject.SenderNotAllowed")
            return false
        -- Only accept items while having a masterlooter if enabled
        elseif Addon.db.profile.onlyMasterloot and not ml then
            Addon:Debug("Roll.Update.Reject.NoMasterlooter")
            return false
        end

        roll = Self.Add(Item.FromLink(data.item.link, data.item.owner, nil, nil, Util.Default(data.item.isTradable, true)), data.owner, data.ownerId, data.itemOwnerId, data.timeout, data.disenchant or nil)
        created = true

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
    end

    -- Only the roll owner or ML can send updates
    if Util.In(unit, roll.owner, ml) then
        -- Update basic
        roll.owner = data.owner or roll.owner
        roll.ownerId = data.ownerId or roll.ownerId
        roll.posted = data.posted
        roll.disenchant = data.disenchant
        roll.item.isTradable = Util.Default(data.item.isTradable, true)

        -- Update the timeout
        if data.timeout > roll.timeout then
            roll:ExtendTimeout(data.timeout)
        end

        -- Cancel the roll if the owner has canceled it
        if data.status == Self.STATUS_CANCELED then
            roll:Cancel()
        else
            roll.item:OnLoaded(function()
                -- Declare our interest if the roll is pending and our interest might have been missed
                if Self.IsActive(data) and roll:ShouldBeBidOn() and (
                    (data.item.eligible or 0) == 0
                    or not roll.declaredInterest and (roll.item:IsCollectibleMissing() or not roll.item:GetEligible("player"))
                ) then
                    roll.declaredInterest = true
                    roll.item:SetEligible("player", roll.item:GetEligible("player") or false)
                    Comm.SendData(Comm.EVENT_INTEREST, { ownerId = roll.ownerId }, roll.owner)
                end

                -- Start (or restart) the roll if the owner has started it
                if data.status < roll.status or roll.started and data.started ~= roll.started then
                    roll:Restart(data.started, data.status == Self.STATUS_PENDING)
                elseif data.status == Self.STATUS_RUNNING and roll.status < Self.STATUS_RUNNING then
                    roll:Start(data.started)
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

                    for fromUnit, unit in pairs(data.votes or {}) do
                        roll:Vote(unit, fromUnit, true)
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

        return true
        -- The winner can inform us that it has been traded, or the item owner if the winner doesn't have the addon or he traded it to someone else
    elseif roll.winner and (unit == roll.winner or unit == roll.item.owner and not Addon:UnitIsTracking(roll.winner) or data.traded ~= roll.winner) then
        roll.item:OnLoaded(function()
            -- Register when the roll has been traded
            if data.traded ~= roll.traded then
                roll:OnTraded(data.traded)
            end
        end)

        return true
    else
        return created
    end
end

-- Clear old rolls
---@param roll Roll
local clearFn = function(roll)
    if roll.status < Self.STATUS_DONE then
        roll:Cancel()
    end

    Addon.rolls[roll.id] = nil

    Addon:SendMessage(Self.EVENT_CLEAR, roll)
end
---@param self Roll
function Self.Clear(self)
    if self then
        clearFn(self)
    else
        for i, roll in pairs(Addon.rolls) do
            if roll.created + Self.CLEAR < time() then
                clearFn(roll)
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
    if slot then
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
end

-- Check for and convert from/to PLR roll id
function Self.IsPlrId(id) return id < 0 end

function Self.ToPlrId(id) return -id end

function Self.FromPlrId(id) return -id end

-------------------------------------------------------
--                     Rolling                       --
-------------------------------------------------------

-- Start a roll
---@param startedOrManually integer|boolean?
---@param silent boolean?
function Self:Start(startedOrManually, silent)
    Addon:Verbose(L["ROLL_START"], self.item.link, Comm.GetPlayerLink(self.item.owner))

    local started, manually = type(startedOrManually) == "number" and startedOrManually, type(startedOrManually) == "boolean" and startedOrManually
    Self.startedManually = Self.startedManually or self.isOwner and Addon.db.profile.masterloot.rules.startManually and manually

    self.item:OnLoaded(function()
        self.item:GetFullInfo()

        -- Check if we can start he roll
        local valid, msg = self:Validate(Self.STATUS_PENDING)
        if not valid then
            Addon:Error(msg)
        else
            -- Update eligible players if not already done so
            if self.isOwner or self.item.isOwner then
                self.item:GetEligible()
            end

            -- Run the roll
            if not self.isOwner or self:CanBeRun(manually) then
                self.started = started or time()
                self:SetStatus(Self.STATUS_RUNNING)

                Addon:SendMessage(Self.EVENT_START, self, self.started)

                if self.isTest or not (self:ShouldEnd() and self:End()) then
                    -- Schedule timer to end the roll and/or hide the frame
                    if self.timeout > 0 then
                        self.timers.bid = Addon:ScheduleTimer(Self.End, self:GetTimeLeft(), self, nil, true)
                    elseif not Addon.db.profile.chillMode then
                        self.timers.bid = Addon:ScheduleTimer(Self.HideRollFrame, self:GetTimeLeft(), self)
                    end

                    -- Let everyone know
                    self:Advertise(Util.Check(silent, false, nil), true)
                end
            end

            -- Let others know
            self:SendStatus()

            if not self.bid then
                -- Show some UI
                if self.item.isOwner or self.item:ShouldBeBidOn() then
                    if self.item.isOwner or self.status == Self.STATUS_RUNNING then
                        self:ShowRollFrame()
                    end
                    -- Bid disenchant
                elseif self.disenchant and Addon.db.profile.filter.disenchant and Unit.IsEnchanter() then
                    self:Bid(Self.BID_DISENCHANT)
                end
            end
        end
    end)

    return self
end

-- Add a roll now and start it later
function Self:Schedule()
    if not self.timers.schedule then
        self.item:GetBasicInfo()

        self.timers.schedule = Addon:ScheduleTimer(function()
            Addon:Debug("Roll.Schedule", self)

            self.timers.schedule = nil

            -- Only if it's still pending
            if self.status == Self.STATUS_PENDING then
                -- Maybe adopt the roll if ML
                if Addon.db.profile.masterloot.rules.startAll and Session.IsMasterlooter() and not (self.ownerId or Addon:UnitIsTracking(self.owner)) then
                    self:Adopt(true)
                end

                -- Start or cancel
                if self.isOwner and self.item:ShouldBeRolledFor() or not self.isOwner and self:ShouldBeBidOn() then
                    Addon:Debug("Roll.Schedule.Start")
                    self:Start()
                else
                    Addon:Debug("Roll.Schedule.Cancel", Addon.db.profile.dontShare, self.owner, self.isOwner, self.item.owner, self.item.isOwner, self.item:HasSufficientQuality(), self.item:GetBasicInfo().isEquippable, self.item:GetFullInfo().isTradable, self.item:GetNumEligible(true))
                    self:Cancel()
                end
            end
        end, Self.DELAY)
    end

    return self
end

-- Restart a roll
function Self:Restart(started, pending)
    Addon:Debug("Roll.Restart", self.id, started, pending)

    self.started = nil
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

    self:HideRollFrame()

    for i, v in pairs(self.timers) do
        Addon:CancelTimer(v)
        self.timers[i] = nil
    end

    Util.Tbl.Except(Addon.lastWhisperedRoll, self.id, true)

    self:SetStatus(Self.STATUS_PENDING)
    Addon:SendMessage(Self.EVENT_RESTART, self)

    return pending and self or self:Start(started)
end

-- Adopt a roll
function Self:Adopt(noStatus)
    self.owner, self.ownerId, self.isOwner, self.posted = UnitName("player"), self.id, true, nil
    self.item.isTradable = true

    if not noStatus then
        self:SendStatus()
    end

    return self
end

-- Bid on a roll
---@param bid number
---@param fromUnit string?
---@param roll integer?
---@param isImport boolean?
---@param silent boolean?
---@return Roll
function Self:Bid(bid, fromUnit, roll, isImport, silent)
    Addon:Debug("Roll.Bid", self.id, bid, fromUnit, roll, isImport)

    bid = bid or Self.BID_NEED
    fromUnit = Unit.Name(fromUnit or "player")
    roll = roll or self.isOwner and bid ~= Self.BID_PASS and random(100) or nil
    local fromSelf = Unit.IsSelf(fromUnit)

    -- Handle custom answers
    local answer, answers = 10 * bid - 10 * floor(bid), Session.rules["answers" .. floor(bid)]
    if bid == floor(bid) and answers and Session.IsMasterlooter(self.owner) then
        local i = Util.Tbl.Find(answers, bid == Self.BID_NEED and Self.ANSWER_NEED or Self.ANSWER_GREED)
        if i then bid, answer = bid + (i / 10), i end
    end

    -- Hide the roll frame
    if fromSelf then
        self:HideRollFrame()
    end

    if self:ValidateBid(bid, fromUnit, roll, isImport, answer, answers) then
        self.bids[fromUnit] = bid
        self.rolls[fromUnit] = roll

        if fromSelf then
            self.bid = bid
        end

        Addon:SendMessage(Self.EVENT_BID, self, bid, fromUnit, roll, isImport)

        -- Let everyone know
        Comm.RollBid(self, bid, fromUnit, roll, isImport, silent)

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
    end

    return self
end

-- Vote for a unit
---@param vote string?
---@param fromUnit string?
---@param isImport boolean?
---@return Roll
function Self:Vote(vote, fromUnit, isImport)
    Addon:Debug("Roll.Vote", self.id, vote, fromUnit, isImport)

    vote = Unit.Name(vote)
    fromUnit = Unit.Name(fromUnit or "player")

    if self:ValidateVote(vote, fromUnit, isImport) then
        self.votes[fromUnit] = vote

        if Unit.IsSelf(fromUnit) then
            self.vote = vote
        end

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

    -- The item owner voted need
    if self.isOwner and allowKeep and floor(self.bids[self.item.owner] or 0) == Self.BID_NEED then
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
    for unit, interest in pairs(self.item:GetEligible()) do
        if not self.bids[unit] and (interest or ml or Addon.db.profile.awardSelf) then
            return false
        end
    end

    return true
end

-- End a roll
---@param winner boolean|string?
---@param cleanup boolean?
---@param force boolean?
function Self:End(winner, cleanup, force)
    Addon:Debug("Roll.End", self.id, winner, cleanup, force)

    winner = winner and winner ~= true and Unit.Name(winner) or winner
    local sendStatus = false

    -- Hide UI elements etc.
    if cleanup then
        for i, timer in Util.Each("schedule", "bid") do
            if self.timers[timer] then
                Addon:CancelTimer(self.timers[timer])
                self.timers[timer] = nil
            end
        end

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

        -- Update status
        self:SetStatus(Self.STATUS_DONE)
        self.ended = time()
        self.started = self.started or time()

        Addon:SendMessage(Self.EVENT_END, self, self.ended)
        sendStatus = true
    end

    -- Determine a winner
    if not self.winner or force then
        if self.isOwner and (not winner or winner == true) then
            if (not Session.GetMasterlooter() or Session.rules.allowKeep) and floor(self.bids[self.item.owner] or 0) == Self.BID_NEED then
                -- Give it to the item owner
                winner = self.item.owner
            elseif winner == true or not (Addon.db.profile.awardSelf or Session.IsMasterlooter()) then
                -- Pick a winner now
                winner = self:DetermineWinner()
            elseif Session.IsMasterlooter() and Addon.db.profile.masterloot.rules.autoAward and not self.timers.award then
                -- Schedule a timer to pick a winner
                local base = Addon.db.profile.masterloot.rules.autoAwardTimeout or Self.TIMEOUT
                local perItem = Addon.db.profile.masterloot.rules.autoAwardTimeoutPerItem or Self.TIMEOUT_PER_ITEM
                self.timers.award = Addon:ScheduleTimer(Self.End, base + Util.GetNumDroppedItems() * perItem, self, true)
            end
        end

        local prevWinner = self.winner

        -- Set winner
        if not Util.In(winner, self.winner, true) then
            self.winner = winner
            self.isWinner = Unit.IsSelf(self.winner)

            if self.winner then
                -- Cancel auto award timer
                if self.timers.award then
                    Addon:CancelTimer(self.timers.award)
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
    if sendStatus then self:SendStatus() end

    return self
end

-- Cancel a roll
---@param silent boolean?
function Self:Cancel(silent)
    if self.status == Self.STATUS_CANCELED then return end
    Addon:Verbose(L["ROLL_CANCEL"], self.item.link, Comm.GetPlayerLink(self.item.owner))

    -- Cancel a pending timer
    for i, v in pairs(self.timers) do
        Addon:CancelTimer(v)
        self.timers[i] = nil
    end

    -- Update status
    self:SetStatus(Self.STATUS_CANCELED)

    -- Hide the roll frame
    self:HideRollFrame()

    -- Let everyone know
    Addon:SendMessage(Self.EVENT_CANCEL, self)
    if not silent then
        self:SendStatus()
    end

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
local fn = function(roll) return roll.isOwner and roll:IsActive(true) end
---@param status integer
function Self:SetStatus(status)
    local prev = self.status
    self.status = status

    if self.status ~= prev then
        Self.startedManually = Self.startedManually and Util.Tbl.FindFn(Addon.rolls, fn) ~= nil

        Addon:SendMessage(Self.EVENT_STATUS, self, self.status, prev)
    end
end

-- Check if we can start other pending rolls after status updates
local fn = Util.Fn.Debounce(function()
    for i, roll in pairs(Addon.rolls) do
        if roll.isOwner and roll:CanBeRun() and roll:Validate() then
            roll:Start()
        end
    end
end, 0)
Addon:RegisterMessage(Self.EVENT_STATUS, function(_, roll)
    if roll.isOwner then fn() end
end)

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
    if Addon.DEBUG or self.isTest then return true end

    if not self.item.isTradable then
        return false, L["ERROR_ITEM_NOT_TRADABLE"]
    elseif not IsInGroup() then
        return false, L["ERROR_NOT_IN_GROUP"]
    elseif not UnitExists(self.owner) or not Unit.InGroup(self.owner) then
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
---@param answer integer
function Self:ValidateBid(bid, fromUnit, roll, isImport, answer, answers)
    local valid, msg = self:Validate(fromUnit)
    if not valid then
        Addon:Error(msg)
        -- Don't validate imports any further
    elseif isImport then
        return true
        -- Check if it's a valid bid
    elseif not Util.Tbl.Find(Self.BIDS, floor(bid)) or Session.GetMasterlooter(self.owner) and answer > 0 and not (answers and answers[answer]) then
        if Unit.IsSelf(fromUnit) then
            Addon:Error(L["ERROR_ROLL_BID_UNKNOWN_SELF"])
        else
            Addon:Verbose(L["ERROR_ROLL_BID_UNKNOWN_OTHER"], fromUnit, self.item.link)
        end
        -- Check if the unit can bid
    elseif not self:UnitCanBid(fromUnit, bid) then
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
---@param fromUnit string?
---@param isImport boolean?
function Self:ValidateVote(vote, fromUnit, isImport)
    local valid, msg = self:Validate(vote, fromUnit)
    if not valid then
        Addon:Error(msg)
        -- Don't validate imports any further
    elseif isImport then
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

-- Get the loot frame for a loot id
---@return Frame|nil
---@return integer|nil
function Self:GetRollFrame()
    local id, frame = self:GetPlrId()

    for i = 1, NUM_GROUP_LOOT_FRAMES do
        frame = _G["GroupLootFrame" .. i]
        if frame.rollID == id then
            return frame, i
        end
    end
end

-- Show the roll frame
function Self:ShowRollFrame()
    local frame = self:GetRollFrame()
    if not frame or not frame:IsShown() then
        self.shown = false

        if Addon.db.profile.ui.showRollFrames then
            GroupLootFrame_OpenNewFrame(self:GetPlrId(), self:GetRunTime())
            self.shown = self:GetRollFrame() ~= nil

            -- TODO: This is required to circumvent a bug in ElvUI
            if self.shown then
                Util.Tbl.List(GroupLootContainer.rollFrames)
                GroupLootContainer_Update(GroupLootContainer)
            end
        else
            self.shown = true
        end
    end
end

-- Hide the roll frame
function Self:HideRollFrame()
    local frame = self:GetRollFrame()
    if frame then
        ---@diagnostic disable-next-line: redundant-parameter
        GroupLootContainer_RemoveFrame(GroupLootContainer, frame)

        -- TODO: This is required to circumvent a bug in ElvUI
        Util.Tbl.List(GroupLootContainer.rollFrames)
        GroupLootContainer_Update(GroupLootContainer)
    end
end

-- Show the alert frame for winning an item
function Self:ShowAlertFrame()
    if self.item:GetBasicInfo().isEquippable then
        -- itemLink, quantity, rollType, roll, specID, isCurrency, showFactionBG, lootSource, lessAwesome, isUpgraded, wonRoll, showRatedBG, plrId
        GUI.LootAlertSystem:AddAlert(self.item.link, 1, nil, nil, nil, false, false, nil, false, false, true, false, self.id)
    end
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
    local c = ChatTypeInfo[Unit.IsSelf(unit) and "WHISPER_INFORM" or "WHISPER"] or Util.Tbl.EMPTY
    c = Util.Str.Color(c.r, c.g, c.b)
    msg = ("|c%s[|r%s|c%s]: %s|r"):format(c, Unit.ColoredShortenedName(unit), c, msg)

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
function Self:Advertise(force, noStatus)
    local manually, silent = force == true, force == false

    if manually and self.posted == -1 then
        self.posted = nil
    elseif silent and not self.posted then
        self.posted = -1
    end

    if not self:ShouldAdvertise(manually) then
        return false
    end

    self:ExtendTimeLeft()

    -- Get the next free roll slot
    local concise, slot = self:ShouldBeConcise(), nil
    for i = concise and 0 or 1, 49 do
        if not Self.FindWhere("status", Self.STATUS_RUNNING, "posted", i) then
            slot = i
            break
        end
    end

    if slot then
        self.posted = slot
        Comm.RollAdvertise(self)

        if not noStatus then
            self:SendStatus()
        end

        Addon:SendMessage(Self.EVENT_ADVERTISE, self, force, noStatus)

        return true
    else
        return false
    end
end

-- Send the roll status to others
---@param noCheck boolean?
---@param target string?
---@param full boolean?
function Self:SendStatus(noCheck, target, full)
    if (noCheck or self.isOwner) and not self.isTest then
        local data = Util.Tbl.New()
        data.owner = Unit.FullName(self.owner)
        data.ownerId = self.ownerId
        data.itemOwnerId = self.itemOwnerId
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
            "eligible", self.item:GetNumEligible(true, true)
        )

        if full then
            if Addon.db.profile.bidPublic or Session.rules.bidPublic or Session.IsOnCouncil(target) then
                data.bids = Util.Tbl.MapKeys(self.bids, Unit.FullName)
                data.rolls = Util.Tbl.MapKeys(self.rolls, Unit.FullName)
            end

            if Session.rules.votePublic or Session.IsOnCouncil(target) then
                data.votes = Util(self.votes):MapKeys(Unit.FullName):Map(Unit.FullName)()
            end
        end

        Comm.SendData(Comm.EVENT_ROLL_STATUS, data, target or Comm.TYPE_GROUP)

        Util.Tbl.Release(true, data)
    end
end

-------------------------------------------------------
--                      Timing                       --
-------------------------------------------------------

-- Get the total runtime for a roll
---@param real boolean?
function Self:GetRunTime(real)
    if self.timeout == 0 and (real or Addon.db.profile.chillMode) then
        return 0
    else
        return max(0, self.timeout == 0 and self:CalculateTimeout(real) or self.timeout + (real and 0 or Self.DELAY))
    end
end

-- Get the time that is left on a roll
---@param real boolean?
function Self:GetTimeLeft(real)
    if self.status ~= Self.STATUS_RUNNING and real or self.timeout == 0 and (real or Addon.db.profile.chillMode) then
        return 0
    else
        return max(0, (self.started and self.started - time() or 0) + self:GetRunTime(real))
    end
end

-- Extend the timeout to at least the given # of seconds
---@param to number
function Self:ExtendTimeout(to)
    if self.status < Self.STATUS_DONE and self.timeout > 0 and self.timeout < to then
        -- Extend a running timer
        if self.status == Self.STATUS_RUNNING then
            self.timers.bid = Addon:ExtendTimerBy(self.timers.bid, to - self.timeout)
        end

        self.timeout = to

        -- Update the roll frame
        local frame = self:GetRollFrame()
        if frame then
            frame.Timer:SetMinMaxValues(0, self.timeout)
        end

        self:SendStatus()
    end
end

-- Extend the remaining time to at least the given # of seconds
---@param to number?
function Self:ExtendTimeLeft(to)
    to = to or Self.TIMEOUT
    local left = self:GetTimeLeft(true)

    if self.status < Self.STATUS_DONE and left < to then
        self:ExtendTimeout(self.timeout + (to - left))
    end
end

-- Calculate the correct timeout
---@param selfOrOwner Roll|string
---@param real boolean?
function Self.CalculateTimeout(selfOrOwner, real)
    local owner = type(selfOrOwner) == "table" and selfOrOwner.owner or selfOrOwner
    local ml = Session.GetMasterlooter()
    local chill = Addon.db.profile.chillMode
    local timeout

    if not ml and chill and (Unit.IsSelf(owner) and Addon.db.profile.awardSelf or not Addon:UnitIsTracking(owner)) then
        timeout = 0
    else
        local base, perItem = ml and Session.rules.timeoutBase or Self.TIMEOUT, ml and Session.rules.timeoutPerItem or Self.TIMEOUT_PER_ITEM
        timeout = (base + Util.GetNumDroppedItems() * perItem) * (not ml and chill and Self.TIMEOUT_CHILL_MODE or 1)
    end

    if not real and not chill and timeout == 0 then
        timeout = Self.TIMEOUT + Util.GetNumDroppedItems() * Self.TIMEOUT_PER_ITEM
    end

    return timeout
end

-------------------------------------------------------
--                      Helper                       --
-------------------------------------------------------

-- Check if we should bid on the roll
---@return boolean
function Self:ShouldBeBidOn()
    return self.item:ShouldBeBidOn() or self.disenchant and Addon.db.profile.filter.disenchant and Unit.IsEnchanter()
end

-- Check if the given unit is eligible
---@param unit string
---@param checkInterest boolean
---@return boolean
function Self:UnitIsEligible(unit, checkInterest)
    if not checkInterest and not self:HasMasterlooter() and Unit.IsUnit(unit, self.owner) then
        return true
    else
        local val = self.item:GetEligible(unit or "player") --[[@as boolean]]
        if checkInterest then return val else return val ~= nil end
    end
end

-- Check if the roll can still be won
function Self:CanBeWon(includeDone)
    return not self.traded and (self:IsActive() or includeDone and self.status == Self.STATUS_DONE and not self.winner)
end

-- Check if the given unit can win this roll
---@param unit string
function Self:UnitCanWin(unit, includeDone, checkInterest)
    return self:CanBeWon(includeDone) and self:UnitIsEligible(unit, checkInterest)
end

-- Check if we can still award the roll
function Self:CanBeAwarded(includeDone)
    return self.isOwner and self:CanBeWon(includeDone)
end

-- Check if we can still award the roll to the given unit
---@param unit string
---@param includeDone boolean
---@param checkInterest boolean?
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
---@param unit string
---@param bid integer?
---@param checkInterest boolean?
function Self:UnitCanBid(unit, bid, checkInterest)
    unit = Unit.Name(unit or "player")

    -- Obvious stuff
    if self.traded or self.status == Self.STATUS_CANCELED or not Unit.InGroup(unit) then
        return false
        -- Only need+pass for rolls from non-users
    elseif not (self:GetOwnerAddon() or Util.In(bid, nil, Self.BID_NEED, Self.BID_PASS)) then
        return false
        -- Can't bid disenchant if it's not allowed
    elseif bid == Self.BID_DISENCHANT and not self.disenchant then
        return false
        -- Can't bid if "Don't share" is enabled
    elseif Addon.db.profile.dontShare and Unit.IsSelf(unit) then
        return false
        -- We can always convert a previous non-pass bid into a pass
    elseif bid == Self.BID_PASS and not Util.In(self.bids[unit], nil, Self.BID_PASS) then
        return true
        -- Hasn't bid but could win
    elseif not self.bids[unit] and self:UnitCanWin(unit, true, checkInterest) then
        if self.status == Self.STATUS_DONE then
            -- Only non-pass bids on done rolls, and only if there are no non-pass bids
            return bid ~= Self.BID_PASS and Util.Tbl.CountExcept(self.rolls, Self.BID_PASS) == 0
        else
            return true
        end
    else
        return false
    end
end

-- Check if the given unit can vote on this roll
---@param unit string?
function Self:UnitCanVote(unit)
    return self.status > Self.STATUS_CANCELED and not self.winner and Session.IsOnCouncil(unit or "player")
end

-- Check if the unit could have interest in the roll
---@param unit string
function Self:UnitIsInvolved(unit)
    unit = Unit.Name(unit or "player")
    return self.owner == unit or self.winner == unit or self:UnitCanBid(unit) or self:UnitCanVote(unit)
end

-- Check if the roll can be started
function Self:CanBeStarted()
    return self.isOwner and self.status == Self.STATUS_PENDING
end

-- Check if we can run a roll
function Self:CanBeRun(manually)
    if self.status ~= Self.STATUS_PENDING then
        return false
    elseif manually then
        return true
    elseif self.timers.schedule then
        return false
    end

    local ml = Session.GetMasterlooter()
    local waitForOwner = Util.Check(ml, Session.rules.allowKeep, Addon.db.profile.chillMode)
    local startManually = ml and Addon.db.profile.masterloot.rules.startManually
    local startLimit = ml and Addon.db.profile.masterloot.rules.startLimit or 0

    if waitForOwner and self.itemOwnerId and not self.bids[self.item.owner] then
        return false
    elseif startManually and not (startLimit > 0 and Self.startedManually) then
        return false
    elseif startLimit > 0 and Util.Tbl.CountWhere(Addon.rolls, "isOwner", true, "status", Self.STATUS_RUNNING) >= startLimit then
        return false
    else
        return true
    end
end

-- Check if we can restart a roll
function Self:CanBeRestarted()
    return self.isOwner and Util.In(self.status, Self.STATUS_CANCELED, Self.STATUS_DONE) and (not self.traded or UnitIsUnit(self.traded, self.item.owner))
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
    return Util.Bool(self.ownerId or self.itemOwnerId) or Addon:UnitIsTracking(self.owner, not exclCompAddons)
end

-- Check if the player has to take an action to complete the roll (e.g. trade)
---@return string?
function Self:GetActionRequired()
    if not self.traded then
        if self.item.isOwner and self.winner or self.isWinner then
            return Self.ACTION_TRADE
        end
        if not self.winner and Util.Tbl.CountExcept(self.bids, Self.BID_PASS) > 0 then
            if self.status == Self.STATUS_DONE then
                if self:CanBeAwarded(true) then
                    return Self.ACTION_AWARD
                elseif self:UnitCanVote() and not self.vote then
                    return Self.ACTION_VOTE
                end
            end
            if self.item.isOwner or self.bid and self.bid ~= Self.BID_PASS then
                return self:GetOwnerAddon() and Self.ACTION_WAIT or Self.ACTION_ASK
            end
        end
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
---@param validate boolean?
function Self:IsActive(validate)
    return self.status == Self.STATUS_RUNNING or self.status == Self.STATUS_PENDING and (not validate or self:Validate())
end

-- Check if the roll is running or recently ended
---@param timeout number
function Self:IsRecent(timeout)
    return self.status == Self.STATUS_RUNNING or timeout ~= false and self.status == Self.STATUS_DONE and self.ended + (timeout or Self.TIMEOUT_RECENT) >= time()
end

-- Get the rolls id with PLR prefix
function Self:GetPlrId()
    return Self.ToPlrId(self.id)
end

-- Get the name for a bid
function Self.GetBidName(roll, bid)
    if type(bid) == "string" then
        bid = roll.bids[Unit.Name(bid)]
    end

    if not bid then
        return "-"
    else
        local bid, i, answers = floor(bid), 10 * bid - 10 * floor(bid), Session.rules["answers" .. floor(bid)]
        if i == 0 or not Session.IsMasterlooter(roll.owner) or not answers or not answers[i] or Util.In(answers[i], Self.ANSWER_NEED, Self.ANSWER_GREED) then
            return L["ROLL_BID_" .. bid]
        else
            return answers[i]
        end
    end
end
