local Name, Addon = ...
local L = LibStub("AceLocale-3.0"):GetLocale(Name)
local AceGUI = LibStub("AceGUI-3.0")
local Comm = Addon.Comm
local Inspect = Addon.Inspect
local Masterloot = Addon.Masterloot
local Roll = Addon.Roll
local Trade = Addon.Trade
local Unit = Addon.Unit
local Util = Addon.Util
local Self = Addon.GUI

-------------------------------------------------------
--                  Popup dialogs                    --
-------------------------------------------------------


Self.DIALOG_ROLL_CANCEL = "PLR_ROLL_CANCEL"
StaticPopupDialogs[Self.DIALOG_ROLL_CANCEL] = {
    text = L["DIALOG_ROLL_CANCEL"],
    button1 = YES,
    button2 = NO,
    OnAccept = function(self, roll)
        roll:Cancel()
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3
}

Self.DIALOG_ROLL_RESTART = "PLR_ROLL_RESTART"
StaticPopupDialogs[Self.DIALOG_ROLL_RESTART] = {
    text = L["DIALOG_ROLL_RESTART"],
    button1 = YES,
    button2 = NO,
    OnAccept = function(self, roll)
        roll:Restart()
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3
}

Self.DIALOG_MASTERLOOT_ASK = "PLR_MASTERLOOT_ASK"
StaticPopupDialogs[Self.DIALOG_MASTERLOOT_ASK] = {
    text = L["DIALOG_MASTERLOOT_ASK"],
    button1 = YES,
    button2 = NO,
    timeout = 30,
    whileDead = true,
    hideOnEscape = false,
    preferredIndex = 3
}

-------------------------------------------------------
--                     Dropdowns                     --
-------------------------------------------------------

local dropDown

-- Masterloot
dropDown = CreateFrame("FRAME", "PlrMasterlootDropDown", UIParent, "UIDropDownMenuTemplate")
UIDropDownMenu_Initialize(dropDown, function (self, level, menuList)
    local info = UIDropDownMenu_CreateInfo()
    info.text, info.func = L["MENU_MASTERLOOT_START"], function ()
        Masterloot.SetMasterlooter("player")
    end
    UIDropDownMenu_AddButton(info)
    info.text, info.func = L["MENU_MASTERLOOT_SEARCH"], function ()
        Comm.SendData(Comm.EVENT_MASTERLOOT_ASK)
    end
    UIDropDownMenu_AddButton(info)
end, "MENU")
Self.DROPDOWN_MASTERLOOT = dropDown

-------------------------------------------------------
--                 LootAlertSystem                   --
-------------------------------------------------------

-- Setup
local function PLR_LootWonAlertFrame_SetUp(self, itemLink, quantity, rollType, roll, specID, isCurrency, showFactionBG, lootSource, lessAwesome, isUpgraded, wonRoll, showRatedBG, rollId)
    self.rollId = rollId

    LootWonAlertFrame_SetUp(self, itemLink, quantity, rollType, roll, specID, isCurrency, showFactionBG, lootSource, lessAwesome, isUpgraded, wonRoll, showRatedBG)
end

-- OnClick
function PLR_LootWonAlertFrame_OnClick(self, button, down)
    if not AlertFrame_OnClick(self, button, down) then
        local roll = Roll.Get(self.rollId)

        if roll and not roll.traded then
            Trade.Initiate(roll.item.owner)
        end
    end
end

Self.LootAlertSystem = AlertFrame:AddQueuedAlertFrameSubSystem("PLR_LootWonAlertFrameTemplate", PLR_LootWonAlertFrame_SetUp, 6, math.huge);

-------------------------------------------------------
--                   Rolls frame                     --
-------------------------------------------------------

local Rolls = {
    frames = {},
    filter = {all = false, canceled = false, done = true, awarded = true, traded = false},
    status = {width = 700, height = 300},
    open = {}
}

-- Show the rolls frame
function Rolls.Show()
    if Rolls.frames.window then
        Rolls.frames.window.frame:Show()
    else
        -- WINDOW

        Rolls.frames.window = Self("Window")
            .SetLayout(nil)
            .SetTitle("PersoLootRoll - " .. L["ROLLS"])
            .SetCallback("OnClose", function (self)
                Rolls.status.width = self.frame:GetWidth()
                Rolls.status.height = self.frame:GetHeight()
                self.optionsbutton:Release()
                self.optionsbutton = nil
                self:Release()
                wipe(Rolls.frames)
                wipe(Rolls.open)
            end)
            .SetMinResize(700, 120)
            .SetStatusTable(Rolls.status)()

        do
            local window = Rolls.frames.window

            -- Options button
            f = Self("Icon")
                .SetImage("Interface\\Buttons\\UI-OptionsButton")
                .SetImageSize(14, 14).SetHeight(16).SetWidth(16)
                .SetCallback("OnClick", function (self)
                    Addon:ShowOptions()
                    GameTooltip:Hide()
                end)
                .SetCallback("OnEnter", function (self)
                    GameTooltip:SetOwner(self.frame, "ANCHOR_TOP")
                    GameTooltip:SetText(OPTIONS, 1, 1, 1, 1)
                    GameTooltip:Show()
                end)
                .SetCallback("OnLeave", Self.TooltipHide)()
            f.OnRelease = function (self)
                self.image:SetPoint("TOP", 0, -5)
                self.frame:SetFrameStrata("FULLSCREEN_DIALOG")
                self.OnRelease = nil
            end
            f.image:SetPoint("TOP", 0, -2)
            f.frame:SetParent(window.frame)
            f.frame:SetPoint("TOPRIGHT", window.closebutton, "TOPLEFT", -8, -8)
            f.frame:SetFrameStrata("TOOLTIP")
            f.frame:Show()

            window.optionsbutton = f
        end

        -- FILTER

        Rolls.frames.filter = Self("SimpleGroup")
            .SetLayout(nil)
            .AddTo(Rolls.frames.window)
            .SetPoint("BOTTOMLEFT", 0, 0)
            .SetPoint("BOTTOMRIGHT", -25, 0)
            .SetHeight(24)()
        
        do
            f = Self("Label")
                .SetFontObject(GameFontNormal)
                .SetText(L["FILTER"] .. ":")
                .AddTo(Rolls.frames.filter)
                .SetPoint("TOPLEFT")()
            f:SetWidth(f.label:GetStringWidth() + 30)
            f.label:SetPoint("TOPLEFT", 15, -6)

            for _,key in ipairs({"all", "done", "awarded", "traded", "canceled"}) do
                Self.CreateFilterCheckbox(key)
            end

            -- ML action
            f = Self("Icon")
                .AddTo(Rolls.frames.filter)
                .SetCallback("OnEnter", function (self)
                    GameTooltip:SetOwner(self.frame, "ANCHOR_TOP")
                    GameTooltip:SetText(L["TIP_MASTERLOOT_" .. (Masterloot.GetMasterlooter() and "STOP" or "START")])
                    GameTooltip:Show()
                end)
                .SetCallback("OnLeave", Self.TooltipHide)
                .SetCallback("OnClick", function (self)
                    local ml = Masterloot.GetMasterlooter()
                    if ml then
                        Masterloot.SetMasterlooter(nil)
                    else
                        ToggleDropDownMenu(1, nil, Self.DROPDOWN_MASTERLOOT, "cursor", 3, -3)
                    end
                end)
                .SetImageSize(16, 16).SetHeight(16).SetWidth(16)
                .SetPoint("TOP", 0, -4)
                .SetPoint("RIGHT")()
            f.image:SetPoint("TOP")

            -- ML
            f = Self("InteractiveLabel")
                .SetFontObject(GameFontNormal)
                .AddTo(Rolls.frames.filter)
                .SetText()
                .SetCallback("OnEnter", function (self)
                    local ml = Masterloot.GetMasterlooter()
                    if ml then
                        local s = Masterloot.session
                        local council = not s.council and "-" or Util(s.council).Keys().Map(function (unit)
                            return Unit.ColoredName(Unit.ShortenedName(unit), unit)
                        end).Concat(", ")()
                        local bids = L[s.bidPublic and "PUBLIC" or "PRIVATE"]
                        local votes = L[s.votePublic and "PUBLIC" or "PRIVATE"]

                        GameTooltip:SetOwner(self.frame, "ANCHOR_BOTTOM")
                        GameTooltip:SetText(L["TIP_MASTERLOOT"] .. "\n")
                        GameTooltip:AddLine(L["TIP_MASTERLOOT_INFO"]:format(Unit.ColoredName(ml), council, bids, votes), 1, 1, 1)

                        if Masterloot.IsMasterlooter() then
                            GameTooltip:AddLine("\n" .. L["TIP_MASTERLOOTING"])

                            local c = Unit.Color("player")
                            GameTooltip:AddLine(ml, c.r, c.g, c.b, false)
                            for unit,_ in pairs(Masterloot.masterlooting) do
                                local c = Unit.Color(unit)
                                GameTooltip:AddLine(unit, c.r, c.g, c.b, false)
                            end
                        end

                        GameTooltip:Show()
                    end
                end)
                .SetCallback("OnLeave", Self.TooltipHide)
                .SetCallback("OnClick", function ()
                    if Masterloot.GetMasterlooter() then ChatFrame_SendSmartTell(Masterloot.GetMasterlooter()) end
                end)
                .SetHeight(12)
                .SetPoint("TOP", 0, -6)
                .SetPoint("RIGHT", f.frame, "LEFT")()
        end

        -- SCROLL

        Rolls.frames.scroll = Self("ScrollFrame")
            .SetLayout("PLR_Table")
            .SetUserData("table", {
                columns = {20, 1, {25, 100}, {25, 100}, {25, 100}, {25, 100}, {25, 100}, {25, 100}, 6 * 20 - 4},
                space = 10
            })
            .AddTo(Rolls.frames.window)
            .SetPoint("TOPRIGHT")
            .SetPoint("BOTTOMLEFT", Rolls.frames.filter.frame, "TOPLEFT", 0, 8)()

        do
            local scroll = Rolls.frames.scroll

            local header = {"ID", "ITEM", "LEVEL", "OWNER", "ML", "STATUS", "YOUR_BID", "WINNER"}
            for i,v in pairs(header) do
                Self("Label").SetFontObject(GameFontNormal).SetText(Util.StrUcFirst(L[v])).SetColor(1, 0.82, 0).AddTo(scroll)
            end

            local actions = Self("SimpleGroup")
                .SetLayout(nil)
                .SetHeight(16)
                .SetWidth(17)
                .SetUserData("cell", {alignH = "end"})
                .AddTo(scroll)()
            local backdrop = {f.frame:GetBackdropColor()}
            actions.frame:SetBackdropColor(0, 0, 0, 0)
            actions.OnRelease = function (self)
                self.frame:SetBackdropColor(unpack(backdrop))
                self.OnRelease = nil
            end
            
            -- Toggle all
            f = Self.CreateIconButton("UI-MinusButton", actions, function (self)
                for i,child in pairs(scroll.children) do
                    if child:GetUserData("isDetails") then child.frame:Hide() end
                end
                Rolls.Update()
            end)
            f.image:SetPoint("TOP", 0, 2)
            f.frame:SetPoint("TOPRIGHT")
        end

        Rolls.Update()
    end
end

-- Update the rolls frame
local createFn = function (scroll)
    -- ID
    Self("Label")
        .SetFontObject(GameFontNormal)
        .AddTo(scroll)

    -- Item
    Self("InteractiveLabel")
        .SetFontObject(GameFontNormal)
        .SetWidth(217)
        .SetCallback("OnEnter", function (self)
            GameTooltip:SetOwner(self.frame, "ANCHOR_LEFT")
            GameTooltip:SetHyperlink(self:GetUserData("link"))
            GameTooltip:Show()
        end)
        .SetCallback("OnLeave", Self.TooltipHide)
        .SetCallback("OnClick", function (self)
            if IsModifiedClick("DRESSUP") then
                DressUpItemLink(self:GetUserData("link"))
            elseif IsModifiedClick("CHATLINK") then
                ChatEdit_InsertLink(self:GetUserData("link"))
            end
        end)
        .AddTo(scroll)
    
    -- Ilvl
    Self("Label")
        .SetFontObject(GameFontNormal)
        .AddTo(scroll)

    -- Owner, ML, Status, Your bid, Winner
    Self.CreateUnitLabel(scroll)
    Self.CreateUnitLabel(scroll)
    Self("Label").SetFontObject(GameFontNormal).AddTo(scroll)
    Self("Label").SetFontObject(GameFontNormal).AddTo(scroll)
    Self.CreateUnitLabel(scroll)

    -- Actions
    f = Self("SimpleGroup")
        .SetLayout(nil)
        .SetHeight(16)
        .SetUserData("cell", {alignH = "end"})
        .AddTo(scroll)()
    local backdrop = {f.frame:GetBackdropColor()}
    f.frame:SetBackdropColor(0, 0, 0, 0)
    f.OnRelease = function (self)
        self.frame:SetBackdropColor(unpack(backdrop))
        self.OnRelease = nil
    end

    do
        local actions = f

        -- Need
        Self.CreateIconButton("UI-GroupLoot-Dice", actions, function (self)
            self:GetUserData("roll"):Bid(Roll.BID_NEED)
        end, NEED, 14, 14)

        -- Greed
        Self.CreateIconButton("UI-GroupLoot-Coin", actions, function (self)
            self:GetUserData("roll"):Bid(Roll.BID_GREED)
        end, GREED)

        -- Pass
        Self.CreateIconButton("UI-GroupLoot-Pass", actions, function (self)
            self:GetUserData("roll"):Bid(Roll.BID_PASS)
        end, PASS, 13, 13)

        -- Advertise
        Self.CreateIconButton("UI-GuildButton-MOTD", actions, function (self)
            self:GetUserData("roll"):Advertise(true)
        end, L["ADVERTISE"], 13, 13)

        -- Award randomly
        Self.CreateIconButton("Interface\\GossipFrame\\BankerGossipIcon", actions, function (self)
            self:GetUserData("roll"):End(true)
        end, L["AWARD_RANDOMLY"], 11, 11)

        -- Trade
        Self.CreateIconButton("Interface\\GossipFrame\\VendorGossipIcon", actions, function (self)
            self:GetUserData("roll"):Trade()
        end, TRADE, 13, 13)

        -- Restart
        f = Self.CreateIconButton("UI-RotationLeft-Button", actions, function (self)
            local dialog = StaticPopup_Show(Self.DIALOG_ROLL_RESTART)
            if dialog then
                dialog.data = self:GetUserData("roll")
            end
        end, L["RESTART"])
        f.image:SetPoint("TOP", 0, 2)
        f.image:SetTexCoord(0.07, 0.93, 0.07, 0.93)

        -- Cancel
        f = Self.CreateIconButton("CancelButton", actions, function (self)
            local dialog = StaticPopup_Show(Self.DIALOG_ROLL_CANCEL)
            if dialog then
                dialog.data = self:GetUserData("roll")
            end
        end, CANCEL)
        f.image:SetPoint("TOP", 0, 1)
        f.image:SetTexCoord(0.2, 0.8, 0.2, 0.8)

        -- Toggle
        f = Self.CreateIconButton("UI-PlusButton", actions, function (self)
            local roll = self:GetUserData("roll")
            local details = self:GetUserData("details")

            if details:IsShown() then
                Rolls.open[roll.id] = nil
                details.frame:Hide()
                self:SetImage("Interface\\Buttons\\UI-PlusButton-Up")
            else
                Rolls.open[roll.id] = true
                Rolls.UpdateDetails(details, roll)
                self:SetImage("Interface\\Buttons\\UI-MinusButton-Up")
            end
            self.parent.parent:DoLayout()
        end)
        f.image:SetPoint("TOP", 0, 2)
    end

    -- Details
    local details = Self("SimpleGroup")
        .SetLayout("PLR_Table")
        .SetFullWidth(true)
        .SetUserData("isDetails", true)
        .SetUserData("cell", {colspan = 99})
        .SetUserData("table", {
            columns = {1, {25, 100}, {25, 100}, {25, 100}, 100},
            spaceH = 10,
            spaceV = 2
        })
        .AddTo(scroll)()

    do
        details.content:SetPoint("TOPLEFT", details.frame, "TOPLEFT", 8, -8)
        details.content:SetPoint("BOTTOMRIGHT", details.frame, "BOTTOMRIGHT", -8, 8)
        local layoutFinished = details.LayoutFinished
        local onWidthSet = details.OnWidthSet
        local onHeightSet = details.OnHeightSet
        details.LayoutFinished, details.OnWidthSet, details.OnHeightSet = function (self, width, height)
            layoutFinished(self, width and width + 16 or nil, height and height + 16 or nil)
        end
        details.OnRelease = function (self)
            self.content:SetPoint("TOPLEFT")
            self.content:SetPoint("BOTTOMRIGHT")
            self.LayoutFinished, self.OnWidthSet, self.OnHeightSet = layoutFinished, onWidthSet, onHeightSet
            self.OnRelease = nil
        end
    
        local header = {"PLAYER", "ITEM_LEVEL", "BID", "VOTES"}
        for i,v in pairs(header) do
            local f = Self("Label").SetFontObject(GameFontNormal).SetText(Util.StrUcFirst(L[v])).SetColor(1, 0.82, 0)()
            if i == #header then
                f:SetUserData("cell", {colspan = 2})
            end
            details:AddChild(f)
        end

        details.frame:Hide()
    end
end
local updateFn = function (roll, children, it)
    -- ID
    Self(children[it()]).SetText(roll.id).Show()

    -- Item
    Self(children[it()])
        .SetText(roll.item.link)
        .SetImage(roll.item.texture)
        .SetUserData("link", roll.item.link)
        .Show()

    -- Ilvl
    Self(children[it()]).SetText(roll.item:GetBasicInfo().level or "-").Show()

    -- Owner
    Self(children[it()])
        .SetText(Unit.ColoredName(Unit.ShortenedName(roll.item.owner), roll.item.owner))
        .SetUserData("unit", roll.item.owner)
        .Show()

    -- ML
    Self(children[it()])
        .SetText(roll:HasMasterlooter() and Unit.ColoredName(Unit.ShortenedName(roll.owner), roll.owner) or "-")
        .SetUserData("unit", roll:HasMasterlooter() and roll.owner or nil)
        .Show()

    -- Status
    Self(children[it()]).SetText(roll.traded and L["ROLL_TRADED"] or roll.winner and L["ROLL_AWARDED"] or L["ROLL_STATUS_" .. roll.status]).Show()

    -- Your Bid
    Self(children[it()]).SetText(roll.bid and L["ROLL_BID_" .. roll.bid] or "-").Show()

    -- Winner
    Self(children[it()])
        .SetText(roll.winner and Unit.ColoredName(Unit.ShortenedName(roll.winner), roll.winner) or "-")
        .SetUserData("unit", roll.winner or nil)
        .Show()

    -- Actions
    do
        local actions = children[it()]
        local details = children[it(0) + 1]
        local children = actions.children
        local it = Util.Iter()

        local canBid = not roll.bid and roll:UnitCanBid("player")
        local canBeAwarded = roll:CanBeAwarded(true)

        -- Need
        Self(children[it()]).SetUserData("roll", roll).Toggle(canBid)
        -- Greed
        Self(children[it()]).SetUserData("roll", roll).Toggle(canBid and (roll.ownerId or roll.itemOwnerId))
        -- Pass
        Self(children[it()]).SetUserData("roll", roll).Toggle(canBid)
        -- Advertise
        Self(children[it()]).SetUserData("roll", roll).Toggle(roll:ShouldAdvertise(true))
        -- Award randomly
        Self(children[it()]).SetUserData("roll", roll).Toggle(roll.status == roll.STATUS_DONE and canBeAwarded and Util.TblCountNot(roll.bids, Roll.BID_PASS) > 0)
        -- Trade
        Self(children[it()]).SetUserData("roll", roll).Toggle(not roll.traded and roll.winner and (roll.item.isOwner or roll.isWinner))
        -- Restart
        Self(children[it()]).SetUserData("roll", roll).Toggle(roll:CanBeRestarted())
        -- Cancel
        Self(children[it()]).SetUserData("roll", roll).Toggle(canBeAwarded)
        -- Toggle
        Self(children[it()])
            .SetImage("Interface\\Buttons\\UI-" .. (Rolls.open[roll.id] and "Minus" or "Plus") .. "Button-Up")
            .SetUserData("roll", roll)
            .SetUserData("details", details)

        local n, prev = 0
        for i=#children,1,-1 do
            local child = children[i]
            if child:IsShown() then
                if not prev then
                    child.frame:SetPoint("TOPRIGHT")
                else
                    child.frame:SetPoint("TOPRIGHT", prev.frame, "TOPLEFT", -4, 0)
                end
                n, prev = n + 1, child
            end
        end

        Self(actions).SetWidth(max(0, 20 * n - 4)).Show()
    end

    -- Details
    local details = children[it()]
    if Rolls.open[roll.id] then
        Rolls.UpdateDetails(details, roll)
    else
        details.frame:Hide()
    end
end
local filterFn = function (roll)
    return (Rolls.filter.all or roll.isOwner or roll.item.isOwner or roll.item:GetEligible("player"))
       and (Rolls.filter.canceled or roll.status >= Roll.STATUS_RUNNING)
       and (Rolls.filter.done or (roll.status ~= Roll.STATUS_DONE))
       and (Rolls.filter.awarded or not roll.winner)
       and (Rolls.filter.traded or not roll.traded)
end
function Rolls.Update()
    if not Rolls.frames.window then return end
    local f

    -- SCROLL

    local scroll = Rolls.frames.scroll
    scroll:PauseLayout()

    Self.UpdateRows(scroll, Util(Addon.rolls).CopyFilter(filterFn).SortBy("id")(), createFn, updateFn, 9)

    scroll:ResumeLayout()
    scroll:DoLayout()

    -- FILTER

    local filter = Rolls.frames.filter
    local it = Util.Iter(1)

    filter.children[it()]:SetValue(Rolls.filter.all)
    filter.children[it()]:SetValue(Rolls.filter.done)
    filter.children[it()]:SetValue(Rolls.filter.awarded)
    filter.children[it()]:SetValue(Rolls.filter.traded)
    filter.children[it()]:SetValue(Rolls.filter.canceled)

    -- ML action
    local ml = Masterloot.GetMasterlooter()
    filter.children[it()]:SetImage(ml and "Interface\\Buttons\\UI-StopButton" or "Interface\\GossipFrame\\WorkOrderGossipIcon")

    -- ML
    f = Self(filter.children[it()]).SetText(L["ML"] .. ": " .. (ml and Unit.ColoredName(Unit.ShortenedName(ml)) or ""))
end

-- Hide the rolls frame
function Rolls.Hide()
    if Rolls.frames.window then
        Rolls.frames.window.frame:Hide()
    end
end

-- Toggle the rolls frame
function Rolls.Toggle()
    if Rolls.frames.window then
        Rolls.Hide()
    else
        Rolls.Show()
    end
end

-- Update the details view of a row
local createFn = function (details)
    -- Unit, Ilvl, Bid, Votes
    Self.CreateUnitLabel(details)
    Self("Label").SetFontObject(GameFontNormal).AddTo(details)
    Self("Label").SetFontObject(GameFontNormal).AddTo(details)
    Self("Label").SetFontObject(GameFontNormal).AddTo(details)

    -- Actions
    local f = Self("Button")
        .SetWidth(100)
        .SetCallback("OnClick", function (self)
            local roll = self:GetUserData("roll")
            if roll:CanBeAwardedTo(self:GetUserData("unit"), true) then
                roll:Finish(self:GetUserData("unit"))
            elseif roll:UnitCanVote() then
                roll:Vote(roll.vote ~= self:GetUserData("unit") and self:GetUserData("unit") or nil)
            end
        end)()
    f.text:SetFont(GameFontNormal:GetFont())
    details:AddChild(f)
end
local updateFn = function (player, children, it, roll, canBeAwarded, canVote)
    -- Unit
    Self(children[it()])
        .SetText(Unit.ColoredName(Unit.ShortenedName(player.unit), player.unit))
        .SetUserData("unit", player.unit)
        .Show()

    -- Ilvl, Bid, Votes
    Self(children[it()]).SetText(player.ilvl).Show()
    Self(children[it()]).SetText(player.bid and L["ROLL_BID_" .. player.bid] or "-").Show()
    Self(children[it()]).SetText(player.votes > 0 and player.votes or "-").Show()

    -- Actions
    local txt = canBeAwarded and L["AWARD"]
        or canVote and (roll.vote == player.unit and L["VOTE_WITHDRAW"] or L["VOTE"])
        or "-"
    Self(children[it()])
        .SetText(txt)
        .SetDisabled(not (canBeAwarded or canVote))
        .SetUserData("unit", player.unit)
        .SetUserData("roll", roll)
        .Show()
end
function Rolls.UpdateDetails(details, roll)
    details.frame:Show()
    details:PauseLayout()

    local players = Util({}).Merge(roll.item:GetEligible(), roll.bids).FoldL(function (u, val, unit)
        tinsert(u, {
            unit = unit,
            ilvl = roll.item:GetLevelForLocation(unit),
            bid = type(val) == "number" and val or nil,
            votes = Util.TblCountVal(roll.votes, unit)
        })
        return u
    end, {}, true).SortBy("bid", 99, false, "votes", 0, true, "ilvl", 0, false, "unit")()

    Self.UpdateRows(details, players, createFn, updateFn, 4, roll, roll:CanBeAwarded(true), roll:UnitCanVote())

    details:ResumeLayout()
end

Self.Rolls = Rolls

-------------------------------------------------------
--               AceGUI table layout                 --
-------------------------------------------------------

-- Get alignment method and value. Possible alignment methods are a callback, a number, "start", "middle", "end", "fill" or "TOPLEFT", "BOTTOMRIGHT" etc.
local GetAlign = function (dir, tableObj, colObj, cellObj, cell, child)
    local fn = cellObj and (cellObj["align" .. dir] or cellObj.align)
            or colObj and (colObj["align" .. dir] or colObj.align)
            or tableObj["align" .. dir] or tableObj.align
            or "CENTERLEFT"
    local child, cell, val = child or 0, cell or 0, nil

    if type(fn) == "string" then
        fn = fn:lower()
        fn = dir == "V" and (fn:sub(1, 3) == "top" and "start" or fn:sub(1, 6) == "bottom" and "end" or fn:sub(1, 6) == "center" and "middle")
          or dir == "H" and (fn:sub(-4) == "left" and "start" or fn:sub(-5) == "right" and "end" or fn:sub(-6) == "center" and "middle")
          or fn
        val = (fn == "start" or fn == "fill") and 0 or fn == "end" and cell - child or (cell - child) / 2
    elseif type(fn) == "function" then
        val = fn(child or 0, cell, dir)
    else
        val = fn
    end

    return fn, max(0, min(val, cell))
end

-- Get width or height for multiple cells combined
local GetDimension = function (dir, laneDim, from, to, space)
    local dim = 0
    for i=from,to do
        dim = dim + (laneDim[i] or 0)
    end
    return dim + max(0, to - from) * (space or 0)
end

--[[ Options
============
Container:
 - columns ({col, col, ...}): Column settings. "col" can be a number (<= 0: content width, <1: rel. width, <10: weight, >=10: abs. width) or a table with column setting.
 - space, spaceH, spaceV: Overall, horizontal and vertical spacing between cells.
 - align, alignH, alignV: Overall, horizontal and vertical cell alignment. See GetAlign() for possible values.
Columns:
 - width: Fixed column width (nil or <=0: content width, <1: rel. width, >=1: abs. width).
 - min or 1: Min width for content based width
 - max or 2: Max width for content based width
 - weight: Flexible column width. The leftover width after accounting for fixed-width columns is distributed to weighted columns according to their weights.
 - align, alignH, alignV: Overwrites the container setting for alignment.
Cell:
 - colspan: Makes a cell span multiple columns.
 - rowspan: Makes a cell span multiple rows.
 - align, alignH, alignV: Overwrites the container and column setting for alignment.
]]
AceGUI:RegisterLayout("PLR_Table", function (content, children)
    local obj = content.obj
    obj:PauseLayout()

    local tableObj = obj:GetUserData("table")
    local cols = tableObj.columns
    local spaceH = tableObj.spaceH or tableObj.space or 0
    local spaceV = tableObj.spaceV or tableObj.space or 0
    local totalH = (content:GetWidth() or content.width or 0) - spaceH * (#cols - 1)
    
    -- We need to reuse these because layout events can come in very frequently
    local layoutCache = obj:GetUserData("layoutCache")
    if not layoutCache then
        layoutCache = {{}, {}, {}, {}, {}, {}}
        obj:SetUserData("layoutCache", layoutCache)
    end
    local t, laneH, laneV, rowspans, rowStart, colStart = unpack(layoutCache)
    
    -- Create the grid
    local n, slotFound = 0
    for i,child in ipairs(children) do
        if child:IsShown() then
            repeat
                n = n + 1
                local col = (n - 1) % #cols + 1
                local row = ceil(n / #cols)
                local rowspan = rowspans[col]
                local cell = rowspan and rowspan.child or child
                local cellObj = cell:GetUserData("cell")
                slotFound = not rowspan

                -- Rowspan
                if not rowspan and cellObj and cellObj.rowspan then
                    rowspan = {child = child, from = row, to = row + cellObj.rowspan - 1}
                    rowspans[col] = rowspan
                end
                if rowspan and i == #children then
                    rowspan.to = row
                end

                -- Colspan
                local colspan = max(0, min((cellObj and cellObj.colspan or 1) - 1, #cols - col))
                n = n + colspan

                -- Place the cell
                if not rowspan or rowspan.to == row then
                    t[n] = cell
                    rowStart[cell] = rowspan and rowspan.from or row
                    colStart[cell] = col

                    if rowspan then
                        rowspans[col] = nil
                    end
                end
            until slotFound
        end
    end

    local rows = ceil(n / #cols)

    -- Determine fixed size cols and collect weights
    local extantH, totalWeight = totalH, 0
    for col,colObj in ipairs(cols) do
        laneH[col] = 0

        if type(colObj) == "number" then
            colObj = {[colObj >= 1 and colObj < 10 and "weight" or "width"] = colObj}
            cols[col] = colObj
        end

        if colObj.weight then
            -- Weight
            totalWeight = totalWeight + (colObj.weight or 1)
        else
            if not colObj.width or colObj.width <= 0 then
                -- Content width
                for row=1,rows do
                    local child = t[(row - 1) * #cols + col]
                    if child then
                        local f = child.frame
                        f:ClearAllPoints()
                        local childH = f:GetWidth() or 0
    
                        laneH[col] = max(laneH[col], childH - GetDimension("H", laneH, colStart[child], col - 1, spaceH))
                    end
                end

                laneH[col] = max(colObj.min or colObj[1] or 0, min(laneH[col], colObj.max or colObj[2] or laneH[col]))
            else
                -- Rel./Abs. width
                laneH[col] = colObj.width < 1 and colObj.width * totalH or colObj.width
            end
            extantH = max(0, extantH - laneH[col])
        end
    end

    -- Determine sizes based on weight
    local scale = totalWeight > 0 and extantH / totalWeight or 0
    for col,colObj in pairs(cols) do
        if colObj.weight then
            laneH[col] = scale * colObj.weight
        end
    end

    -- Arrange children
    for row=1,rows do
        local rowV = 0

        -- Horizontal placement and sizing
        for col=1,#cols do
            local child = t[(row - 1) * #cols + col]
            if child then
                local colObj = cols[colStart[child]]
                if not child.GetUserData then Util.Dump(row, col, (row - 1) * #cols + col, child) end
                local cellObj = child:GetUserData("cell")
                local offsetH = GetDimension("H", laneH, 1, colStart[child] - 1, spaceH) + (colStart[child] == 1 and 0 or spaceH)
                local cellH = GetDimension("H", laneH, colStart[child], col, spaceH)
                
                local f = child.frame
                f:ClearAllPoints()
                local childH = f:GetWidth() or 0

                local alignFn, align = GetAlign("H", tableObj, colObj, cellObj, cellH, childH)
                f:SetPoint("LEFT", content, offsetH + align, 0)
                if child:IsFullWidth() or alignFn == "fill" or childH > cellH then
                    f:SetPoint("RIGHT", content, "LEFT", offsetH + align + cellH, 0)
                end
                
                if child.DoLayout then
                    child:DoLayout()
                end

                rowV = max(rowV, (f:GetHeight() or 0) - GetDimension("V", laneV, rowStart[child], row - 1, spaceV))
            end
        end

        laneV[row] = rowV

        -- Vertical placement and sizing
        for col=1,#cols do
            local child = t[(row - 1) * #cols + col]
            if child then
                local colObj = cols[colStart[child]]
                local cellObj = child:GetUserData("cell")
                local offsetV = GetDimension("V", laneV, 1, rowStart[child] - 1, spaceV) + (rowStart[child] == 1 and 0 or spaceV)
                local cellV = GetDimension("V", laneV, rowStart[child], row, spaceV)
                    
                local f = child.frame
                local childV = f:GetHeight() or 0

                local alignFn, align = GetAlign("V", tableObj, colObj, cellObj, cellV, childV)
                if child:IsFullHeight() or alignFn == "fill" then
                    f:SetHeight(cellV)
                end
                f:SetPoint("TOP", content, 0, -(offsetV + align))
            end
        end
    end

    -- Calculate total height
    local totalV = GetDimension("V", laneV, 1, #laneV, spaceV)
    
    -- Cleanup
    for _,v in pairs(layoutCache) do wipe(v) end

    Util.Safecall(obj.LayoutFinished, obj, nil, totalV)
    obj:ResumeLayout()
end)

-------------------------------------------------------
--                      Helper                       --
-------------------------------------------------------

-- Update table rows in-place
function Self.UpdateRows(parent, items, createFn, updateFn, skip, ...)
    local children = parent.children

    -- Create and/or update rows
    local it = Util.Iter(skip or 0)
    for _,item in ipairs(items) do
        local id, child = item[idPath], children[it(0) + 1]

        -- Create the row
        if not child then
            createFn(parent, ...)
            child = children[it(0) + 1]
        end

        -- Update the row
        updateFn(item, children, it, ...)
    end

    -- Release the rest
    while children[it()] do
        children[it(0)]:Release()
        children[it(0)] = nil
    end
end

function Self.CreateFilterCheckbox(key)
    local filter = Rolls.frames.filter

    f = Self("CheckBox")
        .SetLabel(L["FILTER_" .. key:upper()])
        .SetCallback("OnValueChanged", function (self, _, checked)
            if Rolls.filter[key] ~= checked then
                Rolls.filter[key] = checked
                Rolls.Update()
            end
        end)
        .SetCallback("OnEnter", function (self)
            GameTooltip:SetOwner(self.frame, "ANCHOR_TOP")
            GameTooltip:ClearLines()
            GameTooltip:AddLine(L["FILTER_" .. key:upper()])
            GameTooltip:AddLine(L["FILTER_" .. key:upper() .. "_DESC"], 1, 1, 1, true)
            GameTooltip:Show()
        end)
        .SetCallback("OnLeave", Self.TooltipHide)
        .AddTo(filter)
        .SetPoint("TOPLEFT", filter.children[#filter.children-1].frame, "TOPRIGHT")()
    f:SetWidth(f.text:GetStringWidth() + 24 + 15)
    return f
end

function Self.CreateIconButton(icon, parent, onClick, desc, width, height)
    f = Self("Icon")
        .SetImage(icon:sub(1, 9) == "Interface" and icon or "Interface\\Buttons\\" .. icon .. "-Up")
        .SetImageSize(width or 16, height or 16).SetHeight(16).SetWidth(16)
        .SetCallback("OnClick", function (...) onClick(...) GameTooltip:Hide() end)
        .AddTo(parent)()
    f.image:SetPoint("TOP")

    if desc then
        f:SetCallback("OnEnter", function (self)
            GameTooltip:SetOwner(self.frame, "ANCHOR_TOP")
            GameTooltip:SetText(desc, 1, 1, 1, 1)
            GameTooltip:Show()
        end)
        f:SetCallback("OnLeave", Self.TooltipHide)
    end

    return f
end

function Self.CreateUnitLabel(parent, baseTooltip)
    return Self("InteractiveLabel")
        .SetFontObject(GameFontNormal)
        .SetCallback("OnEnter", baseTooltip and Self.TooltipUnit or Self.TooltipUnitFullName)
        .SetCallback("OnLeave", Self.TooltipHide)
        .SetCallback("OnClick", Self.Whisper)
        .AddTo(parent)
end

function Self.TooltipUnit(self)
    GameTooltip_SetDefaultAnchor(GameTooltip, UIParent)
    GameTooltip:SetUnit(self:GetUserData("unit"))
    GameTooltip:Show()
end

function Self.TooltipUnitFullName(self)
    local unit = self:GetUserData("unit")
    if unit and unit ~= Unit(unit) then
        GameTooltip:SetOwner(self.frame, "ANCHOR_TOP")
        GameTooltip:SetText(unit)
        GameTooltip:Show()
    end
end

function Self.TooltipHide()
    GameTooltip:Hide()
end

function Self.Whisper(self)
    local unit = self:GetUserData("unit")
    if unit then
        ChatFrame_SendSmartTell(unit)
    end
end

-- Enable chain-calling
Self.C = {f = nil, k = nil}
local Fn = function (...)
    local c, k, f = Self.C, rawget(Self.C, "k"), rawget(Self.C, "f")
    if k == "AddTo" then
        local parent, beforeWidget = ...
        parent:AddChild(f, beforeWidget)
    else
        if k == "Toggle" then
            k = (...) and "Show" or "Hide"
        end

        local obj = f[k] and f
            or f.frame and f.frame[k] and f.frame
            or f.image and f.image[k] and f.image
            or f.label and f.label[k] and f.label
        obj[k](obj, ...)

        if (k == "SetText" or k == "SetFontObject") and (f.type == "Label" or f.type == "InteractiveLabel") then
            f.frame:SetWidth(f.label:GetStringWidth())
        end
    end
    return c
end
setmetatable(Self.C, {
    __index = function (c, k)
        c.k = Util.StrUcFirst(k)
        return Fn
    end,
    __call = function (c, i)
        local f = rawget(c, "f")
        if i ~= nil then return f[i] else return f end
    end
})
setmetatable(Self, {
    __call = function (_, f, ...)
        Self.C.f = type(f) == "string" and AceGUI:Create(f, ...) or f
        Self.C.k = nil
        return Self.C
    end
})