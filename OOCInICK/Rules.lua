-- OOC-In-ICK: small, explainable heuristics; suggestions are NOT policy verdicts.
local addonName, ns = ...

-- Examples from Blizzard's RP naming policy.
local examples = {
    slipnslide = true, robotman = true, discoinferno = true,
    britneyspears = true, austinpowers = true, mcdonalds = true,
    georgewashington = true, newyork = true, inyourface = true,
    welovebeef = true, howareyou = true, sixtyseventy = true,
}

-- Exact components or whole-name matches only: "Batman" matches;
-- "Batmanning" does not. Avoid common words like "cloud" or "link".
local references = {
    -- Video games, films, television, and anime
    pokemon = true, pikachu = true, charizard = true, sephiroth = true,
    minecraft = true, fortnite = true, roblox = true, overwatch = true,
    valorant = true, callofduty = true, leagueoflegends = true,
    masterchief = true, doomguy = true, kratos = true, solidsnake = true,
    darthvader = true, harrypotter = true, voldemort = true,
    spiderman = true, batman = true, thanos = true,
    spongebob = true, patrickstar = true, optimusprime = true,
    sonic = true, naruto = true, sasuke = true, kakashi = true,
    itachi = true, goku = true, vegeta = true, gojo = true,
    saitama = true, kirito = true, totoro = true,
    -- Modern brands, sites, and technology
    youtube = true, netflix = true, walmart = true, starbucks = true,
    tiktok = true, instagram = true, snapchat = true, spotify = true,
    reddit = true, discord = true, twitch = true, facebook = true,
    google = true, microsoft = true, nvidia = true, playstation = true,
    xbox = true, nintendo = true, costco = true,
}

-- Modern chat slang and memes. Matching a complete component prevents
-- "gg" in "Dagger" or "rekt" in a longer fantasy name from being flagged.
local slang = {
    lol = true, lmao = true, rofl = true, roflmao = true,
    afk = true, brb = true, ggwp = true, ezpz = true,
    gitgud = true, getrekt = true, getgood = true, skillissue = true,
    noob = true, n00b = true, pwned = true, pwnd = true,
    rekt = true, teabag = true, tbag = true, yolo = true,
    uwu = true, owo = true, skibidi = true, gyatt = true,
    deeznuts = true, ligma = true, sugma = true, updog = true,
    touchgrass = true, rickroll = true, copypasta = true,
    trollface = true, pepega = true, bigchungus = true,
    amogus = true, susbro = true, youmadbro = true,
    itsame = true, notaname = true, justaprank = true,
}

-- Word combinations and short sentence names.
local jokePhrases = {
    yourmom = true, yourdad = true, urmom = true, urdad = true,
    whocares = true, noonecares = true, nobodycares = true,
    dontcare = true, pleasestop = true, pleasehelp = true,
    sendnudes = true, eatmyshorts = true, getoutofhere = true,
    imthebest = true, imnotreal = true, lookatme = true,
    checkoutmy = true, givemeloot = true, gibloot = true,
    whereismyloot = true, wheresmyloot = true, followme = true,
    subscribe = true, sendhelp = true, followmy = true,
    mynameis = true, ineedhealing = true, noscope = true,
    onevone = true, oneversusone = true,
}

-- Specific prefixes only. Broad prefixes like "^my" or "^no"
-- would produce too many false positives on genuine RP names.
local phrasePrefixes = {
    "^ilove", "^ihate", "^mynameis", "^yourmom", "^yourdad",
    "^urmom", "^urdad", "^followme", "^subscribeto", "^sendhelp",
    "^touchgrass", "^giveme", "^pleasegive", "^wheresmy",
    "^whereismy", "^imthebest", "^imnot", "^youmadbro",
    "^pleasefollow", "^ineedhealing",
}

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

-- "xXSephirothXx" -> "xxsephirothxx". Decorative Xs at either
-- edge are suspicious; an isolated X is not (Xavier, Xanthus, Felix).
local function decorativeX(part)
    if not part:match("^[a-z%d]+$") or #part < 5 then return false end

    -- XxName, NameXx, xXNameXx, etc. Require at least two body chars.
    if part:match("^xx[a-z%d][a-z%d]+") or part:match("[a-z%d][a-z%d]+xx$") then
        return true
    end

    -- Single X wrapping a known reference: xSephiroth, Sephirothx,
    -- xSephirothx. Never generically flag all names starting in X.
    local stripped = part:match("^x([a-z%d]+)x$")
        or part:match("^x([a-z%d]+)$")
        or part:match("^([a-z%d]+)x$")
    return stripped and (references[stripped] or slang[stripped] or jokePhrases[stripped]) or false
end

local function exactMatch(part)
    if examples[part] then return "Blizzard RP naming-policy example", "high" end
    if references[part] then return "Modern/pop-culture reference", "medium" end
    if slang[part] then return "Internet slang or meme", "medium" end
    if jokePhrases[part] then return "Modern joke or sentence-like phrase", "medium" end
end

function ns.EvaluateName(name, custom)
    local raw, joined = clean(name)
    if not raw then return nil end

    if type(custom) == "table" and (custom[raw] or custom[joined]) then
        return "Custom watchlist match", "custom"
    end

    -- Check each component and the combined spelling ("Deez Nuts").
    local reason, confidence = exactMatch(joined)
    if reason then return reason, confidence end

    for part in raw:gmatch("[^%s']+") do
        reason, confidence = exactMatch(part)
        if reason then return reason, confidence end

        if decorativeX(part) then
            return "Decorative X prefix/suffix (online nickname style)", "medium"
        end
    end

    for _, prefix in ipairs(phrasePrefixes) do
        if joined:match(prefix) then
            return "Sentence-like or modern joke-name prefix", "medium"
        end
    end

    if joined:match("([a-z])%1%1%1") then
        return "Four or more consecutive identical letters", "low"
    end
    return nil
end
