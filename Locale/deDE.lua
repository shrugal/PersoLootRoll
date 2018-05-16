local Addon = LibStub("AceAddon-3.0"):GetAddon(PLR_NAME)
local Locale = Addon.Locale
local lang = "deDE"

-- Chat messages
local L = {}
setmetatable(L, Locale.MT)
Locale[lang] = L

L["ROLL_START"] = PLR_CHAT .. " Verrolle %s -> Mich anflüstern!"
L["ROLL_WINNER"] = PLR_CHAT .. " <%s> hat %s gewonnen -> Mich anhandeln!"
L["ROLL_WINNER_WHISPER"] = "Du hast %s gewonnen! Bitte handel mich an."
L["ROLL_ANSWER_BID"] = "Ok, ich hab dein Gebot für %s registriert."
L["ROLL_ANSWER_YES"] = "Du kannst es haben, handel mich einfach an."
L["ROLL_ANSWER_NO_SELF"] = "Tut mir Leid, Ich brauche es selber."
L["ROLL_ANSWER_NO_OTHER"] = "Tut mir Leid, ich habs schon jemand anderes gegeben."
L["ROLL_ANSWER_NOT_TRADABLE"] = "Tut mir Leid, ich kann das nicht handeln."
L["ROLL_ANSWER_AMBIGUOUS"] = "Ich vergebe gerade mehrere Items, bitte schick mir den Link von dem Item das du haben möchtest."
L["BID"] = "Brauchst du das %s?"
L["ITEM"] = "Item"

-- Addon
local L = LibStub("AceLocale-3.0"):NewLocale(PLR_NAME, lang, lang == Locale.DEFAULT)
if not L then return end

LOOT_ROLL_INELIGIBLE_REASONPLR_NO_ADDON = "Der Besitzer dieses Items benutzt nicht das PersoLootRoll Addon."
LOOT_ROLL_INELIGIBLE_REASONPLR_NO_DISENCHANT = "Das PersoLootRoll Addon unterstützt kein Entzaubern."

L["TRADE"] = "Handeln"
L["ITEM"] = "Item"

L["HELP"] = "Verrolle und biete auf items (/PersoLootRoll oder /plr).\n"
 .. "Benutzung: \n"
 .. "/plr: Optionen öffnen\n"
 .. "/plr roll [Item]* (<Zeit> <Spieler>): Verrolle ein item\n"
 .. "/plr bid <Spieler> ([Item]): Biete auf ein Item eines anderen Spielers\n"
 .. "/plr config: Einstellungen über die Commando-Zeile ändern\n"
 .. "/plr help: Gib diese Hilfsmeldung aus\n"
 .. "Legende: (..) = optional, [..] = Item-Link, * = Ein- oder Mehrmals"
L["USAGE_ROLL"] = "Benutzung: /plr roll [Item]* (<Zeit> <Spieler>)"
L["USAGE_BID"] = "Benutzung: /plr bid <Spieler> ([Item])"

L["ROLL_START"] = "Verolle Item %s."
L["ROLL_END"] = "Beende Roll für %s von %s."
L["ROLL_WINNER_OWN"] = "Du hast %s von dir selbst gewonnen."
L["ROLL_WINNER_SELF"] = "Du hast %s von %s gewonnen -> %s."
L["ROLL_WINNER_OTHER"] = "%s hat %s von dir gewonnen -> %s."
L["ROLL_CANCEL"] = "Breche Roll für %s von %s ab."
L["ROLL_ANSWER_0"] = "Passen"
L["ROLL_ANSWER_1"] = "Bedarf"
L["ROLL_ANSWER_2"] = "Gier"
L["ROLL_ANSWER_3"] = "Entzaubern"

L["BID_START"] = "Biete auf %s von %s."
L["BID_PASS"] = "Passe auf %s von %s."
L["BID_CHAT"] = "Frage %s nach %s -> %s."
L["BID_NO_CHAT"] = "Flüstern ist deaktiviert, du musst %s selbst nach %s fragen -> %s."

L["TRADE_START"] = "Starte Handel mit %s."
L["TRADE_CANCEL"] = "Breche Handel mit %s ab."

L["AWARD_LOOT"] = "Beute vergeben"

L["ERROR_PLAYER_NOT_FOUND"] = "Kann Spieler %s nicht finden."
L["ERROR_ITEM_NOT_TRADABLE"] = "Du kannst dieses Item nicht handeln."
L["ERROR_NOT_IN_GROUP"] = "Du bist nicht in einer Gruppe/Raid."
L["ERROR_ROLL_UNKNOWN"] = "Dieser Roll existiert nicht."
L["ERROR_ROLL_STATUS_NOT_0"] = "Dieser Roll hat schon begonnen oder wurde beendet."
L["ERROR_ROLL_STATUS_NOT_1"] = "Dieser Roll läuft noch nicht."
L["ERROR_ROLL_ANSWER_UNKNOWN_SELF"] = "Das ist keine gültige Antwort."
L["ERROR_ROLL_ANSWER_UNKNOWN_OTHER"] = "%s hat ein ungültiges Gebot für %s gesendet."

L["OPT_GENERAL"] = "Allgemein"
L["OPT_ENABLE"] = "Aktiviert"
L["OPT_ENABLE_DESC"] = "Aktiviere oder deaktiviere das Addon"
L["OPT_ECHO"] = "Chat Informationen"
L["OPT_ECHO_DESC"] = "Wie viel Information möchtest du vom Addon im Chat sehen?\n\n"
    .. "|cffffff00Nichts:|r Keine Infos im Chat.\n"
    .. "|cffffff00Fehler:|r Nur Fehlernachrichten.\n"
    .. "|cffffff00Info:|r Fehler und nützliche Infos.\n"
    .. "|cffffff00Ausführlich:|r Informiert dich über quasi jede Aktion die das Addon tut.\n"
    .. "|cffffff00Debug:|r Genauso wie Ausführlich, und zusätzlich Debug-Informationen."
L["OPT_ECHO_NONE"] = "Nichts"
L["OPT_ECHO_ERROR"] = "Fehler"
L["OPT_ECHO_INFO"] = "Info"
L["OPT_ECHO_VERBOSE"] = "Ausführlich"
L["OPT_ECHO_DEBUG"] = "Debug"
L["OPT_CHAT"] = "Chat"
L["OPT_CHAT_DESC"] = "Hier kannst du ändern wann das Addon Nachrichten im Gruppen/Raid/Flüster Chat posten soll."
L["OPT_ANNOUNCE"] = "Verlosungen und Gewinner ankündigen"
L["OPT_ANNOUNCE_DESC"] = "Verkünde Verlosungen und Gewinner im Gruppen/Raid Chat."
L["OPT_ANSWER"] = "Flüsternachrichten beantworten"
L["OPT_ANSWER_DESC"] = "Lass das Addon auf Flüsternachrichten von Gruppenmitgliedern antworten, die sich auf Items von dir beziehen."
L["OPT_ROLL"] = "Auf Loot im Chat rollen"
L["OPT_ROLL_DESC"] = "Rolle auf Loot (/roll), wenn andere Links im Gruppen/Raid Chat posten."
L["OPT_WHISPER_GROUP"] = "Flüstern nach Gruppe"
L["OPT_WHISPER_GROUP_DESC"] = "Flüstere andere an, abhängig von der Art von Gruppe in der du gerade bist."
L["OPT_WHIPSER_TARGET"] = "Flüstern nach Ziel"
L["OPT_WHISPER_TARGET_DESC"] = "Flüstere andere an, abhängig davon ob sie auf deiner Freundesliste oder in deiner Gilde sind."