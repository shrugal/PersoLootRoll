---@type Addon
local Addon = select(2, ...)
local RI = LibStub("LibRealmInfo")
local Util = Addon.Util
---@class Locale
local Self = Addon.Locale

-- The region's default language
---@type string
Self.DEFAULT = Util.Select(RI:GetCurrentRegion(), "KR", "koKR", "TW", "zhTW", "CN", "zhCN", "enUS")

-- Fallback language for missing lines
Self.FALLBACK = "enUS"

-- Get language for the given realm
---@param realm string?
---@return string
function Self.GetRealmLanguage(realm)
    local lang = select(5, RI:GetRealmInfo(realm or GetRealmName())) or Self.DEFAULT
    return lang == "enGB" and "enUS" or lang
end

-- Get language for the given unit
---@param unit string
---@return string
function Self.GetUnitLanguage(unit)
    local lang = select(5, RI:GetRealmInfoByUnit(unit or "player")) or Self.DEFAULT
    return lang == "enGB" and "enUS" or lang
end

-- Get a language's name (e.g. "enUS" -> "English")
---@param lang string
---@return string
function Self.GetLanguageName(lang)
    return lang:sub(1, 2) == "en" and LFG_LIST_LANGUAGE_ENUS or _G[lang:upper()] or lang
end

-- Get locale
---@param lang string
---@return table
function Self.GetLocale(lang)
    return Self[lang == true and GetLocale() or lang or Self.GetRealmLanguage()] or Self[Self.FALLBACK]
end

-- Get a single line
---@param lang string
---@return string
function Self.GetLine(line, lang, ...)
    local L = Self.GetLocale(lang)
    return ... and L(line, ...) or L[line]
end

-------------------------------------------------------
--                        Comm                       --
-------------------------------------------------------

-- Get language for communication with another player or group/raid
---@return string
function Self.GetCommLanguage(unit)
    local lang = Self.GetRealmLanguage()

    -- Check single unit
    if unit then
        if lang ~= Self.GetUnitLanguage(unit) then
            return Self.DEFAULT
        end
    -- Check group/raid
    elseif IsInGroup() then
        for i=1, GetNumGroupMembers() do
            unit = GetRaidRosterInfo(i)
            if lang ~= Self.GetUnitLanguage(unit) then
                return Self.DEFAULT
            end
        end
    end

    return lang
end

-- Get locale for communication with another player or group/raid
---@param unit string
function Self.GetCommLocale(unit)
    return Self.GetLocale(Self.GetCommLanguage(unit))
end

-- Get a single line for communication with another player or group/raid
---@param unit string
---@return string
function Self.GetCommLine(line, unit, ...)
    return Self.GetLine(line, Self.GetCommLanguage(unit), ...)
end

-------------------------------------------------------
--                       Helper                      --
-------------------------------------------------------

---@param ucfirst boolean
function Self.Gender(unit, w, m, ucfirst)
    local L, g = Self.GetCommLocale(unit), UnitSex(unit)
    w, m = ucfirst and Util.Str.UcFirst(L[w]) or L[w], ucfirst and Util.Str.UcFirst(L[m]) or L[m]
    return g == 2 and m or g == 3 and w or w .. "/" .. m
end

-------------------------------------------------------
--                    Lang tables                    --
-------------------------------------------------------

-- Meta table for chat message translations
Self.MT = {
    __index = function (table, key)
        return table == Self[Self.FALLBACK] and key or Self[Self.FALLBACK][key]
    end,
    __call = function (table, line, ...)
        return table[line]:format(...)
    end
}