local Name, Addon = ...
local Locale = Addon.Locale
local lang = "zhTW"

-- Chat messages
local L = {lang = lang}
setmetatable(L, Locale.MT)
Locale[lang] = L

L["MSG_BID"] = "你有需要%s嗎？"
L["MSG_HER"] = "她"
L["MSG_HIM"] = "他"
L["MSG_ITEM"] = "物品"
L["MSG_ROLL_ANSWER_AMBIGUOUS"] = "我現在正在捐贈多件物品，請將您想要物品的連結發給我。"
L["MSG_ROLL_ANSWER_BID"] = "OK，我已經為%s註冊了你的競標。"
L["MSG_ROLL_ANSWER_NO_OTHER"] = "抱歉！我已經把它交易給別人了。"
L["MSG_ROLL_ANSWER_NO_SELF"] = "抱歉，我自己也需要。"
L["MSG_ROLL_ANSWER_NOT_TRADABLE"] = "抱歉，我無法交易它。"
L["MSG_ROLL_ANSWER_YES_MASTERLOOT"] = "你可以擁有它，只要交易 <%s>。"
L["MSG_ROLL_ANSWER_YES"] = "你可以擁有它，來跟我交易。"
L["MSG_ROLL_START_MASTERLOOT"] = "放棄 %s 從 <%s> -> /w 我或 /roll %d！"
L["MSG_ROLL_START"] = "放棄 %s -> /w 我 或 /roll %d！"
L["MSG_ROLL_WINNER_MASTERLOOT"] = "<%s>已經贏得 %s 從<%s> -> 交易 %s！"
L["MSG_ROLL_WINNER_WHISPER_MASTERLOOT"] = "你已經贏得 %s 從<%s>！請交易 %s。"
L["MSG_ROLL_WINNER_WHISPER"] = "你已經贏得 %s！請跟我交易。"
L["MSG_ROLL_WINNER"] = "<%s> 已贏得 %s -> 來跟我交易！"

-- Addon
local L = LibStub("AceLocale-3.0"):NewLocale(Name, lang, lang == Locale.DEFAULT)
if not L then return end

LOOT_ROLL_INELIGIBLE_REASONPLR_NO_ADDON = "物品的贏家並沒有使用PersoLootRoll插件。"
LOOT_ROLL_INELIGIBLE_REASONPLR_NO_DISENCHANT = "PersoLootRoll插件不支援附魔分解。"

L["ACTION"] = "Action" -- Translation missing
L["ACTIONS"] = "動作"
L["ADVERTISE"] = "在聊天中廣播"
L["ANSWER"] = "Answer" -- Translation missing
L["ASK"] = "Ask" -- Translation missing
L["AWARD_LOOT"] = "獎勵拾取"
L["AWARD_RANDOMLY"] = "隨機獎勵"
L["AWARD"] = "獎勵"
L["DISABLED"] = "停用"
L["DOWN"] = "down" -- Translation missing
L["ENABLED"] = "啟用"
L["EQUIPPED"] = "Equipped" -- Translation missing
L["GET_FROM"] = "Get from" -- Translation missing
L["GIVE_TO"] = "Give to" -- Translation missing
L["GUILD_MASTER"] = "公會會長"
L["GUILD_OFFICER"] = "公會幹部"
L["HIDE_ALL"] = "Hide all" -- Translation missing
L["HIDE"] = "Hide" -- Translation missing
L["ID"] = ID
L["ITEM"] = "物品"
L["ITEM_LEVEL"] = "物品等級"
L["ITEMS"] = ITEMS
L["LEFT"] = "left" -- Translation missing
L["LEVEL"] = LEVEL
L["MASTERLOOTER"] = "拾取分配者"
L["MESSAGE"] = "Message" -- Translation missing
L["ML"] = "分配者"
L["MSG_BID"] = "拍裝"
L["MSG_ITEM"] = "物品"
L["OWNER"] = "擁有者"
L["PLAYER"] = "玩家"
L["PRIVATE"] = "私人"
L["PUBLIC"] = "公開"
L["RAID_ASSISTANT"] = "團隊助理"
L["RAID_LEADER"] = "團隊領隊"
L["RESTART"] = "重新開始"
L["RIGHT"] = "right" -- Translation missing
L["ROLL"] = "Roll" -- Translation missing
L["ROLLS"] = "擲骰"
L["SECONDS"] = "%ds" -- Translation missing
L["SET_ANCHOR"] = "Set anchor: Grow %s and %s" -- Translation missing
L["SHOW_HIDE"] = "Show/Hide" -- Translation missing
L["SHOW"] = "Show" -- Translation missing
L["STATUS"] = STATUS
L["TARGET"] = TARGET
L["TRADE"] = "Trade" -- Translation missing
L["UP"] = "up" -- Translation missing
L["VOTE_WITHDRAW"] = "收回"
L["VOTE"] = "投票"
L["VOTES"] = "投票"
L["WINNER"] = "贏家"
L["WON"] = "Won" -- Translation missing
L["YOUR_BID"] = "你的競標"

L["HELP"] = [=[開始物品的擲骰或競標（/PersoLootRoll or /plr）。
使用方法：
/plr: 開啟選項視窗
/plr roll [item]* (<timeout> <owner>): 開始一個或多個物品的擲骰
/plr bid <owner> ([item]): 競標來自其他玩家的物品
/plr options: 開啟選項視窗
/plr config: 透過指令更改設置
/plr help: 發送此幫助訊息
解釋: [..] = 物品連結, * = 一個或多個物品， (..) = 任選的]=]
L["USAGE_BID"] = "使用：/plr bid <擁有者> ([物品])"
L["USAGE_ROLL"] = "使用：/plr roll [item]* (<持續時間> <擁有者>)"

L["VERSION_NOTICE"] = "插件已經有新的版本，請更新以保持跟所有人的相容性，才不會錯過任何戰利品！"

L["ROLL_AWARDED"] = "已贏取"
L["ROLL_BID_1"] = NEED
L["ROLL_BID_2"] = GREED
L["ROLL_BID_3"] = ROLL_DISENCHANT
L["ROLL_BID_4"] = PASS
L["ROLL_CANCEL"] = "取消擲骰在%s 從%s。"
L["ROLL_END"] = "結束擲骰在%s 從%s。"
L["ROLL_IGNORING_BID"] = "忽略%s對%s的競標，因為之前已經聊過了 -> 競標: %s 或 %s。"
L["ROLL_LIST_EMPTY"] = "Active rolls will be shown here" -- Translation missing
L["MSG_ROLL_START"] = "開始擲骰在%s 從%s。"
L["ROLL_STATUS_-1"] = "已取消"
L["ROLL_STATUS_0"] = "等待中"
L["ROLL_STATUS_1"] = "運作中"
L["ROLL_STATUS_2"] = "完成"
L["ROLL_TRADED"] = "已交易"
L["ROLL_WHISPER_SUPPRESSED"] = "Bid from %s for %s -> %s / %s." -- Translation missing
L["MSG_ROLL_WINNER_MASTERLOOT"] = "%s已經贏得%s 從%s。"
L["ROLL_WINNER_OTHER"] = "%s已經從你這贏得%s -> %s。 "
L["ROLL_WINNER_OWN"] = "你贏得了自己得到的%s。"
L["ROLL_WINNER_SELF"] = "你已經贏得%s 從%s -> %s。"

L["BID_CHAT"] = "詢問%s為%s -> %s。"
L["BID_NO_CHAT"] = "密語已禁用，你需要詢問%s為%s你自己 -> %s。"
L["BID_PASS"] = "放棄%s 由%s。"
L["BID_START"] = "競標%q 在%s 從%s。"

L["TRADE_START"] = "與%s開始交易。"
L["TRADE_CANCEL"] = "與%s取消交易。"

L["MASTERLOOTER_SELF"] = "你現在是拾取分配者"
L["MASTERLOOTER_OTHER"] = "%s現在是你的拾取分配者。"

L["FILTER"] = "過濾器"
L["FILTER_ALL"] = "所有玩家"
L["FILTER_ALL_DESC"] = "包含所有玩家的擲骰，並非只有你的或是你感興趣的物品。"
L["FILTER_DONE"] = "已結束"
L["FILTER_DONE_DESC"] = "包含已經結束的擲骰。"
L["FILTER_AWARDED"] = "已贏取"
L["FILTER_AWARDED_DESC"] = "包含已經被某人贏取的。"
L["FILTER_TRADED"] = "已交易"
L["FILTER_TRADED_DESC"] = "包含物品已經交易的擲骰。"
L["FILTER_HIDDEN"] = "Hidden" -- Translation missing
L["FILTER_HIDDEN_DESC"] = "Include canceled, pending, passed and hidden rolls." -- Translation missing

L["TIP_ADDON_MISSING"] = "Addon missing:" -- Translation missing
L["TIP_ADDON_VERSIONS"] = "Addon versions:" -- Translation missing
L["TIP_MASTERLOOT_START"] = "成為或搜尋一個拾取分配者"
L["TIP_MASTERLOOT_STOP"] = "移除拾取分配者"
L["TIP_MASTERLOOT"] = "隊長分配是啟用的"
L["TIP_MASTERLOOTING"] = "隊長分配的團體:"
L["TIP_MINIMAP_ICON"] = "|cffffff00左鍵點擊:|r 開關擲骰視窗\n|cffffff00右鍵點擊:|r 顯示選項"
L["TIP_VOTES"] = "投票從:"
L["TIP_MASTERLOOT_INFO"] = [=[|cffffff00拾取分配者:|r %s 
|cffffff00擲骰時間:|r %ds (+ %ds 每項物品) 
|cffffff00議會:|r %s |
cffffff00競標:|r %s 
|cffffff00投票:|r %s]=]

L["MENU_MASTERLOOT_START"] = "成為拾取分配者"
L["MENU_MASTERLOOT_SEARCH"] = "搜尋有拾取分配者的隊伍"

L["DIALOG_MASTERLOOT_ASK"] = "<%s>想成為你的拾取分配者。"
L["DIALOG_ROLL_CANCEL"] = "你想要取消這次擲骰嗎？"
L["DIALOG_ROLL_RESTART"] = "你想要重新開始擲骰嗎？"

L["ERROR_CMD_UNKNOWN"] = "未知指令'%s'"
L["ERROR_ITEM_NOT_TRADABLE"] = "你無法交易這項物品。"
L["ERROR_NOT_IN_GROUP"] = "你不在隊伍或團隊中。"
L["ERROR_PLAYER_NOT_FOUND"] = "無法找到玩家 %s。"
L["ERROR_ROLL_BID_UNKNOWN_OTHER"] = "%s已發送了%s的競標邀請。"
L["ERROR_ROLL_BID_UNKNOWN_SELF"] = "這不是有效的競標。"
L["ERROR_ROLL_STATUS_NOT_0"] = "此擲骰已經開始或是結束。"
L["ERROR_ROLL_STATUS_NOT_1"] = "此擲骰並沒有運作。"
L["ERROR_ROLL_UNKNOWN"] = "此擲骰不存在。"

L["OPT_ENABLE"] = "啟用"
L["OPT_ENABLE_DESC"] = "啟用或停用此插件"
L["OPT_INFO"] = "資訊"
L["OPT_INFO_DESC"] = "關於此插件的一些資訊。"
L["OPT_VERSION"] = "|cffffff00版本:|r %s"
L["OPT_AUTHOR"] = "|cffffff00作者:|r Shrugal-Mal'Ganis (EU)"
L["OPT_TRANSLATION"] = "|cffffff00翻譯:|r Shrugal-Mal'Ganis (EU)"
L["OPT_UI"] = "使用者介面"
L["OPT_UI_DESC"] = "根據自己的喜好自訂%s的外觀。"
L["OPT_MINIMAP_ICON"] = "顯示小地圖圖示"
L["OPT_MINIMAP_ICON_DESC"] = "顯示或隱藏小地圖圖示"
L["OPT_ROLL_FRAMES"] = "顯示擲骰框架"
L["OPT_ROLL_FRAMES_DESC"] = "當某人拾取你感興趣的戰利品時顯示擲骰框架，這樣你就可以骰它。"
L["OPT_ROLLS_WINDOW"] = "顯示擲骰視窗"
L["OPT_ROLLS_WINDOW_DESC"] = "當某人拾取你感興趣的戰利品時總是顯示擲骰視窗(所有的擲骰都在上面)。當你是拾取分配者時，始終啟用此功能。"
L["OPT_ACTIONS_WINDOW"] = "Show actions window" -- Translation missing
L["OPT_ACTIONS_WINDOW_DESC"] = "Show the actions window when there are pending actions, e.g. when you won an item and need to trade someone to get it." -- Translation missing
L["OPT_ACTIONS_WINDOW_MOVE"] = "Move" -- Translation missing
L["OPT_ACTIONS_WINDOW_MOVE_DESC"] = "Move the actions window around." -- Translation missing

L["OPT_MESSAGES"] = "訊息"
L["OPT_ECHO"] = "聊天資訊"
L["OPT_ECHO_DESC"] = [=[你想要在聊天中顯示多少插件的資訊？

|cffffff00無:|r 聊天中無資訊。 
|cffffff00錯誤:|r 只有錯誤訊息。 
|cffffff00資訊:|r 你可能會採取行動的錯誤與有用訊息。 
|cffffff00詳細:|r 獲取有關插件所做的任何事情的通知。
|cffffff00偵錯:|r 類似於詳細，但有額外偵錯訊息。]=]
L["OPT_ECHO_NONE"] = "無"
L["OPT_ECHO_ERROR"] = "錯誤"
L["OPT_ECHO_INFO"] = "資訊"
L["OPT_ECHO_VERBOSE"] = "詳細"
L["OPT_ECHO_DEBUG"] = "偵錯"

L["OPT_SHOULD_CHAT"] = "Enable/Disable" -- Translation missing
L["OPT_SHOULD_CHAT_DESC"] = "Define when the addon will post to group/raid chat and whisper other players." -- Translation missing
L["OPT_GROUPCHAT"] = "群聊"
L["OPT_GROUPCHAT_DESC"] = "更改插件是否要將內容發佈到團體中"
L["OPT_GROUPCHAT_ANNOUNCE"] = "公告擲骰以及贏家"
L["OPT_GROUPCHAT_ANNOUNCE_DESC"] = "在團體聊天中公告擲骰以及贏家。"
L["OPT_GROUPCHAT_ROLL"] = "在聊天中擲骰戰利品"
L["OPT_GROUPCHAT_ROLL_DESC"] = "如果其他人在團體聊天中貼出連結，請擲骰你要的戰利品(/roll)。"
L["OPT_WHISPER"] = "聊天密語"
L["OPT_WHISPER_DESC"] = "更改插件是否會密語其他玩家並且/或回應其他人的訊息。"
L["OPT_WHISPER_ANSWER"] = "回應密語"
L["OPT_WHISPER_ANSWER_DESC"] = "讓插件自動回應從隊伍/團隊成員來的關於你拾取物品的密語。"
L["OPT_WHISPER_SUPPRESS"] = "Suppress whispers" -- Translation missing
L["OPT_WHISPER_SUPPRESS_DESC"] = "Suppress incoming whisper messages from eligible players when giving away your loot." -- Translation missing
L["OPT_WHISPER_GROUP"] = "密語根據團體類型"
L["OPT_WHISPER_GROUP_DESC"] = "如果其他人拾取你想要的物品則密語他們，這取決於你目前所處的團體類型。"
L["OPT_WHISPER_TARGET"] = "密語目標"
L["OPT_WHISPER_TARGET_DESC"] = "如果其他人得到你想要的物品則密語他們，這取決於目標是否在你的公會或是好友名單上。"

L["OPT_CUSTOM_MESSAGES"] = "Custom messages" -- Translation missing
L["OPT_CUSTOM_MESSAGES_DESC"] = "The number and position of placeholders (|cffffff00%s|r, |cffffff00%d|r) cannot be changed currently, so make sure your custom lines match the default lines in this regard (see tooltips for details)." -- Translation missing
L["OPT_CUSTOM_MESSAGES_DEFAULT"] = "Default language (%s)" -- Translation missing
L["OPT_CUSTOM_MESSAGES_DEFAULT_DESC"] = "These messages will be used when the recipient speaks English or something other than your realm's default language (%s)." -- Translation missing
L["OPT_CUSTOM_MESSAGES_LOCALIZED"] = "Realm language (%s)" -- Translation missing
L["OPT_CUSTOM_MESSAGES_LOCALIZED_DESC"] = "These messages will be used when the recipient speaks your realm's default language (%s)." -- Translation missing
L["OPT_MSG_ROLL_START"] = "Announcing a new roll" -- Translation missing
L["OPT_MSG_ROLL_START_DESC"] = "%s: Item link\n%d: Roll number\n" -- Translation missing
L["OPT_MSG_ROLL_START_MASTERLOOT"] = "Announcing a new roll (as masterlooter)" -- Translation missing
L["OPT_MSG_ROLL_START_MASTERLOOT_DESC"] = "%s: Item link\n%s: Item owner\n%d: Roll number" -- Translation missing
L["OPT_MSG_ROLL_WINNER"] = "Announcing a roll winner" -- Translation missing
L["OPT_MSG_ROLL_WINNER_DESC"] = "%s: Winner\n%s: Item link" -- Translation missing
L["OPT_MSG_ROLL_WINNER_MASTERLOOT"] = "Announcing a roll winner (as masterlooter)" -- Translation missing
L["OPT_MSG_ROLL_WINNER_MASTERLOOT_DESC"] = "%s: Winner\n%s: Item link\n%s: Item owner\n%s: him/her" -- Translation missing
L["OPT_MSG_ROLL_WINNER_WHISPER"] = "Whispering the roll winner" -- Translation missing
L["OPT_MSG_ROLL_WINNER_WHISPER_DESC"] = "%s: Item link" -- Translation missing
L["OPT_MSG_ROLL_WINNER_WHISPER_MASTERLOOT"] = "Whispering the roll winner (as masterlooter)" -- Translation missing
L["OPT_MSG_ROLL_WINNER_WHISPER_MASTERLOOT_DESC"] = "%s: Item link\n%s: Item owner\n%s: him/her" -- Translation missing
L["OPT_MSG_BID"] = "Bidding on an item from another player" -- Translation missing
L["OPT_MSG_BID_DESC"] = "%s: Item link" -- Translation missing
L["OPT_MSG_ROLL_ANSWER_BID"] = "Answer: Bid registered" -- Translation missing
L["OPT_MSG_ROLL_ANSWER_BID_DESC"] = "%s: Item link" -- Translation missing
L["OPT_MSG_ROLL_ANSWER_YES"] = "Answer: You can have it" -- Translation missing
L["OPT_MSG_ROLL_ANSWER_YES_DESC"] = "" -- Translation missing
L["OPT_MSG_ROLL_ANSWER_YES_MASTERLOOT"] = "Answer: You can have it (as masterlooter)" -- Translation missing
L["OPT_MSG_ROLL_ANSWER_YES_MASTERLOOT_DESC"] = "%s: Item owner" -- Translation missing
L["OPT_MSG_ROLL_ANSWER_NO_SELF"] = "Answer: I need it myself" -- Translation missing
L["OPT_MSG_ROLL_ANSWER_NO_SELF_DESC"] = "" -- Translation missing
L["OPT_MSG_ROLL_ANSWER_NO_OTHER"] = "Answer: I gave it to someone else" -- Translation missing
L["OPT_MSG_ROLL_ANSWER_NO_OTHER_DESC"] = "" -- Translation missing
L["OPT_MSG_ROLL_ANSWER_NOT_TRADABLE"] = "Answer: It's not tradable" -- Translation missing
L["OPT_MSG_ROLL_ANSWER_NOT_TRADABLE_DESC"] = "" -- Translation missing
L["OPT_MSG_ROLL_ANSWER_AMBIGUOUS"] = "Answer: Send me the item link" -- Translation missing
L["OPT_MSG_ROLL_ANSWER_AMBIGUOUS_DESC"] = "" -- Translation missing

L["OPT_AWARD_SELF"] = "自行選擇贏家"
L["OPT_AWARD_SELF_DESC"] = "自行選擇誰該得到你的戰利品，而非讓插件隨機選擇，當你是拾取分配者時，始終啟用此功能。"
L["OPT_ITEM_FILTER"] = "物品過濾器"
L["OPT_ITEM_FILTER_DESC"] = "自訂宣告對你有用物品的規則。你只會被要求擲骰有用的物品。"
L["OPT_ILVL_THRESHOLD"] = "物品等級門檻"
L["OPT_ILVL_THRESHOLD_DESC"] = "物品可以低於你覺得有用的物品等級，飾品為雙倍。"
L["OPT_ILVL_THRESHOLD_TRINKETS"] = "Double threshold for trinkets" -- Translation missing
L["OPT_ILVL_THRESHOLD_TRINKETS_DESC"] = "Trinkets should have double the normal threshold because proc effects can make their value vary by a large amount." -- Translation missing
L["OPT_SPECS"] = "專精"
L["OPT_SPECS_DESC"] = "只建議這些職業專精的戰利品。"
L["OPT_TRANSMOG"] = "檢查塑形外觀"
L["OPT_TRANSMOG_DESC"] = "擲骰那些你還未擁有外觀的物品。"

L["OPT_MASTERLOOT"] = "拾取分配"
L["OPT_MASTERLOOT_DESC"] = "當你(或其他人)成為拾取分配者，所有戰利品都將由此人分發。你會收到你贏得什麼物品以及誰贏的你的物品的通知，因此你可以交易物品給合適的人。"
L["OPT_MASTERLOOT_START"] = "成為拾取分配者"
L["OPT_MASTERLOOT_SEARCH"] = "搜尋拾取分配者"
L["OPT_MASTERLOOT_STOP"] = "停止拾取分配"
L["OPT_MASTERLOOT_APPROVAL"] = "Approval" -- Translation missing
L["OPT_MASTERLOOT_APPROVAL_DESC"] = "Here you can define who can become your masterlooter." -- Translation missing
L["OPT_MASTERLOOT_ALLOW"] = "允許成為拾取分配者"
L["OPT_MASTERLOOT_ALLOW_DESC"] = [=[選擇誰可以請求成為你的拾取分配者。你仍然會收到一個需要確認的彈出訊息，所以你可以在當時拒絕成為拾取分配者。

|cffffff00公會團隊:|r 團隊的80%或更多的成員是來自一個公會。]=]
L["OPT_MASTERLOOT_WHITELIST"] = "拾取分配者白名單"
L["OPT_MASTERLOOT_WHITELIST_DESC"] = "如果上述選項某人並非真正適宜，但你仍希望該玩家能成為你的拾取分配者，那麼請在此輸入名稱，用空格或逗號在名稱中分隔。"
L["OPT_MASTERLOOT_ALLOW_ALL"] = "允許所有人"
L["OPT_MASTERLOOT_ALLOW_ALL_DESC"] = "|cffff0000警告:|r 這會允許每個人請求成為拾取分配者，並可能騙你放棄戰利品！只有你知道自己在做什麼的情況下才可以啟用它。"
L["OPT_MASTERLOOT_ACCEPT"] = "自動接受拾取分配者"
L["OPT_MASTERLOOT_ACCEPT_DESC"] = "自動接受來自其他玩家的拾取分配者請求。"

L["OPT_MASTERLOOTER"] = "拾取分配者"
L["OPT_MASTERLOOTER_DESC"] = "當你是拾取分配者時，這些選項適用於每個人。"
L["OPT_MASTERLOOTER_BID_PUBLIC"] = "公開競標"
L["OPT_MASTERLOOTER_BID_PUBLIC_DESC"] = "你可以公開競標，這樣每個人都可以看到誰出價。"
L["OPT_MASTERLOOTER_TIMEOUT_BASE"] = "擲骰時間(基礎)"
L["OPT_MASTERLOOTER_TIMEOUT_BASE_DESC"] = "無論掉落多少物品，擲骰的基本運行時間。"
L["OPT_MASTERLOOTER_TIMEOUT_PER_ITEM"] = "擲骰時間(每項物品)"
L["OPT_MASTERLOOTER_TIMEOUT_PER_ITEM_DESC"] = "將每個掉落的物品都加入到基礎擲骰運行時間。"
L["OPT_MASTERLOOTER_NEED_ANSWERS"] = "Custom 'Need' answers" -- Translation missing
L["OPT_MASTERLOOTER_NEED_ANSWERS_DESC"] = "Specify up to 9 custom answers when rolling 'Need', with decreasing priority. You can also insert '%s' itself to lower its priority below the prior answers. Separate multiple entries with Commas.\n\nThey can be accessed by right-clicking on the 'Need' button when rolling on loot." -- Translation missing
L["OPT_MASTERLOOTER_GREED_ANSWERS"] = "Custom 'Greed' answers" -- Translation missing
L["OPT_MASTERLOOTER_GREED_ANSWERS_DESC"] = "Specify up to 9 custom answers when rolling 'Greed', with decreasing priority. You can also insert '%s' itself to lower its priority below the prior answers. Separate multiple entries with Commas.\n\nThey can be accessed by right-clicking on the 'Greed' button when rolling on loot." -- Translation missing
L["OPT_MASTERLOOTER_COUNCIL"] = "議會"
L["OPT_MASTERLOOTER_COUNCIL_DESC"] = "議會的玩家可以投票表決誰該得到戰利品。"
L["OPT_MASTERLOOTER_COUNCIL_ALLOW"] = "議會成員"
L["OPT_MASTERLOOTER_COUNCIL_ALLOW_DESC"] = "那些玩家會自動成為議會的一份子。"
L["OPT_MASTERLOOTER_COUNCIL_GUILD_RANK"] = "議會公會階級"
L["OPT_MASTERLOOTER_COUNCIL_GUILD_RANK_DESC"] = "除了上面的選項之外，想要加入這個公會階級的成員進入議會。"
L["OPT_MASTERLOOTER_COUNCIL_WHITELIST"] = "議會白名單"
L["OPT_MASTERLOOTER_COUNCIL_WHITELIST_DESC"] = "你還可以在議會中命名特定的玩家。用空格或逗號分隔多個人。"
L["OPT_MASTERLOOTER_VOTE_PUBLIC"] = "議會投票公開"
L["OPT_MASTERLOOTER_VOTE_PUBLIC_DESC"] = "你可以公開議會投票，所以每個人都可以看到誰有多少票。"