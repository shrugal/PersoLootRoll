local Addon = LibStub("AceAddon-3.0"):GetAddon(PLR_NAME)
local L = LibStub("AceLocale-3.0"):GetLocale(PLR_NAME)
local Util = Addon.Util
local Roll = Addon.Roll
local Trade = Addon.Trade
local Self = {}

-------------------------------------------------------
--                   GroupLootRoll                   --
-------------------------------------------------------

function Self.EnableGroupLootRoll()
    -- GetLootRollTimeLeft
    if not Addon:IsHooked("GetLootRollTimeLeft") then
        Addon:RawHook("GetLootRollTimeLeft", function (id)
            if Roll.IsPlrId(id) then
                return Roll.Get(id):GetTimeLeft()
            else
                return Addon.hooks.GetLootRollTimeLeft(id)
            end
        end, true)
    end

    -- GetLootRollItemInfo
    if not Addon:IsHooked("GetLootRollItemInfo") then
        Addon:RawHook("GetLootRollItemInfo", function (id)
            if Roll.IsPlrId(id) then
                local roll = Roll.Get(id)
                local item = roll.item

                return item.texture, item.name, 1, item.quality, item.bindType == LE_ITEM_BIND_ON_ACQUIRE,
                    true, -- Can need
                    roll.ownerId or roll.itemOwnerId, -- Can greed
                    false, -- Can disenchant
                    5, -- Reason need
                    "PLR_NO_ADDON", -- Reason greed
                    "PLR_NO_DISENCHANT", -- Reason disenchant
                    nil -- Disenchant skill required
                    -- TODO
            else
                return Addon.hooks.GetLootRollItemInfo(id)
            end
        end, true)
    end

    -- GetLootRollItemLink
    if not Addon:IsHooked("GetLootRollItemLink") then
        Addon:RawHook("GetLootRollItemLink", function (id)
            if Roll.IsPlrId(id) then
                return Roll.Get(id).item.link
            else
                return Addon.hooks.GetLootRollItemLink(id)
            end
        end, true)
    end

    -- RollOnLoot
    if not Addon:IsHooked("RollOnLoot") then
        Addon:RawHook("RollOnLoot", function (id, bid)
            if Roll.IsPlrId(id) then
                local roll = Roll.Get(id)

                if roll.status == Roll.STATUS_RUNNING then
                    roll:Bid(bid == 0 and Roll.BID_PASS or bid)
                else
                    roll:HideRollFrame()
                end
            else
                return Addon.hooks.RollOnLoot(id, bid)
            end
        end, true)
    end

    -- GroupLootFrame
    local onShow = function (self)
        if Roll.IsPlrId(self.rollID) then
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
            
            local owner = Roll.Get(self.rollID).item.owner
            local color = Util.GetUnitColor(owner)
            self.Player:SetText(owner)
            self.Player:SetTextColor(color.r, color.g, color.b)
            self.Player:Show()
        end
    end

    local onHide = function (self)
        if Roll.IsPlrId(self.rollID) then
            self.Name:SetMaxLines(0)
            self.Name:SetHeight(30)
            self.Player:Hide()
        end
    end

    for i=1, NUM_GROUP_LOOT_FRAMES do
        local frame = _G["GroupLootFrame" .. i]

        -- OnShow
        if not Addon:IsHooked(frame, "OnShow") then
            Addon:HookScript(frame, "OnShow", onShow)
        end

        -- OnHide
        if not Addon:IsHooked(frame, "OnHide") then
            Addon:HookScript(frame, "OnHide", onHide)
        end
    end

    --GroupLootContainer:RemoveFrame
    if not Addon:IsHooked("GroupLootContainer_RemoveFrame") then
        Addon:SecureHook("GroupLootContainer_RemoveFrame", function (self, frame)
            -- Find a running roll that hasn't been shown yet
            local roll = Util.TblFirst(Addon.rolls, function (roll)
                return not roll.shown and roll.status == Roll.STATUS_RUNNING and roll.item:ShouldBeBidOn()
            end)
            if roll then
                roll:ShowRollFrame()
            end
        end)
    end

    -- GameTooltip:SetLootRollItem
    if not Addon:IsHooked(GameTooltip, "SetLootRollItem") then
        Addon:RawHook(GameTooltip, "SetLootRollItem", function (self, id)
            --Util.dump(id)
            if Roll.IsPlrId(id) then
                self:SetHyperlink(Roll.Get(id).item.link)
            else
                return Addon.hooks[self].SetLootRollItem(id)
            end
        end, true)
    end
end

function Self.DisableGroupLootRoll()
    Addon:Unhook("GetLootRollTimeLeft")
    Addon:Unhook("GetLootRollItemInfo")
    Addon:Unhook("GetLootRollItemLink")
    Addon:Unhook("RollOnLoot")
    for i=1, NUM_GROUP_LOOT_FRAMES do
        Addon:Unhook(_G["GroupLootFrame" .. i], "OnShow")
        Addon:Unhook(_G["GroupLootFrame" .. i], "OnHide")
    end
    Addon:Unhook("GroupLootContainer_RemoveFrame")
    Addon:Unhook(GameTooltip, "SetLootRollItem")
end

-------------------------------------------------------
--                    Chat links                     --
-------------------------------------------------------

function Self.EnableChatLinks()
    -- Suppress messages starting with [PLR]
    if not Addon:IsHooked("SetItemRef") then
        Addon:RawHook("SetItemRef", function (link, text, button, frame)
            local linkType, args = link:match("^([^:]+):(.*)$")

            if linkType == "plrtrade" then
                Trade.Initiate(args)
            else
                return Addon.hooks.SetItemRef(link, text, button, frame)
            end
        end, true)
    end
end

function Self.DisableChatLinks()
    Addon:Unhook("SetItemRef")
end

-------------------------------------------------------
--             Chat message suppression              --
-------------------------------------------------------

function Self.EnableChatSuppression()
    -- Suppress messages starting with [PLR]
    if not Addon:IsHooked("ChatFrame_OnEvent") then
        Addon:RawHook("ChatFrame_OnEvent", function (...)
            if not Util.StrStartsWith(arg2, "[" .. PLR_PREFIX .. "]") then
                return Addon.hooks.ChatFrame_OnEvent(...)
            end
        end)
    end
end

function Self.DisableChatSuppression()
    Addon:Unhook("ChatFrameOnEvent")
end

-------------------------------------------------------
--                    Unit menus                     --
-------------------------------------------------------

local MENUS = {"SELF", "PLAYER", "FRIEND", "PARTY", "RAID_PLAYER", "RAID"}
local NAME = "PLR_LOOT_AWARD"

function Self.EnableUnitMenus()
    -- Add menu and button
    UnitPopupMenus[NAME] = {}
    UnitPopupButtons[NAME] = {text = L["AWARD_LOOT"], dist = 0, nested = 1}

    -- Add entries to unit menus 
    for _, which in pairs(MENUS) do
        local menu = UnitPopupMenus[which]
        local i = Util.TblFind(menu, "LOOT_PROMOTE") or Util.TblFind(menu, "OTHER_SUBSECTION_TITLE")
        tinsert(menu, i or #menu+1, NAME)
    end

    -- UnitPopup:HideButtons()
    if not Addon:IsHooked("UnitPopup_HideButtons") then
        Addon:SecureHook("UnitPopup_HideButtons", function ()
            local dropdownMenu = UIDROPDOWNMENU_INIT_MENU;
            local unit = Util.GetName(dropdownMenu.unit or dropdownMenu.chatTarget)
            local which = UIDROPDOWNMENU_MENU_VALUE or dropdownMenu.which

            if unit and Util.TblFind(MENUS, which) then
                local i = Util.TblFind(UnitPopupMenus[which], NAME)
                if i then
                    if Util.UnitInGroup(unit) then
                        -- Populate submenu list with all awardable items for that unit
                        UnitPopupMenus[NAME] = Util.TblMap(Roll.ForUnit(unit, true), function (roll, i)
                            UnitPopupButtons[NAME .. i] = {text = roll.item.link, dist = 0, roll = roll.id}
                            return NAME .. i
                        end)

                        -- Show parent entry if submenu isn't empty
                        UnitPopupShown[UIDROPDOWNMENU_MENU_LEVEL][i] = next(UnitPopupMenus[NAME]) and 1 or 0
                    else
                        wipe(UnitPopupMenus[NAME])
                        UnitPopupShown[UIDROPDOWNMENU_MENU_LEVEL][i] = 0
                    end
                end
            end
        end)
    end

    -- UnitPopup:OnUpdate()
    if not Addon:IsHooked("UnitPopup_OnUpdate") then
        Addon:SecureHook("UnitPopup_OnUpdate", function ()
            local dropdownMenu = OPEN_DROPDOWNMENUS[2]

            -- Disable all items buttons that can't be won anymore
            if dropdownMenu and dropdownMenu.which == NAME then
                local unit = Util.GetName(dropdownMenu.unit or dropdownMenu.chatTarget)

                for i,_ in pairs(UnitPopupMenus[NAME]) do
                    local roll = Roll.Get(UnitPopupButtons[NAME .. i].roll)
                    if not roll or not roll:CanBeAwardedTo(unit, true) then
                        UIDropDownMenu_DisableButton(2, i)
                    end
                end
            end
        end)
    end

    -- UnitPopup:OnClick()
    if not Addon:IsHooked("UnitPopup_OnClick") then
        Addon:SecureHook("UnitPopup_OnClick", function (self)
            local dropdownMenu = UIDROPDOWNMENU_INIT_MENU
            local unit = Util.GetName(dropdownMenu.unit or dropdownMenu.chatTarget)

            if self.value and Util.StrStartsWith(self.value, NAME) then
                local roll = Roll.Get(UnitPopupButtons[self.value].roll)
                if roll and roll:CanBeAwardedTo(unit, true) then
                    roll:Finish(unit)
                end
            end
        end)
    end

    -- UIDropDownList buttons
    local onEnter = function (self)
        if self.value and Util.StrStartsWith(self.value, NAME) then
            local roll = Roll.Get(UnitPopupButtons[self.value].roll)
            if roll and roll:CanBeAwarded() then
                GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                GameTooltip:SetHyperlink(roll.item.link)
                GameTooltip:Show()
            end
        end
    end

    for i=1, UIDROPDOWNMENU_MAXBUTTONS do
        local button = _G["DropDownList2Button" .. i]
        if button and not Addon:IsHooked(button, "OnEnter") then
            Addon:SecureHookScript(button, "OnEnter", onEnter)
        end
    end
end

function Self.DisableUnitMenus()
    Addon:Unhook("UnitPopup_HideButtons")
    Addon:Unhook("UnitPopup_OnUpdate")
    Addon:Unhook("UnitPopup_OnClick")
    for i=1, UIDROPDOWNMENU_MAXBUTTONS do
        local button = _G["DropDownList2Button" .. i]
        if button then Addon:Unhook(button, "OnEnter") end
    end
end

-- Export

Addon.Hooks = Self