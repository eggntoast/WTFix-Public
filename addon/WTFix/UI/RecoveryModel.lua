local _, ns = ...

-- Presentation only. In particular, these readers must never call
-- InitializePreparation/GetCharacterLinkOffer or grant recovery authority.
function ns.RecoveryText(value)
    return tostring(value or "Unavailable"):gsub("|", "||"):gsub("[%c]", " ")
end
function ns.RecoveryTime(value)
    if type(value) ~= "number" or value <= 0 then return "Not recorded" end
    if date then
        local ok, text = pcall(date, "%d %b %Y %H:%M", value)
        if ok then return text end
    end
    return tostring(value)
end
local blocked = {BINDING_CONFLICT=true, IDENTITY_CONFLICT=true, BOUND_RECORD_MISSING=true,
    CONFIG=true, SNAPSHOT=true}
function ns.GetRecoveryView(checkLive)
    local p = ns.GetPreparationState()
    local presentation = ns.GetStatusPresentation(checkLive)
    local s = presentation.summary
    local view = {status=presentation.label, kind=presentation.kind, action="details", actionLabel="Details",
        explanation=presentation.detail, countLabel="Protected addons", count=tostring(s.protectedAddons),
        saved=s.lastSaved, source=s.source == "disk" and "Disk bridge" or s.source == "native" and "Native"
            or s.source == "bootstrap" and "Bootstrap" or "None",
        link=p.characterLinked and "Linked" or "Not linked", cold=s.launcherDetected and "Ready" or "Unavailable", editable=p.ready,
        summary=s, preparation=p}
    if not p.ready then
        view.count, view.saved, view.source, view.cold = "—", "—", "Not applied", "Unavailable"
        local count=0; for _ in pairs(ns.GetTargets()) do count=count+1 end
        if count > 0 then view.countLabel,view.count="Detected addons",tostring(count) end
        view.explanation="Recovery is unavailable. Saved data has not been qualified; this does not mean it is missing."
        if ns.recoveryPerformed then view.source="Applied earlier" end
        if p.code == "IDENTITY_PENDING" then
            view.status,view.kind,view.actionLabel,view.action="Checking identity","warning","Details","details"
            view.link,view.cold="Checking","Waiting for identity"
            view.explanation="Waiting for the character name. WTFix has not applied recovery this login."
        elseif p.code == "LINK_REQUIRED" or (p.code == "RELOAD_REQUIRED" and ns.pendingReload ~= "identity") then
            view.status,view.kind,view.actionLabel,view.action="Link required","warning","Link Character","link"
            view.cold="Awaiting link"
            view.explanation="Choose the saved character record WTFix should use. Recovery has not been applied this login."
        elseif p.code == "RELOAD_REQUIRED" and ns.pendingReload == "identity" then
            view.status,view.kind,view.actionLabel,view.action="Reload required","warning","Reload Now","reload"
            view.link,view.cold="Linked","Awaiting reload"
            view.explanation="Character linked. Reload once to apply saved settings. No new snapshot was saved."
        else
            view.status,view.kind="Setup required","danger"
            view.action,view.actionLabel="help","Setup Help"
            if blocked[p.code] then view.status,view.actionLabel="Recovery blocked","View Problem" end
        end
    elseif ns.pendingReload then
        view.status,view.kind,view.actionLabel,view.action="Reload required","warning","Reload Now","reload"
        view.cold="Awaiting reload"
    elseif p.identity and p.identity.guid and not p.characterLinked then
        view.status,view.kind,view.actionLabel,view.action="Link required","warning","Link Character","link"
        view.cold="Awaiting link"
        view.explanation="Recovery ran this login. Link this character so recovery can also start before its name is available on a cold start."
    elseif presentation.state == "PARTIAL" or presentation.state == "WARNING" then
        view.action,view.actionLabel="details","View Details"
    elseif presentation.state == "NO_LAUNCHER" then
        view.action,view.actionLabel="help","Setup Help"
    end
    return view
end

local help = {
    ABSENT={"Preparation data is unavailable.", "In the AddOn List, check that WTFix preparation data is installed and enabled for this character. If it is missing, exit WoW and run the Windows launcher or Linux preparation tool. Its absence alone does not tell WTFix whether setup was never run or the companion is disabled."},
    PROTOCOL={"The runtime and preparation use incompatible bridge versions.", "Update the WTFix runtime and preparation tool to compatible versions. Exit WoW and run preparation again."},
    INCOMPLETE={"Preparation data did not finish loading.", "Check the AddOn List and any Lua errors. Exit WoW and run preparation again if the companion still cannot finish loading."},
    BRIDGE_ID={"The disk bridge does not match this preparation.", "Exit WoW and run preparation for the intended game folder and account. Do not delete SavedVariables to repair the bridge."},
    DISK={"The disk recovery input is unavailable or invalid.", "Preserve the recovery files. Check the selected game folder/account and the preparation tool's result. Run preparation with WoW closed; seek help if the problem remains."},
    CHARACTER_NOT_PREPARED={"This full character name is not in the prepared roster.", "Exit WoW and prepare the intended account. WTFix cannot prove the active account from the character name alone."},
    CHARACTER_AMBIGUOUS={"More than one prepared directory matches this character name.", "Preserve the folders and review the preparation account/character roster. Do not delete settings or guess a directory to force a match."},
    BINDING_CONFLICT={"The saved character link conflicts with the available identity or configuration.", "Do not Save a replacement or guess another link. Preserve your recovery files and report the problem. Rerunning preparation does not necessarily repair a conflicting link."},
    IDENTITY_CONFLICT={"The available character identities do not agree.", "Do not Save a replacement. Preserve your recovery files and report the problem; WTFix will not guess which identity is correct."},
    BOUND_RECORD_MISSING={"The linked saved character record is missing.", "Preserve your recovery files and backups. Do not create a replacement snapshot until the missing record has been investigated."},
    CONFIG={"Recovery configuration conflicts or cannot be safely copied.", "Preserve your recovery files and report the problem. Do not Save a replacement or delete the existing files."},
    SNAPSHOT={"The selected checkpoint cannot be safely copied.", "Preserve your recovery files and report the problem. WTFix will not silently replace it with an older checkpoint."},
    METADATA={"Preparation metadata is invalid.", "Exit WoW and run preparation again for the intended game folder/account. Preserve existing recovery files."},
    BOOTSTRAP={"Generated recovery data is invalid.", "Exit WoW and run preparation again. If the problem remains, preserve the preparation report and recovery files for support."},
}
function ns.GetRecoveryHelp()
    local p=ns.GetPreparationState()
    local item=help[p.code]
    return item and item[1] or "Recovery is not ready.", item and item[2] or p.reason,
        "Reason code: " .. ns.RecoveryText(p.code) .. ". For support, include your WTFix version and /wtfix status."
end
function ns.GetRecoveryDetails(technical)
    local v=ns.GetRecoveryView(false)
    local p,s=v.preparation,v.summary
    local identity=ns.ObservePlayerIdentity and ns.ObservePlayerIdentity() or nil
    local rows={
        {"Current character", identity and identity.ready and ns.RecoveryText(identity.fullName) or "Unavailable"},
        {"Character link",v.link},
        {"Linked saved record",(p.characterLinked or ns.pendingReload=="identity") and p.checkpointKey and ns.RecoveryText(p.checkpointKey) or "Not selected"},
        {"Recovery applied this login",ns.recoveryPerformed and "Yes" or "No"},
        {v.countLabel,v.count}, {"Last saved",v.saved},
        {"Snapshot generation",p.ready and tostring(s.snapshotGeneration) or "— (not qualified)"},
        {"Cold-start recovery",v.cold},
    }
    if p.ready then
        rows[#rows+1]={"Loaded variables missing at recovery",tostring(s.missingVariables or 0)}
        rows[#rows+1]={"Variables recovered from fallback",tostring(s.fallbackVariables or 0)}
        for _, warning in ipairs(s.warningDetails or {}) do
            rows[#rows+1]={"Recovery warning",ns.RecoveryText(warning)}
        end
    end
    if technical then
        rows[#rows+1]={"Recovery source",v.source}
        rows[#rows+1]={"Identity source",ns.RecoveryText(p.identity and p.identity.source or "Not qualified")}
        rows[#rows+1]={"Preparation code",ns.RecoveryText(p.code)}
        rows[#rows+1]={"Disk bridge read",ns.diskReadObserved and "Completed" or "Unavailable"}
        rows[#rows+1]={"Account identity","Not verified by the client"}
    end
    return rows,v.explanation
end
