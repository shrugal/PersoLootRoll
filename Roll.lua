local Name, Addon = ...
local L = LibStub("AceLocale-3.0"):GetLocale(Name)
local CB = LibStub("CallbackHandler-1.0")
local Comm, Events, GUI, Item, Locale, Masterloot, Trade, Unit, Util = Addon.Comm, Addon.Events, Addon.GUI, Addon.Item, Addon.Locale, Addon.Masterloot, Addon.Trade, Addon.Unit, Addon.Util
local Self = Addon.Roll

-- Default schedule delay
Self.DELAY = 1
-- Clear rolls older than this
Self.CLEAR = 600
-- Base timeout
Self.TIMEOUT = 15
-- Timeout increase per item
Self.TIMEOUT_PER_ITEM = 5
-- Seconds after a roll ended when it's still considered "recently" ended
Self.TIMEOUT_RECENT = 120

-- Status
Self.STATUS_CANCELED = -1
Self.STATUS_PENDING = 0
Self.STATUS_RUNNING = 1
Self.STATUS_DONE = 2
Self.STATUS = {Self.STATUS_CANCELED, Self.STATUS_PENDING, Self.STATUS_RUNNING, Self.STATUS_DONE}

-- Bids
Self.BID_NEED = 1
Self.BID_GREED = 2
Self.BID_DISENCHANT = 3
Self.BID_PASS = 4
Self.BIDS = {Self.BID_NEED, Self.BID_GREED, Self.BID_DISENCHANT, Self.BID_PASS}

-- Actions
Self.ACTION_TRADE = "TRADE"
Self.ACTION_AWARD = "AWARD"
Self.ACTION_VOTE = "VOTE"
Self.ACTION_ASK = "ASK"

-- Custom answers
Self.ANSWER_NEED = "NEED"
Self.ANSWER_GREED = "GREED"

-- Events
Self.EVENT_ADD = "ADD"
Self.EVENT_CLEAR = "CLEAR"
Self.EVENT_START = "START"
Self.EVENT_CANCEL = "CANCEL"
Self.EVENT_ADVERTISE = "ADVERTISE"
Self.EVENT_BID = "BID"
Self.EVENT_VOTE = "VOTE"
Self.EVENT_END = "END"
Self.EVENT_AWARD = "AWARD"
Self.EVENT_TRADE = "TRADE"
Self.EVENT_VISIBILITY = "VISIBILITY"
Self.EVENT_CHAT = "CHAT"
Self.EVENT_CHANGE = "CHANGE"
Self.EVENTS = {Self.EVENT_ADD, Self.EVENT_CLEAR, Self.EVENT_START, Self.EVENT_CANCEL, Self.EVENT_ADVERTISE, Self.EVENT_BID, Self.EVENT_VOTE, Self.EVENT_END, Self.EVENT_AWARD, Self.EVENT_TRADE, Self.EVENT_VISIBILITY, Self.EVENT_CHAT}

Self.events = CB:New(Self, "On", "Off")

local changeFn = function (...) Self.events:Fire(Self.EVENT_CHANGE, ...) end
for _,ev in pairs(Self.EVENTS) do
    Self:On(ev, changeFn)
end

-- Get a roll by id or prefixed id
function Self.Get(id)
    return id and Addon.rolls[Self.IsPlrId(id) and Self.FromPlrId(id) or id] or nil
end

-- Get a roll by id and owner
function Self.Find(ownerId, owner, item, itemOwnerId, itemOwner)
    owner = Unit.Name(owner or "player")
    local id
    
    -- It's our own item
    if UnitIsUnit(owner, "player") then
        id = ownerId
    end
    
    -- Search by owner id and owner
    if not id and ownerId and owner then
        id = Util.TblFindWhere(Addon.rolls, "ownerId", ownerId, "owner", owner)
    end

    -- Search by item owner id
    if not id and itemOwnerId and itemOwner then
        id = Util.TblFindWhere(Addon.rolls, {itemOwnerId = itemOwnerId, item = {owner = itemOwner}}, true)
    end

    -- Search by owner and link/id
    if not id and owner and item then
        local t = type(item)
        if t == "table" and not item.infoLevel then
            item = Item.FromLink(item.link, item.owner):GetBasicInfo()
        end

        id = Util.TblSearch(Addon.rolls, function (roll)
            return  (roll.owner == owner or not (roll.owner and owner))
                and (roll.item.owner == (itemOwner or item.owner) or not (roll.item.owner and (itemOwner or item.owner)))
                and (roll.ownerId == ownerId or not (roll.ownerId and ownerId))
                and (roll.itemOwnerId == itemOwnerId or not (roll.itemOwnerId and itemOwnerId))
                and (
                       t == "table" and roll.item.link == item.link
                    or t == "number" and item == roll.item.id
                    or t == "string" and item == roll.item.link
                )
        end)
    end

    return id and Addon.rolls[id]
end

-- Find rolls that the given unit can win from us
function Self.ForUnit(unit, includeDone, k)
    unit = Unit.Name(unit)
    return Util.TblCopyFilter(Addon.rolls, function (roll)
        return roll:CanBeAwardedTo(unit, includeDone)
    end, k)
end

-- Add a roll to the list
function Self.Add(item, owner, timeout, ownerId, itemOwnerId)
    owner = Unit.Name(owner or "player")
    item = Item.FromLink(item, owner)

    -- Create the roll entry
    local roll = {
        created = time(),
        isOwner = UnitIsUnit(owner, "player"),
        item = item,
        owner = owner,
        ownerId = ownerId,
        itemOwnerId = itemOwnerId,
        timeout = timeout or Self.GetTimeout(),
        status = Self.STATUS_PENDING,
        bids = {},
        rolls = {},
        votes = {},
        whispers = 0,
        shown = nil,
        hidden = nil,
        posted = nil,
        traded = nil
    }
    setmetatable(roll, {__index = Self})

    -- Add it to the list
    roll.id = Addon.rolls.Add(roll)

    -- Set owner id if we are the owner
    if roll.isOwner then
        roll.ownerId = roll.id
    end
    if roll.item.isOwner then
        roll.itemOwnerId = roll.id
    end

    Self.events:Fire(Self.EVENT_ADD, roll)

    return roll
end

-- Process a roll update message
function Self.Update(data, unit)
    -- Get or create the roll
    local roll = Self.Find(data.ownerId, data.owner, data.item, data.itemOwnerId, data.item.owner)
    if not roll then
        local ml = Masterloot.GetMasterlooter()

        -- Only the item owner or his/her masterlooter can create rolls
        if not Util.In(unit, data.item.owner, Masterloot.GetMasterlooter(data.item.owner)) then
            return
        -- Only accept items from our masterlooter if enabled
        elseif Addon.db.profile.onlyMasterloot and not (ml and ml == data.owner) then
            return
        end

        roll = Self.Add(Item.FromLink(data.item.link, data.item.owner), data.owner, data.timeout, data.ownerId, data.itemOwnerId)

        if roll.isOwner then roll.item:OnLoaded(function ()
            if roll.item:ShouldBeRolledFor() or roll.item:ShouldBeBidOn() then
                roll:Start()
            elseif roll.item.isEquippable then
                roll:Schedule():SendStatus()
            else
                roll:Cancel()
            end
        end) end
    end

    -- Only the roll owner can send updates
    if unit == roll.owner then
        roll.owner = data.owner or roll.owner
        roll.ownerId = data.ownerId or roll.ownerId
        roll.posted = data.posted

        -- Update the timeout
        if data.timeout > roll.timeout then
            roll:ExtendTimeout(data.timeout)
        end
        
        -- Cancel the roll if the owner has canceled it
        if data.status == Self.STATUS_CANCELED and roll.status ~= Self.STATUS_CANCELED then
            roll:Cancel()
        else roll.item:OnLoaded(function ()
            -- Declare our interest if the roll is pending
            if data.status == Self.STATUS_PENDING and roll.item:ShouldBeBidOn() then
                roll.item:SetEligible("player")
                Comm.SendData(Comm.EVENT_INTEREST, {ownerId = roll.ownerId}, roll.owner)
            else
                -- Start (or restart) the roll if the owner has started it
                if data.status >= Self.STATUS_RUNNING then
                    if roll.status < Self.STATUS_RUNNING then
                        roll:Start(data.started)
                    elseif data.status == Self.STATUS_RUNNING and roll.status > Self.STATUS_RUNNING or data.started ~= roll.started then
                        roll:Restart(data.started)
                    end
                end

                -- Import bids
                if data.bids and next(data.bids) then
                    roll.bid = nil
                    wipe(roll.bids)

                    for fromUnit,bid in pairs(data.bids or {}) do
                        roll:Bid(bid, fromUnit, true)
                    end
                end

                -- Import votes
                if data.votes and next(data.votes) then
                    roll.vote = nil
                    wipe(roll.votes)

                    for fromUnit,unit in pairs(data.votes or {}) do
                        roll:Vote(unit, fromUnit, true)
                    end
                end
                
                -- End the roll if the owner has ended it
                if data.status >= Self.STATUS_DONE and roll.status < Self.STATUS_DONE or data.winner ~= roll.winner then
                    roll:End(data.winner)
                end

                -- Register when the roll has been traded
                if data.traded ~= roll.traded then
                    roll:OnTraded(data.traded)
                end
            end
        end) end
    -- The winner can inform us that it has been traded, or the item owner if the winner doesn't have the addon or he traded it to someone else
    elseif roll.winner and (unit == roll.winner or unit == roll.item.owner and not Addon:IsTracking(roll.winner) or data.traded ~= roll.winner) then
        roll.item:OnLoaded(function()
            -- Register when the roll has been traded
            if data.traded ~= roll.traded then
                roll:OnTraded(data.traded)
            end
        end)
    end

    return roll
end

-- Clear old rolls
local clearFn = function (roll)
    if roll.status  < Self.STATUS_DONE then
        roll:Cancel()
    end

    Addon.rolls[roll.id] = nil

    Self.events:Fire(Self.EVENT_CLEAR, roll)
end
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

-- Check for and convert from/to PLR roll id
function Self.IsPlrId(id) return id < 0 end
function Self.ToPlrId(id) return -id end
function Self.FromPlrId(id) return -id end

-- Calculate the optimal timeout
function Self.GetTimeout()
    local items, ml = 0, Masterloot.GetMasterlooter()
    local base, perItem = ml and Masterloot.session.timeoutBase or Self.TIMEOUT, ml and Masterloot.session.timeoutPerItem or Self.TIMEOUT_PER_ITEM

    if select(3, GetInstanceInfo()) == DIFFICULTY_DUNGEON_CHALLENGE then
        -- In M+ we get 2 items at the end of the dungeon, +1 if in time, +0.4 per keystone level above 15
        local _, level, _, onTime = C_ChallengeMode.GetCompletionInfo();
        items = 2 + (onTime and 1 or 0) + (level > 15 and math.ceil(0.4 * (level - 15)) or 0)
    else
        -- Normally we get 1 item per 5 players in the group
        items = math.ceil(GetNumGroupMembers() / 5)
    end

    return base + items * perItem
end

-- Get the name for a bid
function Self.GetBidName(roll, bid)
    if type(bid) == "string" then
        bid = roll.bids[Unit.Name(bid)]
    end

    if not bid then
        return "-"
    else
        local bid, i, answers = floor(bid), 10*bid - 10*floor(bid), Masterloot.session["answers" .. floor(bid)]
        if i == 0 or not Masterloot.IsMasterlooter(roll.owner) or not answers or not answers[i] or Util.In(answers[i], Self.ANSWER_NEED, Self.ANSWER_GREED) then
            return L["ROLL_BID_" .. bid]
        else
            return answers[i]
        end
    end
end

-------------------------------------------------------
--                     Rolling                       --
-------------------------------------------------------

-- Start a roll
function Self:Start(started)
    Addon:Verbose(L["ROLL_START"], self.item.link, Comm.GetPlayerLink(self.item.owner))

    self.item:OnLoaded(function ()
        self.item:GetFullInfo()

        -- Check if we can start he roll
        local valid, msg = self:Validate(Self.STATUS_PENDING)
        if not valid then
            Addon:Err(msg)
        else
            -- Update eligible players if not already done so
            if self.isOwner or self.item.isOwner then
                self.item:GetEligible()
            end

            -- Start the roll
            self.started = started or time()
            self.status = Self.STATUS_RUNNING

            -- Show some UI
            if self.item.isOwner or self.item:ShouldBeBidOn() then
                self:ShowRollFrame()
            end

            -- Schedule timer to end the roll and hide the frame
            self.timer = Addon:ScheduleTimer(Self.End, self:GetTimeLeft(), self, nil, true)

            -- Let everyone know
            Self.events:Fire(Self.EVENT_START, self)
            self:Advertise(false, true)
            self:SendStatus()

            -- Send message to PLH users
            if self.isOwner then
                Comm.SendPlh(self, Comm.PLH_ACTION_TRADE, self.item.link)
            end
        end
    end)

    return self
end

-- Add a roll now and start it later
function Self:Schedule()
    if self.timer then
        return
    end

    self.item:GetBasicInfo()

    self.timer = Addon:ScheduleTimer(function ()
        -- Start the roll if it hasn't been started after the waiting period
        if self.status == Self.STATUS_PENDING then
            self.timer = nil

            if self.isOwner and self.item:ShouldBeRolledFor() or not self.isOwner and self.item:ShouldBeBidOn() then
                self:Start()
            elseif self.item.isEquippable then
                self:Cancel()
            else
                self:Clear()
            end
        end
    end, Self.DELAY)

    return self
end

-- Restart a roll
function Self:Restart(started)
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
    self.status = Self.STATUS_PENDING

    wipe(self.bids)
    wipe(self.rolls)
    wipe(self.votes)

    self:HideRollFrame()

    if self.timer then
        Addon:CancelTimer(self.timer)
        self.timer = nil
    end

    return self:Start(started)
end

-- Bid on a roll
function Self:Bid(bid, fromUnit, rollOrImport)
    bid = bid or Self.BID_NEED
    fromUnit = Unit.Name(fromUnit or "player")
    local fromSelf = Unit.IsSelf(fromUnit)

    -- It might be a roll in chat or an import operation
    local rollResult, isImport = type(rollOrImport) == "number" and rollOrImport, rollOrImport == true

    -- Handle custom answers
    local answer, answers = 10*bid - 10*floor(bid), Masterloot.session["answers" .. floor(bid)]
    if bid == floor(bid) and answers and Masterloot.IsMasterlooter(self.owner) then
        local i = Util.TblFind(answers, bid == Self.BID_NEED and Self.ANSWER_NEED or Self.ANSWER_GREED)
        if i then bid, answer = bid + (i / 10), i end
    end

    -- Hide the roll frame
    if fromSelf then
        self:HideRollFrame()
    end
    
    if self:ValidateBid(bid, answer, fromUnit, isImport) then
        self.bids[fromUnit] = bid

        if rollResult then self.rolls[fromUnit] = rollResult end
        if fromSelf then self.bid = bid end        

        Self.events:Fire(Self.EVENT_BID, self, bid, fromUnit, rollOrImport)

        -- Let everyone know
        Comm.RollBid(self, bid, fromUnit, isImport)

        if self.isOwner then
            -- Check if we should end the roll or advertise to chat
            if self.status == Self.STATUS_RUNNING and not (self:ShouldEnd() and self:End()) then
                self:Advertise()
            -- Check if the winner just passed on the item
            elseif self.winner == fromUnit and not self.traded then
                self:End(nil, false, true)
            end
        end
    end

    return self
end

-- Vote for a unit
function Self:Vote(vote, fromUnit, isImport)
    vote = Unit.Name(vote)
    fromUnit = Unit.Name(fromUnit or "player")

    if self:ValidateVote(vote, fromUnit, isImport) then
        self.votes[fromUnit] = vote

        if Unit.IsSelf(fromUnit) then
            self.vote = vote
        end

        Self.events:Fire(Self.EVENT_VOTE, self, vote, fromUnit, isImport)

        -- Let everyone know
        Comm.RollVote(self, vote, fromUnit)
    end

    return self
end

-- Check if we should end the roll prematurely
function Self:ShouldEnd()
    -- We have bid and the owner doesn't have the addon
    if not self.ownerId and self.bid then
        return true
    -- Not the owner, not running or we haven't bid yet
    elseif not self.isOwner or self.status ~= Self.STATUS_RUNNING or not self.bid then
        return false
    -- We voted need on our own item
    elseif not Masterloot.GetMasterlooter() and self.item.isOwner and self.bid and floor(self.bid) == Self.BID_NEED then
        return true
    end

    -- Check if all eligible players have bid
    for unit,ilvl in pairs(self.item:GetEligible()) do
        if ilvl and not self.bids[unit] then
            return false
        end
    end

    return true
end

-- End a roll
function Self:End(winner, cleanup, force)
    if self.winner and not force then
        return self
    end

    winner = winner and winner ~= true and Unit.Name(winner) or winner
    
    -- End it if it is running
    if self.status < Self.STATUS_DONE then
        Addon:Verbose(L["ROLL_END"], self.item.link, Comm.GetPlayerLink(self.item.owner))

        -- Check if we can end the roll
        local valid, msg = self:Validate(Self.STATUS_RUNNING, winner)
        if not valid then
            Addon:Err(msg)
            return self
        end

        -- Check if we should post it to chat first
        if self.isOwner and not winner and self:Advertise() then
            return self
        end

        -- Update status
        self.status = Self.STATUS_DONE
        self.ended = time()

        Self.events:Fire(Self.EVENT_END, self)
    end

    -- Hide UI elements etc.
    if cleanup then
        if self.timer then
            Addon:CancelTimer(self.timer)
            self.timer = nil
        end

        self:HideRollFrame()
    end

    -- Determine a winner
    if self.isOwner and not winner or winner == true then
        if not Masterloot.GetMasterlooter() and self.item.isOwner and self.bid and floor(self.bid) == Self.BID_NEED then
            winner = UnitName("player")
        elseif self.isOwner and (winner or not Addon.db.profile.awardSelf and not Masterloot.IsMasterlooter()) then
            winner = self:DetermineWinner()
        end
    end

    -- Set winner or just send status
    if winner ~= self.winner then
        self.winner = winner
        self.isWinner = Unit.IsSelf(self.winner)
        
        Self.events:Fire(Self.EVENT_AWARD, self)
        self:SendStatus()

        if self.winner then
            -- It has already been traded
            if self.winner == self.item.owner then
                self:OnTraded(self.winner)
            end

            -- Let everyone know
            Comm.RollEnd(self)
        end
    else
        self:SendStatus()
    end

    return self
end

-- Cancel a roll
function Self:Cancel()
    if self.status == Self.STATUS_CANCELED then return end
    Addon:Verbose(L["ROLL_CANCEL"], self.item.link, Comm.GetPlayerLink(self.item.owner))

    -- Cancel a pending timer
    if self.timer then
        Addon:CancelTimer(self.timer)
        self.timer = nil
    end

    -- Update status
    self.status = Self.STATUS_CANCELED

    -- Hide the roll frame
    self:HideRollFrame(id)

    -- Let everyone know
    Self.events:Fire(Self.EVENT_CANCEL, self)
    self:SendStatus()
    
    return self
end

-- Trade with the owner or the winner of the roll
function Self:Trade()
    local target = self:GetActionTarget()
    if target then
        Trade.Initiate(target)
    end
end

-- Called when the roll's item is traded
function Self:OnTraded(target)
    if not target or target == self.traded then
        return
    end

    self.traded = target
    
    -- Update the status
    if self.isOwner and self.item.isOwner then
        if self.status == Self.STATUS_PENDING then
            self:Cancel()
        elseif self.status == Self.STATUS_RUNNING then
            self:End(target)
        end
    end

    Self.events:Fire(Self.EVENT_TRADE, self, target)
    self:SendStatus(self.item.isOwner or self.isWinner)
end

-------------------------------------------------------
--                      GUI                       --
-------------------------------------------------------

-- Get the loot frame for a loot id
function Self:GetRollFrame()
    local id, frame = self:GetPlrId()

    for i=1, NUM_GROUP_LOOT_FRAMES do
        frame = _G["GroupLootFrame"..i]
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
                Util.TblList(GroupLootContainer.rollFrames)
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
        GroupLootContainer_RemoveFrame(GroupLootContainer, frame)

        -- TODO: This is required to circumvent a bug in ElvUI
        Util.TblList(GroupLootContainer.rollFrames)
        GroupLootContainer_Update(GroupLootContainer)
    end
end

-- Show the alert frame for winning an item
function Self:ShowAlertFrame()
    -- itemLink, quantity, rollType, roll, specID, isCurrency, showFactionBG, lootSource, lessAwesome, isUpgraded, wonRoll, showRatedBG, plrId
    GUI.LootAlertSystem:AddAlert(self.item.link, 1, nil, nil, nil, false, false, nil, false, false, true, false, self.id)
end

-- Toggle the rolls visiblity in GUIs
function Self:ToggleVisibility(show)
    if show == nil then self.hidden = not self.hidden else self.hidden = not show end
    Self.events:Fire(Self.EVENT_VISIBILITY, self)
end

-- Log a chat message about the roll
function Self:AddChat(msg, unit)
    unit = unit or "player"
    self.chat = self.chat or Util.Tbl()
    tinsert(self.chat, "[" .. Unit.ColoredName(Unit.ShortenedName(unit), unit) .. "]: " .. msg)    
    Self.events:Fire(Self.EVENT_CHAT, self)
end

-------------------------------------------------------
--                       Comm                        --
-------------------------------------------------------

function Self:ShouldAdvertise(manually)
    return not self.posted and self:CanBeAwarded() and not self:ShouldEnd() and (
        manually or Comm.ShouldInitChat() and (self.bid or Masterloot.GetMasterlooter())
    )
end

-- Advertise the roll to the group
function Self:Advertise(manually, silent)
    if not self:ShouldAdvertise(manually) then
        return false
    end
    
    self:ExtendTimeLeft()

    -- Get the next free roll slot
    local posted, i = {}
    for _,roll in pairs(Addon.rolls) do
        if roll.status == Self.STATUS_RUNNING and type(roll.posted) == "number" then
            posted[roll.posted] = true
        end
    end
    for j=1,50 do
        if not posted[j] then
            i = j break
        end
    end

    if i < 50 then
        if self.item.isOwner then
            Comm.ChatLine("MSG_ROLL_START", Comm.TYPE_GROUP, self.item.link, 100 + i)
        else
            Comm.ChatLine("MSG_ROLL_START_MASTERLOOT", Comm.TYPE_GROUP, self.item.link, self.item.owner, 100 + i)
        end

        self.posted = i

        if not silent then
            self:SendStatus()
        end

        Self.events:Fire(Self.EVENT_ADVERTISE, self, manually, silent)

        return true
    else
        return false
    end
end

-- Send the roll status to others
function Self:SendStatus(noCheck, target, full)
    if noCheck or self.isOwner then
        local data = {
            owner = Unit.FullName(self.owner),
            ownerId = self.ownerId,
            itemOwnerId = self.itemOwnerId,
            status = self.status,
            started = self.started,
            timeout = self.timeout,
            posted = self.posted,
            winner = self.winner and Unit.FullName(self.winner),
            traded = self.traded and Unit.FullName(self.traded),
            item = {
                link = self.item.link,
                owner = Unit.FullName(self.item.owner)
            }
        }

        if full then
            if Masterloot.session.bidPublic or Masterloot.IsOnCouncil(target) then
                data.bids = Util.TblMapKeys(self.bids, Unit.FullName)
            end

            if Masterloot.session.votePublic or Masterloot.IsOnCouncil(target) then
                data.votes = Util(self.votes).MapKeys(Unit.FullName).Map(Unit.FullName)()
            end
        end

        Comm.SendData(Comm.EVENT_ROLL_STATUS, data, target or Comm.TYPE_GROUP)
    end
end

-------------------------------------------------------
--                      Timing                       --
-------------------------------------------------------

-- Get the total runtime for a roll
function Self:GetRunTime(real)
    return self.timeout + (real and 0 or Self.DELAY)
end

-- Get the time that is left on a roll
function Self:GetTimeLeft(real)
    return (self.started and self.started - time() or 0) + self:GetRunTime(real)
end

-- Extend the timeout to at least the given # of seconds
function Self:ExtendTimeout(to)
    if self.status < Self.STATUS_DONE and self.timeout < to then
        -- Extend a running timer
        if self.status == Self.STATUS_RUNNING then
            self.timer = Addon:ExtendTimerBy(self.timer, to - self.timeout)
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
function Self:ExtendTimeLeft(to)
    to = to or Self.TIMEOUT
    local left = self:GetTimeLeft(true)

    if self.status < Self.STATUS_DONE and left < to then
        self:ExtendTimeout(self.timeout + (to - left))
    end
end

-------------------------------------------------------
--                    Validation                     --
-------------------------------------------------------

-- Some common error checks for a loot roll
function Self:Validate(status, ...)
    if Addon.DEBUG then
        return true
    end

    if status and self.status ~= status then
        return false, L["ERROR_ROLL_STATUS_NOT_" .. status]
    elseif not self.item.isTradable then
        return false, L["ERROR_ITEM_NOT_TRADABLE"]
    elseif not IsInGroup() then 
        return false, L["ERROR_NOT_IN_GROUP"]
    else
        for _,unit in pairs({self.owner, ...}) do
            if not UnitExists(unit) or not Unit.InGroup(unit) then
                return false, Util.StrFormat(L["ERROR_PLAYER_NOT_FOUND"], unit)
            end
        end

        return true
    end
end

-- Validate an incoming bid
function Self:ValidateBid(bid, answer, fromUnit, isImport)
    local valid, msg = self:Validate(nil, fromUnit)
    if not valid then
        Addon:Err(msg)
    -- Don't validate imports any further
    elseif isImport then
        return true
    -- Check if it's a valid bid
    elseif not Util.TblFind(Self.BIDS, floor(bid)) or Masterloot.GetMasterlooter(self.owner) and answer > 0 and not (answers and answers[answer]) then
        if Unit.IsSelf(fromUnit) then
            Addon:Err(L["ERROR_ROLL_BID_UNKNOWN_SELF"])
        else
            Addon:Verbose(L["ERROR_ROLL_BID_UNKNOWN_OTHER"], fromUnit, self.item.link)
        end
    -- Check if the unit can bid
    elseif not (self:CanBeBidOn() or Util.In(self.status, Self.STATUS_RUNNING, Self.STATUS_DONE) and self.bids[fromUnit] and bid == Self.BID_PASS) then
        if Unit.IsSelf(fromUnit) then
            Addon:Err(L["ERROR_ROLL_BID_IMPOSSIBLE_SELF"])
        else
            Addon:Verbose(L["ERROR_ROLL_BID_IMPOSSIBLE_OTHER"], fromUnit, self.item.link)
        end
    else
        return true
    end
end

-- Validate an incoming vote
function Self:ValidateVote(vote, fromUnit, isImport)
    local valid, msg = self:Validate(nil, vote, fromUnit)
    if not valid then
        Addon:Err(msg)
    -- Don't validate imports any further
    elseif isImport then
        return true
    -- Check if the unit can bid
    elseif not self:UnitCanVote(fromUnit) then
        if fromSelf then
            Addon:Err(L["ERROR_ROLL_VOTE_IMPOSSIBLE_SELF"])
        else
            Addon:Verbose(L["ERROR_ROLL_VOTE_IMPOSSIBLE_OTHER"], fromUnit, self.item.link)
        end
    else
        return true
    end
end

-------------------------------------------------------
--                      Helper                       --
-------------------------------------------------------

-- Figure out a random winner
local countFn = function (val, bid) return floor(val) == bid and 1 or 0 end
function Self:DetermineWinner()
    for i,bid in pairs(Self.BIDS) do
        if bid ~= Self.BID_PASS then
            local n = Util.TblCountFn(self.bids, countFn, bid)
            if n > 0 then
                n = math.random(n)
                for unit,unitBid in pairs(self.bids) do
                    if floor(unitBid) == bid then
                        n = n - 1
                    end
                    if n == 0 then
                        -- We have a winner, now let's check if someone rolled higher in chat
                        if not self.rolls[unit] then
                            return unit
                        else
                            local winner, maxRoll = unit, self.rolls[unit]
                            for unitRoll,rollResult in pairs(self.rolls) do
                                if rollResult > maxRoll and floor(self.bids[unitRoll]) == bid then
                                    winner, maxRoll = unitRoll, rollResult
                                end
                            end
                            return winner
                        end
                    end
                end
            end
        end
    end
end

-- Check if the given unit is eligible
function Self:UnitIsEligible(unit, checkIlvl)
    local val = unit and self.item:GetEligible(unit or "player") or nil
    if checkIlvl then return val else return val ~= nil end
end

-- Check if the roll can still be won
function Self:CanBeWon(includeDone)
    return not self.traded and (Util.In(self.status, Self.STATUS_PENDING, Self.STATUS_RUNNING) or includeDone and self.status == Self.STATUS_DONE and not self.winner)
end

-- Check if the given unit can win this roll
function Self:CanBeWonBy(unit, includeDone, checkIlvl)
    return self:CanBeWon(includeDone) and self:UnitIsEligible(unit, checkIlvl)
end

-- Check if we can still award the roll
function Self:CanBeAwarded(includeDone)
    return self.isOwner and self:CanBeWon(includeDone)
end

-- Check if we can still award the roll to the given unit
function Self:CanBeAwardedTo(unit, includeDone, checkIlvl)
    return self.isOwner and self:CanBeWonBy(unit, includeDone, checkIlvl)
end

-- Check if the roll can be bid on
function Self:CanBeBidOn()
    return self.status == Self.STATUS_RUNNING
end

-- Check if the given unit can bid on this roll
function Self:UnitCanBid(unit, checkIlvl)
    return not (Addon.db.profile.dontShare and Unit.IsSelf(unit or "player")) and self:CanBeBidOn() and self:CanBeWonBy(unit, nil, checkIlvl)
end

-- Check if the roll can be voted on
function Self:CanBeVotedOn()
    return self.status > Self.STATUS_CANCELED and not self.winner
end

-- Check if the given unit can vote on this roll
function Self:UnitCanVote(unit)
    return self:CanBeVotedOn() and Masterloot.IsOnCouncil(unit or "player")
end

-- Check if the given unit can pass on this roll
function Self:UnitCanPass(unit)
    unit = Unit.Name(unit or "player")
    return not self.traded and self.bids[unit] and self.bids[unit] ~= Self.BID_PASS
end

-- Check if we can restart a roll
function Self:CanBeRestarted()
    return self.isOwner and Util.In(self.status, Self.STATUS_CANCELED, Self.STATUS_DONE) and (not self.traded or UnitIsUnit(self.traded, self.item.owner))
end

-- Check if the roll is handled by a masterlooter
function Self:HasMasterlooter()
    return self.owner ~= self.item.owner or self.owner == Masterloot.GetMasterlooter(self.item.owner)
end

-- Check if the player has to take an action to complete the roll (e.g. trade)
function Self:GetActionRequired()
    if self.traded then
        return false
    elseif not self.ownerId and self.bid and self.bid ~= Self.BID_PASS then
        return Self.ACTION_ASK
    elseif self.item.isOwner and self.winner or self.isWinner then
        return Self.ACTION_TRADE
    elseif self.status == Self.STATUS_DONE and Util.TblCountExcept(self.bids, Self.BID_PASS) > 0 then
        return self:CanBeAwarded(true) and Self.ACTION_AWARD or self:UnitCanVote() and not self.vote and Self.ACTION_VOTE or false
    else
        return false
    end
end

-- Get the target for actions (e.g. trade, whisper)
function Self:GetActionTarget()
    if Util.In(self:GetActionRequired(), Self.ACTION_TRADE, Self.ACTION_ASK) then
        return self.item.isOwner and self.winner or not self.item.isOwner and self.item.owner
    end
end

-- Check if the roll is running or recently ended
function Self:IsRecent(timeout)
    return self.status == Self.STATUS_RUNNING or timeout ~= false and self.status == Self.STATUS_DONE and self.ended + (timeout or Self.TIMEOUT_RECENT) >= time()
end

-- Get the rolls id with PLR prefix
function Self:GetPlrId()
    return Self.ToPlrId(self.id)
end