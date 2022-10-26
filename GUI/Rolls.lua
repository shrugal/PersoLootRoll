---@type string
local Name = ...
---@type Addon
local Addon = select(2, ...)
---@type L
local L = LibStub("AceLocale-3.0"):GetLocale(Name)
local AceGUI = LibStub("AceGUI-3.0")
local GUI, Inspect, Item, Options, Session, Roll, Trade, Unit, Util = Addon.GUI, Addon.Inspect, Addon.Item, Addon.Options, Addon.Session, Addon.Roll, Addon.Trade, Addon.Unit, Addon.Util
---@class Rolls : Module
local Self = GUI.Rolls

---@type table<Widget>
Self.frames = {}
---@type table<Widget>
Self.buttons = {}
Self.filter = {all = false, hidden = false, done = true, awarded = true, traded = false, id = nil}
Self.status = {width = 700, height = 300}
Self.open = {}
Self.confirm = {roll = nil, unit = nil}

---@type Texture
local HIGHLIGHT = UIParent:CreateTexture(nil, "OVERLAY")
HIGHLIGHT:SetTexture("Interface\\PaperDollInfoFrame\\UI-GearManager-ItemButton-Highlight")
HIGHLIGHT:SetTexCoord(.1, .6, .1, .7)
HIGHLIGHT:SetBlendMode("ADD")

-------------------------------------------------------
--                     Show/Hide                     --
-------------------------------------------------------

-- Show the frame
function Self.Show()
    if Self.frames.window then
        Self.frames.window.frame:Show()
    else
        Addon:Debug("GUI.Rolls.Show")
        local f

        -- WINDOW

        local window = GUI("Window")
            .SetLayout(nil)
            .SetFrameStrata("MEDIUM")
            .SetTitle("PersoLootRoll - " .. L["ROLLS"])
            .SetResizeBounds(550, 120)
            .SetStatusTable(Self.status)
            .SetCallback("OnClose", function (self)
                Self.status.width = self.frame:GetWidth()
                Self.status.height = self.frame:GetHeight()
                self:Release()
                GUI(HIGHLIGHT).SetParent(UIParent).Hide()
                Util.Tbl.Wipe(Self.frames, Self.buttons, Self.open, Self.confirm)
            end)()

        -- Darker background
        GUI(select(2, window.frame:GetRegions()))
            .SetColorTexture(0, 0, 0, 1)
            .SetVertexColor(0, 0, 0, .8)
        local OnRelease = window.OnRelease
        window.OnRelease = function (self, ...)
            GUI(select(2, self.frame:GetRegions()))
                .SetTexture([[Interface\Tooltips\UI-Tooltip-Background]])
                .SetVertexColor(0, 0, 0, .75)
            self.OnRelease = OnRelease
            self:OnRelease(...)
        end

        Self.frames.window = window

        -- BUTTONS

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

        Self.buttons.options = f

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
        f.frame:SetPoint("RIGHT", Self.buttons.options.frame, "LEFT", -15, 0)
        f.frame:SetFrameStrata("HIGH")
        f.frame:Show()

        Self.buttons.test = f

        -- Version label
        f = GUI("InteractiveLabel")
            .SetText("v" .. Addon.VERSION)
            .SetColor(1, 0.82, 0)
            .SetCallback("OnEnter", function(self)
                if IsInGroup() then
                    GameTooltip:SetOwner(self.frame, "ANCHOR_BOTTOMRIGHT")

                    -- Addon versions
                    local count = Util.Tbl.Count(Addon.versions)
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
                                s = Util.Str.Postfix(s, ", ") .. Unit.ColoredShortenedName(unit)
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
                                s = Util.Str.Postfix(s, ", ") .. Unit.ColoredShortenedName(unit)
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
        f.frame:SetPoint("RIGHT", Self.buttons.test.frame, "LEFT", -15, -1)
        f.frame:SetFrameStrata("HIGH")
        f.frame:Show()

        Self.buttons.version = f

        -- ITEMS

        f = GUI("ScrollFrame")
            .SetLayout("List")
            .AddTo(Self.frames.window)
            .SetPoint("TOPRIGHT", Self.frames.window.content, "TOPLEFT", -4, 8)
            .SetPoint("BOTTOM")
            .SetFrameStrata("LOW")
            .SetWidth(40)()
        local fixScroll, onRelease = f.FixScroll, f.OnRelease
        f.FixScroll = function (self, ...)
            fixScroll(self, ...)
            self.scrollbar:Hide()
            self.scrollframe:SetPoint("BOTTOMRIGHT")
        end
        f.OnRelease = function (self)
            self.content:SetFrameStrata("MEDIUM")
            self.FixScroll, self.OnRelease = fixScroll, onRelease
            self:OnRelease()
        end
        Self.frames.items = f

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
                        local council = not s.council and "-" or Util(s.council):Keys():Map(function (unit)
                            return Unit.ColoredShortenedName(unit)
                        end):Concat(", ")()
                        local bids = L[s.bidPublic and "PUBLIC" or "PRIVATE"]
                        local votes = L[s.votePublic and "PUBLIC" or "PRIVATE"]

                        GameTooltip:SetOwner(self.frame, "ANCHOR_BOTTOM")
                        GameTooltip:SetText(L["TIP_MASTERLOOT"] .. "\n")
                        GameTooltip:AddLine(L["TIP_MASTERLOOT_INFO"]:format(Unit.ColoredName(ml), timeoutBase, timeoutPerItem, council, bids, votes), 1, 1, 1)

                        -- Players
                        GameTooltip:AddLine("\n" .. L["TIP_MASTERLOOTING"]:format(1 + Util.Tbl.CountOnly(Session.masterlooting, ml)))
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
                .SetCallback("OnClick", function (...)
                    if Session.IsMasterlooter() then
                        Options.Show("Masterloot")
                    else
                        GUI.UnitClick(...)
                    end
                end)
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
        f.layoutFinished = Util.Fn.Noop
        Self.frames.scroll = f

        -- EMPTY MESSAGE

        Self.frames.empty = GUI("Label")
            .SetFont(GameFontNormal:GetFont(), 14, "")
            .SetColor(0.5, 0.5, 0.5)
            .SetText("- " .. L["ROLL_LIST_EMPTY"] .. " -")
            .AddTo(Self.frames.window)
            .SetPoint("CENTER")()

        Self.Update()
    end
end

-- Check if the frame is currently being shown
---@return boolean
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

function Self.Update()
    if Self.frames.window then
        if Self.filter.id and not Self.TestRoll(Roll.Get(Self.filter.id)) then
            Self.filter.id = nil
        end

        Self.UpdateRolls()
        Self.UpdateItems()

        Self.DoLayout(false, true)
    end
end

function Self.DoLayout(now, next, frame)
    frame = frame or Self.frames.scroll

    if frame then
        if now then
            frame:DoLayout()
        end
        if next then
            Self:ScheduleTimer(frame.DoLayout, 0, frame)
        end
    end
end

-- Update the frame
function Self.UpdateRolls()
    local f
    local ml = Session.GetMasterlooter()

    -- SCROLL

    local scroll = Self.frames.scroll
    local children = scroll.children
    scroll:PauseLayout()

    -- Header

    local header = Util.Tbl.New("ID", "ITEM", "LEVEL", "OWNER", "ML", "STATUS", "YOUR_BID", "WINNER")
    if #children == 0 then
        scroll.userdata.table.columns = {20, 1, {25, 100}, {25, 100}, {25, 100}, {25, 100}, {25, 100}, {25, 100}, 8 * 20 - 4}

        for _,v in pairs(header) do
            GUI("Label").SetFontObject(GameFontNormal).SetText(L[v]).SetColor(1, 0.82, 0).AddTo(scroll)
        end

        local actions = GUI("SimpleGroupWithBackdrop")
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
        f = GUI.CreateIconButton("UI-MinusButton", actions, function ()
            for _,child in pairs(scroll.children) do
                if child:GetUserData("isDetails") then child.frame:Hide() end
            end
            wipe(Self.open)
            Self.Update()
        end, L["HIDE_ALL"])
        f.image:SetPoint("TOP", 0, 2)
        f.frame:SetPoint("TOPRIGHT")

        local color = {0.25, 0.25, 0.25, 0.9}
        GUI.TableRowBackground(scroll, function (_, _, cols) return cols > 1 and color end, #header + 1)
    end

    GUI(children[#header + 1].children[1]).Toggle(not Self.filter.id)

    -- Rolls

    local rolls = Self.GetRolls(true)

    GUI(Self.frames.empty).Toggle(Util.Tbl.Count(rolls) == 0)

    local it = Util.Iter(#header + 1)
    for i,roll in ipairs(rolls) do
        -- Create the row
        if not children[it(0) + 1] then
            -- ID
            GUI("Label")
                .SetFontObject(GameFontNormal)
                .AddTo(scroll)()

            -- Item
            GUI.CreateItemLabel(scroll)

            -- Ilvl
            GUI("Label")
                .SetFontObject(GameFontNormal)
                .AddTo(scroll)

            -- Owner, ML
            GUI.CreateUnitLabel(scroll)
            GUI.CreateUnitLabel(scroll)

            -- Status
            f = GUI("Label").SetFontObject(GameFontNormal).AddTo(scroll)()
            f.OnRelease = GUI.ResetLabel

            -- Your bid, Winner
            GUI("Label").SetFontObject(GameFontNormal).AddTo(scroll)
            GUI.CreateUnitLabel(scroll)

            -- Actions
            f = GUI("SimpleGroupWithBackdrop")
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
                        GUI.RollBid(roll, bid)
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
                    GUI.RollBid(self:GetUserData("roll"), Roll.BID_DISENCHANT)
                end, ROLL_DISENCHANT, 14, 14)

                -- Pass
                GUI.CreateIconButton("UI-GroupLoot-Pass", actions, function (self)
                    GUI.RollBid(self:GetUserData("roll"), Roll.BID_PASS)
                end, PASS, 13, 13)

                -- Start
                f = GUI.CreateIconButton("UI-SpellbookIcon-NextPage", actions, function (self)
                    self:GetUserData("roll"):Start(true)
                end, START)
                f.image:SetPoint("TOP", 0, 2)
                f.image:SetTexCoord(0.05, 0.95, 0.05, 0.95)

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
                    StaticPopup_Show(GUI.DIALOG_ROLL_RESTART, nil, nil, self:GetUserData("roll"))
                end, L["RESTART"])
                f.image:SetPoint("TOP", 0, 2)
                f.image:SetTexCoord(0.07, 0.93, 0.07, 0.93)

                -- Cancel
                f = GUI.CreateIconButton("CancelButton", actions, function (self)
                    StaticPopup_Show(GUI.DIALOG_ROLL_CANCEL, nil, nil, self:GetUserData("roll"))
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
                    
                    Self.DoLayout(true, true)
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
        f = GUI(children[it()]).Show()
        if roll.status == Roll.STATUS_RUNNING or not roll.winner and roll.timers.award then
            f.SetUserData("roll", roll)
            .SetScript("OnUpdate", Self.OnStatusUpdate)
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
            .SetColor(GUI.RollBidColor(roll.bid))
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
            -- Start
            GUI(children[it()]).SetUserData("roll", roll).Toggle(roll:CanBeStarted())
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
                .Show()
            -- Toggle
            GUI(children[it()])
                .Toggle(not Self.filter.id)
                .SetImage("Interface\\Buttons\\UI-" .. (Self.open[roll.id] and "Minus" or "Plus") .. "Button-Up")
                .SetUserData("roll", roll)
                .SetUserData("details", details)

            GUI.ArrangeIconButtons(actions, nil, nil, -2)
        end

        -- Details
        local details = children[it()]
        if Self.open[roll.id] or Self.filter.id == roll.id then
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

    Util.Tbl.Release(rolls, header)
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
---@param details SimpleGroup
---@param roll Roll
function Self.UpdateDetails(details, roll)
    details.frame:Show()
    details:PauseLayout()

    local children = details.children

    -- Header

    local header = Util.Tbl.New("PLAYER", "ITEM_LEVEL", "EQUIPPED", "CUSTOM", "BID", "ROLL", "VOTES", "")
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
            local grp = GUI("SimpleGroupWithBackdrop")
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
                    ---@type Roll
                    local roll = self:GetUserData("roll")
                    local unit = self:GetUserData("unit")
                    if Util.Tbl.CountOnly(roll.votes, unit) > 0 then
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
                .SetCallback("OnClick", Self.UnitConfirmOrVote)()
            f.text:SetFont(GameFontNormal:GetFont(), 12, "")
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

        if not roll.item:IsRelic() then Util.Tbl.Release(links) end

        -- Custom columns
        for i,col in GUI.PlayerColumns:Iter() do
            if col.header then
                GUI(children[it()])
                    .SetText(Util.Fn.Val(col.desc, player.unit, roll, player) or player[col.name] or "-")
                    .Show()
            end
        end

        -- Bid
        GUI(children[it()])
            .SetText(roll:GetBidName(player.bid))
            .SetColor(GUI.RollBidColor(player.bid))
            .Show()

        -- Roll
        GUI(children[it()])
            .SetText(player.roll and Util.Num.Round(player.roll) or "-")
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

    Util.Tbl.Release(1, players, header)
    details:ResumeLayout()
end

-------------------------------------------------------
--                    Update Items                   --
-------------------------------------------------------

function Self.UpdateItems()
    local f
    local items = Self.frames.items
    local children = items.children
    local size = 40

    items:PauseLayout()

    if #children == 0 then
        f = GUI.CreateIcon(items, GUI.TooltipText, Self.ItemClick)
        GUI(f).SetImageSize(size, size)
            .SetWidth(size)
            .SetHeight(size)
            .SetImage(237285)
            .SetUserData("text", L["SHOW_ALL"])
    end

    local rolls = Self.GetRolls()
    local selected

    local it = Util.Iter(1)
    for _,roll in ipairs(rolls) do
        if not children[it(0) + 1] then
            f = GUI.CreateItemIcon(items, Self.ItemClick)
            GUI(f).SetImageSize(size, size)
                .SetWidth(size)
                .SetHeight(size)
                .SetUserData("anchor", "ANCHOR_LEFT")
        end

        f = GUI(children[it()])
            .SetImage(roll.item.texture)
            .SetUserData("id", roll.id)
            .SetUserData("link", roll.item.link)()

        if Self.filter.id == roll.id then
            selected = f.frame
        end
    end

    -- Release the rest
    while children[it()] do
        children[it(0)]:Release()
        children[it(0)] = nil
    end

    GUI(HIGHLIGHT)
        .SetParent(selected or children[1].frame)
        .SetAllPoints()
        .Show()

    Util.Tbl.Release(rolls)
    items:ResumeLayout()
    items:DoLayout()
end

-------------------------------------------------------
--                      Helpers                      --
-------------------------------------------------------

---@return Roll[]
function Self.GetRolls(filterById)
    return Util(Addon.rolls):CopyFilter(function (roll)
        if filterById and Self.filter.id then
            return Self.filter.id == roll.id
        else
            return Self.TestRoll(roll)
        end
    end):SortBy("id")()
end

function Self.TestRoll(roll)
    local ml = Session.GetMasterlooter()
    local startManually = ml and Addon.db.profile.masterloot.rules.startManually
    local startLimit = ml and Addon.db.profile.masterloot.rules.startLimit or 0

    return  roll
        and (Self.filter.all or roll.isOwner or roll.item.isOwner or roll.item:IsLoaded() and roll.item:GetEligible("player"))
        and (Self.filter.done or (roll.status ~= Roll.STATUS_DONE))
        and (Self.filter.awarded or not roll.winner)
        and (Self.filter.traded or not roll.traded)
        and (Self.filter.hidden or not roll.hidden and (
            roll.status >= Roll.STATUS_RUNNING and (roll.isWinner or roll.isOwner or roll.item.isOwner or roll.bid ~= Roll.BID_PASS)
            or (startManually or startLimit > 0) and roll:CanBeStarted()
        ))
end

-- Create a filter checkbox
---@param key string
---@return CheckBox
function Self.CreateFilterCheckbox(key)
    local parent = Self.frames.filter

    local f = GUI("CheckBox")
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

function Self.ItemClick(self)
    local id = self:GetUserData("id")
    Self.filter.id = Self.filter.id ~= id and id or nil
    Self.Update()
end

-- Roll status OnUpdate callback
---@param frame Frame
function Self.OnStatusUpdate(frame)
    local roll = frame.obj:GetUserData("roll")
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

---@param self Widget
function Self.UnitConfirmOrVote(self, ...)
    ---@type Roll
    local roll = self:GetUserData("roll")
    local unit = self:GetUserData("unit")
    Addon:Debug("GUI.Click:Rolls.ConfirmOrVote", roll and roll.id, unit, Self.confirm)

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

-- Debounce updates after roll changes to prevent flickering
local updateDebounced = Util.Fn.Debounce(Self.Update, 0.02)

function Self:OnEnable()
    Self:RegisterMessage(Roll.EVENT_START, "ROLL_START")
    Self:RegisterMessage(Roll.EVENT_CHANGE, updateDebounced)
    Self:RegisterMessage(Roll.EVENT_CLEAR, "ROLL_CLEAR")
    Self:RegisterMessage(Session.EVENT_CHANGE, updateDebounced)
    Self:RegisterMessage(GUI.PlayerColumns.EVENT_CHANGE, "GUI_PLAYER_COLUMN_CHANGE")
end

function Self:OnDisable()
    Self:UnregisterAllMessages()
end

---@param roll Roll
function Self:ROLL_START(_, roll)
    if roll.isOwner and Session.IsMasterlooter() or Addon.db.profile.ui.showRollsWindow and (roll.item.isOwner or roll:ShouldBeBidOn()) then
        Self.Show()
    end
end

---@param roll Roll
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

        updateDebounced()
    end
end