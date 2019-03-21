local Name, Addon = ...
local L = LibStub("AceLocale-3.0"):GetLocale(Name)
local AceGUI = LibStub("AceGUI-3.0")
local GUI, Inspect, Item, Options, Session, Roll, Trade, Unit, Util = Addon.GUI, Addon.Inspect, Addon.Item, Addon.Options, Addon.Session, Addon.Roll, Addon.Trade, Addon.Unit, Addon.Util
local Self = GUI.Rolls

Self.frames = {}
Self.filter = {all = false, hidden = false, done = true, awarded = true, traded = false}
Self.status = {width = 700, height = 300}
Self.open = {}
Self.confirm = {roll = nil, unit = nil}

-------------------------------------------------------
--                     Show/Hide                     --
-------------------------------------------------------

-- Show the frame
function Self.Show()
    if Self.frames.window then
        Self.frames.window.frame:Show()
    else

        -- WINDOW

        Self.frames.window = GUI("Window")
            .SetLayout(nil)
            .SetFrameStrata("MEDIUM")
            .SetTitle("PersoLootRoll - " .. L["ROLLS"])
            .SetCallback("OnClose", function (self)
                Self.status.width = self.frame:GetWidth()
                Self.status.height = self.frame:GetHeight()
                self.optionsBtn, self.versionBtn = nil, nil
                self:Release()
                wipe(Self.frames)
                wipe(Self.open)
            end)
            .SetMinResize(550, 120)
            .SetStatusTable(Self.status)()

        do
            local window = Self.frames.window

            -- Options button
            f = GUI("Icon")
                .SetImage("Interface\\Buttons\\UI-OptionsButton")
                .SetImageSize(14, 14).SetHeight(16).SetWidth(16)
                .SetCallback("OnClick", function (self)
                    Options.Show()
                    GameTooltip:Hide()
                end)
                .SetCallback("OnEnter", GUI.TooltipText)
                .SetCallback("OnLeave", GUI.TooltipHide)
                .SetUserData("text", OPTIONS)
                .AddTo(window)()
            f.OnRelease = GUI.ResetIcon
            f.image:SetPoint("TOP", 0, -1)
            f.frame:SetParent(window.frame)
            f.frame:SetPoint("TOPRIGHT", window.closebutton, "TOPLEFT", -8, -8)
            f.frame:SetFrameStrata("HIGH")
            f.frame:Show()
            
            window.optionsBtn = f

            -- Test button
            f = GUI("Icon")
                .SetImage("Interface\\Buttons\\AdventureGuideMicrobuttonAlert")
                .SetImageSize(17, 17).SetHeight(16).SetWidth(16)
                .SetCallback("OnClick", Roll.Test)
                .SetCallback("OnEnter", GUI.TooltipText)
                .SetCallback("OnLeave", GUI.TooltipHide)
                .SetUserData("text", L["TIP_TEST"])
                .AddTo(window)()
            f.OnRelease = GUI.ResetIcon
            f.image:SetPoint("TOP")
            f.frame:SetParent(window.frame)
            f.frame:SetPoint("RIGHT", window.optionsBtn.frame, "LEFT", -15, 0)
            f.frame:SetFrameStrata("HIGH")
            f.frame:Show()
            
            window.testBtn = f

            -- Version label
            f = GUI("InteractiveLabel")
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
                                local name = Unit.ColoredShortenedName(unit)
                                local versionColor = Util.Select(Addon:CompareVersion(version), -1, "ff0000", 1, "00ff00", "ffffff")
                                local line = ("%s: |cff%s%s|r"):format(name, versionColor, version) .. (Addon.disabled[unit] and " (" .. OFF .. ")" or "")
                                GameTooltip:AddLine(line, 1, 1, 1, false)
                            end
                        end

                        -- Addon missing
                        if count + 1 < GetNumGroupMembers() then
                            GameTooltip:AddLine((count > 0 and "\n" or "") .. L["TIP_ADDON_MISSING"])
                            local s = ""
                            for i=1,GetNumGroupMembers() do
                                local unit = GetRaidRosterInfo(i)
                                if unit and not Addon.versions[unit] and not Unit.IsSelf(unit) then
                                    s = Util.StrPostfix(s, ", ") .. Unit.ColoredShortenedName(unit)
                                end
                            end
                            GameTooltip:AddLine(s, 1, 1, 1, true)
                        end

                        -- Users of compatible addons
                        if next(Addon.compAddonUsers) then
                            GameTooltip:AddLine((GetNumGroupMembers() > 1 and "\n" or "") .. L["TIP_COMP_ADDON_USERS"])

                            for addon,users in pairs(Addon.compAddonUsers) do
                                local s = ""
                                for unit,version in pairs(users) do
                                    s = Util.StrPostfix(s, ", ") .. Unit.ColoredShortenedName(unit)
                                end
                                GameTooltip:AddLine(addon .. ": " .. s, 1, 1, 1, true)
                            end
                        end
                        GameTooltip:Show()
                    end
                end)
                .SetCallback("OnLeave", GUI.TooltipHide)
                .AddTo(window)()
            f.OnRelease = GUI.ResetLabel
            f.frame:SetParent(window.frame)
            f.frame:SetPoint("RIGHT", window.testBtn.frame, "LEFT", -15, -1)
            f.frame:SetFrameStrata("HIGH")
            f.frame:Show()

            window.versionBtn = f
        end

        -- FILTER

        Self.frames.filter = GUI("SimpleGroup")
            .SetLayout(nil)
            .AddTo(Self.frames.window)
            .SetPoint("BOTTOMLEFT", 0, 0)
            .SetPoint("BOTTOMRIGHT", -25, 0)
            .SetHeight(24)()
        
        do
            f = GUI("Label")
                .SetFontObject(GameFontNormal)
                .SetText(L["FILTER"] .. ":")
                .AddTo(Self.frames.filter)
                .SetPoint("LEFT", 15, 0)()
            f:SetWidth(f.label:GetStringWidth())

            for _,key in ipairs({"all", "done", "awarded", "traded", "hidden"}) do
                Self.CreateFilterCheckbox(key)
            end

            -- ML action
            f = GUI("Icon")
                .AddTo(Self.frames.filter)
                .SetCallback("OnEnter", function (self)
                    GameTooltip:SetOwner(self.frame, "ANCHOR_TOP")
                    GameTooltip:SetText(L["TIP_MASTERLOOT_" .. (Session.GetMasterlooter() and "STOP" or "START")])
                    GameTooltip:Show()
                end)
                .SetCallback("OnLeave", GUI.TooltipHide)
                .SetCallback("OnClick", function (self)
                    local ml = Session.GetMasterlooter()
                    if ml then
                        Session.SetMasterlooter(nil)
                    else 
                        GUI.ToggleMasterlootDropdown("TOPLEFT", self.frame, "CENTER")
                    end
                end)
                .SetImageSize(16, 16).SetHeight(16).SetWidth(16)
                .SetPoint("TOP", 0, -4)
                .SetPoint("RIGHT")()
            f.image:SetPoint("TOP")
            f.OnRelease = GUI.ResetIcon

            -- ML
            f = GUI("InteractiveLabel")
                .SetFontObject(GameFontNormal)
                .AddTo(Self.frames.filter)
                .SetText()
                .SetCallback("OnEnter", function (self)
                    local ml = Session.GetMasterlooter()
                    if ml then
                        -- Info
                        local s = Session.rules
                        local timeoutBase, timeoutPerItem = s.timeoutBase or Roll.TIMEOUT, s.timeoutPerItem or Roll.TIMEOUT_PER_ITEM
                        local council = not s.council and "-" or Util(s.council).Keys().Map(function (unit)
                            return Unit.ColoredShortenedName(unit)
                        end).Concat(", ")()
                        local bids = L[s.bidPublic and "PUBLIC" or "PRIVATE"]
                        local votes = L[s.votePublic and "PUBLIC" or "PRIVATE"]

                        GameTooltip:SetOwner(self.frame, "ANCHOR_BOTTOM")
                        GameTooltip:SetText(L["TIP_MASTERLOOT"] .. "\n")
                        GameTooltip:AddLine(L["TIP_MASTERLOOT_INFO"]:format(Unit.ColoredName(ml), timeoutBase, timeoutPerItem, council, bids, votes), 1, 1, 1)

                        -- Players
                        GameTooltip:AddLine("\n" .. L["TIP_MASTERLOOTING"]:format(1 + Util.TblCountOnly(Session.masterlooting, ml)))
                        local units = Unit.ColoredName(UnitName("player"))
                        for unit,unitMl in pairs(Session.masterlooting) do
                            if ml == unitMl then
                                units = units .. ", " .. Unit.ColoredShortenedName(unit)
                            end
                        end
                        GameTooltip:AddLine(units, 1, 1, 1, 1)

                        GameTooltip:Show()
                    end
                end)
                .SetCallback("OnLeave", GUI.TooltipHide)
                .SetCallback("OnClick", GUI.UnitClick)
                .SetHeight(12)
                .SetPoint("TOP", 0, -6)
                .SetPoint("RIGHT", f.frame, "LEFT")()
        end

        -- SCROLL

        f = GUI("ScrollFrame")
            .SetLayout("PLR_Table")
            .SetUserData("table", {space = 10})
            .AddTo(Self.frames.window)
            .SetPoint("TOPRIGHT")
            .SetPoint("BOTTOMLEFT", Self.frames.filter.frame, "TOPLEFT", 0, 8)()
        f.backgrounds = {}
        local layoutFinished = f.layoutFinished
        f.layoutFinished = function (self, width, height)

        end
        Self.frames.scroll = f

        -- EMPTY MESSAGE

        Self.frames.empty = GUI("Label")
            .SetFont(GameFontNormal:GetFont(), 14)
            .SetColor(0.5, 0.5, 0.5)
            .SetText("- " .. L["ROLL_LIST_EMPTY"] .. " -")
            .AddTo(Self.frames.window)
            .SetPoint("CENTER")()

        Self.Update()
    end
end

-- Check if the frame is currently being shown
function Self.IsShown()
    return Self.frames.window and Self.frames.window.frame:IsShown()
end

-- Hide the frame
function Self.Hide()
    if Self:IsShown() then Self.frames.window.frame:Hide() end
end

-- Toggle the frame
function Self.Toggle()
    if Self:IsShown() then Self.Hide() else Self.Show() end
end

-------------------------------------------------------
--                      Update                       --
-------------------------------------------------------

-- Update the frame
function Self.Update()
    if not Self.frames.window then return end
    local f

    -- SCROLL

    local scroll = Self.frames.scroll
    local children = scroll.children
    scroll:PauseLayout()

    -- Header

    local header = Util.Tbl("ID", "ITEM", "LEVEL", "OWNER", "ML", "STATUS", "YOUR_BID", "WINNER")
    if #children == 0 then
        scroll.userdata.table.columns = {20, 1, {25, 100}, {25, 100}, {25, 100}, {25, 100}, {25, 100}, {25, 100}, 7 * 20 - 4}

        for i,v in pairs(header) do
            GUI("Label").SetFontObject(GameFontNormal).SetText(L[v]).SetColor(1, 0.82, 0).AddTo(scroll)
        end

        local actions = GUI("SimpleGroup")
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
        f = GUI.CreateIconButton("UI-MinusButton", actions, function (self)
            for i,child in pairs(scroll.children) do
                if child:GetUserData("isDetails") then child.frame:Hide() end
            end
            wipe(Self.open)
            Self.Update()
        end)
        f.image:SetPoint("TOP", 0, 2)
        f.frame:SetPoint("TOPRIGHT")

        local color = {0.25, 0.25, 0.25, 0.9}
        GUI.TableRowBackground(scroll, function (_, _, cols) return cols > 1 and color end, #header + 1)
    end

    -- Rolls

    local rolls = Util(Addon.rolls).CopyFilter(function (roll)
        return (Self.filter.all or roll.isOwner or roll.item.isOwner or roll.item:GetEligible("player"))
           and (Self.filter.done or (roll.status ~= Roll.STATUS_DONE))
           and (Self.filter.awarded or not roll.winner)
           and (Self.filter.traded or not roll.traded)
           and (Self.filter.hidden or roll.status >= Roll.STATUS_RUNNING and (roll.isWinner or roll.isOwner or roll.item.isOwner or roll.bid ~= Roll.BID_PASS) and not roll.hidden)
    end).SortBy("id")()

    GUI(Self.frames.empty).Toggle(Util.TblCount(rolls) == 0)

    local it = Util.Iter(#header + 1)
    for i,roll in ipairs(rolls) do
        -- Create the row
        if not children[it(0) + 1] then
            -- ID
            GUI("Label")
                .SetFontObject(GameFontNormal)
                .AddTo(scroll)()
        
            -- Item
            GUI.CreateItemLabel(scroll, "ANCHOR_LEFT")
            
            -- Ilvl
            GUI("Label")
                .SetFontObject(GameFontNormal)
                .AddTo(scroll)
        
            -- Owner, ML
            GUI.CreateUnitLabel(scroll)
            GUI.CreateUnitLabel(scroll)
        
            -- Status
            local f = GUI("Label").SetFontObject(GameFontNormal).AddTo(scroll)()
            f.OnRelease = GUI.ResetLabel
        
            -- Your bid, Winner
            GUI("Label").SetFontObject(GameFontNormal).AddTo(scroll)
            GUI.CreateUnitLabel(scroll)
        
            -- Actions
            f = GUI("SimpleGroup")
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
                    elseif button == "RightButton" and roll.owner == Session.GetMasterlooter() then
                        local answers = Session.rules["answers" .. bid]
                        if answers and #answers > 0 then
                            GUI.ToggleAnswersDropdown(roll, bid, answers, "TOPLEFT", self.frame, "CENTER")
                        end
                    end
                end 
        
                -- Need
                f = GUI.CreateIconButton("UI-GroupLoot-Dice", actions, needGreedClick, NEED, 14, 14)
                f:SetUserData("bid", Roll.BID_NEED)
                f.frame:RegisterForClicks("LeftButtonUp", "RightButtonUp")
        
                -- Greed
                f = GUI.CreateIconButton("UI-GroupLoot-Coin", actions, needGreedClick, GREED)
                f:SetUserData("bid", Roll.BID_GREED)
                f.frame:RegisterForClicks("LeftButtonUp", "RightButtonUp")
        
                -- Disenchant
                f = GUI.CreateIconButton("UI-GroupLoot-DE", actions, function (self)
                    self:GetUserData("roll"):Bid(Roll.BID_DISENCHANT)
                end, ROLL_DISENCHANT, 14, 14)
        
                -- Pass
                GUI.CreateIconButton("UI-GroupLoot-Pass", actions, function (self)
                    self:GetUserData("roll"):Bid(Roll.BID_PASS)
                end, PASS, 13, 13)
        
                -- Advertise
                GUI.CreateIconButton("UI-GuildButton-MOTD", actions, function (self)
                    self:GetUserData("roll"):Advertise(true)
                end, L["ADVERTISE"], 13, 13)
        
                -- Award randomly
                GUI.CreateIconButton("Interface\\GossipFrame\\BankerGossipIcon", actions, function (self)
                    self:GetUserData("roll"):End(true)
                end, L["AWARD_RANDOMLY"], 11, 11)

                -- Chat
                f = GUI.CreateIconButton("Interface\\GossipFrame\\GossipGossipIcon", actions, GUI.ChatClick, nil, 13, 13)
                f:SetCallback("OnEnter", GUI.TooltipChat)
                f.frame:RegisterForClicks("LeftButtonUp", "RightButtonUp")
        
                -- Trade
                GUI.CreateIconButton("Interface\\GossipFrame\\VendorGossipIcon", actions, function (self)
                    self:GetUserData("roll"):Trade()
                end, TRADE, 13, 13)
        
                -- Restart
                f = GUI.CreateIconButton("UI-RotationLeft-Button", actions, function (self)
                    local dialog = StaticPopup_Show(GUI.DIALOG_ROLL_RESTART)
                    if dialog then
                        dialog.data = self:GetUserData("roll")
                    end
                end, L["RESTART"])
                f.image:SetPoint("TOP", 0, 2)
                f.image:SetTexCoord(0.07, 0.93, 0.07, 0.93)
        
                -- Cancel
                f = GUI.CreateIconButton("CancelButton", actions, function (self)
                    local dialog = StaticPopup_Show(GUI.DIALOG_ROLL_CANCEL)
                    if dialog then
                        dialog.data = self:GetUserData("roll")
                    end
                end, CANCEL)
                f.image:SetPoint("TOP", 0, 1)
                f.image:SetTexCoord(0.2, 0.8, 0.2, 0.8)

                -- Hide
                f = GUI.CreateIconButton("Interface\\Buttons\\UI-CheckBox-Check", actions, function (self)
                    self:GetUserData("roll"):ToggleVisibility()
                end)
                f.image:SetPoint("TOP", 0, 1)
        
                -- Toggle
                f = GUI.CreateIconButton("UI-PlusButton", actions, function (self)
                    local roll = self:GetUserData("roll")
                    local details = self:GetUserData("details")
        
                    if details:IsShown() then
                        Self.open[roll.id] = nil
                        details.frame:Hide()
                        self:SetImage("Interface\\Buttons\\UI-PlusButton-Up")
                    else
                        Self.open[roll.id] = true
                        Self.UpdateDetails(details, roll)
                        self:SetImage("Interface\\Buttons\\UI-MinusButton-Up")
                    end
                    self.parent.parent:DoLayout()
                    Self:ScheduleTimer(self.parent.parent.DoLayout, 0, self.parent.parent)
                end)
                f.image:SetPoint("TOP", 0, 2)
            end
        
            -- Details
            local details = GUI("SimpleGroup")
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
            end
        end

        -- ID
        GUI(children[it()]).SetText(roll.id).Show()

        -- Item
        GUI(children[it()])
            .SetImage(roll.item.texture)
            .SetText(roll.item.link)
            .SetUserData("link", roll.item.link)
            .Show()

        -- Ilvl
        GUI(children[it()]).SetText(roll.item:GetFullInfo().realLevel or "-").Show()

        -- Owner
        GUI(children[it()])
            .SetText(Unit.ColoredShortenedName(roll.item.owner))
            .SetUserData("unit", roll.item.owner)
            .Show()

        -- ML
        GUI(children[it()])
            .SetText(roll:HasMasterlooter() and Unit.ColoredShortenedName(roll.owner) or "-")
            .SetUserData("unit", roll:HasMasterlooter() and roll.owner or nil)
            .Show()

        -- Status
        local f = GUI(children[it()]).Show()
        if roll.status == Roll.STATUS_RUNNING or not roll.winner and roll.timers.award then
            f.SetUserData("roll", roll).SetScript("OnUpdate", Self.OnStatusUpdate)
            Self.OnStatusUpdate(f().frame)
        else
            f.SetText(roll.traded and L["ROLL_TRADED"] or roll.winner and L["ROLL_AWARDED"] or L["ROLL_STATUS_" .. roll.status])
            .SetUserData("roll", nil)
            .SetScript("OnUpdate", nil)
            .SetColor(1, 1, 1)
        end

        -- Your Bid
        GUI(children[it()])
            .SetText(roll:GetBidName(roll.bid))
            .SetColor(GUI.GetBidColor(roll.bid))
            .Show()

        -- Winner
        GUI(children[it()])
            .SetText(roll.winner and Unit.ColoredShortenedName(roll.winner) or "-")
            .SetUserData("unit", roll.winner or nil)
            .Show()

        -- Actions
        do
            local actions = children[it()]
            local details = children[it(0) + 1]
            local children = actions.children
            local it = Util.Iter()

            local canTrade = Trade.ShouldInitTrade(roll)
            local actionTarget = roll:GetActionTarget()

            -- Need
            GUI(children[it()]).SetUserData("roll", roll).Toggle(roll:UnitCanBid(nil, Roll.BID_NEED))
            -- Greed
            GUI(children[it()]).SetUserData("roll", roll).Toggle(roll:UnitCanBid(nil, Roll.BID_GREED))
            -- Disenchant
            GUI(children[it()]).SetUserData("roll", roll).Toggle(roll:UnitCanBid(nil, Roll.BID_DISENCHANT) and Unit.IsEnchanter())
            -- Pass
            GUI(children[it()]).SetUserData("roll", roll).Toggle(roll:UnitCanBid(nil, Roll.BID_PASS))
            -- Advertise
            GUI(children[it()]).SetUserData("roll", roll).Toggle(roll:ShouldAdvertise(true))
            -- Award randomly
            GUI(children[it()]).SetUserData("roll", roll).Toggle(roll:CanBeAwardedRandomly())
            -- Chat
            GUI(children[it()])
                .SetImage("Interface\\GossipFrame\\" .. (roll.chat and "Petition" or "Gossip") .. "GossipIcon")
                .SetImageSize(13, 13).SetWidth(16).SetHeight(16)
                .SetUserData("roll", roll)
                .SetUserData("unit", actionTarget)
                .Toggle(actionTarget)
            -- Trade
            GUI(children[it()])
                .SetUserData("roll", roll)
                .SetUserData("text", canTrade and TRADE or L["TIP_CHAT_TO_TRADE"])
                .Toggle(actionTarget)
                .SetDisabled(not canTrade)
            -- Restart
            GUI(children[it()]).SetUserData("roll", roll).Toggle(roll:CanBeRestarted())
            -- Cancel
            GUI(children[it()]).SetUserData("roll", roll).Toggle(roll:CanBeAwarded(true))
            -- Hide
            GUI(children[it()])
                .SetImage("Interface\\Buttons\\UI-CheckBox-Check" .. (roll.hidden and "-Disabled" or ""), -.1, 1.1, -.1, 1.1)
                .SetUserData("roll", roll)
                .SetUserData("text", L[roll.hidden and "SHOW" or "HIDE"])
                .Toggle(roll.hidden or roll.status > Roll.STATUS_RUNNING)
            -- Toggle
            GUI(children[it()])
                .SetImage("Interface\\Buttons\\UI-" .. (Self.open[roll.id] and "Minus" or "Plus") .. "Button-Up")
                .SetUserData("roll", roll)
                .SetUserData("details", details)

            GUI.ArrangeIconButtons(actions, nil, nil, -2)
        end

        -- Details
        local details = children[it()]
        if Self.open[roll.id] then
            Self.UpdateDetails(details, roll)
        else
            details.frame:Hide()
        end
    end

    -- Release the rest
    while children[it()] do
        children[it(0)]:Release()
        children[it(0)] = nil
    end

    Util.TblRelease(rolls, header)
    scroll:ResumeLayout()
    scroll:DoLayout()

    -- FILTER

    local filter = Self.frames.filter
    local it = Util.Iter(1)

    filter.children[it()]:SetValue(Self.filter.all)
    filter.children[it()]:SetValue(Self.filter.done)
    filter.children[it()]:SetValue(Self.filter.awarded)
    filter.children[it()]:SetValue(Self.filter.traded)
    filter.children[it()]:SetValue(Self.filter.hidden)

    -- ML action
    local ml = Session.GetMasterlooter()
    filter.children[it()]:SetImage(ml and "Interface\\Buttons\\UI-StopButton" or "Interface\\GossipFrame\\WorkOrderGossipIcon")

    -- ML
    GUI(filter.children[it()])
        .SetText(L["ML"] .. ": " .. (ml and Unit.ColoredShortenedName(ml) or ""))
        .SetUserData("unit", ml)
end

-------------------------------------------------------
--                   Update Details                  --
-------------------------------------------------------

-- Update the details view of a row
function Self.UpdateDetails(details, roll)
    details.frame:Show()
    details:PauseLayout()
    
    local children = details.children

    -- Header

    local header = Util.Tbl("PLAYER", "ITEM_LEVEL", "EQUIPPED", "CUSTOM", "BID", "ROLL", "VOTES", "")
    local numCols = #header - 1 + GUI.PlayerColumns:CountWhere("header")

    if #children == 0 then
        local columns = {1, {25, 100}, {34, 100}, {25, 100}, {25, 100}, {25, 100}, 100}
        
        for i,v in pairs(header) do
            if v == "CUSTOM" then
                local j = 0
                for _,col in GUI.PlayerColumns:Iter() do
                    if col.header then
                        details:AddChild(GUI("Label").SetFontObject(GameFontNormal).SetText(col.header).SetColor(1, 0.82, 0)())
                        tinsert(columns, i + j, col.width or {25, 100})
                        j = j + 1
                    end
                end
            else
                details:AddChild(GUI("Label").SetFontObject(GameFontNormal).SetText(L[v]).SetColor(1, 0.82, 0)())
            end
        end

        details.userdata.table.columns = columns
        GUI.TableRowHighlight(details, numCols)
    end

    -- Players

    local canBeAwarded, canVote = roll:CanBeAwarded(true), roll:UnitCanVote()

    local it = Util.Iter(numCols)
    local players = GUI.GetPlayerList(roll)

    for _,player in ipairs(players) do
        -- Create the row
        if not children[it(0) + 1] then
            -- Unit, Ilvl
            GUI.CreateUnitLabel(details)
            GUI("Label").SetFontObject(GameFontNormal).AddTo(details)
        
            -- Items
            local grp = GUI("SimpleGroup")
                .SetLayout(nil)
                .SetWidth(34).SetHeight(16)
                .SetBackdropColor(0, 0, 0, 0)
                .AddTo(details)()
            for i=1,2 do
                local f = GUI("Icon")
                    .SetCallback("OnEnter", GUI.TooltipItemLink)
                    .SetCallback("OnLeave", GUI.TooltipHide)
                    .SetCallback("OnClick", GUI.ItemClick)
                    .AddTo(grp)
                    .SetPoint(i == 1 and "LEFT" or "RIGHT")()
                f.image:SetPoint("TOP")
                f.OnRelease = GUI.ResetIcon
            end

            -- Custom columns
            for i,col in GUI.PlayerColumns:Iter() do
                if col.header then
                    GUI("Label").SetFontObject(GameFontNormal).AddTo(details)
                end
            end
        
            -- Bid, Roll
            GUI("Label").SetFontObject(GameFontNormal).AddTo(details)
            GUI("Label").SetFontObject(GameFontNormal).AddTo(details)
        
            -- Votes
            GUI("InteractiveLabel")
                .SetFontObject(GameFontNormal)
                .SetCallback("OnEnter", function (self)
                    local roll, unit = self:GetUserData("roll"), self:GetUserData("unit")
                    if Util.TblCountOnly(roll.votes, unit) > 0 then
                        GameTooltip:SetOwner(self.frame, "ANCHOR_BOTTOM")
                        GameTooltip:SetText(L["TIP_VOTES"])
                        for fromUnit,toUnit in pairs(roll.votes) do
                            if unit == toUnit then
                                local c = Unit.Color(fromUnit)
                                GameTooltip:AddLine(Unit.ShortenedName(fromUnit), c.r, c.g, c.b, false)
                            end
                        end
                        GameTooltip:Show()
                    end
                end)
                .SetCallback("OnLeave", GUI.TooltipHide)
                .AddTo(details)
        
            -- Action
            local f = GUI("Button")
                .SetWidth(100)
                .SetCallback("OnClick", Self.UnitconfirmOrVote)()
            f.text:SetFont(GameFontNormal:GetFont())
            details:AddChild(f)
        end

        -- Unit
        GUI(children[it()])
            .SetText(Unit.ColoredShortenedName(player.unit))
            .SetUserData("unit", player.unit)
            .Show()

        -- Ilvl
        GUI(children[it()]).SetText(player.ilvl).Show()

        -- Items
        local f, links = children[it()], roll.item:GetEquippedForLocation(player.unit)

        for i,child in pairs(f.children) do
            if links and links[i] then
                GUI(f.children[i])
                    .SetImage(Item.GetInfo(links[i], "texture"))
                    .SetImageSize(16, 16).SetWidth(16).SetHeight(16)
                    .SetUserData("link", links[i])
                    .Show()
            else
                child.frame:Hide()
            end
        end

        if not roll.item.isRelic then Util.TblRelease(links) end

        -- Custom columns
        for i,col in GUI.PlayerColumns:Iter() do
            if col.header then
                GUI(children[it()])
                    .SetText(Util.FnVal(col.desc, player.unit, roll, player) or player[col.name] or "-")
                    .Show()
            end
        end

        -- Bid
        GUI(children[it()])
            .SetText(roll:GetBidName(player.bid))
            .SetColor(GUI.GetBidColor(player.bid))
            .Show()

        -- Roll
        GUI(children[it()])
            .SetText(player.roll and Util.NumRound(player.roll) or "-")
            .Show()

        -- Votes
        GUI(children[it()])
            .SetText(player.votes > 0 and player.votes or "-")
            .SetUserData("roll", roll)
            .SetUserData("unit", player.unit)
            .Show()

        -- Action
        local isConfirming = canBeAwarded and Self.confirm.roll == roll.id and Self.confirm.unit == player.unit
        local hasVoted = canVote and roll.vote == player.unit
        GUI(children[it()])
            .SetText(
                isConfirming and L["CONFIRM"]
                or canBeAwarded and L["AWARD"]
                or hasVoted and L["VOTE_WITHDRAW"]
                or canVote and L["VOTE"]
                or "-"
            )
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

    Util.TblRelease(1, players, header)
    details:ResumeLayout()
end

-------------------------------------------------------
--                      Helpers                      --
-------------------------------------------------------

-- Create a filter checkbox
function Self.CreateFilterCheckbox(key)
    local parent = Self.frames.filter

    f = GUI("CheckBox")
        .SetLabel(L["FILTER_" .. key:upper()])
        .SetCallback("OnValueChanged", function (self, _, checked)
            if Self.filter[key] ~= checked then
                Self.filter[key] = checked
                Self.Update()
            end
        end)
        .SetCallback("OnEnter", function (self)
            GameTooltip:SetOwner(self.frame, "ANCHOR_TOP")
            GameTooltip:ClearLines()
            GameTooltip:AddLine(L["FILTER_" .. key:upper()])
            GameTooltip:AddLine(L["FILTER_" .. key:upper() .. "_DESC"], 1, 1, 1, true)
            GameTooltip:Show()
        end)
        .SetCallback("OnLeave", GUI.TooltipHide)
        .AddTo(parent)
        .SetPoint("LEFT", parent.children[#parent.children-1].frame, "RIGHT", 15, 0)()
    f:SetWidth(f.text:GetStringWidth() + 24)
    return f
end

-- Roll status OnUpdate callback
function Self.OnStatusUpdate(frame)
    local roll, txt = frame.obj:GetUserData("roll")
    if roll.status == Roll.STATUS_RUNNING then
        local timeLeft = roll:GetTimeLeft(true)
        GUI(frame.obj)
            .SetColor(1, 1, 0)
            .SetText(L["ROLL_STATUS_" .. Roll.STATUS_RUNNING] .. (timeLeft > 0 and " (" .. L["SECONDS"]:format(timeLeft) .. ")" or ""))
    elseif not roll.winner and roll.timers.award then
        GUI(frame.obj)
            .SetColor(0, 1, 0)
            .SetText(L["ROLL_AWARDING"] .. " (" .. L["SECONDS"]:format(ceil(roll.timers.award.ends - GetTime())) .. ")")
    else
        GUI(frame.obj).SetColor(1, 1, 1).SetText("-")
    end
end

function Self.UnitconfirmOrVote(self, ...)
    local roll, unit = self:GetUserData("roll"), self:GetUserData("unit")
    if roll:CanBeAwardedTo(unit, true) and not (Self.confirm.roll == roll.id and Self.confirm.unit == unit) then
        Self.confirm.roll, Self.confirm.unit = roll.id, unit
        Self.Update()
    else
        wipe(Self.confirm)
        GUI.UnitAwardOrVote(self, ...)
    end
end

-------------------------------------------------------
--                      Events                       --
-------------------------------------------------------

function Self:OnEnable()
    Self:RegisterMessage(Roll.EVENT_START, "ROLL_START")
    Self:RegisterMessage(Roll.EVENT_CHANGE, Self.Update)
    Self:RegisterMessage(Roll.EVENT_CLEAR, "ROLL_CLEAR")
    Self:RegisterMessage(Session.EVENT_CHANGE, Self.Update)
    Self:RegisterMessage(GUI.PlayerColumns.EVENT_CHANGE, "GUI_PLAYER_COLUMN_CHANGE")
end

function Self:OnDisable()
    Self:UnregisterAllMessages()
end

function Self:ROLL_START(_, roll)
    if roll.isOwner and Session.IsMasterlooter() or Addon.db.profile.ui.showRollsWindow and (roll.item.isOwner or roll:ShouldBeBidOn()) then
        Self.Show()
    end
end

function Self:ROLL_CLEAR(_, roll)
    Self.open[roll.id] = nil
end

function Self:GUI_PLAYER_COLUMN_CHANGE()
    if Self.frames.scroll then
        for i,child in pairs(Self.frames.scroll.children) do
            if child:GetUserData("isDetails") then
                child:ReleaseChildren()
            end
        end

        Self.Update()
    end
end