---
-- This class contains EmmyLua annotations to help
-- IDEs work with some external classes and types
---

---@class WoWUnit
---@field IsTrue fun(val: any)
---@field AreEqual fun(a: any, b: any)
---@field Replace fun(obj: table, key: any, val: any) | fun(key: any, val: any)
WoWUnit = nil

---@class BugGrabber
---@field RegisterCallback fun(obj: table, event: string, callback: function)
BugGrabber = nil

-- WoW frames

---@class Frame
---@class Texture

---@class ChatFrame: Frame
---@field AddMessage fun(self: self, msg: string)
DEFAULT_CHAT_FRAME = nil

-- WoW methods

---@type fun(unit: string): boolean
IsGuildMember = nil

-- Ace3 widgets

---@class Widget
---@field frame Frame
---@class Icon : Widget
---@class Label : Widget
---@class InteractiveLabel : Label
---@class CheckBox : Widget
---@class SimpleGroup : Widget
---@class FrameWidget : Widget