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
Self.DIALOG_MASTERLOOT_ASK = "PLR_MASTERLOOT_ASK"

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
        Addon:SetMasterlooter("player")
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
    filter = {all = false, canceled = false, done = true, won = true, traded = false},
    status = {width = 700, height = 400}
}

-- Show the rolls frame
function Rolls.Show()
    if Rolls.frames.window then
        Rolls.frames.window.frame:Show()
    else
        -- WINDOW

        Rolls.frames.window = Self("Window"):SetLayout(nil):SetTitle("PersoLootRoll - " .. L["ROLLS"])
            :SetCallback("OnClose", function (self)
                Rolls.status = {width = self.frame:GetWidth(), height = self.frame:GetHeight(), top = self.status.top, left = self.status.left}
                self.optionsbutton:Release()
                self.optionsbutton = nil
                self:Release()
                wipe(Rolls.frames)
            end)
            :SetMinResize(700, 120)
            :SetStatusTable(Rolls.status)()

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

            for _,key in ipairs({"all", "done", "awarded", "traded", "canceled"}) do
                Self.CreateFilterCheckbox(key)
            end

            -- ML action
            f = Self("Icon")
                :AddTo(Rolls.frames.filter)
                :SetCallback("OnEnter", function (self)
                    GameTooltip:SetOwner(self.frame, "ANCHOR_TOP")
                    GameTooltip:SetText(L["TIP_MASTERLOOT_" .. (Addon:GetMasterlooter() and "STOP" or "START")])
                    GameTooltip:Show()
                end)
                :SetCallback("OnLeave", function () GameTooltip:Hide() end)
                :SetCallback("OnClick", function (self)
                    local ml = Addon:GetMasterlooter()
                    if ml then
                        Addon:SetMasterlooter(nil)
                    else
                        ToggleDropDownMenu(1, nil, Self.DROPDOWN_MASTERLOOT, "cursor", 3, -3)
                    end
                end)
                :SetImageSize(16, 16):SetHeight(16):SetWidth(16)
                :SetPoint("TOP", 0, -4)
                :SetPoint("RIGHT")()
            f.image:SetPoint("TOP")

            -- ML
            f = Self("InteractiveLabel"):SetFontObject(GameFontNormal)
                :AddTo(Rolls.frames.filter)
                :SetText()
                :SetCallback("OnEnter", function (self)
                    local ml = Addon:GetMasterlooter()
                    if Addon:IsMasterlooter() then
                        GameTooltip:SetOwner(self.frame, "ANCHOR_BOTTOM")
                        GameTooltip:SetText(L["TIP_MASTERLOOTING"])

                        local c = Util.GetUnitColor("player")
                        GameTooltip:AddLine(ml, c.r, c.g, c.b, false)
                        for unit,_ in pairs(Addon.masterlooting) do
                            local c = Util.GetUnitColor(unit)
                            GameTooltip:AddLine(unit, c.r, c.g, c.b, false)
                        end
                        GameTooltip:Show()
                    elseif ml then
                        GameTooltip_SetDefaultAnchor(GameTooltip, UIParent)
                        GameTooltip:SetUnit(ml)
                        GameTooltip:Show()
                    end
                end)
                :SetCallback("OnLeave", function () GameTooltip:Hide() end)
                :SetCallback("OnClick", function ()
                    local ml = Addon:GetMasterlooter()
                    if ml then ChatFrame_SendSmartTell(ml) end
                end)
                :SetHeight(12)
                :SetPoint("TOP", 0, -6)
                :SetPoint("RIGHT", f.frame, "LEFT")()
        end

        -- SCROLL

        Rolls.frames.scroll = Self("ScrollFrame"):SetLayout("PLR_Table")
            :SetUserData("table", {
                columns = {20, 1, {25, 100}, {25, 100}, {25, 100}, {25, 100}, {25, 100}, {25, 100}, 20 * 5 - 4},
                space = 10
            })
            :AddTo(Rolls.frames.window)
            :SetPoint("TOPRIGHT")
            :SetPoint("BOTTOMLEFT", Rolls.frames.filter.frame, "TOPLEFT", 0, 8)()

        do
            local scroll = Rolls.frames.scroll

            local header = {"ID", "ITEM", "LEVEL", "OWNER", "ML", "STATUS", "YOUR_BID", "WINNER"}
            for i,v in pairs(header) do
                Self("Label"):SetFontObject(GameFontNormal):SetText(Util.StrUcFirst(L[v])):SetColor(1, 0.82, 0):AddTo(scroll)
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
           and (Rolls.filter.canceled or roll.status >= Roll.STATUS_RUNNING)
           and (Rolls.filter.done or (roll.status ~= Roll.STATUS_DONE))
           and (Rolls.filter.won or not roll.winner)
           and (Rolls.filter.traded or not roll.traded)
    end).Values().SortBy("id")()

    Self.UpdateRows(scroll, rolls, function (scroll, roll, first)
        -- ID
        Self("Label"):SetFontObject(GameFontNormal):AddTo(scroll, first)

        -- Item
        Self("InteractiveLabel"):SetFontObject(GameFontNormal):SetCallback("OnLeave", function ()
            GameTooltip:Hide()
        end):AddTo(scroll, first)
        
        -- Ilvl
        Self("Label"):SetFontObject(GameFontNormal):AddTo(scroll, first)

        -- Owner, ML
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
                columns = {1, {25, 100}, {25, 100}, 100},
                spaceH = 10,
                spaceV = 2
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
                local f = Self("Label"):SetFontObject(GameFontNormal):SetText(Util.StrUcFirst(L[v])):SetColor(1, 0.82, 0)()
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
        Self(children[it()])
            :SetText(roll.item.link)
            :SetImage(roll.item.texture)
            :SetWidth(217)
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
        Self(children[it()]):SetText(roll.item:GetBasicInfo().level or "-")

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

        -- ML
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
        Self(children[it()]):SetText(roll.traded and L["ROLL_TRADED"] or roll.winner and L["ROLL_AWARDED"] or L["ROLL_STATUS_" .. roll.status])

        -- Your Bid
        Self(children[it()]):SetText(roll.answer and L["ROLL_ANSWER_" .. roll.answer] or "-")

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

            if roll:CanBeWonBy(UnitName("player")) and not roll.answer then
                -- Need
                f = Self.CreateIconButton("UI-GroupLoot-Dice", actions, function ()
                    roll:Bid(Roll.ANSWER_NEED)
                end, NEED)
                Self(f):SetImageSize(14, 14):SetWidth(16):SetHeight(16)

                -- Greed
                if roll.ownerId or roll.itemOwnerId then
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
            if roll:ShouldAdvertise(true) then
                f = Self.CreateIconButton("UI-GuildButton-MOTD", actions, function ()
                    roll:Advertise(true)
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

    -- ML action
    local ml = Addon:GetMasterlooter()
    Self(filter.children[it()]):SetImage(ml and "Interface\\Buttons\\UI-StopButton" or "Interface\\GossipFrame\\WorkOrderGossipIcon")

    -- ML
    f = Self(filter.children[it()])
        :SetText(L["ML"] .. ": " .. (ml and Util.GetColoredName(Util.GetShortenedName(ml)) or ""))()
    f:SetWidth(f.label:GetStringWidth())
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
        return {
            unit = unit,
            bid = type(val) == "number" and val or nil,
            ilvl = roll.item:GetLevelForLocation(unit)
        }
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
        Self(children[it()]):SetText(player.ilvl)

        -- Bid
        Self(children[it()]):SetText(player.bid and L["ROLL_ANSWER_" .. player.bid] or "-")

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
local GetAlign = function (dir, tableObj, colObj, cellObj, cell, child)
    local fn = cellObj["align" .. dir] or cellObj.align or colObj["align" .. dir] or colObj.align or tableObj["align" .. dir] or tableObj.align or "CENTERLEFT"
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

    local tableObj = obj:GetUserData("table") or {}
    local cols = tableObj.columns
    local spaceH = tableObj.spaceH or tableObj.space or 0
    local spaceV = tableObj.spaceV or tableObj.space or 0
    local totalH = (content:GetWidth() or content.width or 0) - spaceH * (#cols - 1)
    local t, laneH, laneV, rowspans = {}, {}, {}, {}
    
    -- Create the grid
    local n, slotFound = 1
    for i,child in ipairs(children) do
        if child:IsShown() then
            repeat
                local col = (n - 1) % #cols + 1
                local row = ceil(n / #cols)
                local rowspan = rowspans[col]
                local cell = rowspan and rowspan.cell or child
                local cellObj = cell:GetUserData("cell") or {}
                slotFound = not rowspan
                
                -- First col
                if col == 1 then t[row] = {} end

                -- Rowspan
                if not rowspan and cellObj.rowspan then
                    rowspan = {cell = cell, from = row, to = row + cellObj.rowspan - 1}
                    rowspans[col] = rowspan
                end
                if rowspan and i == #children then
                    rowspan.to = row
                end

                -- Colspan
                local colspan = max(0, min((cellObj.colspan or 1) - 1, #cols - col))

                -- Place the cell
                if not rowspan or rowspan.to == row then
                    t[row][col + colspan] = {
                        child = cell,
                        rowStart = rowspan and rowspan.from or row,
                        colStart = col,
                    }

                    if rowspan then
                        rowspans[col] = nil
                    end
                end
                
                n = n + colspan + 1
            until slotFound
        end
    end

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
                for row=1,#t do
                    local cell = t[row][col]
                    if cell then
                        local f = cell.child.frame
                        f:ClearAllPoints()
                        local childH = f:GetWidth() or 0
    
                        laneH[col] = max(laneH[col], childH - GetDimension("H", laneH, cell.colStart, col - 1, spaceH))
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
    for row,cells in ipairs(t) do
        local rowV = 0

        -- Horizontal placement and sizing
        for col=1,#cols do
            local cell = t[row][col]
            if cell then
                local child = cell.child
                local colObj = cols[cell.colStart]
                local cellObj = child:GetUserData("cell") or {}
                local offsetH = GetDimension("H", laneH, 1, cell.colStart - 1, spaceH) + (cell.colStart == 1 and 0 or spaceH)
                local cellH = GetDimension("H", laneH, cell.colStart, col, spaceH)
                
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

                rowV = max(rowV, (f:GetHeight() or 0) - GetDimension("V", laneV, cell.rowStart, row - 1, spaceV))
            end
        end

        laneV[row] = rowV

        -- Vertical placement and sizing
        for col,cell in pairs(cells) do
            local child = cell.child
            local colObj = cols[cell.colStart]
            local cellObj = child:GetUserData("cell") or {}
            local offsetV = GetDimension("V", laneV, 1, cell.rowStart - 1, spaceV) + (cell.rowStart == 1 and 0 or spaceV)
            local cellV = GetDimension("V", laneV, cell.rowStart, row, spaceV)
                
            local f = child.frame
            local childV = f:GetHeight() or 0

            local alignFn, align = GetAlign("V", tableObj, colObj, cellObj, cellV, childV)
            if child:IsFullHeight() or alignFn == "fill" then
                f:SetHeight(cellV)
            end
            f:SetPoint("TOP", content, 0, -(offsetV + align))
        end
    end

    -- Calculate total height
    local totalV = GetDimension("V", laneV, 1, #laneV, spaceV)

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

                        if (k == "SetText" or k == "SetFontObject") and (c.f.type == "Label" or c.f.type == "InteractiveLabel") then
                            c.f.frame:SetWidth(c.f.label:GetStringWidth())
                        end
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