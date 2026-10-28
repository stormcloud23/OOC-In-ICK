-- Run with: lua5.1 tests/rules.lua  (from repository root)
local ns = {}
local chunk = assert(loadfile("OOCInICK/Rules.lua"))
chunk("OOCInICK", ns)

local function flagged(name, expected)
    local reason, level = ns.EvaluateName(name)
    assert(reason, "Expected candidate: " .. name)
    if expected then assert(level == expected, name .. ": expected " .. expected .. ", got " .. tostring(level)) end
end

local function clear(name)
    assert(ns.EvaluateName(name) == nil, "False positive: " .. name)
end

flagged("Slipnslide", "high")
flagged("Britney Spears", "high")
flagged("New York", "high")
flagged("Grumdin Mcdonalds", "high")
flagged("Nimzi Youtube", "medium")
flagged("Ilovefishing Redbeard", "medium")
flagged("Booooork Stout", "low")
clear("Grumdin Redbeard")
clear("Nimzi Blackwick")
clear("Markus Eisenhart")
clear("Theodore Ironforge")
clear("Lorith Silvermoon")
clear("Gandalfar Brightvale") -- substring of a name is not a media reference
assert(ns.NormalizeName("Grumdin-Redbeard") == ns.NormalizeName("Grumdin Redbeard"))
assert(ns.NormalizeName("Grumdin Redbeard") ~= ns.NormalizeName("Grumdinred Beard"))
assert(ns.NormalizeName("Robot Man") ~= ns.NormalizeName("Robotman"))
assert(ns.HasFullName("Grumdin Redbeard"))
assert(ns.HasFullName("Grumdin-Redbeard"))
assert(not ns.HasFullName("Grumdin"))
assert(ns.NormalizeName("|cff00ff00Fake Name|r") == nil)
assert(ns.EvaluateName("|cff00ff00Fake Name|r") == nil)
assert(ns.EvaluateName("Grumdin Redbeard", {grumdinredbeard = true}) == "Custom watchlist match")
assert(ns.EvaluateName("Grumdin-Redbeard", {["grumdin redbeard"] = true}) == "Custom watchlist match")
-- Modern media, joke names, chat slang, and joined first/surname phrases.
for _, name in ipairs({
    "Sephiroth Ironforge", "Naruto Stone", "TikTok Blackwick",
    "Deez Nuts", "Your Mom", "Skillissue Stout", "Skibidi McIron",
    "Sendhelp Redbeard", "Wheresmyloot Grumdin", "Ihatethisgame Stone",
    "Givemegold Stout", "Onevone Plz", "XxSephirothXx", "xXSephirothXx Blackwick",
    "xxGrumdin Stone", "Grumdinxx Stone", "xSephiroth Stone",
    "Sephirothx Stone", "xSephirothx Stone",
}) do
    flagged(name, "medium")
end

-- A single X, or an embedded modern term, is not by itself suspicious.
for _, name in ipairs({
    "Xavier Blackwick", "Xanthus Redbeard", "Xander Ironforge",
    "Felix Stone", "Xerox Blackwick", "Nyx Stone", "Xylix Silver",
    "Sephirothian Redbeard", "Batmanning Stout", "Ggandor Stone",
    "Ligmah Redbeard", "Grumdin Stone", "Gandalfar Brightvale",
}) do clear(name) end

-- A user-specified watchlist should still have priority over general rules.
assert(ns.EvaluateName("Sephiroth Ironforge", {["sephiroth ironforge"] = true})
    == "Custom watchlist match")
print("OOC-In-ICK heuristic tests passed.")
