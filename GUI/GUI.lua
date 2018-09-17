local Name, Addon = ...
local L = LibStub("AceLocale-3.0"):GetLocale(Name)
local AceGUI = LibStub("AceGUI-3.0")
local Comm, Inspect, Item, Options, Session, Roll, Trade, Unit, Util = Addon.Comm, Addon.Inspect, Addon.Item, Addon.Options, Addon.Session, Addon.Roll, Addon.Trade, Addon.Unit, Addon.Util
local Self = Addon.GUI

Self.Rolls = {}
Self.Actions = {}

-- Row highlight frame
Self.HIGHLIGHT = CreateFrame("Frame", nil, UIParent)
Self.HIGHLIGHT:SetFrameStrata("BACKGROUND")
Self.HIGHLIGHT:Hide()
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

Self.DIALOG_OPT_MASTERLOOT_LOAD = "PLR_OPT_MASTERLOOT_LOAD"
StaticPopupDialogs[Self.DIALOG_OPT_MASTERLOOT_LOAD] = {
    text = L["DIALOG_OPT_MASTERLOOT_LOAD"],
    button1 = YES,
    button2 = NO,
    OnAccept = function () Options.ImportRules() end,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3
}

Self.DIALOG_OPT_MASTERLOOT_SAVE = "PLR_OPT_MASTERLOOT_SAVE"
StaticPopupDialogs[Self.DIALOG_OPT_MASTERLOOT_SAVE] = {
    text = L["DIALOG_OPT_MASTERLOOT_SAVE"],
    button1 = YES,
    button2 = NO,
    OnAccept = function () Options.ExportRules() end,
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
--                     Dropdowns                     --
-------------------------------------------------------

-- Masterloot
function Self.ToggleMasterlootDropdown(...)
    local dropdown = Self.dropdownMasterloot
    if not dropdown then
        dropdown = Self("Dropdown-Pullout").Hide()()
        Self("Dropdown-Item-Execute")
            .SetText(L["MENU_MASTERLOOT_START"])
            .SetCallback("OnClick", function () Session.SetMasterlooter("player") end)
            .AddTo(dropdown)
        Self("Dropdown-Item-Execute")
            .SetText(L["MENU_MASTERLOOT_SEARCH"])
            .SetCallback("OnClick", function () Session.SendRequest() end)
            .AddTo(dropdown)
        Self("Dropdown-Item-Execute")
            .SetText(CLOSE)
            .SetCallback("OnClick", function () dropdown:Close() end)
            .AddTo(dropdown)
        Self.dropdownMasterloot = dropdown
    end

    if not dropdown:IsShown() then dropdown:Open(...) else dropdown:Close() end
end

-- Custom bid answers
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
                .SetCallback("OnClick", function () roll:Bid(bid + i/10) end)
                .AddTo(dropdown)
        end
    end

    if not dropdown:IsShown() then dropdown:Open(...) else dropdown:Close() end
end

-- Award loot
function Self.ToggleAwardOrVoteDropdown(roll, ...)
    local dropdown = Self.dropdownAwardOrVote
    if not dropdown then
        dropdown = AceGUI:Create("Dropdown-Pullout")
        Self.dropdownAwardOrVote = dropdown
    end

    if not dropdown:IsShown() or roll ~= dropdown:GetUserData("roll") then
        Self(dropdown).Clear().SetUserData("roll", roll)

        local players = Self.GetRollEligibleList(roll)
        local width = 0

        for i,player in pairs(players) do
            local f = Self("Dropdown-Item-Execute")
                .SetText(("%s: |c%s%s|r (%s: %s, %s: %s)"):format(
                    Unit.ColoredShortenedName(player.unit),
                    Util.StrColor(Self.GetBidColor(player.bid)), roll:GetBidName(player.bid),
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
            .SetText(CLOSE)
            .SetCallback("OnClick", function () dropdown:Close() end)
            .AddTo(dropdown)

        dropdown.frame:SetWidth(max(200, width + 32 + dropdown:GetLeftBorderWidth() + dropdown:GetRightBorderWidth()))

        Util.TblRelease(1, players)
        dropdown:Open(...)
    else
        dropdown:Close()
    end
end

-- Award loot to unit
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
            .SetText(CLOSE)
            .SetCallback("OnClick", function () dropdown:Close() end)
            .AddTo(dropdown)
    end

    if not dropdown:IsShown() then dropdown:Open(...) else dropdown:Close() end
end

-------------------------------------------------------
--                      Helper                       --
-------------------------------------------------------

function Self.GetRollEligibleList(roll)
    return Util(roll.item:GetEligible()).Copy().Merge(roll.bids).Map(function (val, unit)
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
end

function Self.ReverseAnchor(anchor)
    return anchor:gsub("TOP", "B-OTTOM"):gsub("BOTTOM", "T-OP"):gsub("LEFT", "R-IGHT"):gsub("RIGHT", "L-EFT"):gsub("-", "")
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

-- Create an interactive label for an item, with tooltip and click support
function Self.CreateItemLabel(parent, anchor)
    local f = Self("InteractiveLabel")
        .SetFontObject(GameFontNormal)
        .SetCallback("OnEnter", Self.TooltipItemLink)
        .SetCallback("OnLeave", Self.TooltipHide)
        .SetCallback("OnClick", Self.ItemClick)
        .AddTo(parent)()

    -- Fix the stupid label anchors
    local methods = Util.TblCopySelect(f, "OnWidthSet", "SetText", "SetImage", "SetImageSize")
    for name,fn in pairs(methods) do
        f[name] = function (self, ...)
            fn(self, ...)

            if self.imageshown then
                local width, imagewidth = self.frame.width or self.frame:GetWidth() or 0, self.image:GetWidth()
                
                self.label:ClearAllPoints()
                self.image:ClearAllPoints()
                
                self.image:SetPoint("TOPLEFT")
                if self.image:GetHeight() > self.label:GetHeight() then
                    self.label:SetPoint("LEFT", self.image, "RIGHT", 4, 0)
                else
                    self.label:SetPoint("TOPLEFT", self.image, "TOPRIGHT", 4, 0)
                end
                self.label:SetWidth(width - imagewidth - 4)
                
                local height = max(self.image:GetHeight(), self.label:GetHeight())
                self.resizing = true
                self.frame:SetHeight(height)
                self.frame:SetWidth(Util.NumRound(self.frame:GetWidth()), 1)
                self.frame.height = height
                self.resizing = nil
            end
        end
    end
    f.OnRelease = function (self)
        for name,fn in pairs(methods) do f[name] = fn end
        Util.TblRelease(methods)
        f.OnRelease = nil
    end

    return f
end

-- Create an icon button
function Self.CreateIconButton(icon, parent, onClick, desc, width, height)
    f = Self("Icon")
        .SetImage(icon:sub(1, 9) == "Interface" and icon or "Interface\\Buttons\\" .. icon .. "-Up")
        .SetImageSize(width or 16, height or 16).SetHeight(16).SetWidth(16)
        .SetCallback("OnClick", function (...) onClick(...) GameTooltip:Hide() end)
        .SetCallback("OnEnter", Self.TooltipText)
        .SetCallback("OnLeave", Self.TooltipHide)
        .SetUserData("text", desc)
        .AddTo(parent)
        .Show()()
    f.image:SetPoint("TOP")
    f.OnRelease = Self.ResetIcon

    return f
end

-- Arrange visible icon buttons
function Self.ArrangeIconButtons(parent, margin)
    margin = margin or 4
    local n, width, prev = 0, 0

    for i=#parent.children,1,-1 do
        local child = parent.children[i]
        if child:IsShown() then
            if not prev then
                child.frame:SetPoint("TOPRIGHT")
            else
                child.frame:SetPoint("TOPRIGHT", prev.frame, "TOPLEFT", -margin, 0)
            end
            n, prev, width = n + 1, child, width + child.frame:GetWidth()
        end
    end

    Self(parent).SetWidth(max(0, width + (n-1) * margin)).Show()
end

-- Display the given text as tooltip
function Self.TooltipText(self)
    local text = self:GetUserData("text")
    if text then
        GameTooltip:SetOwner(self.frame, "ANCHOR_TOP")
        GameTooltip:SetText(text)
        GameTooltip:Show()
    end
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
    if unit and Unit.Realm(unit) ~= Unit.RealmName() then
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
        GameTooltip:SetOwner(self.frame, self:GetUserData("anchor") or "ANCHOR_RIGHT")
        GameTooltip:SetHyperlink(link)
        GameTooltip:Show()
    end
end

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
end

-- Handle clicks on unit labels
function Self.UnitClick(self, event, button)
    local unit = self:GetUserData("unit")
    if unit then
        if button == "LeftButton" then
            ChatFrame_SendSmartTell(unit)
        elseif button == "RightButton" then
            -- local dropDown = Self.DROPDOWN_UNIT
            -- dropDown.which = Unit.IsSelf(unit) and "SELF" or UnitInRaid(unit) and "RAID_PLAYER" or UnitInParty(unit) and "PARTY" or "PLAYER"
            -- dropDown.unit = unit
            -- ToggleDropDownMenu(1, nil, dropDown, "cursor", 3, -3)
        end
    end
end

function Self.ChatClick(self, event, button)
    if button == "RightButton" and not Addon.db.profile.messages.whisper.ask then
        Options.Show("Messages")
    else
        Self.UnitClick(self, event, button)
    end
end

-- Award loot to or vote for unit
function Self.UnitAwardOrVote(self)
    local roll, unit = self:GetUserData("roll"), self:GetUserData("unit")
    if roll:CanBeAwardedTo(unit, true) then
        roll:End(unit, true)
    elseif roll:UnitCanVote() then
        roll:Vote(roll.vote ~= unit and unit or nil)
    end
end

-- Handle clicks on item labels/icons
function Self.ItemClick(self)
    if IsModifiedClick("DRESSUP") then
        return DressUpItemLink(self:GetUserData("link"))
    elseif IsModifiedClick("CHATLINK") then
        return ChatEdit_InsertLink(self:GetUserData("link"))
    end
end

-- Get the color for a bid
function Self.GetBidColor(bid, hex)
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

function Self.ResetIcon(self)
    self.image:SetPoint("TOP", 0, -5)
    self.frame:SetFrameStrata("MEDIUM")
    self.frame:RegisterForClicks("LeftButtonUp")
    self.OnRelease = nil
end

function Self.ResetLabel(self)
    self.label:SetPoint("TOPLEFT")
    self.frame:SetFrameStrata("MEDIUM")
    self.frame:SetScript("OnUpdate", nil)
    self.OnRelease = nil
end

function Self.ShowExportWindow(title, text)
    local f = Self("Frame").SetLayout("Fill").SetTitle(Name .. " - " .. title).Show()()
    Self("MultiLineEditBox").DisableButton(true).SetLabel().SetText(text).AddTo(f)
    return f
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
                    
                    if Self.HIGHLIGHT:GetParent() == self then
                        Self.HIGHLIGHT:SetParent(UIParent)
                        Self.HIGHLIGHT:Hide()
                    end
                else
                    local cY = select(2, GetCursorPosition()) / UIParent:GetEffectiveScale()
                    local frameTop, frameBottom = parent.frame:GetTop(), parent.frame:GetBottom()
                    local row, top, bottom

                    for i=skip+1,#parent.children do
                        local childTop, childBottom = parent.children[i].frame:GetTop(), parent.children[i].frame:GetBottom()
                        if childTop and childBottom and childTop + spaceV/2 >= cY and childBottom - spaceV/2 <= cY then
                            top =  min(frameTop, max(top or 0, childTop + spaceV/2))
                            bottom = max(frameBottom, min(bottom or frameTop, childBottom - spaceV/2))
                        end
                    end
                    
                    if top and bottom then
                        Self(Self.HIGHLIGHT)
                            .SetParent(self)
                            .SetPoint("LEFT").SetPoint("RIGHT")
                            .SetPoint("TOP", 0, top - frameTop)
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
                if not child.GetUserData then Util.Dump(row, col, (row - 1) * #cols + col, child) end
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
        obj[k](obj, ...)

        -- Fix Label's stupid image anchoring
        if Util.In(obj.type, "Label", "InteractiveLabel") and Util.In(k, "SetText", "SetFont", "SetFontObject", "SetImage") then
            local strWidth, imgWidth = obj.label:GetStringWidth(), obj.imageshown and obj.image:GetWidth() or 0
            local width = Util.NumRound(strWidth + imgWidth + (min(strWidth, imgWidth) > 0 and 4 or 0), 1)
            obj:SetWidth(width)
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