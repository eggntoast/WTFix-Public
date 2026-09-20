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

local versionMeta = ns.UI_CreateLabel(header, "WTFix " .. ns.version .. "  |  NS", true, T.fonts.bodySmall)
versionMeta:SetPoint("TOPRIGHT", 0, -12)
versionMeta:SetWidth(170)
versionMeta:SetJustifyH("RIGHT")

local statePill = ns.UI_CreateStatusPill(header)
statePill:SetPoint("TOPRIGHT", 0, -36)

local headerDetail = ns.UI_CreateLabel(header, "", true, T.fonts.tiny)
headerDetail:SetPoint("RIGHT", statePill, "LEFT", -10, 0)
headerDetail:SetWidth(150)
headerDetail:SetJustifyH("RIGHT")

local headerLine = header:CreateTexture(nil, "BORDER")
headerLine:SetPoint("BOTTOMLEFT")
headerLine:SetPoint("BOTTOMRIGHT")
headerLine:SetHeight(1)
T.SetColorTexture(headerLine, C.border)

local rightWidth = 232
local topHeight = 156

local statusCard = ns.UI_CreateCard(root, topHeight, false, false)
statusCard:SetPoint("TOPLEFT", header, "BOTTOMLEFT", 0, -M.gap)
statusCard:SetPoint("RIGHT", root, "RIGHT", -(rightWidth + M.gap), 0)

local statusTitle = ns.UI_CreateSectionTitle(statusCard, "Status")
statusTitle:SetPoint("TOPLEFT", 16, -14)

local statusLabels = {}
local function addStatusRow(key, titleText, y)
    local left = ns.UI_CreateLabel(statusCard, titleText, true, T.fonts.bodySmall)
    left:SetPoint("TOPLEFT", 16, y)
    left:SetWidth(126)

    local right = ns.UI_CreateLabel(statusCard, "", false, T.fonts.bodySmall)
    right:SetPoint("TOPLEFT", 146, y)
    right:SetPoint("RIGHT", -14, 0)
    right:SetJustifyH("LEFT")
    statusLabels[key] = right
end

addStatusRow("addons", "Protected addons", -40)
addStatusRow("source", "Recovery source", -61)
addStatusRow("saved", "Last saved", -82)
addStatusRow("character", "Current character", -103)
addStatusRow("cold", "Cold-start recovery", -124)

local actionCard = ns.UI_CreateCard(root, topHeight, true, true)
actionCard:SetPoint("TOPLEFT", statusCard, "TOPRIGHT", M.gap, 0)
actionCard:SetPoint("TOPRIGHT", root, "TOPRIGHT", 0, -(M.headerHeight + M.gap))

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

local detailsCard = ns.UI_CreateCard(root, nil, false, false)
detailsCard:SetPoint("TOPLEFT", statusCard, "BOTTOMLEFT", 0, -M.gap)
detailsCard:SetPoint("BOTTOMRIGHT", root, "BOTTOMRIGHT", -(rightWidth + M.gap), 0)

local detailsTitle = ns.UI_CreateSectionTitle(detailsCard, "Protected Addons")
detailsTitle:SetPoint("TOPLEFT", 16, -14)

local detailsSub = ns.UI_CreateLabel(
    detailsCard,
    "Saved means a checkpoint exists, not that live data is identical. Use /wtfix diff to inspect differences.",
    true,
    T.fonts.bodySmall
)
detailsSub:SetPoint("TOPLEFT", 16, -38)
detailsSub:SetPoint("RIGHT", -16, 0)
detailsSub:SetHeight(32)
detailsSub:SetJustifyV("TOP")
detailsSub:SetWordWrap(true)

local columnHeader = CreateFrame("Frame", nil, detailsCard)
columnHeader:SetPoint("TOPLEFT", 16, -76)
columnHeader:SetPoint("TOPRIGHT", -16, -76)
columnHeader:SetHeight(18)

local addonHeader = ns.UI_CreateLabel(columnHeader, "ADDON", true, T.fonts.tiny)
addonHeader:SetPoint("LEFT", 5, 0)
addonHeader:SetPoint("RIGHT", columnHeader, "RIGHT", -164, 0)

local statusHeader = ns.UI_CreateLabel(columnHeader, "SNAPSHOT", true, T.fonts.tiny)
statusHeader:SetWidth(98)
statusHeader:SetPoint("RIGHT", columnHeader, "RIGHT", -64, 0)

local versionHeader = ns.UI_CreateLabel(columnHeader, "VERSION", true, T.fonts.tiny)
versionHeader:SetWidth(58)
versionHeader:SetPoint("RIGHT", -4, 0)
versionHeader:SetJustifyH("RIGHT")

local rowsScroll = ns.UI_CreateScroll(detailsCard)
rowsScroll:SetPoint("TOPLEFT", 16, -96)
rowsScroll:SetPoint("BOTTOMRIGHT", -12, 14)
local rowsFrame = rowsScroll.child

local detailRows = {}

local optionsCard = ns.UI_CreateCard(root, 132, true, false)
optionsCard:SetPoint("TOPLEFT", actionCard, "BOTTOMLEFT", 0, -M.gap)
optionsCard:SetPoint("TOPRIGHT", root, "TOPRIGHT", 0, -(M.headerHeight + topHeight + (M.gap * 2)))

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

local aboutCard = ns.UI_CreateCard(root, nil, false, false)
aboutCard:SetPoint("TOPLEFT", optionsCard, "BOTTOMLEFT", 0, -M.gap)
aboutCard:SetPoint("BOTTOMRIGHT", root, "BOTTOMRIGHT", 0, 0)

local aboutTitle = ns.UI_CreateSectionTitle(aboutCard, "About")
aboutTitle:SetPoint("TOPLEFT", 14, -14)

local aboutVersion = ns.UI_CreateLabel(aboutCard, "WTFix " .. ns.version, false, T.fonts.section)
aboutVersion:SetPoint("TOPLEFT", 14, -40)
aboutVersion:SetPoint("RIGHT", -14, 0)

local aboutSubtitle = ns.UI_CreateLabel(aboutCard, "SavedVariables recovery for WoW Forever", true, T.fonts.bodySmall)
aboutSubtitle:SetPoint("TOPLEFT", aboutVersion, "BOTTOMLEFT", 0, -4)
aboutSubtitle:SetPoint("RIGHT", -14, 0)
aboutSubtitle:SetHeight(30)
aboutSubtitle:SetJustifyV("TOP")
aboutSubtitle:SetWordWrap(true)

local aboutBody = ns.UI_CreateLabel(
    aboutCard,
    "Protect a trusted setup and keep restoring it until you save a new one.",
    true,
    T.fonts.bodySmall
)
aboutBody:SetPoint("TOPLEFT", aboutSubtitle, "BOTTOMLEFT", 0, -8)
aboutBody:SetPoint("RIGHT", -14, 0)
aboutBody:SetHeight(38)
aboutBody:SetJustifyV("TOP")
aboutBody:SetWordWrap(true)

local aboutAuthor = ns.UI_CreateLabel(aboutCard, "by NS", true, T.fonts.tiny)
aboutAuthor:SetPoint("BOTTOMLEFT", 14, 12)

local function statusTextForAddon(addon, target, snapshot, characterKey)
    if not ns.IsProtectedAddon(addon) then
        return "Disabled", "muted"
    end

    local accountRecord = snapshot and snapshot.account and snapshot.account.addons and snapshot.account.addons[addon]
    local charRecord = snapshot and characterKey and snapshot.characters and snapshot.characters[characterKey]
    charRecord = charRecord and charRecord.addons and charRecord.addons[addon]

    local hasAccount = type(target.account) == "table" and #target.account > 0
    local hasCharacter = type(target.character) == "table" and #target.character > 0
    local savedAccount = (not hasAccount) or (accountRecord and type(accountRecord.entries) == "table")
    local savedCharacter = (not hasCharacter) or (charRecord and type(charRecord.entries) == "table")

    if savedAccount and savedCharacter then
        local currentVersion = ns.GetAddonVersion(addon)
        local savedVersion = (accountRecord and accountRecord.addonVersion) or (charRecord and charRecord.addonVersion)
        if currentVersion and savedVersion and currentVersion ~= savedVersion then
            return "Updated", "warning"
        end
        return "Saved", "success"
    end

    if snapshot then
        return "Not saved", "warning"
    end
    return "Fallback", "muted"
end

local function colorForKind(kind)
    if kind == "success" then return C.success end
    if kind == "warning" then return C.warning end
    if kind == "danger" then return C.danger end
    return C.muted
end

local function currentCharacterState(snapshot, characterKey)
    if not ns.CanSave() then return "Not prepared", "warning" end
    local needsCharacterData = false
    for addon, target in pairs(ns.GetTargets()) do
        if ns.IsProtectedAddon(addon) and type(target.character) == "table" and #target.character > 0 then
            needsCharacterData = true
            break
        end
    end

    if not needsCharacterData then return "Not required", "muted" end
    if not characterKey then return "Unavailable", "warning" end
    local record = snapshot and snapshot.characters and snapshot.characters[characterKey]
    if record and type(record.addons) == "table" then return "Saved", "success" end
    if snapshot then return "Not saved", "warning" end
    return "Fallback", "muted"
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
        if row.toggle.__label then row.toggle.__label:SetText(addonName) end

        row.toggle.OnValueChanged = function(self, checked)
            if checked then
                WTFIX_DB.protectedAddons[addonName] = nil
            else
                WTFIX_DB.protectedAddons[addonName] = false
            end
            if panel.Refresh then panel:Refresh(false) end
        end

        local textValue, kind = statusTextForAddon(addonName, ns.GetTargets()[addonName], snapshot, characterKey)
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
    local presentation = ns.GetStatusPresentation(checkLive)
    local summary = presentation.summary
    local state = summary.state

    if ns.CanSave() and not checkLive and not ns.pendingReload and ns.HasSnapshot() and state ~= "WARNING" and state ~= "PARTIAL" and state ~= "NO_LAUNCHER" and C_Timer and C_Timer.After then
        statePill:SetStatus("Checking", "warning")
        C_Timer.After(0, function()
            if panel:IsShown() then panel:Refresh(true) end
        end)
    else
        statePill:SetStatus(presentation.label, presentation.kind)
    end

    statusLabels.addons:SetText(tostring(summary.protectedAddons))
    local sourceLabel = summary.source == "disk" and "Disk bridge" or (summary.source == "native" and "Native" or (summary.source == "bootstrap" and "Bootstrap" or "None"))
    statusLabels.source:SetText(sourceLabel)
    statusLabels.saved:SetText(summary.lastSaved)
    statusLabels.cold:SetText(ns.CanSave() and "Ready" or "SETUP REQUIRED")

    local snapshot = ns.GetAuthoritativeSnapshot()
    local characterText, characterKind = currentCharacterState(snapshot, ns.GetCharacterKey())
    statusLabels.character:SetText(characterText)
    local characterColor = colorForKind(characterKind)
    statusLabels.character:SetTextColor(characterColor[1], characterColor[2], characterColor[3], characterColor[4] or 1)

    if ns.HasSnapshot() then
        statusLabels.source:SetTextColor(C.success[1], C.success[2], C.success[3], C.success[4])
    else
        statusLabels.source:SetTextColor(C.muted[1], C.muted[2], C.muted[3], C.muted[4])
    end
    statusLabels.cold:SetTextColor(
        summary.launcherDetected and C.success[1] or C.warning[1],
        summary.launcherDetected and C.success[2] or C.warning[2],
        summary.launcherDetected and C.success[3] or C.warning[3],
        1
    )

    saveButton:SetEnabledState(ns.CanSave())
    restoreButton:SetEnabledState(ns.CanRestore())
    detailsSub:SetText(ns.CanSave()
        and "Saved means a checkpoint exists, not that live data is identical. Use /wtfix diff to inspect differences."
        or ns.GetPreparationState().reason)

    headerDetail:SetText(presentation.compact or "")
    local hintColor = colorForKind(presentation.kind)
    headerDetail:SetTextColor(hintColor[1], hintColor[2], hintColor[3], hintColor[4] or 1)

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
                return
            end

            ns.pendingReload = "save"
            panel:Refresh(true)
            ns.Print("Snapshot captured. Reload required to write it to disk.")
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
    if ns.SetMinimapVisible then
        ns.SetMinimapVisible(checked)
    else
        WTFIX_DB.minimap.hide = not checked
    end
end

chatToggle.OnValueChanged = function(_, checked)
    WTFIX_DB.chatStatus = checked and true or false
end

panel:SetScript("OnShow", function(self)
    self:Refresh(false)
end)

ns.settingsLabel = "|T" .. ns.media .. "Icon:16:16:0:0|t " .. ns.brandTitle
ns.SettingsCompat.Register(panel, ns.settingsLabel)
ns.Panel = panel
