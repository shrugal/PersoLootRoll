---@type string, Addon
local Name, Addon = ...
---@type L
local L = LibStub("AceLocale-3.0"):GetLocale(Name)
local Comm, GUI, Item, Session, Roll, Trade, Unit, Util = Addon.Comm, Addon.GUI, Addon.Item, Addon.Session, Addon.Roll, Addon.Trade, Addon.Unit, Addon.Util

---@class Addon
local Self = Addon

function Self.EnableHooks()
    Self.EnableGroupLootRollHook()
    Self.EnableChatLinksHook()
    Self.EnableUnitMenusHook()
end

function Self.DisableHooks()
    Self.DisableGroupLootRoll()
    Self.DisableChatLinks()
    Self.DisableUnitMenus()
end

-------------------------------------------------------
--                   GroupLootRoll                   --
-------------------------------------------------------

function Self.EnableGroupLootRollHook()
    -- GetLootRollTimeLeft
    if not Self:IsHooked("GetLootRollTimeLeft") then
        Self:RawHook("GetLootRollTimeLeft", function (id)
            local roll = Roll.GetByLootRollId(id)
            if not roll or not roll.owner then return Self.hooks.GetLootRollTimeLeft(id) end

            return roll:GetLootRollTimeLeft()
        end, true)
    end

    -- GetLootRollItemInfo
    if not Self:IsHooked("GetLootRollItemInfo") then
        Self:RawHook("GetLootRollItemInfo", function (id)
            local roll = Roll.GetByLootRollId(id)
            if not roll then return Self.hooks.GetLootRollItemInfo(id) end

            local item = roll.item
            local texture, name, count, quality, bop, canNeed, canGreed, canDis, needReason, greedReason, disReason, disSkill =
                item.texture, item.name, 1, item.quality, item.bindType == LE_ITEM_BIND_ON_ACQUIRE, true, nil, nil, 5, "PLR_NO_ADDON", nil, 1

            if Roll.IsPlrId(id) then
                canGreed = roll:GetOwnerAddon()
                disReason = not roll:GetOwnerAddon() and "PLR_NO_ADDON"
                    or not roll.disenchant and "PLR_NO_DISENCHANT"
                    or not Unit.IsEnchanter() and "PLR_NOT_ENCHANTER"
                    or nil
                canDis = not disReason
            else
                texture, name, count, quality, bop, _, _, canDis, _, _, disReason, disSkill = Self.hooks.GetLootRollItemInfo(id)

                if canDis and not roll.disenchant then
                    canDis, disReason = false, "PLR_NO_DISENCHANT"
                end

                local ids = Roll.GetNeedGreedByLink(roll.item.link, true)
                if ids then count = #ids end
            end

            -- TODO
            local canTransmog = false

            return texture, name, count, quality, bop, canNeed, canGreed, canDis, needReason, greedReason, disReason, disSkill, canTransmog
        end, true)
    end

    -- GetLootRollItemLink
    if not Self:IsHooked("GetLootRollItemLink") then
        Self:RawHook("GetLootRollItemLink", function (id)
            if not Roll.IsPlrId(id) then return Self.hooks.GetLootRollItemLink(id) end

            local roll = Roll.GetByLootRollId(id)
            if not roll then return end

            return roll.item.link
        end, true)
    end

    -- RollOnLoot
    if not Self:IsHooked("RollOnLoot") then
        Self:RawHook("RollOnLoot", function (id, bid)
            if not Roll.IsPlrId(id) then
                local canNeed, canGreed = select(6, Self.hooks.GetLootRollItemInfo(id))

                bid = floor(bid)
                if bid == LOOT_ROLL_TYPE_NEED and not canNeed then bid = LOOT_ROLL_TYPE_GREED end
                if bid == LOOT_ROLL_TYPE_GREED and not canGreed then bid = canNeed and LOOT_ROLL_TYPE_NEED or LOOT_ROLL_TYPE_PASS end

                Self.hooks.RollOnLoot(id, bid)
            end

            local roll = Roll.GetByLootRollId(id)

            Self:Debug("GUI.Click:Hooks.RollOnLoot", roll and roll.id, bid)

            if roll then GUI.RollBid(roll, bid) end
        end, true)
    end

    -- GroupLootFrame
    local onShow = function (self)
        local roll = Roll.GetByLootRollId(self.rollID)
        if not roll then return end

        -- Owner name
        local owner = roll.item.owner
        if owner then
            local color = Unit.Color(owner)

            self.Name:SetMaxLines(1)
            self.Name:SetHeight(15)

            if not self.Owner then
                local f = self:CreateFontString(nil, "ARTWORK", "GameFontNormal")
                f:SetSize(125, 15)
                f:SetPoint("TOPLEFT", self.Name, "BOTTOMLEFT")
                f:SetJustifyH("LEFT")
                f:SetJustifyV("MIDDLE")
                f:SetMaxLines(1)
                self.Owner = f
            end

            self.Owner:SetText(owner)
            self.Owner:SetTextColor(color.r, color.g, color.b)
            self.Owner:Show()
        end

        -- Buttons
        if roll.item.isOwner and Util.Check(Session.GetMasterlooter(), Session.rules.allowKeep, roll.isOwner) then
            self.NeedButton:SetNormalTexture("Interface\\AddOns\\PersoLootRoll\\Media\\Roll-Keep-Up")
            self.NeedButton:SetHighlightTexture("Interface\\AddOns\\PersoLootRoll\\Media\\Roll-Keep-Highlight")
            self.NeedButton:SetPushedTexture("Interface\\AddOns\\PersoLootRoll\\Media\\Roll-Keep-Down")
            self.NeedButton.tooltipText = L["KEEP"]
            self.PassButton:SetNormalTexture("Interface\\AddOns\\PersoLootRoll\\Media\\Roll-Pass-Up")
            self.PassButton:SetHighlightTexture("Interface\\AddOns\\PersoLootRoll\\Media\\Roll-Pass-Highlight")
            self.PassButton:SetPushedTexture("Interface\\AddOns\\PersoLootRoll\\Media\\Roll-Pass-Down")
            self.PassButton.tooltipText = L["GIVE_AWAY"]
        end

        -- Highlight
        if not self.Highlight then
            local f = self:CreateTexture(nil, "BACKGROUND")
            f:SetTexture("Interface\\LootFrame\\LootToast")
            f:SetTexCoord(0, 0.2813, 0, 0.4375)
            f:SetPoint("TOPLEFT", -24, 23)
            f:SetPoint("BOTTOMRIGHT", 20, -23)
            f:SetBlendMode("ADD")
            f:SetAlpha(0.7)
            f:Hide()
            self.Highlight = f
        end
        if roll.item.isOwner then
            self.Highlight:Show()
        end
    end

    local onHide = function (self)
        local roll = Roll.GetByLootRollId(self.rollID)
        if not roll then return end

        -- Owner name
        self.Name:SetMaxLines(0)
        self.Name:SetHeight(30)
        if self.Owner then self.Owner:Hide() end

        -- Buttons
        self.NeedButton:SetNormalTexture("Interface\\Buttons\\UI-GroupLoot-Dice-Up")
        self.NeedButton:SetHighlightTexture("Interface\\Buttons\\UI-GroupLoot-Dice-Highlight")
        self.NeedButton:SetPushedTexture("Interface\\Buttons\\UI-GroupLoot-Dice-Down")
        self.NeedButton.tooltipText = NEED
        self.PassButton:SetNormalTexture("Interface\\Buttons\\UI-GroupLoot-Pass-Up")
        self.PassButton:SetHighlightTexture("Interface\\Buttons\\UI-GroupLoot-Pass-Highlight")
        self.PassButton:SetPushedTexture("Interface\\Buttons\\UI-GroupLoot-Pass-Down")
        self.PassButton.tooltipText = PASS

        -- Highlight
        if self.Highlight then self.Highlight:Hide() end
    end

    local onButtonClick = function (self, button)
        if button ~= "RightButton" then Self.hooks[self].OnClick(self, button) end

        local rollId, bid = self:GetParent().rollID, self:GetID()

        local roll = Roll.GetByLootRollId(rollId)
        local ml = Session.GetMasterlooter()
        if not roll or not ml or roll.owner and roll.owner ~= ml then return end

        local answers = Session.rules["answers" .. bid] --[[@as table]]
        if not answers or #answers == 0 then return end

        GUI.ToggleAnswersDropdown(roll, bid, answers, "TOPLEFT", self, "CENTER")
    end

    for i=1, math.huge do
        local frame = _G["GroupLootFrame" .. i]
        if not frame then break end

        -- OnShow
        if not Self:IsHooked(frame, "OnShow") then
            Self:HookScript(frame, "OnShow", onShow)
        end

        -- OnHide
        if not Self:IsHooked(frame, "OnHide") then
            Self:HookScript(frame, "OnHide", onHide)
        end

        -- OnClick
        if not Self:IsHooked(frame.NeedButton, "OnClick") then
            Self:RawHookScript(frame.NeedButton, "OnClick", onButtonClick)
            frame.NeedButton:RegisterForClicks("LeftButtonUp", "RightButtonUp")
            Self:RawHookScript(frame.GreedButton, "OnClick", onButtonClick)
            frame.GreedButton:RegisterForClicks("LeftButtonUp", "RightButtonUp")
        end

        -- OnLeave
        if not Self:IsHooked(frame.IconFrame, "OnLeave") then
            Self:HookScript(frame.IconFrame, "OnLeave", function ()
                BattlePetTooltip:Hide()
            end)
        end
    end

    -- GroupLootContainer_OpenNewFrame
    if not Self:IsHooked("GroupLootContainer_OpenNewFrame") then
        Self:SecureHook("GroupLootContainer_OpenNewFrame", function (id, timeout)
            local roll = Roll.GetByLootRollId(id)
            if not roll or roll.shown then return end

            local frame = roll:GetRollFrame()
            if not frame or not frame:IsShown() then return end

            if roll.shown == false then
                roll.shown = true
            elseif not Addon.db.profile.ui.showRollFrames or roll.owner then
                roll:HideRollFrame()
            end
        end)
    end

    --GroupLootContainer:RemoveFrame
    if not Self:IsHooked("GroupLootContainer_RemoveFrame") then
        Self:SecureHook("GroupLootContainer_RemoveFrame", function (self, frame)
            -- Find a running roll that hasn't been shown yet
            for i,roll in pairs(Self.rolls) do
                if roll.shown == false and not roll.bid and roll:UnitCanBid() then
                    roll:ShowRollFrame() break
                end
            end
        end)
    end

    -- GameTooltip:SetLootRollItem
    if not Self:IsHooked(GameTooltip, "SetLootRollItem") then
        Self:RawHook(GameTooltip, "SetLootRollItem", function (self, id)
            if not Roll.IsPlrId(id) then return Self.hooks[self].SetLootRollItem(self, id) end

            local roll = Roll.GetByLootRollId(id)
            if not roll then return end

            if Item.GetInfo(roll.item, "itemType") == "battlepet" then
                BattlePetToolTip_ShowLink(roll.item.link)
            else
                self:SetHyperlink(roll.item.link)
            end
        end, true)
    end
end

function Self.DisableGroupLootRoll()
    Self:Unhook("GetLootRollTimeLeft")
    Self:Unhook("GetLootRollItemInfo")
    Self:Unhook("GetLootRollItemLink")
    Self:Unhook("RollOnLoot")

    for i=1, math.huge do
        local frame = _G["GroupLootFrame" .. i]
        if not frame then break end

        Self:Unhook(frame, "OnShow")
        Self:Unhook(frame, "OnHide")
        Self:Unhook(frame.NeedButton, "OnClick")
        Self:Unhook(frame.GreedButton, "OnClick")
        Self:Unhook(frame.IconFrame, "OnLeave")
    end
    Self:Unhook("GroupLootContainer_OpenNewFrame")
    Self:Unhook("GroupLootContainer_RemoveFrame")
    Self:Unhook(GameTooltip, "SetLootRollItem")
end

-------------------------------------------------------
--                    Chat links                     --
-------------------------------------------------------

function Self.EnableChatLinksHook()

    -- CLICK

    if not Self:IsHooked("SetItemRef") then
        Self:SecureHook("SetItemRef", function (link, text, button, frame)
            local linkType, args = link:match("^([^:]+):(.*)$")

            if linkType and linkType:sub(1, 3) == "plr" then
                Self:Debug("GUI.Click:Hooks.Link", linkType, args)

                if linkType == "plrtrade" then
                    Trade.Initiate(args)
                elseif linkType == "plrbid" then
                    ---@type (string|number)?, string?, (string|number)?
                    local id, unit, bid = args:match("(%d+):([^:]+):(%d)")
                    id = tonumber(id)
                    bid = tonumber(bid)
                    local roll = Roll.Get(id)

                    if roll and unit and bid and roll:CanBeAwardedTo(unit) then
                        roll:Bid(bid, unit)
                    end
                end

                -- The default handler will show it, so we have to hide it again
                HideUIPanel(ItemRefTooltip)
            end
        end)
    end

    -- HOVER

    local onHyperlinkEnter = function (self, link)
        local linkType, args = link:match("^([^:]+):(.*)$")
        if linkType == "plrtooltip" then
            local title, text = string.split(":", args)
            GameTooltip:SetOwner(self, "ANCHOR_CURSOR")
            GameTooltip:ClearLines()
            if not Util.Str.IsEmpty(title) then
                GameTooltip:AddLine(Comm.UnescapeString(title), 1, .82, 0)
            end
            GameTooltip:AddLine(Comm.UnescapeString(text), 1, 1, 1, true)
            GameTooltip:Show()
        end
    end
    local onHyperlinkLeave = function () GameTooltip:Hide() end

    for i=1,NUM_CHAT_WINDOWS do
        local frame = _G["ChatFrame" .. i]
        if frame and not Self:IsHooked(frame, "OnHyperlinkEnter") then
            Self:SecureHookScript(frame, "OnHyperlinkEnter", onHyperlinkEnter)
            Self:SecureHookScript(frame, "OnHyperlinkLeave", onHyperlinkLeave)
        end
    end
end

function Self.DisableChatLinks()
    Self:Unhook("SetItemRef")
end

-------------------------------------------------------
--                    Unit menus                     --
-------------------------------------------------------

function Self.EnableUnitMenusHook()
    -- TODO
    do return end

    local menus = {"SELF", "PLAYER", "FRIEND", "PARTY", "RAID_PLAYER", "RAID"}

    local button = GUI(CreateFrame("Button", "PLR_AwardLootButton", UIParent, "UIDropDownMenuButtonTemplate"))
        .SetText(L["AWARD_LOOT"])
        .SetScript("OnClick", function (self)
            Self:Debug("GUI.Click:Hooks.UnitMenu", self.unit)
            local s, x, y = UIParent:GetEffectiveScale(), GetCursorPosition()
            GUI.ToggleAwardUnitDropdown(self.unit, "TOPLEFT", UIParent, "BOTTOMLEFT", x / s, y / s)
        end)
        .Hide()()

    PLR_AwardLootButtonNormalText:SetPoint("LEFT")

    if not Self:IsHooked("UnitPopup_ShowMenu") then
        Self:SecureHook("UnitPopup_ShowMenu", function (dropdown, menu, unit)
            if UIDROPDOWNMENU_MENU_LEVEL ~= 1 then return end

            unit = unit or dropdown.unit or dropdown.chatTarget

            button:Hide()

            if not Util.In(menu, menus) or not Util.Tbl.First(Self.rolls, "CanBeAwardedTo", nil, nil, unit, true) then return end

            local parent = _G["DropDownList1"]
            local placed = false

            for i=1,UIDROPDOWNMENU_MAXBUTTONS do
                local f = _G["DropDownList1Button" .. i]

                if placed then
                    local x, y = select(4, f:GetPoint(1))
                    f:SetPoint("TOPLEFT", x or 0, (y or 0) - UIDROPDOWNMENU_BUTTON_HEIGHT)
                elseif Util.In(f.value, "LOOT_SUBSECTION_TITLE", "INTERACT_SUBSECTION_TITLE") then
                    local x, y = select(4, f:GetPoint(1))
                    GUI(button).SetParent(parent).ClearAllPoints()
                        .SetPoint("TOPLEFT", x or 0, (y or 0) - UIDROPDOWNMENU_BUTTON_HEIGHT)
                        .SetWidth(parent.maxWidth)
                        .Show()
                    button.unit = unit
                    placed = true
                end
            end

            parent:SetHeight(parent:GetHeight() + UIDROPDOWNMENU_BUTTON_HEIGHT)
        end)
    end
end

function Self.DisableUnitMenus()
    Self:Unhook("UnitPopup_ShowMenu")
end
