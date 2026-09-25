local _, ns = ...

local host = ns.RecoveryDialogHost
local sheet = ns.UI_CreateScroll(host.dialog)
sheet:SetPoint("TOPLEFT", 20, -58)
sheet:SetPoint("BOTTOMRIGHT", -20, 64)
sheet:Hide()
local entries, blocks, selected, offer = {}, {}, nil, nil
local layoutBusy = false

local function layout()
    if layoutBusy then return end
    layoutBusy = true
    local width = math.max(140, sheet.scroll:GetWidth())
    local y = 0
    for i, block in ipairs(blocks) do
        local entry = entries[i]
        if not entry then
            entry = ns.UI_CreateButton(sheet.child, "", width, "secondary")
            entry.__label:ClearAllPoints()
            entry.__label:SetPoint("TOPLEFT", 10, -9)
            entry.__label:SetJustifyH("LEFT")
            entry.__label:SetWordWrap(true)
            entry.text = ns.UI_CreateLabel(sheet.child, "", false)
            entry.text:SetWordWrap(true)
            entry.text:SetJustifyV("TOP")
            entries[i] = entry
        end
        entry:Hide(); entry.text:Hide()
        local label = block.click and entry.__label or entry.text
        label:SetWidth(width - (block.click and 20 or 0))
        label:SetText(block.text)
        local height = math.max(16, label:GetStringHeight())
        if block.click then
            entry.contentY = y
            entry:ClearAllPoints(); entry:SetPoint("TOPLEFT", 0, -y)
            entry:SetSize(width, height + 18)
            entry:SetScript("OnClick", block.click)
            entry:Show()
            height = height + 18
        else
            label:ClearAllPoints(); label:SetPoint("TOPLEFT", 0, -y)
            label:SetHeight(height); label:Show()
        end
        y = y + height + 12
    end
    for i = #blocks + 1, #entries do entries[i]:Hide(); entries[i].text:Hide() end
    sheet.child:SetHeight(math.max(1, y))
    sheet.UpdateThumb()
    layoutBusy = false
end
sheet.child:SetScript("OnSizeChanged", layout)
local function display(title, content, primary, callback, onKey)
    blocks = content
    if not ns.ShowRecoverySheet(title, sheet, primary, callback, onKey) then return false end
    sheet.scroll:SetVerticalScroll(0)
    layout()
    return true
end

function ns.ShowRecoveryDetails(technical)
    local rows, explanation = ns.GetRecoveryDetails(technical)
    local content = {{text=explanation or "Recovery information for this login."}}
    for _, row in ipairs(rows) do content[#content+1]={text=row[1] .. ": " .. row[2]} end
    content[#content+1]={text=technical and "Hide Technical Details" or "Show Technical Details",
        click=function() ns.ShowRecoveryDetails(not technical) end}
    display("Recovery Details", content)
end

function ns.ShowRecoveryHelp()
    local cause, step, diagnostic = ns.GetRecoveryHelp()
    display("Setup Help / View Problem", {{text=cause}, {text=step},
        {text="An unavailable recovery state does not mean your saved data is gone."}, {text=diagnostic}})
end

local function linkError(reason)
    display("Character Link Not Changed", {
        {text=ns.RecoveryText(reason)},
        {text="No character link was confirmed. Review the available records again, or close this dialog and use Setup Help if recovery is blocked."},
        {text="Review Records", click=function() ns.ShowCharacterLink() end}})
    if ns.Panel then ns.Panel:Refresh(false) end
end

function ns.ShowCharacterLink()
    if InCombatLockdown and InCombatLockdown() then
        ns.Print("Leave combat before linking a character."); return
    end
    local reason
    offer, reason = ns.GetCharacterLinkOffer()
    selected = nil
    if not offer then linkError(reason); return end
    local currentOffer = offer
    local content = {
        {text="Current character: " .. ns.RecoveryText(offer.identity.fullName)},
        {text="Choose the saved character record that belongs to this character. Linking does not save current settings or apply recovery. A reload will be required."},
        {text="Nothing is selected. If you are unsure which record belongs to you, cancel and ask for help. A higher generation is not proof of ownership."},
    }
    local firstRow = #content + 1
    local function rowText(i)
        local choice = currentOffer.choices[i]
        local record = currentOffer.snapshot and currentOffer.snapshot.characters[choice.key]
        local name = choice.key:match("^[^/]+/(.+)$") or choice.key
        return (selected == i and "[Selected] " or "[ ] ") .. ns.RecoveryText(name)
            .. "\nSaved record: " .. ns.RecoveryText(choice.key)
            .. (record and ("\nLast saved: " .. ns.RecoveryTime(record.savedAt)
                .. "   •   Generation " .. tostring(choice.generation))
                or "\nNo saved character record exists. This links the character without creating a snapshot.")
    end
    local function selectRow(i)
        selected = i
        for j=1,#currentOffer.choices do content[firstRow+j-1].text=rowText(j) end
        host.confirm:SetEnabledState(true)
        layout()
        local entry = entries[firstRow+i-1]
        local offset, height = sheet.scroll:GetVerticalScroll(), sheet.scroll:GetHeight()
        if entry.contentY < offset then sheet.scroll:SetVerticalScroll(entry.contentY)
        elseif entry.contentY + entry:GetHeight() > offset + height then
            sheet.scroll:SetVerticalScroll(math.min(sheet.scroll:GetVerticalScrollRange(), entry.contentY + entry:GetHeight() - height))
        end
        sheet.UpdateThumb()
    end
    for i=1,#currentOffer.choices do
        local index=i
        content[#content+1]={text=rowText(index),click=function() selectRow(index) end}
    end
    local function confirm()
        if not selected then return end
        if InCombatLockdown and InCombatLockdown() then linkError("Leave combat before confirming a character link."); return end
        local ok, failure = ns.ConfirmCharacterLink(currentOffer, selected)
        if not ok then linkError(failure); return end
        ns.ShowReloadRequired("identity")
    end
    if display("Link Character", content, "Link Selected Record", confirm, function(key)
        if key == "UP" or key == "DOWN" then
            local i = selected or (key == "DOWN" and 0 or #currentOffer.choices+1)
            selectRow(math.max(1, math.min(#currentOffer.choices, i+(key == "DOWN" and 1 or -1))))
            return true
        end
        -- Enter never doubles as confirmation/reload: the explicit buttons are
        -- the adoption affordance, independent of keyboard selection.
        return false
    end) then host.confirm:SetEnabledState(false) end
end

function ns.RunRecoveryAction()
    local action = ns.GetRecoveryView(false).action
    if action == "link" then ns.ShowCharacterLink()
    elseif action == "reload" then ns.ShowReloadRequired(ns.pendingReload)
    elseif action == "help" then ns.ShowRecoveryHelp()
    else ns.ShowRecoveryDetails(false) end
end
