local Name, Addon = ...
local L = LibStub("AceLocale-3.0"):GetLocale(Name)
local AceGUI = LibStub("AceGUI-3.0")
local GUI, Inspect, Item, Masterloot, Roll, Trade, Unit, Util = Addon.GUI, Addon.Inspect, Addon.Item, Addon.Masterloot, Addon.Roll, Addon.Trade, Addon.Unit, Addon.Util
local Self = GUI.Actions

Self.frames = {}
Self.moving = nil
Self.anchors = Util.TblFlip({"TOPLEFT", "TOP", "TOPRIGHT", "RIGHT", "BOTTOMRIGHT", "BOTTOM", "BOTTOMLEFT", "LEFT", "CENTER"}, false)

-- Register for roll changes
Roll.On(Self, Roll.EVENT_CHANGE, function (_, e, roll)
    if Addon.db.profile.ui.showActionsWindow and Util.In(e, Roll.EVENT_AWARD, Roll.EVENT_VISIBILITY) and roll:IsActionNeeded() then
        Self.Show()
    end
    Self.Update()
end)

-------------------------------------------------------
--                     Show/Hide                     --
-------------------------------------------------------

-- Show the frame
function Self.Show(move)
    if Self.frames.window then
        Self.frames.window.frame:Show()
    else
        local status = Addon.db.profile.gui.actions

        Self.frames.window = GUI("InlineGroup")
            .SetLayout("PLR_Table")
            .SetUserData("table", {
                columns = {20, {25, 300}, {25, 100}, {25, 100}, 36},
                space = 10
            })
            .SetTitle("PersoLootRoll - " .. L["ACTIONS"])
            .SetClampedToScreen(true)
            .SetPoint(status.anchor, status.h, status.v)
            .Show()()

        local fn = Self.frames.window.LayoutFinished
        Self.frames.window.LayoutFinished = function (self, width, height)
            fn(self, width, height)
            self:SetWidth((width or 0) + 20)
        end
        Self.frames.window.OnRelease = function (self)
            self.LayoutFinished = fn
            Self.frames.closeBtn:Release()
            wipe(Self.frames)
            self.OnRelease = nil
        end

        -- Close button
        local f = GUI("Icon")
            .SetImage("Interface\\Buttons\\UI-StopButton")
            .SetImageSize(12, 12).SetWidth(12).SetHeight(12)
            .SetFrameStrata("HIGH")
            .SetCallback("OnClick", Self.Hide)
            .AddTo(Self.frames.window.frame)
            .SetPoint("TOPRIGHT", -3, -2)
            .Show()()
        f.image:SetPoint("TOP")
        f.OnRelease = function (self)
            self.image:SetPoint("TOP", 0, -5)
            self.OnRelease = nil
        end
        Self.frames.closeBtn = f

        -- Lock button
        f = GUI("Icon")
            .SetImage("Interface\\Buttons\\LockButton-Locked-Up", 0.2, 0.8, 0.2, 0.8)
            .SetImageSize(12, 12).SetWidth(12).SetHeight(12)
            .SetFrameStrata("HIGH")
            .SetCallback("OnClick", Self.StopMoving)
            .AddTo(Self.frames.window.frame)
            .SetPoint("RIGHT", Self.frames.closeBtn.frame, "LEFT", -5, 0)
            .Toggle(move)()
        f.image:SetPoint("TOP")
        f.OnRelease = function (self)
            self.image:SetPoint("TOP", 0, -5)
            self.OnRelease = nil
        end
        Self.frames.lockBtn = f

        GUI.TableRowHighlight(Self.frames.window)
    end

    if move then
        Self.StartMoving()
    end

    Self.Update()
end

-- Check if the frame is currently being shown
function Self.IsShown()
    return Self.frames.window and Self.frames.window.frame:IsShown()
end

-- Hide the frame
function Self.Hide()
    if Self:IsShown() then
        if Self.moving then Self.StopMoving() end
        Self.frames.window.frame:Hide()
    end
end

-- Toggle the frame
function Self.Toggle()
    if Self:IsShown() then Self.Hide() else Self.Show() end
end

-------------------------------------------------------
--                      Update                       --
-------------------------------------------------------

function Self.Update()
    if not Self.frames.window then return end
    
    local f
    local parent = Self.frames.window
    local children = parent.children
    parent:PauseLayout()

    -- Rolls

    local rolls = Util(Addon.rolls).CopyFilter(function (roll)
        return not roll.hidden and roll.status == Roll.STATUS_DONE and roll:IsActionNeeded()
    end).SortBy("id")()

    local it = Util.Iter()
    for _,roll in pairs(rolls) do
        -- Create the row
        if not children[it(0) + 1] then
            -- ID
            GUI("Label")
                .SetFontObject(GameFontNormal)
                .AddTo(parent)
        
            -- Item
            GUI.CreateItemLabel(parent)
        
            -- Status
            local f = GUI("Label").SetFontObject(GameFontNormal).AddTo(parent)()
            
            -- Target
            GUI.CreateUnitLabel(parent)
        
            -- Actions
            local actions = GUI("SimpleGroup")
                .SetLayout(nil)
                .SetHeight(16)
                .SetUserData("cell", {alignH = "end"})
                .AddTo(parent)()
            local backdrop = {actions.frame:GetBackdropColor()}
            actions.frame:SetBackdropColor(0, 0, 0, 0)
            actions.OnRelease = function (self)
                self.frame:SetBackdropColor(unpack(backdrop))
                self.OnRelease = nil
            end
            do
                -- Trade
                f = GUI.CreateIconButton("Interface\\GossipFrame\\VendorGossipIcon", actions, function (self)
                    self:GetUserData("roll"):Trade()
                end, TRADE, 13, 13)
                f.frame:SetPoint("TOPLEFT")

                -- Hide
                f = GUI.CreateIconButton("Interface\\Buttons\\UI-CheckBox-Check", actions, function (self)
                    self:GetUserData("roll"):ToggleVisibility(false)
                end, L["HIDE"])
                f.image:SetPoint("TOP", 0, 1)
                f.frame:SetPoint("TOPRIGHT")
            end
        end

        -- ID
        GUI(children[it()]).SetText(roll.id).Show()

        -- Item
        GUI(children[it()])
            .SetImage(roll.item.texture)
            .SetText(roll.item.link)
            .SetUserData("link", roll.item.link)
            .Show()

        -- Status
        GUI(children[it()]).SetText(L[roll.isWinner and "GET_FROM" or roll.ownerId and "GIVE_TO" or "ASK"]).Show()

        -- Target
        local target = roll.item.isOwner and roll.winner or roll.item.owner
        GUI(children[it()])
            .SetText(Unit.ColoredName(Unit.ShortenedName(target), target) or "-")
            .SetUserData("unit", target)
            .Show()

        -- Actions
        for i,child in pairs(children[it()].children) do
            child:SetUserData("roll", roll)
        end
    end

    -- Release the rest
    while children[it()] do
        children[it(0)]:Release()
        children[it(0)] = nil
    end
    
    -- Hide if empty
    if Util.TblCount(rolls) == 0 and not Self.moving then
        Self.Hide()
    end

    Util.TblRelease(rolls)
    parent:ResumeLayout()
    parent:DoLayout()
end

-------------------------------------------------------
--                       Moving                      --
-------------------------------------------------------

function Self.StartMoving()
    Self.moving = true

    local f = Self.frames.window.frame
    f:EnableMouse(true)
    f:SetMovable(true)
    f:SetScript("OnMouseDown", f.StartMoving)
    f:SetScript("OnMouseUp", function (self)
        self:StopMovingOrSizing()
        Self.SavePosition()
    end)

    Self.frames.lockBtn.frame:Show()

    Self.UpdateAnchorButtons()
end

function Self.StopMoving()
    local f = Self.frames.window.frame
    Self.moving = nil

    f:EnableMouse(false)
    f:SetMovable(false)
    f:SetScript("OnMouseDown", nil)
    f:SetScript("OnMouseUp", nil)

    Self.frames.lockBtn.frame:Hide()
    for name,btn in pairs(Self.anchors) do if btn then btn.frame:Hide() end end

    Self.Update()
end

function Self.SavePosition(anchor)
    local f = Self.frames.window.frame
    local status = Addon.db.profile.gui.actions
    anchor = anchor or status.anchor or "TOPLEFT"

    status.anchor = anchor
    status.h = anchor:sub(-4) == "LEFT" and f:GetLeft() or anchor:sub(-5) == "RIGHT" and f:GetRight() - GetScreenWidth() or f:GetLeft() + f:GetWidth()/2 - GetScreenWidth()/2
    status.v = anchor:sub(1, 6) == "BOTTOM" and f:GetBottom() or anchor:sub(1, 3) == "TOP" and f:GetTop() - GetScreenHeight() or f:GetTop() - f:GetHeight()/2 - GetScreenHeight()/2

    Self.frames.window.frame:ClearAllPoints()
    Self.frames.window.frame:SetPoint(status.anchor, status.h, status.v)

    Self.UpdateAnchorButtons()
end

function Self.UpdateAnchorButtons()
    local anchor = Addon.db.profile.gui.actions.anchor or "TOPLEFT"
    
    for name,btn in pairs(Self.anchors) do
        if not btn then
            btn = GUI("Icon")
                .SetFrameStrata("TOOLTIP")
                .SetCallback("OnClick", function () Self.SavePosition(name) end)
                .SetCallback("OnEnter", function (self)
                    GameTooltip:SetOwner(self.frame, "ANCHOR_TOP")
                    GameTooltip:SetText(L["SET_ANCHOR"]:format(
                        name:sub(-4) == "LEFT" and L["RIGHT"] or name:sub(-5) == "RIGHT" and L["LEFT"] or L["LEFT"] .. "/" .. L["RIGHT"],
                        name:sub(1, 6) == "BOTTOM" and L["UP"] or name:sub(1, 3) == "TOP" and L["DOWN"] or L["UP"] .. "/" .. L["DOWN"]
                    ))
                    GameTooltip:Show()
                end)
                .SetCallback("OnLeave", GUI.TooltipHide)
                .AddTo(Self.frames.window.frame)
                .SetPoint(name, name:sub(-5) == "RIGHT" and 5 or name:sub(-4) == "LEFT" and -5 or 0, name:sub(1, 3) == "TOP" and 5 or name:sub(1, 6) == "BOTTOM" and -5 or 0)()
            btn.image:SetPoint("TOP")
            btn.OnRelease = function (self)
                self.image:SetPoint("TOP", 0, -5)
                self.frame:SetFrameStrata("MEDIUM")
                self.OnRelease = nil
            end
            Self.anchors[name] = btn
        end

        GUI(btn)
            .SetColorTexture(name == anchor and 0 or 1, name == anchor and 1 or 0, 0, name == anchor and 1 or 0.7)
            .SetFrameStrata("TOOLTIP")
            .SetImageSize(10, 10).SetWidth(10).SetHeight(10)
            .SetAlpha(name == anchor and 1 or 0.3)
            .Show()
    end
end