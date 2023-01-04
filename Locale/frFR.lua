local Name, Addon = ...
local Locale = Addon.Locale
local lang = "frFR"

-- Chat messages
local L = { lang = lang }
setmetatable(L, Locale.MT)
Locale[lang] = L

--@localization(locale="frFR", format="lua_additive_table", handle-unlocalized="english", namespace="Messages")@

-- Addon
local L = LibStub("AceLocale-3.0"):NewLocale(Name, lang, lang == Locale.FALLBACK)
if not L then return end

--@localization(locale="frFR", format="lua_additive_table", handle-unlocalized="english")@
--@localization(locale="frFR", format="lua_additive_table", handle-unlocalized="english", namespace="Commands")@
--@localization(locale="frFR", format="lua_additive_table", handle-unlocalized="english", namespace="Errors")@
--@localization(locale="frFR", format="lua_additive_table", handle-unlocalized="english", namespace="GUI")@
--@localization(locale="frFR", format="lua_additive_table", handle-unlocalized="english", namespace="Options-Home")@
--@localization(locale="frFR", format="lua_additive_table", handle-unlocalized="english", namespace="Options-Masterloot")@
--@localization(locale="frFR", format="lua_additive_table", handle-unlocalized="english", namespace="Options-Messages")@
--@localization(locale="frFR", format="lua_additive_table", handle-unlocalized="english", namespace="Plugins-EPGP")@
--@localization(locale="frFR", format="lua_additive_table", handle-unlocalized="english", namespace="Roll")@
--@localization(locale="frFR", format="lua_additive_table", handle-unlocalized="english", namespace="Globals", table-name="_G")@

-- Other
L["ID"] = ID
L["ITEMS"] = ITEMS
L["LEVEL"] = LEVEL
L["STATUS"] = STATUS
L["TARGET"] = TARGET
L["ROLL_BID_0"] = PASS
L["ROLL_BID_1"] = NEED
L["ROLL_BID_2"] = GREED
L["ROLL_BID_3"] = ROLL_DISENCHANT
L[""] = ""
