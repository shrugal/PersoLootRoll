local Addon = LibStub("AceAddon-3.0"):GetAddon(PLR_NAME)
local L = LibStub("AceLocale-3.0"):GetLocale(PLR_NAME)
local Util = Addon.Util
local Item = Addon.Item
local Comm = Addon.Comm
local Self = {}

-- Default schedule delay
Self.DELAY = 1
-- Clear rolls older than this
Self.CLEAR = 600
-- Base timeout
Self.TIMEOUT = 15
-- Timeout increase per item
Self.TIMEOUT_PER_ITEM = 5

-- Status
Self.STATUS_CANCELED = -1
Self.STATUS_PENDING = 0
Self.STATUS_RUNNING = 1
Self.STATUS_DONE = 2
Self.STATUS = {Self.STATUS_CANCELED, Self.STATUS_PENDING, Self.STATUS_RUNNING, Self.STATUS_DONE}

-- Answers
Self.ANSWER_PASS = 0
Self.ANSWER_NEED = 1
Self.ANSWER_GREED = 2
Self.ANSWER_DISENCHANT = 3
Self.ANSWERS = {Self.ANSWER_PASS, Self.ANSWER_NEED, Self.ANSWER_GREED, Self.ANSWER_DISENCHANT}

-- Get a roll by id or prefixed id
function Self.Get(id)
    return id and Addon.rolls[Self.IsPlrId(id) and Self.FromPlrId(id) or id] or nil
end

-- Get a roll by id and owner
function Self.Find(ownerId, owner, item)
    owner = Util.GetName(owner or "player")
    local id
    
    if isOwner then
        id = ownerId
    else
        -- Search by owner id and owner
        if ownerId and owner then
            id = Util.TblFindWhere(Addon.rolls, {ownerId = ownerId, owner = owner})
        end

        -- Search by owner and link
        if not id and owner and item then
            id = Util.TblSearch(Addon.rolls, function (roll)
                return (ownerId == nil or roll.ownerId == nil)
                   and roll.owner == owner
                   and roll.item.link == (item.link or item)
            end)
        end
    end

    return id and Addon.rolls[id]
end

-- Find rolls that the given unit can win from us
function Self.ForUnit(unit, includeDone, k)
    unit = Util.GetName(unit)
    return Util.TblFilter(Addon.rolls, function (roll)
        return roll:CanBeAwardedTo(unit, includeDone)
    end, k)
end

-- Add a roll to the list
function Self.Add(item, owner, ownerId, timeout)
    owner = Util.GetName(owner or "player")
    item = Item.FromLink(item, owner)

    -- Create the roll entry
    local roll = {
        created = time(),
        isOwner = item.isOwner,
        item = item,
        owner = owner,
        ownerId = ownerId,
        timeout = timeout or Self.GetTimeout(),
        status = Self.STATUS_PENDING,
        shown = false,
        posted = false,
        traded = false
    }
    setmetatable(roll, {__index = Self})

    -- Add it to the list
    roll.id = Addon.rolls.Add(roll)

    -- Set ownerId if we are the owner
    if roll.isOwner then
        roll.ownerId = roll.id
        roll.bids = {}
    end

    Addon.GUI.Rolls.Update()

    return roll
end

-- Process a roll update message
function Self.Update(data, owner)
    -- Get or create the roll
    local roll = Self.Find(data.id, owner, data.item)
    if not roll then
        -- No point in creating rolls that are canceled or done
        if data.status == Self.STATUS_CANCELED or data.status == Self.STATUS_DONE and data.winner ~= UnitName("player") then
            return
        end

        roll = Self.Add(data.item, owner, data.id)
    elseif not roll.ownerId then
        roll.ownerId = data.id
    end

    -- We don't need updates on canceled rolles
    if roll.status == Self.STATUS_CANCELED then
        return
    end

    -- Update the timeout
    if data.timeout > roll.timeout then
        self:ExtendTimeout(data.timeout)
    end
    
    -- Cancel the roll if the owner has canceled it
    if data.status == Self.STATUS_CANCELED and roll.status ~= Self.STATUS_CANCELED then
        roll:Cancel()
    else
        -- This stuff needs item data to be loaded
        roll.item:OnLoaded(function ()
            -- Start the roll if the owner has started it
            if data.status >= Self.STATUS_RUNNING and roll.status < Self.STATUS_RUNNING then
                roll:Start(data.started)
            end
            -- End the roll if the owner has ended it
            if data.status >= Self.STATUS_DONE and roll.status < Self.STATUS_DONE then
                roll:End(data.winner)
            end

            Addon.GUI.Rolls.Update()
        end)
    end

    Addon.GUI.Rolls.Update()

    return roll
end

-- Clear old rolls
function Self.Clear(self)
    local rolls = self and {self} or Util.TblFilter(Addon.rolls, function (roll, id)
        return roll.created + Self.CLEAR < time()
    end)
    
    for i, roll in pairs(rolls) do
        if roll.status  < Self.STATUS_DONE then
            roll:Cancel()
        end

        Addon.rolls[roll.id] = nil
    end

    Addon.GUI.Rolls.Update()
end

-- Check for and convert from/to PLR roll id

function Self.IsPlrId(id)
    return Util.StrStartsWith("" .. id, PLR_PREFIX)
end

function Self.ToPlrId(id)
    return PLR_PREFIX .. id
end

function Self.FromPlrId(id)
    return tonumber(("" .. id):sub(PLR_PREFIX:len() + 1))
end

-- Calculate the optimal timeout
function Self.GetTimeout()
    local items = 0

    if select(4, GetInstanceInfo()) == DIFFICULTY_DUNGEON_CHALLENGE then
        -- In M+ we get 2 items at the end of the dungeon, +1 if in time, +0.4 per keystone level above 15
        local _, level, _, onTime = C_ChallengeMode.GetCompletionInfo();
        items = 2 + (onTime and 1 or 0) + (level > 15 and math.ceil(0.4 * (level - 15)) or 0)
    else
        -- Normally we get 1 item per 5 players in the group
        items = math.ceil(GetNumGroupMembers() / 5)
    end

    return Self.TIMEOUT + items * Self.TIMEOUT_PER_ITEM
end

-------------------------------------------------------
--                     Rolling                       --
-------------------------------------------------------

-- Start a roll
function Self:Start(started)
    Addon:Verbose(L["ROLL_START"]:format(self.item.link, Comm.GetPlayerLink(self.owner)))

    self.item:OnLoaded(function ()
        self.item:GetFullInfo()

        -- Check if we can start he roll
        local valid, msg = self:Validate(Self.STATUS_PENDING)
        if not valid then
            Addon:Err(msg)
        else
            -- Update eligible players if not already done so
            if self.isOwner then
                self.item:GetEligible()
            end

            -- Start the roll
            self.started = started or time()
            self.status = Self.STATUS_RUNNING
            self:ShowRollFrame()

            -- Schedule timer to end the roll and hide the frame
            self.timer = Addon:ScheduleTimer(Self.Finish, self:GetTimeLeft(), self)

            -- Let the others know
            self:SendStatus()

            Addon.GUI.Rolls.Update()
        end
    end)

    return self
end

-- Add a roll now and start it later
function Self:Schedule()
    -- Don't schedule a 2nd time
    if self.timer then return end

    -- Start loading basic item info
    self.item:GetBasicInfo()

    self.timer = Addon:ScheduleTimer(function ()
        -- Start the roll if it hasn't been started after the waiting period
        if self.status == Self.STATUS_PENDING then 
            if self.isOwner or (self.item:ShouldBeBidOn() and (self.ownerId or self.item:GetFullInfo().isTradable)) then
                self.timer = nil
                self:Start()
            elseif not self.item.isEquippable then
                self:Clear()
            else
                self:Cancel()
            end

            Addon.GUI.Rolls.Update()
        end
    end, Self.DELAY)

    return self
end

-- Bid on a roll
function Self:Bid(answer, sender, isWhisper)
    answer = answer or Self.ANSWER_NEED
    sender = Util.GetName(sender or "player")
    local fromSelf = UnitIsUnit(sender, "player")

    -- Hide the roll frame
    if fromSelf then
        self:HideRollFrame()
    end
    
    -- Check if we can bid
    local valid, msg = self:Validate(Self.STATUS_RUNNING)
    if not valid then
        Addon:Err(msg)
    elseif not Util.TblFind(Self.ANSWERS, answer) then
        if fromSelf then
            Addon:Err(L["ERROR_ROLL_ANSWER_UNKNOWN_SELF"])
        else
            Addon:Verbose(L["ERROR_ROLL_ANSWER_UNKNOWN_OTHER"]:format(sender, self.item.link))
        end
    else
        if fromSelf then
            -- Print some text
            if answer == Self.ANSWER_PASS then
                Addon:Verbose(L["BID_PASS"]:format((self.item and self.item.link) or L["ITEM"], Comm.GetPlayerLink(self.owner)))
            else
                Addon:Verbose(L["BID_START"]:format(L["ROLL_ANSWER_" .. answer], (self.item and self.item.link) or L["ITEM"], Comm.GetPlayerLink(self.owner)))
            end
            
            -- Save the answer
            self.answer = answer
        end

        if self.isOwner then
            -- Register the bid
            Util.TblSet(self, {"bids", answer, sender}, isWhisper or false)
            
            -- Check if we can end it now or post to chat
            if not self:CheckEnd() and not self.posted and Comm.ShouldChat() then
                self:ExtendTimeLeft()

                Comm.ChatLine("ROLL_START", Comm.TYPE_GROUP, self.item.link)
                self.posted = true
            end
        elseif fromSelf then
            -- Send our bid to the owner
            self:SendBid()
        end

        Addon.GUI.Rolls.Update()
    end

    return self
end

-- Check if we should end the roll prematurely
function Self:CheckEnd()
    -- Only end running rolls that we own and that we answered already
    if not self.isOwner or self.status ~= Self.STATUS_RUNNING or not self.answer then
        return false
    end

    -- We voted need on our own item
    if self.answer == Self.ANSWER_NEED then
        self:End(self.owner)
        return true
    end

    -- Check if all eligible players have bid
    local bids = Util.TblFlatten(self.bids)
    if not Util.TblSearch(self.item:GetEligible(), function (ilvl, unit) return bids[unit] == nil end) then
        self:End()
        return true
    end

    return false
end

-- End a roll, including closing UI elements etc.
function Self:Finish(winner, whisper)
    if self.timer then
        Addon:CancelTimer(self.timer)
        self.timer = nil
    end

    if self.isOwner and self.status < Self.STATUS_DONE then
        self:End(winner, whisper)
    end

    self:HideRollFrame()
end

-- End a roll
function Self:End(winner, whisper)
    Addon:Verbose(L["ROLL_END"]:format(self.item.link, Comm.GetPlayerLink(self.owner)))
    
    -- Check if we can end he roll
    local valid, msg = self:Validate(Self.STATUS_RUNNING, winner)
    if not valid then
        Addon:Err(msg)
    else
        winner = winner and Util.GetName(winner) or nil

        if self.isOwner then
            if not winner then
                -- Set our own answer
                if not self.answer then
                    self:Bid(Self.ANSWER_PASS)

                    -- We posted it to chat, so we'll wait a bit longer before we end the roll
                    if self.posted then
                        return self
                    end
                end

                -- Determine a winner
                local bids = Util(Self.ANSWERS).Except(Self.ANSWER_PASS).Map(Util.FnPluckFrom(self.bids)).First()()
                if bids then
                    local names = Util.TblKeys(bids)
                    winner = names[math.random(#names)]
                end
            end

            -- Check if we should whisper the target
            if whisper == nil then
                whisper = Util.TblFlatten(self.bids)[winner]
            end
        end

        -- Update status
        self.status = Self.STATUS_DONE
        self:Award(winner, whisper)

        -- Let everyone know
        self:SendStatus()
    end

    return self
end

-- Select a winner
function Self:Award(winner, whisper)
    if self.status ~= Self.STATUS_DONE then
        self:Finish(winner, whisper)
    else
        -- Set winner
        self.winner = winner and Util.GetName(winner) or nil

        -- Let the player know, announce to chat and the winner
        if self.winner then
            -- It has already been traded
            if self.winner == self.owner then
                self:OnTraded(self.winner)
            end

            -- We won the item
            if UnitIsUnit(self.winner, "player") then
                if not self.isOwner or self.answer ~= Self.ANSWER_NEED then
                    if self.isOwner then
                        Addon:Info(L["ROLL_WINNER_OWN"]:format(self.item.link))
                    else
                        Addon:Info(L["ROLL_WINNER_SELF"]:format(self.item.link, Comm.GetPlayerLink(self.owner), Comm.GetTradeLink(self.owner)))
                    end

                    self:ShowAlertFrame()
                end

            -- Someone won our item
            elseif self.isOwner then
                Addon:Info(L["ROLL_WINNER_OTHER"]:format(Comm.GetPlayerLink(self.winner), self.item.link, Comm.GetTradeLink(self.winner)))

                -- Announce to chat
                if self.posted and Comm.ShouldChat() then
                    Comm.ChatLine("ROLL_WINNER", Comm.TYPE_GROUP, Util.GetFullName(self.winner), self.item.link)
                end

                -- Announce to target
                if whisper and Addon.db.profile.answer then
                    if Util.TblCount(self.item:GetEligible()) == 1 then
                        Comm.ChatLine("ROLL_ANSWER_YES", self.winner)
                    else
                        Comm.ChatLine("ROLL_WINNER_WHISPER", self.winner, self.item.link)
                    end
                end
            end
        end

        Addon.GUI.Rolls.Update()
    end

    return self
end

-- Cancel a roll
function Self:Cancel()
    if self.status == Self.STATUS_CANCELED then return end
    Addon:Verbose(L["ROLL_CANCEL"]:format(self.item.link, Comm.GetPlayerLink(self.owner)))

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
        
    Addon.GUI.Rolls.Update()
    
    return self
end

-- Trade with the owner or the winner of the roll
function Self:Trade()
    local target = self.item.isOwner and self.winner or self.winner == UnitName("player") and self.item.owner
    if target then
        Trade.Initiate(target)
    end
end

-- Called when the roll's item is traded
function Self:OnTraded(target)
    if self.status < Self.STATUS_DONE then
        self:Cancel()
    end

    self.traded = target
        
    Addon.GUI.Rolls.Update()
end

-------------------------------------------------------
--                      Frames                       --
-------------------------------------------------------

-- Get the loot frame for a loot id
function Self:GetRollFrame()
    local id, frame = self:GetPlrId()

    for i=1, NUM_GROUP_LOOT_FRAMES do
        frame = _G["GroupLootFrame"..i];
        if frame.rollID == id then
            return frame
        end
    end
end

-- Show the roll frame
function Self:ShowRollFrame()
    GroupLootFrame_OpenNewFrame(self:GetPlrId(), self:GetRunTime())
    self.shown = self:GetRollFrame() ~= nil
end

-- Hide the roll frame
function Self:HideRollFrame()
    local frame = self:GetRollFrame()
    if frame then
        GroupLootContainer_RemoveFrame(GroupLootContainer, frame)
    end
end

-- Show the alert frame for winning an item
function Self:ShowAlertFrame()
    -- itemLink, quantity, rollType, roll, specID, isCurrency, showFactionBG, lootSource, lessAwesome, isUpgraded, wonRoll, showRatedBG, plrId
    Addon.GUI.LootAlertSystem:AddAlert(self.item.link, 1, nil, nil, nil, false, false, nil, false, false, true, false, self.id)
end

-------------------------------------------------------
--                       Comm                        --
-------------------------------------------------------

-- Send the roll status to others
function Self:SendStatus()
    if not self.isOwner then return end

    local data = Util.TblSelect(self, "id", "status", "started", "timeout", "winner")
    data.winner = data.winner and Util.GetFullName(data.winner)
    data.item = self.item.link

    Comm.SendData(Comm.EVENT_ROLL_STATUS, data, target or Comm.TYPE_GROUP)
end

-- Send a bid via addon message, whisper or roll in chat
function Self:SendBid(answer)
    answer = answer or self.answer

    if self.ownerId then
        Comm.SendData(Comm.EVENT_BID, {
            id = self.ownerId,
            answer = answer
        }, self.owner)
    elseif answer ~= Self.ANSWER_PASS then
        if self.posted then
            if Addon.db.profile.roll then
                RandomRoll("1", "100")
            end
        elseif Comm.ShouldChat(self.owner) then
            Comm.ChatBid(self.owner, self.item.link)
            Addon:Info(L["BID_CHAT"]:format(Comm.GetPlayerLink(self.owner), self.item.link, Comm.GetTradeLink(self.owner)))
        else
            Addon:Info(L["BID_NO_CHAT"]:format(Comm.GetPlayerLink(self.owner), self.item.link, Comm.GetTradeLink(self.owner)))
        end
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
--                       Other                       --
-------------------------------------------------------

-- Check if the given unit is eligible
function Self:UnitIsEligible(unit, checkIlvl)
    local val = self.item:GetEligible(unit)
    if checkIlvl then return val else return val ~= nil end
end

-- Check if a unit has bid, optionally with the given answer
function Self:UnitHasBid(unit, answer)
    if answer then
        return Util.TblGet(self.bids or {}, {answer, unit}) ~= nil
    else
        return Util.TblSearch(self.bids or {}, function (bids) return bids[unit] ~= nil end) ~= nil
    end
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

-- Get the rolls id with PLR prefix
function Self:GetPlrId()
    return Self.ToPlrId(self.id)
end

-- Get a player: answer map of all bids
function Self:GetBids()
    return Util(self.bids).Map(function (t, answer)
        return Util.TblMap(t, Util.FnVal(answer))
    end).Flatten()()
end

-- Some common error checks for a loot roll
function Self:Validate(status, unit)
    if Addon.DEBUG then
        return true
    end

    if status and self.status ~= status then
        return false, L["ERROR_ROLL_STATUS_NOT_" .. status]
    elseif not UnitExists(self.owner) then
        return false, L["ERROR_PLAYER_NOT_FOUND"]:format(Comm.GetPlayerLink(self.owner))
    elseif unit and not UnitExists(unit) then
        return false, L["ERROR_PLAYER_NOT_FOUND"]:format(unit)
    elseif not self.item.isTradable then
        return false, L["ERROR_ITEM_NOT_TRADABLE"]
    elseif not IsInGroup() then 
        return false, L["ERROR_NOT_IN_GROUP"]
    else
        return true
    end
end

-- Export

Addon.Roll = Self