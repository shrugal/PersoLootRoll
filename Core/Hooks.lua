---@type string
local Name = ...
---@type Addon
local Addon = select(2, ...)
---@type L
local L = LibStub("AceLocale-3.0"):GetLocale(Name)
local Comm, GUI, Item, Session, Roll, Trade, Unit, Util = Addon.Comm, Addon.GUI, Addon.Item, Addon.Session, Addon.Roll, Addon.Trade, Addon.Unit, Addon.Util
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
            if Roll.IsPlrId(id) then
                local roll = Roll.Get(id)
                if roll then
                    return roll:GetTimeLeft()
                end
            else
                return Self.hooks.GetLootRollTimeLeft(id)
            end
        end, true)
    end

    -- GetLootRollItemInfo
    if not Self:IsHooked("GetLootRollItemInfo") then
        Self:RawHook("GetLootRollItemInfo", function (id)
            if Roll.IsPlrId(id) then
                local roll = Roll.Get(id)
                if roll then
                    local item = roll.item
                    local disReason = not roll:GetOwnerAddon() and "PLR_NO_ADDON"
                        or not roll.disenchant and "PLR_NO_DISENCHANT"
                        or not Unit.IsEnchanter() and "PLR_NOT_ENCHANTER"
                        or nil

                    return item.texture, item.name, 1, item.quality, item.bindType == LE_ITEM_BIND_ON_ACQUIRE,
                        true,                   -- Can need
                        roll:GetOwnerAddon(),   -- Can greed
                        not disReason,          -- Can disenchant
                        5,                      -- Reason need
                        "PLR_NO_ADDON",         -- Reason greed
                        disReason,              -- Reason disenchant
                        1                       -- Disenchant skill required
                end
            else
                return Self.hooks.GetLootRollItemInfo(id)
            end
        end, true)
    end

    -- GetLootRollItemLink
    if not Self:IsHooked("GetLootRollItemLink") then
        Self:RawHook("GetLootRollItemLink", function (id)
            if Roll.IsPlrId(id) then
                local roll = Roll.Get(id)
                if roll then
                    return Roll.Get(id).item.link
                end
            else
                return Self.hooks.GetLootRollItemLink(id)
            end
        end, true)
    end

    -- RollOnLoot
    if not Self:IsHooked("RollOnLoot") then
        Self:RawHook("RollOnLoot", function (id, bid)
            if Roll.IsPlrId(id) then
                local roll = Roll.Get(id)
                if roll then
                    bid = bid == 0 and Roll.BID_PASS or bid

                    Self:Debug("GUI.Click:Hooks.RollOnLoot", roll.id, bid)

                    GUI.RollBid(roll, bid)
                end
            else
                return Self.hooks.RollOnLoot(id, bid)
            end
        end, true)
    end

    -- GroupLootFrame
    local onShow = function (self)
        if Roll.IsPlrId(self.rollID) then
            local roll = Roll.Get(self.rollID)
            local owner = roll.item.owner
            local color = Unit.Color(owner)

            -- Player name
            self.Name:SetMaxLines(1)
            self.Name:SetHeight(15)

            if not self.Player then
                local f = self:CreateFontString(nil, "ARTWORK", "GameFontNormal")
                f:SetSize(125, 15)
                f:SetPoint("TOPLEFT", self.Name, "BOTTOMLEFT")
                f:SetJustifyH("LEFT")
                f:SetJustifyV("MIDDLE")
                f:SetMaxLines(1)
                self.Player = f
            end
            
            self.Player:SetText(owner)
            self.Player:SetTextColor(color.r, color.g, color.b)
            self.Player:Show()

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
    end

    local onHide = function (self)
        if Roll.IsPlrId(self.rollID) then
            -- Player name
            self.Name:SetMaxLines(0)
            self.Name:SetHeight(30)
            self.Player:Hide()

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
            self.Highlight:Hide()
        end
    end

    local onButtonClick = function (self, button)
        if button == "RightButton" then
            local rollId, bid = self:GetParent().rollID, self:GetID()
            local roll = Roll.IsPlrId(rollId) and Roll.Get(rollId)
            if roll and roll.owner == Session.GetMasterlooter() then
                local answers = Session.rules["answers" .. bid]
                if answers and #answers > 0 then
                    GUI.ToggleAnswersDropdown(roll, bid, answers, "TOPLEFT", self, "CENTER")
                end
            end
        else
            Self.hooks[self].OnClick(self, button)
        end
    end

    for i=1, NUM_GROUP_LOOT_FRAMES do
        local frame = _G["GroupLootFrame" .. i]

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
            if Roll.IsPlrId(id) then
                local roll = Roll.Get(id)
                if roll then
                    if Item.GetInfo(roll.item, "itemType") == "battlepet" then
                        BattlePetToolTip_ShowLink(roll.item.link)
                    else
                        self:SetHyperlink(roll.item.link)
                    end
                end
            else
                return Self.hooks[self].SetLootRollItem(self, id)
            end
        end, true)
    end
end

function Self.DisableGroupLootRoll()
    Self:Unhook("GetLootRollTimeLeft")
    Self:Unhook("GetLootRollItemInfo")
    Self:Unhook("GetLootRollItemLink")
    Self:Unhook("RollOnLoot")
    for i=1, NUM_GROUP_LOOT_FRAMES do
        Self:Unhook(_G["GroupLootFrame" .. i], "OnShow")
        Self:Unhook(_G["GroupLootFrame" .. i], "OnHide")
        Self:Unhook(_G["GroupLootFrame" .. i].NeedButton, "OnClick")
        Self:Unhook(_G["GroupLootFrame" .. i].GreedButton, "OnClick")
        Self:Unhook(_G["GroupLootFrame" .. i].IconFrame, "OnLeave")
    end
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
                    local id, unit, bid = args:match("(%d+):([^:]+):(%d)")
                    local roll = id and Roll.Get(tonumber(id))
                    if roll and unit and bid and roll:CanBeAwardedTo(unit) then
                        roll:Bid(tonumber(bid), unit)
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
            unit = unit or dropdown.unit or dropdown.chatTarget

            if UIDROPDOWNMENU_MENU_LEVEL == 1 then
                button:Hide()

                if Util.In(menu, menus) and Util.Tbl.First(Self.rolls, "CanBeAwardedTo", nil, nil, unit, true) then
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
                end
            end
        end)
    end
end

function Self.DisableUnitMenus()
    Self:Unhook("UnitPopup_ShowMenu")
end
