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

-- Contemporary concepts that are particularly implausible as fantasy names.
-- Exact word or joined first/surname only; no matching inside invented names.
local technology = {
    -- Internet, computers, networks, and security
    wifi = true, bluetooth = true, ethernet = true, router = true,
    modem = true, hotspot = true, broadband = true, fiberoptic = true,
    gigabit = true, internet = true, website = true, webpage = true,
    webbrowser = true, searchengine = true, searchhistory = true,
    download = true, upload = true, screenshot = true, screenrecording = true,
    smartphone = true, cellphone = true, mobilephone = true,
    iphone = true, ipad = true, macbook = true, laptop = true,
    computer = true, desktopcomputer = true, tabletcomputer = true,
    touchscreen = true, microchip = true, motherboard = true,
    graphicscard = true, harddrive = true, flashdrive = true,
    usbdrive = true, solidstatedrive = true, keyboard = true,
    mousepad = true, webcam = true, photocopier = true,
    password = true, passcode = true, captcha = true,
    twofactor = true, twofactorauth = true, antivirus = true,
    malware = true, ransomware = true, phishing = true,
    spamemail = true, emailaddress = true, inbox = true,
    -- Software, AI, and online services
    sourcecode = true, javascript = true, typescript = true,
    html = true, css = true, sql = true, json = true,
    spreadsheet = true, database = true, programmer = true,
    softwareupdate = true,
    operatingsystem = true, windowsupdate = true,
    github = true, stackoverflow = true, chatgpt = true,
    openai = true, artificialintelligence = true,
    machinelearning = true, neuralnetwork = true,
    generativeai = true, deepfake = true, chatbot = true,
    livestream = true, livestreaming = true, videocall = true,
    videochat = true,
    videoconference = true, podcast = true, zoomcall = true,
    -- Online finance and technology-specific modern products
    cryptocurrency = true, bitcoin = true, ethereum = true,
    blockchain = true, cryptowallet = true, nft = true,
    smartcontract = true, electricvehicle = true,
    selfdrivingcar = true, electriccar = true,
}

-- Products, institutions, and daily-life concepts distinctly modern
-- in their full spelling. Individual generic words (e.g. "tax", "steam",
-- "engine", "bank", "craft") are intentionally excluded.
local modernLife = {
    -- Modern transport and household technology
    automobile = true, pickuptruck = true, schoolbus = true,
    trafficlight = true, trafficjam = true, parkingticket = true,
    parkingmeter = true, gasstation = true, airportsecurity = true,
    jetplane = true, helicopter = true, skateboard = true,
    airfryer = true, microwave = true, refrigerator = true,
    dishwasher = true, washingmachine = true, vacuumcleaner = true,
    electrictoothbrush = true, coffeemaker = true, toasteroven = true,
    -- Contemporary finances, workplaces, and bureaucracy
    creditcard = true, debitcard = true, creditreport = true,
    creditscore = true, taxreturn = true, taxrefund = true,
    taxseason = true, studentloan = true, studentloans = true,
    healthinsurance = true, carinsurance = true,
    socialsecurity = true, retirementplan = true,
    pensionfund = true, mortgagepayment = true, paydayloan = true,
    jobinterview = true, jobapplication = true, corporatemeeting = true,
    shareholdermeeting = true, powerpoints = true,
    powerpoint = true, customerservice = true,
    customersupport = true, humanresources = true,
    -- Social media, online shopping, and media concepts
    socialmedia = true, influencer = true, contentcreator = true,
    livestreamer = true, streamer = true, vlogger = true,
    youtuber = true, clickbait = true, ragebait = true,
    doomscrolling = true, hashtag = true, selfie = true,
    photobomb = true,
    onlinedating = true, datingapp = true,
    swiperight = true, swipeleft = true, deliveryapp = true,
    fooddelivery = true, onlineorder = true,
    subscriptionfee = true, monthlysubscription = true,
    notification = true, unsubscribe = true,
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
    -- Twitch, competitive gaming, and internet shorthand
    poggers = true, pogchamp = true, omegalul = true, kekw = true,
    lulw = true, pepehands = true, sadge = true, monkas = true,
    copium = true, hopium = true, malding = true, rizzler = true,
    gigachad = true, cringelord = true, brainrot = true,
    doomposter = true, normie = true, edgelord = true,
    skilldiff = true, tankdiff = true, healdiff = true,
    dpsdiff = true, pingdiff = true, lagspike = true,
    streamsniper = true, ragequit = true, altf4 = true,
    ezclap = true, quickscope = true, noscoper = true,
    noscoped = true, blazeit = true, yeet = true,
    slayqueen = true, ratioed = true, copeharder = true,
    cryaboutit = true, wompwomp = true, feelsbadman = true,
    feelsgoodman = true, notlikethis = true,
    memelord = true, memequeen = true,
    -- Avoid broad/ambiguous terms like "troll", "raid", "tank",
    -- "sigma", "chad", "based", "salty", and "mid".
    idk = true, idc = true, ikr = true, smh = true,
    tbh = true, imho = true, frfr = true, wtf = true,
    omg = true, bruh = true, sus = true, gg = true,
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
    -- Joke accounts, spam, gamer tags, and out-of-world messages
    notabot = true, justabot = true, notarealplayer = true,
    username = true, usernametaken = true, nameistaken = true,
    passwordreset = true, forgotpassword = true,
    error404 = true, pagenotfound = true, loadingpleasewait = true,
    pleasewait = true,
    loadingscreen = true, freegold = true, buygold = true,
    cheapgold = true, sellgold = true, sendgold = true,
    goldseller = true, goldselling = true, paytowin = true,
    pay2win = true, freewins = true, easymode = true,
    momsaidno = true, momsaidyes = true, dadsaidno = true,
    dontbanme = true, banmeplease = true, reportme = true,
    dontreportme = true, alreadybanned = true, bannedagain = true,
    unsubscribed = true, likeandsubscribe = true,
    likeandsub = true, sub2me = true, followmytwitch = true,
    streamingnow = true, likemyvideo = true,
    imafk = true, brbsoon = true, needheals = true,
    plshelp = true, plzhelp = true, plsno = true,
    ihavenolife = true, thisisameme = true,
}

-- Specific prefixes only. Broad prefixes like "^my" or "^no"
-- would produce too many false positives on genuine RP names.
local phrasePrefixes = {
    "^ilove", "^ihate", "^mynameis", "^yourmom", "^yourdad",
    "^urmom", "^urdad", "^followme", "^subscribeto", "^sendhelp",
    "^touchgrass", "^giveme", "^pleasegive", "^wheresmy",
    "^whereismy", "^imthebest", "^imnot", "^youmadbro",
    "^pleasefollow", "^ineedhealing",
    "^dontbanme", "^dontreportme", "^imafk",
    "^followmytwitch", "^likeandsubscribe", "^sub2me",
    "^freegold", "^buygold", "^sendgold",
    "^mywifi", "^myinternet", "^passwordreset",
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
    return stripped and (references[stripped] or technology[stripped] or
        modernLife[stripped] or slang[stripped] or jokePhrases[stripped]) or false
end

local function exactMatch(part)
    if examples[part] then return "Blizzard RP naming-policy example", "high" end
    if references[part] then return "Modern/pop-culture reference", "medium" end
    if technology[part] then return "Modern technology or internet term", "medium" end
    if modernLife[part] then return "Modern product, institution or concept", "medium" end
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

        -- Streaming-platform handle suffixes; not arbitrary "x" endings.
        if part:match("^[a-z][a-z][a-z]+ttv$") or
            part:match("^[a-z][a-z][a-z]+yt$") then
            return "Streamer/gamer-tag suffix", "medium"
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
