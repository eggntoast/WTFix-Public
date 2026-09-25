local _, ns = ...

local LibStub = _G.LibStub
if not LibStub then return end
local LDB = LibStub("LibDataBroker-1.1", true)
local DBIcon = LibStub("LibDBIcon-1.0", true)
if not LDB or not DBIcon then return end

local iconPath = ns.media .. "Icon"
local broker = LDB:NewDataObject("WTFix", {
    type = "launcher",
    text = "WTFix",
    icon = iconPath,
})

local function tooltipColor(kind)
    local colors = ns.Theme and ns.Theme.colors or nil
    if colors then
        if kind == "success" then return colors.success[1], colors.success[2], colors.success[3] end
        if kind == "warning" then return colors.warning[1], colors.warning[2], colors.warning[3] end
        if kind == "danger" then return colors.danger[1], colors.danger[2], colors.danger[3] end
        return colors.accentBright[1], colors.accentBright[2], colors.accentBright[3]
    end
    if kind == "success" then return 0.31, 0.88, 0.54 end
    if kind == "warning" then return 0.98, 0.72, 0.22 end
    if kind == "danger" then return 0.91, 0.34, 0.34 end
    return 0.44, 0.91, 1.00
end

broker.OnClick = function(_, button)
    if button == "LeftButton" then
        ns.SettingsCompat.Toggle()
    elseif button == "RightButton" then
        ns.PrintStatus()
    end
end

broker.OnTooltipShow = function(tooltip)
    local presentation = ns.GetStatusPresentation(true)
    local view = ns.GetRecoveryView(false)
    local summary = view.summary
    tooltip:AddLine("WTFix", 0.4, 0.85, 1)
    local r, g, b = tooltipColor(view.kind)
    tooltip:AddLine(view.status, r, g, b)
    tooltip:AddLine(view.explanation or "", 0.70, 0.76, 0.82, true)
    tooltip:AddLine("Last saved: " .. view.saved, 0.62, 0.69, 0.76)
    tooltip:AddLine("Recovery source: " .. view.source, 0.62, 0.69, 0.76)
    if (summary.unloadedAddonCount or 0) > 0 then
        tooltip:AddLine("Not loaded: " .. summary.unloadedAddonCount .. " protected addons", 0.62, 0.69, 0.76)
    end

    local warningDetails = presentation and presentation.warningDetails or summary.warningDetails
    if type(warningDetails) == "table" and #warningDetails > 0 then
        tooltip:AddLine(" ")
        local shown = math.min(2, #warningDetails)
        for index = 1, shown do
            tooltip:AddLine(warningDetails[index], 0.95, 0.72, 0.28, true)
        end
        if #warningDetails > shown then
            tooltip:AddLine("+" .. tostring(#warningDetails - shown) .. " more", 0.62, 0.69, 0.76)
        end
    end

    tooltip:AddLine(" ")
    tooltip:AddLine("Left-click: Open settings", 0.7, 0.75, 0.8)
    tooltip:AddLine("Right-click: Status", 0.7, 0.75, 0.8)
end

DBIcon:Register("WTFix", broker, WTFIX_DB.minimap)
ns.Broker = { object = broker, icon = DBIcon }

function ns.SetMinimapVisible(visible)
    WTFIX_DB.minimap.hide = not visible
    if visible then DBIcon:Show("WTFix") else DBIcon:Hide("WTFix") end
end
