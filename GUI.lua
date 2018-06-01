local Addon = LibStub("AceAddon-3.0"):GetAddon(PLR_NAME)
local L = LibStub("AceLocale-3.0"):GetLocale(PLR_NAME)
local AceGUI = LibStub("AceGUI-3.0")
local Util = Addon.Util
local Comm = Addon.Comm
local Masterloot = Addon.Masterloot
local Roll = Addon.Roll
local Trade = Addon.Trade
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
    status = {width = 650, height = 400}
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
                Rolls.status = {width = self.frame:GetWidth(), height = self.frame:GetHeight(), top = self.status.top, left = self.status.left}
                self.optionsbutton:Release()
                self.optionsbutton = nil
                self:Release()
                wipe(Rolls.frames)
            end)
            .SetMinResize(650, 120)
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
                            return Util.GetColoredName(Util.GetShortenedName(unit), unit)
                        end).Concat(", ")()
                        local bids = L[s.bidPublic and "PUBLIC" or "PRIVATE"]
                        local votes = L[s.votePublic and "PUBLIC" or "PRIVATE"]

                        GameTooltip:SetOwner(self.frame, "ANCHOR_BOTTOM")
                        GameTooltip:SetText(L["TIP_MASTERLOOT"] .. "\n")
                        GameTooltip:AddLine(L["TIP_MASTERLOOT_INFO"]:format(Util.GetColoredName(ml), council, bids, votes), 1, 1, 1)

                        if Masterloot.IsMasterlooter() then
                            GameTooltip:AddLine("\n" .. L["TIP_MASTERLOOTING"])

                            local c = Util.GetUnitColor("player")
                            GameTooltip:AddLine(ml, c.r, c.g, c.b, false)
                            for unit,_ in pairs(Masterloot.masterlooting) do
                                local c = Util.GetUnitColor(unit)
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
                columns = {20, 1, {25, 100}, {25, 100}, {25, 100}, {25, 100}, {25, 100}, {25, 100}, 20 * 5 - 4},
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
local createFn = function (scroll, roll, first)
    -- ID
    Self("Label")
        .SetFontObject(GameFontNormal)
        .SetText(roll.id)
        .AddTo(scroll, first)

    -- Item
    Self("InteractiveLabel")
        .SetFontObject(GameFontNormal)
        .SetText(roll.item.link)
        .SetImage(roll.item.texture)
        .SetWidth(217)
        .SetCallback("OnEnter", function (self)
            GameTooltip:SetOwner(self.frame, "ANCHOR_LEFT")
            GameTooltip:SetHyperlink(roll.item.link)
            GameTooltip:Show()
        end)
        .SetCallback("OnLeave", Self.TooltipHide)
        .SetCallback("OnClick", function (self)
            if IsModifiedClick("DRESSUP") then
                DressUpItemLink(roll.item.link)
            elseif IsModifiedClick("CHATLINK") then
                ChatEdit_InsertLink(roll.item.link)
            end
        end)
        .AddTo(scroll, first)
    
    -- Ilvl
    Self("Label")
        .SetFontObject(GameFontNormal)
        .AddTo(scroll, first)

    -- Owner
    Self("InteractiveLabel")
        .SetFontObject(GameFontNormal)
        .SetCallback("OnEnter", function (self)
            GameTooltip_SetDefaultAnchor(GameTooltip, UIParent)
            GameTooltip:SetUnit(roll.item.owner)
            GameTooltip:Show()
        end)
        .SetCallback("OnLeave", Self.TooltipHide)
        .SetCallback("OnClick", function () ChatFrame_SendSmartTell(roll.item.owner) end)
        .AddTo(scroll, first)

    -- ML
    Self("InteractiveLabel")
        .SetFontObject(GameFontNormal)
        .SetCallback("OnEnter", function (self)
            if roll:HasMasterlooter() then
                GameTooltip_SetDefaultAnchor(GameTooltip, UIParent)
                GameTooltip:SetUnit(roll.owner)
                GameTooltip:Show()
            end
        end)
        .SetCallback("OnLeave", Self.TooltipHide)
        .SetCallback("OnClick", function ()
            if roll:HasMasterlooter() then
                ChatFrame_SendSmartTell(roll.owner)
            end
        end)
        .AddTo(scroll, first)

    -- Status, Your bid
    Self("Label").SetFontObject(GameFontNormal).AddTo(scroll, first)
    Self("Label").SetFontObject(GameFontNormal).AddTo(scroll, first)

    -- Winner
    Self("InteractiveLabel")
        .SetFontObject(GameFontNormal)
        .SetCallback("OnEnter", function (self)
            if roll.winner then
                GameTooltip_SetDefaultAnchor(GameTooltip, UIParent)
                GameTooltip:SetUnit(roll.winner)
                GameTooltip:Show()
            end
        end)
        .SetCallback("OnLeave", Self.TooltipHide)
        .SetCallback("OnClick", function ()
            if roll.winner then
                ChatFrame_SendSmartTell(roll.winner)
            end
        end)
        .AddTo(scroll, first)

    -- Actions
    f = Self("SimpleGroup")
        .SetLayout(nil)
        .SetHeight(16)
        .SetUserData("cell", {alignH = "end"})
        .AddTo(scroll, first)()
    local backdrop = {f.frame:GetBackdropColor()}
    f.frame:SetBackdropColor(0, 0, 0, 0)
    f.OnRelease = function (self)
        self.frame:SetBackdropColor(unpack(backdrop))
        self.OnRelease = nil
    end

    -- Details
    local details = Self("SimpleGroup")
        .SetLayout("PLR_Table")
        .SetFullWidth(true)
        .SetUserData("isDetails", true)
        .SetUserData("cell", {
            colspan = 99
        })
        .SetUserData("table", {
            columns = {1, {25, 100}, {25, 100}, {25, 100}, 100},
            spaceH = 10,
            spaceV = 2
        })
        .AddTo(scroll, first)()

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
local updateFn = function (scroll, roll, children, it)
    -- ID, Item
    it(1)

    -- Ilvl
    Self(children[it()]).SetText(roll.item:GetBasicInfo().level or "-")

    -- Owner
    Self(children[it()]).SetText(Util.GetColoredName(Util.GetShortenedName(roll.item.owner), roll.item.owner))

    -- ML
    Self(children[it()]).SetText(roll:HasMasterlooter() and Util.GetColoredName(Util.GetShortenedName(roll.owner), roll.owner) or "-")

    -- Status
    Self(children[it()]).SetText(roll.traded and L["ROLL_TRADED"] or roll.winner and L["ROLL_AWARDED"] or L["ROLL_STATUS_" .. roll.status])

    -- Your Bid
    Self(children[it()]).SetText(roll.bid and L["ROLL_BID_" .. roll.bid] or "-")

    -- Winner
    Self(children[it()]).SetText(roll.winner and Util.GetColoredName(Util.GetShortenedName(roll.winner), roll.winner) or "-")

    -- Actions
    do
        local actions = children[it()]
        actions:ReleaseChildren()

        if roll:CanBeWonBy(UnitName("player")) and not roll.bid then
            -- Need
            f = Self.CreateIconButton("UI-GroupLoot-Dice", actions, function ()
                roll:Bid(Roll.BID_NEED)
            end, NEED)
            Self(f).SetImageSize(14, 14).SetWidth(16).SetHeight(16)

            -- Greed
            if roll.ownerId or roll.itemOwnerId then
                Self.CreateIconButton("UI-GroupLoot-Coin", actions, function ()
                    roll:Bid(Roll.BID_GREED)
                end, GREED)
            end

            -- Pass
            f = Self.CreateIconButton("UI-GroupLoot-Pass", actions, function ()
                roll:Bid(Roll.BID_PASS)
            end, PASS)
            Self(f).SetImageSize(13, 13).SetWidth(16).SetHeight(16)
        end

        -- Advertise
        if roll:ShouldAdvertise(true) then
            f = Self.CreateIconButton("UI-GuildButton-MOTD", actions, function ()
                roll:Advertise(true)
            end, L["ADVERTISE"])
            Self(f).SetImageSize(13, 13).SetWidth(16).SetHeight(16)
        end

        -- Trade
        if not roll.traded and roll.winner and (roll.item.isOwner or roll.isWinner) then
            f = Self.CreateIconButton("Interface\\GossipFrame\\VendorGossipIcon", actions, function ()
                roll:Trade()
            end, TRADE)
            Self(f).SetImageSize(13, 13).SetWidth(16).SetHeight(16)
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
            self.parent.parent:DoLayout()
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
end

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
           and (Rolls.filter.awarded or not roll.winner)
           and (Rolls.filter.traded or not roll.traded)
    end).SortBy("id")()

    Self.UpdateRows(scroll, rolls, createFn, updateFn)

    scroll:ResumeLayout()
    scroll:DoLayout()

    -- FILTER

    local filter = Rolls.frames.filter

    it = Util.Iter(1)
    filter.children[it()]:SetValue(Rolls.filter.all)
    filter.children[it()]:SetValue(Rolls.filter.done)
    filter.children[it()]:SetValue(Rolls.filter.awarded)
    filter.children[it()]:SetValue(Rolls.filter.traded)
    filter.children[it()]:SetValue(Rolls.filter.canceled)

    -- ML action
    local ml = Masterloot.GetMasterlooter()
    filter.children[it()]:SetImage(ml and "Interface\\Buttons\\UI-StopButton" or "Interface\\GossipFrame\\WorkOrderGossipIcon")

    -- ML
    f = Self(filter.children[it()]).SetText(L["ML"] .. ": " .. (ml and Util.GetColoredName(Util.GetShortenedName(ml)) or ""))
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
local createFn = function (self, player, first, roll)
    -- Unit
    Self("InteractiveLabel")
        .SetFontObject(GameFontNormal)
        .SetText(Util.GetColoredName(Util.GetShortenedName(player.unit), player.unit))
        .SetCallback("OnEnter", function (self)
            GameTooltip_SetDefaultAnchor(GameTooltip, UIParent)
            GameTooltip:SetUnit(player.unit)
            GameTooltip:Show()
        end)
        .SetCallback("OnLeave", Self.TooltipHide)
        .SetCallback("OnClick", function () ChatFrame_SendSmartTell(player.unit) end)
        .AddTo(self, first)

    -- Ilvl, Bid, Votes
    Self("Label").SetFontObject(GameFontNormal).AddTo(self, first)
    Self("Label").SetFontObject(GameFontNormal).AddTo(self, first)
    Self("Label").SetFontObject(GameFontNormal).AddTo(self, first)

    -- Actions
    local f = Self("Button")
        .SetWidth(100)
        .SetCallback("OnClick", function (self)
            if roll:CanBeAwardedTo(player.unit, true) then
                roll:Finish(player.unit)
            elseif roll:CanVote() then
                roll:Vote(roll.vote ~= player.unit and player.unit or nil)
            end
        end)()
    f.text:SetFont(GameFontNormal:GetFont())
    self:AddChild(f)
end
local updateFn = function (self, player, children, it, roll, canBeAwarded, canVote)
    -- Unit
    it(0)

    -- Ilvl
    Self(children[it()]).SetText(player.ilvl)

    -- Bid
    Self(children[it()]).SetText(player.bid and L["ROLL_BID_" .. player.bid] or "-")

    -- Votes
    Self(children[it()]).SetText(player.votes > 0 and player.votes or "-")

    -- Actions
    local txt = canBeAwarded and L["AWARD"]
        or canVote and (roll.vote == player.unit and L["VOTE_WITHDRAW"] or L["VOTE"])
        or "-"
    Self(children[it()]).SetText(txt).SetDisabled(not (canBeAwarded or canVote))
end

function Rolls.UpdateDetails(self, roll)
    self.frame:Show()
    self:PauseLayout()

    local players = Util({}).Merge(roll.item:GetEligible(), roll.bids).FoldL(function (u, val, unit)
        tinsert(u, {
            unit = unit,
            ilvl = roll.item:GetLevelForLocation(unit),
            bid = type(val) == "number" and val or nil,
            votes = Util(roll.votes).Only(unit).Count()()
        })
        return u
    end, {}).SortBy({{"bid", 99}, {"votes", 0, true}, {"ilvl", 0}, {"unit"}})()

    Self.UpdateRows(self, players, createFn, updateFn, "unit", roll, roll:CanBeAwarded(true), roll:CanVote())

    self:ResumeLayout()
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
local searchFn = function (child) return child:GetUserData("row-id") end
local foldLFn = function (rows, child, i)
    local id = child and child:GetUserData("row-id")
    if id then rows[id] = i end
    return rows
end

function Self.UpdateRows(self, items, createFn, updateFn, idPath, ...)
    local children = self.children
    idPath = idPath or "id"
    start = Util.TblSearch(children, searchFn) or #children + 1

    local rows = Util.TblFoldL(children, foldLFn, {})

    -- Create and/or update rows
    local it = Util.Iter(start - 1)
    for _,item in ipairs(items) do
        local i = it()
        local id, first = item[idPath], children[i]

        -- Create the row or move it to the current position
        if not first or first:GetUserData("row-id") ~= id then
            if not rows[id] then
                -- Create rows
                createFn(self, item, first, ...)
            else
                -- Move rows
                local n = 0
                repeat
                    tinsert(children, i + n, tremove(children, rows[id] + n))
                    n = n + 1
                until not children[rows[id] + n] or children[rows[id] + n]:GetUserData("row-id")

                -- Update row map
                for id,row in pairs(rows) do
                    if row > i and row < rows[id] then
                        rows[id] = row + n
                    end
                end
                rows[id] = i
            end

            first = children[i]
        end

        first:SetUserData("row-id", id)
        updateFn(self, item, children, it, ...)
    end

    -- Remove the rest
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

function Self.CreateIconButton(icon, parent, onClick, desc)
    f = Self("Icon")
        .SetImage(icon:sub(1, 9) == "Interface" and icon or "Interface\\Buttons\\" .. icon .. "-Up")
        .SetImageSize(16, 16).SetHeight(16).SetWidth(16)
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

-- It's just used so often
function Self.TooltipHide()
    GameTooltip:Hide()
end

-- Enable chain-calling
Self.C = {f = nil, k = nil}
local Fn = function (...)
    local c, k, f = Self.C, rawget(Self.C, "k"), rawget(Self.C, "f")
    if k == "AddTo" then
        local parent, beforeWidget = ...
        parent:AddChild(f, beforeWidget)
    else
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

-- Export

Addon.GUI = Self