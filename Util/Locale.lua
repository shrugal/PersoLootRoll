local Name, Addon = ...
local Unit, Util = Addon.Unit, Addon.Util
local Self = Addon.Locale

Self.DEFAULT = "enUS"

-- Get the current region
function Self.GetRegion()
    return ({"US", "KO", "EU", "TW", "CN"})[GetCurrentRegion()]
end

-- Get language for realm
function Self.GetLanguage(realm)
    local region = Self.GetRegion()

    if Self.REALMS[region] then
        realm = realm or GetRealmName()
        return Self.REALMS[region][realm] or Self.DEFAULT
    else
        return region:lower() .. region
    end
end

-- Get locale
function Self.GetLocale(lang)
    return Self[lang or Self.GetLanguage()] or Self[Self.DEFAULT]
end

-- Get a single line
function Self.GetLine(line, lang, ...)
    local L = Self.GetLocale(lang)
    return ... and L(line, ...) or L[line]
end

-------------------------------------------------------
--                        Comm                       --
-------------------------------------------------------

-- Get language for communication with another player or group/raid
function Self.GetCommLanguage(player)
    local lang = Self.GetLanguage()

    -- Check single player
    if player then
        if lang ~= Self.GetLanguage(Unit.RealmName(player)) then
            return Self.DEFAULT
        end
    -- Check group/raid
    elseif IsInGroup() then
        for i=1, GetNumGroupMembers() do
            player = GetRaidRosterInfo(i)
            if lang ~= Self.GetLanguage(Unit.RealmName(player)) then
                return Self.DEFAULT
            end
        end
    end
    
    return lang
end

-- Get locale for communication with another player or group/raid
function Self.GetCommLocale(player)
    return Self.GetLocale(Self.GetCommLanguage(player))
end

-- Get a single line for communication with another player or group/raid
function Self.GetCommLine(line, player, ...)
    return Self.GetLine(line, Self.GetCommLanguage(player), ...)
end

-------------------------------------------------------
--                       Helper                      --
-------------------------------------------------------

function Self.Gender(unit, w, m, ucfirst)
    local L, g = Self.GetCommLocale(unit), UnitSex(unit)
    w, m = ucfirst and Util.StrUcFirst(L[w]) or L[w], ucfirst and Util.StrUcFirst(L[m]) or L[m]
    return g == 2 and m or g == 3 and w or w .. "/" .. m
end

-------------------------------------------------------
--                    Lang tables                    --
-------------------------------------------------------

-- Meta table for chat message translations
Self.MT = {
    __index = function (table, key)
        return table == Self[Self.DEFAULT] and key or Self[Self.DEFAULT][key]
    end,
    __call = function (table, line, ...)
        return string.format(table[line], ...)
    end
}