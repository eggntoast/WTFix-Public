local _, ns = ...

local T = ns.Theme
local C = T.colors

local overlay = CreateFrame("Frame", "WTFixConfirmOverlay", UIParent)
overlay:SetAllPoints()
overlay:SetFrameStrata("DIALOG")
overlay:SetFrameLevel(900)
overlay:EnableMouse(true)
overlay:Hide()

local shade = overlay:CreateTexture(nil, "BACKGROUND")
shade:SetAllPoints()
shade:SetColorTexture(0, 0, 0, 0.68)

local dialog = CreateFrame("Frame", nil, overlay)
dialog:SetSize(430, 220)
dialog:SetPoint("CENTER")
T.AddPanelSkin(dialog, true)

local title = dialog:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
title:SetPoint("TOPLEFT", 20, -20)
title:SetPoint("RIGHT", -20, 0)
title:SetJustifyH("LEFT")
title:SetTextColor(C.accentBright[1], C.accentBright[2], C.accentBright[3])

local body = dialog:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
body:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -16)
body:SetPoint("RIGHT", -20, 0)
body:SetHeight(112)
body:SetJustifyH("LEFT")
body:SetJustifyV("TOP")
body:SetSpacing(3)
body:SetWordWrap(true)
body:SetTextColor(C.text[1], C.text[2], C.text[3])

local confirm = ns.UI_CreateButton(dialog, "Confirm", 150, "primary")
confirm:SetPoint("BOTTOMRIGHT", -20, 18)

local cancel = ns.UI_CreateButton(dialog, "Cancel", 120, "secondary")
cancel:SetPoint("RIGHT", confirm, "LEFT", -10, 0)

-- Keep the protected reload action isolated from the normal WTFix frame tree.
-- The button is fully configured when the addon loads and is only shown later.
local reloadButton = CreateFrame("Button", "WTFixSecureReloadButton", UIParent, "SecureActionButtonTemplate")
reloadButton:SetSize(150, 32)
reloadButton:SetPoint("CENTER", UIParent, "CENTER", 120, -76)
reloadButton:SetFrameStrata("DIALOG")
reloadButton:SetFrameLevel(920)
reloadButton:RegisterForClicks("LeftButtonUp")
reloadButton:SetAttribute("type1", "macro")
reloadButton:SetAttribute("macrotext1", "/reload")
reloadButton:SetAttribute("useOnKeyDown", false)

local reloadShadow = reloadButton:CreateTexture(nil, "BACKGROUND")
reloadShadow:SetPoint("TOPLEFT", 2, -2)
reloadShadow:SetPoint("BOTTOMRIGHT", 2, -2)
reloadShadow:SetColorTexture(0, 0, 0, 0.38)

local reloadBg = reloadButton:CreateTexture(nil, "BACKGROUND", nil, 1)
reloadBg:SetAllPoints()
T.SetColorTexture(reloadBg, C.buttonHover)

local reloadTop = reloadButton:CreateTexture(nil, "BORDER")
reloadTop:SetPoint("TOPLEFT")
reloadTop:SetPoint("TOPRIGHT")
reloadTop:SetHeight(1)
T.SetColorTexture(reloadTop, C.borderBright)

local reloadBottom = reloadButton:CreateTexture(nil, "BORDER")
reloadBottom:SetPoint("BOTTOMLEFT")
reloadBottom:SetPoint("BOTTOMRIGHT")
reloadBottom:SetHeight(1)
T.SetColorTexture(reloadBottom, C.borderSoft)

local reloadLeft = reloadButton:CreateTexture(nil, "BORDER")
reloadLeft:SetPoint("TOPLEFT")
reloadLeft:SetPoint("BOTTOMLEFT")
reloadLeft:SetWidth(1)
T.SetColorTexture(reloadLeft, C.borderSoft)

local reloadRight = reloadButton:CreateTexture(nil, "BORDER")
reloadRight:SetPoint("TOPRIGHT")
reloadRight:SetPoint("BOTTOMRIGHT")
reloadRight:SetWidth(1)
T.SetColorTexture(reloadRight, C.borderSoft)

local reloadLabel = reloadButton:CreateFontString(nil, "OVERLAY", "GameFontNormal")
reloadLabel:SetPoint("CENTER")
reloadLabel:SetText("Reload Now")
reloadLabel:SetTextColor(C.text[1], C.text[2], C.text[3], C.text[4] or 1)
reloadButton:Hide()

local callback
local mode = "confirm"
local customContent
local keyHandler

local function inCombat()
    return InCombatLockdown and InCombatLockdown()
end

local function restoreConfirmButtons()
    confirm:SetWidth(150)
    confirm:SetEnabledState(true)
    confirm:ClearAllPoints()
    confirm:SetPoint("BOTTOMRIGHT", -20, 18)
    cancel:ClearAllPoints()
    cancel:SetPoint("RIGHT", confirm, "LEFT", -10, 0)
    cancel:SetButtonText("Cancel")
    confirm:Show()
    cancel:Show()
end

local function resetDialog()
    if customContent then customContent:Hide() end
    keyHandler = nil
    dialog:SetSize(430, 220)
    body:Show()
end

cancel:SetScript("OnClick", function()
    if mode == "reload" then
        if inCombat() then
            ns.Print("Reload is still required. Leave combat before closing this prompt.")
            return
        end
        reloadButton:Hide()
        overlay:Hide()
        mode = "confirm"
        callback = nil
        return
    end

    callback = nil
    overlay:Hide()
end)

function ns.CloseRecoveryDialog()
    local fn = cancel:GetScript("OnClick")
    if fn then fn() end
end
overlay:EnableKeyboard(true)
overlay:SetPropagateKeyboardInput(true)
overlay:SetScript("OnKeyDown", function(self, key)
    local handled = false
    if key == "ESCAPE" then ns.CloseRecoveryDialog(); handled = true
    elseif keyHandler then handled = keyHandler(key) == true end
    self:SetPropagateKeyboardInput(not handled)
end)

confirm:SetScript("OnClick", function()
    if not confirm.__enabled then return end
    local fn = callback
    callback = nil
    overlay:Hide()
    if fn then fn() end
end)

function ns.ShowConfirm(dialogTitle, dialogBody, confirmText, fn)
    if reloadButton:IsShown() and inCombat() then return false end
    resetDialog()
    if reloadButton:IsShown() and not inCombat() then
        reloadButton:Hide()
    end
    mode = "confirm"
    restoreConfirmButtons()
    title:SetText(dialogTitle or "Confirm")
    body:SetText(dialogBody or "")
    confirm:SetButtonText(confirmText or "Confirm")
    callback = fn
    overlay:Show()
end

function ns.ShowReloadRequired(reloadMode)
    if inCombat() then
        ns.Print("Reload is required. Leave combat, then reopen WTFix to continue.")
        return false
    end

    resetDialog()

    callback = nil
    mode = "reload"
    confirm:Hide()
    cancel:ClearAllPoints()
    cancel:SetPoint("BOTTOMLEFT", dialog, "BOTTOMLEFT", 20, 18)
    cancel:SetButtonText("Later")
    cancel:Show()

    if reloadMode == "identity" then
        title:SetText("Character Linked — Reload Required")
        body:SetText("Reload once to apply your saved settings before protected addons initialize. This can replace unsaved addon changes. Linking did not save current settings or apply recovery. Choose Later to continue with recovery pending.")
    elseif reloadMode == "restore" then
        title:SetText("Reload to Restore")
        body:SetText("WTFix is ready to restore your protected snapshot. Reload now to discard current unsaved addon changes and apply the snapshot during addon startup.")
    else
        title:SetText("Snapshot Captured")
        body:SetText("WTFix captured your new protected snapshot. Reload now so WoW writes the updated SavedVariables to disk and restarts the interface cleanly.")
    end

    overlay:Show()
    reloadButton:Show()
    return true
end

ns.SecureReloadButton = reloadButton

-- Reuse the same modal surface for read-only help/details and record selection.
-- The secure reload button retains its original separate frame and fixed setup.
function ns.ShowRecoverySheet(dialogTitle, content, primaryText, fn, onKey)
    if reloadButton:IsShown() and inCombat() then
        ns.Print("Leave combat before changing the reload prompt."); return false
    end
    if reloadButton:IsShown() then reloadButton:Hide() end
    resetDialog()
    mode = "sheet"
    customContent, keyHandler = content, onKey
    dialog:SetSize(math.max(300, math.min(520, UIParent:GetWidth()-40)), math.max(260, math.min(470, UIParent:GetHeight()-60)))
    title:SetText(dialogTitle)
    body:Hide()
    restoreConfirmButtons()
    confirm:SetWidth(190)
    confirm:SetButtonText(primaryText or "")
    confirm:SetShown(primaryText ~= nil)
    confirm:SetEnabledState(fn ~= nil)
    cancel:SetButtonText(primaryText and "Cancel" or "Close")
    local stacked = primaryText and dialog:GetWidth() < 400
    content:SetPoint("BOTTOMRIGHT", -20, stacked and 102 or 64)
    if stacked then
        confirm:ClearAllPoints(); confirm:SetPoint("BOTTOMRIGHT", -20, 54)
        confirm:SetWidth(dialog:GetWidth()-40)
        cancel:ClearAllPoints(); cancel:SetPoint("BOTTOMRIGHT", -20, 14)
    end
    if not primaryText then cancel:ClearAllPoints(); cancel:SetPoint("BOTTOMRIGHT", -20, 18) end
    callback = fn
    content:Show()
    overlay:Show()
    return true
end
ns.RecoveryDialogHost = {dialog=dialog, overlay=overlay, confirm=confirm, cancel=cancel}
