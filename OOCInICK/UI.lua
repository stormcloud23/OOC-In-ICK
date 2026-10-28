local addonName, ns = ...
local frame, rows, page = nil, {}, 0
local VISIBLE = 8

local function makeButton(parent, label, width, height, anchor, x, y, callback)
    local button = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    button:SetSize(width, height)
    button:SetPoint("TOPLEFT", anchor or parent, "TOPLEFT", x or 0, y or 0)
    button:SetText(label)
    button:SetScript("OnClick", callback)
    return button
end

function ns.ShowDetails(entry)
    if not entry then return end
    if not StaticPopupDialogs.OOCINICK_DETAILS then
        StaticPopupDialogs.OOCINICK_DETAILS = {
            text = "Suggested report details (Ctrl+C to copy; you must submit any report yourself):",
            button1 = CLOSE,
            hasEditBox = true,
            editBoxWidth = 335,
            OnShow = function(self, data)
                local eb = self.EditBox or self.editBox
                if eb then
                    eb:SetText(ns.ReportDetails(data))
                    eb:SetFocus()
                    eb:HighlightText()
                end
            end,
            timeout = 0,
            whileDead = true,
            hideOnEscape = true,
            preferredIndex = 3,
        }
    end
    StaticPopup_Show("OOCINICK_DETAILS", nil, nil, entry)
end

local function build()
    if frame then return end
    frame = CreateFrame("Frame", "OOCInICKFrame", UIParent, "BasicFrameTemplateWithInset")
    frame:SetSize(684, 458)
    frame:SetPoint("CENTER")
    frame:SetClampedToScreen(true)
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", function(self) self:StartMoving() end)
    frame:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)
    frame:SetFrameStrata("DIALOG")
    frame:Hide()

    local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetPoint("TOPLEFT", frame, "TOPLEFT", 15, -11)
    title:SetText("OOC-In-ICK | RP Name Review")

    local help = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    help:SetPoint("TOPLEFT", frame, "TOPLEFT", 17, -40)
    help:SetText("Heuristic suggestions only. Review each name before reporting. Nothing is auto-submitted.")

    local headings = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    headings:SetPoint("TOPLEFT", frame, "TOPLEFT", 22, -65)
    headings:SetText("Character / reason")

    for i = 1, VISIBLE do
        local row = CreateFrame("Frame", nil, frame)
        row:SetSize(640, 35)
        row:SetPoint("TOPLEFT", frame, "TOPLEFT", 18, -80 - (i - 1) * 36)
        local label = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        label:SetPoint("LEFT", row, "LEFT", 3, 0)
        label:SetWidth(362)
        label:SetJustifyH("LEFT")
        label:SetWordWrap(false)
        row.label = label

        row.report = makeButton(row, "Report", 66, 25, row, 371, -5, function()
            if row.entry then ns.OpenReport(row.entry) end
        end)
        row.details = makeButton(row, "Details", 63, 25, row, 440, -5, function()
            if row.entry then ns.ShowDetails(row.entry) end
        end)
        row.ignore = makeButton(row, "Ignore", 60, 25, row, 506, -5, function()
            if row.key then ns.Delete(row.key, true) end
        end)
        row.remove = makeButton(row, "X", 28, 25, row, 569, -5, function()
            if row.key then ns.Delete(row.key, false) end
        end)
        rows[#rows + 1] = row
    end

    frame.status = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    frame.status:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 22, 57)

    makeButton(frame, "< Prev", 75, 25, frame, 20, -393, function()
        page = math.max(0, page - 1)
        ns.Refresh()
    end)
    makeButton(frame, "Next >", 75, 25, frame, 100, -393, function()
        local maxPage = math.max(0, math.ceil(#ns.GetEntries() / VISIBLE) - 1)
        page = math.min(maxPage, page + 1)
        ns.Refresh()
    end)
    makeButton(frame, "Scan visible", 108, 25, frame, 195, -393, function()
        ns.ScanVisible()
        ns.Print("Rechecked visible nameplates/target/mouseover.")
    end)
    makeButton(frame, "Close", 70, 25, frame, 565, -393, function()
        frame:Hide()
    end)
    frame:EnableMouseWheel(true)
    frame:SetScript("OnMouseWheel", function(_, direction)
        local maxPage = math.max(0, math.ceil(#ns.GetEntries() / VISIBLE) - 1)
        page = math.max(0, math.min(maxPage, page - direction))
        ns.Refresh()
    end)
end

function ns.Refresh()
    if not frame or not frame:IsShown() then return end
    local entries = ns.GetEntries()
    page = math.max(0, math.min(page, math.max(0, math.ceil(#entries / VISIBLE) - 1)))
    for i = 1, VISIBLE do
        local row = rows[i]
        local item = entries[page * VISIBLE + i]
        if item then
            row.entry, row.key = item.data, item.key
            local data = item.data
            local reason = data.reason or "Manual review"
            if #reason > 49 then reason = reason:sub(1, 46) .. "..." end
            row.label:SetText("|cffffcc66" .. data.name .. "|r - " .. reason)
            row:Show()
        else
            row.entry, row.key = nil, nil
            row:Hide()
        end
    end
    frame.status:SetText(string.format("%d candidate(s) | Page %d/%d | Report = Blizzard's window",
        #entries, page + 1, math.max(1, math.ceil(#entries / VISIBLE))))
end

function ns.Toggle()
    build()
    if frame:IsShown() then
        frame:Hide()
    else
        frame:Show()
        ns.Refresh()
    end
end
