local Name, Addon = ...
local Locale = Addon.Locale
local lang = "ptBR"

-- Chat messages
local L = { lang = lang }
setmetatable(L, Locale.MT)
Locale[lang] = L

--@localization(locale="ptBR", format="lua_additive_table", handle-unlocalized="english", namespace="Messages")@

-- Addon
local L = LibStub("AceLocale-3.0"):NewLocale(Name, lang, lang == Locale.FALLBACK)
if not L then return end

--@localization(locale="ptBR", format="lua_additive_table", handle-unlocalized="english")@
--@localization(locale="ptBR", format="lua_additive_table", handle-unlocalized="english", namespace="Commands")@
--@localization(locale="ptBR", format="lua_additive_table", handle-unlocalized="english", namespace="Errors")@
--@localization(locale="ptBR", format="lua_additive_table", handle-unlocalized="english", namespace="GUI")@
--@localization(locale="ptBR", format="lua_additive_table", handle-unlocalized="english", namespace="Options-Home")@
--@localization(locale="ptBR", format="lua_additive_table", handle-unlocalized="english", namespace="Options-Masterloot")@
--@localization(locale="ptBR", format="lua_additive_table", handle-unlocalized="english", namespace="Options-Messages")@
--@localization(locale="ptBR", format="lua_additive_table", handle-unlocalized="english", namespace="Plugins-EPGP")@
--@localization(locale="ptBR", format="lua_additive_table", handle-unlocalized="english", namespace="Roll")@
--@localization(locale="ptBR", format="lua_additive_table", handle-unlocalized="english", namespace="Globals", table-name="_G")@

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
