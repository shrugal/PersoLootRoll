---@type string
local Name = ...
---@type Addon
local Addon = select(2, ...)
---@type L
local L = LibStub("AceLocale-3.0"):GetLocale(Name)
local AceGUI = LibStub("AceGUI-3.0")
local CB = LibStub("CallbackHandler-1.0")
local Comm, Inspect, Item, Options, Session, Roll, Trade, Unit, Util = Addon.Comm, Addon.Inspect, Addon.Item, Addon.Options, Addon.Session, Addon.Roll, Addon.Trade, Addon.Unit, Addon.Util
---@class GUI
local Self = Addon.GUI

--- Add a player column entry
---@class PlayerColumns : Registrar
---@field Add function(name: string, value: string|number|function, header: string, desc: string|number|function, width: number, sortBefore: string, sortDefault: any, sortDesc: boolean): table
---@param name string       A unique identifier
---@param value string|number|function(unit: string, roll: Roll, listEntity: table):string|number   Value for sorting etc., either a primitive or callback
---@param header string     Localized title, e.g. for table headers (optional: Column won't be shown)
---@param desc string|number|function(unit: string, roll: Roll, listEntity: table):string|number    Localized value shown to the user (optional: Value will be used)
---@param width number      Column width, @see table layout for details (optional: Default will be used)
---@param sortBefore string Other column name with lower sorting priority, one of "bid", "votes", "roll", "ilvl" or "unit" (optional: Column won't be used for sorting)
---@param sortDefault any   Sorting default value (optional)
---@param sortDesc boolean  Sort in descending order (optional)
---@return table            The column entry
Self.PlayerColumns = Util.Registrar.New("GUI_PLAYER_COLUMN", "name", function (name, value, header, desc, width, sortBefore, sortDefault, sortDesc)
    return Util.Tbl.Hash("name", name, "value", value, "header", header, "desc", desc, "width", width, "sortBefore", sortBefore, "sortDefault", sortDefault, "sortDesc", sortDesc)
end)

-- Windows
Self.Rolls = Self:NewModule("Rolls", nil, "AceEvent-3.0", "AceTimer-3.0")
Self.Actions = Self:NewModule("Actions", nil, "AceEvent-3.0")

-- Row highlight frame
---@type Frame
Self.HIGHLIGHT = CreateFrame("Frame", nil, UIParent)
Self.HIGHLIGHT:SetFrameStrata("BACKGROUND")
Self.HIGHLIGHT:Hide()
---@type Texture
local tex = Self.HIGHLIGHT:CreateTexture(nil, "BACKGROUND")
tex:SetTexture("Interface\\Buttons\\UI-Listbox-Highlight")
tex:SetVertexColor(1, 1, 1, .5)
tex:SetAllPoints(Self.HIGHLIGHT)

-------------------------------------------------------
--                  Popup dialogs                    --
-------------------------------------------------------

Self.DIALOG_ROLL_CANCEL = "PLR_ROLL_CANCEL"
StaticPopupDialogs[Self.DIALOG_ROLL_CANCEL] = {
    text = L["DIALOG_ROLL_CANCEL"],
    button1 = YES,
    button2 = NO,
    OnAccept = function(self, roll)
        Addon:Debug("GUI.Click:RollCancelDialog", roll and roll.id)
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
        Addon:Debug("GUI.Click:RollRestartDialog", roll and roll.id)
        roll:Restart()
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3
}

Self.DIALOG_ROLL_WHISPER_ASK = "PLR_ROLL_WHISPER_ASK"
StaticPopupDialogs[Self.DIALOG_ROLL_WHISPER_ASK] = {
    text = L["DIALOG_ROLL_WHISPER_ASK"],
    button1 = YES,
    button2 = NO,
    OnAccept = function(_, data)
        local roll, bid = Util.Tbl.Unpack(data)
        Addon:Debug("GUI.Click:RollWhisperAskDialog", true, roll and roll.id, bid)

        if Util.InstanceOf(roll, Roll) then
            Addon.db.profile.messages.whisper.ask = true
            Addon.db.profile.messages.whisper.askPrompted = true

            Self.RollBid(roll, bid)
        end
    end,
    OnCancel = function(_, data, reason)
        local roll, bid = Util.Tbl.Unpack(data)
        Addon:Debug("GUI.Click:RollWhisperAskDialog", reason, roll and roll.id, bid)

        if Util.InstanceOf(roll, Roll) and reason == "clicked" then
            Addon.db.profile.messages.whisper.ask = false
            Addon.db.profile.messages.whisper.askPrompted = true

            Self.RollBid(roll, bid)
        end
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
    cancels = Self.DIALOG_ROLL_WHISPER_ASK
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

Self.DIALOG_OPT_MASTERLOOT_LOAD = "PLR_OPT_MASTERLOOT_LOAD"
StaticPopupDialogs[Self.DIALOG_OPT_MASTERLOOT_LOAD] = {
    text = L["DIALOG_OPT_MASTERLOOT_LOAD"],
    button1 = YES,
    button2 = NO,
    OnAccept = function ()
        Addon:Debug("GUI.Click:MasterlootLoadDialog")
        Options.ImportRules()
    end,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3
}

Self.DIALOG_OPT_MASTERLOOT_SAVE = "PLR_OPT_MASTERLOOT_SAVE"
StaticPopupDialogs[Self.DIALOG_OPT_MASTERLOOT_SAVE] = {
    text = L["DIALOG_OPT_MASTERLOOT_SAVE"],
    button1 = YES,
    button2 = NO,
    OnAccept = function ()
        Addon:Debug("GUI.Click:MasterlootSaveDialog")
        Options.ExportRules()
    end,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3
}

-------------------------------------------------------
--                 LootAlertSystem                   --
-------------------------------------------------------

-- Setup
local function PLR_LootWonAlertFrame_SetUp(self, itemLink, quantity, rollType, roll, specID, isCurrency, showFactionBG, lootSource, lessAwesome, isUpgraded, wonRoll, showRatedBG, rollId)
    self.rollId = rollId

    LootWonAlertFrame_SetUp(self, itemLink, quantity, rollType, roll, specID, isCurrency, showFactionBG, lootSource, lessAwesome, isUpgraded, wonRoll, showRatedBG)
end

-- OnClick
function PLR_LootWonAlertFrame_OnClick(self, ...)
    if not AlertFrame_OnClick(self, ...) then
        local roll = Roll.Get(self.rollId)
        Addon:Debug("GUI.Click:LootWonAlert", roll and roll.id)

        if roll and not roll.traded then
            Trade.Initiate(roll.item.owner)
        end
    end
end

Self.LootAlertSystem = AlertFrame:AddQueuedAlertFrameSubSystem("PLR_LootWonAlertFrameTemplate", PLR_LootWonAlertFrame_SetUp, 6, math.huge);

-------------------------------------------------------
--                     Dropdowns                     --
-------------------------------------------------------

-- Masterloot
function Self.ToggleMasterlootDropdown(...)
    local dropdown = Self.dropdownMasterloot
    if not dropdown then
        dropdown = Self("Dropdown-Pullout").Hide()()
        Self("Dropdown-Item-Execute")
            .SetText(L["MENU_MASTERLOOT_SEARCH"])
            .SetCallback("OnClick", function ()
                Addon:Debug("GUI.Click:MasterlootDropdown.RequestML")
                Session.SendRequest()
            end)
            .AddTo(dropdown)
        Self("Dropdown-Item-Execute")
            .SetText(L["MENU_MASTERLOOT_START"])
            .SetCallback("OnClick", function ()
                Addon:Debug("GUI.Click:MasterlootDropdown.BecomeML")
                Session.SetMasterlooter("player")
            end)
            .AddTo(dropdown)
        Self("Dropdown-Item-Execute")
            .SetText(L["MENU_MASTERLOOT_SETTINGS"])
            .SetCallback("OnClick", function () Options.Show("Masterloot") end)
            .AddTo(dropdown)
        Self("Dropdown-Item-Execute")
            .SetText("- " .. CLOSE .. " -")
            .SetCallback("OnClick", function () dropdown:Close() end)
            .AddTo(dropdown)
        Self.dropdownMasterloot = dropdown
    end

    if not dropdown:IsShown() then dropdown:Open(...) else dropdown:Close() end
end

-- Custom bid answers
---@param roll Roll
---@param bid number
---@param answers table
function Self.ToggleAnswersDropdown(roll, bid, answers, ...)
    local dropdown = Self.dropdownAnswers
    if not dropdown then
        dropdown = AceGUI:Create("Dropdown-Pullout")
        Self.dropdownAnswers = dropdown
    end

    if roll ~= dropdown:GetUserData("roll") or bid ~= dropdown:GetUserData("bid") then
        Self(dropdown).Clear().SetUserData("roll", roll).SetUserData("bid", bid).Hide()

        for i,v in pairs(answers) do
            Self("Dropdown-Item-Execute")
                .SetText(Util.In(v, Roll.ANSWER_NEED, Roll.ANSWER_GREED) and L["ROLL_BID_" .. bid] or v)
                .SetCallback("OnClick", function ()
                    Addon:Debug("GUI.Click:AnswersDropdown.Bid", roll and roll.id, bid, i)
                    roll:Bid(bid + i/10)
                end)
                .AddTo(dropdown)
        end
    end

    if not dropdown:IsShown() then dropdown:Open(...) else dropdown:Close() end
end

-- Award loot
---@param roll Roll
function Self.ToggleAwardOrVoteDropdown(roll, ...)
    local dropdown = Self.dropdownAwardOrVote
    if not dropdown then
        dropdown = AceGUI:Create("Dropdown-Pullout")
        Self.dropdownAwardOrVote = dropdown
    end

    if not dropdown:IsShown() or roll ~= dropdown:GetUserData("roll") then
        Self(dropdown).Clear().SetUserData("roll", roll)

        local players = Self.GetPlayerList(roll)
        local width = 0

        for i,player in pairs(players) do
            local f = Self("Dropdown-Item-Execute")
                .SetText(("%s: |c%s%s|r (%s: %s, %s: %s)"):format(
                    Unit.ColoredShortenedName(player.unit),
                    Util.Str.Color(Self.RollBidColor(player.bid)), roll:GetBidName(player.bid),
                    L["VOTES"], player.votes,
                    L["ITEM_LEVEL"], player.ilvl
                ))
                .SetCallback("OnClick", Self.UnitAwardOrVote)
                .SetUserData("roll", roll)
                .SetUserData("unit", player.unit)
                .AddTo(dropdown)()
            width = max(width, f.text:GetStringWidth())
        end

        Self("Dropdown-Item-Execute")
            .SetText("- " .. CLOSE .. " -")
            .SetCallback("OnClick", function () dropdown:Close() end)
            .AddTo(dropdown)

        dropdown.frame:SetWidth(max(200, width + 32 + dropdown:GetLeftBorderWidth() + dropdown:GetRightBorderWidth()))

        Util.Tbl.Release(1, players)
        dropdown:Open(...)
    else
        dropdown:Close()
    end
end

-- Award loot to unit
---@param unit string
function Self.ToggleAwardUnitDropdown(unit, ...)
    local dropdown = Self.dropdownAwardUnit
    if not dropdown then
        dropdown = AceGUI:Create("Dropdown-Pullout")
        Self.dropdownAwardUnit = dropdown
    end

    if unit ~= dropdown:GetUserData("unit") then
        Self(dropdown).Clear().SetUserData("unit", unit).Hide()

        for i,roll in pairs(Addon.rolls) do
            if roll:CanBeAwardedTo(unit, true) then
                Self("Dropdown-Item-Execute")
                    .SetText(roll.item.link)
                    .SetCallback("OnClick", function (...)
                        Addon:Debug("GUI.Click:AwardUnitDropdown.Item", roll and roll.id, unit)
                        if not Self.ItemClick(...) then
                            roll:End(unit, true)
                        end
                    end)
                    .SetCallback("OnEnter", Self.TooltipItemLink)
                    .SetCallback("OnLeave", Self.TooltipHide)
                    .SetUserData("link", roll.item.link)
                    .AddTo(dropdown)
            end
        end

        Self("Dropdown-Item-Execute")
            .SetText("- " .. CLOSE .. " -")
            .SetCallback("OnClick", function () dropdown:Close() end)
            .AddTo(dropdown)
    end

    if not dropdown:IsShown() then dropdown:Open(...) else dropdown:Close() end
end

-------------------------------------------------------
--                 Roll player list                  --
-------------------------------------------------------

--- Get list of eligible players for a roll
---@param roll Roll The roll in question
-- @return table    A sorted list of eligible players
function Self.GetPlayerList(roll)
    local list = Util(roll.item:GetEligible()):Copy():Merge(roll.bids):Map(function (val, unit)
        return Util.Tbl.Hash(
            "unit", unit,
            "ilvl", roll.item:GetLevelForLocation(unit),
            "bid", type(val) == "number" and val or nil,
            "votes", Util.Tbl.CountOnly(roll.votes, unit),
            "roll", roll.rolls[unit]
        )
    end, true):List()()

    local sortBy = Util.Tbl.New(
        "bid",   99,  false,
        "votes", 0,   true,
        "roll",  100, true,
        "ilvl",  0,   false,
        "unit",  nil, false
    )

    -- Add custom columns
    for i,col in Self.PlayerColumns:Iter() do
        for j,entry in pairs(list) do
            entry[col.name] = Util.Fn.Val(col.value, entry.unit, roll, entry)
        end

        local sortPos = col.sortBefore and Util.Tbl.Find(sortBy, col.sortBefore)
        if sortPos then
            tinsert(sortBy, sortPos, col.sortDesc or false)
            tinsert(sortBy, sortPos, col.sortDefault)
            tinsert(sortBy, sortPos, col.name)
        end
    end

    return Util.Tbl.SortBy(list, sortBy), Util.Tbl.Release(sortBy)
end

-------------------------------------------------------
--                      Helper                       --
-------------------------------------------------------

---@param anchor string
function Self.ReverseAnchor(anchor)
    return anchor:gsub("TOP", "B-OTTOM"):gsub("BOTTOM", "T-OP"):gsub("LEFT", "R-IGHT"):gsub("RIGHT", "L-EFT"):gsub("-", "")
end

-- Create an interactive label for a unit, with tooltip, unitmenu and whispering on click
---@param parent Frame|Widget
---@param baseTooltip boolean
function Self.CreateUnitLabel(parent, baseTooltip)
    return Self("InteractiveLabel")
        .SetFontObject(GameFontNormal)
        .SetCallback("OnEnter", baseTooltip and Self.TooltipUnit or Self.TooltipUnitFullName)
        .SetCallback("OnLeave", Self.TooltipHide)
        .SetCallback("OnClick", Self.UnitClick)
        .AddTo(parent)
end

-- Create an interactive label for an item, with tooltip and click support
---@param parent Frame|Widget
---@return InteractiveLabel
function Self.CreateItemLabel(parent)
    local f = Self("InteractiveLabel")
        .SetFontObject(GameFontNormal)
        .SetCallback("OnEnter", Self.TooltipItemLink)
        .SetCallback("OnLeave", Self.TooltipHide)
        .SetCallback("OnClick", Self.ItemClick)
        .AddTo(parent)()

    -- Fix the stupid label anchors
    local methods = Util.Tbl.CopySelect(f, "OnWidthSet", "SetText", "SetImage", "SetImageSize")
    for name,fn in pairs(methods) do
        f[name] = function (self, ...)
            fn(self, ...)

            if self.imageshown then
                self.label:ClearAllPoints()
                self.image:ClearAllPoints()

                self.image:SetPoint("TOPLEFT")
                if self.image:GetHeight() > self.label:GetHeight() then
                    self.label:SetPoint("LEFT", self.image, "RIGHT", 4, 0)
                else
                    self.label:SetPoint("TOPLEFT", self.image, "TOPRIGHT", 4, 0)
                end
                self.label:SetPoint("RIGHT")

                local height = max(self.image:GetHeight(), self.label:GetHeight())
                self.resizing = true
                self.frame:SetHeight(height)
                self.frame.height = height
                self.resizing = nil
            end
        end
    end
    f.OnRelease = function (self)
        for name,fn in pairs(methods) do f[name] = fn end
        Util.Tbl.Release(methods)
        f.OnRelease = nil
    end

    return f
end

function Self.CreateIcon(parent, onEnter, onClick)
    local f = Self("Icon")
        .setCallback("OnEnter", onEnter)
        .SetCallback("OnLeave", Self.TooltipHide)
        .SetCallback("OnClick", function (...)
            onClick(...)
            Self.TooltipHide()
        end)
        .AddTo(parent)
        .Show()()
    f.image:SetPoint("TOP")
    f.OnRelease = Self.ResetIcon

    return f
end

function Self.CreateItemIcon(parent, onClick)
    return Self.CreateIcon(parent, Self.TooltipItemLink, onClick)
end

-- Create an icon button
---@param parent Frame|Widget
---@param onClick function
---@param desc string
---@param width number
---@param height number
---@return Icon
function Self.CreateIconButton(icon, parent, onClick, desc, width, height)
    return Self(
        Self.CreateIcon(parent, Self.TooltipText, function (...)
            if desc then Addon:Debug("GUI.Click:IconButton", desc) end
            onClick(...)
        end)
    )
        .SetImage(icon:sub(1, 9) == "Interface" and icon or "Interface\\Buttons\\" .. icon .. "-Up")
        .SetImageSize(width or 16, height or 16)
        .SetHeight(16)
        .SetWidth(16)
        .SetUserData("text", desc)()
end

-- Arrange visible icon buttons
---@param xOff number
---@param yOff number
function Self.ArrangeIconButtons(parent, margin, xOff, yOff)
    margin = margin or 4
    local n, width, prev = 0, 0

    for i=#parent.children,1,-1 do
        local child = parent.children[i]
        if child:IsShown() then
            if not prev then
                child.frame:SetPoint("TOPRIGHT", xOff or 0, yOff or 0)
            else
                child.frame:SetPoint("TOPRIGHT", prev.frame, "TOPLEFT", -margin, 0)
            end
            n, prev, width = n + 1, child, width + child.frame:GetWidth()
        end
    end

    Self(parent).SetWidth(max(0, width + (n-1) * margin)).Show()
end

-- Display the given text as tooltip
---@param self Widget
function Self.TooltipText(self)
    local text = self:GetUserData("text")
    if text then
        GameTooltip:SetOwner(self.frame, "ANCHOR_TOP")
        GameTooltip:SetText(text)
        GameTooltip:Show()
    end
end

-- Display a regular unit tooltip
---@param self Widget
function Self.TooltipUnit(self)
    GameTooltip_SetDefaultAnchor(GameTooltip, UIParent)
    GameTooltip:SetUnit(self:GetUserData("unit"))
    GameTooltip:Show()
end

-- Display a tooltip showing only the full name of an x-realm player
---@param self Widget
function Self.TooltipUnitFullName(self)
    local unit = self:GetUserData("unit")
    if unit and Unit.Realm(unit) ~= Unit.RealmName() then
        local c = Unit.Color(unit)
        GameTooltip:SetOwner(self.frame, "ANCHOR_TOP")
        GameTooltip:SetText(Unit.FullName(unit), c.r, c.g, c.b, false)
        GameTooltip:Show()
    end
end

-- Display a tooltip for an item link
---@param self Widget
function Self.TooltipItemLink(self)
    local link = self:GetUserData("link")
    if link then
        GameTooltip:SetOwner(self.frame, self:GetUserData("anchor") or "ANCHOR_RIGHT")

        if Item.GetInfo(link, "itemType") == "battlepet" then
            BattlePetToolTip_ShowLink(link)
        else
            GameTooltip:SetHyperlink(link)
            GameTooltip:Show()
        end
    end
end

-- Display a tooltip for a chat button
---@param self Widget
function Self.TooltipChat(self)
    local chat = self:GetUserData("roll").chat
    local anchor = chat and self:GetUserData("anchor") or "TOP"
    local hint = not chat and not Addon.db.profile.messages.whisper.ask

    GameTooltip:SetOwner(self.frame, "ANCHOR_" .. anchor)
    GameTooltip:SetText(WHISPER .. (hint and " (" .. L["TIP_ENABLE_WHISPER_ASK"] .. ")" or ""))
    if chat then for i,line in ipairs(chat) do
        GameTooltip:AddLine(line, 1, 1, 1, true)
    end end
    GameTooltip:Show()
end

-- Hide the tooltip
function Self.TooltipHide()
    GameTooltip:Hide()
    BattlePetTooltip:Hide()
end

-- Handle clicks on unit labels
---@param self Widget
---@param event string
---@param button string
function Self.UnitClick(self, event, button)
    local unit = self:GetUserData("unit")
    Addon:Debug("GUI.Click:Unit", button, unit)

    if unit then
        if button == "LeftButton" then
            ChatFrame_SendTell(unit)
        elseif button == "RightButton" then
            -- local dropDown = Self.DROPDOWN_UNIT
            -- dropDown.which = Unit.IsSelf(unit) and "SELF" or UnitInRaid(unit) and "RAID_PLAYER" or UnitInParty(unit) and "PARTY" or "PLAYER"
            -- dropDown.unit = unit
            -- ToggleDropDownMenu(1, nil, dropDown, "cursor", 3, -3)
        end
    end
end

-- Handle clicks on chat buttons
---@param self Widget
---@param event string
---@param button string
function Self.ChatClick(self, event, button)
    Addon:Debug("GUI.Click:Chat", button)

    if button == "RightButton" and not Addon.db.profile.messages.whisper.ask then
        Options.Show("Messages")
    else
        Self.UnitClick(self, event, button)
    end
end

-- Award loot to or vote for unit
---@param self Widget
function Self.UnitAwardOrVote(self)
    ---@type Roll
    local roll = self:GetUserData("roll")
    local unit = self:GetUserData("unit")
    Addon:Debug("GUI.Click:AwardOrVote", roll and roll.id, unit)

    if roll:CanBeAwardedTo(unit, true) then
        roll:End(unit, true)
    elseif roll:UnitCanVote() then
        roll:Vote(roll.vote ~= unit and unit or nil)
    end
end

-- Handle clicks on item labels/icons
---@param self Widget
function Self.ItemClick(self)
    local link = self:GetUserData("link")
    Addon:Debug("GUI.Click:Item", link)

    if IsModifiedClick("DRESSUP") then
        return DressUpItemLink(link)
    elseif IsModifiedClick("CHATLINK") then
        return ChatEdit_InsertLink(link)
    end
end

-- Handle bidding on rolls through the UI
---@param roll Roll
---@param bid number
function Self.RollBid(roll, bid)
    if bid < Roll.BID_PASS and not roll:GetOwnerAddon() and not Addon.db.profile.messages.whisper.askPrompted then
        StaticPopup_Show(Self.DIALOG_ROLL_WHISPER_ASK, nil, nil, Util.Tbl.New(roll, bid))
    elseif roll:UnitCanBid("player", bid) then
        roll:Bid(bid, nil, nil, nil, IsShiftKeyDown())
    else
        roll:HideRollFrame()
    end
end

-- Get the color for a bid
function Self.RollBidColor(bid)
    if not bid then
        return 1, 1, 1
    elseif bid == Roll.BID_DISENCHANT then
        return .7, .26, .95
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

-- Reset an icon widget so it can be released
---@param self Icon
function Self.ResetIcon(self)
    self.frame:SetFrameStrata("MEDIUM")
    self.frame:RegisterForClicks("LeftButtonUp")
    self.image:SetPoint("TOP", 0, -5)
    self.OnRelease = nil
end

-- Reset a label widget so it can be released
---@param self Label
function Self.ResetLabel(self)
    self.label:SetPoint("TOPLEFT")
    self.frame:SetFrameStrata("MEDIUM")
    self.frame:SetScript("OnUpdate", nil)
    self.OnRelease = nil
end

---@return FrameWidget
function Self.ShowExportWindow(title, text)
    local f = Self("Frame").SetLayout("Fill").SetTitle(Name .. " - " .. title).Show()()
    Self("MultiLineEditBox").DisableButton(true).SetLabel().SetText(text).AddTo(f)
    return f
end

-- Add row-highlighting to a table
---@param parent Widget
---@param skip integer
function Self.TableRowHighlight(parent, skip)
    skip = skip or 0
    local isOver = false
    local tblObj = parent:GetUserData("table")
    local spaceV = tblObj.spaceV or tblObj.space or 0

    parent.frame:SetScript("OnEnter", function (self)
        if not isOver then
            self:SetScript("OnUpdate", function (self)
                if not MouseIsOver(self) then
                    isOver = false
                    self:SetScript("OnUpdate", nil)

                    if Self.HIGHLIGHT:GetParent() == self then
                        Self.HIGHLIGHT:SetParent(UIParent)
                        Self.HIGHLIGHT:Hide()
                    end
                else
                    local cY = select(2, GetCursorPosition()) / UIParent:GetEffectiveScale()
                    local frameTop, frameBottom = parent.frame:GetTop(), parent.frame:GetBottom()
                    local offset = parent.localstatus and parent.localstatus.offset or parent.status and parent.status.offset or 0
                    local top, bottom

                    for i=skip+1,#parent.children do
                        local childTop, childBottom = parent.children[i].frame:GetTop(), parent.children[i].frame:GetBottom()
                        if childTop and childBottom and childTop + spaceV/2 >= cY and childBottom - spaceV/2 <= cY then
                            top =  max(top or 0, childTop + spaceV/2)
                            bottom = min(bottom or math.huge, childBottom - spaceV/2)
                        end
                    end

                    if top and bottom then
                        Self(Self.HIGHLIGHT)
                            .ClearAllPoints()
                            .SetParent(self)
                            .SetPoint("LEFT")
                            .SetPoint("RIGHT")
                            .SetPoint("TOP", 0, top - frameTop - offset)
                            .SetHeight(top - bottom)
                            .Show()
                    else
                        Self.HIGHLIGHT:Hide()
                    end
                end
            end)
        end
        isOver = true
    end)

    local OnRelease = parent.OnRelease
    parent.OnRelease = function (self, ...)
        self.frame:SetScript("OnEnter", nil)
        self.frame:SetScript("OnUpdate", nil)
        self.OnRelease = OnRelease
        if self.OnRelease then self.OnRelease(self, ...) end
    end
end

-- Add row-backgrounds to a table
---@param parent Widget
---@param colors function|table
---@param skip integer
function Self.TableRowBackground(parent, colors, skip)
    local default = {1, 1, 1, 0.5}
    colors = colors or default
    skip = skip or 0
    local tblObj = parent:GetUserData("table")
    local spaceV = tblObj.spaceV or tblObj.space or 0
    local textures = {}

    local LayoutFinished = parent.LayoutFinished
    parent.LayoutFinished = function (self, ...)
        if LayoutFinished then LayoutFinished(self, ...) end

        Util.Tbl.Call(textures, "Hide")

        local frameTop, frameBottom = parent.frame:GetTop(), parent.frame:GetBottom()
        local offset = parent.localstatus and parent.localstatus.offset or parent.status and parent.status.offset or 0
        local cols, tex, row, top, bottom, last, child, childTop, childBottom, color = 0, 1

        for i=skip + 1, #parent.children + 1 do
            child = parent.children[i]
            last = i == #parent.children + 1

            if child then
                childTop, childBottom = child.frame:GetTop(), child.frame:GetBottom()
            end

            if row and last or child and child:IsShown() and childTop and childBottom then
                if row and (last or childTop < bottom) then
                    -- Determine color
                    if type(colors) == "function" then
                        color = colors(parent, row, cols, top - frameTop, top - bottom)
                    elseif type(colors) == "table" and type(colors[1]) ~= "number" then
                        color = colors[row % #colors]
                    else
                        color = colors
                    end

                    if color then
                        textures[tex] = textures[tex] or parent.content:CreateTexture(nil, "BACKGROUND")
                        Self(textures[tex])
                            .SetPoint("LEFT")
                            .SetPoint("RIGHT")
                            .SetPoint("TOP", 0, top - frameTop - offset)
                            .SetHeight(top - bottom)
                            .SetColorTexture(unpack(color == true and default or color))
                            .Show()
                        tex = tex + 1
                    end

                    row, cols, top, bottom = row + 1, 0
                end

                if not last then
                    row = row or 1
                    cols = cols + 1
                    top =  max(top or 0, childTop + spaceV/2)
                    bottom = min(bottom or math.huge, childBottom - spaceV/2)
                end
            end
        end
    end

    local OnRelease = parent.OnRelease
    parent.OnRelease = function (self, ...)
        Util.Tbl.Call(textures, "Hide")
        self.LayoutFinished = LayoutFinished
        self.OnRelease = OnRelease
        if self.OnRelease then self.OnRelease(self, ...) end
    end
end

-------------------------------------------------------
--               AceGUI table layout                 --
-------------------------------------------------------

-- Get alignment method and value. Possible alignment methods are a callback, a number, "start", "middle", "end", "fill" or "TOPLEFT", "BOTTOMRIGHT" etc.
local GetCellAlign = function (dir, tableObj, colObj, cellObj, cell, child)
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
local GetCellDimension = function (dir, laneDim, from, to, space)
    local dim = 0
    for cell=from,to do
        dim = dim + (laneDim[cell] or 0)
    end
    return dim + max(0, to - from) * (space or 0)
end

--[[ Options
============
Container:
 - columns ({col, col, ...}): Column settings. "col" can be a number (<= 0: content width, <1: rel. width, <10: weight, >=10: abs. width) or a table with column setting.
 - space, spaceH, spaceV: Overall, horizontal and vertical spacing between cells.
 - align, alignH, alignV: Overall, horizontal and vertical cell alignment. See GetCellAlign() for possible values.
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

                        laneH[col] = max(laneH[col], childH - GetCellDimension("H", laneH, colStart[child], col - 1, spaceH))
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
                local cellObj = child:GetUserData("cell")
                local offsetH = GetCellDimension("H", laneH, 1, colStart[child] - 1, spaceH) + (colStart[child] == 1 and 0 or spaceH)
                local cellH = GetCellDimension("H", laneH, colStart[child], col, spaceH)

                local f = child.frame
                f:ClearAllPoints()
                local childH = f:GetWidth() or 0

                local alignFn, align = GetCellAlign("H", tableObj, colObj, cellObj, cellH, childH)
                f:SetPoint("LEFT", content, offsetH + align, 0)
                if child:IsFullWidth() or alignFn == "fill" or childH > cellH then
                    f:SetPoint("RIGHT", content, "LEFT", offsetH + align + cellH, 0)
                end

                if child.DoLayout then
                    child:DoLayout()
                end

                rowV = max(rowV, (f:GetHeight() or 0) - GetCellDimension("V", laneV, rowStart[child], row - 1, spaceV))
            end
        end

        laneV[row] = rowV

        -- Vertical placement and sizing
        for col=1,#cols do
            local child = t[(row - 1) * #cols + col]
            if child then
                local colObj = cols[colStart[child]]
                local cellObj = child:GetUserData("cell")
                local offsetV = GetCellDimension("V", laneV, 1, rowStart[child] - 1, spaceV) + (rowStart[child] == 1 and 0 or spaceV)
                local cellV = GetCellDimension("V", laneV, rowStart[child], row, spaceV)

                local f = child.frame
                local childV = f:GetHeight() or 0

                local alignFn, align = GetCellAlign("V", tableObj, colObj, cellObj, cellV, childV)
                if child:IsFullHeight() or alignFn == "fill" then
                    f:SetHeight(cellV)
                end
                f:SetPoint("TOP", content, 0, -(offsetV + align))
            end
        end
    end

    -- Calculate total width and height
    local totalH = GetCellDimension("H", laneH, 1, #laneH, spaceH)
    local totalV = GetCellDimension("V", laneV, 1, #laneV, spaceV)

    -- Cleanup
    for _,v in pairs(layoutCache) do wipe(v) end

    Util.Safecall(obj.LayoutFinished, obj, totalH, totalV)
    obj:ResumeLayout()
end)

-- Enable chain-calling
Self.C = {f = nil, k = nil}
local Fn = function (...)
    local c, k, f = Self.C, rawget(Self.C, "k"), rawget(Self.C, "f")
    if k == "AddTo" then
        local parent, beforeWidget = ...
        if parent.type == "Dropdown-Pullout" then
            parent:AddItem(f)
        elseif not parent.children or beforeWidget == false then
            (f.frame or f):SetParent(parent.frame or parent)
        else
            parent:AddChild(f, beforeWidget)
        end
    else
        if k == "Toggle" then
            k = (...) and "Show" or "Hide"
        end

        local obj = f[k] and f
            or f.frame and f.frame[k] and f.frame
            or f.image and f.image[k] and f.image
            or f.label and f.label[k] and f.label
            or f.content and f.content[k] and f.content

        obj[k](obj, ...)

        -- Fix Label's stupid image anchoring
        if Util.In(obj.type, "Label", "InteractiveLabel") and Util.In(k, "SetText", "SetFont", "SetFontObject", "SetImage") then
            local strWidth, imgWidth = obj.label:GetStringWidth(), obj.imageshown and obj.image:GetWidth() or 0
            local width = Util.Num.Round(strWidth + imgWidth + (min(strWidth, imgWidth) > 0 and 4 or 0), 1)
            obj:SetWidth(width)
        end
    end
    return c
end
setmetatable(Self.C, {
    __index = function (c, k)
        c.k = Util.Str.UcFirst(k)
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