local Addon = LibStub("AceAddon-3.0"):GetAddon(PLR_NAME)
local L = LibStub("AceLocale-3.0"):GetLocale(PLR_NAME)
local AceGUI = LibStub("AceGUI-3.0")
local Util = Addon.Util
local Roll = Addon.Roll
local Trade = Addon.Trade
local Comm = Addon.Comm
local Inspect = Addon.Inspect
local Self = {}

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
    filter = {all = false, canceled = false, done = true, won = true, traded = false}
}

-- Show the rolls frame
function Rolls.Show()
    if Rolls.frames.window then
        Rolls.frames.window.frame:Show()
    else
        -- WINDOW

        Rolls.frames.window = Self("Window"):SetLayout(nil):SetTitle("PersoLootRoll - " .. L["ROLLS"])
            :SetCallback("OnClose", function (self)
                self.optionsbutton:Release()
                self.optionsbutton = nil
                self:Release()
                wipe(Rolls.frames)
            end)
            :SetMinResize(600, 120)()

        do
            local window = Rolls.frames.window

            -- Options button
            f = Self("Icon"):SetImage("Interface\\Buttons\\UI-OptionsButton")
                :SetImageSize(14, 14):SetHeight(16):SetWidth(16)
                :SetCallback("OnClick", function (self)
                    Addon:ShowOptions()
                    GameTooltip:Hide()
                end)
                :SetCallback("OnEnter", function (self)
                    GameTooltip:SetOwner(self.frame, "ANCHOR_TOP")
                    GameTooltip:SetText(OPTIONS, 1, 1, 1, 1)
                    GameTooltip:Show()
                end)
                :SetCallback("OnLeave", function () GameTooltip:Hide() end)()
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

        Rolls.frames.filter = Self("SimpleGroup"):SetLayout(nil)
            :AddTo(Rolls.frames.window)
            :SetPoint("BOTTOMLEFT", 0, 0)
            :SetPoint("BOTTOMRIGHT", -25, 0)
            :SetHeight(24)()
        
        do
            f = Self("Label"):SetFontObject(GameFontNormal):SetText(L["FILTER"] .. ":")
                :AddTo(Rolls.frames.filter)
                :SetPoint("TOPLEFT")()
            f:SetWidth(f.label:GetStringWidth() + 30)
            f.label:SetPoint("TOPLEFT", 15, -6)

            for _,key in ipairs({"all", "done", "won", "traded", "canceled"}) do
                Self.CreateFilterCheckbox(key)
            end

            f = Self("InteractiveLabel"):SetFontObject(GameFontNormal):SetText()
                :AddTo(Rolls.frames.filter)
                :SetPoint("TOPRIGHT")
                :SetPoint("BOTTOMRIGHT")()
        end

        -- SCROLL

        Rolls.frames.scroll = Self("ScrollFrame"):SetLayout("PLR_Table")
            :SetUserData("table", {
                columns = {20, 1, 30, 75, 75, 50, 50, 75, 20 * 5 - 4},
                space = 10
            })
            :AddTo(Rolls.frames.window)
            :SetPoint("TOPRIGHT")
            :SetPoint("BOTTOMLEFT", Rolls.frames.filter.frame, "TOPLEFT", 0, 8)()

        do
            local scroll = Rolls.frames.scroll

            local header = {"ID", "ITEM", "LEVEL", "OWNER", "LOOTMASTER", "STATUS", "YOUR_BID", "WINNER"}
            for i,v in pairs(header) do
                Self("Label"):SetText(Util.StrUcFirst(L[v])):SetFontObject(GameFontNormal):SetColor(1, 0.82, 0):AddTo(scroll)
            end

            local actions = Self("SimpleGroup"):SetLayout(nil)
                :SetHeight(16)
                :SetWidth(17)
                :SetUserData("cell", {alignH = "end"})
                :AddTo(scroll)()
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
function Rolls.Update()
    if not Rolls.frames.window then return end
    local f

    -- SCROLL

    local scroll = Rolls.frames.scroll
    scroll:PauseLayout()

    local player = UnitName("player")
    local rolls = Util(Addon.rolls).Filter(function (roll)
        return (Rolls.filter.all or roll.isOwner or roll.item.isOwner or roll.item:GetEligible(player))
           and (Rolls.filter.canceled or roll.status ~= Roll.STATUS_CANCELED)
           and (Rolls.filter.done or (roll.status ~= Roll.STATUS_DONE))
           and (Rolls.filter.won or not roll.winner)
           and (Rolls.filter.traded or not roll.traded)
    end).Values().SortBy("id")()

    Self.UpdateRows(scroll, rolls, function (scroll, roll, first)
        -- ID
        Self("Label"):SetFontObject(GameFontNormal):AddTo(scroll, first)

        -- Item
        Self("InteractiveLabel"):SetWidth(216):SetFontObject(GameFontNormal):SetCallback("OnLeave", function ()
            GameTooltip:Hide()
        end):AddTo(scroll, first)
        
        -- Ilvl
        Self("Label"):SetFontObject(GameFontNormal):AddTo(scroll, first)

        -- Owner, Masterlooter
        Self("InteractiveLabel"):SetFontObject(GameFontNormal):AddTo(scroll, first)
        Self("InteractiveLabel"):SetFontObject(GameFontNormal):AddTo(scroll, first)

        -- Status, Your bid
        Self("Label"):SetFontObject(GameFontNormal):AddTo(scroll, first)
        Self("Label"):SetFontObject(GameFontNormal):AddTo(scroll, first)

        -- Winner
        Self("InteractiveLabel"):SetFontObject(GameFontNormal):AddTo(scroll, first)

        -- Actions
        f = Self("SimpleGroup"):SetLayout(nil)
            :SetHeight(16)
            :SetUserData("cell", {alignH = "end"})
            :AddTo(scroll, first)()
        local backdrop = {f.frame:GetBackdropColor()}
        f.frame:SetBackdropColor(0, 0, 0, 0)
        f.OnRelease = function (self)
            self.frame:SetBackdropColor(unpack(backdrop))
            self.OnRelease = nil
        end

        -- Details
        local details = Self("SimpleGroup"):SetLayout("PLR_Table")
            :SetFullWidth(true)
            :SetUserData("isDetails", true)
            :SetUserData("cell", {
                colspan = 99
            })
            :SetUserData("table", {
                columns = {1, 75, 75, 100},
                space = 2
            })
            :AddTo(scroll, first)()

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
        
            local header = {"PLAYER", "ITEM_LEVEL", "BID"}
            for i,v in pairs(header) do
                local f = Self("Label"):SetText(Util.StrUcFirst(L[v])):SetFontObject(GameFontNormal):SetColor(1, 0.82, 0)()
                if i == #header then
                    f:SetUserData("cell", {colspan = 2})
                end
                details:AddChild(f)
            end

            details.frame:Hide()
        end
    end, function (scroll, roll, children, it)
        -- ID
        children[it(0)]:SetText(roll.id)

        -- Item
        Self(children[it()]):SetText(roll.item.link):SetImage(roll.item.texture)
            :SetCallback("OnEnter", function (self)
                GameTooltip:SetOwner(self.frame, "ANCHOR_LEFT")
                GameTooltip:SetHyperlink(roll.item.link)
                GameTooltip:Show()
            end)
            :SetCallback("OnLeave", function () GameTooltip:Hide() end)
            :SetCallback("OnClick", function (self)
                if IsModifiedClick("DRESSUP") then
                    DressUpItemLink(roll.item.link)
                elseif IsModifiedClick("CHATLINK") then
                    ChatEdit_InsertLink(roll.item.link)
                end
            end)

        -- Ilvl
        children[it()]:SetText(roll.item:GetBasicInfo().level or "-")

        -- Owner
        Self(children[it()])
            :SetText(Util.GetColoredName(Util.GetShortenedName(roll.item.owner), roll.item.owner))
            :SetCallback("OnEnter", function (self)
                GameTooltip_SetDefaultAnchor(GameTooltip, UIParent)
                GameTooltip:SetUnit(roll.item.owner)
                GameTooltip:Show()
            end)
            :SetCallback("OnLeave", function () GameTooltip:Hide() end)
            :SetCallback("OnClick", function () ChatFrame_SendSmartTell(roll.item.owner) end)

        -- Masterlooter
        local ml = children[it()]
        if roll.owner ~= roll.item.owner then
            Self(ml)
                :SetText(Util.GetColoredName(Util.GetShortenedName(roll.owner), roll.owner))
                :SetCallback("OnEnter", function (self)
                    GameTooltip_SetDefaultAnchor(GameTooltip, UIParent)
                    GameTooltip:SetUnit(roll.owner)
                    GameTooltip:Show()
                end)
                :SetCallback("OnLeave", function () GameTooltip:Hide() end)
                :SetCallback("OnClick", function () ChatFrame_SendSmartTell(roll.owner) end)
        else
            Self(ml):SetText("-"):SetCallback("OnEnter", Util.FnNoop):SetCallback("OnLeave", Util.FnNoop):SetCallback("OnClick", Util.FnNoop)
        end

        -- Status
        children[it()]:SetText(roll.traded and L["TRADED"] or L["ROLL_STATUS_" .. roll.status])

        -- Your Bid
        children[it()]:SetText(roll.answer and L["ROLL_ANSWER_" .. roll.answer] or "-")

        -- Winner
        Self(children[it()])
            :SetText(roll.winner and Util.GetColoredName(Util.GetShortenedName(roll.winner), roll.winner) or "-")
            :SetCallback("OnEnter", function (self)
                if roll.winner then
                    GameTooltip_SetDefaultAnchor(GameTooltip, UIParent)
                    GameTooltip:SetUnit(roll.winner)
                    GameTooltip:Show()
                end
            end)
            :SetCallback("OnLeave", function () GameTooltip:Hide() end)
            :SetCallback("OnClick", function () if roll.winner then ChatFrame_SendSmartTell(roll.winner) end end)

        -- Actions
        do
            local actions = children[it()]
            actions:ReleaseChildren()

            if roll:CanBeWonBy(UnitName("player")) and not roll:UnitHasBid(UnitName("player")) then
                -- Need
                f = Self.CreateIconButton("UI-GroupLoot-Dice", actions, function ()
                    roll:Bid(Roll.ANSWER_NEED)
                end, NEED)
                Self(f):SetImageSize(14, 14):SetWidth(16):SetHeight(16)

                -- Greed
                if roll.ownerId then
                    Self.CreateIconButton("UI-GroupLoot-Coin", actions, function ()
                        roll:Bid(Roll.ANSWER_GREED)
                    end, GREED)
                end

                -- Pass
                f = Self.CreateIconButton("UI-GroupLoot-Pass", actions, function ()
                    roll:Bid(Roll.ANSWER_PASS)
                end, PASS)
                Self(f):SetImageSize(13, 13):SetWidth(16):SetHeight(16)
            end

            -- Advertise
            if roll:CanBeAwarded() and not roll.posted then
                f = Self.CreateIconButton("UI-GuildButton-MOTD", actions, function ()
                    roll:Advertise()
                end, L["ADVERTISE"])
                Self(f):SetImageSize(13, 13):SetWidth(16):SetHeight(16)
            end

            -- Trade
            if not roll.traded and roll.winner and (roll.item.isOwner or roll.isWinner) then
                f = Self.CreateIconButton("Interface\\GossipFrame\\VendorGossipIcon", actions, function ()
                    roll:Trade()
                end, TRADE)
                Self(f):SetImageSize(13, 13):SetWidth(16):SetHeight(16)
            end

            -- Cancel
            if roll:CanBeAwarded() then
                f = Self.CreateIconButton("CancelButton", actions, function ()
                    local dialog = StaticPopup_Show(Self.DIALOG_ROLL_CANCEL)
                    if dialog then
                        dialog.data = roll
                    end
                end, CANCEL)
                f.image:SetTexCoord(0.22, 0.78, 0.22, 0.78)
            end

            -- Toggle
            local details = children[it(0) + 1]
            f = Self.CreateIconButton("UI-" .. (details:IsShown() and "Minus" or "Plus") .. "Button", actions, function (self)
                if details:IsShown() then
                    details.frame:Hide()
                    self:SetImage("Interface\\Buttons\\UI-PlusButton-Up")
                else
                    Rolls.UpdateDetails(details, roll)
                    self:SetImage("Interface\\Buttons\\UI-MinusButton-Up")
                end
                scroll:DoLayout()
            end)
            f.image:SetPoint("TOP", 0, 2)

            for i=#actions.children,1,-1 do
                if i == #actions.children then
                    actions.children[i].frame:SetPoint("TOPRIGHT")
                else
                    actions.children[i].frame:SetPoint("TOPRIGHT", actions.children[i+1].frame, "TOPLEFT", -4, 0)
                end
            end
            actions.frame:SetWidth(max(0, 20 * #actions.children - 4))
        end

        -- Details
        local details = children[it()]
        if details:IsShown() then
            Rolls.UpdateDetails(details, roll)
        end
    end)

    scroll:ResumeLayout()
    scroll:DoLayout()

    -- FILTER

    local filter = Rolls.frames.filter

    it = Util.Iter(1)
    filter.children[it()]:SetValue(Rolls.filter.all)
    filter.children[it()]:SetValue(Rolls.filter.done)
    filter.children[it()]:SetValue(Rolls.filter.won)
    filter.children[it()]:SetValue(Rolls.filter.traded)
    filter.children[it()]:SetValue(Rolls.filter.canceled)

    local unit = Util.GetName(Addon.masterlooter)
    local ml = Self(filter.children[it()]):SetText(unit and L["ML"] .. ": " .. Util.GetColoredName(Util.GetShortenedName(unit)) or "")
        :SetCallback("OnEnter", function (self)
            if unit then
                GameTooltip_SetDefaultAnchor(GameTooltip, UIParent)
                GameTooltip:SetUnit(unit)
                GameTooltip:Show()
            end
        end)
        :SetCallback("OnLeave", function () GameTooltip:Hide() end)
        :SetCallback("OnClick", function () if unit then ChatFrame_SendSmartTell(unit) end end)()
    ml:SetWidth(ml.label:GetStringWidth() + 30)
    ml.label:ClearAllPoints()
    ml.label:SetPoint("TOPLEFT", 15, -6)
    ml.label:SetPoint("TOPRIGHT", -15, -6)
end

-- Hide the rolls frame
function Rolls.Hide()
    if Rolls.frames.window then
        Rolls.frames.window.frame:Hide()
    end
end

-- Update the details view of a row
function Rolls.UpdateDetails(self, roll)
    self.frame:Show()
    self:PauseLayout()

    local players = Util({}).Merge(roll.item:GetEligible(true), roll:GetBids()).Map(function (val, unit)
        return {unit = unit, bid = type(val) == "number" and val or nil, ilvl = roll.item:GetLevelForLocation(unit)}
    end).Values().SortBy("bid", 99, "ilvl", 0, "unit")()
    local canBeAwarded = roll:CanBeAwarded(true)

    Self.UpdateRows(self, players, function (self, player, first)
        -- Unit
        Self("InteractiveLabel"):SetFontObject(GameFontNormal):AddTo(self, first)

        -- Ilvl, Bid
        Self("Label"):SetFontObject(GameFontNormal):AddTo(self, first)
        Self("Label"):SetFontObject(GameFontNormal):AddTo(self, first)

        -- Actions
        local f = Self("Button"):SetWidth(100):SetCallback("OnClick", function (self)
            if roll:CanBeAwardedTo(player.unit, true) then
                roll:Finish(player.unit)
            end
        end)()
        f.text:SetFont(GameFontNormal:GetFont())
        self:AddChild(f)
    end, function (self, player, children, it)
        -- Unit
        Self(children[it(0)])
            :SetText(Util.GetColoredName(Util.GetShortenedName(player.unit), player.unit))
            :SetCallback("OnEnter", function (self)
                GameTooltip_SetDefaultAnchor(GameTooltip, UIParent)
                GameTooltip:SetUnit(player.unit)
                GameTooltip:Show()
            end)
            :SetCallback("OnLeave", function () GameTooltip:Hide() end)
            :SetCallback("OnClick", function () ChatFrame_SendSmartTell(player.unit) end)

        -- Ilvl
        children[it()]:SetText(player.ilvl)

        -- Bid
        children[it()]:SetText(player.bid and L["ROLL_ANSWER_" .. player.bid] or "-")

        -- Actions
        Self(children[it()]):SetText(canBeAwarded and L["AWARD"] or "-"):SetDisabled(not canBeAwarded)
    end, "unit")

    self:ResumeLayout()
end

Self.Rolls = Rolls

-------------------------------------------------------
--               AceGUI table layout                 --
-------------------------------------------------------

-- Get alignment method and value. Possible alignment methods are a callback, a number, "start", "middle", "end", "fill" or "TOPLEFT", "BOTTOMRIGHT" etc.
local GetAlign = function (dir, cellObj, colObj, tableObj, cell, total)
    local fn = cellObj["align" .. dir] or cellObj.align or colObj["align" .. dir] or colObj.align or tableObj["align" .. dir] or tableObj.align or "CENTERLEFT"
    local cell, total, val = cell or 0, total or 0, nil

    if type(fn) == "string" then
        fn = fn:lower()
        fn = dir == "V" and (fn:sub(1, 3) == "top" and "start" or fn:sub(1, 6) == "bottom" and "end" or fn:sub(1, 6) == "center" and "middle")
          or dir == "H" and (fn:sub(-4) == "left" and "start" or fn:sub(-5) == "right" and "end" or fn:sub(-6) == "center" and "middle")
          or fn
        val = (fn == "start" or fn == "fill") and 0 or fn == "end" and total - cell or (total - cell) / 2
    elseif type(fn) == "function" then
        val = fn(cell or 0, total, dir)
    else
        val = fn
    end

    return fn, max(0, min(val, total))
end

-- Get the width for a column, based on abs. width, rel. width or weight.
local GetWidth = function (col, scale, total)
    return col.width and col.width < 1 and col.width * total or col.width or (col.weight or 1) * scale
end

--[[ Options
============
Container:
 - columns ({col, col, ...}): Column settings. "col" can be a number (<1: rel. width, <10: weight, >=10: abs. width) or a table with column setting.
 - space, spaceH, spaceV: Overall, horizontal and vertical spacing between cells.
 - align, alignH, alignV: Overall, horizontal and vertical cell alignment. See GetAlign() for possible values.
Columns:
 - width: Fixed column width. <1: rel. width, >=1: abs. width.
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

    local tableObj = obj:GetUserData("table") or {}
    local cols = tableObj.columns
    local spaceH = tableObj.spaceH or tableObj.space or 0
    local spaceV = tableObj.spaceV or tableObj.space or 0
    local totalH = (content:GetWidth() or content.width or 0) - spaceH * (#cols - 1)
    local rowspans = {}

    -- Determine fixed size cols, collect weights and calculate scale
    local extantH, weight = totalH, 0
    for i, col in ipairs(cols) do
        if type(col) == "number" then
            col = {[col >= 1 and col < 10 and "weight" or "width"] = col}
            cols[i] = col
        end

        if col.width then
            extantH = max(0, extantH - GetWidth(col, 1, totalH))
        else
            weight = weight + (col.weight or 1)
        end
    end
    local scale = weight > 0 and extantH / weight or 0

    -- Arrange children
    local n, offsetH, offsetV, rowV = 1, 0, 0, 0
    local slotFound, col, row, rowStart, rowEnd, lastRow, cell, cellH, cellV, cellOffsetV, childH, f, alignFn, align, colspan, rowspan, j
    for i, child in ipairs(children) do
        if child:IsShown() then
            repeat
                col = (n - 1) % #cols + 1
                row = ceil(n / #cols)
                colObj = cols[col]
                cellH = GetWidth(colObj, scale, totalH)

                -- First column of a row -> Update/reset variables
                if col == 1 then
                    rowStart = i
                    offsetH, offsetV, rowV = 0, offsetV + rowV + spaceV, 0
                end

                rowspan = rowspans[col]
                cell = rowspan and rowspan.cell or child
                cellObj = cell:GetUserData("cell") or {}

                -- Handle colspan
                colspan = max(0, min((cellObj.colspan or 1) - 1, #cols - col))
                for j=col+1, col+colspan do
                    cellH = cellH + spaceH + GetWidth(cols[j], scale, totalH)
                end
                n = n + colspan + 1

                -- Set width and left anchor
                slotFound = not rowspan
                lastRow = slotFound and i == #children
                if slotFound then
                    f = cell.frame
                    f:ClearAllPoints()

                    childH = f:GetWidth() or 0
                    alignFn, align = GetAlign("H", cellObj, colObj, tableObj, childH, cellH)
                    f:SetPoint("LEFT", content, offsetH + align, 0)
                    if cell:IsFullWidth() or alignFn == "fill" or childH > cellH then
                        f:SetPoint("RIGHT", content, "LEFT", offsetH + align + cellH, 0)
                    end
                    
                    if cell.DoLayout then
                        cell:DoLayout()
                    end

                    if cellObj.rowspan then
                        rowspans[col] = {cell = cell, span = cellObj.rowspan - 1, height = 0}
                    else
                        rowV = max(rowV, f:GetHeight() or 0)
                    end
                -- Or decrement rowspan counter and update total height
                else
                    rowspan.span = rowspan.span - 1
                    if lastRow or rowspan.span == 0 then
                        rowV = max(rowV, (cell.frame:GetHeight() or 0) - rowspan.height)
                    end
                end

                offsetH = offsetH + cellH + spaceH

                -- Last column of a row -> Set top anchors
                if col+colspan == #cols or lastRow then
                    j, col, rowEnd = rowStart, 1, col
                    while col <= rowEnd do
                        rowspan = rowspans[col]
                        cell = rowspan and rowspan.cell or children[j]

                        if cell:IsShown() then
                            cellV, cellOffsetV, cellObj =  rowV, offsetV, cell:GetUserData("cell") or {}

                            -- Account for and update cumulative rowspan height
                            if rowspan then
                                cellV, cellOffsetV = cellV + rowspan.height, cellOffsetV - rowspan.height
                                rowspan.height = cellV
                            end

                            -- No rowspan or the rowspan ends here
                            if not rowspan or lastRow or rowspan.span == 0 then
                                f = cell.frame
                                alignFn, align = GetAlign("V", cellObj, colObj, tableObj, f:GetHeight() or 0, cellV)
                                if cell:IsFullHeight() or alignFn == "fill" then
                                    f:SetHeight(cellV)
                                end
                                f:SetPoint("TOP", content, 0, -(cellOffsetV + align))
                                rowspans[col] = nil
                            end

                            -- Update loop variables
                            col = col + max(0, min((cellObj.colspan or 1) - 1, #cols - col)) + 1
                            if not rowspan or rowspan.cell == children[j] then
                                j = j + 1
                            end
                        end
                    end
                end
            until slotFound
        end
    end

    -- Calculate total height
    local totalV = offsetV + rowV

    Util.Safecall(obj.LayoutFinished, obj, nil, totalV)
    obj:ResumeLayout()
end)

-------------------------------------------------------
--                      Helper                       --
-------------------------------------------------------

-- Update table rows in-place
function Self.UpdateRows(self, items, createFn, updateFn, idPath)
    local children = self.children
    idPath = idPath or "id"
    start = Util.TblSearch(children, function (child) return child:GetUserData("row-id") end) or #children + 1

    local rows = Util.TblIter(children, function (child, i, rows)
        local id = child and child:GetUserData("row-id")
        if id then rows[id] = i end
    end)


    -- Create and/or update rows
    local it = Util.Iter(start - 1)
    for _,item in ipairs(items) do
        local i = it()
        local id, first = Util.TblGet(item, idPath), children[i]

        -- Create the row or move it to the current position
        if not first or first:GetUserData("row-id") ~= id then
            if not rows[id] then
                -- Create rows
                createFn(self, item, first)
            else
                -- Move rows
                local n = 0
                repeat
                    tinsert(children, i + n, tremove(children, rows[id] + n))
                    n = n + 1
                until not children[rows[id] + n] or children[rows[id] + n]:GetUserData("row-id")

                -- Update row map
                rows = Util.TblMap(rows, function (row, id) return row > i and row < rows[id] and row + n or row end)
                rows[id] = i
            end

            first = children[i]
        end

        first:SetUserData("row-id", id)
        updateFn(self, item, children, it)
    end

    -- Remove the rest
    while children[it()] do
        children[it(0)]:Release()
        children[it(0)] = nil
    end
end

function Self.CreateFilterCheckbox(key)
    local filter = Rolls.frames.filter

    f = Self("CheckBox"):SetLabel(L["FILTER_" .. key:upper()])
        :SetCallback("OnValueChanged", function (self, _, checked)
            if Rolls.filter[key] ~= checked then
                Rolls.filter[key] = checked
                Rolls.Update()
            end
        end)
        :SetCallback("OnEnter", function (self)
            GameTooltip:SetOwner(self.frame, "ANCHOR_TOP")
            GameTooltip:ClearLines()
            GameTooltip:AddLine(L["FILTER_" .. key:upper()])
            GameTooltip:AddLine(L["FILTER_" .. key:upper() .. "_DESC"], 1, 1, 1, true)
            GameTooltip:Show()
        end)
        :SetCallback("OnLeave", function () GameTooltip:Hide() end)
        :AddTo(filter)
        :SetPoint("TOPLEFT", filter.children[#filter.children-1].frame, "TOPRIGHT")()
    f:SetWidth(f.text:GetStringWidth() + 24 + 15)
    return f
end

function Self.CreateIconButton(icon, parent, onClick, desc)
    f = Self("Icon"):SetImage(icon:sub(1, 9) == "Interface" and icon or "Interface\\Buttons\\" .. icon .. "-Up")
        :SetImageSize(16, 16):SetHeight(16):SetWidth(16)
        :SetCallback("OnClick", function (...) onClick(...) GameTooltip:Hide() end):AddTo(parent)()
    f.image:SetPoint("TOP")

    if desc then
        f:SetCallback("OnEnter", function (self)
            GameTooltip:SetOwner(self.frame, "ANCHOR_TOP")
            GameTooltip:SetText(desc, 1, 1, 1, 1)
            GameTooltip:Show()
        end)
        f:SetCallback("OnLeave", function () GameTooltip:Hide() end)
    end

    return f
end

-- Enable chain-calling
setmetatable(Self, {
    __call = function (_, f, ...)
        local c = {f = type(f) == "string" and AceGUI:Create(f, ...) or f}
        setmetatable(c, {
            __index = function (c, k)
                return function (...)
                    local args = {select(... == c and 2 or 1, ...)}
                    if k == "AddTo" then
                        args[1]:AddChild(c.f, unpack(args, 2))
                    else
                        local obj = c.f[k] and c.f
                            or c.f.frame and c.f.frame[k] and c.f.frame
                            or c.f.image and c.f.image[k] and c.f.image
                            or c.f.label and c.f.label[k] and c.f.label
                        obj[k](obj, unpack(args))
                    end
                    return c
                end
            end,
            __call = function (c, i)
                local f = rawget(c, "f")
                if i ~= nil then return f[i] else return f end
            end
        })
        return c
    end
})

-- Export

Addon.GUI = Self