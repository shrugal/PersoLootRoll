local Name, Addon = ...
local Locale = Addon.Locale
local lang = "deDE"

-- Chat messages
local L = {lang = lang}
setmetatable(L, Locale.MT)
Locale[lang] = L

--@localization(locale="deDE", format="lua_additive_table", handle-unlocalized="english", namespace="Messages")@
--@do-not-package@
L["MSG_BID_1"] = "Brauchst du das %s?"
L["MSG_BID_2"] = "Könnte ich %s haben, wenn du es nicht brauchst?"
L["MSG_BID_3"] = "Ich könnte %s gebrauchen, wenn du es nicht willst."
L["MSG_BID_4"] = "%s würde ich nehmen, wenn du es loswerden willst."
L["MSG_BID_5"] = "Brauchst du %s, oder könnte ich das haben?"
L["MSG_HER"] = "sie"
L["MSG_HIM"] = "ihn"
L["MSG_ITEM"] = "Item"
L["MSG_NEED"] = "bedarf,ja,yep,jap,jau,jo,joa,jawohl,nehm ich,würde? ich nehmen"
L["MSG_PASS"] = "passe,nein,nö,nope"
L["MSG_ROLL"] = "roll,vergeben"
L["MSG_ROLL_ANSWER_AMBIGUOUS"] = "Ich vergebe gerade mehrere Items, bitte schick mir den Link von dem Item das du haben möchtest."
L["MSG_ROLL_ANSWER_BID"] = "Ok, ich hab dein Gebot für %s registriert."
L["MSG_ROLL_ANSWER_NO_OTHER"] = "Tut mir Leid, ich habs schon jemand anderes gegeben."
L["MSG_ROLL_ANSWER_NO_SELF"] = "Tut mir Leid, Ich brauche es selber."
L["MSG_ROLL_ANSWER_NOT_TRADABLE"] = "Tut mir Leid, ich kann das nicht handeln."
L["MSG_ROLL_ANSWER_STARTED"] = "Ok, ich werde es verlosen."
L["MSG_ROLL_ANSWER_YES"] = "Du kannst es haben, handel mich einfach an."
L["MSG_ROLL_ANSWER_YES_MASTERLOOT"] = "Du kannst es haben, handel %s einfach an."
L["MSG_ROLL_DISENCHANT"] = "<%s> wird %s entzaubern -> Mich anhandeln!"
L["MSG_ROLL_DISENCHANT_MASTERLOOT"] = "<%s> wird %s von <%s> entzaubern -> %s anhandeln!"
L["MSG_ROLL_DISENCHANT_WHISPER"] = "Du wurdest ausgewählt %s zu entzaubern, bitte handel mich an."
L["MSG_ROLL_DISENCHANT_WHISPER_MASTERLOOT"] = "Du wurdest ausgewählt %s von <%s> zu entzaubern, bitte handel %s an."
L["MSG_ROLL_START"] = "Vergebe %s -> /w me oder /roll %d!"
L["MSG_ROLL_START_CONCISE"] = "%s jemand Bedarf?"
L["MSG_ROLL_START_MASTERLOOT"] = "Vergebe %s von <%s> -> /w me oder /roll %d!"
L["MSG_ROLL_WINNER"] = "<%s> hat %s gewonnen -> Mich anhandeln!"
L["MSG_ROLL_WINNER_CONCISE"] = "<%s> bitte mich anhandeln!"
L["MSG_ROLL_WINNER_MASTERLOOT"] = "<%s> hat %s von <%s> gewonnen -> %s anhandeln!"
L["MSG_ROLL_WINNER_WHISPER"] = "Du hast %s gewonnen! Bitte handel mich an."
L["MSG_ROLL_WINNER_WHISPER_CONCISE"] = "Handel mich bitte an."
L["MSG_ROLL_WINNER_WHISPER_MASTERLOOT"] = "Du hast %s von <%s> gewonnen! Bitte handel %s an."
--@end-do-not-package@

-- Addon
local L = LibStub("AceLocale-3.0"):NewLocale(Name, lang, lang == Locale.FALLBACK)
if not L then return end

--@localization(locale="deDE", format="lua_additive_table", handle-unlocalized="english")@
--@localization(locale="deDE", format="lua_additive_table", handle-unlocalized="english", namespace="Commands")@
--@localization(locale="deDE", format="lua_additive_table", handle-unlocalized="english", namespace="Errors")@
--@localization(locale="deDE", format="lua_additive_table", handle-unlocalized="english", namespace="GUI")@
--@localization(locale="deDE", format="lua_additive_table", handle-unlocalized="english", namespace="Options-Home")@
--@localization(locale="deDE", format="lua_additive_table", handle-unlocalized="english", namespace="Options-Masterloot")@
--@localization(locale="deDE", format="lua_additive_table", handle-unlocalized="english", namespace="Options-Messages")@
--@localization(locale="deDE", format="lua_additive_table", handle-unlocalized="english", namespace="Plugins-EPGP")@
--@localization(locale="deDE", format="lua_additive_table", handle-unlocalized="english", namespace="Roll")@
--@localization(locale="deDE", format="lua_additive_table", handle-unlocalized="english", namespace="Globals", table-name="_G")@

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
L[""] = ""
