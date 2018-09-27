local Name, Addon = ...
local L = LibStub("AceLocale-3.0"):GetLocale(Name)
local CB = LibStub("CallbackHandler-1.0")
local Comm, Events, GUI, Item, Locale, Session, Trade, Unit, Util = Addon.Comm, Addon.Events, Addon.GUI, Addon.Item, Addon.Locale, Addon.Session, Addon.Trade, Addon.Unit, Addon.Util
local Self = Addon.Roll

-- Default schedule delay
Self.DELAY = 1
-- Clear rolls older than this
Self.CLEAR = 1200
-- Base timeout
Self.TIMEOUT = 20
-- Timeout increase per item
Self.TIMEOUT_PER_ITEM = 10
-- How much longer should rolls be when in chill mode
Self.TIMEOUT_CHILL_MODE = 2
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
Self.EVENT_RESTART = "RESTART"
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
Self.EVENTS = {Self.EVENT_ADD, Self.EVENT_CLEAR, Self.EVENT_START, Self.EVENT_RESTART, Self.EVENT_CANCEL, Self.EVENT_ADVERTISE, Self.EVENT_BID, Self.EVENT_VOTE, Self.EVENT_END, Self.EVENT_AWARD, Self.EVENT_TRADE, Self.EVENT_VISIBILITY, Self.EVENT_CHAT}

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
function Self.Find(ownerId, owner, item, itemOwnerId, itemOwner, status)
    owner = Unit.Name(owner or "player")
    local id
    
    -- It's our own item
    if Unit.IsSelf(owner) then
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
                and (roll.item.owner == (itemOwner or t == "table" and item.owner) or not (roll.item.owner and (itemOwner or t == "table" and item.owner)))
                and (roll.ownerId == ownerId or not (roll.ownerId and ownerId))
                and (roll.itemOwnerId == itemOwnerId or not (roll.itemOwnerId and itemOwnerId))
                and (roll.status == status or not status)
                and (
                       t == "table" and roll.item.link == item.link
                    or t == "number" and item == roll.item.id
                    or t == "string" and item == roll.item.link
                )
        end)
    end

    return id and Addon.rolls[id]
end

-- Add a roll to the list
function Self.Add(item, owner, ownerId, itemOwnerId, timeout, disenchant)
    owner = Unit.Name(owner or "player")
    local isOwner = Unit.IsSelf(owner)

    -- Create the roll entry
    local roll = {
        created = time(),
        isOwner = isOwner,
        item = Item.FromLink(item, owner),
        owner = owner,
        ownerId = ownerId,
        itemOwnerId = itemOwnerId,
        timeout = timeout or Self.CalculateTimeout(owner),
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

    Addon:Debug("Roll.Update", unit, data, roll)

    if not roll then
        local ml = Session.GetMasterlooter()

        -- Only the item owner and our ml can create rolls
        if not (unit == data.item.owner or ml and unit == ml) then
            Addon:Debug("Roll.Update.Reject.SenderNotAllowed")
            return
        -- Only accept items while having a masterlooter if enabled
        elseif Addon.db.profile.onlyMasterloot and not ml then
            Addon:Debug("Roll.Update.Reject.NoMasterlooter")
            return
        end

        roll = Self.Add(Item.FromLink(data.item.link, data.item.owner, nil, nil, Util.Default(data.item.isTradable, true)), data.owner, data.ownerId, data.itemOwnerId, data.timeout, data.disenchant or nil)

        if roll.isOwner then roll.item:OnLoaded(function ()
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
        end) end
    end

    -- Only the roll owner can send updates
    if unit == roll.owner then
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
        else roll.item:OnLoaded(function ()
            -- Declare our interest if the roll is pending without any eligible players
            if data.status == Self.STATUS_PENDING and (data.item.eligible or 0) == 0 and roll:ShouldBeBidOn() then
                roll.item:SetEligible("player")
                Comm.SendData(Comm.EVENT_INTEREST, {ownerId = roll.ownerId}, roll.owner)
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

                for fromUnit,bid in pairs(data.bids or {}) do
                    roll:Bid(bid, fromUnit, data.rolls and data.rolls[fromUnit], true)
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
                roll:End(data.winner, false, true)
            end

            -- Register when the roll has been traded
            if data.traded ~= roll.traded then
                roll:OnTraded(data.traded)
            end
        end) end
    -- The winner can inform us that it has been traded, or the item owner if the winner doesn't have the addon or he traded it to someone else
    elseif roll.winner and (unit == roll.winner or unit == roll.item.owner and not Addon:UnitIsTracking(roll.winner) or data.traded ~= roll.winner) then
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
            Addon:Error(msg)
        else
            -- Update eligible players if not already done so
            if self.isOwner or self.item.isOwner then
                self.item:GetEligible()
            end

            if not (Addon.db.profile.chillMode and self.isOwner and not Session.GetMasterlooter() and not self.bid) then
                -- Start the roll
                self.started = started or time()
                self.status = Self.STATUS_RUNNING

                -- Schedule timer to end the roll and/or hide the frame
                if self.timeout > 0 then
                    self.timers.bid = Addon:ScheduleTimer(Self.End, self:GetTimeLeft(), self, nil, true)
                elseif not Addon.db.profile.chillMode then
                    self.timers.bid = Addon:ScheduleTimer(Self.HideRollFrame, self:GetTimeLeft(), self)
                end

                -- Let everyone know
                self:Advertise(false, true)

                -- Send message to PLH users
                if self.isOwner then
                    Comm.SendPlh(Comm.PLH_ACTION_TRADE, self, self.item.link)
                end
                
                Self.events:Fire(Self.EVENT_START, self)
            end

            -- Let others know
            self:SendStatus()

            -- Offer to bid or bid disenchant directly
            if not self.bid and (self.item.isOwner or self:ShouldBeBidOn()) then
                -- Show some UI
                if self.item.isOwner or self.item:ShouldBeBidOn() then
                    self:ShowRollFrame()
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
    if self.timers.bid then return end

    self.item:GetBasicInfo()

    self.timers.bid = Addon:ScheduleTimer(function ()
        Addon:Debug("Roll.Schedule", self)

        -- Start the roll if it hasn't been started after the waiting period
        if self.status == Self.STATUS_PENDING then
            self.timers.bid = nil

            if self.isOwner and self.item:ShouldBeRolledFor() or not self.isOwner and self:ShouldBeBidOn() then
                Addon:Debug("Roll.Schedule.Start")
                self:Start()
            else
                Addon:Debug("Roll.Schedule.NotStart", Addon.db.profile.dontShare, self.owner, self.isOwner, self.item.owner, self.item.isOwner, self.item:HasSufficientQuality(), self.item:GetBasicInfo().isEquippable, self.item:GetFullInfo().isTradable, self.item:GetNumEligible(true))
                
                if self.item.isEquippable then
                    self:Cancel()
                else
                    self:Clear()
                end
            end
        end
    end, Self.DELAY)

    return self
end

-- Restart a roll
function Self:Restart(started, pending)
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

    for i,v in pairs(self.timers) do
        Addon:CancelTimer(v)
        self.timers[i] = nil
    end

    Self.events:Fire(Self.EVENT_RESTART, self)
    
    return pending and self or self:Start(started)
end

-- Bid on a roll
function Self:Bid(bid, fromUnit, roll, isImport)
    bid = bid or Self.BID_NEED
    fromUnit = Unit.Name(fromUnit or "player")
    roll = roll or self.isOwner and bid ~= Self.BID_PASS and random(100) or nil
    local fromSelf = Unit.IsSelf(fromUnit)

    -- Handle custom answers
    local answer, answers = 10*bid - 10*floor(bid), Session.rules["answers" .. floor(bid)]
    if bid == floor(bid) and answers and Session.IsMasterlooter(self.owner) then
        local i = Util.TblFind(answers, bid == Self.BID_NEED and Self.ANSWER_NEED or Self.ANSWER_GREED)
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

        Self.events:Fire(Self.EVENT_BID, self, bid, fromUnit, roll, isImport)

        -- Let everyone know
        Comm.RollBid(self, bid, fromUnit, roll, isImport)

        -- Check if we should end the roll
        if not (self:ShouldEnd() and self:End()) and self.isOwner then
            -- or start if in chill mode
            if self.status == Self.STATUS_PENDING then
                self:Start()
            -- or advertise to chat
            elseif self.status == Self.STATUS_RUNNING then
                self:Advertise()
            -- or if the winner just passed on the item
            elseif self.winner == fromUnit and bid == Self.BID_PASS and not self.traded then
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
        Comm.RollVote(self, vote, fromUnit, isImport)
    end

    return self
end

-- Check if we should end the roll prematurely
function Self:ShouldEnd()
    -- We voted need on our own item
    if Util.In(self.status, Self.STATUS_PENDING, Self.STATUS_RUNNING) and not Session.GetMasterlooter() and self.item.isOwner and self.bid and floor(self.bid) == Self.BID_NEED then
        return true
    -- Not running or we haven't bid yet
    elseif self.status ~= Self.STATUS_RUNNING or not self.bid then
        return false
    -- The owner doesn't have the addon
    elseif not self.ownerId then
        return true
    -- Not the owner
    elseif not self.isOwner then
        return false
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
    -- Hide UI elements etc.
    if cleanup then
        if self.timers.bid then
            Addon:CancelTimer(self.timers.bid)
            self.timers.bid = nil
        end

        self:HideRollFrame()
    end

    -- Don't overwrite an existing winner
    if self.winner and not force then return self end

    winner = winner and winner ~= true and Unit.Name(winner) or winner
    
    -- End it if it is running
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
        self.status = Self.STATUS_DONE
        self.ended = time()
        self.started = self.started or time()

        Self.events:Fire(Self.EVENT_END, self)
    end

    -- Determine a winner
    if self.isOwner and (not winner or winner == true) then
        if not Session.GetMasterlooter() and self.bid and floor(self.bid) == Self.BID_NEED then
            -- Give it to ourselfs
            winner = UnitName("player")
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

    local statusSend = false

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
                statusSend = true
            end

            -- Let everyone know
            Comm.RollEnd(self)
        end
    end

    Self.events:Fire(Self.EVENT_AWARD, self)
    if not statusSend then self:SendStatus() end

    return self
end

-- Cancel a roll
function Self:Cancel()
    if self.status == Self.STATUS_CANCELED then return end
    Addon:Verbose(L["ROLL_CANCEL"], self.item.link, Comm.GetPlayerLink(self.item.owner))

    -- Cancel a pending timer
    for i,v in pairs(self.timers) do
        Addon:CancelTimer(v)
        self.timers[i] = nil
    end

    -- Update status
    self.status = Self.STATUS_CANCELED

    -- Hide the roll frame
    self:HideRollFrame()

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
    local c = ChatTypeInfo[Unit.IsSelf(unit) and "WHISPER_INFORM" or "WHISPER"] or Util.TBL_EMPTY
    c = Util.StrColor(c.r, c.g, c.b)
    msg = ("|c%s[|r%s|c%s]: %s|r"):format(c, Unit.ColoredShortenedName(unit), c, msg)

    self.chat = self.chat or Util.Tbl()
    tinsert(self.chat, msg)
    
    Self.events:Fire(Self.EVENT_CHAT, self)
end

-------------------------------------------------------
--                       Comm                        --
-------------------------------------------------------

function Self:ShouldAdvertise(manually)
    return not self.posted and self:CanBeAwarded() and not self:ShouldEnd() and (
        manually or Comm.ShouldInitChat() and (self.bid or Session.GetMasterlooter())
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
        local data = Util.Tbl()
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
        data.item = Util.TblHash(
            "link", self.item.link,
            "owner", Unit.FullName(self.item.owner),
            "isTradable", Util.Check(self.item.isTradable == false and not Addon.DEBUG, false, nil),
            "eligible", self.item:GetNumEligible(true, true)
        )

        if full then
            if Addon.db.profile.bidPublic or Session.rules.bidPublic or Session.IsOnCouncil(target) then
                data.bids = Util.TblMapKeys(self.bids, Unit.FullName)
                data.rolls = Util.TblMapKeys(self.rolls, Unit.FullName)
            end

            if Session.rules.votePublic or Session.IsOnCouncil(target) then
                data.votes = Util(self.votes).MapKeys(Unit.FullName).Map(Unit.FullName)()
            end
        end

        Comm.SendData(Comm.EVENT_ROLL_STATUS, data, target or Comm.TYPE_GROUP)

        Util.TblRelease(true, data)
    end
end

-------------------------------------------------------
--                      Timing                       --
-------------------------------------------------------

-- Get the total runtime for a roll
function Self:GetRunTime(real)
    if self.timeout == 0 and (Addon.db.profile.chillMode or real) then
        return 0
    else
        return max(0, self.timeout == 0 and self:CalculateTimeout() or self.timeout + (real and 0 or Self.DELAY))
    end
end

-- Get the time that is left on a roll
function Self:GetTimeLeft(real)
    if self.status ~= Self.STATUS_RUNNING and real or self.timeout == 0 and (Addon.db.profile.chillMode or real) then
        return 0
    else
        return max(0, (self.started and self.started - time() or 0) + self:GetRunTime(real))
    end
end

-- Extend the timeout to at least the given # of seconds
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
function Self:ExtendTimeLeft(to)
    to = to or Self.TIMEOUT
    local left = self:GetTimeLeft(true)

    if self.status < Self.STATUS_DONE and left < to then
        self:ExtendTimeout(self.timeout + (to - left))
    end
end

-- Calculate the correct timeout
function Self.CalculateTimeout(selfOrOwner)
    local owner = type(selfOrOwner) == "table" and selfOrOwner.owner or selfOrOwner
    local ml = Session.GetMasterlooter()
    local chill = Addon.db.profile.chillMode and not ml

    if chill and Util.Check(Unit.IsSelf(owner), Addon.db.profile.awardSelf, not Addon:UnitIsTracking(owner)) then
        return 0
    else
        local base, perItem = ml and Session.rules.timeoutBase or Self.TIMEOUT, ml and Session.rules.timeoutPerItem or Self.TIMEOUT_PER_ITEM
        return (base + Util.GetNumDroppedItems() * perItem) * (chill and Self.TIMEOUT_CHILL_MODE or 1)
    end
end

-------------------------------------------------------
--                    Validation                     --
-------------------------------------------------------

-- Some common error checks for a loot roll
function Self:Validate(...)
    if Addon.DEBUG then
        return true
    end

    if not self.item.isTradable then
        return false, L["ERROR_ITEM_NOT_TRADABLE"]
    elseif not IsInGroup() then 
        return false, L["ERROR_NOT_IN_GROUP"]
    elseif not UnitExists(self.owner) or not Unit.InGroup(self.owner) then
        return false, L["ERROR_PLAYER_NOT_FOUND"]:format(self.owner)
    else
        local status

        for i,v in Util.Each(...) do
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
function Self:ValidateBid(bid, fromUnit, roll, isImport, answer, answers)
    local valid, msg = self:Validate(fromUnit)
    if not valid then
        Addon:Error(msg)
    -- Don't validate imports any further
    elseif isImport then
        return true
    -- Check if it's a valid bid
    elseif not Util.TblFind(Self.BIDS, floor(bid)) or Session.GetMasterlooter(self.owner) and answer > 0 and not (answers and answers[answer]) then
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
function Self:ValidateVote(vote, fromUnit, isImport)
    local valid, msg = self:Validate(vote, fromUnit)
    if not valid then
        Addon:Error(msg)
    -- Don't validate imports any further
    elseif isImport then
        return true
    -- Check if the unit can bid
    elseif not self:UnitCanVote(fromUnit) then
        if fromSelf then
            Addon:Error(L["ERROR_ROLL_VOTE_IMPOSSIBLE_SELF"])
        else
            Addon:Verbose(L["ERROR_ROLL_VOTE_IMPOSSIBLE_OTHER"], fromUnit, self.item.link)
        end
    else
        return true
    end
end

-------------------------------------------------------
--                     Decisions                     --
-------------------------------------------------------

-- Check if we should bid on the roll
function Self:ShouldBeBidOn()
    return self.item:ShouldBeBidOn() or self.disenchant and Addon.db.profile.filter.disenchant and Unit.IsEnchanter()
end

-------------------------------------------------------
--                      Helper                       --
-------------------------------------------------------

-- Figure out a winner
function Self:DetermineWinner()
    local candidates = Util.TblCopyExcept(self.bids, Self.BID_PASS, true)

    -- Narrow down by votes
    if next(self.votes) then
        Util.TblMap(candidates, Util.FnZero)
        for _,to in pairs(self.votes) do candidates[to] = (candidates[to] or 0) + 1 end
        Util.TblOnly(candidates, Util.TblMax(candidates))
        if Util.TblCount(candidates) == 1 then
            return next(candidates), Util.TblRelease(candidates)
        end
    end

    -- Narrow down by bids
    if next(self.bids) then
        Util.TblMap(candidates, function (_, i) return self.bids[i] end, true)
        Util.TblOnly(candidates, Util.TblMin(candidates))
        if Util.TblCount(candidates) == 1 then
            return next(candidates), Util.TblRelease(candidates)
        end
    end

    -- Narrow down by roll result
    if next(self.rolls) then
        Util.TblMap(candidates, function (_, i) return self.rolls[i] or random(100) end, true)
        Util.TblOnly(candidates, Util.TblMax(candidates))
        if Util.TblCount(candidates) == 1 then
            return next(candidates), Util.TblRelease(candidates)
        end
    end

    -- Pick one at random
    if next(candidates) then
        return Util.TblRandomKey(candidates), Util.TblRelease(candidates)
    end

    Util.TblRelease(candidates)

    -- Check for disenchanter
    if Session.GetMasterlooter() then
        local dis = Util.TblCopyFilter(Addon.db.profile.masterloot.rules.disenchanter[GetRealmName()] or Util.TBL_EMPTY, Unit.InGroup, false, true, true)
        if next(dis) then
            for unit in pairs(dis) do self:Bid(Self.BID_DISENCHANT, unit, nil, true) end
            return self:DetermineWinner()
        end
    end
end

-- Check if the given unit is eligible
function Self:UnitIsEligible(unit, checkIlvl)
    local val = self.item:GetEligible(unit or "player")
    if checkIlvl then return val else return val ~= nil end
end

-- Check if the roll can still be won
function Self:CanBeWon(includeDone)
    return not self.traded and (Util.In(self.status, Self.STATUS_PENDING, Self.STATUS_RUNNING) or includeDone and self.status == Self.STATUS_DONE and not self.winner)
end

-- Check if the given unit can win this roll
function Self:UnitCanWin(unit, includeDone, checkIlvl)
    return self:CanBeWon(includeDone) and self:UnitIsEligible(unit, checkIlvl)
end

-- Check if we can still award the roll
function Self:CanBeAwarded(includeDone)
    return self.isOwner and self:CanBeWon(includeDone)
end

-- Check if we can still award the roll to the given unit
function Self:CanBeAwardedTo(unit, includeDone, checkIlvl)
    return self.isOwner and self:UnitCanWin(unit, includeDone, checkIlvl)
end

-- Check if the given unit can bid on this roll
function Self:UnitCanBid(unit, bid, checkIlvl)
    unit = Unit.Name(unit or "player")

    -- Obvious stuff
    if self.traded or not Unit.InGroup(unit) then
        return false
    -- Only need+pass for rolls from non-users
    elseif not (self:OwnerUsesAddon() or Util.In(bid, nil, Self.BID_NEED, Self.BID_PASS)) then
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
    elseif not self.bids[unit] and self:UnitCanWin(unit, true, checkIlvl) then
        if self.status == Self.STATUS_DONE then
            -- Only non-pass bids on done rolls, and only if there are no non-pass bids
            return bid ~= Self.BID_PASS and Util.TblCountExcept(self.rolls, Self.BID_PASS) == 0
        else
            return true
        end
    else
        return false
    end
end

-- Check if the given unit can vote on this roll
function Self:UnitCanVote(unit)
    return self.status > Self.STATUS_CANCELED and not self.winner and Session.IsOnCouncil(unit or "player")
end

-- Check if the unit could have interest in the roll
function Self:UnitIsInvolved(unit)
    unit = Unit.Name(unit or "player")
    return self.owner == unit or self.winner == unit or self:UnitCanBid(unit) or self:UnitCanVote(unit)
end

-- Check if we can restart a roll
function Self:CanBeRestarted()
    return self.isOwner and Util.In(self.status, Self.STATUS_CANCELED, Self.STATUS_DONE) and (not self.traded or UnitIsUnit(self.traded, self.item.owner))
end

-- Check if the roll is handled by a masterlooter
function Self:HasMasterlooter()
    return self.owner ~= self.item.owner or self.owner == Session.GetMasterlooter(self.item.owner)
end

-- Check if the roll is from an addon user
function Self:OwnerUsesAddon()
    return Util.Bool(self.ownerId or self.itemOwnerId or Addon.plhUsers[self.owner])
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

-- Get the name for a bid
function Self.GetBidName(roll, bid)
    if type(bid) == "string" then
        bid = roll.bids[Unit.Name(bid)]
    end

    if not bid then
        return "-"
    else
        local bid, i, answers = floor(bid), 10*bid - 10*floor(bid), Session.rules["answers" .. floor(bid)]
        if i == 0 or not Session.IsMasterlooter(roll.owner) or not answers or not answers[i] or Util.In(answers[i], Self.ANSWER_NEED, Self.ANSWER_GREED) then
            return L["ROLL_BID_" .. bid]
        else
            return answers[i]
        end
    end
end