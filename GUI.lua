local Addon = LibStub("AceAddon-3.0"):GetAddon(PLR_NAME)
local L = LibStub("AceLocale-3.0"):GetLocale(PLR_NAME)
local AceGUI = LibStub("AceGUI-3.0")
local Util = Addon.Util
local Roll = Addon.Roll
local Trade = Addon.Trade
local Comm = Addon.Comm
local Self = {}

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
            Trade.Initiate(roll.owner)
        end
    end
end

Self.LootAlertSystem = AlertFrame:AddQueuedAlertFrameSubSystem("PLR_LootWonAlertFrameTemplate", PLR_LootWonAlertFrame_SetUp, 6, math.huge);

-------------------------------------------------------
--                   Rolls frame                     --
-------------------------------------------------------

local Rolls = {}

function Rolls.Show()
    if Rolls.window then
        Rolls.window.frame:Show()
    else
        local window = AceGUI:Create("Window")
        Rolls.window = window
        window:SetTitle("Rolls")
        window:SetCallback("OnClose", function (self)
            self:Release()
            Rolls.window = nil
        end)
        window:SetLayout("Fill")

        local scroll = AceGUI:Create("ScrollFrame")
        window.scroll = scroll
        scroll:SetLayout("PLR_Table")
        scroll:SetUserData("table", {
            columns = {20, 1, 100, 50, 50, 100, 16},
            space = 10
        })
        window:AddChild(scroll)

        Rolls.Update()
    end
end

function Rolls.Update()
    local self = Rolls.window
    if not self then return end

    -- TODO: This should update in-place!

    self.scroll:PauseLayout()
    self.scroll:ReleaseChildren()

    local f
    local columns = {"ID", "ITEM", "OWNER", "STATUS", "YOUR_BID", "WINNER"}
    for i,v in pairs(columns) do
        f = AceGUI:Create("Label")
        f:SetText(Util.StrUcFirst(L[v]))
        f:SetFontObject(GameFontNormal)
        f:SetColor(1, 0.82, 0)
        if i == #columns then
            f:SetUserData("cell", {colspan = 2})
        end
        self.scroll:AddChild(f)
    end

    Util.TblIter(Addon.rolls, function (roll, id)
        -- ID
        f = AceGUI:Create("Label")
        f:SetText(id)
        f:SetFontObject(GameFontNormal)
        self.scroll:AddChild(f)

        -- Item
        f = AceGUI:Create("InteractiveLabel")
        f:SetWidth(216)
        f:SetText(roll.item.link)
        f:SetImage(roll.item.texture)
        f:SetFontObject(GameFontNormal)
        f:SetCallback("OnEnter", function (self)
            GameTooltip:SetOwner(self.frame, "ANCHOR_LEFT")
            GameTooltip:SetHyperlink(roll.item.link)
            GameTooltip:Show()
        end)
        f:SetCallback("OnLeave", function ()
            GameTooltip:Hide()
        end)
        self.scroll:AddChild(f)

        -- Owner
        f = AceGUI:Create("Label")
        f:SetText(Comm.GetPlayerLink(roll.item.owner))
        f:SetFontObject(GameFontNormal)
        self.scroll:AddChild(f)
        
        -- Status
        f = AceGUI:Create("Label")
        f:SetText(roll.traded and L["TRADED"] or L["ROLL_STATUS_" .. roll.status])
        f:SetFontObject(GameFontNormal)
        self.scroll:AddChild(f)

        -- Your bid
        f = AceGUI:Create("Label")
        f:SetText(roll.answer and L["ROLL_ANSWER_" .. roll.answer] or "-")
        f:SetFontObject(GameFontNormal)
        self.scroll:AddChild(f)

        -- Winner
        f = AceGUI:Create("Label")
        f:SetText(roll.winner and Comm.GetPlayerLink(roll.winner) or "-")
        f:SetFontObject(GameFontNormal)
        self.scroll:AddChild(f)

        -- Toggle
        local details
        f = AceGUI:Create("Icon")
        f:SetImage("Interface\\Buttons\\UI-PlusButton-UP")
        f:SetImageSize(16, 16)
        f:SetHeight(16)
        f:SetWidth(16)
        f:SetCallback("OnClick", function (self)
            if details:IsShown() then
                details.frame:Hide()
            else
                Rolls.UpdateDetails(details, roll)
            end
            Rolls.window.scroll:DoLayout()
        end)
        self.scroll:AddChild(f)

        -- Details
        f = AceGUI:Create("SimpleGroup")
        f:SetFullWidth(true)
        f:SetLayout("PLR_Table")
        f:SetUserData("cell", {
            colspan = 99
        })
        f:SetUserData("table", {
            columns = {1, 100, 100},
            space = 2
        })
        self.scroll:AddChild(f)
        f.frame:Hide()
        details = f
    end)

    self.scroll:ResumeLayout()
    self.scroll:DoLayout()
end

function Rolls.Hide()
    if Rolls.window then
        Rolls.window.frame:Hide()
    end
end

function Rolls.UpdateDetails(self, roll)
    -- TODO: This should update in-place!

    self:PauseLayout()
    self:ReleaseChildren()

    self.content:SetPoint("TOPLEFT", self.frame, "TOPLEFT", 8, -8)
    self.content:SetPoint("BOTTOMRIGHT", self.frame, "BOTTOMRIGHT", -8, 8)

    local f
    local columns = {"PLAYER", "BID"}
    for i,v in pairs(columns) do
        f = AceGUI:Create("Label")
        f:SetText(Util.StrUcFirst(L[v]))
        f:SetFontObject(GameFontNormal)
        f:SetColor(1, 0.82, 0)
        if i == #columns then
            f:SetUserData("cell", {colspan = 2})
        end
        self:AddChild(f)
    end

    local canBeAwarded = roll:CanBeAwarded(true)

    Util({}).Merge(roll.item:GetEligible(), roll:GetBids()).Map(function (val, unit)
        return {unit = unit, bid = type(val) == "number" and val or nil}
    end).Values().SortBy("bid", 99, "unit").Iter(function (v, i)
        -- Unit
        f = AceGUI:Create("Label")
        f:SetText(Comm.GetPlayerLink(v.unit))
        f:SetFontObject(GameFontNormal)
        self:AddChild(f)
        
        -- Bid
        f = AceGUI:Create("Label")
        f:SetText(v.bid and L["ROLL_ANSWER_" .. v.bid] or "-")
        f:SetFontObject(GameFontNormal)
        self:AddChild(f)

        -- Actions
        f = AceGUI:Create("Button")
        f:SetWidth(100)
        f.text:SetFont(GameFontNormal:GetFont())
        f:SetText(L["AWARD"])
        f:SetDisabled(not canBeAwarded)
        f:SetCallback("OnClick", function (self)
            if roll:CanBeAwardedTo(v.unit, true) then
                roll:Award(v.unit)
            end
        end)
        self:AddChild(f)
    end)

    self:ResumeLayout()
    self.frame:Show()
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

    return fn, max(0, min(floor(val), total))
end

-- Get the width for a column, based on abs. width, rel. width or weight.
local GetWidth = function (col, scale, total)
    return floor(col.width and col.width < 1 and col.width * total or col.width or (col.weight or 1) * scale)
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
    local totalH = (content.width or content:GetWidth() or 0) - spaceH * (#cols - 1)
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
    local slotFound, col, rowStart, rowEnd, lastRow, cell, cellH, cellV, cellOffsetV, childH, f, alignFn, align, colspan, rowspan, j
    for i, child in ipairs(children) do
        if child:IsShown() then
            repeat
                col = (n - 1) % #cols + 1
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

                    childH = floor(f:GetWidth() or 0)
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
                        rowV = max(rowV, ceil(f:GetHeight() or 0))
                    end
                -- Or decrement rowspan counter and update total height
                else
                    rowspan.span = rowspan.span - 1
                    if lastRow or rowspan.span == 0 then
                        rowV = max(rowV, ceil(cell.frame:GetHeight() or 0) - rowspan.height)
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
                                cellV, cellOffsetV = cellV + rowspanHeight, cellOffsetV - rowspanHeight
                                rowspan.height = cellV
                            end

                            -- No rowspan or the rowspan ends here
                            if not rowspan or lastRow or rowspan.span == 0 then
                                f = cell.frame
                                alignFn, align = GetAlign("V", cellObj, colObj, tableObj, floor(f:GetHeight() or 0), cellV)
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
    for i=1, content:GetNumPoints() do
        local point, _, _, _, y = content:GetPoint(i)
        if point:sub(1, 3) == "TOP" then
            totalV = totalV - y
        elseif point:sub(1, 6) == "BOTTOM" then
            totalV = totalV + y
        end
    end

    Util.Safecall(obj.LayoutFinished, obj, nil, totalV)
    obj:ResumeLayout()
end)

-- Export

Addon.GUI = Self