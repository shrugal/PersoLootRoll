local Name, Addon = ...
local Locale = Addon.Locale
local lang = "zhCN"

-- Chat messages
local L = {lang = lang}
setmetatable(L, Locale.MT)
Locale[lang] = L

L["MSG_BID_1"] = "请问您有需要 %s 吗？"
L["MSG_BID_2"] = "如果您无需求，请问可以让 %s 给我吗？"
L["MSG_BID_3"] = "如果您不想要 %s 的话我可以使用。"
L["MSG_BID_4"] = "如果您根本不想要 %s 我想拿。"
L["MSG_BID_5"] = "请问您有需要 %s 吗？或者 是否可以给我吗？"
L["MSG_HER"] = "她"
L["MSG_HIM"] = "他"
L["MSG_ITEM"] = "物品"
L["MSG_ROLL_ANSWER_AMBIGUOUS"] = "我现正要送出多件物品，请将你想要的物品信息发给我。"
L["MSG_ROLL_ANSWER_BID"] = "好的，我已经记下了你对 %s 的需求。"
L["MSG_ROLL_ANSWER_NO_OTHER"] = "抱歉！我已经给别人了。"
L["MSG_ROLL_ANSWER_NO_SELF"] = "抱歉，我自己也有需求。"
L["MSG_ROLL_ANSWER_NOT_TRADABLE"] = "抱歉，这件无法交易。"
L["MSG_ROLL_ANSWER_YES"] = "可以给你，请来跟我交易。"
L["MSG_ROLL_ANSWER_YES_MASTERLOOT"] = "可以给你，请交易 <%s>。"
L["MSG_ROLL_START"] = "分配装备 %s -> 要的密我，或 /roll %d！"
L["MSG_ROLL_START_MASTERLOOT"] = "分配由<%2$s>提供的 %1$s -> /w 我，或 /roll %3$s！"
L["MSG_ROLL_WINNER"] = "<%s> 已贏得 %s -> 请跟我交易！"
L["MSG_ROLL_WINNER_MASTERLOOT"] = "<%1$s> 已贏得由<%3$s>提供的 %2$s -> 请交易 %4$s！"
L["MSG_ROLL_WINNER_WHISPER"] = "你已经贏得 %s！请跟我交易。"
L["MSG_ROLL_WINNER_WHISPER_MASTERLOOT"] = "你已贏得由<%2$s>提供的 %1$s！请交易 %3$s。"
L["MSG_ROLL_DISENCHANT"] = "<%s> will disenchant %s -> Trade me!" -- Translation missing
L["MSG_ROLL_DISENCHANT_MASTERLOOT"] = "<%s> will disenchant %s from <%s> -> Trade %s!" -- Translation missing
L["MSG_ROLL_DISENCHANT_WHISPER"] = "You were picked to disenchant %s, please trade me." -- Translation missing
L["MSG_ROLL_DISENCHANT_WHISPER_MASTERLOOT"] = "You were picked to disenchant %s from <%s>, please trade %s." -- Translation missing

-- Addon
local L = LibStub("AceLocale-3.0"):NewLocale(Name, lang, lang == Locale.FALLBACK)
if not L then return end

L["ACTION"] = "动作"
L["ACTIONS"] = "动作"
L["ADVERTISE"] = "在聊天频道发布讯息"
L["ANSWER"] = "回答"
L["ASK"] = "询问"
L["AWARD"] = "分配"
L["AWARD_LOOT"] = "分配装备/物品"
L["AWARD_RANDOMLY"] = "随机分配"
L["BID"] = "竞标"
L["COMMUNITY_GROUP"] = "社群队伍"
L["COMMUNITY_MEMBER"] = "社群成员"
L["DISABLED"] = "停用"
L["DOWN"] = "下"
L["ENABLED"] = "启用"
L["EQUIPPED"] = "已装备"
L["GET_FROM"] = "得到自"
L["GIVE_AWAY"] = "放弃"
L["GIVE_TO"] = "给予"
L["GUILD_MASTER"] = "公会会长"
L["GUILD_OFFICER"] = "公会干部"
L["HIDE"] = "隐藏"
L["HIDE_ALL"] = "隐藏全部"
L["ITEM"] = "物品"
L["ITEM_LEVEL"] = "物品等级"
L["KEEP"] = "保留"
L["LEFT"] = "左"
L["MASTERLOOTER"] = "负责分装"
L["MESSAGE"] = "讯息"
L["ML"] = "分装者"
L["OPEN_ROLLS"] = "开启ROLL装的窗口"
L["OWNER"] = "提供者"
L["PLAYER"] = "玩家"
L["PRIVATE"] = "私人"
L["PUBLIC"] = "公开"
L["RAID_ASSISTANT"] = "团队助理"
L["RAID_LEADER"] = "团队领队"
L["RESTART"] = "从新开始"
L["RIGHT"] = "右"
L["ROLL"] = "掷骰"
L["ROLLS"] = "骰装"
L["SECONDS"] = "%d秒"
L["SET_ANCHOR"] = "设置定位点：往%s以及%s延展"
L["SHOW"] = "显示"
L["SHOW_HIDE"] = "显示/隐藏"
L["TRADE"] = "交易"
L["UP"] = "上"
L["VERSION_NOTICE"] = "插件已经有新的版本，请更新以保持跟所有人的相容性，才不会错过任何战利品！"
L["VOTE"] = "表決"
L["VOTE_WITHDRAW"] = "收回"
L["VOTES"] = "表決"
L["WINNER"] = "获胜者"
L["WON"] = "获胜"
L["YOUR_BID"] = "你的竞标"

-- Commands
L["HELP"] = [=[开始物品的掷骰或竞标（/PersoLootRoll or /plr）。
使用方法：
/plr: 开启选项视窗
/plr roll [物品]* (<持续时间> <拥有者>): 开始一个或多个物品的掷骰
/plr bid [物品] (<拥有者> <bid>): 竞标来自其他玩家的物品
/plr options: 开启选项视窗
/plr config: 透过指令更改设置
/plr help: 发送此帮助讯息
解释: [..] = 物品连接, * = 一个或多个物品， (..) = 备选的]=]
L["USAGE_BID"] = "使用：/plr bid <提供者> ([物品])"
L["USAGE_ROLL"] = "使用：/plr roll [item]* (<持续时间> <提供者>)"

-- Errors
L["ERROR_CMD_UNKNOWN"] = "未知指令'%s'"
L["ERROR_ITEM_NOT_TRADABLE"] = "你无法交易这项物品。"
L["ERROR_NOT_IN_GROUP"] = "你不在队伍或团队中。"
L["ERROR_OPT_MASTERLOOT_EXPORT_FAILED"] = "汇出分装设置到<%s>失败了！"
L["ERROR_PLAYER_NOT_FOUND"] = "找不到玩家 %q。"
L["ERROR_ROLL_BID_IMPOSSIBLE_OTHER"] = "%s已发送了%s的竞标，但现在不允许这样做。"
L["ERROR_ROLL_BID_IMPOSSIBLE_SELF"] = "你现在无法竞标该物品。"
L["ERROR_ROLL_BID_UNKNOWN_OTHER"] = "%s已发送了%s的竞标邀请。"
L["ERROR_ROLL_BID_UNKNOWN_SELF"] = "这不是有效的竞标。"
L["ERROR_ROLL_STATUS_NOT_0"] = "此掷骰已经开始或是结束。"
L["ERROR_ROLL_STATUS_NOT_1"] = "此掷骰没有运行。"
L["ERROR_ROLL_UNKNOWN"] = "此掷骰不存在。"
L["ERROR_ROLL_VOTE_IMPOSSIBLE_OTHER"] = "%s已经发送了%s的投票表決，但现在不允许这样做。"
L["ERROR_ROLL_VOTE_IMPOSSIBLE_SELF"] = "你现在无法对该物品进行投票。"
L["ERROR_NOT_MASTERLOOTER_OTHER_OWNER"] = "You need to become masterlooter to create rolls for other player's items." -- Translation missing
L["ERROR_NOT_MASTERLOOTER_TIMEOUT"] = "You cannot change the timeout while having a masterlooter other than yourself." -- Translation missing

-- GUI
L["DIALOG_MASTERLOOT_ASK"] = "<%s>想成为你的分装者。"
L["DIALOG_OPT_MASTERLOOT_LOAD"] = "这将用你公会/社群讯息中储存的设置替换你当前的分装设置，你确定要继续吗？"
L["DIALOG_OPT_MASTERLOOT_SAVE"] = "这将使用您当前的设置替换公会/社群讯息中的任何分装设置，您确定要继续吗？"
L["DIALOG_ROLL_CANCEL"] = "你想要取消这次掷骰吗？"
L["DIALOG_ROLL_RESTART"] = "你想要重新开始掷骰吗？"
L["FILTER"] = "过滤"
L["FILTER_ALL"] = "所有玩家"
L["FILTER_ALL_DESC"] = "包含所有玩家的掷骰，并非只有你的或是你感兴趣的物品。"
L["FILTER_AWARDED"] = "已取得"
L["FILTER_AWARDED_DESC"] = "包含已经由其他人赢得的骰装。"
L["FILTER_DONE"] = "已完成"
L["FILTER_DONE_DESC"] = "包含已经结束的掷骰。"
L["FILTER_HIDDEN"] = "隐藏"
L["FILTER_HIDDEN_DESC"] = "包含已取消、处理中、已放弃以及隐藏的骰装。"
L["FILTER_TRADED"] = "已交易"
L["FILTER_TRADED_DESC"] = "包含物品已经交易的掷骰。"
L["MENU_MASTERLOOT_SEARCH"] = "搜寻有人负责分装的团体"
L["MENU_MASTERLOOT_START"] = "成为分装者"
L["TIP_ADDON_MISSING"] = "插件缺少："
L["TIP_ADDON_VERSIONS"] = "插件版本："
L["TIP_ENABLE_WHISPER_ASK"] = "提示：右键点击启用战利品自动询问"
L["TIP_CHAT_TO_TRADE"] = "请在交易前先询问提供者"
L["TIP_MASTERLOOT"] = "队长分配是启用的"
L["TIP_MASTERLOOT_INFO"] = [=[|cffffff00分裝者:|r %s 
|cffffff00掷骰时间:|r %ds (+ %ds 每项物品) 
|cffffff00议会:|r %s |
cffffff00竞标:|r %s 
|cffffff00表決:|r %s]=]
L["TIP_MASTERLOOT_START"] = "成为或搜寻负责分装者"
L["TIP_MASTERLOOT_STOP"] = "移除负责分装者"
L["TIP_MASTERLOOTING"] = "有分装者的队伍:"
L["TIP_MINIMAP_ICON"] = [=[|cffffff00左鍵:|r 开关骰装视窗 
|cffffff00右键:|r 设定选项]=]
L["TIP_PLH_USERS"] = "PLH使用者："
L["TIP_VOTES"] = "表決來自:"

-- Options - Home
L["OPT_ACTIONS_WINDOW"] = "显示动作视窗"
L["OPT_ACTIONS_WINDOW_DESC"] = "当有处理中的动作时显示动作窗口，例如，当你赢得一件物品但还需要交易某人才能得到它。"
L["OPT_ACTIONS_WINDOW_MOVE"] = "移动"
L["OPT_ACTIONS_WINDOW_MOVE_DESC"] = "移动动作窗口到一旁。"
L["OPT_ALLOW_DISENCHANT"] = "Allow \"Disenchant\" bids" -- Translation missing
L["OPT_ALLOW_DISENCHANT_DESC"] = "Allow others to bid \"Disenchant\" on your own items." -- Translation missing
L["OPT_AUTHOR"] = "|cffffff00作者:|r Shrugal (EU-Mal'Ganis)"
L["OPT_AWARD_SELF"] = "自行选择你的物品的获胜者"
L["OPT_AWARD_SELF_DESC"] = "自行选择谁该得到你的战利品，而非让插件随机选择，当你是拾取分配者时，始终启用此功能。"
L["OPT_BID_PUBLIC"] = "公开竞标"
L["OPT_BID_PUBLIC_DESC"] = "你掷骰的竞标是公开的，所有使用此插件的人都可以看见。"
L["OPT_CHILL_MODE"] = "Chill mode" -- Translation missing
L["OPT_CHILL_MODE_DESC"] = [=[The intent of chill mode is to take the pressure out of sharing the loot, even if that means that things will take a bit longer. If you enable it the following things will change:

|cffffff781.|r Rolls from you won't start until you actually decided to share them, so you have as much time as you want to choose, and other addon users won't see your items until you did.
|cffffff782.|r Rolls from you have double the normal run-time, or no run-time at all if you enabled to choose winners of your own items yourself (see next option).
|cffffff783.|r Rolls from non-addon users in your group also stay open until you decided if you want them or not.

|cffff0000IMPORTANT:|r Rolls from other addon users without chill mode active will still have a normal timeout. Make sure that everyone in your group enables this option if you want a chill run.]=] -- Translation missing
L["OPT_DONT_SHARE"] = "不分享战利品"
L["OPT_DONT_SHARE_DESC"] = "不去ROLL别人的战利品但也不分享自己的。此插件将会阻挡对你战利品的请求(如果启用的话)，但你仍可以成为分装者以及战利品议会成员。"
L["OPT_ENABLE"] = "启用"
L["OPT_ENABLE_DESC"] = "启用或停用此插件"
L["OPT_ACTIVE_GROUPS"] = "按照小队类型激活"
L["OPT_ACTIVE_GROUPS_DESC"] = [=[Activate only when you are in one of these group types.

|cffffff78公会团队：|r团队的%d%%或更多的成员是来自一个公会。
|cffffff78社群團隊：|r团队的%d%%或更多的成员是来自一个魔兽社群。]=]
L["OPT_ILVL_THRESHOLD"] = "物品等级门槛"
L["OPT_ILVL_THRESHOLD_DESC"] = "物品等级低于你以下多少的物品将被忽略。"
L["OPT_ILVL_THRESHOLD_TRINKETS"] = "饰品门槛为双倍"
L["OPT_ILVL_THRESHOLD_TRINKETS_DESC"] = "饰品的门槛应该是正常值的两倍，因为触发特效会让收益变化很大。"
L["OPT_ILVL_THRESHOLD_RINGS"] = "戒指双阈值"
L["OPT_ILVL_THRESHOLD_RINGS_DESC"] = "戒指应该是正常阈值的两倍，因为由于缺少主要统计数据，它们的值可能会有很大差异."
L["OPT_INFO"] = "资讯"
L["OPT_INFO_DESC"] = "关于此插件的一些资讯。"
L["OPT_ITEM_FILTER"] = "物品过滤"
L["OPT_ITEM_FILTER_DESC"] = "更改你想要掷骰的物品。"
L["OPT_MINIMAP_ICON"] = "显示小地图图标"
L["OPT_MINIMAP_ICON_DESC"] = "显示或隐藏小地图图标"
L["OPT_ONLY_MASTERLOOT"] = "只有拾取分配"
L["OPT_ONLY_MASTERLOOT_DESC"] = "只有使用拾取分配时才启用此插件(例如跟你的公会一起)"
L["OPT_PAWN"] = "校验 \"Pawn\""
L["OPT_PAWN_DESC"] = "根据\"Pawn\"插件仅ROLL符合升级条件的物品."
L["OPT_ROLL_FRAMES"] = "显示ROLL框架"
L["OPT_ROLL_FRAMES_DESC"] = "当某人拾取你感兴趣的战利品时显示ROLL框架，这样你就可以ROLL它。"
L["OPT_ROLLS_WINDOW"] = "显示ROLL窗口"
L["OPT_ROLLS_WINDOW_DESC"] = "当某人拾取你感兴趣的战利品时总是显示ROLL窗口(所有的ROLL都在上面)。当你是分装者时，始终启用此功能。"
L["OPT_SPECS"] = "专精"
L["OPT_SPECS_DESC"] = "只建议这些职业专精的战利品。"
L["OPT_TRANSLATION"] = "|cffffff00翻译:|r 不懂英文 (CN-新手学习)"
L["OPT_TRANSMOG"] = "检查幻化外观"
L["OPT_TRANSMOG_DESC"] = "ROLL那些你还未拥有外观的物品。"
L["OPT_DISENCHANT"] = "Disenchant" -- Translation missing
L["OPT_DISENCHANT_DESC"] = "Bid \"Disenchant\" on items you can't use if you have the profession and the item owner has allowed it." -- Translation missing
L["OPT_UI"] = "使用者界面"
L["OPT_UI_DESC"] = "根据自己的喜好自订persolootroll的外观。"
L["OPT_VERSION"] = "|cffffff00版本:|r "

-- Options - Masterloot
L["OPT_MASTERLOOT"] = "拾取分配"
L["OPT_MASTERLOOT_APPROVAL"] = "认可"
L["OPT_MASTERLOOT_APPROVAL_ACCEPT"] = "自动接受分装者"
L["OPT_MASTERLOOT_APPROVAL_ACCEPT_DESC"] = "自动接受来自其他玩家的分装者请求。"
L["OPT_MASTERLOOT_APPROVAL_ALLOW"] = "允许成为分装者"
L["OPT_MASTERLOOT_APPROVAL_ALLOW_ALL"] = "允许所有人"
L["OPT_MASTERLOOT_APPROVAL_ALLOW_ALL_DESC"] = "|cffff0000警告:|r 这会允许每个人请求成为分装者，并可能骗你放弃战利品！只有你自己确定明确在做什么的情况下才可以启用它。"
L["OPT_MASTERLOOT_APPROVAL_ALLOW_DESC"] = [=[选择谁可以请求成为你的分装者。你仍然会收到一个需要确认的弹出讯息，所以你可以在当时拒绝成为分装者。

|cffffff00公会团队:|r 团队的%d%%或更多的成员是来自一个公会。]=]
L["OPT_MASTERLOOT_APPROVAL_DESC"] = "在此你可以决定谁可以成为你的分装者。"
L["OPT_MASTERLOOT_APPROVAL_WHITELIST"] = "分装者白名单"
L["OPT_MASTERLOOT_APPROVAL_WHITELIST_DESC"] = "如果上述选项某人并非真正适宜，但你仍希望该玩家能成为你的分装者，那么请在此输入名称，用空格或逗号在名称中分隔。"
L["OPT_MASTERLOOT_CLUB"] = "公会/社群"
L["OPT_MASTERLOOT_CLUB_DESC"] = "选择要从何公会/社群来导入/导出设置。"
L["OPT_MASTERLOOT_COUNCIL"] = "议会"
L["OPT_MASTERLOOT_COUNCIL_CLUB_RANK"] = "议会的公会/社群阶级"
L["OPT_MASTERLOOT_COUNCIL_CLUB_RANK_DESC"] = "除了上面的选项之外，想要加入这个公会/社群阶级的成员进入议会。"
L["OPT_MASTERLOOT_COUNCIL_DESC"] = "议会的玩家可以投票表决谁该得到战利品。"
L["OPT_MASTERLOOT_COUNCIL_ROLES"] = "议会角色"
L["OPT_MASTERLOOT_COUNCIL_ROLES_DESC"] = "那些玩家会自动成为议会的成员。"
L["OPT_MASTERLOOT_COUNCIL_WHITELIST"] = "议会白名单"
L["OPT_MASTERLOOT_COUNCIL_WHITELIST_DESC"] = "你还可以在议会中命名特定的玩家。用空格或逗号分隔多个人。"
L["OPT_MASTERLOOT_DESC"] = "当你(或其他人)成为分装者，所有战利品都将由此人分发。你会收到你赢得什麽物品以及谁赢得你物品的通知，因此你可以交易物品给合适的人。"
L["OPT_MASTERLOOT_EXPORT_DONE"] = "分装设置成功导出到<%s>。"
L["OPT_MASTERLOOT_EXPORT_GUILD_ONLY"] = "请使用本文替换社群的当前讯息，因为自动替换它仅适用于公会。"
L["OPT_MASTERLOOT_EXPORT_NO_PRIV"] = "请让会长用这个文字替换公会的讯息，因为你自己没有权限这样做。"
L["OPT_MASTERLOOT_EXPORT_WINDOW"] = "导出分装设置"
L["OPT_MASTERLOOT_LOAD"] = "载入"
L["OPT_MASTERLOOT_LOAD_DESC"] = "从公会/社群的说明讯息中载入分装设置。"
L["OPT_MASTERLOOT_RULES"] = "规则"
L["OPT_MASTERLOOT_RULES_AUTO_AWARD"] = "自动分配战利品"
L["OPT_MASTERLOOT_RULES_AUTO_AWARD_DESC"] = "让插件决定谁应该获得战利品，基于议会投票，竞标和装等等因素。"
L["OPT_MASTERLOOT_RULES_AUTO_AWARD_TIMEOUT"] = "自动分配时间(基本)"
L["OPT_MASTERLOOT_RULES_AUTO_AWARD_TIMEOUT_DESC"] = "在自动分配战利品之前等待的基准时间，所以你有时间投票表决并可能自己决定。"
L["OPT_MASTERLOOT_RULES_AUTO_AWARD_TIMEOUT_PER_ITEM"] = "自动分配时间(每项物品)"
L["OPT_MASTERLOOT_RULES_AUTO_AWARD_TIMEOUT_PER_ITEM_DESC"] = "将每个掉落的物品都加入到基本自动分配时间。"
L["OPT_MASTERLOOT_RULES_BID_PUBLIC"] = "公开竞标"
L["OPT_MASTERLOOT_RULES_BID_PUBLIC_DESC"] = "你可以公开竞标，这样每个人都可以看到谁出价。"
L["OPT_MASTERLOOT_RULES_DESC"] = "当你是分装者时，这些选项适用于每个人。"
L["OPT_MASTERLOOT_RULES_ALLOW_DISENCHANT_DESC"] = "Allow group members to roll \"Disenchant\" on items." -- Translation missing
L["OPT_MASTERLOOT_RULES_DISENCHANTER"] = "分解者"
L["OPT_MASTERLOOT_RULES_DISENCHANTER_DESC"] = "将没人要的战利品给这些玩家分解。 Separate multiple names with spaces or commas." -- Translation outdated
L["OPT_MASTERLOOT_RULES_GREED_ANSWERS"] = "自订 '贪婪' 的应答"
L["OPT_MASTERLOOT_RULES_GREED_ANSWERS_DESC"] = [=[当掷骰'贪婪'时最多可依据优先等级指定9个自订回答。你还可以插入'%s'本身让优先级降低到先前回答之下。使用逗号分隔多个条目。

当掷骰战利品时，可以透由右键点击'贪婪'按钮来查阅。]=]
L["OPT_MASTERLOOT_RULES_NEED_ANSWERS"] = "自订 '需求' 的应答"
L["OPT_MASTERLOOT_RULES_NEED_ANSWERS_DESC"] = [=[当掷骰'需求'时最多可依据优先等级指定9个自订回答。你还可以插入'%s'本身让优先级降低到先前回答之下。使用逗号分隔多个条目。

当掷骰战利品时，可以透由右键点击'需求'按钮来查阅。]=]
L["OPT_MASTERLOOT_RULES_TIMEOUT_BASE"] = "ROLL装时间(基本)"
L["OPT_MASTERLOOT_RULES_TIMEOUT_BASE_DESC"] = "无论掉落多少物品，ROLL装的基本运行时间。"
L["OPT_MASTERLOOT_RULES_TIMEOUT_PER_ITEM"] = "ROLL装时间(每项物品)"
L["OPT_MASTERLOOT_RULES_TIMEOUT_PER_ITEM_DESC"] = "将每个掉落的物品都加入到基本ROLL装运行时间。"
L["OPT_MASTERLOOT_RULES_VOTE_PUBLIC"] = "投票公开"
L["OPT_MASTERLOOT_RULES_VOTE_PUBLIC_DESC"] = "你可以让议会表决公开透明，所以每个人都可以看到谁有多少票。"
L["OPT_MASTERLOOT_SAVE"] = "储存"
L["OPT_MASTERLOOT_SAVE_DESC"] = "储存你当前的分装设置到你公会/社群的说明讯息。"

-- Options - Messages
L["OPT_CUSTOM_MESSAGES"] = "自订讯息"
L["OPT_CUSTOM_MESSAGES_DEFAULT"] = "预设语言 (%s)"
L["OPT_CUSTOM_MESSAGES_DEFAULT_DESC"] = "当收讯息的人说%s或非你服务器预设的语言时(%s)，将使用这些讯息。"
L["OPT_CUSTOM_MESSAGES_DESC"] = "你可以重新排列占位符(|cffffff00%s|r, |cffffff00%d|r)透过在中间添加它们的位置和$符号，例如：像第二个占位符可以用|cffffff00%2$s|r取代|cffffff00%s|r，详情请看工具提示。"
L["OPT_CUSTOM_MESSAGES_LOCALIZED"] = "服务器语言 (%s)"
L["OPT_CUSTOM_MESSAGES_LOCALIZED_DESC"] = "当收讯人说你服务器的预设语言时(%s)使用这些讯息。"
L["OPT_ECHO"] = "聊天资讯"
L["OPT_ECHO_DEBUG"] = "侦错"
L["OPT_ECHO_DESC"] = [=[你想要在聊天中显示多少插件的资讯？

|cffffff00无:|r 聊天中无资讯。 
|cffffff00错误:|r 只有错误讯息。 
|cffffff00资讯:|r 你可能会采取行动的错误与有用讯息。 
|cffffff00详细:|r 获取有关插件所做的任何事情的通知。
|cffffff00侦错:|r 类似于详细，但有额外侦错讯息。]=]
L["OPT_ECHO_ERROR"] = "错误"
L["OPT_ECHO_INFO"] = "资讯"
L["OPT_ECHO_NONE"] = "无"
L["OPT_ECHO_VERBOSE"] = "详细"
L["OPT_GROUPCHAT"] = "团队聊天频道"
L["OPT_GROUPCHAT_ANNOUNCE"] = "公告ROLL装以及赢家"
L["OPT_GROUPCHAT_ANNOUNCE_DESC"] = "在队伍/团队/副本聊天中公告你的ROLL装以及ROLL装的获得者。"
L["OPT_GROUPCHAT_DESC"] = "更改插件是否要将骰装公告到团体聊天中。"
L["OPT_GROUPCHAT_GROUP_TYPE"] = "公告依据团队类型"
L["OPT_GROUPCHAT_GROUP_TYPE_DESC"] = [=[只有当你是处于以下团队类型时发送到团队聊天。

|cffffff78公会团队：|r团队的%d%%或更多的成员是来自一个公会。
|cffffff78社群团队：|r团队的%d%%或更多的成员是来自一个魔兽社群。]=]
L["OPT_GROUPCHAT_ROLL"] = "在聊天中掷骰战利品"
L["OPT_GROUPCHAT_ROLL_DESC"] = "如果其他人在团体聊天中贴出物品信息，请掷骰你要的战利品(/roll)。"
L["OPT_MESSAGES"] = "讯息"
L["OPT_MSG_BID"] = "询问战利品: 异色版 %d"
L["OPT_MSG_BID_DESC"] = "1：物品连接"
L["OPT_MSG_ROLL_ANSWER_AMBIGUOUS"] = "回答：发给我物品信息"
L["OPT_MSG_ROLL_ANSWER_AMBIGUOUS_DESC"] = ""
L["OPT_MSG_ROLL_ANSWER_BID"] = "回答：竞标已登记"
L["OPT_MSG_ROLL_ANSWER_BID_DESC"] = "1：物品连接"
L["OPT_MSG_ROLL_ANSWER_NO_OTHER"] = "回答：我已经给了別人"
L["OPT_MSG_ROLL_ANSWER_NO_OTHER_DESC"] = ""
L["OPT_MSG_ROLL_ANSWER_NO_SELF"] = "回答：我自己也有需求"
L["OPT_MSG_ROLL_ANSWER_NO_SELF_DESC"] = ""
L["OPT_MSG_ROLL_ANSWER_NOT_TRADABLE"] = "回答：这件无法交易"
L["OPT_MSG_ROLL_ANSWER_NOT_TRADABLE_DESC"] = ""
L["OPT_MSG_ROLL_ANSWER_YES"] = "回答：你可以得到它"
L["OPT_MSG_ROLL_ANSWER_YES_DESC"] = ""
L["OPT_MSG_ROLL_ANSWER_YES_MASTERLOOT"] = "回答：你可以得到它(如同队长分配)"
L["OPT_MSG_ROLL_ANSWER_YES_MASTERLOOT_DESC"] = "1：物品提供者"
L["OPT_MSG_ROLL_START"] = "通告新的骰装"
L["OPT_MSG_ROLL_START_DESC"] = [=[1：物品连接
2：掷骰数字]=]
L["OPT_MSG_ROLL_START_MASTERLOOT"] = "通告新的ROLL装 (作为分装者)"
L["OPT_MSG_ROLL_START_MASTERLOOT_DESC"] = [=[1：物品连接
2：物品提供者
3：掷骰数字]=]
L["OPT_MSG_ROLL_WINNER"] = "通告ROLL装获胜者"
L["OPT_MSG_ROLL_WINNER_DESC"] = [=[1：获胜者
2：物品连接]=]
L["OPT_MSG_ROLL_WINNER_MASTERLOOT"] = "通告ROLL装的获胜者 (如同队长分配)"
L["OPT_MSG_ROLL_WINNER_MASTERLOOT_DESC"] = [=[1：获胜者
2：物品连接
3：物品提供者
4：他/她]=]
L["OPT_MSG_ROLL_WINNER_WHISPER"] = "密语ROLL装获胜者"
L["OPT_MSG_ROLL_WINNER_WHISPER_DESC"] = "1：物品连接"
L["OPT_MSG_ROLL_WINNER_WHISPER_MASTERLOOT"] = "密语ROLL装获胜者 (如同队长分配)"
L["OPT_MSG_ROLL_WINNER_WHISPER_MASTERLOOT_DESC"] = [=[1：物品连接
2：物品提供者
3：他/她]=]
L["OPT_MSG_ROLL_DISENCHANT"] = "Announcing a disenchanter" -- Translation missing
L["OPT_MSG_ROLL_DISENCHANT_DESC"] = [=[1: Disenchanter
2: Item link]=] -- Translation missing
L["OPT_MSG_ROLL_DISENCHANT_MASTERLOOT"] = "Announcing a disenchanter (as masterlooter)" -- Translation missing
L["OPT_MSG_ROLL_DISENCHANT_MASTERLOOT_DESC"] = [=[1: Disenchanter
2: Item link
3: Item owner
4: him/her]=] -- Translation missing
L["OPT_MSG_ROLL_DISENCHANT_WHISPER"] = "Whispering the disenchanter" -- Translation missing
L["OPT_MSG_ROLL_DISENCHANT_WHISPER_DESC"] = "1: Item link" -- Translation missing
L["OPT_MSG_ROLL_DISENCHANT_WHISPER_MASTERLOOT"] = "Whispering the disenchanter (as masterlooter)" -- Translation missing
L["OPT_MSG_ROLL_DISENCHANT_WHISPER_MASTERLOOT_DESC"] = [=[1: Item link
2: Item owner
3: him/her]=] -- Translation missing
L["OPT_SHOULD_CHAT"] = "启用/停用"
L["OPT_SHOULD_CHAT_DESC"] = "决定插件何时发布到队伍/团队聊天并密语其他玩家。"
L["OPT_WHISPER"] = "聊天密语"
L["OPT_WHISPER_ANSWER"] = "回答询问"
L["OPT_WHISPER_ANSWER_DESC"] = "让插件自动回答来自队伍/团队成员的关于你拾取物品的密语。"
L["OPT_WHISPER_ASK"] = "询问战利品"
L["OPT_WHISPER_ASK_DESC"] = "当他人拾取你想要的战利品时密语他们。"
L["OPT_WHISPER_DESC"] = "更改插件是否会密语其他玩家并且/或回应其他人的讯息。"
L["OPT_WHISPER_GROUP"] = "密语根据团队类型"
L["OPT_WHISPER_GROUP_DESC"] = "如果其他人拾取你想要的物品则密语他们，这取决于你目前所处的团队类型。"
L["OPT_WHISPER_GROUP_TYPE"] = "讯问根据团队类型"
L["OPT_WHISPER_GROUP_TYPE_DESC"] = [=[只有当你处于以下类型团体时才讯问战利品。

|cffffff78公会团队：|r团队的%d%%或更多的成员是来自一个公会。
|cffffff78社群团队：|r团队的%d%%或更多的成员是来自一个魔兽社群。]=]
L["OPT_WHISPER_SUPPRESS"] = "阻止询问"
L["OPT_WHISPER_SUPPRESS_DESC"] = "当你放弃战利品时，阻止来自符合条件玩家的密语讯息。"
L["OPT_WHISPER_TARGET"] = "询问目标"
L["OPT_WHISPER_TARGET_DESC"] = "是否询问战利品取决于目标是否在你的公会或是魔兽社群或是好友名单上。"
L["OPT_WHISPER_ASK_VARIANTS"] = "Enable ask variants" -- Translation missing
L["OPT_WHISPER_ASK_VARIANTS_DESC"] = "Use different lines (see below) when asking for loot, to make it less repetitive." -- Translation missing

-- Roll
L["BID_CHAT"] = "正在询问 %s 为了 %s -> %s。"
L["BID_MAX_WHISPERS"] = "不会问 %s 于 %s，因为你队伍中的玩家 %d 已经询问过 -> %s。"
L["BID_NO_CHAT"] = "密语已禁用，你需要询问%s为了%s由你自己 -> %s。"
L["BID_PASS"] = "已放弃 %s 來自 %s。"
L["BID_START"] = "正在竞标 %q 为了 %s 來自 %s。"
L["MASTERLOOTER_OTHER"] = "%s 现在负责分装。"
L["MASTERLOOTER_SELF"] = "你现在负责分装。"
L["ROLL_AWARDED"] = "已分配"
L["ROLL_AWARDING"] = "分配中"
L["ROLL_CANCEL"] = "已取消ROLL由 %2$s 提供的 %1$s。"
L["ROLL_END"] = "由 %2$s 提供的 %1$s ROLL结束。"
L["ROLL_IGNORING_BID"] = "已忽略 %s 对 %s 的竞标，因为之前已经聊过了 -> 竞标：%s 或 %s。"
L["ROLL_LIST_EMPTY"] = "启用的ROLL会显示在此"
L["ROLL_START"] = "开始ROLL由 %2$s 提供的 %1$s。"
L["ROLL_STATUS_0"] = "处理中"
L["ROLL_STATUS_1"] = "执行中"
L["ROLL_STATUS_-1"] = "已取消"
L["ROLL_STATUS_2"] = "完成"
L["ROLL_TRADED"] = "已交易"
L["ROLL_WHISPER_SUPPRESSED"] = "%s 对 %s竞标 -> %s / %s。"
L["ROLL_WINNER_MASTERLOOT"] = "%1$s 已经赢得由 %3$s 提供的 %2$s。"
L["ROLL_WINNER_OTHER"] = "%s 赢得你提供的 %s -> %s。"
L["ROLL_WINNER_OWN"] = "你赢得自己的 %s。"
L["ROLL_WINNER_SELF"] = "你赢得由 %2$s 提供的 %1$s -> %s。"
L["TRADE_CANCEL"] = "与 %s 取消交易。"
L["TRADE_START"] = "与 %s 开始交易。"

-- Globals
LOOT_ROLL_INELIGIBLE_REASONPLR_NO_ADDON = "物品的提供者并没有使用persolootroll插件。"
LOOT_ROLL_INELIGIBLE_REASONPLR_NO_DISENCHANT = "The owner of this item has not allowed \"Disenchant\" bids." -- Translation missing
LOOT_ROLL_INELIGIBLE_REASONPLR_NOT_ENCHANTER = "Your character doesn't have the \"Enchanting\" profession." -- Translation missing

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
