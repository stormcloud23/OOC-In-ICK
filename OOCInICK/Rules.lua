-- OOC-In-ICK: deliberately conservative, explainable heuristics.
-- False positives are inevitable. No result is proof of a policy violation.
local addonName, ns = ...
ns = ns or {}

local examples = {
    ["slipnslide"] = "Blizzard's example of a non-fantasy name",
    ["robotman"] = "Blizzard's example of a non-fantasy name",
    ["discoinferno"] = "Blizzard's example of a non-fantasy name",
    ["britneyspears"] = "Blizzard's example of a real-world celebrity",
    ["austinpowers"] = "Blizzard's example of a fictional celebrity",
    ["mcdonalds"] = "Blizzard's example of a real-world brand",
    ["georgewashington"] = "Blizzard's example of a historical figure",
    ["newyork"] = "Blizzard's example of a real-world place",
    ["inyourface"] = "Blizzard's example of a multiword phrase",
    ["welovebeef"] = "Blizzard's example of a multiword phrase",
    ["howareyou"] = "Blizzard's example of a multiword phrase",
    ["sixtyseventy"] = "Blizzard's example of a multiword phrase",
}

-- A small high-precision starter list, not a blacklist of all pop culture.
-- Only entire name components or entire combined names are matched.
local references = {
    pokemon = "Modern media/franchise reference",
    minecraft = "Modern media/franchise reference",
    youtube = "Modern website/brand reference",
    netflix = "Modern website/brand reference",
    walmart = "Modern brand reference",
    starbucks = "Modern brand reference",
    spiderman = "Famous fictional-character reference",
    batman = "Famous fictional-character reference",
    darthvader = "Famous fictional-character reference",
    harrypotter = "Famous fictional-character reference",
}

local phrases = {
    {"^ilove", "Name appears to start with the modern phrase 'I love'"},
    {"^mynameis", "Name appears to be a sentence ('my name is')"},
    {"^yourmom", "Name appears to be a modern joke phrase"},
    {"^subscribe", "Name appears to use a modern promotional phrase"},
    {"^followme", "Name appears to use a modern promotional phrase"},
    {"^sendhelp", "Name appears to use a sentence rather than a name"},
}

-- Normalize display variants without collapsing genuinely different names:
-- "Grumdin-Redbeard" == "Grumdin Redbeard", but NOT "Grumdinred Beard".
local function clean(name)
    if type(name) ~= "string" or #name > 100 or name:find("|", 1, true) then return nil end
    local canonical = name:lower():gsub("^%s+", ""):gsub("%s+$", "")
        :gsub("[%s%-%_]+", " "):gsub("^%s+", ""):gsub("%s+$", "")
    if canonical == "" then return nil end
    local joined = canonical:gsub("[%s']+", "")
    return canonical, joined
end

function ns.NormalizeName(name)
    local canonical = clean(name)
    return canonical
end

function ns.HasFullName(name)
    local canonical = clean(name)
    return canonical ~= nil and canonical:find(" ", 1, true) ~= nil
end


function ns.EvaluateName(name, custom)
    local raw, joined = clean(name)
    if not raw or joined == "" then return nil end

    -- Explicit user-supplied full-name matches, never hidden substring matches.
    if type(custom) == "table" and (custom[raw] or custom[joined]) then
        return "Custom watchlist match", "custom"
    end

    if examples[joined] then return examples[joined], "high" end

    for part in raw:gmatch("[^%s%-_']+") do
        if examples[part] then return examples[part], "high" end
        if references[part] then return references[part], "medium" end
    end
    if references[joined] then return references[joined], "medium" end

    for _, rule in ipairs(phrases) do
        if joined:match(rule[1]) then return rule[2], "medium" end
    end

    -- Long runs of the same character are a low-confidence review cue.
    if joined:match("([a-z])%1%1%1") then
        return "Four or more consecutive identical letters", "low"
    end

    return nil
end

