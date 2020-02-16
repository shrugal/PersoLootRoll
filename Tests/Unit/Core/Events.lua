if not WoWUnit then return end

---@type string
local Name = ...
---@type Addon
local Addon = select(2, ...)
local Test, Util = Addon.Test, Addon.Util
local Assert, AssertEqual, Replace = WoWUnit.IsTrue, WoWUnit.AreEqual, WoWUnit.Replace

local Tests = WoWUnit(Name .. ".Unit.Core.Events")

-------------------------------------------------------
--                      Roster                       --
-------------------------------------------------------

function Tests:GROUP_JOINED_TEST()
end

function Tests:GROUP_LEFT_TEST()
end

function Tests:RAID_ROSTER_UPDATE_TEST()
end

-------------------------------------------------------
--                   Chat message                    --
-------------------------------------------------------

-- System
function Tests:CHAT_MSG_SYSTEM_TEST()
end

-- Loot
function Tests:CHAT_MSG_LOOT_TEST()
end

-- Group/Raid/Instance
function Tests:CHAT_MSG_GROUP_TEST()
end

-- Whisper
function Tests:CHAT_MSG_WHISPER_TEST()
end

function Tests:CHAT_MSG_WHISPER_INFORM_TEST()
end

function Tests:CHAT_MSG_WHISPER_FILTER_TEST()
end

-------------------------------------------------------
--                       Item                        --
-------------------------------------------------------

function Tests:ITEM_PUSH_TEST()
end

function Tests:ITEM_LOCKED_TEST()
end

function Tests:ITEM_UNLOCKED_TEST()
end

function Tests:BAG_UPDATE_DELAYED_TEST()
end

-------------------------------------------------------
--                   Addon message                   --
-------------------------------------------------------

-- Check
function Tests:EVENT_CHECK_TEST()
end

-- Version
function Tests:EVENT_VERSION_TEST()
end

-- Enable
function Tests:EVENT_ENABLE_TEST() end

-- Disable
function Tests:EVENT_DISABLE_TEST() end

-- Sync
function Tests:EVENT_SYNC_TEST()
end

-- Roll status
function Tests:EVENT_ROLL_STATUS_TEST()
end

-- Bids
function Tests:EVENT_BID_TEST()
end

-- Bid whisper
function Tests:EVENT_BID_WHISPER_TEST()
end

-- Votes
function Tests:EVENT_VOTE_TEST()
end

-- Declaring interest
function Tests:EVENT_INTEREST_TEST()
end

-- XRealm
function Tests:EVENT_XREALM_TEST()
end