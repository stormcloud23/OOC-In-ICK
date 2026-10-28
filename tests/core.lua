-- Headless event and SavedVariables regression tests: lua5.1 tests/core.lua
local ns, handler = {}, nil
local clock = 1000
local names = {player = "Grumdin Redbeard"}
local guids = {player = "Player-1-SELF"}

CreateFrame = function()
    local frame = {}
    function frame:RegisterEvent() end
    function frame:UnregisterEvent() end
    function frame:SetScript(script, fn)
        if script == "OnEvent" then handler = fn end
    end
    return frame
end
GetUnitName = function(unit) return names[unit] end
UnitName = function(unit) return names[unit] end
UnitExists = function(unit) return names[unit] ~= nil end
UnitIsPlayer = function(unit) return names[unit] ~= nil end
UnitIsUnit = function(unit, other) return unit == other end
UnitGUID = function(unit) return guids[unit] end
GetZoneText = function() return "Elwynn Forest" end
GetServerTime = function() return clock end
GetTime = function() return clock end
SlashCmdList = {}
DEFAULT_CHAT_FRAME = {AddMessage = function() end}

assert(loadfile("OOCInICK/Rules.lua"))("OOCInICK", ns)
assert(loadfile("OOCInICK/Core.lua"))("OOCInICK", ns)

-- Simulate the old separator-free key; addon startup should migrate it.
OOCInICKDB = {
    entries = {slipnslidetown = {name = "Slipnslide Town", sightings = 2, lastSeen = 50}},
}
handler(nil, "ADDON_LOADED", "OOCInICK")
handler(nil, "PLAYER_LOGIN")
local db = ns.DB()
local function key(name) return ns.NormalizeName(name) end
local function entry(name) return db.entries[key(name)] end

assert(entry("Slipnslide Town"), "Saved candidate was not migrated")
assert(db.entries.slipnslidetown == nil, "Legacy key was not replaced")

ns.ObserveName("Slipnslide", nil, "Chat") -- first name alone is not unique
assert(entry("Slipnslide") == nil, "Partial names must not be logged")

ns.ObserveName("Grumdin Redbeard", nil, "Chat")
assert(entry("Grumdin Redbeard") == nil, "Self should not be queued")

ns.ObserveName("Nimzi Blackwick", nil, "Chat")
assert(entry("Nimzi Blackwick") == nil, "Ordinary fantasy names should not match")
SlashCmdList.OOCINICK("watch Nimzi Blackwick")
ns.ObserveName("Nimzi-Blackwick", nil, "Nameplate")
assert(entry("Nimzi Blackwick").confidence == "custom", "Watch must invalidate cached non-matches")
SlashCmdList.OOCINICK("unwatch Nimzi Blackwick")
assert(entry("Nimzi Blackwick") == nil, "Removing custom watch should drop custom-only entry")

-- Different full names must not collapse to the same identity key.
assert(key("Robot Man") ~= key("Robotman"), "Separators must preserve character identity")
assert(key("Robot-Man") == key("Robot Man"), "Hyphenated Forever surname rendering should normalize")
assert(key("John Doe") ~= key("Jo Hndoe"), "Different first/surname splits must be distinct")

names.nameplate1 = "YouTube-Blackwick"
guids.nameplate1 = "Player-1-ONE"
handler(nil, "NAME_PLATE_UNIT_ADDED", "nameplate1")
assert(entry("YouTube Blackwick"), "Nameplate event missed a candidate")
assert(entry("YouTube Blackwick").guid == "Player-1-ONE", "Missing GUID")

local candidate = entry("YouTube Blackwick")
ns.ObserveName("YouTube Blackwick", "Player-1-NEW", "Chat")
assert(candidate.guid == "Player-1-NEW", "A better GUID must update even during throttle")
assert(candidate.sightings == 1, "Repeated events should not inflate sightings")
clock = clock + 61
ns.ObserveName("YouTube Blackwick", nil, "Chat")
assert(candidate.sightings == 2, "Distinct sightings should advance after 60s")

names.focus = "Netflix Ironstout"
handler(nil, "PLAYER_FOCUS_CHANGED")
assert(entry("Netflix Ironstout"), "Focus change event missed a candidate")

-- Chat events carry the sender GUID as the 12th payload argument.
handler(nil, "CHAT_MSG_SAY", "Hello", "Walmart Stone", nil, nil, nil, nil, nil, nil, nil, nil, 900, "Player-1-CHAT")
assert(entry("Walmart Stone") and entry("Walmart Stone").guid == "Player-1-CHAT", "Chat GUID extraction failed")

ns.ObserveName("Minecraft Forge", nil, "Chat")
SlashCmdList.OOCINICK("ignore Minecraft Forge")
ns.ObserveName("Minecraft-Forge", nil, "Chat")
assert(entry("Minecraft Forge") == nil, "Ignored candidate returned")

SlashCmdList.OOCINICK("add Nimzi Blackwick")
assert(entry("Nimzi Blackwick") and entry("Nimzi Blackwick").confidence == "manual", "Manual additions must work")
SlashCmdList.OOCINICK("add Robotman") -- invalid: no surname
assert(entry("Robotman") == nil, "Manual additions must require a full name")

-- Common names are classified just once per cache window; known candidates are
-- not rescanned on every incoming observation.
local evaluate = ns.EvaluateName
local evaluations = 0
ns.EvaluateName = function(...)
    evaluations = evaluations + 1
    return evaluate(...)
end
ns.ObserveName("Quietleaf Sunbranch", nil, "Chat")
ns.ObserveName("Quietleaf Sunbranch", nil, "Chat")
assert(evaluations == 1, "Negative classification cache missed")
ns.ObserveName("Youtube Farstrider", nil, "Nameplate")
ns.ObserveName("Youtube Farstrider", nil, "Chat")
assert(evaluations == 2, "Existing candidate should not be reclassified")

-- Names from available full-name events use the expanded dictionary.
ns.ObserveName("xXSephirothXx Stout", "Player-1-X", "Chat")
assert(entry("xXSephirothXx Stout"), "Decorative X name not queued")
ns.ObserveName("Deez Nuts", "Player-1-J", "Chat")
assert(entry("Deez Nuts"), "Joined joke phrase not queued")
ns.ObserveName("Xavier Stone", "Player-1-C", "Chat")
assert(entry("Xavier Stone") == nil, "A normal X-initial name was flagged")
ns.ObserveName("xXSephirothXx", "Player-1-P", "Chat")
assert(entry("xXSephirothXx") == nil, "First-name-only data must not create ambiguous reports")
ns.ObserveName("Chatgpt Ironforge", "Player-1-AI", "Chat")
assert(entry("Chatgpt Ironforge"), "Technology terms should enter review queue")
ns.ObserveName("Airfryer Redbeard", "Player-1-APPLIANCE", "Chat")
assert(entry("Airfryer Redbeard"), "Modern product terms should enter review queue")
ns.ObserveName("GrumdinTTV Stone", "Player-1-TTV", "Chat")
assert(entry("GrumdinTTV Stone"), "TTV suffix should enter review queue")
ns.ObserveName("Engineer Blackwick", "Player-1-OK", "Chat")
assert(entry("Engineer Blackwick") == nil, "Legitimate fantasy engineering term should remain clear")
ns.ObserveName("Asmongold Ironforge", "Player-1-STREAM", "Chat")
assert(entry("Asmongold Ironforge"), "Streamer handle should be queued")
ns.ObserveName("Esfand Ironforge", "Player-1-ALIAS", "Chat")
assert(entry("Esfand Ironforge").confidence == "low", "Ambiguous alias should be low confidence")
ns.ObserveName("Tax Accountant", "Player-1-JOB", "Chat")
assert(entry("Tax Accountant"), "Modern profession should be queued")
ns.ObserveName("CIA Agent", "Player-1-CIA", "Chat")
assert(entry("CIA Agent"), "Modern organization acronym should be queued")
ns.ObserveName("Asmonius Redbeard", "Player-1-OK", "Chat")
assert(entry("Asmonius Redbeard") == nil, "Substring aliases must not trigger")
ns.ObserveName("Asmongolden Stout", "Player-1-EMBEDDED", "Chat")
assert(entry("Asmongolden Stout"), "Embedded streamer handle should enter queue")
ns.ObserveName("OlympusFan Stone", "Player-1-COMMUNITY", "Chat")
assert(entry("OlympusFan Stone").confidence == "medium", "Guild-specific Olympus name should be medium")
ns.ObserveName("Olympus Redbeard", "Player-1-GREEK", "Chat")
assert(entry("Olympus Redbeard").confidence == "low", "Ambiguous Olympus name should be low")
ns.ObserveName("OnlyFangsmember Stone", "Player-1-FANGS", "Chat")
assert(entry("OnlyFangsmember Stone"), "Embedded streamer guild should enter queue")
ns.ObserveName("Olympian Blackwick", "Player-1-OK", "Chat")
assert(entry("Olympian Blackwick") == nil, "Olympian is not an Olympus-guild handle")
print("OOC-In-ICK event-processing tests passed.")
