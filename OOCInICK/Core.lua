local addonName, ns = ...
local addon = CreateFrame("Frame")
ns.addon = addon

local defaults = {enabled = true, chat = true, zoneChat = false, notify = true, maxEntries = 300}
local db
local lastNotice = {}
local MAX_NAME_BYTES = 100

local function safe(fn, ...)
    if type(fn) ~= "function" then return nil end
    local ok, a, b = pcall(fn, ...)
    if not ok then return nil end
    if type(issecretvalue) == "function" then
        if issecretvalue(a) or issecretvalue(b) then return nil end
    end
    return a, b
end

local function text(value)
    if type(issecretvalue) == "function" and issecretvalue(value) then return nil end
    if type(value) ~= "string" or value == "" or #value > MAX_NAME_BYTES then return nil end
    return value
end

local function output(message)
    if DEFAULT_CHAT_FRAME then
        DEFAULT_CHAT_FRAME:AddMessage("|cffd5a65aOOC-In-ICK:|r " .. message)
    end
end
ns.Print = output

function ns.DB()
    return db
end

local function getUnitName(unit)
    -- Forever GetUnitName returns the complete "First Surname".
    local combined = text(safe(GetUnitName, unit, true))
    if combined then return combined end
    local first, surname = safe(UnitName, unit)
    first, surname = text(first), text(surname)
    if first then return surname and (first .. " " .. surname) or first end
    return nil
end
ns.GetUnitName = getUnitName

local function getZone()
    return text(safe(GetZoneText)) or "Unknown zone"
end

local function now()
    return safe(GetServerTime) or time()
end

local function prune()
    local count, ordered = 0, {}
    for key, entry in pairs(db.entries) do
        count = count + 1
        ordered[#ordered + 1] = {key = key, seen = entry.lastSeen or 0}
    end
    if count <= db.options.maxEntries then return end
    table.sort(ordered, function(a, b) return a.seen < b.seen end)
    for i = 1, count - db.options.maxEntries do
        db.entries[ordered[i].key] = nil
    end
end

function ns.ObserveName(name, guid, source, manual)
    if not db or (not db.options.enabled and not manual) then return end
    name = text(name)
    if not name then return end
    local key = ns.NormalizeName(name)
    if not key or key == "" or key == ns.NormalizeName(getUnitName("player")) then return end
    if db.ignored[key] then return end
    local reason, confidence = ns.EvaluateName(name, db.custom)
    if not reason and not manual then return end
    reason = reason or "Manually added for review"
    confidence = confidence or "manual"

    local entry = db.entries[key]
    if entry then
        entry.lastSeen = now()
        entry.sightings = (entry.sightings or 1) + 1
        entry.zone = getZone()
        entry.source = source or entry.source
        if type(guid) == "string" and guid:find("^Player%-") then entry.guid = guid end
        if entry.confidence ~= "manual" then
            entry.reason, entry.confidence = reason, confidence
        end
    else
        db.entries[key] = {
            name = name, reason = reason, confidence = confidence,
            zone = getZone(), source = source or "Unknown",
            firstSeen = now(), lastSeen = now(), sightings = 1,
            guid = (type(guid) == "string" and guid:find("^Player%-")) and guid or nil,
        }
        prune()
        if db.options.notify and (not lastNotice[key] or GetTime() - lastNotice[key] > 30) then
            lastNotice[key] = GetTime()
            output("Review suggested: " .. name .. " (" .. reason .. "). /ooc")
        end
    end
    if ns.Refresh then ns.Refresh() end
end

function ns.ObserveUnit(unit, source)
    if not db or not db.options.enabled then return end
    if not safe(UnitExists, unit) or not safe(UnitIsPlayer, unit) then return end
    if safe(UnitIsUnit, unit, "player") then return end
    local name = getUnitName(unit)
    if not name then return end
    local guid = text(safe(UnitGUID, unit))
    ns.ObserveName(name, guid, source or "Nearby")
end

function ns.GetEntries()
    local result = {}
    if not db then return result end
    for key, entry in pairs(db.entries) do
        result[#result + 1] = {key = key, data = entry}
    end
    table.sort(result, function(a, b)
        if a.data.lastSeen == b.data.lastSeen then return a.key < b.key end
        return (a.data.lastSeen or 0) > (b.data.lastSeen or 0)
    end)
    return result
end

function ns.Delete(key, ignore)
    if not db then return end
    if ignore then db.ignored[key] = true end
    db.entries[key] = nil
    if ns.Refresh then ns.Refresh() end
end

function ns.ReportDetails(entry)
    return "Potential RP naming-policy concern: " .. entry.name .. ". "
        .. "Reason for human review: " .. entry.reason .. ". "
        .. "Observed in: " .. (entry.zone or "Unknown zone")
        .. ". This is an addon-generated suggestion, not a verified violation."
end

local function getCurrentLocation(entry)
    -- Prefer fresh unit tokens; avoid confusing same-first-name characters.
    local candidates = {"target", "mouseover", "focus"}
    for i = 1, 40 do candidates[#candidates + 1] = "nameplate" .. i end
    for _, unit in ipairs(candidates) do
        if safe(UnitExists, unit) and safe(UnitIsPlayer, unit) then
            local guid = text(safe(UnitGUID, unit))
            if (entry.guid and guid == entry.guid) or
               (not entry.guid and getUnitName(unit) == entry.name) then
                local location = safe(PlayerLocation and PlayerLocation.CreateFromUnit, PlayerLocation, unit)
                if location then return location end
            end
        end
    end
    if entry.guid then
        return safe(PlayerLocation and PlayerLocation.CreateFromGUID, PlayerLocation, entry.guid)
    end
    return nil
end

function ns.OpenReport(entry)
    if not entry then return end
    if InCombatLockdown and InCombatLockdown() then
        output("Open reports outside combat to avoid protected-UI restrictions.")
        return
    end

    if not ReportFrame then
        if C_AddOns and C_AddOns.LoadAddOn then
            pcall(C_AddOns.LoadAddOn, "Blizzard_ReportFrame")
        elseif UIParentLoadAddOn then
            pcall(UIParentLoadAddOn, "Blizzard_ReportFrame")
        end
    end

    if not (ReportFrame and ReportInfo and Enum and Enum.ReportType
        and Enum.ReportType.InWorld and PlayerLocation) then
        output("The native report window is unavailable. Target the player and use Blizzard's right-click Report menu.")
        if ns.ShowDetails then ns.ShowDetails(entry) end
        return
    end

    local location = getCurrentLocation(entry)
    if not location then
        output("Cannot resolve a reportable player location. Target/mouse over this character and press Report again.")
        if ns.ShowDetails then ns.ShowDetails(entry) end
        return
    end

    local info = ReportInfo:CreateReportInfoFromType(Enum.ReportType.InWorld)
    local ok, err = pcall(function()
        -- A click on OUR button initiates Blizzard's report dialog.
        -- It never calls C_ReportSystem.SendReport (a protected function).
        ReportFrame:InitiateReport(info, entry.name, location)
    end)
    if not ok then
        output("The client blocked opening its report dialog. Use right-click > Report.")
        if ns.ShowDetails then ns.ShowDetails(entry) end
        return
    end

    -- Best effort category/description prefill, after the report frame opens.
    -- These are UI-only modifications, not report submission.
    if ReportFrame.MajorTypeSelected and Enum.ReportMajorCategory
        and Enum.ReportMajorCategory.InappropriateName then
        pcall(ReportFrame.MajorTypeSelected, ReportFrame,
            Enum.ReportType.InWorld, Enum.ReportMajorCategory.InappropriateName)
    end
    local editBox = ReportFrame.Comment and ReportFrame.Comment.EditBox
    if editBox and editBox.SetText then
        pcall(editBox.SetText, editBox, ns.ReportDetails(entry))
    else
        output("Category/notes may require manual selection; use Details to copy the suggested description.")
    end
    entry.reportDialogOpened = now() -- NOT proof a report was submitted.
    if ns.Refresh then ns.Refresh() end
end

local function handleChat(event, _, sender, ...)
    if not db or not db.options.enabled then return end
    if event == "CHAT_MSG_CHANNEL" and not db.options.zoneChat then return end
    if event ~= "CHAT_MSG_CHANNEL" and not db.options.chat then return end
    local args = {...}
    local guid = args[10] -- 12th event argument (message, sender, ...).
    ns.ObserveName(sender, guid, event)
end

function ns.ScanVisible()
    ns.ObserveUnit("target", "Target")
    ns.ObserveUnit("mouseover", "Mouseover")
    ns.ObserveUnit("focus", "Focus")
    for i = 1, 40 do ns.ObserveUnit("nameplate" .. i, "Nameplate") end
end

local function command(input)
    local cmd, arg = (input or ""):match("^%s*(%S*)%s*(.-)%s*$")
    cmd = (cmd or ""):lower()
    if cmd == "" or cmd == "show" then
        if ns.Toggle then ns.Toggle() end
    elseif cmd == "scan" then
        ns.ScanVisible()
        output("Scanned currently available unit tokens (not a zone-wide roster).")
    elseif cmd == "test" then
        local reason = ns.EvaluateName(arg, db.custom)
        output(arg .. ": " .. (reason or "No heuristic match (not proof of compliance)."))
    elseif cmd == "add" then
        ns.ObserveName(arg, nil, "Manual", true)
    elseif cmd == "ignore" then
        local key = ns.NormalizeName(arg)
        if key then ns.Delete(key, true); output("Ignored " .. arg) end
    elseif cmd == "unignore" then
        local key = ns.NormalizeName(arg)
        if key then db.ignored[key] = nil; output("Unignored " .. arg) end
    elseif cmd == "watch" then
        local key = ns.NormalizeName(arg)
        if key and key ~= "" then db.custom[key] = true; output("Custom watched: " .. arg) end
    elseif cmd == "unwatch" then
        local key = ns.NormalizeName(arg)
        if key then db.custom[key] = nil; output("Removed custom watch: " .. arg) end
    elseif cmd == "on" or cmd == "off" then
        db.options.enabled = cmd == "on"
        output("Detection " .. (db.options.enabled and "enabled" or "disabled"))
    elseif cmd == "chat" or cmd == "zonechat" or cmd == "notify" then
        local key = cmd == "zonechat" and "zoneChat" or cmd
        db.options[key] = not db.options[key]
        output(cmd .. " = " .. tostring(db.options[key]))
    elseif cmd == "clear" then
        db.entries = {}
        if ns.Refresh then ns.Refresh() end
        output("Review queue cleared (ignored names retained).")
    elseif cmd == "status" then
        output("Detection=" .. tostring(db.options.enabled) .. ", nearby chat=" .. tostring(db.options.chat)
            .. ", zone channel=" .. tostring(db.options.zoneChat) .. ", queued=" .. #ns.GetEntries())
    else
        output("Commands: /ooc, /ooc scan, /ooc test NAME, /ooc add NAME, /ooc watch NAME, /ooc unwatch NAME, /ooc ignore NAME, /ooc unignore NAME")
        output("Options: /ooc on|off, /ooc chat, /ooc zonechat, /ooc notify, /ooc clear, /ooc status")
    end
end

SLASH_OOCINICK1 = "/ooc"
SLASH_OOCINICK2 = "/oocick"
SlashCmdList.OOCINICK = command

addon:RegisterEvent("ADDON_LOADED")
addon:RegisterEvent("PLAYER_LOGIN")
addon:RegisterEvent("NAME_PLATE_UNIT_ADDED")
addon:RegisterEvent("PLAYER_TARGET_CHANGED")
addon:RegisterEvent("UPDATE_MOUSEOVER_UNIT")
addon:RegisterEvent("UNIT_NAME_UPDATE")
addon:RegisterEvent("CHAT_MSG_SAY")
addon:RegisterEvent("CHAT_MSG_YELL")
addon:RegisterEvent("CHAT_MSG_EMOTE")
addon:RegisterEvent("CHAT_MSG_TEXT_EMOTE")
addon:RegisterEvent("CHAT_MSG_CHANNEL")

addon:SetScript("OnEvent", function(_, event, ...)
    if event == "ADDON_LOADED" then
        if ... ~= addonName then return end
        OOCInICKDB = OOCInICKDB or {}
        db = OOCInICKDB
        db.entries = db.entries or {}
        db.ignored = db.ignored or {}
        db.custom = db.custom or {}
        db.options = db.options or {}
        for key, value in pairs(defaults) do
            if db.options[key] == nil then db.options[key] = value end
        end
        addon:UnregisterEvent("ADDON_LOADED")
    elseif event == "PLAYER_LOGIN" then
        if db then
            output("Ready. /ooc opens the review queue. No reports are sent automatically.")
            ns.ScanVisible()
        end
    elseif event == "NAME_PLATE_UNIT_ADDED" or event == "UNIT_NAME_UPDATE" then
        ns.ObserveUnit(..., event)
    elseif event == "PLAYER_TARGET_CHANGED" then
        ns.ObserveUnit("target", "Target")
    elseif event == "UPDATE_MOUSEOVER_UNIT" then
        ns.ObserveUnit("mouseover", "Mouseover")
    elseif event:match("^CHAT_MSG_") then
        handleChat(event, ...)
    end
end)
