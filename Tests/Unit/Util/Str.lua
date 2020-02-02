if not WoWUnit then return end

---@type string
local Name = ...
---@type Addon
local Addon = select(2, ...)
local Test, Util = Addon.Test, Addon.Util
local Assert, AssertEqual, Replace = WoWUnit.IsTrue, WoWUnit.AreEqual, WoWUnit.Replace

local Tests = WoWUnit(Name .. ".Unit.Util.Str")

function Tests:IsSetTest()
end

function Tests:IsEmptyTest()
end

function Tests:StartsWithTest()
end

function Tests:EndsWithTest()
end

function Tests:WrapTest()
end

function Tests:PrefixTest()
end

function Tests:PostfixTest()
end

function Tests:SplitTest()
end

function Tests:JoinTest()
end

function Tests:UcLangTest()
    Replace("GetLocale", Test.Const("enUS"))
    AssertEqual("TEST", Util.Str.UcLang("test"))

    for _,locale in pairs({"koKR", "zhCN", "zhTW"}) do
        Replace("GetLocale", Test.Const("enUS"))
        AssertEqual("test", Util.Str.UcLang("test", locale))

        Replace("GetLocale", Test.Const(locale))
        AssertEqual("test", Util.Str.UcLang("test"))
        AssertEqual("TEST", Util.Str.UcLang("test", "enUS"))
    end
end

function Tests:LcLangTest()
    Replace("GetLocale", Test.Const("enUS"))
    AssertEqual("test", Util.Str.LcLang("TEST"))

    for _,locale in pairs({"koKR", "zhCN", "zhTW"}) do
        Replace("GetLocale", Test.Const("enUS"))
        AssertEqual("TEST", Util.Str.LcLang("TEST", locale))

        Replace("GetLocale", Test.Const(locale))
        AssertEqual("TEST", Util.Str.LcLang("TEST"))
        AssertEqual("test", Util.Str.LcLang("TEST", "enUS"))
    end
end

function Tests:UcFirstTest()
end

function Tests:LcFirstTest()
end

function Tests:IsNumberTest()
end

function Tests:AbbrTest()
end

function Tests:ColorTest()
end

function Tests:ReplaceTest()
end

function Tests:ToCamelCaseTest()
end

function Tests:FromCamelCaseTest()
end

function Tests:ToStringTest()
end