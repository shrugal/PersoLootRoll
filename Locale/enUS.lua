local Name, Addon = ...
local Locale = Addon.Locale
local lang = "enUS"

-- Chat messages
local L = {lang = lang}
setmetatable(L, Locale.MT)
Locale[lang] = L

L["MSG_BID_1"] = "Do you need that %s?"
L["MSG_BID_2"] = "May I have %s, if you don't need it?"
L["MSG_BID_3"] = "I could use %s if you don't want it."
L["MSG_BID_4"] = "I would take %s if you want to get rid of it."
L["MSG_BID_5"] = "Do you need %s, or may I have it?"
L["MSG_HER"] = "her"
L["MSG_HIM"] = "him"
L["MSG_ITEM"] = "item"
L["MSG_ROLL_ANSWER_AMBIGUOUS"] = "I am giving away multiple items right now, please send me the link of the item you want."
L["MSG_ROLL_ANSWER_BID"] = "Ok, I registered your bid for %s."
L["MSG_ROLL_ANSWER_NO_OTHER"] = "Sorry, I already gave it to someone else."
L["MSG_ROLL_ANSWER_NO_SELF"] = "Sorry, I need that myself."
L["MSG_ROLL_ANSWER_NOT_TRADABLE"] = "Sorry, I can't trade it."
L["MSG_ROLL_ANSWER_YES"] = "You can have it, just trade me."
L["MSG_ROLL_ANSWER_YES_MASTERLOOT"] = "You can have it, just trade <%s>."
L["MSG_ROLL_START"] = "Giving away %s -> /w me or /roll %d!"
L["MSG_ROLL_START_MASTERLOOT"] = "Giving away %s from <%s> -> /w me or /roll %d!"
L["MSG_ROLL_WINNER"] = "<%s> has won %s -> Trade me!"
L["MSG_ROLL_WINNER_MASTERLOOT"] = "<%s> has won %s from <%s> -> Trade %s!"
L["MSG_ROLL_WINNER_WHISPER"] = "You have won %s! Please trade me."
L["MSG_ROLL_WINNER_WHISPER_MASTERLOOT"] = "You have won %s from <%s>! Please trade %s."
L["MSG_ROLL_DISENCHANT"] = "<%s> will disenchant %s -> Trade me!"
L["MSG_ROLL_DISENCHANT_MASTERLOOT"] = "<%s> will disenchant %s from <%s> -> Trade %s!"
L["MSG_ROLL_DISENCHANT_WHISPER"] = "You were picked to disenchant %s, please trade me."
L["MSG_ROLL_DISENCHANT_WHISPER_MASTERLOOT"] = "You were picked to disenchant %s from <%s>, please trade %s."

-- Addon
local L = LibStub("AceLocale-3.0"):NewLocale(Name, lang, lang == Locale.FALLBACK)
if not L then return end

L["ACTION"] = "Action"
L["ACTIONS"] = "Actions"
L["ADVERTISE"] = "Advertise in chat"
L["ANSWER"] = "Answer"
L["ASK"] = "Ask"
L["AWARD"] = "Award"
L["AWARD_LOOT"] = "Award loot"
L["AWARD_RANDOMLY"] = "Award randomly"
L["BID"] = "Bid"
L["COMMUNITY_GROUP"] = "Community Group"
L["COMMUNITY_MEMBER"] = "Community Member"
L["DISABLED"] = "Disabled"
L["DOWN"] = "down"
L["ENABLED"] = "Enabled"
L["EQUIPPED"] = "Equipped"
L["GET_FROM"] = "Get from"
L["GIVE_AWAY"] = "Give away"
L["GIVE_TO"] = "Give to"
L["GUILD_MASTER"] = "Guild Master"
L["GUILD_OFFICER"] = "Guild Officer"
L["HIDE"] = "Hide"
L["HIDE_ALL"] = "Hide all"
L["ITEM"] = "item"
L["ITEM_LEVEL"] = "Item-Level"
L["KEEP"] = "Keep"
L["LEFT"] = "left"
L["MASTERLOOTER"] = "Masterlooter"
L["MESSAGE"] = "Message"
L["ML"] = "ML"
L["OPEN_ROLLS"] = "Open rolls window"
L["OWNER"] = "Owner"
L["PLAYER"] = "Player"
L["PRIVATE"] = "Private"
L["PUBLIC"] = "Public"
L["RAID_ASSISTANT"] = "Raid assistant"
L["RAID_LEADER"] = "Raid leader"
L["RESTART"] = "Restart"
L["RIGHT"] = "right"
L["ROLL"] = "Roll"
L["ROLLS"] = "Rolls"
L["SECONDS"] = "%ds"
L["SET_ANCHOR"] = "Set anchor: Grow %s and %s"
L["SHOW"] = "Show"
L["SHOW_HIDE"] = "Show/Hide"
L["TRADE"] = "Trade"
L["UP"] = "up"
L["VERSION_NOTICE"] = "There's a new version of this addon available. Please update to stay compatible with everyone and not miss out on any loot!"
L["VOTE"] = "Vote"
L["VOTE_WITHDRAW"] = "Withdraw"
L["VOTES"] = "Votes"
L["WINNER"] = "Winner"
L["WON"] = "Won"
L["YOUR_BID"] = "Your bid"

-- Commands
L["HELP"] = [=[Start rolls and bid for items (/PersoLootRoll or /plr).
Usage:
/plr: Open options window
/plr roll [item]* (<timeout> <owner>): Start a roll for one or more item(s)
/plr bid [item] (<owner> <bid>): Bid for an item from another player
/plr options: Open options window
/plr config: Change settings through the command line
/plr help: Print this help message
Legend: [..] = item link, * = one or more times, (..) = optional]=]
L["USAGE_BID"] = "Usage: /plr bid [item] (<owner> <bid>)"
L["USAGE_ROLL"] = "Usage: /plr roll [item]* (<timeout> <owner>)"

-- Errors
L["ERROR_CMD_UNKNOWN"] = "Unknown command '%s'"
L["ERROR_ITEM_NOT_TRADABLE"] = "You cannot trade that item."
L["ERROR_NOT_IN_GROUP"] = "You are not in a group or raid."
L["ERROR_OPT_MASTERLOOT_EXPORT_FAILED"] = "Exporting masterloot settings to <%s> failed!"
L["ERROR_PLAYER_NOT_FOUND"] = "Cannot find player %q."
L["ERROR_ROLL_BID_IMPOSSIBLE_OTHER"] = "%s has send a bid for %s but is not allowed to do so right now."
L["ERROR_ROLL_BID_IMPOSSIBLE_SELF"] = "You cannot bid on that item right now."
L["ERROR_ROLL_BID_UNKNOWN_OTHER"] = "%s has send an invalid bid for %s."
L["ERROR_ROLL_BID_UNKNOWN_SELF"] = "That's not a valid bid."
L["ERROR_ROLL_STATUS_NOT_0"] = "The roll has already been started or finished."
L["ERROR_ROLL_STATUS_NOT_1"] = "The roll is not running."
L["ERROR_ROLL_UNKNOWN"] = "That roll doesn't exist."
L["ERROR_ROLL_VOTE_IMPOSSIBLE_OTHER"] = "%s has send a vote for %s but is not allowed to do so right now."
L["ERROR_ROLL_VOTE_IMPOSSIBLE_SELF"] = "You cannot vote on that item right now."
L["ERROR_NOT_MASTERLOOTER_OTHER_OWNER"] = "You need to become masterlooter to create rolls for other player's items."
L["ERROR_NOT_MASTERLOOTER_TIMEOUT"] = "You cannot change the timeout while having a masterlooter other than yourself."

-- GUI
L["DIALOG_MASTERLOOT_ASK"] = "<%s> wants to become your masterlooter."
L["DIALOG_OPT_MASTERLOOT_LOAD"] = "This will replace your current masterloot settings with those stored in the guild/community info, are you sure you want to proceed?"
L["DIALOG_OPT_MASTERLOOT_SAVE"] = "This will replace any masterloot settings in the guild/community info with your current settings, are you sure you want to proceed?"
L["DIALOG_ROLL_CANCEL"] = "Do you want to cancel this roll?"
L["DIALOG_ROLL_RESTART"] = "Do you want to restart this roll?"
L["FILTER"] = "Filter"
L["FILTER_ALL"] = "For all players"
L["FILTER_ALL_DESC"] = "Include rolls for all players, not just yours or those with items that might interest you."
L["FILTER_AWARDED"] = "Awarded"
L["FILTER_AWARDED_DESC"] = "Include rolls that have been won by someone."
L["FILTER_DONE"] = "Done"
L["FILTER_DONE_DESC"] = "Include rolls that have ended."
L["FILTER_HIDDEN"] = "Hidden"
L["FILTER_HIDDEN_DESC"] = "Include canceled, pending, passed and hidden rolls."
L["FILTER_TRADED"] = "Traded"
L["FILTER_TRADED_DESC"] = "Include rolls whose items have been traded."
L["MENU_MASTERLOOT_SEARCH"] = "Search group for a masterlooter"
L["MENU_MASTERLOOT_START"] = "Become masterlooter"
L["TIP_ADDON_MISSING"] = "Addon missing:"
L["TIP_ADDON_VERSIONS"] = "Addon versions:"
L["TIP_ENABLE_WHISPER_ASK"] = "Tip: Right-Click to enable asking for loot automatically"
L["TIP_CHAT_TO_TRADE"] = "Please ask the owner first before trading"
L["TIP_MASTERLOOT"] = "Masterloot is active"
L["TIP_MASTERLOOT_INFO"] = [=[|cffffff78Masterlooter:|r %s
|cffffff78Roll time:|r %ds (+ %ds per item)
|cffffff78Council:|r %s
|cffffff78Bids:|r %s
|cffffff78Votes:|r %s]=]
L["TIP_MASTERLOOT_START"] = "Become or search for a masterlooter"
L["TIP_MASTERLOOT_STOP"] = "Remove masterlooter"
L["TIP_MASTERLOOTING"] = "Masterlooting group (%d):"
L["TIP_MINIMAP_ICON"] = [=[|cffffff78Left-Click:|r Toggle rolls window
|cffffff78Right-Click:|r Show Options]=]
L["TIP_PLH_USERS"] = "PLH users:"
L["TIP_VOTES"] = "Votes from:"

-- Options - Home
L["OPT_ACTIONS_WINDOW"] = "Show actions window"
L["OPT_ACTIONS_WINDOW_DESC"] = "Show the actions window when there are pending actions, e.g. when you won an item and need to trade someone to get it."
L["OPT_ACTIONS_WINDOW_MOVE"] = "Move"
L["OPT_ACTIONS_WINDOW_MOVE_DESC"] = "Move the actions window around."
L["OPT_ALLOW_DISENCHANT"] = "Allow \"Disenchant\" bids"
L["OPT_ALLOW_DISENCHANT_DESC"] = "Allow others to bid \"Disenchant\" on your own items."
L["OPT_AUTHOR"] = "|cffffd100Author:|r Shrugal (EU-Mal'Ganis)"
L["OPT_AWARD_SELF"] = "Choose winner of your items yourself"
L["OPT_AWARD_SELF_DESC"] = "Choose for yourself who should get your loot, instead of letting the addon randomly pick someone. This is always enabled when you are a masterlooter."
L["OPT_BID_PUBLIC"] = "Bids public"
L["OPT_BID_PUBLIC_DESC"] = "Bids on your rolls are public, so everyone with the addon can see them."
L["OPT_CHILL_MODE"] = "Chill mode"
L["OPT_CHILL_MODE_DESC"] = [=[The intent of chill mode is to take the pressure out of sharing the loot, even if that means that things will take a bit longer. If you enable it the following things will change:

|cffffff781.|r Rolls from you won't start until you actually decided to share them, so you have as much time as you want to choose, and other addon users won't see your items until you did.
|cffffff782.|r Rolls from you have double the normal run-time, or no run-time at all if you enabled to choose winners of your own items yourself (see next option).
|cffffff783.|r Rolls from non-addon users in your group also stay open until you decided if you want them or not.

|cffff0000IMPORTANT:|r Rolls from other addon users without chill mode active will still have a normal timeout. Make sure that everyone in your group enables this option if you want a chill run.]=]
L["OPT_DONT_SHARE"] = "Don't share loot"
L["OPT_DONT_SHARE_DESC"] = "Don't roll on loot from others and don't share your own loot. The addon will deny incoming requests for your loot (if enabled), and you can still be masterlooter and loot council member."
L["OPT_ENABLE"] = "Enable"
L["OPT_ENABLE_DESC"] = "Enable or disable the addon"
L["OPT_ACTIVE_GROUPS"] = "Activate by group type"
L["OPT_ACTIVE_GROUPS_DESC"] = [=[Activate only when you are in one of these group types.

|cffffff78Guild Group:|r The members of one guild make up %d%% or more of the group.
|cffffff78Community Group:|r The members of one of your WoW-Communities make up %d%% or more of the group.]=]
L["OPT_ILVL_THRESHOLD"] = "Item-level threshold"
L["OPT_ILVL_THRESHOLD_DESC"] = "Items that are more than this many item levels below yours are ignored."
L["OPT_ILVL_THRESHOLD_TRINKETS"] = "Double threshold for trinkets"
L["OPT_ILVL_THRESHOLD_TRINKETS_DESC"] = "Trinkets should have double the normal threshold because proc effects can make their value vary by a large amount."
L["OPT_ILVL_THRESHOLD_RINGS"] = "Double threshold for rings"
L["OPT_ILVL_THRESHOLD_RINGS_DESC"] = "Rings should have double the normal threshold because their value may vary by a large amount due to missing primary stats."
L["OPT_INFO"] = "Information"
L["OPT_INFO_DESC"] = "Some information about this addon."
L["OPT_ITEM_FILTER"] = "Item Filter"
L["OPT_ITEM_FILTER_DESC"] = "Change which items you are asked to roll on."
L["OPT_MINIMAP_ICON"] = "Show minimap icon"
L["OPT_MINIMAP_ICON_DESC"] = "Show or hide the minimap icon."
L["OPT_ONLY_MASTERLOOT"] = "Only masterloot"
L["OPT_ONLY_MASTERLOOT_DESC"] = "Only activate the addon when using masterloot (e.g. with your guild)"
L["OPT_ROLL_FRAMES"] = "Show roll frames"
L["OPT_ROLL_FRAMES_DESC"] = "Show the roll frames when someone loots something you might be interested in, so you can roll for it."
L["OPT_ROLLS_WINDOW"] = "Show rolls window"
L["OPT_ROLLS_WINDOW_DESC"] = "Always show the rolls window (with all rolls on it) when someone loots something you might be interested in. This is always enabled when you are a masterlooter."
L["OPT_SPECS"] = "Specializations"
L["OPT_SPECS_DESC"] = "Only suggest loot for these class specializations."
L["OPT_TRANSLATION"] = "|cffffd100Translation:|r Shrugal (EU-Mal'Ganis)"
L["OPT_TRANSMOG"] = "Check transmog appearance"
L["OPT_TRANSMOG_DESC"] = "Roll on items that you don't have the appearance of yet."
L["OPT_DISENCHANT"] = "Disenchant"
L["OPT_DISENCHANT_DESC"] = "Bid \"Disenchant\" on items you can't use if you have the profession and the item owner has allowed it."
L["OPT_PAWN"] = "Check \"Pawn\""
L["OPT_PAWN_DESC"] = "Only roll on items that are an upgrade according to the \"Pawn\" addon."
L["OPT_UI"] = "User interface"
L["OPT_UI_DESC"] = "Customize %s's look and feel to your liking."
L["OPT_VERSION"] = "|cffffd100Version:|r %s"

-- Options - Masterloot
L["OPT_MASTERLOOT"] = "Masterloot"
L["OPT_MASTERLOOT_APPROVAL"] = "Approval"
L["OPT_MASTERLOOT_APPROVAL_ACCEPT"] = "Automatically accept masterlooter"
L["OPT_MASTERLOOT_APPROVAL_ACCEPT_DESC"] = "Automatically accept masterlooter requests from these players."
L["OPT_MASTERLOOT_APPROVAL_ALLOW"] = "Allow becoming masterlooter"
L["OPT_MASTERLOOT_APPROVAL_ALLOW_ALL"] = "Allow everbody"
L["OPT_MASTERLOOT_APPROVAL_ALLOW_ALL_DESC"] = "|cffff0000WARNING:|r This will allow everybody to request becoming your masterlooter and potentially scam you into giving away your loot! Only activate it if you know what you are doing."
L["OPT_MASTERLOOT_APPROVAL_ALLOW_DESC"] = [=[Choose who can request to become your masterlooter. You will still get a popup message asking you to confirm it, so you can decline a masterlooter request when it happens.

|cffffff78Guild Group:|r Someone from a guild whose members make up %d%% or more of the group.]=]
L["OPT_MASTERLOOT_APPROVAL_DESC"] = "Here you can define who can become your masterlooter."
L["OPT_MASTERLOOT_APPROVAL_WHITELIST"] = "Masterlooter Whitelist"
L["OPT_MASTERLOOT_APPROVAL_WHITELIST_DESC"] = "You can also name specific players who should be able to become your masterlooter. Separate multiple names with spaces or commas."
L["OPT_MASTERLOOT_CLUB"] = "Guild/Community"
L["OPT_MASTERLOOT_CLUB_DESC"] = "Select the Guild/Community to import/export settings from."
L["OPT_MASTERLOOT_COUNCIL"] = "Council"
L["OPT_MASTERLOOT_COUNCIL_CLUB_RANK"] = "Council guild/community rank"
L["OPT_MASTERLOOT_COUNCIL_CLUB_RANK_DESC"] = "Add members of this guild/community rank to you council, in addition to the options above."
L["OPT_MASTERLOOT_COUNCIL_DESC"] = "Players on your loot council can vote on who should get the loot."
L["OPT_MASTERLOOT_COUNCIL_ROLES"] = "Council roles"
L["OPT_MASTERLOOT_COUNCIL_ROLES_DESC"] = "Which players should automatically become part of your council."
L["OPT_MASTERLOOT_COUNCIL_WHITELIST"] = "Council whitelist"
L["OPT_MASTERLOOT_COUNCIL_WHITELIST_DESC"] = "You can also name specific players to be on your council. Separate multiple names with spaces or commas."
L["OPT_MASTERLOOT_DESC"] = "When you (or someone else) becomes masterlooter, all loot will be distributed by that person. You will get a notice about who's items you won or who won your items, so you can trade them to the right person."
L["OPT_MASTERLOOT_EXPORT_DONE"] = "Masterloot settings successfully exported to <%s>."
L["OPT_MASTERLOOT_EXPORT_GUILD_ONLY"] = "Please replace the community's current info with this text, because automatically replacing it is only possible for guilds."
L["OPT_MASTERLOOT_EXPORT_NO_PRIV"] = "Please ask a leader to replace the guild's info with this text, because you don't have the right to do so yourself."
L["OPT_MASTERLOOT_EXPORT_WINDOW"] = "Export masterloot settings"
L["OPT_MASTERLOOT_LOAD"] = "Load"
L["OPT_MASTERLOOT_LOAD_DESC"] = "Load masterloot settings from your guild/community's description."
L["OPT_MASTERLOOT_RULES"] = "Rules"
L["OPT_MASTERLOOT_RULES_AUTO_AWARD"] = "Award loot automatically"
L["OPT_MASTERLOOT_RULES_AUTO_AWARD_DESC"] = "Let the addon decide who should get the loot, based on factors like council votes, bids and equipped ilvl."
L["OPT_MASTERLOOT_RULES_AUTO_AWARD_TIMEOUT"] = "Auto award time (base)"
L["OPT_MASTERLOOT_RULES_AUTO_AWARD_TIMEOUT_DESC"] = "The base time to wait before auto-awarding loot, so you have time to collect votes and maybe decide for yourself."
L["OPT_MASTERLOOT_RULES_AUTO_AWARD_TIMEOUT_PER_ITEM"] = "Auto award time (per item)"
L["OPT_MASTERLOOT_RULES_AUTO_AWARD_TIMEOUT_PER_ITEM_DESC"] = "Will be added to the base auto award time for each item that dropped."
L["OPT_MASTERLOOT_RULES_BID_PUBLIC"] = "Bids public"
L["OPT_MASTERLOOT_RULES_BID_PUBLIC_DESC"] = "You can make bids public, so everybody can see who bid on what."
L["OPT_MASTERLOOT_RULES_DESC"] = "These rules apply to everybody when you are the masterlooter"
L["OPT_MASTERLOOT_RULES_ALLOW_DISENCHANT_DESC"] = "Allow group members to roll \"Disenchant\" on items."
L["OPT_MASTERLOOT_RULES_DISENCHANTER"] = "Disenchanter"
L["OPT_MASTERLOOT_RULES_DISENCHANTER_DESC"] = "Give loot nobody wants to these players for disenchanting. Separate multiple names with spaces or commas."
L["OPT_MASTERLOOT_RULES_GREED_ANSWERS"] = "Custom 'Greed' answers"
L["OPT_MASTERLOOT_RULES_GREED_ANSWERS_DESC"] = [=[Specify up to 9 custom answers when rolling 'Greed', with decreasing priority. You can also insert '%s' itself to lower its priority below the prior answers. Separate multiple entries with Commas.

They can be accessed by right-clicking on the 'Greed' button when rolling on loot.]=]
L["OPT_MASTERLOOT_RULES_NEED_ANSWERS"] = "Custom 'Need' answers"
L["OPT_MASTERLOOT_RULES_NEED_ANSWERS_DESC"] = [=[Specify up to 9 custom answers when rolling 'Need', with decreasing priority. You can also insert '%s' itself to lower its priority below the prior answers. Separate multiple entries with Commas.

They can be accessed by right-clicking on the 'Need' button when rolling on loot.]=]
L["OPT_MASTERLOOT_RULES_TIMEOUT_BASE"] = "Roll time (base)"
L["OPT_MASTERLOOT_RULES_TIMEOUT_BASE_DESC"] = "The base running time for rolls, regardless of how many items have dropped."
L["OPT_MASTERLOOT_RULES_TIMEOUT_PER_ITEM"] = "Roll time (per item)"
L["OPT_MASTERLOOT_RULES_TIMEOUT_PER_ITEM_DESC"] = "Will be added to the base roll running time for each item that dropped."
L["OPT_MASTERLOOT_RULES_VOTE_PUBLIC"] = "Vote public"
L["OPT_MASTERLOOT_RULES_VOTE_PUBLIC_DESC"] = "You can make council votes public, so everybody can see who has how many votes."
L["OPT_MASTERLOOT_SAVE"] = "Save"
L["OPT_MASTERLOOT_SAVE_DESC"] = "Save your current masterloot settings to your guild/community's description."

-- Options - Messages
L["OPT_CUSTOM_MESSAGES"] = "Custom messages"
L["OPT_CUSTOM_MESSAGES_DEFAULT"] = "Default language (%s)"
L["OPT_CUSTOM_MESSAGES_DEFAULT_DESC"] = "These messages will be used when the recipient speaks %s or something other than your realm's default language (%s)."
L["OPT_CUSTOM_MESSAGES_DESC"] = "You can reorder placeholders (|cffffff78%s|r, |cffffff78%d|r) by adding their position and a $ sign in the middle, so e.g. |cffffff78%2$s|r instead of |cffffff78%s|r for the 2nd placeholder. See tooltips for details."
L["OPT_CUSTOM_MESSAGES_LOCALIZED"] = "Realm language (%s)"
L["OPT_CUSTOM_MESSAGES_LOCALIZED_DESC"] = "These messages will be used when the recipient speaks your realm's default language (%s)."
L["OPT_ECHO"] = "Chat information"
L["OPT_ECHO_DEBUG"] = "Debug"
L["OPT_ECHO_DESC"] = [=[How much information do you want to see from the addon in chat?

|cffffff78None:|r No info in chat.
|cffffff78Error:|r Only error messages.
|cffffff78Info:|r Errors and useful info that you probably want to act on.
|cffffff78Verbose:|r Get notices about pretty much anything the addon does.
|cffffff78Debug:|r Same as verbose, plus additional debug info.]=]
L["OPT_ECHO_ERROR"] = "Error"
L["OPT_ECHO_INFO"] = "Info"
L["OPT_ECHO_NONE"] = "None"
L["OPT_ECHO_VERBOSE"] = "Verbose"
L["OPT_GROUPCHAT"] = "Group Chat"
L["OPT_GROUPCHAT_ANNOUNCE"] = "Announce rolls and winners"
L["OPT_GROUPCHAT_ANNOUNCE_DESC"] = "Announce your rolls and winners of your rolls in group chat."
L["OPT_GROUPCHAT_DESC"] = "Change whether or not the addon will post things to the group chat."
L["OPT_GROUPCHAT_GROUP_TYPE"] = "Announce by group type"
L["OPT_GROUPCHAT_GROUP_TYPE_DESC"] = [=[Post to group chat only if you are in one of these group types.

|cffffff78Guild Group:|r The members of one guild make up %d%% or more of the group.
|cffffff78Community Group:|r The members of one of your WoW-Communities make up %d%% or more of the group.]=]
L["OPT_GROUPCHAT_ROLL"] = "Roll on loot in chat"
L["OPT_GROUPCHAT_ROLL_DESC"] = "Roll on loot you want (/roll) if others post links in group chat."
L["OPT_MESSAGES"] = "Messages"
L["OPT_MSG_BID"] = "Ask for loot: Variant %d"
L["OPT_MSG_BID_DESC"] = "1: Item link"
L["OPT_MSG_ROLL_ANSWER_AMBIGUOUS"] = "Answer: Send me the item link"
L["OPT_MSG_ROLL_ANSWER_AMBIGUOUS_DESC"] = ""
L["OPT_MSG_ROLL_ANSWER_BID"] = "Answer: Bid registered"
L["OPT_MSG_ROLL_ANSWER_BID_DESC"] = "1: Item link"
L["OPT_MSG_ROLL_ANSWER_NO_OTHER"] = "Answer: I gave it to someone else"
L["OPT_MSG_ROLL_ANSWER_NO_OTHER_DESC"] = ""
L["OPT_MSG_ROLL_ANSWER_NO_SELF"] = "Answer: I need it myself"
L["OPT_MSG_ROLL_ANSWER_NO_SELF_DESC"] = ""
L["OPT_MSG_ROLL_ANSWER_NOT_TRADABLE"] = "Answer: It's not tradable"
L["OPT_MSG_ROLL_ANSWER_NOT_TRADABLE_DESC"] = ""
L["OPT_MSG_ROLL_ANSWER_YES"] = "Answer: You can have it"
L["OPT_MSG_ROLL_ANSWER_YES_DESC"] = ""
L["OPT_MSG_ROLL_ANSWER_YES_MASTERLOOT"] = "Answer: You can have it (as masterlooter)"
L["OPT_MSG_ROLL_ANSWER_YES_MASTERLOOT_DESC"] = "1: Item owner"
L["OPT_MSG_ROLL_START"] = "Announcing a new roll"
L["OPT_MSG_ROLL_START_DESC"] = [=[1: Item link
2: Roll number]=]
L["OPT_MSG_ROLL_START_MASTERLOOT"] = "Announcing a new roll (as masterlooter)"
L["OPT_MSG_ROLL_START_MASTERLOOT_DESC"] = [=[1: Item link
2: Item owner
3: Roll number]=]
L["OPT_MSG_ROLL_WINNER"] = "Announcing a roll winner"
L["OPT_MSG_ROLL_WINNER_DESC"] = [=[1: Winner
2: Item link]=]
L["OPT_MSG_ROLL_WINNER_MASTERLOOT"] = "Announcing a roll winner (as masterlooter)"
L["OPT_MSG_ROLL_WINNER_MASTERLOOT_DESC"] = [=[1: Winner
2: Item link
3: Item owner
4: him/her]=]
L["OPT_MSG_ROLL_WINNER_WHISPER"] = "Whispering the roll winner"
L["OPT_MSG_ROLL_WINNER_WHISPER_DESC"] = "1: Item link"
L["OPT_MSG_ROLL_WINNER_WHISPER_MASTERLOOT"] = "Whispering the roll winner (as masterlooter)"
L["OPT_MSG_ROLL_WINNER_WHISPER_MASTERLOOT_DESC"] = [=[1: Item link
2: Item owner
3: him/her]=]
L["OPT_MSG_ROLL_DISENCHANT"] = "Announcing a disenchanter"
L["OPT_MSG_ROLL_DISENCHANT_DESC"] = [=[1: Disenchanter
2: Item link]=]
L["OPT_MSG_ROLL_DISENCHANT_MASTERLOOT"] = "Announcing a disenchanter (as masterlooter)"
L["OPT_MSG_ROLL_DISENCHANT_MASTERLOOT_DESC"] = [=[1: Disenchanter
2: Item link
3: Item owner
4: him/her]=]
L["OPT_MSG_ROLL_DISENCHANT_WHISPER"] = "Whispering the disenchanter"
L["OPT_MSG_ROLL_DISENCHANT_WHISPER_DESC"] = "1: Item link"
L["OPT_MSG_ROLL_DISENCHANT_WHISPER_MASTERLOOT"] = "Whispering the disenchanter (as masterlooter)"
L["OPT_MSG_ROLL_DISENCHANT_WHISPER_MASTERLOOT_DESC"] = [=[1: Item link
2: Item owner
3: him/her]=]
L["OPT_SHOULD_CHAT"] = "Enable/Disable"
L["OPT_SHOULD_CHAT_DESC"] = "Define when the addon will post to party/raid chat and whisper other players."
L["OPT_WHISPER"] = "Whisper Chat"
L["OPT_WHISPER_ANSWER"] = "Answer requests"
L["OPT_WHISPER_ANSWER_DESC"] = "Let the addon answer whispers from group members about items you looted."
L["OPT_WHISPER_ASK"] = "Ask for loot"
L["OPT_WHISPER_ASK_DESC"] = "Whisper others if they got loot you want."
L["OPT_WHISPER_DESC"] = "Change whether or not the addon will whisper other players and/or answer incoming messages."
L["OPT_WHISPER_GROUP"] = "Whisper by group type"
L["OPT_WHISPER_GROUP_DESC"] = "Whisper others if they got loot you want, depending on the type of group you are currently in."
L["OPT_WHISPER_GROUP_TYPE"] = "Ask by group type"
L["OPT_WHISPER_GROUP_TYPE_DESC"] = [=[Ask for loot only if you are in one of these group types.

|cffffff78Guild Group:|r The members of one guild make up %d%% or more of the group.
|cffffff78Community Group:|r The members of one of your WoW-Communities make up %d%% or more of the group.]=]
L["OPT_WHISPER_SUPPRESS"] = "Suppress requests"
L["OPT_WHISPER_SUPPRESS_DESC"] = "Suppress incoming whisper messages from eligible players when giving away your loot."
L["OPT_WHISPER_TARGET"] = "Ask by target"
L["OPT_WHISPER_TARGET_DESC"] = "Ask for loot depending on whether the target is in your guild, in one of your WoW-Communities or on your friend list."
L["OPT_WHISPER_ASK_VARIANTS"] = "Enable ask variants"
L["OPT_WHISPER_ASK_VARIANTS_DESC"] = "Use different lines (see below) when asking for loot, to make it less repetitive."

-- Roll
L["BID_CHAT"] = "Asking %s for %s -> %s."
L["BID_MAX_WHISPERS"] = "Won't ask %s for %s, because %d players in your group already asked -> %s."
L["BID_NO_CHAT"] = "Won't ask %s for %s, because it is disabled for the group or target -> %s."
L["BID_PASS"] = "Passing on %s from %s."
L["BID_START"] = "Bidding with %q for %s from %s."
L["MASTERLOOTER_OTHER"] = "%s is now your masterlooter."
L["MASTERLOOTER_SELF"] = "You are now the masterlooter."
L["ROLL_AWARDED"] = "Awarded"
L["ROLL_AWARDING"] = "Awading"
L["ROLL_CANCEL"] = "Canceling roll for %s from %s."
L["ROLL_END"] = "Ending roll for %s from %s."
L["ROLL_IGNORING_BID"] = "Ignoring bid from %s for %s, because you chatted before -> Bid: %s or %s."
L["ROLL_LIST_EMPTY"] = "Active rolls will be shown here"
L["ROLL_START"] = "Starting roll for %s from %s."
L["ROLL_STATUS_0"] = "Pending"
L["ROLL_STATUS_1"] = "Running"
L["ROLL_STATUS_-1"] = "Canceled"
L["ROLL_STATUS_2"] = "Done"
L["ROLL_TRADED"] = "Traded"
L["ROLL_WHISPER_SUPPRESSED"] = "Bid from %s for %s -> %s / %s."
L["ROLL_WINNER_MASTERLOOT"] = "%s has won %s from %s."
L["ROLL_WINNER_OTHER"] = "%s has won %s from you -> %s."
L["ROLL_WINNER_OWN"] = "You have won your own %s."
L["ROLL_WINNER_SELF"] = "You have won %s from %s -> %s."
L["TRADE_CANCEL"] = "Canceling trade with %s."
L["TRADE_START"] = "Starting trade with %s."

-- Globals
LOOT_ROLL_INELIGIBLE_REASONPLR_NO_ADDON = "The owner of this item doesn't use the PersoLootRoll addon."
LOOT_ROLL_INELIGIBLE_REASONPLR_NO_DISENCHANT = "The owner of this item has not allowed \"Disenchant\" bids."
LOOT_ROLL_INELIGIBLE_REASONPLR_NOT_ENCHANTER = "Your character doesn't have the \"Enchanting\" profession."

-- Other
L["ID"] = ID
L["ITEMS"] = ITEMS
L["LEVEL"] = LEVEL
L["STATUS"] = STATUS
L["TARGET"] = TARGET
L["ROLL_BID_1"] = NEED
L["ROLL_BID_2"] = GREED
L["ROLL_BID_3"] = ROLL_DISENCHANT
L["ROLL_BID_4"] = PASS
