local Addon = LibStub("AceAddon-3.0"):GetAddon(PLR_NAME)
local L = LibStub("AceLocale-3.0"):GetLocale(PLR_NAME)
local AceGUI = LibStub("AceGUI-3.0")
local Util = Addon.Util
local Roll = Addon.Roll
local Trade = Addon.Trade
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
    if Self.Rolls.frame then
        Self.Rolls.frame.frame:Show()
    else
        local window = AceGUI:Create("Window")
        Self.Rolls.frame = window
        window:SetTitle("Rolls")
        window:SetCallback("OnClose", function (self)
            self:Release()
            Self.Rolls.frame = nil
        end)
        window:SetLayout("Fill")

        local scroll = AceGUI:Create("ScrollFrame")
        window.scroll = scroll
        scroll:SetLayout("PLR_Table")
        scroll.colums = {20, 1, 100}
        window:AddChild(scroll)
    end
end

function Rolls.Update()
    local self = Self.Rolls.frame
    if not self then return end

    -- TODO: This should update in-place!

    self.scroll:ReleaseChildren()

    local f
    Util.TblIter(Addon.rolls, function (roll, id)
        f = AceGUI:Create("Label")
        f:SetText(id)
        self.scroll:AddChild(f)

        f = AceGUI:Create("Label")
        f:SetText(roll.item.link)
        self.scroll:AddChild(f)

        f = AceGUI:Create("Label")
        f:SetText(roll.owner)
        self.scroll:AddChild(f)
    end)
end

function Rolls.Hide()
    if Self.Rolls.frame then
        Self.Rolls.frame.frame:Hide()
    end
end

Self.Rolls = Rolls

-------------------------------------------------------
--               AceGUI table layout                 --
-------------------------------------------------------

-- Get alignment method and value. Possible alignment methods are a callback, a number, "start", "middle", "end", "fill" or "TOPLEFT", "BOTTOMRIGHT" etc.
local GetAlign = function (dir, child, col, obj, cell, total)
    local fn = child["align" .. dir] or child.align or col["align" .. dir] or col.align or obj["align" .. dir] or obj.align or "middle"
    local cell, total, val = cell or 0, total or 0, nil

    if type(fn) == "string" then
        fn = fn:lower()
        fn = dir == "V" and (fn:sub(1, 3) == "top" and "start" or fn:sub(1, 6) == "bottom" and "end" or fn:sub(1, 6) == "center" and "middle")
          or dir == "H" and (fn:sub(-5) == "right" and "start" or fn:sub(-4) == "left" and "end" or fn:sub(-6) == "center" and "middle")
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
 - rowspan: TODO
 - align, alignH, alignV: Overwrites the container and column setting for alignment.
]]
AceGUI:RegisterLayout("PLR_Table", function (content, children)
    local obj = content.obj
    local cols = obj.columns
    local spaceH = obj.spaceH or obj.space or 0
    local spaceV = obj.spaceV or obj.space or 0
    local totalH = content.width or content:GetWidth() or 0 - spaceH * (#cols - 1)

    -- Determine fixed size cols, collect weights and calculate scale
    local extantH, weight = totalH, 0
    for i, col in ipairs(cols) do
        if type(col) == "number" then
            col = {[col > 1 and col < 10 and "weight" or "width"] = col}
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
    local n, offsetH, offsetV, totalV, cellH, childH, f, col, colspan, alignFn, align = 1, 0, 0, 0
    for i, child in ipairs(children) do
        col = (n - 1) % #cols + 1
        cellH = GetWidth(col, scale, totalH)

        -- First column of a row -> Update/reset variables
        if col == 1 then
            offsetH, offsetV, totalV = 0, offsetV + totalV + spaceV, 0
        end

        -- Handle colspan
        colspan = child.colspan and max(0, min(child.colspan - 1, #cols - col)) or 0
        for j=col+1, col+colspan do
            cellH = cellH + spaceH + GetWidth(j, scale, totalH)
        end
        n = n + colspan

        -- Set width and left anchor
        f = child.frame
        f:ClearAllPoints()
        f:SetWidth(0)
        childH = f:GetWidth() or 0
        alignFn, align = GetAlign("H", child, cols[col], obj, childH, totalH)
        if alignFn == "fill" or childH > cellH then
            childH = cellH
            f:SetWidth(cellH)
        end
        f:SetPoint("LEFT", content, offsetH + align, 0)

        -- Update variables
        offsetH = offsetH + cellH + spaceH
        totalV = max(totalV, f:GetHeight() or 0)
        n = n + 1

        -- Last column of a row -> Set top anchors
        if col+colspan == #cols or i == #children then
            repeat
                f = children[i].frame
                alignFn, align = GetAlign("H", children[i], cols[col], obj, f:GetHeight(), totalV)
                if alignFn == "fill" then
                    f:SetHeight(totalV)
                end
                f:SetPoint("TOP", content, 0, -(offsetV + align))
                i = i - 1
                col, colspan = col - colspan and colspan + 1 or children[i] and children[i].colspan or 1
            until col <= 0
        end
    end
end)

-- Export

Addon.GUI = Self