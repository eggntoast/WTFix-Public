local _, ns = ...

local T = ns.Theme
local C = T.colors
local M = T.metrics

local panel = CreateFrame("Frame", "WTFixSettingsPanel", UIParent)
panel:SetSize(660, 600)
panel:Hide()

local base = panel:CreateTexture(nil, "BACKGROUND")
base:SetAllPoints()
base:SetColorTexture(C.background[1], C.background[2], C.background[3], C.background[4])

local root = CreateFrame("Frame", nil, panel)
root:SetPoint("TOPLEFT", M.outerInset, -14)
root:SetPoint("BOTTOMRIGHT", -M.outerInset, 14)

local header = CreateFrame("Frame", nil, root)
header:SetPoint("TOPLEFT")
header:SetPoint("TOPRIGHT")
header:SetHeight(M.headerHeight)

local logo = header:CreateTexture(nil, "ARTWORK")
logo:SetTexture(ns.media .. "Logo")
logo:SetSize(72, 72)
logo:SetPoint("LEFT", 0, 2)

local wordmark = header:CreateTexture(nil, "ARTWORK")
wordmark:SetTexture(ns.media .. "Wordmark")
wordmark:SetSize(218, 55)
wordmark:SetPoint("TOPLEFT", logo, "TOPRIGHT", 8, -4)

local subtitle = ns.UI_CreateLabel(header, "SavedVariables recovery", true, T.fonts.bodySmall)
subtitle:SetPoint("TOPLEFT", wordmark, "BOTTOMLEFT", 2, 2)
subtitle:SetPoint("RIGHT", header, "RIGHT", -190, 0)

local versionMeta = ns.UI_CreateLabel(header, "WTFix " .. ns.version .. "  ·  NS", true, T.fonts.bodySmall)
versionMeta:SetPoint("TOPRIGHT", 0, -12)
versionMeta:SetWidth(170)
versionMeta:SetJustifyH("RIGHT")

local statePill = ns.UI_CreateStatusPill(header)
local headerAction = ns.UI_CreateButton(header, "Details", 130, "secondary")
headerAction:SetHeight(28)
headerAction:SetScript("OnClick", function() ns.RunRecoveryAction() end)
local function layoutHeader()
    statePill:ClearAllPoints(); headerAction:ClearAllPoints()
    -- Keep the brand and action distinct on the narrower Settings layouts.
    if header:GetWidth() < 610 then
        statePill:SetPoint("TOPRIGHT", 0, -36)
        headerAction:SetPoint("TOPRIGHT", 0, -67)
        header:SetHeight(math.max(M.headerHeight, 106))
    else
        headerAction:SetPoint("TOPRIGHT", 0, -35)
        statePill:SetPoint("RIGHT", headerAction, "LEFT", -8, 0)
        header:SetHeight(M.headerHeight)
    end
end
header:SetScript("OnSizeChanged", layoutHeader)
layoutHeader()

local headerLine = header:CreateTexture(nil, "BORDER")
headerLine:SetPoint("BOTTOMLEFT")
headerLine:SetPoint("BOTTOMRIGHT")
headerLine:SetHeight(1)
T.SetColorTexture(headerLine, C.border)

local tabBar = CreateFrame("Frame", nil, root)
tabBar:SetPoint("TOPLEFT", header, "BOTTOMLEFT", 0, -M.gap)
tabBar:SetPoint("TOPRIGHT", header, "BOTTOMRIGHT", 0, -M.gap)
tabBar:SetHeight(30)

local content = CreateFrame("Frame", nil, root)
content:SetPoint("TOPLEFT", tabBar, "BOTTOMLEFT", 0, -M.gap)
content:SetPoint("BOTTOMRIGHT", root, "BOTTOMRIGHT")
local recoveryPage = CreateFrame("Frame", nil, content)
recoveryPage:SetAllPoints()
local aboutPage = ns.UI_CreateAboutPage(content)
aboutPage:SetAllPoints()

local recoveryTab = ns.UI_CreateButton(tabBar, "Recovery", 116, "secondary")
recoveryTab:SetPoint("TOPLEFT")
recoveryTab:SetHeight(30)
local aboutTab = ns.UI_CreateButton(tabBar, "About", 92, "secondary")
aboutTab:SetPoint("LEFT", recoveryTab, "RIGHT", 8, 0)
aboutTab:SetHeight(30)
local function indicator(button)
    local line = button:CreateTexture(nil, "OVERLAY")
    line:SetPoint("BOTTOMLEFT", 1, 0)
    line:SetPoint("BOTTOMRIGHT", -1, 0)
    line:SetHeight(2)
    T.SetColorTexture(line, C.accent)
    return line
end
local recoveryIndicator, aboutIndicator = indicator(recoveryTab), indicator(aboutTab)
function panel:SelectTab(name)
    local about = name == "About"
    self.selectedTab = about and "About" or "Recovery"
    recoveryPage:SetShown(not about)
    aboutPage:SetShown(about)
    recoveryIndicator:SetShown(not about)
    aboutIndicator:SetShown(about)
end
recoveryTab:SetScript("OnClick", function() panel:SelectTab("Recovery") end)
aboutTab:SetScript("OnClick", function() panel:SelectTab("About") end)
panel:SelectTab("Recovery")

local rightWidth = 232
local topHeight = 156

local statusCard = ns.UI_CreateCard(recoveryPage, topHeight, false, false)
statusCard:SetPoint("TOPLEFT")
statusCard:SetPoint("RIGHT", recoveryPage, "RIGHT", -(rightWidth + M.gap), 0)

local statusTitle = ns.UI_CreateSectionTitle(statusCard, "Status")
statusTitle:SetPoint("TOPLEFT", 16, -14)

local statusLabels, statusTitles = {}, {}
local function addStatusRow(key, titleText, y)
    local left = ns.UI_CreateLabel(statusCard, titleText, true, T.fonts.bodySmall)
    left:SetPoint("TOPLEFT", 16, y)
    left:SetWidth(126)

    local right = ns.UI_CreateLabel(statusCard, "", false, T.fonts.bodySmall)
    right:SetPoint("TOPLEFT", 146, y)
    right:SetPoint("RIGHT", -14, 0)
    right:SetJustifyH("LEFT")
    statusLabels[key], statusTitles[key] = right, left
end

addStatusRow("addons", "Protected addons", -40)
addStatusRow("source", "Recovery source", -61)
addStatusRow("saved", "Last saved", -82)
addStatusRow("character", "Character link", -103)
addStatusRow("cold", "Cold-start recovery", -124)

local actionCard = ns.UI_CreateCard(recoveryPage, topHeight, true, true)
actionCard:SetPoint("TOPLEFT", statusCard, "TOPRIGHT", M.gap, 0)
actionCard:SetPoint("TOPRIGHT", recoveryPage, "TOPRIGHT", 0, 0)

local actionTitle = ns.UI_CreateSectionTitle(actionCard, "Recovery Snapshot")
actionTitle:SetPoint("TOPLEFT", 14, -14)

local saveButton = ns.UI_CreateActionButton(
    actionCard,
    "Save Current Settings",
    "Capture the setup you trust, then reload securely.",
    "primary"
)
saveButton:SetPoint("TOPLEFT", 12, -38)
saveButton:SetPoint("TOPRIGHT", -12, -38)

local restoreButton = ns.UI_CreateActionButton(
    actionCard,
    "Restore Saved Settings",
    "Prepare the protected snapshot for the next reload.",
    "secondary"
)
restoreButton:SetPoint("TOPLEFT", saveButton, "BOTTOMLEFT", 0, -8)
restoreButton:SetPoint("TOPRIGHT", saveButton, "BOTTOMRIGHT", 0, -8)

local detailsCard = ns.UI_CreateCard(recoveryPage, nil, false, false)
detailsCard:SetPoint("TOPLEFT", statusCard, "BOTTOMLEFT", 0, -M.gap)
detailsCard:SetPoint("BOTTOMRIGHT", recoveryPage, "BOTTOMRIGHT", -(rightWidth + M.gap), 0)

local detailsTitle = ns.UI_CreateSectionTitle(detailsCard, "Protected Addons")
detailsTitle:SetPoint("TOPLEFT", 16, -14)

local detailsSub = ns.UI_CreateLabel(
    detailsCard,
    "Saved means a checkpoint exists. Not loaded addons are not captured; existing data is retained. /wtfix diff compares live settings.",
    true,
    T.fonts.bodySmall
)
detailsSub:SetPoint("TOPLEFT", 16, -38)
detailsSub:SetPoint("RIGHT", -16, 0)
detailsSub:SetHeight(32)
detailsSub:SetJustifyV("TOP")
detailsSub:SetWordWrap(true)

local rowsScroll = ns.UI_CreateScroll(detailsCard)
rowsScroll:SetPoint("TOPLEFT", 16, -96)
rowsScroll:SetPoint("BOTTOMRIGHT", -12, 14)
local rowsFrame = rowsScroll.child

local columnHeader = CreateFrame("Frame", nil, detailsCard)
-- Match the visible row viewport, excluding the scrollbar rail and its gap.
columnHeader:SetPoint("TOPLEFT", rowsScroll.scroll, "TOPLEFT", 0, 20)
columnHeader:SetPoint("TOPRIGHT", rowsScroll.scroll, "TOPRIGHT", 0, 20)
columnHeader:SetHeight(18)

local addonHeader = ns.UI_CreateLabel(columnHeader, "ADDON", true, T.fonts.tiny)
addonHeader:SetPoint("LEFT", 5, 0)
addonHeader:SetPoint("RIGHT", columnHeader, "RIGHT", -ns.UI_AddonColumnInset, 0)

local statusHeader = ns.UI_CreateLabel(columnHeader, "SNAPSHOT", true, T.fonts.tiny)

local versionHeader = ns.UI_CreateLabel(columnHeader, "VERSION", true, T.fonts.tiny)
ns.UI_AnchorAddonColumns(columnHeader, statusHeader, versionHeader)

local detailRows = {}

local optionsCard = ns.UI_CreateCard(recoveryPage, 132, true, false)
optionsCard:SetPoint("TOPLEFT", actionCard, "BOTTOMLEFT", 0, -M.gap)
optionsCard:SetPoint("TOPRIGHT", recoveryPage, "TOPRIGHT", 0, -(topHeight + M.gap))

local optionsTitle = ns.UI_CreateSectionTitle(optionsCard, "Options")
optionsTitle:SetPoint("TOPLEFT", 14, -14)

local minimapToggle = ns.UI_CreateToggle(optionsCard, "Show minimap button", not WTFIX_DB.minimap.hide, 204, 28)
minimapToggle:SetPoint("TOPLEFT", 14, -37)

local chatToggle = ns.UI_CreateToggle(
    optionsCard,
    "Show one recovery message on login / reload",
    WTFIX_DB.chatStatus ~= false,
    204,
    44
)
chatToggle:SetPoint("TOPLEFT", minimapToggle, "BOTTOMLEFT", 0, -5)

local statusTextForAddon = ns.GetAddonSnapshotStatus

local function colorForKind(kind)
    if kind == "success" then return C.success end
    if kind == "warning" then return C.warning end
    if kind == "danger" then return C.danger end
    return C.muted
end

local function clearRows()
    for _, row in ipairs(detailRows) do row:Hide() end
end

local function refreshRows()
    clearRows()
    local snapshot = ns.GetAuthoritativeSnapshot()
    local characterKey = ns.GetCharacterKey()
    local addons = {}
    for addon in pairs(ns.GetTargets()) do addons[#addons + 1] = addon end
    table.sort(addons)

    local y = 0
    for index, addon in ipairs(addons) do
        local addonName = addon
        local row = detailRows[index]
        if not row then
            row = ns.UI_CreateAddonRow(rowsFrame)
            detailRows[index] = row
        end

        row:ClearAllPoints()
        row:SetPoint("TOPLEFT", 0, -y)
        row:SetPoint("TOPRIGHT", 0, -y)
        row:Show()
        row:SetAlternate(index % 2 == 0)
        row.toggle:SetChecked(ns.IsProtectedAddon(addonName))
        row.toggle:SetEnabledState(ns.CanSave())
        if row.toggle.__label then row.toggle.__label:SetText(addonName) end

        row.toggle.OnValueChanged = function(self, checked)
            if not ns.CanSave() then return end
            if checked then
                WTFIX_DB.protectedAddons[addonName] = nil
            else
                WTFIX_DB.protectedAddons[addonName] = false
            end
            if panel.Refresh then panel:Refresh(false) end
        end

        local textValue, kind = statusTextForAddon(addonName, ns.GetTargets()[addonName], snapshot, characterKey)
        if not ns.CanSave() then textValue, kind = "Not checked", "muted" end
        row.status:SetText(textValue)
        local color = colorForKind(kind)
        row.status:SetTextColor(color[1], color[2], color[3], color[4] or 1)

        local version = ns.GetAddonVersion(addonName)
        if version then
            version = tostring(version)
            if string.lower(string.sub(version, 1, 1)) ~= "v" then version = "v" .. version end
        end
        row.version:SetText(version or "—")

        y = y + M.rowHeight
    end

    rowsFrame:SetHeight(math.max(1, y))
    rowsScroll.UpdateThumb()
end

local function updateStatus(checkLive)
    local view = ns.GetRecoveryView(checkLive)
    statePill:SetStatus(view.status, view.kind)
    headerAction:SetButtonText(view.actionLabel)
    statusTitles.addons:SetText(view.countLabel)
    statusLabels.addons:SetText(view.count)
    statusLabels.source:SetText(view.source)
    statusLabels.saved:SetText(view.saved)
    statusLabels.character:SetText(view.link)
    statusLabels.cold:SetText(view.cold)
    local color = colorForKind(view.kind)
    statusLabels.character:SetTextColor(color[1], color[2], color[3], 1)
    statusLabels.cold:SetTextColor(color[1], color[2], color[3], 1)
    saveButton:SetEnabledState(ns.CanSave())
    restoreButton:SetEnabledState(ns.CanRestore())
    minimapToggle:SetEnabledState(view.editable)
    chatToggle:SetEnabledState(view.editable)
    detailsSub:SetText(view.explanation or "Saved means a checkpoint exists. Details shows recovery information.")
    local textHeight = math.max(32, detailsSub:GetStringHeight())
    detailsSub:SetHeight(textHeight)
    rowsScroll:ClearAllPoints()
    rowsScroll:SetPoint("TOPLEFT", 16, -(64 + textHeight))
    rowsScroll:SetPoint("BOTTOMRIGHT", -12, 14)
    if view.editable and not checkLive and C_Timer and C_Timer.After then
        C_Timer.After(0, function() if panel:IsShown() then panel:Refresh(true) end end)
    end

    minimapToggle:SetChecked(not WTFIX_DB.minimap.hide)
    chatToggle:SetChecked(WTFIX_DB.chatStatus ~= false)
    refreshRows()
end

function panel:Refresh(checkLive)
    updateStatus(checkLive == true)
    rowsScroll.UpdateThumb()
end

local function inCombat()
    return InCombatLockdown and InCombatLockdown()
end

local function blockCombat(action)
    if not inCombat() then return false end
    ns.Print(action .. " is unavailable during combat. Try again after combat.")
    return true
end

local function showPendingReload()
    if not ns.pendingReload then return false end
    if blockCombat("Reload") then return true end
    ns.ShowReloadRequired(ns.pendingReload)
    return true
end

saveButton:SetScript("OnClick", function()
    if showPendingReload() then return end
    if blockCombat("Save") then return end
    if not ns.CanSave() then
        ns.Print(ns.GetPreparationState().reason)
        return
    end

    ns.ShowConfirm(
        "Save Current Settings?",
        "WTFix will replace your protected recovery snapshot with your current addon settings. After the snapshot is captured, use the secure Reload Now button so WoW writes it to disk.",
        "Save Snapshot",
        function()
            if blockCombat("Save") then
                saveButton:SetEnabledState(true)
                return
            end

            saveButton:SetEnabledState(false)
            local ok, result, err = ns.SaveCurrentSettings()
            saveButton:SetEnabledState(true)
            if not ok then
                ns.Print("Save failed: " .. tostring(err or "unknown error"))
                if result and ns.PrintCaptureFailures then ns.PrintCaptureFailures(result.failures) end
                ns.Print("The previous checkpoint was retained. Use /wtfix check for capture and missing-variable details.")
                return
            end

            ns.pendingReload = "save"
            panel:Refresh(true)
            ns.Print("Snapshot captured. Reload required to write it to disk.")
            if result and result.omissions and result.omissions.count > 0 then
                ns.Print(tostring(result.omissions.count) .. " nonpersistent fields omitted. Settings data captured; /wtfix check shows details.")
            end
            ns.ShowReloadRequired("save")
        end
    )
end)

restoreButton:SetScript("OnClick", function()
    if showPendingReload() then return end
    if not ns.CanRestore() then return end
    if blockCombat("Restore") then return end

    local summary = ns.GetStatusSummary()
    ns.ShowConfirm(
        "Restore Saved Settings?",
        "Your current unsaved addon changes will be discarded on reload. WTFix will apply the protected snapshot saved:\n" .. tostring(summary.lastSaved),
        "Prepare Restore",
        function()
            if blockCombat("Restore") then return end
            local ok, reason = ns.PrepareRestore()
            if not ok then ns.Print(reason); return end
            panel:Refresh(true)
            ns.Print("Restore prepared. Reload required to apply the protected snapshot.")
            ns.ShowReloadRequired("restore")
        end
    )
end)

minimapToggle.OnValueChanged = function(_, checked)
    if not ns.CanSave() then return end
    if ns.SetMinimapVisible then
        ns.SetMinimapVisible(checked)
    else
        WTFIX_DB.minimap.hide = not checked
    end
end

chatToggle.OnValueChanged = function(_, checked)
    if not ns.CanSave() then return end
    WTFIX_DB.chatStatus = checked and true or false
end

panel:SetScript("OnShow", function(self)
    self:Refresh(false)
end)

ns.settingsLabel = "|T" .. ns.media .. "Icon:16:16:0:0|t " .. ns.brandTitle
ns.SettingsCompat.Register(panel, ns.settingsLabel)
ns.Panel = panel
