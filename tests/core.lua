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

print("OOC-In-ICK event-processing tests passed.")
