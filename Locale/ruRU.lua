local Name, Addon = ...
local Locale = Addon.Locale
local lang = "ruRU"

-- Chat messages
local L = {lang = lang}
setmetatable(L, Locale.MT)
Locale[lang] = L

L["MSG_BID_1"] = "Тебе это нужно %s?"
L["MSG_BID_2"] = "Можно мне %s, если тебе не нужно?"
L["MSG_BID_3"] = "Я могу забрать %s, если ты не хочешь."
L["MSG_BID_4"] = "Я бы взял %s, если ты хочешь избавиться от него."
L["MSG_BID_5"] = "Тебе нужно %s, или я могу получить?"
L["MSG_HER"] = "её"
L["MSG_HIM"] = "его"
L["MSG_ITEM"] = "предмет"
L["MSG_ROLL_ANSWER_AMBIGUOUS"] = "Я сейчас раздаю несколько предметов, пожалуйста, пришлите мне ссылку на предмет, который вы хотите."
L["MSG_ROLL_ANSWER_BID"] = "Хорошо, я зарегистрировал твою ставку на %s."
L["MSG_ROLL_ANSWER_NO_OTHER"] = "Извини, я уже отдал кому-то другому."
L["MSG_ROLL_ANSWER_NO_SELF"] = "Извини, я оставлю себе."
L["MSG_ROLL_ANSWER_NOT_TRADABLE"] = "Извини, я не могу передать этот предмет."
L["MSG_ROLL_ANSWER_YES"] = "Ты можешь забрать этот предмет, предложи мне обмен."
L["MSG_ROLL_ANSWER_YES_MASTERLOOT"] = "Ты можешь забрать этот предмет, предложи <%s> обмен."
L["MSG_ROLL_START"] = "Отдаю %s -> /w мне или /roll %d!"
L["MSG_ROLL_START_MASTERLOOT"] = "Отдаю %s от <%s> -> /w мне или /roll %d!"
L["MSG_ROLL_WINNER"] = "<%s> выиграл %s -> Предложи мне обмен!"
L["MSG_ROLL_WINNER_MASTERLOOT"] = "<%s> выиграл %s от <%s> -> Предложи %s обмен!"
L["MSG_ROLL_WINNER_WHISPER"] = "Ты выиграл %s! Предложи мне обмен."
L["MSG_ROLL_WINNER_WHISPER_MASTERLOOT"] = "Ты выиграл %s от <%s>! Предложи %s обмен."
L["MSG_ROLL_DISENCHANT"] = "<%s> will disenchant %s -> Trade me!" -- Translation missing
L["MSG_ROLL_DISENCHANT_MASTERLOOT"] = "<%s> will disenchant %s from <%s> -> Trade %s!" -- Translation missing
L["MSG_ROLL_DISENCHANT_WHISPER"] = "You were picked to disenchant %s, please trade me." -- Translation missing
L["MSG_ROLL_DISENCHANT_WHISPER_MASTERLOOT"] = "You were picked to disenchant %s from <%s>, please trade %s." -- Translation missing

-- Addon
local L = LibStub("AceLocale-3.0"):NewLocale(Name, lang, lang == Locale.FALLBACK)
if not L then return end

L["ACTION"] = "Действие"
L["ACTIONS"] = "Действия"
L["ADVERTISE"] = "Сообщить в чат"
L["ANSWER"] = "Ответ"
L["ASK"] = "Спросить"
L["AWARD"] = "Отдать"
L["AWARD_LOOT"] = "Отдать добычу"
L["AWARD_RANDOMLY"] = "Отдать случайно"
L["BID"] = "Заявка"
L["COMMUNITY_GROUP"] = "Community Group" -- Translation missing
L["COMMUNITY_MEMBER"] = "Community Member" -- Translation missing
L["DISABLED"] = "Отключено"
L["DOWN"] = "вниз"
L["ENABLED"] = "Включено"
L["EQUIPPED"] = "Надетые"
L["GET_FROM"] = "Получено от"
L["GIVE_AWAY"] = "Разыграть"
L["GIVE_TO"] = "Отдать"
L["GUILD_MASTER"] = "Глава гильдии"
L["GUILD_OFFICER"] = "Офицер гильдии"
L["HIDE"] = "Скрыть"
L["HIDE_ALL"] = "Скрыть все"
L["ITEM"] = "предмет"
L["ITEM_LEVEL"] = "Уровень предмета"
L["KEEP"] = "Оставить"
L["LEFT"] = "влево"
L["MASTERLOOTER"] = "Ответственный за добычу"
L["MESSAGE"] = "Сообщение"
L["ML"] = "ОД"
L["OPEN_ROLLS"] = "Открыть окно с бросками"
L["OWNER"] = "Владелец"
L["PLAYER"] = "Игрок"
L["PRIVATE"] = "Приватный"
L["PUBLIC"] = "Публичный"
L["RAID_ASSISTANT"] = "Помощник  рейда"
L["RAID_LEADER"] = "Лидер рейда"
L["RESTART"] = "Перезапуск"
L["RIGHT"] = "вправо"
L["ROLL"] = "Розыгрыш"
L["ROLLS"] = "Розыгрыши"
L["SECONDS"] = "%d с."
L["SET_ANCHOR"] = "Установить привязку: Увеличиваться %s и %s"
L["SHOW"] = "Показать"
L["SHOW_HIDE"] = "Показать/Скрыть"
L["TRADE"] = "Обмен"
L["UP"] = "вверх"
L["VERSION_NOTICE"] = "Доступна новая версия этого аддона. Пожалуйста, обновите, чтобы оставаться совместимым со всеми и не пропустить ни одной добычи!"
L["VOTE"] = "Голос"
L["VOTE_WITHDRAW"] = "Отозвать"
L["VOTES"] = "Голоса"
L["WINNER"] = "Победитель"
L["WON"] = "Выиграл"
L["YOUR_BID"] = "Ваша заявка"

-- Commands
L["HELP"] = [=[Начать розыгрыши предметов (/PersoLootRoll или /plr).
Использование:
/plr: Открыть настройки
/plr roll [предмет]* (<таймаут> <владелец>): Начать розыгрыш одного и более предметов
/plr bid [предмет] (<владелец> <bid>): Ставка на предмет от другого игрока
/plr options: Открыть настройки
/plr config: Изменить настройки через команды чата
/plr help: Показать это сообщение
Легенда: [..] = ссылка на предмет, * = один и более раз, (..) = опционально]=]
L["USAGE_BID"] = "Использование: /plr bid [предмет] (<владелец> <bid>)"
L["USAGE_ROLL"] = "Использование: /plr roll [предмет]* (<таймаут> <владелец>)"

-- Errors
L["ERROR_CMD_UNKNOWN"] = "Неизвестная команда '%s' "
L["ERROR_ITEM_NOT_TRADABLE"] = "Вы не можете передать этот предмет."
L["ERROR_NOT_IN_GROUP"] = "Вы не в группе или рейде."
L["ERROR_OPT_MASTERLOOT_EXPORT_FAILED"] = "Exporting masterloot settings to <%s> failed!" -- Translation missing
L["ERROR_PLAYER_NOT_FOUND"] = "Игрок %q не найден."
L["ERROR_ROLL_BID_IMPOSSIBLE_OTHER"] = "%s отправил заявку на %s, но сейчас это не разрешено."
L["ERROR_ROLL_BID_IMPOSSIBLE_SELF"] = "Вы не можете делать заявки на этот предмет прямо сейчас."
L["ERROR_ROLL_BID_UNKNOWN_OTHER"] = "%s отправил недопустимую заявку для %s."
L["ERROR_ROLL_BID_UNKNOWN_SELF"] = "Это неправильная заявка."
L["ERROR_ROLL_STATUS_NOT_0"] = "Этот бросок уже был начат или завершен."
L["ERROR_ROLL_STATUS_NOT_1"] = "Розыгрыш не запущен."
L["ERROR_ROLL_UNKNOWN"] = "Этот бросок не существует."
L["ERROR_ROLL_VOTE_IMPOSSIBLE_OTHER"] = "%s проголосовал за %s, но сейчас это не разрешено."
L["ERROR_ROLL_VOTE_IMPOSSIBLE_SELF"] = "Вы не можете проголосовать прямо сейчас."
L["ERROR_NOT_MASTERLOOTER_OTHER_OWNER"] = "You need to become masterlooter to create rolls for other player's items." -- Translation missing
L["ERROR_NOT_MASTERLOOTER_TIMEOUT"] = "You cannot change the timeout while having a masterlooter other than yourself." -- Translation missing

-- GUI
L["DIALOG_MASTERLOOT_ASK"] = "<%s> хочет стать вашим ответственным за добычу."
L["DIALOG_OPT_MASTERLOOT_LOAD"] = "This will replace your current masterloot settings with those stored in the guild/community info, are you sure you want to proceed?" -- Translation missing
L["DIALOG_OPT_MASTERLOOT_SAVE"] = "This will replace any masterloot settings in the guild/community info with your current settings, are you sure you want to proceed?" -- Translation missing
L["DIALOG_ROLL_CANCEL"] = "Вы действительно хотите отменить этот бросок?"
L["DIALOG_ROLL_RESTART"] = "Вы действительно хотите перезапустить этот бросок?"
L["FILTER"] = "Фильтр"
L["FILTER_ALL"] = "Для всех игроков"
L["FILTER_ALL_DESC"] = "Показать не только Ваши розыгрыши, а всех игроков или тех, у кого есть предметы, которые могут вас заинтересовать."
L["FILTER_AWARDED"] = "Выигранные"
L["FILTER_AWARDED_DESC"] = "Показать розыгрыши, выигранные кем-то."
L["FILTER_DONE"] = "Завершенные"
L["FILTER_DONE_DESC"] = "Показать завершенные розыгрыши."
L["FILTER_HIDDEN"] = "Скрытые"
L["FILTER_HIDDEN_DESC"] = "Показать отмененные, ожидающие, пропущенные и скрытые розыгрыши."
L["FILTER_TRADED"] = "Отданы"
L["FILTER_TRADED_DESC"] = "Показать розыгрыши предметов, которые были отданы.  "
L["MENU_MASTERLOOT_SEARCH"] = "Поиск ответственного за добычу"
L["MENU_MASTERLOOT_START"] = "Стать ответственным за добычу"
L["TIP_ADDON_MISSING"] = "Аддон отсутствует:"
L["TIP_ADDON_VERSIONS"] = "Версии аддона:"
L["TIP_CHAT_TO_TRADE"] = "Please ask the owner first before trading" -- Translation missing
L["TIP_ENABLE_WHISPER_ASK"] = "Совет: щелкните правой кнопкой мыши, чтобы автоматически запрашивать добычу"
L["TIP_MASTERLOOT"] = "Ответственный за добычу активен"
L["TIP_MASTERLOOT_INFO"] = [=[|cffffff78Ответственный за добычу:|r %s
|cffffff78Период розыгрыша:|r %d с. (+ %d с. на предмет)
|cffffff78Совет:|r %s
|cffffff78Заявки:|r %s
|cffffff78Голоса:|r %s]=]
L["TIP_MASTERLOOT_START"] = "Стать или искать ответственного за добычу"
L["TIP_MASTERLOOT_STOP"] = "Убрать ответственного за добычу"
L["TIP_MASTERLOOTING"] = "Группа ответственного за добычу:"
L["TIP_MINIMAP_ICON"] = [=[|cffffff78Left-Click:|r Показать окно с бросками
|cffffff78Right-Click:|r Открыть настройки]=]
L["TIP_PLH_USERS"] = "PLH пользователи:"
L["TIP_VOTES"] = "Голоса от:"

-- Options - Home
L["OPT_ACTIONS_WINDOW"] = "Показать окно действий"
L["OPT_ACTIONS_WINDOW_DESC"] = "Показать окно действий, когда есть ожидающие действия, например, когда выиграли предмет и нужно предложить обмен, чтобы получить его."
L["OPT_ACTIONS_WINDOW_MOVE"] = "Переместить"
L["OPT_ACTIONS_WINDOW_MOVE_DESC"] = "Переместить окно действий."
L["OPT_ALLOW_DISENCHANT"] = "Allow \"Disenchant\" bids" -- Translation missing
L["OPT_ALLOW_DISENCHANT_DESC"] = "Allow others to bid \"Disenchant\" on your own items." -- Translation missing
L["OPT_AUTHOR"] = "|cffffd100Автор:|r Shrugal (EU-Mal'Ganis)"
L["OPT_AWARD_SELF"] = "Выберите победителя ваших предметов самостоятельно"
L["OPT_AWARD_SELF_DESC"] = "Выбирать самому кто получит вашу добычу, вместо того чтобы аддон случайно выбирал. Эта опция всегда включена, когда вы ответственный за добычу."
L["OPT_BID_PUBLIC"] = "Публичные заявки"
L["OPT_BID_PUBLIC_DESC"] = "Заявки в ваших розыгрышах являются публичными, поэтому все с аддоном могут их видеть."
L["OPT_CHILL_MODE"] = "Chill mode" -- Translation missing
L["OPT_CHILL_MODE_DESC"] = [=[The intent of chill mode is to take the pressure out of sharing the loot, even if that means that things will take a bit longer. If you enable it the following things will change:

|cffffff781.|r Rolls from you won't start until you actually decided to share them, so you have as much time as you want to choose, and other addon users won't see your items until you did.
|cffffff782.|r Rolls from you have double the normal run-time, or no run-time at all if you enabled to choose winners of your own items yourself (see next option).
|cffffff783.|r Rolls from non-addon users in your group also stay open until you decided if you want them or not.

|cffff0000IMPORTANT:|r Rolls from other addon users without chill mode active will still have a normal timeout. Make sure that everyone in your group enables this option if you want a chill run.]=] -- Translation missing
L["OPT_DONT_SHARE"] = "Не делиться добычей"
L["OPT_DONT_SHARE_DESC"] = "Не участвовать в розыгрышах добычи от других и не делиться своей добычей. Аддон будет отклонять входящие запросы на вашу добычу (если включено), и вы все еще можете быть ответственным за добычу и членом совета."
L["OPT_ENABLE"] = "Включить"
L["OPT_ENABLE_DESC"] = "Включить или отключить аддон"
L["OPT_ACTIVE_GROUPS"] = "Activate by group type" -- Translation missing
L["OPT_ACTIVE_GROUPS_DESC"] = [=[Activate only when you are in one of these group types.

|cffffff78Гильдейская группа:|r Кто-то из гильдии, члены которой составляют %d%% или более группы.
|cffffff78Community Group:|r The members of one of your WoW-Communities make up %d%% or more of the group.]=] -- Translation missing
L["OPT_ILVL_THRESHOLD"] = "Диапазон уровней предметов"
L["OPT_ILVL_THRESHOLD_DESC"] = "Предметы, уровень которых ниже ваших, игнорируются."
L["OPT_ILVL_THRESHOLD_TRINKETS"] = "Удвоить диапазон для аксессуаров"
L["OPT_ILVL_THRESHOLD_TRINKETS_DESC"] = "Аксессуары должны иметь двойной диапазон, потому что эффекты на них могут сделать их ценность больше."
L["OPT_ILVL_THRESHOLD_RINGS"] = "Double threshold for rings" -- Translation missing
L["OPT_ILVL_THRESHOLD_RINGS_DESC"] = "Rings should have double the normal threshold because their value may vary by a large amount due to missing primary stats." -- Translation missing
L["OPT_INFO"] = "Информация"
L["OPT_INFO_DESC"] = "Немного информации об этом аддоне."
L["OPT_ITEM_FILTER"] = "Фильтр предметов"
L["OPT_ITEM_FILTER_DESC"] = "Change which items you are asked to roll on." -- Translation missing
L["OPT_MINIMAP_ICON"] = "Показать значок у мини-карты"
L["OPT_MINIMAP_ICON_DESC"] = "Показать или скрыть значок у мини-карты."
L["OPT_ONLY_MASTERLOOT"] = "Только ответственный за добычу"
L["OPT_ONLY_MASTERLOOT_DESC"] = "Включать аддон только когда используется 'ответственный за добычу' (например, в гильдии)"
L["OPT_PAWN"] = "Check \"Pawn\"" -- Translation missing
L["OPT_PAWN_DESC"] = "Only roll on items that are an upgrade according to the \"Pawn\" addon." -- Translation missing
L["OPT_ROLL_FRAMES"] = "Показать панели розыгрышей"
L["OPT_ROLL_FRAMES_DESC"] = "Показать панели розыгрышей, когда кто-либо получает добычу, в которой вы можете быть заинтересованы."
L["OPT_ROLLS_WINDOW"] = "Показать окно розыгрышей"
L["OPT_ROLLS_WINDOW_DESC"] = "Always show the rolls window (with all rolls on it) when someone loots something you might be interested in. This is always enabled when you are a masterlooter." -- Translation missing
L["OPT_SPECS"] = "Специализации"
L["OPT_SPECS_DESC"] = "Предлагать добычу только для этих специализаций."
L["OPT_TRANSLATION"] = "|cffffd100Перевод:|r Боонер (EU-Галакронд)"
L["OPT_TRANSMOG"] = "Проверять на трансмогрификацию."
L["OPT_TRANSMOG_DESC"] = "Участвовать в розыгрышах предметов, которых нет в коллекции моделей."
L["OPT_DISENCHANT"] = "Disenchant" -- Translation missing
L["OPT_DISENCHANT_DESC"] = "Bid \"Disenchant\" on items you can't use if you have the profession and the item owner has allowed it." -- Translation missing
L["OPT_UI"] = "Пользовательский интерфейс"
L["OPT_UI_DESC"] = "Настройте внешний вид %s по своему вкусу."
L["OPT_VERSION"] = "|cffffd100Версия:|r %s"

-- Options - Masterloot
L["OPT_MASTERLOOT"] = "Masterloot" -- Translation missing
L["OPT_MASTERLOOT_APPROVAL"] = "Утверждение"
L["OPT_MASTERLOOT_APPROVAL_ACCEPT"] = "Автоматически принимать ответственного за добычу"
L["OPT_MASTERLOOT_APPROVAL_ACCEPT_DESC"] = "Автоматически принимать запросы на 'ответственного за добычу' от этих игроков"
L["OPT_MASTERLOOT_APPROVAL_ALLOW"] = "Разрешить стать ответственным за добычу"
L["OPT_MASTERLOOT_APPROVAL_ALLOW_ALL"] = "Разрешить всем"
L["OPT_MASTERLOOT_APPROVAL_ALLOW_ALL_DESC"] = "|cffff0000ПРЕДУПРЕЖДЕНИЕ:|r Это разрешит всем запрашивать стать вашим ответственным за добычу и возможно вас могут обмануть, чтобы вы отдали свою добычу! Включайте это только, если вы знаете, что делаете."
L["OPT_MASTERLOOT_APPROVAL_ALLOW_DESC"] = [=[Выбрать кто может делать запрос на то, чтобы стать вашим ответственным за добычу. Вы всё равно будете получать выскакивающие сообщения, спрашивающие вашего разрешения, где вы сможете отклонить подобный запрос.

|cffffff78Гильдейская группа:|r Кто-то из гильдии, члены которой составляют %d%% или более группы.]=]
L["OPT_MASTERLOOT_APPROVAL_DESC"] = "Здесь вы можете задать кто может стать вашим ответственным за добычу."
L["OPT_MASTERLOOT_APPROVAL_WHITELIST"] = "Белый список ответственных за добычу"
L["OPT_MASTERLOOT_APPROVAL_WHITELIST_DESC"] = "Вы также можете указать имена персонажей, которые могут стать вашим ответственным за добычу. Разделяйте имена пробелами или запятыми."
L["OPT_MASTERLOOT_CLUB"] = "Guild/Community" -- Translation missing
L["OPT_MASTERLOOT_CLUB_DESC"] = "Select the Guild/Community to import/export settings from." -- Translation missing
L["OPT_MASTERLOOT_COUNCIL"] = "Совет"
L["OPT_MASTERLOOT_COUNCIL_CLUB_RANK"] = "Гильдейское звание для совета"
L["OPT_MASTERLOOT_COUNCIL_CLUB_RANK_DESC"] = "Add members of this guild/community rank to you council, in addition to the options above." -- Translation missing
L["OPT_MASTERLOOT_COUNCIL_DESC"] = "Players on your loot council can vote on who should get the loot." -- Translation missing
L["OPT_MASTERLOOT_COUNCIL_ROLES"] = "Council roles" -- Translation missing
L["OPT_MASTERLOOT_COUNCIL_ROLES_DESC"] = "Which players should automatically become part of your council." -- Translation missing
L["OPT_MASTERLOOT_COUNCIL_WHITELIST"] = "Council whitelist" -- Translation missing
L["OPT_MASTERLOOT_COUNCIL_WHITELIST_DESC"] = "You can also name specific players to be on your council. Separate multiple names with spaces or commas." -- Translation missing
L["OPT_MASTERLOOT_DESC"] = "Когда вы или кто-то другой становитесь ответственным за добычу, вся добыча будет распределяться этим человеком. Вы получите уведомление о том, чьи предметы вы выиграли или кто выиграл ваши, так что вы сможете произвести обмен с нужным человеком."
L["OPT_MASTERLOOT_EXPORT_DONE"] = "Masterloot settings successfully exported to <%s>." -- Translation missing
L["OPT_MASTERLOOT_EXPORT_GUILD_ONLY"] = "Please replace the community's current info with this text, because automatically replacing it is only possible for guilds." -- Translation missing
L["OPT_MASTERLOOT_EXPORT_NO_PRIV"] = "Please ask a leader to replace the guild's info with this text, because you don't have the right to do so yourself." -- Translation missing
L["OPT_MASTERLOOT_EXPORT_WINDOW"] = "Export masterloot settings" -- Translation missing
L["OPT_MASTERLOOT_LOAD"] = "Load" -- Translation missing
L["OPT_MASTERLOOT_LOAD_DESC"] = "Load masterloot settings from your guild/community's description." -- Translation missing
L["OPT_MASTERLOOT_RULES"] = "Правила"
L["OPT_MASTERLOOT_RULES_AUTO_AWARD"] = "Award loot automatically" -- Translation missing
L["OPT_MASTERLOOT_RULES_AUTO_AWARD_DESC"] = "Let the addon decide who should get the loot, based on factors like council votes, bids and equipped ilvl." -- Translation missing
L["OPT_MASTERLOOT_RULES_AUTO_AWARD_TIMEOUT"] = "Auto award time (base)" -- Translation missing
L["OPT_MASTERLOOT_RULES_AUTO_AWARD_TIMEOUT_DESC"] = "The base time to wait before auto-awarding loot, so you have time to collect votes and maybe decide for yourself." -- Translation missing
L["OPT_MASTERLOOT_RULES_AUTO_AWARD_TIMEOUT_PER_ITEM"] = "Auto award time (per item)" -- Translation missing
L["OPT_MASTERLOOT_RULES_AUTO_AWARD_TIMEOUT_PER_ITEM_DESC"] = "Will be added to the base auto award time for each item that dropped." -- Translation missing
L["OPT_MASTERLOOT_RULES_BID_PUBLIC"] = "Публичные заявки"
L["OPT_MASTERLOOT_RULES_BID_PUBLIC_DESC"] = "Вы можете сделать заявки публичными, чтобы все могли видеть, кто на что делает заявки."
L["OPT_MASTERLOOT_RULES_DESC"] = "Эти настройки применяются ко всем, когда вы ответственный за добычу."
L["OPT_MASTERLOOT_RULES_ALLOW_DISENCHANT_DESC"] = "Allow group members to roll \"Disenchant\" on items." -- Translation missing
L["OPT_MASTERLOOT_RULES_DISENCHANTER"] = "Disenchanter" -- Translation missing
L["OPT_MASTERLOOT_RULES_DISENCHANTER_DESC"] = "Give loot nobody wants to these players for disenchanting. Separate multiple names with spaces or commas." -- Translation missing
L["OPT_MASTERLOOT_RULES_GREED_ANSWERS"] = "Custom 'Greed' answers" -- Translation missing
L["OPT_MASTERLOOT_RULES_GREED_ANSWERS_DESC"] = [=[Specify up to 9 custom answers when rolling 'Greed', with decreasing priority. You can also insert '%s' itself to lower its priority below the prior answers. Separate multiple entries with Commas.

They can be accessed by right-clicking on the 'Greed' button when rolling on loot.]=] -- Translation missing
L["OPT_MASTERLOOT_RULES_NEED_ANSWERS"] = "Настраиваемые ответы 'Нужно'"
L["OPT_MASTERLOOT_RULES_NEED_ANSWERS_DESC"] = [=[Specify up to 9 custom answers when rolling 'Need', with decreasing priority. You can also insert '%s' itself to lower its priority below the prior answers. Separate multiple entries with Commas.

They can be accessed by right-clicking on the 'Need' button when rolling on loot.]=] -- Translation missing
L["OPT_MASTERLOOT_RULES_TIMEOUT_BASE"] = "Roll time (base)" -- Translation missing
L["OPT_MASTERLOOT_RULES_TIMEOUT_BASE_DESC"] = "The base running time for rolls, regardless of how many items have dropped." -- Translation missing
L["OPT_MASTERLOOT_RULES_TIMEOUT_PER_ITEM"] = "Roll time (per item)" -- Translation missing
L["OPT_MASTERLOOT_RULES_TIMEOUT_PER_ITEM_DESC"] = "Will be added to the base roll running time for each item that dropped." -- Translation missing
L["OPT_MASTERLOOT_RULES_VOTE_PUBLIC"] = "Совет голосует открыто"
L["OPT_MASTERLOOT_RULES_VOTE_PUBLIC_DESC"] = "Вы можете сделать, чтобы совет голосовал открыто, чтобы каждый мог увидеть, у кого сколько голосов."
L["OPT_MASTERLOOT_SAVE"] = "Save" -- Translation missing
L["OPT_MASTERLOOT_SAVE_DESC"] = "Save your current masterloot settings to your guild/community's description." -- Translation missing

-- Options - Messages
L["OPT_CUSTOM_MESSAGES"] = "Пользовательские сообщения"
L["OPT_CUSTOM_MESSAGES_DEFAULT"] = "Язык по умолчанию (%s)"
L["OPT_CUSTOM_MESSAGES_DEFAULT_DESC"] = "Эти сообщения будут использованы, когда получатель говорит на %s или каком-либо другом, отличающимся от стандартного языка вашего игрового мира (%s)."
L["OPT_CUSTOM_MESSAGES_DESC"] = "Вы можете поменять порядок меток (|cffffff78%s|r, |cffffff78%d|r) добавив их позицию и знак $ в середине, например |cffffff78%2$s|r вместо |cffffff78%s|r для второй метки. Смотри подсказки для подробностей."
L["OPT_CUSTOM_MESSAGES_LOCALIZED"] = "Язык игрового мира (%s)"
L["OPT_CUSTOM_MESSAGES_LOCALIZED_DESC"] = "Эти сообщения будут использоваться, когда у получателя совпадает язык игрового мира с вашим (%s)."
L["OPT_ECHO"] = "Информация в чат"
L["OPT_ECHO_DEBUG"] = "Отладка"
L["OPT_ECHO_DESC"] = [=[Сколько информации вы хотите видеть от аддона в чате?

|cffffff78Отключено:|r Нисколько.
|cffffff78Ошибка:|r Только ошибки.
|cffffff78Инфо:|r Ошибки и полезная информация, на которую можно обратить внимание.
|cffffff78Подробно:|r Все сообщения о том, что делает аддон.
|cffffff78Отладка:|r Как и "Подробно" плюс дополнительная отладочная информация.]=]
L["OPT_ECHO_ERROR"] = "Ошибка"
L["OPT_ECHO_INFO"] = "Инфо"
L["OPT_ECHO_NONE"] = "Отключено"
L["OPT_ECHO_VERBOSE"] = "Подробно"
L["OPT_GROUPCHAT"] = "Чат группы"
L["OPT_GROUPCHAT_ANNOUNCE"] = "Анонсировать розыгрыши и победителей"
L["OPT_GROUPCHAT_ANNOUNCE_DESC"] = "Объявлять ваши розыгрыши и победителей в чате группы."
L["OPT_GROUPCHAT_DESC"] = "Будет ли аддон публиковать сообщения в чате группы."
L["OPT_GROUPCHAT_GROUP_TYPE"] = "Объявлять по типу группы"
L["OPT_GROUPCHAT_GROUP_TYPE_DESC"] = [=[Отправлять сообщения в чат группы, только если вы находитесь в группе одного из этих типов.

|cffffff78Гильдейская группа:|r Кто-то из гильдии, члены которой составляют %d%% или более группы.
|cffffff78Community Group:|r The members of one of your WoW-Communities make up %d%% or more of the group.]=] -- Translation missing
L["OPT_GROUPCHAT_ROLL"] = "Roll on loot in chat" -- Translation missing
L["OPT_GROUPCHAT_ROLL_DESC"] = "Roll on loot you want (/roll) if others post links in group chat." -- Translation missing
L["OPT_MESSAGES"] = "Сообщения"
L["OPT_MSG_BID"] = "Запросить добычу: Вариант %d"
L["OPT_MSG_BID_DESC"] = "1: Ссылка на предмет"
L["OPT_MSG_ROLL_ANSWER_AMBIGUOUS"] = "Ответ: отправьте мне ссылку на предмет"
L["OPT_MSG_ROLL_ANSWER_AMBIGUOUS_DESC"] = "" -- Translation missing
L["OPT_MSG_ROLL_ANSWER_BID"] = "Ответ: Заявка зарегистрирована"
L["OPT_MSG_ROLL_ANSWER_BID_DESC"] = "1: Ссылка на предмет"
L["OPT_MSG_ROLL_ANSWER_NO_OTHER"] = "Ответ: Я уже отдал кому-то другому"
L["OPT_MSG_ROLL_ANSWER_NO_OTHER_DESC"] = "" -- Translation missing
L["OPT_MSG_ROLL_ANSWER_NO_SELF"] = "Ответ: Мне нужно самому"
L["OPT_MSG_ROLL_ANSWER_NO_SELF_DESC"] = "" -- Translation missing
L["OPT_MSG_ROLL_ANSWER_NOT_TRADABLE"] = "Ответ: Предмет непередаваемый"
L["OPT_MSG_ROLL_ANSWER_NOT_TRADABLE_DESC"] = "" -- Translation missing
L["OPT_MSG_ROLL_ANSWER_YES"] = "Ответ: Ты можешь получить"
L["OPT_MSG_ROLL_ANSWER_YES_DESC"] = "" -- Translation missing
L["OPT_MSG_ROLL_ANSWER_YES_MASTERLOOT"] = "Answer: You can have it (as masterlooter)" -- Translation missing
L["OPT_MSG_ROLL_ANSWER_YES_MASTERLOOT_DESC"] = "1: Владелец предмета"
L["OPT_MSG_ROLL_START"] = "Объявление нового розыгрыша"
L["OPT_MSG_ROLL_START_DESC"] = [=[1: Ссылка на предмет
2: Номер розыгрыша]=]
L["OPT_MSG_ROLL_START_MASTERLOOT"] = "Announcing a new roll (as masterlooter)" -- Translation missing
L["OPT_MSG_ROLL_START_MASTERLOOT_DESC"] = [=[1: Ссылка на предмет
2: Владелец предмета
3: Номер розыгрыша]=]
L["OPT_MSG_ROLL_WINNER"] = "Объявление победителя розыгрыша"
L["OPT_MSG_ROLL_WINNER_DESC"] = [=[1: Победитель
2: Ссылка на предмет]=]
L["OPT_MSG_ROLL_WINNER_MASTERLOOT"] = "Announcing a roll winner (as masterlooter)" -- Translation missing
L["OPT_MSG_ROLL_WINNER_MASTERLOOT_DESC"] = [=[1: Победитель
2: Ссылка на предмет
3: Владелец предмета
4: его/её]=]
L["OPT_MSG_ROLL_WINNER_WHISPER"] = "Whispering the roll winner" -- Translation missing
L["OPT_MSG_ROLL_WINNER_WHISPER_DESC"] = "1: Ссылка на предмет"
L["OPT_MSG_ROLL_WINNER_WHISPER_MASTERLOOT"] = "Whispering the roll winner (as masterlooter)" -- Translation missing
L["OPT_MSG_ROLL_WINNER_WHISPER_MASTERLOOT_DESC"] = [=[1: Ссылка на предмет
2: Владелец предмета
3: его/её]=]
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
L["OPT_SHOULD_CHAT"] = "Включить/Отключить"
L["OPT_SHOULD_CHAT_DESC"] = "Задайте когда аддон будет отправлять сообщения в чат группы/рейда и шептать другим игрокам."
L["OPT_WHISPER"] = "Шёпот"
L["OPT_WHISPER_ANSWER"] = "Ответить на запросы"
L["OPT_WHISPER_ANSWER_DESC"] = "Позволить аддону отвечать на личные сообщения от членов группы по поводу вещей, которые вы получили."
L["OPT_WHISPER_ASK"] = "Спросить про добычу"
L["OPT_WHISPER_ASK_DESC"] = "Шептать другим, если они получили добычу, которую вы хотите."
L["OPT_WHISPER_DESC"] = "Change whether or not the addon will whisper other players and/or answer incoming messages." -- Translation missing
L["OPT_WHISPER_GROUP"] = "Шептать по типу группы"
L["OPT_WHISPER_GROUP_DESC"] = "Whisper others if they got loot you want, depending on the type of group you are currently in." -- Translation missing
L["OPT_WHISPER_GROUP_TYPE"] = "Спрашивать по типу группы"
L["OPT_WHISPER_GROUP_TYPE_DESC"] = [=[Спрашивать про добычу, если вы в одной из этих типов групп.

|cffffff78Гильдейская группа:|r Кто-то из гильдии, члены которой составляют %d%% или более группы.
|cffffff78Community Group:|r The members of one of your WoW-Communities make up %d%% or more of the group.]=] -- Translation outdated
L["OPT_WHISPER_SUPPRESS"] = "Подавлять запросы"
L["OPT_WHISPER_SUPPRESS_DESC"] = "Подавлять входящие личные сообщения от подходящих игроков при розыгрыше добычи."
L["OPT_WHISPER_TARGET"] = "Спросить у цели"
L["OPT_WHISPER_TARGET_DESC"] = "Спросить про добычу в зависимости от того, находится ли цель в вашей гильдии или в списке друзей."
L["OPT_WHISPER_ASK_VARIANTS"] = "Enable ask variants" -- Translation missing
L["OPT_WHISPER_ASK_VARIANTS_DESC"] = "Use different lines (see below) when asking for loot, to make it less repetitive." -- Translation missing

-- Roll
L["BID_CHAT"] = "Спросить %s про %s -> %s."
L["BID_MAX_WHISPERS"] = "Не буду спрашивать %s про %s, потому что %d игроков в вашей группе уже спросили - > %s."
L["BID_NO_CHAT"] = "Не буду спрашивать %s про %s, так как отключено для группы или цели - > %s."
L["BID_PASS"] = "Пропуск %s от %s."
L["BID_START"] = "Bidding with %q for %s from %s." -- Translation missing
L["MASTERLOOTER_OTHER"] = "Теперь %s ответственный за добычу."
L["MASTERLOOTER_SELF"] = "Теперь Вы ответственный за добычу."
L["ROLL_AWARDED"] = "Отдано"
L["ROLL_AWARDING"] = "Awading" -- Translation missing
L["ROLL_CANCEL"] = "Отмена розыгрыша на %s от %s."
L["ROLL_END"] = "Конец розыгрыша %s от %s."
L["ROLL_IGNORING_BID"] = "Игнорирование заявки от %s для %s, потому что вы общались ранее - > Заявка: %s или %s."
L["ROLL_LIST_EMPTY"] = "Активные розыгрыши будут показаны здесь"
L["ROLL_START"] = "Начало розыгрыша на %s от %s."
L["ROLL_STATUS_0"] = "Ожидает"
L["ROLL_STATUS_1"] = "В процессе"
L["ROLL_STATUS_-1"] = "Отменён"
L["ROLL_STATUS_2"] = "Завершён"
L["ROLL_TRADED"] = "Передан"
L["ROLL_WHISPER_SUPPRESSED"] = "Заявка от %s на %s -> %s / %s."
L["ROLL_WINNER_MASTERLOOT"] = "%s выиграл %s от %s."
L["ROLL_WINNER_OTHER"] = "%s выиграл %s от тебя -> %s."
L["ROLL_WINNER_OWN"] = "Ты выиграл собственный предмет %s."
L["ROLL_WINNER_SELF"] = "Ты выиграл %s от %s -> %s."
L["TRADE_CANCEL"] = "Отмена обмена с %s."
L["TRADE_START"] = "Начало обмена с %s."

-- Globals
LOOT_ROLL_INELIGIBLE_REASONPLR_NO_ADDON = "Владелец этого предмета не использует PersoLootRoll."
LOOT_ROLL_INELIGIBLE_REASONPLR_NO_DISENCHANT = "Аддон PersoLootRoll не поддерживает распыление."

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
