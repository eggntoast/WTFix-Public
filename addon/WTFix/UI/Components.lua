local _, ns = ...

local T = ns.Theme
local C = T.colors
local M = T.metrics

local function colorText(fs, color)
    fs:SetTextColor(color[1], color[2], color[3], color[4] or 1)
end

local function addFrameBorder(parent, target, color)
    local top = parent:CreateTexture(nil, "BORDER")
    top:SetPoint("TOPLEFT", target, "TOPLEFT")
    top:SetPoint("TOPRIGHT", target, "TOPRIGHT")
    top:SetHeight(1)
    T.SetColorTexture(top, color)

    local bottom = parent:CreateTexture(nil, "BORDER")
    bottom:SetPoint("BOTTOMLEFT", target, "BOTTOMLEFT")
    bottom:SetPoint("BOTTOMRIGHT", target, "BOTTOMRIGHT")
    bottom:SetHeight(1)
    T.SetColorTexture(bottom, color)

    local left = parent:CreateTexture(nil, "BORDER")
    left:SetPoint("TOPLEFT", target, "TOPLEFT")
    left:SetPoint("BOTTOMLEFT", target, "BOTTOMLEFT")
    left:SetWidth(1)
    T.SetColorTexture(left, color)

    local right = parent:CreateTexture(nil, "BORDER")
    right:SetPoint("TOPRIGHT", target, "TOPRIGHT")
    right:SetPoint("BOTTOMRIGHT", target, "BOTTOMRIGHT")
    right:SetWidth(1)
    T.SetColorTexture(right, color)

    return top, bottom, left, right
end

function ns.UI_CreateCard(parent, height, alt, raised)
    local frame = CreateFrame("Frame", nil, parent)
    if height then frame:SetHeight(height) end
    T.AddPanelSkin(frame, alt, raised)
    return frame
end

function ns.UI_CreateSectionTitle(parent, text)
    local fs = parent:CreateFontString(nil, "OVERLAY", T.fonts.section)
    fs:SetText(text or "")
    fs:SetJustifyH("LEFT")
    colorText(fs, C.accentBright)
    return fs
end

function ns.UI_CreateLabel(parent, text, muted, template)
    local fs = parent:CreateFontString(nil, "OVERLAY", template or T.fonts.body)
    fs:SetText(text or "")
    fs:SetJustifyH("LEFT")
    fs:SetJustifyV("MIDDLE")
    colorText(fs, muted and C.muted or C.text)
    return fs
end

function ns.UI_CreateButton(parent, text, width, kind)
    local button = CreateFrame("Button", nil, parent)
    button:SetSize(width or 170, M.buttonHeight)
    button:RegisterForClicks("LeftButtonUp", "RightButtonUp")

    local shadow = button:CreateTexture(nil, "BACKGROUND")
    shadow:SetPoint("TOPLEFT", 2, -2)
    shadow:SetPoint("BOTTOMRIGHT", 2, -2)
    shadow:SetColorTexture(0, 0, 0, 0.32)

    local bg = button:CreateTexture(nil, "BACKGROUND", nil, 1)
    bg:SetAllPoints()

    local top, bottom, left, right = addFrameBorder(button, bg, C.border)
    local sheen = button:CreateTexture(nil, "BORDER")
    sheen:SetPoint("TOPLEFT", 2, -2)
    sheen:SetPoint("TOPRIGHT", -2, -2)
    sheen:SetHeight(1)

    local label = button:CreateFontString(nil, "OVERLAY", T.fonts.section)
    label:SetPoint("CENTER")
    label:SetText(text or "")

    button.__bg = bg
    button.__top = top
    button.__bottom = bottom
    button.__left = left
    button.__right = right
    button.__sheen = sheen
    button.__label = label
    button.__kind = kind or "primary"
    button.__enabled = true

    local function palette(self, state)
        local accent = self.__kind == "danger" and C.danger or C.border
        local fill = C.button
        if state == "hover" then
            fill = C.buttonHover
            accent = self.__kind == "danger" and C.danger or C.borderBright
        elseif state == "down" then
            fill = C.buttonDown
            accent = self.__kind == "danger" and C.danger or C.accent
        end
        if not self.__enabled then
            fill = C.buttonDisabled
            accent = C.dim
        end

        T.SetColorTexture(self.__bg, fill)
        T.SetColorTexture(self.__top, accent)
        T.SetColorTexture(self.__bottom, C.borderSoft)
        T.SetColorTexture(self.__left, C.borderSoft)
        T.SetColorTexture(self.__right, C.borderSoft)
        T.SetColorTexture(self.__sheen, self.__enabled and C.accentDim or C.borderSoft)
        colorText(self.__label, self.__enabled and C.text or C.muted)
    end

    button:SetScript("OnEnter", function(self) if self.__enabled then palette(self, "hover") end end)
    button:SetScript("OnLeave", function(self) palette(self, "normal") end)
    button:SetScript("OnMouseDown", function(self) if self.__enabled then palette(self, "down") end end)
    button:SetScript("OnMouseUp", function(self) if self.__enabled then palette(self, self:IsMouseOver() and "hover" or "normal") end end)

    function button:SetEnabledState(enabled)
        self.__enabled = enabled and true or false
        self:EnableMouse(self.__enabled)
        palette(self, "normal")
    end

    function button:SetButtonText(value)
        self.__label:SetText(value or "")
    end

    palette(button, "normal")
    return button
end

function ns.UI_CreateActionButton(parent, titleText, descriptionText, kind)
    local button = CreateFrame("Button", nil, parent)
    button:SetHeight(M.actionButtonHeight)
    button:RegisterForClicks("LeftButtonUp")
    button.__kind = kind or "primary"
    button.__enabled = true

    local shadow = button:CreateTexture(nil, "BACKGROUND")
    shadow:SetPoint("TOPLEFT", 2, -2)
    shadow:SetPoint("BOTTOMRIGHT", 2, -2)
    shadow:SetColorTexture(0, 0, 0, 0.38)

    local bg = button:CreateTexture(nil, "BACKGROUND", nil, 1)
    bg:SetAllPoints()

    local accent = button:CreateTexture(nil, "ARTWORK")
    accent:SetPoint("TOPLEFT", 0, 0)
    accent:SetPoint("BOTTOMLEFT", 0, 0)
    accent:SetWidth(4)

    local top, bottom, left, right = addFrameBorder(button, bg, C.border)

    local title = button:CreateFontString(nil, "OVERLAY", T.fonts.section)
    title:SetPoint("TOPLEFT", 14, -8)
    title:SetPoint("RIGHT", -10, 0)
    title:SetJustifyH("LEFT")
    title:SetText(titleText or "")

    local desc = button:CreateFontString(nil, "OVERLAY", T.fonts.bodySmall)
    desc:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -2)
    desc:SetPoint("RIGHT", -10, 0)
    desc:SetJustifyH("LEFT")
    desc:SetJustifyV("TOP")
    desc:SetWordWrap(true)
    desc:SetText(descriptionText or "")

    button.__bg = bg
    button.__accent = accent
    button.__top = top
    button.__bottom = bottom
    button.__left = left
    button.__right = right
    button.__title = title
    button.__desc = desc

    local function palette(self, state)
        local fill = C.button
        local edge = C.border
        if state == "hover" then
            fill = C.buttonHover
            edge = C.borderBright
        elseif state == "down" then
            fill = C.buttonDown
            edge = C.accent
        end
        if not self.__enabled then
            fill = C.buttonDisabled
            edge = C.dim
        end

        T.SetColorTexture(self.__bg, fill)
        T.SetColorTexture(self.__accent, self.__enabled and C.accent or C.dim)
        T.SetColorTexture(self.__top, edge)
        T.SetColorTexture(self.__bottom, C.borderSoft)
        T.SetColorTexture(self.__left, C.borderSoft)
        T.SetColorTexture(self.__right, C.borderSoft)
        colorText(self.__title, self.__enabled and C.text or C.muted)
        colorText(self.__desc, self.__enabled and C.muted or C.dim)
    end

    button:SetScript("OnEnter", function(self) if self.__enabled then palette(self, "hover") end end)
    button:SetScript("OnLeave", function(self) palette(self, "normal") end)
    button:SetScript("OnMouseDown", function(self) if self.__enabled then palette(self, "down") end end)
    button:SetScript("OnMouseUp", function(self) if self.__enabled then palette(self, self:IsMouseOver() and "hover" or "normal") end end)

    function button:SetEnabledState(enabled)
        self.__enabled = enabled and true or false
        self:EnableMouse(self.__enabled)
        palette(self, "normal")
    end

    function button:SetButtonText(value)
        self.__title:SetText(value or "")
    end

    palette(button, "normal")
    return button
end

function ns.UI_CreateToggle(parent, labelText, initial, width, height)
    local button = CreateFrame("Button", nil, parent)
    button:SetSize(width or 240, height or 28)
    button:RegisterForClicks("LeftButtonUp")

    local box = button:CreateTexture(nil, "BACKGROUND")
    box:SetPoint("LEFT", 0, 0)
    box:SetSize(M.checkboxSize, M.checkboxSize)
    T.SetColorTexture(box, C.button)

    local top, bottom, left, right = addFrameBorder(button, box, C.borderSoft)

    local mark = button:CreateTexture(nil, "ARTWORK")
    mark:SetPoint("CENTER", box, "CENTER")
    mark:SetSize(10, 10)
    T.SetColorTexture(mark, C.accent)

    local markInner = button:CreateTexture(nil, "OVERLAY")
    markInner:SetPoint("CENTER", box, "CENTER")
    markInner:SetSize(5, 5)
    T.SetColorTexture(markInner, C.accentBright)

    local label = button:CreateFontString(nil, "OVERLAY", T.fonts.body)
    label:SetPoint("TOPLEFT", box, "TOPRIGHT", 8, 5)
    label:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -2, 1)
    label:SetJustifyH("LEFT")
    label:SetJustifyV("MIDDLE")
    label:SetWordWrap(true)
    label:SetText(labelText or "")
    colorText(label, C.text)

    button.__enabled = true
    button.__checked = initial and true or false
    button.__box = box
    button.__mark = mark
    button.__markInner = markInner
    button.__label = label
    button.__top = top
    button.__bottom = bottom
    button.__left = left
    button.__right = right

    function button:SetChecked(value)
        self.__checked = value and true or false
        self.__mark:SetShown(self.__checked)
        self.__markInner:SetShown(self.__checked)
        local borderColor = self.__checked and C.borderBright or C.borderSoft
        T.SetColorTexture(self.__top, borderColor)
        T.SetColorTexture(self.__bottom, borderColor)
        T.SetColorTexture(self.__left, borderColor)
        T.SetColorTexture(self.__right, borderColor)
    end

    function button:SetEnabledState(enabled)
        self.__enabled = enabled and true or false
        self:EnableMouse(self.__enabled)
        self:SetAlpha(self.__enabled and 1 or 0.5)
    end

    function button:GetChecked()
        return self.__checked
    end

    button:SetScript("OnEnter", function(self)
        if not self.__enabled then return end
        T.SetColorTexture(self.__box, C.buttonHover)
        colorText(self.__label, C.accentBright)
    end)
    button:SetScript("OnLeave", function(self)
        T.SetColorTexture(self.__box, C.button)
        colorText(self.__label, C.text)
    end)
    button:SetScript("OnClick", function(self)
        if not self.__enabled then return end
        self:SetChecked(not self:GetChecked())
        if self.OnValueChanged then self:OnValueChanged(self:GetChecked()) end
    end)

    button:SetChecked(button.__checked)
    return button
end

function ns.UI_CreateStatusPill(parent)
    local frame = CreateFrame("Frame", nil, parent)
    frame:SetSize(156, 25)

    local bg = frame:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    T.SetColorTexture(bg, C.panelRaised)
    addFrameBorder(frame, bg, C.borderSoft)

    local dotBack = frame:CreateTexture(nil, "ARTWORK")
    dotBack:SetSize(10, 10)
    dotBack:SetPoint("LEFT", 10, 0)
    T.SetColorTexture(dotBack, C.borderSoft)

    local dot = frame:CreateTexture(nil, "OVERLAY")
    dot:SetSize(6, 6)
    dot:SetPoint("CENTER", dotBack, "CENTER")

    local text = frame:CreateFontString(nil, "OVERLAY", T.fonts.status)
    text:SetPoint("LEFT", dotBack, "RIGHT", 7, 0)
    text:SetPoint("RIGHT", -8, 0)
    text:SetJustifyH("LEFT")

    frame.__dot = dot
    frame.__dotBack = dotBack
    frame.__text = text

    function frame:SetStatus(label, kind)
        local color = C.accent
        if kind == "success" then color = C.success
        elseif kind == "warning" then color = C.warning
        elseif kind == "danger" then color = C.danger end
        T.SetColorTexture(self.__dotBack, C.borderSoft)
        T.SetColorTexture(self.__dot, color)
        self.__text:SetText(label or "")
        colorText(self.__text, color)
    end

    return frame
end

-- Header and row cells use the same viewport width and column geometry.
-- Keeping these anchors shared avoids compensating for the scrollbar by pixels.
local snapshotWidth, versionWidth, rightInset, columnGap = 98, 58, 4, 2
ns.UI_AddonColumnInset = rightInset + versionWidth + columnGap + snapshotWidth + columnGap
function ns.UI_AnchorAddonColumns(parent, snapshot, version)
    snapshot:SetWidth(snapshotWidth)
    snapshot:SetPoint("RIGHT", parent, "RIGHT", -(rightInset + versionWidth + columnGap), 0)
    snapshot:SetJustifyH("LEFT")
    snapshot:SetWordWrap(false)
    version:SetWidth(versionWidth)
    version:SetPoint("RIGHT", parent, "RIGHT", -rightInset, 0)
    version:SetJustifyH("RIGHT")
end

function ns.UI_CreateAddonRow(parent)
    local row = CreateFrame("Frame", nil, parent)
    row:SetHeight(M.rowHeight)

    local bg = row:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    T.SetColorTexture(bg, C.row)

    local divider = row:CreateTexture(nil, "BORDER")
    divider:SetPoint("BOTTOMLEFT")
    divider:SetPoint("BOTTOMRIGHT")
    divider:SetHeight(1)
    T.SetColorTexture(divider, C.borderSoft)

    row.toggle = ns.UI_CreateToggle(row, "", true, 180, M.rowHeight)
    row.toggle:SetPoint("LEFT", 4, 0)
    row.toggle:SetPoint("RIGHT", row, "RIGHT", -ns.UI_AddonColumnInset, 0)

    row.status = ns.UI_CreateLabel(row, "", true, T.fonts.bodySmall)

    row.version = ns.UI_CreateLabel(row, "", true, T.fonts.bodySmall)
    ns.UI_AnchorAddonColumns(row, row.status, row.version)

    row.__bg = bg

    function row:SetAlternate(alternate)
        T.SetColorTexture(self.__bg, alternate and C.rowAlt or C.row)
        self.__alternate = alternate and true or false
    end

    row:SetScript("OnEnter", function(self)
        T.SetColorTexture(self.__bg, C.rowHover)
    end)
    row:SetScript("OnLeave", function(self)
        T.SetColorTexture(self.__bg, self.__alternate and C.rowAlt or C.row)
    end)

    return row
end

function ns.UI_CreateScroll(parent)
    local holder = CreateFrame("Frame", nil, parent)
    local railWidth = M.scrollbarWidth

    local scroll = CreateFrame("ScrollFrame", nil, holder)
    scroll:SetPoint("TOPLEFT")
    scroll:SetPoint("BOTTOMRIGHT", -(railWidth + 8), 0)

    local child = CreateFrame("Frame", nil, scroll)
    child:SetWidth(1)
    child:SetHeight(1)
    scroll:SetScrollChild(child)

    local track = holder:CreateTexture(nil, "BACKGROUND")
    track:SetPoint("TOPRIGHT", -2, -2)
    track:SetPoint("BOTTOMRIGHT", -2, 2)
    track:SetWidth(railWidth)
    T.SetColorTexture(track, C.scrollTrack)

    local trackEdge = holder:CreateTexture(nil, "BORDER")
    trackEdge:SetPoint("TOPLEFT", track, "TOPLEFT")
    trackEdge:SetPoint("BOTTOMLEFT", track, "BOTTOMLEFT")
    trackEdge:SetWidth(1)
    T.SetColorTexture(trackEdge, C.borderSoft)

    local thumb = CreateFrame("Button", nil, holder)
    thumb:SetWidth(railWidth)
    thumb:SetHeight(40)
    local thumbTex = thumb:CreateTexture(nil, "ARTWORK")
    thumbTex:SetAllPoints()
    T.SetColorTexture(thumbTex, C.scrollThumb)
    thumb.__tex = thumbTex

    local dragging = false
    local dragOffset = 0

    local function updateThumb()
        local range = scroll:GetVerticalScrollRange() or 0
        local visible = scroll:GetHeight() or 1
        local content = visible + range
        local trackHeight = holder:GetHeight() - 4
        if range <= 0 or content <= 0 or trackHeight <= 0 then
            thumb:Hide()
            return
        end
        thumb:Show()
        local thumbHeight = math.max(28, math.min(trackHeight, trackHeight * (visible / content)))
        thumb:SetHeight(thumbHeight)
        local maxTravel = trackHeight - thumbHeight
        local ratio = range > 0 and (scroll:GetVerticalScroll() / range) or 0
        thumb:ClearAllPoints()
        thumb:SetPoint("TOPRIGHT", holder, "TOPRIGHT", -2, -2 - (maxTravel * ratio))
    end

    local function setFromCursor()
        local _, cursorY = GetCursorPosition()
        local scale = holder:GetEffectiveScale()
        cursorY = cursorY / scale
        local top = holder:GetTop() or 0
        local trackHeight = holder:GetHeight() - 4
        local thumbHeight = thumb:GetHeight()
        local maxTravel = math.max(1, trackHeight - thumbHeight)
        local y = math.max(0, math.min(maxTravel, (top - cursorY) - dragOffset - 2))
        local range = scroll:GetVerticalScrollRange() or 0
        scroll:SetVerticalScroll((y / maxTravel) * range)
        updateThumb()
    end

    thumb:RegisterForDrag("LeftButton")
    thumb:SetScript("OnDragStart", function(self)
        dragging = true
        local _, cursorY = GetCursorPosition()
        cursorY = cursorY / holder:GetEffectiveScale()
        dragOffset = (holder:GetTop() or 0) - cursorY - math.abs(select(5, self:GetPoint(1)) or 0)
        self:SetScript("OnUpdate", setFromCursor)
        T.SetColorTexture(self.__tex, C.scrollThumbHover)
    end)
    thumb:SetScript("OnDragStop", function(self)
        dragging = false
        self:SetScript("OnUpdate", nil)
        T.SetColorTexture(self.__tex, C.scrollThumb)
        updateThumb()
    end)
    thumb:SetScript("OnEnter", function(self)
        if not dragging then T.SetColorTexture(self.__tex, C.scrollThumbHover) end
    end)
    thumb:SetScript("OnLeave", function(self)
        if not dragging then T.SetColorTexture(self.__tex, C.scrollThumb) end
    end)

    scroll:EnableMouseWheel(true)
    scroll:SetScript("OnMouseWheel", function(self, delta)
        local step = M.rowHeight * 2
        local range = self:GetVerticalScrollRange() or 0
        self:SetVerticalScroll(math.max(0, math.min(range, self:GetVerticalScroll() - (delta * step))))
        updateThumb()
    end)
    scroll:SetScript("OnScrollRangeChanged", updateThumb)
    holder:SetScript("OnSizeChanged", function()
        child:SetWidth(math.max(1, scroll:GetWidth()))
        updateThumb()
    end)

    holder.scroll = scroll
    holder.child = child
    holder.UpdateThumb = updateThumb
    return holder
end
