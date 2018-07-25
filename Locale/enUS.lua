local Name, Addon = ...
local Locale = Addon.Locale
local lang = "enUS"

-- Chat messages
local L = {lang = lang}
setmetatable(L, Locale.MT)
Locale[lang] = L

L["MSG_BID"] = "Do you need that %s?"
L["MSG_HER"] = "her"
L["MSG_HIM"] = "him"
L["MSG_ITEM"] = "item"
L["MSG_ROLL_ANSWER_AMBIGUOUS"] = "I am giving away multiple items right now, please send me the link of the item you want."
L["MSG_ROLL_ANSWER_BID"] = "Ok, I registered your bid for %s."
L["MSG_ROLL_ANSWER_NO_OTHER"] = "Sorry, I already gave it to someone else."
L["MSG_ROLL_ANSWER_NO_SELF"] = "Sorry, I need that myself."
L["MSG_ROLL_ANSWER_NOT_TRADABLE"] = "Sorry, I can't trade it."
L["MSG_ROLL_ANSWER_YES_MASTERLOOT"] = "You can have it, just trade <%s>."
L["MSG_ROLL_ANSWER_YES"] = "You can have it, just trade me."
L["MSG_ROLL_START_MASTERLOOT"] = "Giving away %s from <%s> -> /w me or /roll %d!"
L["MSG_ROLL_START"] = "Giving away %s -> /w me or /roll %d!"
L["MSG_ROLL_WINNER_MASTERLOOT"] = "<%s> has won %s from <%s> -> Trade %s!"
L["MSG_ROLL_WINNER_WHISPER_MASTERLOOT"] = "You have won %s from <%s>! Please trade %s."
L["MSG_ROLL_WINNER_WHISPER"] = "You have won %s! Please trade me."
L["MSG_ROLL_WINNER"] = "<%s> has won %s -> Trade me!"

-- Addon
local L = LibStub("AceLocale-3.0"):NewLocale(Name, lang, lang == Locale.FALLBACK)
if not L then return end

LOOT_ROLL_INELIGIBLE_REASONPLR_NO_ADDON = "The owner of this item doesn't use the PersoLootRoll addon."
LOOT_ROLL_INELIGIBLE_REASONPLR_NO_DISENCHANT = "The PersoLootRoll addon doesn't support disenchanting."

L["ACTION"] = "Action"
L["ACTIONS"] = "Actions"
L["ADVERTISE"] = "Advertise in chat"
L["ANSWER"] = "Answer"
L["ASK"] = "Ask"
L["AWARD_LOOT"] = "Award loot"
L["AWARD_RANDOMLY"] = "Award randomly"
L["AWARD"] = "Award"
L["DISABLED"] = "Disabled"
L["DOWN"] = "down"
L["ENABLED"] = "Enabled"
L["EQUIPPED"] = "Equipped"
L["GET_FROM"] = "Get from"
L["GIVE_TO"] = "Give to"
L["GUILD_MASTER"] = "Guild Master"
L["GUILD_OFFICER"] = "Guild Officer"
L["HIDE_ALL"] = "Hide all"
L["HIDE"] = "Hide"
L["ID"] = ID
L["ITEM"] = "Item"
L["ITEM_LEVEL"] = "Item-Level"
L["ITEMS"] = ITEMS
L["LEFT"] = "left"
L["LEVEL"] = LEVEL
L["MASTERLOOTER"] = "Masterlooter"
L["MESSAGE"] = "Message"
L["ML"] = "ML"
L["BID"] = "Bid"
L["ITEM"] = "item"
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
L["SHOW_HIDE"] = "Show/Hide"
L["SHOW"] = "Show"
L["STATUS"] = STATUS
L["TARGET"] = TARGET
L["TRADE"] = "Trade"
L["UP"] = "up"
L["VOTE_WITHDRAW"] = "Withdraw"
L["VOTE"] = "Vote"
L["VOTES"] = "Votes"
L["WINNER"] = "Winner"
L["WON"] = "Won"
L["YOUR_BID"] = "Your bid"

L["HELP"] = [=[Start rolls and bid for items (/PersoLootRoll or /plr).
Usage:
/plr: Open options window
/plr roll [item]* (<timeout> <owner>): Start a roll for one or more item(s)
/plr bid <owner> ([item]): Bid for an item from another player
/plr options: Open options window
/plr config: Change settings through the command line
/plr help: Print this help message
Legend: [..] = item link, * = one or more times, (..) = optional]=]
L["USAGE_ROLL"] = "Usage: /plr roll [item]* (<timeout> <owner>)"
L["USAGE_BID"] = "Usage: /plr bid <owner> ([item])"

L["VERSION_NOTICE"] = "There's a new version of this addon available. Please update to stay compatible with everyone and not miss out on any loot!"

L["ROLL_AWARDED"] = "Awarded"
L["ROLL_BID_1"] = NEED
L["ROLL_BID_2"] = GREED
L["ROLL_BID_3"] = ROLL_DISENCHANT
L["ROLL_BID_4"] = PASS
L["ROLL_CANCEL"] = "Canceling roll for %s from %s."
L["ROLL_END"] = "Ending roll for %s from %s."
L["ROLL_IGNORING_BID"] = "Ignoring bid from %s for %s, because you chatted before -> Bid: %s or %s."
L["ROLL_LIST_EMPTY"] = "Active rolls will be shown here"
L["ROLL_START"] = "Starting roll for %s from %s."
L["ROLL_STATUS_-1"] = "Canceled"
L["ROLL_STATUS_0"] = "Pending"
L["ROLL_STATUS_1"] = "Running"
L["ROLL_STATUS_2"] = "Done"
L["ROLL_TRADED"] = "Traded"
L["ROLL_WHISPER_SUPPRESSED"] = "Bid from %s for %s -> %s / %s."
L["ROLL_WINNER_MASTERLOOT"] = "%s has won %s from %s."
L["ROLL_WINNER_OTHER"] = "%s has won %s from you -> %s."
L["ROLL_WINNER_OWN"] = "You have won your own %s."
L["ROLL_WINNER_SELF"] = "You have won %s from %s -> %s."

L["BID_CHAT"] = "Asking %s for %s -> %s."
L["BID_MAX_WHISPERS"] = "Won't ask %s for %s, because %d players in your group already asked -> %s."
L["BID_NO_CHAT"] = "Won't ask %s for %s, because it is disabled for the group or target -> %s."
L["BID_PASS"] = "Passing on %s from %s."
L["BID_START"] = "Bidding with %q for %s from %s."

L["TRADE_START"] = "Starting trade with %s."
L["TRADE_CANCEL"] = "Canceling trade with %s."

L["MASTERLOOTER_SELF"] = "You are now the masterlooter."
L["MASTERLOOTER_OTHER"] = "%s is now your masterlooter."

L["FILTER"] = "Filter"
L["FILTER_ALL"] = "For all players"
L["FILTER_ALL_DESC"] = "Include rolls for all players, not just yours or those with items that might interest you."
L["FILTER_DONE"] = "Done"
L["FILTER_DONE_DESC"] = "Include rolls that have ended."
L["FILTER_AWARDED"] = "Awarded"
L["FILTER_AWARDED_DESC"] = "Include rolls that have been won by someone."
L["FILTER_TRADED"] = "Traded"
L["FILTER_TRADED_DESC"] = "Include rolls whose items have been traded."
L["FILTER_HIDDEN"] = "Hidden"
L["FILTER_HIDDEN_DESC"] = "Include canceled, pending, passed and hidden rolls."

L["TIP_ADDON_MISSING"] = "Addon missing:"
L["TIP_ADDON_VERSIONS"] = "Addon versions:"
L["TIP_ENABLE_WHISPER_ASK"] = "Tip: Right-Click to enable asking for loot automatically"
L["TIP_MASTERLOOT_START"] = "Become or search for a masterlooter"
L["TIP_MASTERLOOT_STOP"] = "Remove masterlooter"
L["TIP_MASTERLOOT"] = "Masterloot is active"
L["TIP_MASTERLOOTING"] = "Masterlooting group:"
L["TIP_MINIMAP_ICON"] = "|cffffff78Left-Click:|r Toggle rolls window\n|cffffff78Right-Click:|r Show Options"
L["TIP_VOTES"] = "Votes from:"
L["TIP_MASTERLOOT_INFO"] = [=[|cffffff78Masterlooter:|r %s
|cffffff78Roll time:|r %ds (+ %ds per item)
|cffffff78Council:|r %s
|cffffff78Bids:|r %s
|cffffff78Votes:|r %s]=]

L["MENU_MASTERLOOT_START"] = "Become masterlooter"
L["MENU_MASTERLOOT_SEARCH"] = "Search group for a masterlooter"

L["DIALOG_MASTERLOOT_ASK"] = "<%s> wants to become your masterlooter."
L["DIALOG_ROLL_CANCEL"] = "Do you want to cancel this roll?"
L["DIALOG_ROLL_RESTART"] = "Do you want to restart this roll?"

L["ERROR_CMD_UNKNOWN"] = "Unknown command '%s'"
L["ERROR_ITEM_NOT_TRADABLE"] = "You cannot trade that item."
L["ERROR_NOT_IN_GROUP"] = "You are not in a group or raid."
L["ERROR_PLAYER_NOT_FOUND"] = "Cannot find player %s."
L["ERROR_ROLL_BID_UNKNOWN_OTHER"] = "%s has send an invalid bid for %s."
L["ERROR_ROLL_BID_UNKNOWN_SELF"] = "That's not a valid bid."
L["ERROR_ROLL_STATUS_NOT_0"] = "The roll has already been started or finished."
L["ERROR_ROLL_STATUS_NOT_1"] = "The roll is not running."
L["ERROR_ROLL_UNKNOWN"] = "That roll doesn't exist."

-- Options: Home

L["OPT_INFO"] = "Information"
L["OPT_INFO_DESC"] = "Some information about this addon."
L["OPT_VERSION"] = "|cffffd100Version:|r %s"
L["OPT_AUTHOR"] = "|cffffd100Author:|r Shrugal (EU-Mal'Ganis)"
L["OPT_TRANSLATION"] = "|cffffd100Translation:|r Shrugal (EU-Mal'Ganis)"
L["OPT_ENABLE"] = "Enable"
L["OPT_ENABLE_DESC"] = "Enable or disable the addon"
L["OPT_ONLY_MASTERLOOT"] = "Only masterloot"
L["OPT_ONLY_MASTERLOOT_DESC"] = "Only activate the addon when using masterloot (e.g. with your guild)"
L["OPT_DONT_SHARE"] = "Don't share loot"
L["OPT_DONT_SHARE_DESC"] = "Don't roll on loot from others and don't share your own loot. The addon will deny incoming requests for your loot (if enabled), and you can still be masterlooter and loot council member."
L["OPT_AWARD_SELF"] = "Choose winner of your items yourself"
L["OPT_AWARD_SELF_DESC"] = "Choose for yourself who should get your loot, instead of letting the addon randomly pick someone. This is always enabled when you are a masterlooter."
L["OPT_BID_PUBLIC"] = "Bids public"
L["OPT_BID_PUBLIC_DESC"] = "Bids on your rolls are public, so everyone with the addon can see them."

L["OPT_UI"] = "User interface"
L["OPT_UI_DESC"] = "Customize %s's look and feel to your liking."
L["OPT_MINIMAP_ICON"] = "Show minimap icon"
L["OPT_MINIMAP_ICON_DESC"] = "Show or hide the minimap icon."
L["OPT_ROLL_FRAMES"] = "Show roll frames"
L["OPT_ROLL_FRAMES_DESC"] = "Show the roll frames when someone loots something you might be interested in, so you can roll for it."
L["OPT_ROLLS_WINDOW"] = "Show rolls window"
L["OPT_ROLLS_WINDOW_DESC"] = "Always show the rolls window (with all rolls on it) when someone loots something you might be interested in. This is always enabled when you are a masterlooter."
L["OPT_ACTIONS_WINDOW"] = "Show actions window"
L["OPT_ACTIONS_WINDOW_DESC"] = "Show the actions window when there are pending actions, e.g. when you won an item and need to trade someone to get it."
L["OPT_ACTIONS_WINDOW_MOVE"] = "Move"
L["OPT_ACTIONS_WINDOW_MOVE_DESC"] = "Move the actions window around."

L["OPT_ITEM_FILTER"] = "Item Filter"
L["OPT_ITEM_FILTER_DESC"] = "Change which items you are asked to roll on."
L["OPT_ILVL_THRESHOLD"] = "Item-level threshold"
L["OPT_ILVL_THRESHOLD_DESC"] = "Items that are more than this many item levels below yours are ignored."
L["OPT_ILVL_THRESHOLD_TRINKETS"] = "Double threshold for trinkets"
L["OPT_ILVL_THRESHOLD_TRINKETS_DESC"] = "Trinkets should have double the normal threshold because proc effects can make their value vary by a large amount."
L["OPT_SPECS"] = "Specializations"
L["OPT_SPECS_DESC"] = "Only suggest loot for these class specializations."
L["OPT_TRANSMOG"] = "Check transmog appearance"
L["OPT_TRANSMOG_DESC"] = "Roll on items that you don't have the appearance of yet."

-- Options: Messages

L["OPT_MESSAGES"] = "Messages"
L["OPT_ECHO"] = "Chat information"
L["OPT_ECHO_DESC"] = [=[How much information do you want to see from the addon in chat?

|cffffff78None:|r No info in chat.
|cffffff78Error:|r Only error messages.
|cffffff78Info:|r Errors and useful info that you probably want to act on.
|cffffff78Verbose:|r Get notices about pretty much anything the addon does.
|cffffff78Debug:|r Same as verbose, plus additional debug info.]=]
L["OPT_ECHO_NONE"] = "None"
L["OPT_ECHO_ERROR"] = "Error"
L["OPT_ECHO_INFO"] = "Info"
L["OPT_ECHO_VERBOSE"] = "Verbose"
L["OPT_ECHO_DEBUG"] = "Debug"

L["OPT_SHOULD_CHAT"] = "Enable/Disable"
L["OPT_SHOULD_CHAT_DESC"] = "Define when the addon will post to party/raid chat and whisper other players."
L["OPT_GROUPCHAT"] = "Group Chat"
L["OPT_GROUPCHAT_DESC"] = "Change whether or not the addon will post things to the group chat."
L["OPT_GROUPCHAT_ANNOUNCE"] = "Announce rolls and winners"
L["OPT_GROUPCHAT_ANNOUNCE_DESC"] = "Announce your rolls and winners of your rolls in group chat."
L["OPT_GROUPCHAT_GROUP_TYPE"] = "Announce by group type"
L["OPT_GROUPCHAT_GROUP_TYPE_DESC"] = "Post to group chat only if you are in one of these group types.\n\n|cffffff78Guild Group:|r Someone from a guild whose members make up 80% or more of the group."
L["OPT_GROUPCHAT_ROLL"] = "Roll on loot in chat"
L["OPT_GROUPCHAT_ROLL_DESC"] = "Roll on loot you want (/roll) if others post links in group chat."
L["OPT_WHISPER"] = "Whisper Chat"
L["OPT_WHISPER_DESC"] = "Change whether or not the addon will whisper other players and/or answer incoming messages."
L["OPT_WHISPER_ASK"] = "Ask for loot"
L["OPT_WHISPER_ASK_DESC"] = "Whisper others if they got loot you want."
L["OPT_WHISPER_ANSWER"] = "Answer requests"
L["OPT_WHISPER_ANSWER_DESC"] = "Let the addon answer whispers from group members about items you looted."
L["OPT_WHISPER_SUPPRESS"] = "Suppress requests"
L["OPT_WHISPER_SUPPRESS_DESC"] = "Suppress incoming whisper messages from eligible players when giving away your loot."
L["OPT_WHISPER_GROUP_TYPE"] = "Ask by group type"
L["OPT_WHISPER_GROUP_TYPE_DESC"] = "Ask for loot only if you are in one of these group types.\n\n|cffffff78Guild Group:|r Someone from a guild whose members make up 80% or more of the group."
L["OPT_WHISPER_TARGET"] = "Ask by target"
L["OPT_WHISPER_TARGET_DESC"] = "Ask for loot depending on whether the target is in your guild or on your friend list."

L["OPT_CUSTOM_MESSAGES"] = "Custom messages"
L["OPT_CUSTOM_MESSAGES_DESC"] = "You can reorder placeholders (|cffffff78%s|r, |cffffff78%d|r) by adding their position and a $ sign in the middle, so e.g. |cffffff78%2$s|r instead of |cffffff78%s|r for the 2nd placeholder. See tooltips for details."
L["OPT_CUSTOM_MESSAGES_DEFAULT"] = "Default language (%s)"
L["OPT_CUSTOM_MESSAGES_DEFAULT_DESC"] = "These messages will be used when the recipient speaks %s or something other than your realm's default language (%s)."
L["OPT_CUSTOM_MESSAGES_LOCALIZED"] = "Realm language (%s)"
L["OPT_CUSTOM_MESSAGES_LOCALIZED_DESC"] = "These messages will be used when the recipient speaks your realm's default language (%s)."
L["OPT_MSG_ROLL_START"] = "Announcing a new roll"
L["OPT_MSG_ROLL_START_DESC"] = "1: Item link\n2: Roll number"
L["OPT_MSG_ROLL_START_MASTERLOOT"] = "Announcing a new roll (as masterlooter)"
L["OPT_MSG_ROLL_START_MASTERLOOT_DESC"] = "1: Item link\n2: Item owner\n3: Roll number"
L["OPT_MSG_ROLL_WINNER"] = "Announcing a roll winner"
L["OPT_MSG_ROLL_WINNER_DESC"] = "1: Winner\n2: Item link"
L["OPT_MSG_ROLL_WINNER_MASTERLOOT"] = "Announcing a roll winner (as masterlooter)"
L["OPT_MSG_ROLL_WINNER_MASTERLOOT_DESC"] = "1: Winner\n2: Item link\n3: Item owner\n4: him/her"
L["OPT_MSG_ROLL_WINNER_WHISPER"] = "Whispering the roll winner"
L["OPT_MSG_ROLL_WINNER_WHISPER_DESC"] = "1: Item link"
L["OPT_MSG_ROLL_WINNER_WHISPER_MASTERLOOT"] = "Whispering the roll winner (as masterlooter)"
L["OPT_MSG_ROLL_WINNER_WHISPER_MASTERLOOT_DESC"] = "1: Item link\n2: Item owner\n3: him/her"
L["OPT_MSG_BID"] = "Bidding on an item from another player"
L["OPT_MSG_BID_DESC"] = "1: Item link"
L["OPT_MSG_ROLL_ANSWER_BID"] = "Answer: Bid registered"
L["OPT_MSG_ROLL_ANSWER_BID_DESC"] = "1: Item link"
L["OPT_MSG_ROLL_ANSWER_YES"] = "Answer: You can have it"
L["OPT_MSG_ROLL_ANSWER_YES_DESC"] = ""
L["OPT_MSG_ROLL_ANSWER_YES_MASTERLOOT"] = "Answer: You can have it (as masterlooter)"
L["OPT_MSG_ROLL_ANSWER_YES_MASTERLOOT_DESC"] = "1: Item owner"
L["OPT_MSG_ROLL_ANSWER_NO_SELF"] = "Answer: I need it myself"
L["OPT_MSG_ROLL_ANSWER_NO_SELF_DESC"] = ""
L["OPT_MSG_ROLL_ANSWER_NO_OTHER"] = "Answer: I gave it to someone else"
L["OPT_MSG_ROLL_ANSWER_NO_OTHER_DESC"] = ""
L["OPT_MSG_ROLL_ANSWER_NOT_TRADABLE"] = "Answer: It's not tradable"
L["OPT_MSG_ROLL_ANSWER_NOT_TRADABLE_DESC"] = ""
L["OPT_MSG_ROLL_ANSWER_AMBIGUOUS"] = "Answer: Send me the item link"
L["OPT_MSG_ROLL_ANSWER_AMBIGUOUS_DESC"] = ""

-- Options: Masterloot

L["OPT_MASTERLOOT"] = "Masterloot"
L["OPT_MASTERLOOT_DESC"] = "When you (or someone else) becomes masterlooter, all loot will be distributed by that person. You will get a notice about who's items you won or who won your items, so you can trade them to the right person."
L["OPT_MASTERLOOT_START"] = "Become masterlooter"
L["OPT_MASTERLOOT_SEARCH"] = "Search masterlooter"
L["OPT_MASTERLOOT_STOP"] = "Stop masterloot"
L["OPT_MASTERLOOT_APPROVAL"] = "Approval"
L["OPT_MASTERLOOT_APPROVAL_DESC"] = "Here you can define who can become your masterlooter."
L["OPT_MASTERLOOT_ALLOW"] = "Allow becoming masterlooter"
L["OPT_MASTERLOOT_ALLOW_DESC"] = "Choose who can request to become your masterlooter. You will still get a popup message asking you to confirm it, so you can decline a masterlooter request when it happens.\n\n|cffffff78Guild Group:|r Someone from a guild whose members make up 80% or more of the group."
L["OPT_MASTERLOOT_WHITELIST"] = "Masterlooter Whitelist"
L["OPT_MASTERLOOT_WHITELIST_DESC"] = "You can also name specific players who should be able to become your masterlooter. Separate multiple names with spaces or commas."
L["OPT_MASTERLOOT_ALLOW_ALL"] = "Allow everbody"
L["OPT_MASTERLOOT_ALLOW_ALL_DESC"] = "|cffff0000WARNING:|r This will allow everybody to request becoming your masterlooter and potentially scam you into giving away your loot! Only activate it if you know what you are doing."
L["OPT_MASTERLOOT_ACCEPT"] = "Automatically accept masterlooter"
L["OPT_MASTERLOOT_ACCEPT_DESC"] = "Automatically accept masterlooter requests from these players."

L["OPT_MASTERLOOTER"] = "Rules"
L["OPT_MASTERLOOTER_DESC"] = "These options apply to everybody when you are the masterlooter."
L["OPT_MASTERLOOTER_BID_PUBLIC"] = "Bids public"
L["OPT_MASTERLOOTER_BID_PUBLIC_DESC"] = "You can make bids public, so everybody can see who bid on what."
L["OPT_MASTERLOOTER_TIMEOUT_BASE"] = "Roll time (base)"
L["OPT_MASTERLOOTER_TIMEOUT_BASE_DESC"] = "The base running time for rolls, regardless of how many items have dropped."
L["OPT_MASTERLOOTER_TIMEOUT_PER_ITEM"] = "Roll time (per item)"
L["OPT_MASTERLOOTER_TIMEOUT_PER_ITEM_DESC"] = "Will be added to the base roll running time for each item that dropped."
L["OPT_MASTERLOOTER_NEED_ANSWERS"] = "Custom 'Need' answers"
L["OPT_MASTERLOOTER_NEED_ANSWERS_DESC"] = "Specify up to 9 custom answers when rolling 'Need', with decreasing priority. You can also insert '%s' itself to lower its priority below the prior answers. Separate multiple entries with Commas.\n\nThey can be accessed by right-clicking on the 'Need' button when rolling on loot."
L["OPT_MASTERLOOTER_GREED_ANSWERS"] = "Custom 'Greed' answers"
L["OPT_MASTERLOOTER_GREED_ANSWERS_DESC"] = "Specify up to 9 custom answers when rolling 'Greed', with decreasing priority. You can also insert '%s' itself to lower its priority below the prior answers. Separate multiple entries with Commas.\n\nThey can be accessed by right-clicking on the 'Greed' button when rolling on loot."
L["OPT_MASTERLOOTER_COUNCIL"] = "Council"
L["OPT_MASTERLOOTER_COUNCIL_DESC"] = "Players on your loot council can vote on who should get the loot."
L["OPT_MASTERLOOTER_COUNCIL_ALLOW"] = "Council members"
L["OPT_MASTERLOOTER_COUNCIL_ALLOW_DESC"] = "Which players should automatically become part of your council."
L["OPT_MASTERLOOTER_COUNCIL_GUILD_RANK"] = "Council guild rank"
L["OPT_MASTERLOOTER_COUNCIL_GUILD_RANK_DESC"] = "Add members of this guild rank to you council, in addition to the options above."
L["OPT_MASTERLOOTER_COUNCIL_WHITELIST"] = "Council whitelist"
L["OPT_MASTERLOOTER_COUNCIL_WHITELIST_DESC"] = "You can also name specific players to be on your council. Separate multiple names with spaces or commas."
L["OPT_MASTERLOOTER_VOTE_PUBLIC"] = "Council votes public"
L["OPT_MASTERLOOTER_VOTE_PUBLIC_DESC"] = "You can make council votes public, so everybody can see who has how many votes."