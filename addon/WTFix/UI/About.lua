local _, ns = ...
local T, C = ns.Theme, ns.Theme.colors
local issueURL = "https://github.com/eggntoast/WTFix-Public/issues"

-- A page in the existing settings panel. No browser API, clipboard API,
-- SavedVariables mutation or recovery action is needed to copy the support URL.
function ns.UI_CreateAboutPage(parent)
    local page = ns.UI_CreateCard(parent)
    local scroll = ns.UI_CreateScroll(page)
    scroll:SetPoint("TOPLEFT", 20, -18)
    scroll:SetPoint("BOTTOMRIGHT", -14, 32)
    local body = scroll.child
    body:SetHeight(540)

    local function label(text, y, font, muted, height)
        local fs = ns.UI_CreateLabel(body, text, muted, font)
        fs:SetPoint("TOPLEFT", 0, y)
        fs:SetPoint("RIGHT", -12, 0)
        fs:SetHeight(height or 24)
        fs:SetJustifyV("TOP")
        fs:SetWordWrap(true)
        return fs
    end
    label("WTFix " .. ns.version, 0, T.fonts.brand, false, 28)
    label("SavedVariables recovery for WoW Forever", -34, T.fonts.body, true)
    local divider = body:CreateTexture(nil, "ARTWORK")
    divider:SetPoint("TOPLEFT", 0, -72)
    divider:SetPoint("TOPRIGHT", -12, -72)
    divider:SetHeight(1)
    T.SetColorTexture(divider, C.borderSoft)

    local title = label("What's New in " .. ns.version, -92, T.fonts.section, false)
    title:SetTextColor(unpack(C.accentBright))
    local changes = {
        "More reliable recovery of character-specific settings on Forever.",
        "Ambiguous character matches are never guessed.",
        "Save checks that the complete checkpoint fits safe recovery limits.",
        "Your previous checkpoint stays protected if capture cannot complete.",
    }
    for index, text in ipairs(changes) do
        local y = -126 - (index - 1) * 38
        local dot = body:CreateTexture(nil, "ARTWORK")
        dot:SetSize(4, 4)
        dot:SetPoint("TOPLEFT", 0, y - 4)
        T.SetColorTexture(dot, C.accent)
        local item = label(text, y, T.fonts.body, false, 34)
        item:ClearAllPoints()
        item:SetPoint("TOPLEFT", 14, y)
        item:SetPoint("RIGHT", -12, 0)
    end

    local support = label("Support / Bug Reports", -334, T.fonts.section, false)
    support:SetTextColor(unpack(C.accentBright))
    label("Include your WTFix version and /wtfix status. For Save issues, add /wtfix check.",
        -362, T.fonts.bodySmall, true, 36)
    local report = ns.UI_CreateButton(body, "Report a Bug", 154, "secondary")
    report:SetPoint("TOPLEFT", 0, -408)

    local copyBox = ns.UI_CreateCard(body, 34, true)
    copyBox:SetPoint("TOPLEFT", 0, -456)
    copyBox:SetPoint("TOPRIGHT", -12, -456)
    local url = CreateFrame("EditBox", nil, copyBox)
    url:SetPoint("TOPLEFT", 10, -6)
    url:SetPoint("BOTTOMRIGHT", -10, 6)
    url:SetFontObject(T.fonts.bodySmall)
    url:SetAutoFocus(false)
    url:SetMultiLine(false)
    url:SetMaxLetters(#issueURL)
    url:SetText(issueURL)
    local hint = label("Press Ctrl+C to copy the link, then paste it into your browser.",
        -502, T.fonts.bodySmall, true, 32)
    copyBox:Hide()
    hint:Hide()
    url:SetScript("OnEditFocusGained", function(self) self:HighlightText() end)
    url:SetScript("OnMouseUp", function(self) self:HighlightText() end)
    url:SetScript("OnTextChanged", function(self, userInput)
        if userInput then self:SetText(issueURL); self:HighlightText() end
    end)
    url:SetScript("OnEscapePressed", function(self) self:ClearFocus(); copyBox:Hide(); hint:Hide() end)
    url:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)
    report:SetScript("OnClick", function()
        copyBox:Show()
        hint:Show()
        scroll.scroll:SetVerticalScroll(scroll.scroll:GetVerticalScrollRange() or 0)
        scroll.UpdateThumb()
        url:SetText(issueURL)
        url:SetFocus()
        url:HighlightText()
    end)
    page:SetScript("OnShow", function() scroll.UpdateThumb() end)
    page:SetScript("OnHide", function() url:ClearFocus(); copyBox:Hide(); hint:Hide() end)

    return page
end
