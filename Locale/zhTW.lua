local Name, Addon = ...
local Locale = Addon.Locale
local lang = "zhTW"

-- Chat messages
local L = {lang = lang}
setmetatable(L, Locale.MT)
Locale[lang] = L

L["MSG_BID"] = "請問你有需要 %s 嗎？"
L["MSG_HER"] = "她"
L["MSG_HIM"] = "他"
L["MSG_ITEM"] = "物品"
L["MSG_ROLL_ANSWER_AMBIGUOUS"] = "我現正要送出多件物品，請將你想要的物品連結傳送給我。"
L["MSG_ROLL_ANSWER_BID"] = "好的，我已經登記了你在 %s 的競標。"
L["MSG_ROLL_ANSWER_NO_OTHER"] = "抱歉！我已經給別人了。"
L["MSG_ROLL_ANSWER_NO_SELF"] = "抱歉，我自己也有需求。"
L["MSG_ROLL_ANSWER_NOT_TRADABLE"] = "抱歉，這件無法交易。"
L["MSG_ROLL_ANSWER_YES_MASTERLOOT"] = "可以給你，請交易 <%s>。"
L["MSG_ROLL_ANSWER_YES"] = "可以給你，請來跟我交易。"
L["MSG_ROLL_START_MASTERLOOT"] = "送出 %s <%s> 提供的 -> /w 我，或 /roll %d！"
L["MSG_ROLL_START"] = "送出 %s -> /w 我，或 /roll %d！"
L["MSG_ROLL_WINNER_MASTERLOOT"] = "<%s> 贏得 %s 由<%s>提供 -> 請交易 %s！"
L["MSG_ROLL_WINNER_WHISPER_MASTERLOOT"] = "你已經贏得 %s 由<%s>提供！請交易 %s。"
L["MSG_ROLL_WINNER_WHISPER"] = "你已經贏得 %s！請跟我交易。"
L["MSG_ROLL_WINNER"] = "<%s> 已贏得 %s -> 請跟我交易！"

-- Addon
local L = LibStub("AceLocale-3.0"):NewLocale(Name, lang, lang == Locale.FALLBACK)
if not L then return end

LOOT_ROLL_INELIGIBLE_REASONPLR_NO_ADDON = "物品的提供者並沒有使用PersoLootRoll插件。"
LOOT_ROLL_INELIGIBLE_REASONPLR_NO_DISENCHANT = "PersoLootRoll插件不支援附魔分解。"

L["ACTION"] = "動作"
L["ACTIONS"] = "動作"
L["ADVERTISE"] = "在聊天頻道發佈訊息"
L["ANSWER"] = "回答"
L["ASK"] = "詢問"
L["AWARD_LOOT"] = "獎勵拾取"
L["AWARD_RANDOMLY"] = "隨機獎勵"
L["AWARD"] = "獎勵"
L["DISABLED"] = "停用"
L["DOWN"] = "下"
L["ENABLED"] = "啟用"
L["EQUIPPED"] = "已裝備"
L["GET_FROM"] = "得到自"
L["GIVE_TO"] = "給予"
L["GUILD_MASTER"] = "公會會長"
L["GUILD_OFFICER"] = "公會幹部"
L["HIDE_ALL"] = "隱藏全部"
L["HIDE"] = "隱藏"
L["ID"] = ID
L["ITEM"] = "物品"
L["ITEM_LEVEL"] = "物品等級"
L["ITEMS"] = ITEMS
L["LEFT"] = "左"
L["LEVEL"] = LEVEL
L["MASTERLOOTER"] = "分裝者"
L["MESSAGE"] = "訊息"
L["ML"] = "分裝者"
L["BID"] = "拍裝"
L["ITEM"] = "物品"
L["OWNER"] = "提供者"
L["PLAYER"] = "玩家"
L["PRIVATE"] = "私人"
L["PUBLIC"] = "公開"
L["RAID_ASSISTANT"] = "團隊助理"
L["RAID_LEADER"] = "團隊領隊"
L["RESTART"] = "重新開始"
L["RIGHT"] = "右"
L["ROLL"] = "擲骰"
L["ROLLS"] = "骰裝"
L["SECONDS"] = "%d秒"
L["SET_ANCHOR"] = "設置定位點：延展%s 以及%s"
L["SHOW_HIDE"] = "顯示/隱藏"
L["SHOW"] = "顯示"
L["STATUS"] = STATUS
L["TARGET"] = TARGET
L["TRADE"] = "交易"
L["UP"] = "上"
L["VOTE_WITHDRAW"] = "收回"
L["VOTE"] = "表決"
L["VOTES"] = "表決"
L["WINNER"] = "獲勝者"
L["WON"] = "獲勝"
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
L["USAGE_BID"] = "使用：/plr bid <提供者> ([物品])"
L["USAGE_ROLL"] = "使用：/plr roll [item]* (<持續時間> <提供者>)"

L["VERSION_NOTICE"] = "插件已經有新的版本，請更新以保持跟所有人的相容性，才不會錯過任何戰利品！"

L["ROLL_AWARDED"] = "已給予"
L["ROLL_BID_1"] = NEED
L["ROLL_BID_2"] = GREED
L["ROLL_BID_3"] = ROLL_DISENCHANT
L["ROLL_BID_4"] = PASS
L["ROLL_CANCEL"] = "取消骰 %s (%s 提供的)。"
L["ROLL_END"] = "擲骰 %s 結束(%s 提供的)。"
L["ROLL_IGNORING_BID"] = "忽略%s對%s的競標，因為之前已經聊過了 -> 競標: %s 或 %s。"
L["ROLL_LIST_EMPTY"] = "啟用的擲骰會顯示在此"
L["ROLL_START"] = "開始骰 %s (%s 提供的)。"
L["ROLL_STATUS_-1"] = "已取消"
L["ROLL_STATUS_0"] = "待決中"
L["ROLL_STATUS_1"] = "運作中"
L["ROLL_STATUS_2"] = "完成"
L["ROLL_TRADED"] = "已交易"
L["ROLL_WHISPER_SUPPRESSED"] = "競標來自%s 在%s -> %s / %s。"
L["ROLL_WINNER_MASTERLOOT"] = "%s已經贏得%s 由%s提供。"
L["ROLL_WINNER_OTHER"] = "%s 贏得 %s (你提供的) -> %s。"
L["ROLL_WINNER_OWN"] = "你贏得自己的 %s。"
L["ROLL_WINNER_SELF"] = "你贏得 %s (%s 提供的) -> %s。"

L["BID_CHAT"] = "詢問%s為%s -> %s。"
L["BID_NO_CHAT"] = "密語已禁用，你需要詢問%s為%s你自己 -> %s。"
L["BID_PASS"] = "放棄%s 由%s。"
L["BID_START"] = "競標%q 在%s 從%s。"

L["TRADE_START"] = "與%s開始交易。"
L["TRADE_CANCEL"] = "與%s取消交易。"

L["MASTERLOOTER_SELF"] = "你現在負責分裝。"
L["MASTERLOOTER_OTHER"] = "%%s 現在負責分裝。"

L["FILTER"] = "過濾"
L["FILTER_ALL"] = "所有玩家"
L["FILTER_ALL_DESC"] = "包含所有玩家的擲骰，並非只有你的或是你感興趣的物品。"
L["FILTER_DONE"] = "已完成"
L["FILTER_DONE_DESC"] = "包含已經結束的擲骰。"
L["FILTER_AWARDED"] = "已取得"
L["FILTER_AWARDED_DESC"] = "包含已經由其他人贏得的骰裝。"
L["FILTER_TRADED"] = "已交易"
L["FILTER_TRADED_DESC"] = "包含物品已經交易的擲骰。"
L["FILTER_HIDDEN"] = "隱藏"
L["FILTER_HIDDEN_DESC"] = "包含已取消、待決的、已放棄以及隱藏的骰裝。"

L["TIP_ADDON_MISSING"] = "插件缺少："
L["TIP_ADDON_VERSIONS"] = "插件版本："
L["TIP_MASTERLOOT_START"] = "成為或搜尋負責分裝者"
L["TIP_MASTERLOOT_STOP"] = "移除負責分裝者"
L["TIP_MASTERLOOT"] = "隊長分配是啟用的"
L["TIP_MASTERLOOTING"] = "有分裝者的隊伍::"
L["TIP_MINIMAP_ICON"] = "|cffffff00左鍵點擊:|r 開關擲骰視窗\n|cffffff00右鍵點擊:|r 顯示選項"
L["TIP_VOTES"] = "表決來自:"
L["TIP_MASTERLOOT_INFO"] = [=[|cffffff00分裝者:|r %s 
|cffffff00擲骰時間:|r %ds (+ %ds 每項物品) 
|cffffff00議會:|r %s |
cffffff00競標:|r %s 
|cffffff00表決:|r %s]=]

L["MENU_MASTERLOOT_START"] = "成為分裝者"
L["MENU_MASTERLOOT_SEARCH"] = "搜尋有人負責分裝的團體"

L["DIALOG_MASTERLOOT_ASK"] = "<%s>想成為你的分裝者。"
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

-- Options: Home

L["OPT_INFO"] = "資訊"
L["OPT_INFO_DESC"] = "關於此插件的一些資訊。"
L["OPT_VERSION"] = "|cffffd100版本:|r %s"
L["OPT_AUTHOR"] = "|cffffd100作者:|r Shrugal (EU-Mal'Ganis)"
L["OPT_TRANSLATION"] = "|cffffd100翻譯:|r 三皈依 (TW-暗影之月)"
L["OPT_ENABLE"] = "啟用"
L["OPT_ENABLE_DESC"] = "啟用或停用此插件"
L["OPT_ONLY_MASTERLOOT"] = "Only masterloot" -- Translation missing
L["OPT_ONLY_MASTERLOOT_DESC"] = "Only activate the addon when using masterloot (e.g. with your guild)" -- Translation missing
L["OPT_AWARD_SELF"] = "自行選擇贏家"
L["OPT_AWARD_SELF_DESC"] = "自行選擇誰該得到你的戰利品，而非讓插件隨機選擇，當你是拾取分配者時，始終啟用此功能。"

L["OPT_UI"] = "使用者介面"
L["OPT_UI_DESC"] = "根據自己的喜好自訂%s的外觀。"
L["OPT_MINIMAP_ICON"] = "顯示小地圖圖示"
L["OPT_MINIMAP_ICON_DESC"] = "顯示或隱藏小地圖圖示"
L["OPT_ROLL_FRAMES"] = "顯示擲骰框架"
L["OPT_ROLL_FRAMES_DESC"] = "當某人拾取你感興趣的戰利品時顯示擲骰框架，這樣你就可以骰它。"
L["OPT_ROLLS_WINDOW"] = "顯示擲骰視窗"
L["OPT_ROLLS_WINDOW_DESC"] = "當某人拾取你感興趣的戰利品時總是顯示擲骰視窗(所有的擲骰都在上面)。當你是分裝者時，始終啟用此功能。"
L["OPT_ACTIONS_WINDOW"] = "顯示動作視窗"
L["OPT_ACTIONS_WINDOW_DESC"] = "當有處理中的動作時顯示動作視窗，例如，當你贏得一件物品但還需要交易某人才能得到它。"
L["OPT_ACTIONS_WINDOW_MOVE"] = "移動"
L["OPT_ACTIONS_WINDOW_MOVE_DESC"] = "移動動作視窗到一旁。"

L["OPT_ITEM_FILTER"] = "物品過濾"
L["OPT_ITEM_FILTER_DESC"] = "更改你想要擲骰的物品。"
L["OPT_ILVL_THRESHOLD"] = "物品等級門檻"
L["OPT_ILVL_THRESHOLD_DESC"] = "物品等級低於你以下多少的物品將被忽略。"
L["OPT_ILVL_THRESHOLD_TRINKETS"] = "飾品門檻為雙倍"
L["OPT_ILVL_THRESHOLD_TRINKETS_DESC"] = "飾品的門檻應該是正常值的兩倍，因為觸發特效會讓收益變化很大。"
L["OPT_SPECS"] = "專精"
L["OPT_SPECS_DESC"] = "只建議這些職業專精的戰利品。"
L["OPT_TRANSMOG"] = "檢查塑形外觀"
L["OPT_TRANSMOG_DESC"] = "擲骰那些你還未擁有外觀的物品。"

-- Options: Messages

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

L["OPT_SHOULD_CHAT"] = "啟用/停用"
L["OPT_SHOULD_CHAT_DESC"] = "決定插件何時發佈到隊伍/團隊聊天並密語其他玩家。"
L["OPT_GROUPCHAT"] = "團體聊天頻道"
L["OPT_GROUPCHAT_DESC"] = "更改插件是否要將骰裝公告到團體聊天中。"
L["OPT_GROUPCHAT_ANNOUNCE"] = "公告骰裝以及贏家"
L["OPT_GROUPCHAT_ANNOUNCE_DESC"] = "在隊伍/團隊/副本聊天中公告骰裝以及獲得者。"
L["OPT_GROUPCHAT_ROLL"] = "在聊天中擲骰戰利品"
L["OPT_GROUPCHAT_ROLL_DESC"] = "如果其他人在團體聊天中貼出連結，請擲骰你要的戰利品(/roll)。"
L["OPT_WHISPER"] = "聊天密語"
L["OPT_WHISPER_DESC"] = "更改插件是否會密語其他玩家並且/或回應其他人的訊息。"
L["OPT_WHISPER_ANSWER"] = "回應密語"
L["OPT_WHISPER_ANSWER_DESC"] = "讓插件自動回應從隊伍/團隊成員來的關於你拾取物品的密語。"
L["OPT_WHISPER_SUPPRESS"] = "阻擋密語"
L["OPT_WHISPER_SUPPRESS_DESC"] = "當放棄你的戰利品時，阻擋來自符合條件玩家的密語訊息。"
L["OPT_WHISPER_GROUP"] = "密語根據團體類型"
L["OPT_WHISPER_GROUP_DESC"] = "如果其他人拾取你想要的物品則密語他們，這取決於你目前所處的團體類型。"
L["OPT_WHISPER_TARGET"] = "密語目標"
L["OPT_WHISPER_TARGET_DESC"] = "如果其他人得到你想要的物品則密語他們，這取決於目標是否在你的公會或是好友名單上。"

L["OPT_CUSTOM_MESSAGES"] = "自訂訊息"
L["OPT_CUSTOM_MESSAGES_DESC"] = "You can reorder placeholders (|cffffff00%s|r, |cffffff00%d|r) by adding their position and a $ sign in the middle, so e.g. |cffffff00%2$s|r instead of |cffffff00%s|r for the 2nd placeholder. See tooltips for details." -- Translation missing
L["OPT_CUSTOM_MESSAGES_DEFAULT"] = "預設語言 (%s)"
L["OPT_CUSTOM_MESSAGES_DEFAULT_DESC"] = "當收訊息的人說英文或非你伺服器預設的語言時(%s)，將使用這些訊息。"
L["OPT_CUSTOM_MESSAGES_LOCALIZED"] = "伺服器語言 (%s)"
L["OPT_CUSTOM_MESSAGES_LOCALIZED_DESC"] = "當收訊人說你伺服器的預設語言時(%s)使用這些訊息。"
L["OPT_MSG_ROLL_START"] = "通告新的骰裝"
L["OPT_MSG_ROLL_START_DESC"] = "1：物品連結\n2：擲骰數字"
L["OPT_MSG_ROLL_START_MASTERLOOT"] = "通告新的骰裝 (如同隊長分配)"
L["OPT_MSG_ROLL_START_MASTERLOOT_DESC"] = "1：物品連結\n2：物品提供者\n3：擲骰數字"
L["OPT_MSG_ROLL_WINNER"] = "通告骰裝獲勝者"
L["OPT_MSG_ROLL_WINNER_DESC"] = "1：獲勝者\n2：物品連結"
L["OPT_MSG_ROLL_WINNER_MASTERLOOT"] = "通告骰裝的獲勝者 (如同隊長分配)"
L["OPT_MSG_ROLL_WINNER_MASTERLOOT_DESC"] = "1：獲勝者\n2：物品連結\n3：物品提供者\n4：他/她"
L["OPT_MSG_ROLL_WINNER_WHISPER"] = "密語骰裝獲勝者"
L["OPT_MSG_ROLL_WINNER_WHISPER_DESC"] = "1：物品連結"
L["OPT_MSG_ROLL_WINNER_WHISPER_MASTERLOOT"] = "密語骰裝獲勝者 (如同隊長分配)"
L["OPT_MSG_ROLL_WINNER_WHISPER_MASTERLOOT_DESC"] = "1：物品連結\n2：物品提供者\n3：他/她"
L["OPT_MSG_BID"] = "競標來自其他玩家的物品"
L["OPT_MSG_BID_DESC"] = "1：物品連結"
L["OPT_MSG_ROLL_ANSWER_BID"] = "回答：競標已登記"
L["OPT_MSG_ROLL_ANSWER_BID_DESC"] = "1：物品連結"
L["OPT_MSG_ROLL_ANSWER_YES"] = "回答：你可以得到它"
L["OPT_MSG_ROLL_ANSWER_YES_DESC"] = ""
L["OPT_MSG_ROLL_ANSWER_YES_MASTERLOOT"] = "回答：你可以得到它(如同隊長分配)"
L["OPT_MSG_ROLL_ANSWER_YES_MASTERLOOT_DESC"] = "1：物品提供者"
L["OPT_MSG_ROLL_ANSWER_NO_SELF"] = "回答：我自己也有需求"
L["OPT_MSG_ROLL_ANSWER_NO_SELF_DESC"] = ""
L["OPT_MSG_ROLL_ANSWER_NO_OTHER"] = "回答：我已經給了別人"
L["OPT_MSG_ROLL_ANSWER_NO_OTHER_DESC"] = ""
L["OPT_MSG_ROLL_ANSWER_NOT_TRADABLE"] = "回答：這件無法交易"
L["OPT_MSG_ROLL_ANSWER_NOT_TRADABLE_DESC"] = ""
L["OPT_MSG_ROLL_ANSWER_AMBIGUOUS"] = "回答：發給我物品連結"
L["OPT_MSG_ROLL_ANSWER_AMBIGUOUS_DESC"] = ""

-- Options: Masterloot

L["OPT_MASTERLOOT"] = "拾取分配"
L["OPT_MASTERLOOT_DESC"] = "當你(或其他人)成為分裝者，所有戰利品都將由此人分發。你會收到你贏得什麼物品以及誰贏得你物品的通知，因此你可以交易物品給合適的人。"
L["OPT_MASTERLOOT_START"] = "成為分裝者"
L["OPT_MASTERLOOT_SEARCH"] = "搜尋分裝者"
L["OPT_MASTERLOOT_STOP"] = "停止拾取分配"
L["OPT_MASTERLOOT_APPROVAL"] = "贊同"
L["OPT_MASTERLOOT_APPROVAL_DESC"] = "在此你可以決定誰可以成為你的分裝者。"
L["OPT_MASTERLOOT_ALLOW"] = "允許成為分裝者"
L["OPT_MASTERLOOT_ALLOW_DESC"] = [=[選擇誰可以請求成為你的拾取分配者。你仍然會收到一個需要確認的彈出訊息，所以你可以在當時拒絕成為拾取分配者。

|cffffff00公會團隊:|r 團隊的80%或更多的成員是來自一個公會。]=]
L["OPT_MASTERLOOT_WHITELIST"] = "分裝者白名單"
L["OPT_MASTERLOOT_WHITELIST_DESC"] = "如果上述選項某人並非真正適宜，但你仍希望該玩家能成為你的分裝者，那麼請在此輸入名稱，用空格或逗號在名稱中分隔。"
L["OPT_MASTERLOOT_ALLOW_ALL"] = "允許所有人"
L["OPT_MASTERLOOT_ALLOW_ALL_DESC"] = "|cffff0000警告:|r 這會允許每個人請求成為分裝者，並可能騙你放棄戰利品！只有你知道自己在做什麼的情況下才可以啟用它。"
L["OPT_MASTERLOOT_ACCEPT"] = "自動接受分裝者"
L["OPT_MASTERLOOT_ACCEPT_DESC"] = "自動接受來自其他玩家的分裝者請求。"

L["OPT_MASTERLOOTER"] = "規則"
L["OPT_MASTERLOOTER_DESC"] = "當你是分裝者時，這些選項適用於每個人。"
L["OPT_MASTERLOOTER_BID_PUBLIC"] = "公開競標"
L["OPT_MASTERLOOTER_BID_PUBLIC_DESC"] = "你可以公開競標，這樣每個人都可以看到誰出價。"
L["OPT_MASTERLOOTER_TIMEOUT_BASE"] = "骰裝時間(基本)"
L["OPT_MASTERLOOTER_TIMEOUT_BASE_DESC"] = "無論掉落多少物品，骰裝的基本運行時間。"
L["OPT_MASTERLOOTER_TIMEOUT_PER_ITEM"] = "骰裝時間(每項物品)"
L["OPT_MASTERLOOTER_TIMEOUT_PER_ITEM_DESC"] = "將每個掉落的物品都加入到基本骰裝運行時間。"
L["OPT_MASTERLOOTER_NEED_ANSWERS"] = "自訂 '需求' 的應答"
L["OPT_MASTERLOOTER_NEED_ANSWERS_DESC"] = "當擲骰'需求'時最多可依據優先等級指定9個自訂回答。你還可以插入'%s'本身讓優先級降低到先前回答之下。使用逗號分隔多個條目。\n\n當擲骰戰利品時，可以透由右鍵點擊'需求'按鈕來查閱。"
L["OPT_MASTERLOOTER_GREED_ANSWERS"] = "自訂 '貪婪' 的應答"
L["OPT_MASTERLOOTER_GREED_ANSWERS_DESC"] = "當擲骰'貪婪'時最多可依據優先等級指定9個自訂回答。你還可以插入'%s'本身讓優先級降低到先前回答之下。使用逗號分隔多個條目。\n\n當擲骰戰利品時，可以透由右鍵點擊'貪婪'按鈕來查閱。"
L["OPT_MASTERLOOTER_COUNCIL"] = "議會"
L["OPT_MASTERLOOTER_COUNCIL_DESC"] = "議會的玩家可以投票表決誰該得到戰利品。"
L["OPT_MASTERLOOTER_COUNCIL_ALLOW"] = "議會成員"
L["OPT_MASTERLOOTER_COUNCIL_ALLOW_DESC"] = "那些玩家會自動成為議會的一份子。"
L["OPT_MASTERLOOTER_COUNCIL_GUILD_RANK"] = "議會公會階級"
L["OPT_MASTERLOOTER_COUNCIL_GUILD_RANK_DESC"] = "除了上面的選項之外，想要加入這個公會階級的成員進入議會。"
L["OPT_MASTERLOOTER_COUNCIL_WHITELIST"] = "議會白名單"
L["OPT_MASTERLOOTER_COUNCIL_WHITELIST_DESC"] = "你還可以在議會中命名特定的玩家。用空格或逗號分隔多個人。"
L["OPT_MASTERLOOTER_VOTE_PUBLIC"] = "議會表決公開"
L["OPT_MASTERLOOTER_VOTE_PUBLIC_DESC"] = "你可以公開議會表決，所以每個人都可以看到誰有多少票。"