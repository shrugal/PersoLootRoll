local Name, Addon = ...
local L = LibStub("AceLocale-3.0"):GetLocale(Name)
local AceGUI = LibStub("AceGUI-3.0")
local Comm, Inspect, Item, Masterloot, Roll, Trade, Unit, Util = Addon.Comm, Addon.Inspect, Addon.Item, Addon.Masterloot, Addon.Roll, Addon.Trade, Addon.Unit, Addon.Util
local Self = Addon.GUI

-- Row highlight frame
local frame = CreateFrame("Frame", nil, UIParent)
frame:SetFrameStrata("BACKGROUND")
frame:Hide()
local tex = frame:CreateTexture(nil, "BACKGROUND")
tex:SetTexture("Interface\\Buttons\\UI-Listbox-Highlight")
tex:SetVertexColor(1, 1, 1, .5)
tex:SetAllPoints(frame)
Self.HighlightFrame = frame
Self.HighlightFrame.HighlightTexture = tex

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
    button1 = ACCEPT,
    button2 = DECLINE,
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
UIDropDownMenu_SetInitializeFunction(dropDown, function (self, level, menuList)
    local info = UIDropDownMenu_CreateInfo()
    info.text, info.func = L["MENU_MASTERLOOT_START"], function () Masterloot.SetMasterlooter("player") end
    UIDropDownMenu_AddButton(info)
    info.text, info.func = L["MENU_MASTERLOOT_SEARCH"], function () Masterloot.SendRequest() end
    UIDropDownMenu_AddButton(info)
end)
Self.DROPDOWN_MASTERLOOT = dropDown

-- Unit
dropDown = CreateFrame("FRAME", "PlrUnitDropDown", UIParent, "UIDropDownMenuTemplate")
UIDropDownMenu_SetInitializeFunction(dropDown, function (self, level, menuList)
    UnitPopup_ShowMenu(self, self.which, self.unit)
end)
Self.DROPDOWN_UNIT = dropDown

-- Custom bid answers
local clickFn = function (self, roll, bid) roll:Bid(bid) end
dropDown = CreateFrame("FRAME", "PlrBidAnswersDropDown", UIParent, "UIDropDownMenuTemplate")
UIDropDownMenu_SetInitializeFunction(dropDown, function (self, level, menuList)
    for i,v in pairs(self.answers) do
        local info = UIDropDownMenu_CreateInfo()
        info.text, info.func, info.arg1, info.arg2 = Util.In(v, Roll.ANSWER_NEED, Roll.ANSWER_GREED) and L["ROLL_BID_" .. self.bid] or v, clickFn, self.roll, self.bid + i/10
        UIDropDownMenu_AddButton(info)
    end
end)
Self.DROPDOWN_BID_ANSWERS = dropDown

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
    filter = {all = false, hidden = false, done = true, awarded = true, traded = false},
    status = {width = 700, height = 300},
    open = {},
    hidden = {}
}

-- Register for roll changes
Roll:On(Roll.EVENT_CHANGE, function () Rolls.Update() end)
Roll:On(Roll.EVENT_CLEAR, function (_, roll)
    roll.open[roll.id] = nil
    roll.hidden[roll.id] = nil
end)

-- Register for ML changes
Masterloot:On(Masterloot.EVENT_CHANGE, function () Rolls.Update() end)

-- Show the rolls frame
function Rolls.Show()
    if Rolls.frames.window then
        Rolls.frames.window.frame:Show()
    else
        -- WINDOW

        Rolls.frames.window = Self("Window")
            .SetLayout(nil)
            .SetFrameStrata("MEDIUM")
            .SetTitle("PersoLootRoll - " .. L["ROLLS"])
            .SetCallback("OnClose", function (self)
                Rolls.status.width = self.frame:GetWidth()
                Rolls.status.height = self.frame:GetHeight()
                self.optionsbutton, self.versionbutton = nil, nil
                self:Release()
                wipe(Rolls.frames)
                wipe(Rolls.open)
            end)
            .SetMinResize(550, 120)
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
                .SetCallback("OnLeave", Self.TooltipHide)
                .AddTo(window)()
            f.OnRelease = function (self)
                self.image:SetPoint("TOP", 0, -5)
                self.frame:SetFrameStrata("MEDIUM")
                self.OnRelease = nil
            end
            f.image:SetPoint("TOP", 0, -2)
            f.frame:SetParent(window.frame)
            f.frame:SetPoint("TOPRIGHT", window.closebutton, "TOPLEFT", -8, -8)
            f.frame:SetFrameStrata("HIGH")
            f.frame:Show()
            
            window.optionsbutton = f

            -- Version label
            f = Self("InteractiveLabel")
                .SetText("v" .. Addon.VERSION)
                .SetColor(1, 0.82, 0)
                .SetCallback("OnEnter", function(self)
                    if IsInGroup() then
                        GameTooltip:SetOwner(self.frame, "ANCHOR_BOTTOMRIGHT")

                        -- Addon versions
                        local count = Util.TblCount(Addon.versions)
                        if count > 0 then
                            GameTooltip:SetText(L["TIP_ADDON_VERSIONS"])                        
                            for unit,version in pairs(Addon.versions) do
                                local name = Unit.ColoredName(Unit.ShortenedName(unit), unit)
                                local versionColor = (not version or version == Addon.VERSION) and "ffffff" or version < Addon.VERSION and "ff0000" or "00ff00"
                                GameTooltip:AddLine(("%s: |cff%s%s|r"):format(name, versionColor, version), 1, 1, 1, false)
                            end
                        end

                        -- Addon missing
                        if count + 1 < GetNumGroupMembers() then
                            GameTooltip:AddLine("\n" .. L["TIP_ADDON_MISSING"])
                            local s = ""
                            for i=1,GetNumGroupMembers() do
                                local unit = GetRaidRosterInfo(i)
                                if unit and not Addon.versions[unit] and not UnitIsUnit(unit, "player") then
                                    s = Util.StrPostfix(s, ", ") .. Unit.ColoredName(Unit.ShortenedName(unit), unit)
                                end
                            end
                            GameTooltip:AddLine(s, 1, 1, 1, true)
                        end
                        GameTooltip:Show()
                    end
                end)
                .SetCallback("OnLeave", Self.TooltipHide)
                .AddTo(window)()
            f.OnRelease = function (self)
                self.frame:SetFrameStrata("MEDIUM")
                self.OnRelease = nil
            end
            f.frame:SetParent(window.frame)
            f.frame:SetPoint("RIGHT", window.optionsbutton.frame, "LEFT", -15, -1)
            f.frame:SetFrameStrata("HIGH")
            f.frame:Show()

            window.versionbutton = f
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

            for _,key in ipairs({"all", "done", "awarded", "traded", "hidden"}) do
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
                        -- Info
                        local s = Masterloot.session
                        local timeoutBase, timeoutPerItem = s.timeoutBase or Roll.TIMEOUT, s.timeoutPerItem or Roll.TIMEOUT_PER_ITEM
                        local council = not s.council and "-" or Util(s.council).Keys().Map(function (unit)
                            return Unit.ColoredName(Unit.ShortenedName(unit), unit)
                        end).Concat(", ")()
                        local bids = L[s.bidPublic and "PUBLIC" or "PRIVATE"]
                        local votes = L[s.votePublic and "PUBLIC" or "PRIVATE"]

                        GameTooltip:SetOwner(self.frame, "ANCHOR_BOTTOM")
                        GameTooltip:SetText(L["TIP_MASTERLOOT"] .. "\n")
                        GameTooltip:AddLine(L["TIP_MASTERLOOT_INFO"]:format(Unit.ColoredName(ml), timeoutBase, timeoutPerItem, council, bids, votes), 1, 1, 1)

                        -- Players
                        GameTooltip:AddLine("\n" .. L["TIP_MASTERLOOTING"])
                        local units = Unit.ColoredName(UnitName("player"))
                        for unit,unitMl in pairs(Masterloot.masterlooting) do
                            if ml == unitMl then
                                units = units .. ", " .. Unit.ColoredName(Unit.ShortenedName(unit), unit)
                            end
                        end
                        GameTooltip:AddLine(units, 1, 1, 1, 1)

                        GameTooltip:Show()
                    end
                end)
                .SetCallback("OnLeave", Self.TooltipHide)
                .SetCallback("OnClick", function (self, ...)
                    self:SetUserData("unit", Masterloot.GetMasterlooter())
                    Self.UnitClick(self, ...)
                end)
                .SetHeight(12)
                .SetPoint("TOP", 0, -6)
                .SetPoint("RIGHT", f.frame, "LEFT")()
        end

        -- SCROLL

        Rolls.frames.scroll = Self("ScrollFrame")
            .SetLayout("PLR_Table")
            .SetUserData("table", {space = 10})
            .AddTo(Rolls.frames.window)
            .SetPoint("TOPRIGHT")
            .SetPoint("BOTTOMLEFT", Rolls.frames.filter.frame, "TOPLEFT", 0, 8)()

        Rolls.Update()
    end
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

----------------------- UPDATE ------------------------

-- Update the rolls frame
function Rolls.Update()
    if not Rolls.frames.window then return end
    local f

    -- SCROLL

    local scroll = Rolls.frames.scroll
    local children = scroll.children
    scroll:PauseLayout()

    -- Header

    local header = {"ID", "ITEM", "LEVEL", "OWNER", "ML", "STATUS", "YOUR_BID", "WINNER"}
    if #children == 0 then
        scroll.userdata.table.columns = {20, 1, {25, 100}, {25, 100}, {25, 100}, {25, 100}, {25, 100}, {25, 100}, 6 * 20 - 4}

        for i,v in pairs(header) do
            Self("Label").SetFontObject(GameFontNormal).SetText(Util.StrUcFirst(L[v])).SetColor(1, 0.82, 0).AddTo(scroll)
        end

        local actions = Self("SimpleGroup")
            .SetLayout(nil)
            .SetHeight(16).SetWidth(17)
            .SetUserData("cell", {alignH = "end"})
            .AddTo(scroll)()
        local backdrop = {actions.frame:GetBackdropColor()}
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

    -- Rolls

    local rolls = Util(Addon.rolls).CopyFilter(function (roll)
        return (Rolls.filter.all or roll.isOwner or roll.item.isOwner or roll.item:GetEligible("player"))
           and (Rolls.filter.hidden or roll.status >= Roll.STATUS_RUNNING and not Rolls.hidden[roll.id])
           and (Rolls.filter.done or (roll.status ~= Roll.STATUS_DONE))
           and (Rolls.filter.awarded or not roll.winner)
           and (Rolls.filter.traded or not roll.traded)
    end).SortBy("id")()

    local it = Util.Iter(#header + 1)
    for _,roll in pairs(rolls) do
        -- Create the row
        if not children[it(0) + 1] then
            -- ID
            Self("Label")
                .SetFontObject(GameFontNormal)
                .AddTo(scroll)
        
            -- Item
            Self("InteractiveLabel")
                .SetFontObject(GameFontNormal)
                .SetCallback("OnEnter", Self.TooltipItemLink)
                .SetCallback("OnLeave", Self.TooltipHide)
                .SetCallback("OnClick", Self.ItemClick)
                .AddTo(scroll)
            
            -- Ilvl
            Self("Label")
                .SetFontObject(GameFontNormal)
                .AddTo(scroll)
        
            -- Owner, ML
            Self.CreateUnitLabel(scroll)
            Self.CreateUnitLabel(scroll)
        
            -- Status
            local f = Self("Label").SetFontObject(GameFontNormal).AddTo(scroll)()
            f.OnRelease = function (self)
                self.frame:SetScript("OnUpdate", nil)
                self.OnRelease = nil
            end
        
            -- Your bid, Winner
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
        
                local needGreedClick = function (self, _, button)
                    local roll, bid = self:GetUserData("roll"), self:GetUserData("bid")
                    if button == "LeftButton" then
                        roll:Bid(bid)
                    elseif button == "RightButton" and roll.owner == Masterloot.GetMasterlooter() then
                        local answers = Masterloot.session["answers" .. bid]
                        if answers and #answers > 0 then
                            local dropDown = Self.DROPDOWN_BID_ANSWERS
                            dropDown.roll, dropDown.bid, dropDown.answers = roll, bid, answers
                            ToggleDropDownMenu(1, nil, dropDown, "cursor", 3, -3)
                        end
                    end
                end 
        
                -- Need
                f = Self.CreateIconButton("UI-GroupLoot-Dice", actions, needGreedClick, NEED, 14, 14)
                f:SetUserData("bid", Roll.BID_NEED)
                f.frame:RegisterForClicks("LeftButtonUp", "RightButtonUp")
                f.OnRelease = function (self)
                    self.frame:RegisterForClicks("LeftButtonUp")
                    self.OnRelease = nil
                end
        
                -- Greed
                f = Self.CreateIconButton("UI-GroupLoot-Coin", actions, needGreedClick, GREED)
                f:SetUserData("bid", Roll.BID_GREED)
                f.frame:RegisterForClicks("LeftButtonUp", "RightButtonUp")
                f.OnRelease = function (self)
                    self.frame:RegisterForClicks("LeftButtonUp")
                    self.OnRelease = nil
                end
        
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

                -- Hide
                f = Self.CreateIconButton("Interface\\Buttons\\UI-CheckBox-Check", actions, function (self)
                    local roll = self:GetUserData("roll")
                    Rolls.hidden[roll.id] = not Rolls.hidden[roll.id]
                    Rolls.Update()
                end, L["SHOW_HIDE"])
                f.image:SetPoint("TOP", 0, 2)
        
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
                .SetUserData("table", {spaceH = 10, spaceV = 2})
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

                details.frame:Hide()
                Self.TableRowHighlight(details, #header)
            end
        end

        -- ID
        Self(children[it()]).SetText(roll.id).Show()

        -- Item
        Self(children[it()])
            .SetImage(roll.item.texture)
            .SetText(roll.item.link)
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
        local f = Self(children[it()]).Show()
        if roll.status == Roll.STATUS_RUNNING then
            f.SetUserData("roll", roll)
            .SetScript("OnUpdate", Self.OnStatusUpdate)
            .SetColor(1, 1, 0)
            Self.OnStatusUpdate(f().frame)
        else
            f.SetText(roll.traded and L["ROLL_TRADED"] or roll.winner and L["ROLL_AWARDED"] or L["ROLL_STATUS_" .. roll.status])
            .SetUserData("roll", nil)
            .SetScript("OnUpdate", nil)
            .SetColor(1, 1, 1)
        end

        -- Your Bid
        Self(children[it()])
            .SetText(roll:GetBidName(roll.bid))
            .SetColor(Self.GetBidColor(roll.bid))
            .Show()

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
            local hidden = Rolls.hidden[roll.id]

            -- Need
            Self(children[it()]).SetUserData("roll", roll).Toggle(canBid)
            -- Greed
            Self(children[it()]).SetUserData("roll", roll).Toggle(canBid and (roll.ownerId or roll.itemOwnerId))
            -- Pass
            Self(children[it()]).SetUserData("roll", roll).Toggle(canBid)
            -- Advertise
            Self(children[it()]).SetUserData("roll", roll).Toggle(roll:ShouldAdvertise(true))
            -- Award randomly
            Self(children[it()]).SetUserData("roll", roll).Toggle(roll.status == roll.STATUS_DONE and canBeAwarded and Util.TblCountExcept(roll.bids, Roll.BID_PASS) > 0)
            -- Trade
            Self(children[it()]).SetUserData("roll", roll).Toggle(
                not roll.traded and (
                    (roll.winner and roll.item.isOwner or roll.isWinner) or
                    (roll.bid and roll.bid ~= Roll.BID_PASS and not roll.ownerId)
                )
            )
            -- Restart
            Self(children[it()]).SetUserData("roll", roll).Toggle(roll:CanBeRestarted())
            -- Cancel
            Self(children[it()]).SetUserData("roll", roll).Toggle(canBeAwarded)
            -- Hide
            Self(children[it()])
                .SetImage("Interface\\Buttons\\UI-CheckBox-Check" .. (hidden and "-Disabled" or ""), -.1, 1.1, -.1, 1.1)
                .SetUserData("roll", roll)
                .Toggle(hidden or roll.status ~= Roll.STATUS_RUNNING)
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

    -- Release the rest
    while children[it()] do
        children[it(0)]:Release()
        children[it(0)] = nil
    end

    Util.TblRelease(rolls)
    scroll:ResumeLayout()
    scroll:DoLayout()

    -- FILTER

    local filter = Rolls.frames.filter
    local it = Util.Iter(1)

    filter.children[it()]:SetValue(Rolls.filter.all)
    filter.children[it()]:SetValue(Rolls.filter.done)
    filter.children[it()]:SetValue(Rolls.filter.awarded)
    filter.children[it()]:SetValue(Rolls.filter.traded)
    filter.children[it()]:SetValue(Rolls.filter.hidden)

    -- ML action
    local ml = Masterloot.GetMasterlooter()
    filter.children[it()]:SetImage(ml and "Interface\\Buttons\\UI-StopButton" or "Interface\\GossipFrame\\WorkOrderGossipIcon")

    -- ML
    Self(filter.children[it()]).SetText(L["ML"] .. ": " .. (ml and Unit.ColoredName(Unit.ShortenedName(ml)) or ""))
end

------------------- UPDATE DETAILS --------------------

-- Update the details view of a row
function Rolls.UpdateDetails(details, roll)
    details.frame:Show()
    details:PauseLayout()
    
    local children = details.children

    -- Header

    local header = {"PLAYER", "ITEM_LEVEL", "EQUIPPED", "BID", "ROLL", "VOTES"}
    if #children == 0 then
        details.userdata.table.columns = {1, {25, 100}, {34, 100}, {25, 100}, {25, 100}, {25, 100}, 100}
        
        for i,v in pairs(header) do
            local f = Self("Label").SetFontObject(GameFontNormal).SetText(Util.StrUcFirst(L[v])).SetColor(1, 0.82, 0)()
            if i == #header then
                f:SetUserData("cell", {colspan = 2})
            end
            details:AddChild(f)
        end
    end

    -- Players

    local canBeAwarded, canVote = roll:CanBeAwarded(true), roll:UnitCanVote()

    local players = Util(roll.item:GetEligible()).Copy().Merge(roll.bids).Map(function (val, unit)
        local t = Util.Tbl()
        t.unit = unit
        t.ilvl = roll.item:GetLevelForLocation(unit)
        t.bid = type(val) == "number" and val or nil
        t.votes = Util.TblCountOnly(roll.votes, unit)
        t.roll = roll.rolls[unit]
        return t
    end, true).List().SortBy(
        "bid",   99,  false,
        "votes", 0,   true,
        "roll",  100, true,
        "ilvl",  0,   false,
        "unit"
    )()

    local it = Util.Iter(#header)
    for _,player in pairs(players) do
        -- Create the row
        if not children[it(0) + 1] then
            -- Unit, Ilvl
            Self.CreateUnitLabel(details)
            Self("Label").SetFontObject(GameFontNormal).AddTo(details)
        
            -- Items
            local grp = Self("SimpleGroup")
                .SetLayout(nil)
                .SetWidth(34).SetHeight(16)
                .SetBackdropColor(0, 0, 0, 0)
                .AddTo(details)()
            for i=1,2 do
                local f = Self("Icon")
                    .SetCallback("OnEnter", Self.TooltipItemLink)
                    .SetCallback("OnLeave", Self.TooltipHide)
                    .SetCallback("OnClick", Self.ItemClick)
                    .AddTo(grp)
                    .SetPoint(i == 1 and "LEFT" or "RIGHT")()
                f.image:SetPoint("TOP")
                f.OnRelease = function (self)
                    self.image:SetPoint("TOP", 0, -5)
                    self.OnRelease = nil
                end
            end
        
            -- Bid, Roll
            Self("Label").SetFontObject(GameFontNormal).AddTo(details)
            Self("Label").SetFontObject(GameFontNormal).AddTo(details)
        
            -- Votes
            Self("Label")
                .SetFontObject(GameFontNormal)
                .SetCallback("OnEnter", function (self)
                    local roll, unit = self:GetUserData("roll"), self:GetUserData("unit")
                    if Util.TblCountOnly(roll.votes, unit) > 0 then
                        GameTooltip:SetOwner(self.frame, "ANCHOR_BOTTOM")
                        GameTooltip:SetText(L["TIP_VOTES"])
                        for toUnit,fromUnit in pairs(roll.votes) do
                            if unit == toUnit then
                                local c = Unit.Color(fromUnit)
                                GameTooltip:AddLine(Unit.ShortenedName(fromUnit), c.r, c.g, c.b, false)
                            end
                        end
                        GameTooltip:Show()
                    end
                end)
                .SetCallback("OnLeave", Self.TooltipHide)
                .AddTo(details)
        
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

        -- Unit
        Self(children[it()])
            .SetText(Unit.ColoredName(Unit.ShortenedName(player.unit), player.unit))
            .SetUserData("unit", player.unit)
            .Show()

        -- Ilvl
        Self(children[it()]).SetText(player.ilvl).Show()

        -- Items
        local f, links = children[it()]

        if roll.item.isRelic then
            links = Inspect.GetLink(player.unit, roll.item.relicType)
        elseif roll.item.isEquippable then
            links = Util.Tbl()
            for i,slot in pairs(Item.SLOTS[roll.item.equipLoc]) do
                tinsert(links, Inspect.GetLink(player.unit, slot))
            end
        end

        for i,child in pairs(f.children) do
            if links and links[i] then
                Self(f.children[i])
                    .SetImage(Item.GetInfo(links[i], "texture"))
                    .SetImageSize(16, 16).SetWidth(16).SetHeight(16)
                    .SetUserData("link", links[i])
                    .Show()
            else
                child.frame:Hide()
            end
        end

        if not roll.item.isRelic then
            Util.TblRelease(links)
        end

        -- Bid
        Self(children[it()])
            .SetText(roll:GetBidName(player.bid))
            .SetColor(Self.GetBidColor(player.bid))
            .Show()

        -- Roll
        Self(children[it()])
            .SetText(player.roll and Util.NumRound(player.roll) or "-")
            .Show()

        -- Votes
        Self(children[it()])
            .SetText(player.votes > 0 and player.votes or "-")
            .SetUserData("roll", roll)
            .SetUserData("unit", player.unit)
            .Show()

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

    -- Release the rest
    while children[it()] do
        children[it(0)]:Release()
        children[it(0)] = nil
    end

    Util.TblRelease(1, players)
    details:ResumeLayout()
end

Self.Rolls = Rolls

-------------------------------------------------------
--                      Helper                       --
-------------------------------------------------------

-- Create a filter checkbox
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

-- Create an icon button
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

-- Create an interactive label for a unit, with tooltip, unitmenu and whispering on click
function Self.CreateUnitLabel(parent, baseTooltip)
    return Self("InteractiveLabel")
        .SetFontObject(GameFontNormal)
        .SetCallback("OnEnter", baseTooltip and Self.TooltipUnit or Self.TooltipUnitFullName)
        .SetCallback("OnLeave", Self.TooltipHide)
        .SetCallback("OnClick", Self.UnitClick)
        .AddTo(parent)
end

-- Display a regular unit tooltip
function Self.TooltipUnit(self)
    GameTooltip_SetDefaultAnchor(GameTooltip, UIParent)
    GameTooltip:SetUnit(self:GetUserData("unit"))
    GameTooltip:Show()
end

-- Display a tooltip showing only the full name of an x-realm player
function Self.TooltipUnitFullName(self)
    local unit = self:GetUserData("unit")
    if unit and Unit.Realm(unit) ~= GetRealmName() then
        local c = Unit.Color(unit)
        GameTooltip:SetOwner(self.frame, "ANCHOR_TOP")
        GameTooltip:SetText(Unit.FullName(unit), c.r, c.g, c.b, false)
        GameTooltip:Show()
    end
end

-- Display a tooltip for an item link
function Self.TooltipItemLink(self)
    local link = self:GetUserData("link")
    if link then
        GameTooltip:SetOwner(self.frame, "ANCHOR_LEFT")
        GameTooltip:SetHyperlink(link)
        GameTooltip:Show()
    end
end

-- Hide the tooltip
function Self.TooltipHide()
    GameTooltip:Hide()
end

-- Handle clicks on unit labels
function Self.UnitClick(self, event, button)
    local unit = self:GetUserData("unit")
    if unit then
        if button == "LeftButton" then
            ChatFrame_SendSmartTell(unit)
        elseif button == "RightButton" then
            local dropDown = Self.DROPDOWN_UNIT
            dropDown.which = UnitIsUnit(unit, "player") and "SELF" or UnitInRaid(unit) and "RAID_PLAYER" or UnitInParty(unit) and "PARTY" or "PLAYER"
            dropDown.unit = unit
            ToggleDropDownMenu(1, nil, dropDown, "cursor", 3, -3)
        end
    end
end

-- Handle clicks on item labels/icons
function Self.ItemClick(self)
    if IsModifiedClick("DRESSUP") then
        DressUpItemLink(self:GetUserData("link"))
    elseif IsModifiedClick("CHATLINK") then
        ChatEdit_InsertLink(self:GetUserData("link"))
    end
end

-- Roll status OnUpdate callback
function Self.OnStatusUpdate(frame)
    Self(frame.obj).SetText(L["SECONDS"]:format(frame.obj:GetUserData("roll"):GetTimeLeft()))
end

-- Add row-highlighting to a table
function Self.TableRowHighlight(parent, skip)
    skip = skip or 0
    local frame = parent.frame
    local isOver = false
    local tblObj = parent:GetUserData("table")
    local spaceV = tblObj.spaceV or tblObj.space or 0

    frame:SetScript("OnEnter", function (self)
        if not isOver then
            self:SetScript("OnUpdate", function (self)
                if not MouseIsOver(self) then
                    isOver = false
                    self:SetScript("OnUpdate", nil)
                    
                    if Self.HighlightFrame:GetParent() == self then
                        Self.HighlightFrame:SetParent(UIParent)
                        Self.HighlightFrame:Hide()
                    end
                else
                    local cY = select(2, GetCursorPosition()) / UIParent:GetEffectiveScale()
                    local frameTop, frameBottom = parent.frame:GetTop(), parent.frame:GetBottom()
                    local row, top, bottom

                    for i=skip+1,#parent.children do
                        local childTop, childBottom = parent.children[i].frame:GetTop(), parent.children[i].frame:GetBottom()
                        if childTop + spaceV/2 >= cY and childBottom - spaceV/2 <= cY then
                            top =  min(frameTop, max(top or 0, childTop + spaceV/2))
                            bottom = max(frameBottom, min(bottom or frameTop, childBottom - spaceV/2))
                        end
                    end
                    
                    if top and bottom then
                        Self(Self.HighlightFrame)
                            .SetParent(self)
                            .SetPoint("LEFT").SetPoint("RIGHT")
                            .SetPoint("TOP", 0, top - frameTop)
                            .SetHeight(top - bottom)
                            .Show()
                    else
                        Self.HighlightFrame:Hide()
                    end
                end
            end)
        end
        isOver = true
    end)
end

-- Get the color for a bid
function Self.GetBidColor(bid)
    if not bid then
        return 1, 1, 1
    elseif bid == Roll.BID_PASS then
        return .5, .5, .5
    else
        local bid, i = floor(bid), 10*bid - 10*floor(bid)
        if bid == Roll.BID_NEED then
            return 0, max(.2, min(1, 1 - .2 * (i - 5))), max(0, min(1, .2 * i))
        elseif bid == Roll.BID_GREED then
            return 1, max(0, min(1, 1 - .1 * i)), 0
        end
    end
end

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

        -- Fix Label's stupid image anchoring
        if (k == "SetText" or k == "SetFontObject" or k == "SetImage") and (obj.type == "Label" or obj.type == "InteractiveLabel") then
            obj:SetWidth(max(obj.imageshown and (201 + obj.image:GetWidth()) or 0, obj.label:GetStringWidth() + (obj.imageshown and obj.image:GetWidth() + 4 or 0)))
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