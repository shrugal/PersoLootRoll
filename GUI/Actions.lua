---@type string
local Name = ...
---@type Addon
local Addon = select(2, ...)
---@type L
local L = LibStub("AceLocale-3.0"):GetLocale(Name)
local GUI, Roll, Trade, Unit, Util = Addon.GUI, Addon.Roll, Addon.Trade, Addon.Unit, Addon.Util
---@class Actions : Module
local Self = GUI.Actions

---@type table<Widget>
Self.frames = {}
Self.moving = nil
---@type table<string, boolean>
Self.anchors = Util.Tbl.Flip({"TOPLEFT", "TOP", "TOPRIGHT", "RIGHT", "BOTTOMRIGHT", "BOTTOM", "BOTTOMLEFT", "LEFT", "CENTER"}, false)

-------------------------------------------------------
--                     Show/Hide                     --
-------------------------------------------------------

-- Show the frame
---@param move boolean?
function Self.Show(move)
    if Self.frames.window then
        Self.frames.window.frame:Show()
    else
        local status = Addon.db.profile.gui.actions

        Self.frames.window = GUI("InlineGroup")
            .SetLayout("PLR_Table")
            .SetClampedToScreen(true)
            .SetFrameStrata("MEDIUM")
            .SetUserData("table", {
                columns = {20, {75, 300}, {25, 100}, {25, 100}, 0},
                space = 10
            })
            .SetTitle("PersoLootRoll - " .. L["ACTIONS"])
            .SetPoint(status.anchor, status.h, status.v)
            .Show()()

        local fn = Self.frames.window.LayoutFinished
        Self.frames.window.LayoutFinished = function (self, width, height)
            fn(self, width, height)
            self:SetWidth((width or 0) + 20)
        end
        Self.frames.window.OnRelease = function (self)
            Self.frames.window = nil
            Util.Tbl.Call(Self.frames, "Release")
            wipe(Self.frames)
            self.frame:SetFrameStrata("FULLSCREEN_DIALOG")
            self.LayoutFinished = fn
            self.OnRelease = nil
        end

        -- Buttons
        do
            local it = Util.Iter()

            -- Close
            Self.frames.closeBtn = Self.CreateHeaderIconButton(CLOSE, it(), Self.Hide, "UI-StopButton")

            -- Hide all
            Self.frames.hideAllBtn = Self.CreateHeaderIconButton(L["HIDE_ALL"], it(), function (self)
                for i,roll in pairs(Addon.rolls) do
                    if roll:GetActionRequired() and not roll.hidden then
                        roll:ToggleVisibility(false)
                    end
                end
            end, "UI-CheckBox-Check")

            -- Lock button
            Self.frames.lockBtn = Self.CreateHeaderIconButton(UNLOCK, it(), function ()
                if Self.moving then Self.StopMoving() else Self.StartMoving() end
            end, "LockButton-Unlocked-Up", 0.2, 0.8, 0.2, 0.8)
        end

        GUI.TableRowHighlight(Self.frames.window)
    end

    if move then
        Self.StartMoving()
    end

    Self.Update()
end

-- Check if the frame is currently being shown
---@return boolean
function Self.IsShown()
    return Self.frames.window and Self.frames.window.frame:IsShown()
end

-- Hide the frame
function Self.Hide()
    if Self.IsShown() then
        if Self.moving then Self.StopMoving() end
        Self.frames.window.frame:Hide()
    end
end

-- Toggle the frame
function Self.Toggle()
    if Self.IsShown() then Self.Hide() else Self.Show() end
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

    local rolls = Util(Addon.rolls):CopyFilter(function (roll)
        return roll:GetActionRequired() and not roll.hidden
    end):SortBy("id")()

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
            f = GUI("Label").SetFontObject(GameFontNormal).AddTo(parent)()

            -- Target
            GUI.CreateUnitLabel(parent)

            -- Actions
            local actions = GUI("SimpleGroupWithBackdrop")
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
                -- Chat
                f = GUI.CreateIconButton("Interface\\GossipFrame\\GossipGossipIcon", actions, GUI.ChatClick, nil, 13, 13)
                f:SetCallback("OnEnter", GUI.TooltipChat)
                f.frame:RegisterForClicks("LeftButtonUp", "RightButtonUp")

                -- Trade
                f = GUI.CreateIconButton("Interface\\GossipFrame\\VendorGossipIcon", actions, function (self)
                    self:GetUserData("roll"):Trade()
                end, TRADE, 13, 13)

                -- Award or vote
                f = GUI.CreateIconButton("Interface\\FriendsFrame\\UI-Toast-FriendOnlineIcon", actions, function (self)
                    GUI.ToggleAwardOrVoteDropdown(self:GetUserData("roll"), "TOPLEFT", self.frame, "CENTER")
                end)
                f.image:SetPoint("TOP", 0, 1)

                -- Rolls window
                f = GUI.CreateIconButton("UI-Panel-BiggerButton", actions, GUI.Rolls.Show, L["OPEN_ROLLS"])
                f.image:SetTexCoord(0.1, 0.9, 0.1, 0.9)
                f.image:SetPoint("TOP", 0, 1)

                -- Hide
                f = GUI.CreateIconButton("Interface\\Buttons\\UI-CheckBox-Check", actions, function (self)
                    self:GetUserData("roll"):ToggleVisibility(false)
                end, L["HIDE"])
                f.image:SetPoint("TOP", 0, 1)
            end
        end

        local action = roll:GetActionRequired()
        local target = roll:GetActionTarget()
        local canTrade = Trade.ShouldInitTrade(roll)

        -- ID
        GUI(children[it()]).SetText(roll.id).Show()

        -- Item
        GUI(children[it()])
            .SetImage(roll.item.texture)
            .SetText(roll.item.link)
            .SetUserData("link", roll.item.link)
            .Show()

        -- Status
        f = GUI(children[it()]).Show()
        if action == Roll.ACTION_WAIT and roll.status == Roll.STATUS_RUNNING then
            f.SetUserData("roll", roll)
            .SetScript("OnUpdate", Self.OnStatusUpdate)
            Self.OnStatusUpdate(f().frame)
        else
            f.SetText(L[action == Roll.ACTION_TRADE and (roll.isWinner and "GET_FROM" or "GIVE_TO") or action])
            .SetUserData("roll", nil)
            .SetScript("OnUpdate", nil)
        end

        -- Target
        GUI(children[it()])
            .SetText(target and Unit.ColoredShortenedName(target) or "-")
            .SetUserData("unit", target)
            .Show()

        -- Actions
        do
            local actions = children[it()]
            local children = actions.children
            local it = Util.Iter()

            -- Chat
            local anchor = GUI.ReverseAnchor(Addon.db.profile.gui.actions.anchor):gsub("CENTER", "TOP")
            GUI(children[it()])
                .SetUserData("roll", roll)
                .SetUserData("unit", target)
                .SetUserData("anchor", anchor == "TOPLEFT" and "TOPRIGHT" or anchor == "TOPRIGHT" and "TOPLEFT" or anchor)
                .SetImage("Interface\\GossipFrame\\" .. (roll.chat and "Petition" or "Gossip") .. "GossipIcon")
                .SetImageSize(13, 13).SetWidth(13).SetHeight(13)
                .Toggle(target)
            -- Trade
            GUI(children[it()])
                .SetUserData("roll", roll)
                .SetUserData("text", canTrade and TRADE or L["TIP_CHAT_TO_TRADE"])
                .Toggle(target)
                .SetDisabled(not canTrade)
            -- Award or vote
            GUI(children[it()])
                .SetUserData("roll", roll)
                .SetUserData("text", L[action])
                .Toggle(Util.In(action, Roll.ACTION_AWARD, Roll.ACTION_VOTE))
            -- Rolls window
            GUI(children[it()]).Toggle(Util.In(action, Roll.ACTION_AWARD, Roll.ACTION_VOTE))
            -- Hide
            GUI(children[it()]).SetUserData("roll", roll)

            GUI.ArrangeIconButtons(actions)
        end
    end

    -- Release the rest
    while children[it()] do
        children[it(0)]:Release()
        children[it(0)] = nil
    end

    -- Hide if empty
    if Util.Tbl.Count(rolls) == 0 and not Self.moving then
        Self.Hide()
    end

    Util.Tbl.Release(rolls)
    parent:ResumeLayout()
    parent:DoLayout()
end

function Self.OnStatusUpdate(frame)
    local timeLeft = frame.obj:GetUserData("roll"):GetTimeLeft(true)
    GUI(frame.obj)
        .SetText(L["WAIT"] .. (timeLeft > 0 and " (" .. L["SECONDS"]:format(timeLeft) .. ")" or ""))
end

-------------------------------------------------------
--                       Moving                      --
-------------------------------------------------------

function Self.StartMoving()
    Self.moving = true

    local f = Self.frames.window.frame
    f:SetMovable(true)
    f:SetScript("OnMouseDown", f.StartMoving)
    f:SetScript("OnMouseUp", function (self)
        self:StopMovingOrSizing()
        Self.SavePosition()
    end)

    Self.UpdateButtons()
end

function Self.StopMoving()
    local f = Self.frames.window.frame
    Self.moving = nil

    f:SetMovable(false)
    f:SetScript("OnMouseDown", nil)
    f:SetScript("OnMouseUp", nil)

    Self.UpdateButtons()
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

    Self.UpdateButtons()
    Self.Update()
end

function Self.UpdateButtons()
    local anchor = Addon.db.profile.gui.actions.anchor or "TOPLEFT"

    -- Lock button
    GUI(Self.frames.lockBtn)
        .SetImage("Interface\\Buttons\\LockButton-" .. (Self.moving and "L" or "Unl") .. "ocked-Up", 0.2, 0.8, 0.2, 0.8)
        .SetImageSize(12, 12).SetWidth(12).SetHeight(12)
        .SetUserData("text", Self.moving and LOCK or UNLOCK)

    -- Anchor buttons
    for name,btn in pairs(Self.anchors) do
        if not Self.moving then
            if btn then btn.frame:Hide() end
        else
            if not btn then
                btn = GUI("Icon")
                    .SetCallback("OnClick", function () Self.SavePosition(name) end)
                    .SetCallback("OnEnter", GUI.TooltipText)
                    .SetCallback("OnLeave", GUI.TooltipHide)
                    .SetUserData("text", L["SET_ANCHOR"]:format(
                        name:sub(-4) == "LEFT" and L["RIGHT"] or name:sub(-5) == "RIGHT" and L["LEFT"] or L["LEFT"] .. "/" .. L["RIGHT"],
                        name:sub(1, 6) == "BOTTOM" and L["UP"] or name:sub(1, 3) == "TOP" and L["DOWN"] or L["UP"] .. "/" .. L["DOWN"]
                    ))
                    .AddTo(Self.frames.window.frame)
                    .SetPoint(name, name:sub(-5) == "RIGHT" and 5 or name:sub(-4) == "LEFT" and -5 or 0, name:sub(1, 3) == "TOP" and 5 or name:sub(1, 6) == "BOTTOM" and -5 or 0)()
                btn.image:SetPoint("TOP")
                btn.OnRelease = GUI.ResetIcon
                Self.anchors[name] = btn
            end

            GUI(btn)
                .SetColorTexture(name == anchor and 0 or 1, name == anchor and 1 or 0, 0, name == anchor and 1 or 0.7)
                .SetFrameStrata("HIGH")
                .SetImageSize(10, 10).SetWidth(10).SetHeight(10)
                .Show()
        end
    end
end

-------------------------------------------------------
--                      Helpers                      --
-------------------------------------------------------

function Self.CreateHeaderIconButton(text, n, onClick, icon, ...)
    local f = GUI("Icon")
        .SetImage(icon:sub(1, 9) == "Interface" and icon or "Interface\\Buttons\\" .. icon, ...)
        .SetImageSize(12, 12).SetWidth(12).SetHeight(12)
        .SetCallback("OnClick", onClick)
        .SetCallback("OnEnter", GUI.TooltipText)
        .SetCallback("OnLeave", GUI.TooltipHide)
        .SetUserData("text", text)
        .AddTo(Self.frames.window.frame)
        .SetPoint("TOPRIGHT", -(n-1)*17 - 3, -2)
        .Show()()
    f.image:SetPoint("TOP")
    f.OnRelease = Self.ResetIcon

    return f
end

-------------------------------------------------------
--                      Events                       --
-------------------------------------------------------

function Self:OnEnable()
    Self:RegisterMessage(Roll.EVENT_CHANGE, Self.ROLL_CHANGE)
end

function Self:OnDisable()
    Self:UnregisterAllMessages()
end

---@param e string
---@param roll Roll
function Self.ROLL_CHANGE(_, e, roll, ...)
    if Addon.db.profile.ui.showActionsWindow then
        local isShowEvent = Util.In(e, Roll.EVENT_END, Roll.EVENT_AWARD, Roll.EVENT_TOGGLE)
            or e == Roll.EVENT_BID and Unit.IsSelf(select(2, ...))
        if isShowEvent and roll:GetActionRequired() then
            Self.Show()
        end
    end
    Self.Update()
end