local _, ns = ...

ns.Theme = {
    colors = {
        background = {0.018, 0.027, 0.038, 0.99},
        panel = {0.033, 0.050, 0.067, 0.99},
        panelAlt = {0.042, 0.064, 0.084, 0.99},
        panelRaised = {0.052, 0.080, 0.104, 0.99},
        row = {0.040, 0.058, 0.074, 0.72},
        rowAlt = {0.050, 0.071, 0.090, 0.80},
        rowHover = {0.060, 0.105, 0.135, 0.90},
        border = {0.09, 0.35, 0.50, 0.95},
        borderBright = {0.13, 0.67, 0.86, 1.00},
        borderSoft = {0.09, 0.19, 0.26, 0.92},
        accent = {0.07, 0.72, 0.95, 1.00},
        accentBright = {0.44, 0.91, 1.00, 1.00},
        accentDim = {0.04, 0.34, 0.48, 1.00},
        text = {0.91, 0.95, 0.98, 1.00},
        muted = {0.58, 0.66, 0.74, 1.00},
        dim = {0.40, 0.48, 0.55, 1.00},
        success = {0.31, 0.88, 0.54, 1.00},
        warning = {0.98, 0.72, 0.22, 1.00},
        danger = {0.91, 0.34, 0.34, 1.00},
        button = {0.045, 0.085, 0.115, 1.00},
        buttonHover = {0.055, 0.135, 0.185, 1.00},
        buttonDown = {0.030, 0.090, 0.125, 1.00},
        buttonDisabled = {0.095, 0.115, 0.135, 1.00},
        disabled = {0.095, 0.115, 0.135, 1.00},
        scrollTrack = {0.025, 0.045, 0.060, 0.78},
        scrollThumb = {0.08, 0.38, 0.53, 0.95},
        scrollThumbHover = {0.08, 0.70, 0.91, 1.00},
    },
    metrics = {
        padding = 16,
        outerInset = 18,
        gap = 12,
        sectionGap = 12,
        headerHeight = 82,
        buttonHeight = 32,
        actionButtonHeight = 50,
        rowHeight = 28,
        checkboxSize = 18,
        scrollbarWidth = 6,
    },
    fonts = {
        brand = "GameFontNormalLarge",
        section = "GameFontNormal",
        body = "GameFontHighlight",
        bodySmall = "GameFontHighlightSmall",
        status = "GameFontNormalSmall",
        tiny = "GameFontHighlightSmall",
    },
}

local function setColorTexture(texture, color)
    texture:SetColorTexture(color[1], color[2], color[3], color[4] or 1)
end

function ns.Theme.SetColorTexture(texture, color)
    setColorTexture(texture, color)
end

local function addEdge(frame, pointA, pointB, horizontal, color, inset)
    local edge = frame:CreateTexture(nil, "BORDER")
    inset = inset or 0
    if horizontal then
        edge:SetPoint(pointA, frame, pointA, inset, 0)
        edge:SetPoint(pointB, frame, pointB, -inset, 0)
        edge:SetHeight(1)
    else
        edge:SetPoint(pointA, frame, pointA, 0, -inset)
        edge:SetPoint(pointB, frame, pointB, 0, inset)
        edge:SetWidth(1)
    end
    setColorTexture(edge, color)
    return edge
end

function ns.Theme.AddPanelSkin(frame, alt, raised)
    local c = ns.Theme.colors
    local bg = frame:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    if raised then
        setColorTexture(bg, c.panelRaised)
    else
        setColorTexture(bg, alt and c.panelAlt or c.panel)
    end
    frame.__wtfixBackground = bg

    local shadow = frame:CreateTexture(nil, "BACKGROUND", nil, -1)
    shadow:SetPoint("TOPLEFT", frame, "TOPLEFT", 3, -3)
    shadow:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 3, -3)
    shadow:SetColorTexture(0, 0, 0, 0.34)
    frame.__wtfixShadow = shadow

    frame.__wtfixTop = addEdge(frame, "TOPLEFT", "TOPRIGHT", true, c.border, 0)
    frame.__wtfixBottom = addEdge(frame, "BOTTOMLEFT", "BOTTOMRIGHT", true, c.borderSoft, 0)
    frame.__wtfixLeft = addEdge(frame, "TOPLEFT", "BOTTOMLEFT", false, c.borderSoft, 0)
    frame.__wtfixRight = addEdge(frame, "TOPRIGHT", "BOTTOMRIGHT", false, c.borderSoft, 0)

    local inner = frame:CreateTexture(nil, "BORDER")
    inner:SetPoint("TOPLEFT", 1, -1)
    inner:SetPoint("TOPRIGHT", -1, -1)
    inner:SetHeight(1)
    setColorTexture(inner, c.accentDim)
    frame.__wtfixInnerTop = inner
end

function ns.Theme.AddSectionDivider(frame, y)
    local line = frame:CreateTexture(nil, "ARTWORK")
    line:SetPoint("TOPLEFT", frame, "TOPLEFT", 16, y)
    line:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -16, y)
    line:SetHeight(1)
    setColorTexture(line, ns.Theme.colors.borderSoft)
    return line
end
