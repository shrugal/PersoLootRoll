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
-- Max # of whispers per item for all addons in the group
Self.MAX_WHISPERS = 2

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
Self.EVENT_TRADE = "TRADE"
Self.EVENT_CHANGE = "CHANGE"
Self.EVENTS = {Self.EVENT_ADD, Self.EVENT_CLEAR, Self.EVENT_START, Self.EVENT_CANCEL, Self.EVENT_ADVERTISE, Self.EVENT_BID, Self.EVENT_VOTE, Self.EVENT_END, Self.EVENT_TRADE}

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
        -- Only the item owner or his/her masterlooter can create rolls
        if not Util.In(unit, data.item.owner, Masterloot.masterlooting[data.item.owner]) then
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
    elseif roll.winner and (unit == roll.winner or unit == roll.item.owner and (not Addon.versions[roll.winner]) or data.traded ~= roll.winner) then
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

function Self.IsPlrId(id)
    return Util.StrStartsWith("" .. id, Addon.ABBR)
end

function Self.ToPlrId(id)
    return Addon.ABBR .. id
end

function Self.FromPlrId(id)
    return tonumber(("" .. id):sub(Addon.ABBR:len() + 1))
end

-- Calculate the optimal timeout
function Self.GetTimeout()
    local items, ml = 0, Masterloot.GetMasterlooter()
    local base, perItem = ml and Masterloot.session.timeoutBase or Self.TIMEOUT, ml and Masterloot.session.timeoutPerItem or Self.TIMEOUT_PER_ITEM

    if select(4, GetInstanceInfo()) == DIFFICULTY_DUNGEON_CHALLENGE then
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
    Addon:Verbose(L["ROLL_START"]:format(self.item.link, Comm.GetPlayerLink(self.item.owner)))

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
            local shouldRoll = self.item.isOwner or self.item:ShouldBeBidOn()
            if shouldRoll then
                self:ShowRollFrame()
            end
            if self.isOwner and Masterloot.IsMasterlooter() or shouldRoll and Addon.db.profile.ui.showRollsWindow then
                GUI.Rolls.Show()
            end

            -- Schedule timer to end the roll and hide the frame
            self.timer = Addon:ScheduleTimer(Self.Finish, self:GetTimeLeft(), self)

            -- Let the others know
            self:Advertise(false, true)
            self:SendStatus()

            Self.events:Fire(Self.EVENT_START, self)
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
    self.bid = nil
    self.vote = nil
    self.winner = nil
    self.isWinner = nil
    self.shown = nil
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

    self:Start(started)
end

-- Bid on a roll
function Self:Bid(bid, fromUnit, rollOrImport)
    bid = bid or Self.BID_NEED
    fromUnit = Unit.Name(fromUnit or "player")
    local fromSelf = UnitIsUnit(fromUnit, "player")

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
    
    -- Check if we can bid
    local valid, msg = self:Validate(not isImport and Self.STATUS_RUNNING or nil, fromUnit)
    if not valid then
        Addon:Err(msg)
    elseif not Util.TblFind(Self.BIDS, floor(bid)) or Masterloot.GetMasterlooter(self.owner) and answer > 0 and not (answers and answers[answer]) then
        Comm.RollBidError(self, fromUnit)
    else
        -- Register the bid
        self.bids[fromUnit] = bid

        if rollResult then
            self.rolls[fromUnit] = rollResult
        end

        if fromSelf then
            self.bid = bid
            Comm.RollBidSelf(self, isImport)
        end

        -- Check if we should advertise to chat
        if self.isOwner and not (self.status == Self.STATUS_DONE or self:CheckEnd()) then
            self:Advertise()
        end

        -- Inform others
        if not isImport then
            if self.isOwner then
                local data = {ownerId = self.ownerId, bid = bid, fromUnit = Unit.FullName(fromUnit)}

                -- Send to all or the council
                if Addon.db.profile.masterlooter.bidPublic then
                    Comm.SendData(Comm.EVENT_BID, data)
                elseif Masterloot.IsMasterlooter() then
                    for target,_ in pairs(Masterloot.session.council or {}) do
                        Comm.SendData(Comm.EVENT_BID, data, target)
                    end
                end
            elseif fromSelf then
                if self.ownerId then
                    -- Send to owner
                    Comm.SendData(Comm.EVENT_BID, {ownerId = self.ownerId, bid = bid}, self.owner)
                elseif bid ~= Self.BID_PASS then
                    -- Roll on it in chat or whisper the owner
                    if self.posted then
                        if Addon.db.profile.roll and Events.lastPostedRoll == self then
                            RandomRoll("1", floor(bid) == Self.BID_GREED and "50" or "100")
                        end
                    elseif self.whispers < Self.MAX_WHISPERS and Comm.RollBid(self.item.owner, self.item.link) then
                        self.whispers = self.whispers + 1
                        Comm.SendData(Comm.EVENT_BID_WHISPER, {owner = Util.FullName(roll.item.owner), link = roll.item.link})
                    end
                end
            end
        end

        Self.events:Fire(Self.EVENT_BID, self, bid, fromUnit, rollOrImport)
    end

    return self
end

-- Vote for a unit
function Self:Vote(vote, fromUnit, isImport)
    vote = Unit.Name(vote)
    fromUnit = Unit.Name(fromUnit or "player")
    local fromSelf = UnitIsUnit(fromUnit, "player")

    -- Check if we can vote
    local valid, msg = self:Validate(nil, vote, fromUnit)
    if not valid then
        Addon:Err(msg)
    elseif not (isImport or self:UnitCanVote(fromUnit)) then
        Comm.RollVoteError(self)
    else
        -- Register the vote
        self.votes[fromUnit] = vote

        if fromSelf then
            self.vote = vote
        end

        -- Inform others
        if not isImport then
            if self.isOwner then
                local data = {ownerId = self.ownerId, vote = Unit.FullName(vote), fromUnit = Unit.FullName(fromUnit)}

                -- Send to all or the council
                if Addon.db.profile.masterlootert.votePublic then
                    Comm.SendData(Comm.EVENT_VOTE, data)
                elseif Masterloot.IsMasterlooter() then
                    for target,_ in pairs(Masterloot.session.council or {}) do
                        Comm.SendData(Comm.EVENT_VOTE, data, target)
                    end
                end
            elseif fromSelf then
                -- Send to owner
                Comm.SendData(Comm.EVENT_VOTE, {ownerId = self.ownerId, vote = Unit.FullName(vote)}, Masterloot.GetMasterlooter())
            end
        end

        Self.events:Fire(Self.EVENT_VOTE, self, vote, fromUnit, isImport)
    end
end

-- Check if we should end the roll prematurely
function Self:ShouldEnd()
    -- Only end running rolls that we own and that we answered already
    if not self.isOwner or self.status ~= Self.STATUS_RUNNING or not self.bid then
        return false
    end

    -- We voted need on our own item
    if not Masterloot.GetMasterlooter() and self.item.isOwner and self.bid and floor(self.bid) == Self.BID_NEED then
        return self.item.owner
    end

    -- Check if all eligible players have bid
    for unit,ilvl in pairs(self.item:GetEligible()) do
        if ilvl and not self.bids[unit] then
            return false
        end
    end

    return true
end

-- Check if we should end the roll prematurely, and then end it
function Self:CheckEnd()
    local winner = self:ShouldEnd()
    if winner then
        self:End(type(winner) == "string" and winner or nil)
        return true
    else
        return false
    end
end

-- End a roll
function Self:End(winner)
    if self.winner then return end

    local award = winner == true
    if award then
        winner = nil
    else
        winner = winner and Unit.Name(winner) or nil
    end
    
    -- End it if it is running
    if self.status < Self.STATUS_DONE then
        Addon:Verbose(L["ROLL_END"]:format(self.item.link, Comm.GetPlayerLink(self.item.owner)))

        -- Check if we can end the roll
        local valid, msg = self:Validate(Self.STATUS_RUNNING, winner)
        if not valid then
            Addon:Err(msg)
            return self
        end

        -- Check if we should post it to chat first
        if self.isOwner and not award and not winner and self:Advertise() then
            return self
        end

        -- Update status
        self.status = Self.STATUS_DONE
    end

    -- Determine a winner
    if self.isOwner and (award or not (winner or Addon.db.profile.awardSelf or Masterloot.IsMasterlooter())) then
        winner = self:DetermineWinner()
    end
    
    -- Set winner
    self.winner = winner
    self.isWinner = self.winner and UnitIsUnit(self.winner, "player")

    if self.winner then
        -- It has already been traded
        if self.winner == self.item.owner then
            self:OnTraded(self.winner)
        end

        -- Let the player know, announce to chat and the winner
        Comm.RollEnd(self)
    end

    self:SendStatus()
    
    Self.events:Fire(Self.EVENT_END, self)

    return self
end

-- End a roll, including closing UI elements etc.
function Self:Finish(winner)
    self:End(winner)

    if self.status == Self.STATUS_DONE then
        if self.timer then
            Addon:CancelTimer(self.timer)
            self.timer = nil
        end

        self:HideRollFrame()
    end
end

-- Cancel a roll
function Self:Cancel()
    if self.status == Self.STATUS_CANCELED then return end
    Addon:Verbose(L["ROLL_CANCEL"]:format(self.item.link, Comm.GetPlayerLink(self.item.owner)))

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
    self:SendStatus()
        
    Self.events:Fire(Self.EVENT_CANCEL, self)
    
    return self
end

-- Trade with the owner or the winner of the roll
function Self:Trade()
    local target = self.item.isOwner and self.winner or self.isWinner and self.item.owner
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

    self:SendStatus(self.item.isOwner or self.isWinner)
        
    Self.events:Fire(Self.EVENT_TRADE, self, target)
end

-------------------------------------------------------
--                      Frames                       --
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

-------------------------------------------------------
--                       Comm                        --
-------------------------------------------------------

function Self:ShouldAdvertise(manually)
    return not self.posted and self:CanBeAwarded() and not self:ShouldEnd() and (manually or Comm.ShouldChat() and (self.bid or Masterloot.GetMasterlooter()))
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
            Comm.ChatLine("ROLL_START", Comm.TYPE_GROUP, self.item.link, 100 + i)
        else
            Comm.ChatLine("ROLL_START_MASTERLOOT", Comm.TYPE_GROUP, self.item.link, self.item.owner, 100 + i)
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
    local val = self.item:GetEligible(unit)
    if checkIlvl then return val else return val ~= nil end
end

-- Check if the roll can still be won
function Self:CanBeWon(includeDone)
    return not self.traded and (self.status == Self.STATUS_PENDING or self.status == Self.STATUS_RUNNING or includeDone and self.status == Self.STATUS_DONE and not self.winner)
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
    return self:CanBeBidOn() and self:CanBeWonBy(unit, nil, checkIlvl)
end

-- Check if the roll can be voted on
function Self:CanBeVotedOn()
    return self.status > Self.STATUS_CANCELED and not self.winner
end

-- Check if the given unit can vote on this roll
function Self:UnitCanVote(unit)
    return self:CanBeVotedOn() and Masterloot.IsOnCouncil(unit)
end

-- Check if we can restart a roll
function Self:CanBeRestarted()
    return self.isOwner and Util.In(self.status, Self.STATUS_CANCELED, Self.STATUS_DONE) and (not self.traded or UnitIsUnit(self.traded, self.item.owner))
end

-- Check if the roll is handled by a masterlooter
function Self:HasMasterlooter()
    return self.owner ~= self.item.owner or self.owner == Masterloot.GetMasterlooter(self.item.owner)
end

-- Get the rolls id with PLR prefix
function Self:GetPlrId()
    return Self.ToPlrId(self.id)
end

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
                return false, L["ERROR_PLAYER_NOT_FOUND"]:format(unit)
            end
        end

        return true
    end
end