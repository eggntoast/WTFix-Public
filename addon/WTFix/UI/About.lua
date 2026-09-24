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
    local function label(text, font, muted)
        local fs = ns.UI_CreateLabel(body, text, muted, font)
        fs:SetJustifyV("TOP")
        fs:SetWordWrap(true)
        return fs
    end
    local brand = label("WTFix " .. ns.version, T.fonts.brand, false)
    local subtitle = label("SavedVariables recovery for WoW Forever", T.fonts.body, true)
    local divider = body:CreateTexture(nil, "ARTWORK")
    divider:SetHeight(1)
    T.SetColorTexture(divider, C.borderSoft)

    local title = label("What's New in " .. ns.version, T.fonts.section, false)
    title:SetTextColor(unpack(C.accentBright))
    local changes = {
        "Added Linux preparation support (Preview).",
        "Added dedicated Linux Full and Prepare packages.",
        "Improved cross-platform ZIP portability.",
        "Fixed Protected Addons SNAPSHOT column alignment.",
    }
    local items = {}
    for index, text in ipairs(changes) do
        local dot = body:CreateTexture(nil, "ARTWORK")
        dot:SetSize(4, 4)
        T.SetColorTexture(dot, C.accent)
        items[index] = {text=label(text, T.fonts.body, false), dot=dot}
    end

    local support = label("Support / Bug Reports", T.fonts.section, false)
    support:SetTextColor(unpack(C.accentBright))
    local instructions = label("Include your WTFix version and /wtfix status. For Save issues, add /wtfix check.",
        T.fonts.bodySmall, true)
    local report = ns.UI_CreateButton(body, "Report a Bug", 154, "secondary")

    local copyBox = ns.UI_CreateCard(body, 34, true)
    local url = CreateFrame("EditBox", nil, copyBox)
    url:SetPoint("TOPLEFT", 10, -6)
    url:SetPoint("BOTTOMRIGHT", -10, 6)
    url:SetFontObject(T.fonts.bodySmall)
    url:SetAutoFocus(false)
    url:SetMultiLine(false)
    url:SetMaxLetters(#issueURL)
    url:SetText(issueURL)
    local hint = label("Press Ctrl+C to copy the link, then paste it into your browser.", T.fonts.bodySmall, true)
    copyBox:Hide()
    hint:Hide()

    local expanded, layingOut = false, false
    local function layout()
        if layingOut then return end
        local width = scroll.scroll:GetWidth()
        if not width or width <= 1 then return end -- Wait for real panel geometry.
        layingOut = true
        body:SetWidth(width)
        local y = 0
        local function place(fs, inset, minimum)
            fs:ClearAllPoints()
            fs:SetPoint("TOPLEFT", inset or 0, -y)
            fs:SetWidth(math.max(1, width - 12 - (inset or 0)))
            -- Measure wrapping at the current width instead of reserving fixed rows.
            local height = math.max(minimum or 16, math.ceil(fs:GetStringHeight()))
            fs:SetHeight(height)
            y = y + height
        end
        place(brand, 0, 28); y = y + 6
        place(subtitle); y = y + 18
        divider:ClearAllPoints()
        divider:SetPoint("TOPLEFT", 0, -y)
        divider:SetPoint("TOPRIGHT", -12, -y)
        y = y + 19
        place(title, 0, 20); y = y + 12
        for index, item in ipairs(items) do
            item.dot:ClearAllPoints()
            item.dot:SetPoint("TOPLEFT", 0, -y - 5)
            place(item.text, 14)
            if index < #items then y = y + 8 end
        end
        y = y + 18
        place(support, 0, 20); y = y + 8
        place(instructions); y = y + 12
        report:ClearAllPoints()
        report:SetPoint("TOPLEFT", 0, -y)
        y = y + report:GetHeight()
        if expanded then
            y = y + 12
            copyBox:ClearAllPoints()
            copyBox:SetPoint("TOPLEFT", 0, -y)
            copyBox:SetPoint("TOPRIGHT", -12, -y)
            y = y + copyBox:GetHeight() + 8
            place(hint)
        end
        -- Hidden copy controls must not create blank scrolling space.
        body:SetHeight(y + 8)
        local range = math.max(0, body:GetHeight() - scroll.scroll:GetHeight())
        scroll.scroll:SetVerticalScroll(math.min(scroll.scroll:GetVerticalScroll() or 0, range))
        scroll.UpdateThumb()
        layingOut = false
    end
    local function collapse()
        url:ClearFocus()
        expanded = false
        copyBox:Hide()
        hint:Hide()
        layout()
    end
    body:SetScript("OnSizeChanged", layout)
    url:SetScript("OnEditFocusGained", function(self) self:HighlightText() end)
    url:SetScript("OnMouseUp", function(self) self:HighlightText() end)
    url:SetScript("OnTextChanged", function(self, userInput)
        if userInput then self:SetText(issueURL); self:HighlightText() end
    end)
    url:SetScript("OnEscapePressed", collapse)
    url:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)
    report:SetScript("OnClick", function()
        expanded = true
        copyBox:Show()
        hint:Show()
        layout()
        scroll.scroll:SetVerticalScroll(math.max(0, body:GetHeight() - scroll.scroll:GetHeight()))
        scroll.UpdateThumb()
        url:SetText(issueURL)
        url:SetFocus()
        url:HighlightText()
    end)
    page:SetScript("OnShow", layout)
    page:SetScript("OnHide", collapse)

    return page
end
