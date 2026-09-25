local _, ns = ...

local function snapshotTime()
    local snapshot = ns.GetAuthoritativeSnapshot()
    return snapshot and tonumber(snapshot.createdAt) or nil
end

-- Recovery runs BEFORE dependent addons load. Never gate its writes on their
-- load state. Classify its recorded outcomes when queried instead: dormant
-- addons are not active coverage failures, and a later load becomes visible
-- without reapplying globals after the addon has initialized or adopting data.
function ns.GetRecoveryCoverage()
    local stats = ns.restoreStats or {}
    local result = {missingVariables=0, fallbackVariables=0, missingDetails={}, unloadedMissingDetails={},
        unloadedAddons={}, unloadedAddonCount=0}
    if not ns.GetPreparationState().ready then return result end
    for addon in pairs(ns.GetTargets()) do
        if ns.IsProtectedAddon(addon) and not ns.IsAddonLoaded(addon) then
            result.unloadedAddons[#result.unloadedAddons+1] = addon
        end
    end
    table.sort(result.unloadedAddons)
    result.unloadedAddonCount = #result.unloadedAddons
    for _, kind in ipairs({"missing", "fallback"}) do
        local details = stats[kind .. "Details"]
        if type(details) ~= "table" then
            -- Unknown ownership must not hide a reported recovery problem.
            result[kind .. "Variables"] = tonumber(stats[kind .. "Variables"]) or 0
        else
            for _, item in ipairs(details) do
                if ns.IsProtectedAddon(item.addon) then
                    if ns.IsAddonLoaded(item.addon) then
                        result[kind .. "Variables"] = result[kind .. "Variables"] + 1
                        if kind == "missing" then result.missingDetails[#result.missingDetails+1] = item end
                    elseif kind == "missing" then
                        result.unloadedMissingDetails[#result.unloadedMissingDetails+1] = item
                    end
                end
            end
        end
    end
    return result
end

function ns.GetAddonSnapshotStatus(addon, target, snapshot, characterKey)
    if not ns.IsProtectedAddon(addon) then return "Disabled", "muted" end
    if not ns.IsAddonLoaded(addon) then return "Not loaded", "muted" end
    local account = snapshot and snapshot.account and snapshot.account.addons and snapshot.account.addons[addon]
    local character = snapshot and characterKey and snapshot.characters and snapshot.characters[characterKey]
    character = character and character.addons and character.addons[addon]
    local function complete(record, names)
        for _, name in ipairs(names or {}) do
            if not (record and record.entries and record.entries[name]) then return false end
        end
        return true
    end
    if complete(account, target.account) and complete(character, target.character) then
        local version = ns.GetAddonVersion(addon)
        local savedVersion = (account and account.addonVersion) or (character and character.addonVersion)
        if version and savedVersion and version ~= savedVersion then return "Updated", "warning" end
        return "Saved", "success"
    end
    if snapshot then return "Not saved", "warning" end
    return "Fallback", "muted"
end

function ns.GetStatusState(checkLive, coverage)
    local stats = ns.restoreStats or {}
    if not ns.GetPreparationState().ready then return "SETUP_REQUIRED" end
    if not stats.launcherDetected then return "NO_LAUNCHER" end
    if type(stats.warnings) == "table" and #stats.warnings > 0 then return "WARNING" end
    if not ns.HasSnapshot() then return "NO_SNAPSHOT" end
    coverage = coverage or ns.GetRecoveryCoverage()
    if coverage.fallbackVariables > 0 or coverage.missingVariables > 0 then return "PARTIAL" end
    -- Recovery health is independent of raw addon data equality. Session
    -- counters, logs and caches can change immediately after a correct restore.
    return "READY"
end

local function formatWhen(epoch)
    if not epoch or epoch <= 0 then return "Never" end
    if date then
        local ok, value = pcall(date, "%d %b %Y %H:%M", epoch)
        if ok and value then return value end
    end
    return tostring(epoch)
end

local function copyWarnings(warnings)
    local result = {}
    if type(warnings) ~= "table" then return result end
    for index, value in ipairs(warnings) do
        result[index] = tostring(value)
    end
    return result
end

function ns.GetStatusSummary(checkLive)
    local stats = ns.restoreStats or {}
    local snapshot, currentSource = ns.GetAuthoritativeSnapshot()
    local source = stats.snapshotSource or currentSource
    local warningDetails = copyWarnings(stats.warnings)
    local coverage = ns.GetRecoveryCoverage()
    return {
        state = ns.GetStatusState(checkLive, coverage),
        protectedAddons = tonumber(stats.protectedAddons) or 0,
        snapshotGeneration = snapshot and (tonumber(snapshot.generation) or 0) or 0,
        lastSaved = formatWhen(snapshotTime()),
        source = source,
        launcherDetected = stats.launcherDetected == true,
        snapshotVariables = tonumber(stats.snapshotVariables) or 0,
        fallbackVariables = coverage.fallbackVariables,
        missingVariables = coverage.missingVariables,
        unloadedAddonCount = coverage.unloadedAddonCount,
        warnings = #warningDetails,
        warningDetails = warningDetails,
        differences = checkLive and ns.GetLiveDifferences() or nil,
    }
end

local function plural(count, singular, pluralText)
    if count == 1 then return "1 " .. singular end
    return tostring(count) .. " " .. (pluralText or (singular .. "s"))
end

local function partialCompact(summary)
    local parts = {}
    if summary.fallbackVariables > 0 then
        parts[#parts + 1] = plural(summary.fallbackVariables, "fallback")
    end
    if summary.missingVariables > 0 then
        parts[#parts + 1] = plural(summary.missingVariables, "missing", "missing")
    end
    if #parts == 0 then return "Incomplete coverage" end
    return table.concat(parts, " • ")
end

function ns.GetStatusPresentation(checkLive)
    local summary = ns.GetStatusSummary(checkLive)

    if summary.state == "SETUP_REQUIRED" then
        local code = ns.GetPreparationState().code
        local labels = {IDENTITY_PENDING="Waiting for character", LINK_REQUIRED="Link character", RELOAD_REQUIRED="Reload required"}
        if labels[code] then
            return {state=code, label=labels[code], kind="warning", compact=code == "RELOAD_REQUIRED" and "Character link" or "/wtfix bind",
                detail=ns.GetPreparationState().reason, summary=summary, warningDetails=summary.warningDetails}
        end
        return { state="SETUP_REQUIRED", label="SETUP REQUIRED", kind="danger", compact="Run setup",
            detail=ns.GetPreparationState().reason, summary=summary, warningDetails=summary.warningDetails }
    end
    if ns.pendingReload then
        local compact = ns.pendingReload == "restore" and "Restore pending" or "Snapshot captured"
        return {
            state = "RELOAD_REQUIRED",
            label = "Reload required",
            kind = "warning",
            compact = compact,
            detail = ns.pendingReload == "restore"
                and "Reload to apply the protected snapshot."
                or "Reload to write the new snapshot to disk.",
            summary = summary,
            warningDetails = summary.warningDetails,
        }
    end

    local state = summary.state
    if state == "READY" then
        local differences = summary.differences
        local differs = differences and differences.addonCount > 0
        return {
            state = state,
            label = "Snapshot ready",
            kind = "success",
            compact = differs and (plural(differences.addonCount, "addon") .. " differ" .. (differences.addonCount == 1 and "s" or ""))
                or "Generation " .. tostring(summary.snapshotGeneration),
            detail = differs and "Live addon data differs; this can include settings, session counters or caches. Use /wtfix diff for details."
                or "Protected snapshot is ready.",
            summary = summary,
            warningDetails = summary.warningDetails,
        }
    elseif state == "PARTIAL" then
        return {
            state = state,
            label = "Partial coverage",
            kind = "warning",
            compact = partialCompact(summary),
            detail = "Some loaded, protected variables used disk fallback or lacked recovery data.",
            summary = summary,
            warningDetails = summary.warningDetails,
        }
    elseif state == "WARNING" then
        return {
            state = state,
            label = "Restore warning",
            kind = "danger",
            compact = plural(summary.warnings, "restore warning"),
            detail = "The last restore reported one or more warnings.",
            summary = summary,
            warningDetails = summary.warningDetails,
        }
    elseif state == "NO_LAUNCHER" then
        return {
            state = state,
            label = "Setup not detected",
            kind = "warning",
            compact = "Cold-start recovery unavailable",
            detail = "Run the WTFix setup tool with WoW closed to prepare recovery.",
            summary = summary,
            warningDetails = summary.warningDetails,
        }
    end

    return {
        state = "NO_SNAPSHOT",
        label = "Setup ready",
        kind = "warning",
        compact = "No snapshot saved",
        detail = "Save a protected snapshot when the UI is configured correctly.",
        summary = summary,
        warningDetails = summary.warningDetails,
    }
end

function ns.GetColdStartLabel()
    local p = ns.GetPreparationState()
    if not p.ready then return ns.GetStatusPresentation(false).label end
    if p.identity and p.identity.guid and not p.characterLinked then return "Link character: /wtfix bind" end
    return "Ready"
end

function ns.PrintStatus()
    local presentation = ns.GetStatusPresentation(true)
    local s = presentation.summary
    ns.Print(ns.version)
    ns.Print("Status: " .. presentation.label .. " • " .. presentation.compact)
    ns.Print("Preparation: " .. ns.GetPreparationState().reason)
    local preparation = ns.GetPreparationState()
    if preparation.identity then
        ns.Print("Identity source: " .. tostring(preparation.identity.source or "verified-name"))
    end
    if preparation.checkpointKey then
        ns.Print("Checkpoint key: " .. preparation.checkpointKey:gsub("|", "||"):gsub("[%c]", "?"))
    end
    ns.Print("Recovery applied this session: " .. (ns.recoveryPerformed and "yes" or "no"))
    local view = ns.GetRecoveryView and ns.GetRecoveryView(false)
    ns.Print("Last saved: " .. (view and view.saved or s.lastSaved))
    ns.Print((view and view.countLabel or "Protected addons") .. ": " .. (view and view.count or s.protectedAddons))
    if s.unloadedAddonCount > 0 then ns.Print("Not loaded: " .. s.unloadedAddonCount .. " protected addons; existing data retained, no live capture. /wtfix check lists them.") end
    ns.Print("Recovery source: " .. tostring(s.source))
    if not preparation.ready then
        ns.Print("Snapshot generation: — (not qualified; saved records may still exist)")
    else
        ns.Print("Snapshot generation: " .. tostring(s.snapshotGeneration)
            .. " (restored " .. tostring(ns.restoreStats and ns.restoreStats.snapshotGeneration or 0) .. ")")
    end
    ns.Print("Native at file load: " .. tostring(ns.nativeSnapshotAtFileLoad))
    ns.Print("Native config at file load: " .. tostring(ns.nativeConfigAtFileLoad))
    ns.Print("Native at recovery: " .. tostring(ns.nativeSnapshotAtRestore))
    ns.Print("Disk at file load: " .. tostring(ns.diskSnapshotAtFileLoad))
    ns.Print("Disk bridge: " .. (ns.diskReadObserved and "Loaded" or "Unavailable"))
    if WTFIX_BOOTSTRAP and WTFIX_BOOTSTRAP.snapshotFile then
        ns.Print("Bootstrap snapshot file: " .. WTFIX_BOOTSTRAP.snapshotFile)
    end
    ns.Print("Cold-start recovery: " .. ns.GetColdStartLabel())
    if s.differences and s.differences.addonCount > 0 then
        ns.Print("Live data differs in " .. plural(s.differences.addonCount, "addon") .. ". This may be settings or runtime data; /wtfix diff lists the variables.")
    end
    if s.warnings > 0 then
        ns.Print("Restore warnings: " .. tostring(s.warnings))
    end
    if s.missingVariables > 0 then ns.Print("Missing-variable details: /wtfix check (last recovery, separate from Save).") end
    local snapshot = ns.GetAuthoritativeSnapshot()
    local omitted = snapshot and snapshot.captureOmissions and snapshot.captureOmissions.count or 0
    if omitted > 0 then ns.Print("Last Save omitted " .. tostring(omitted) .. " nonpersistent fields; /wtfix check shows details.") end
end

local function diagnosticText(value)
    -- Do not allow arbitrary addon metadata/keys to create chat links or lines.
    local text = tostring(value or "unknown"):gsub("|", "||"):gsub("[%c]", " ")
    if #text > 480 then text = text:sub(1, 180) .. " ... " .. text:sub(-270) end
    return text
end

function ns.PrintCaptureFailures(failures)
    failures = failures or {}
    for index = 1, math.min(40, #failures) do
        local issue = failures[index]
        ns.Print("Capture blocked: " .. diagnosticText(issue.addon) .. " (" .. diagnosticText(issue.scope)
            .. ", version " .. diagnosticText(issue.addonVersion) .. "), " .. diagnosticText(issue.variable))
        ns.Print("Path: " .. diagnosticText(issue.path))
        ns.Print("Reason: " .. diagnosticText(issue.reason))
    end
    if #failures > 40 then ns.Print(tostring(#failures - 40) .. " more blocked variables (output capped).") end
end

function ns.PrintCaptureOmissions(report, label)
    if not report or (report.count or 0) == 0 then return end
    ns.Print(label .. ": " .. tostring(report.count) .. " nonpersistent fields omitted; scalar/table settings retained.")
    local details = type(report.details) == "table" and report.details or {}
    for index = 1, math.min(40, #details) do
        local issue = details[index]
        ns.Print("Omitted: " .. diagnosticText(issue.addon) .. " (" .. diagnosticText(issue.scope) .. "), " .. diagnosticText(issue.path))
        ns.Print("Reason: " .. diagnosticText(issue.reason))
    end
    if report.count > #details then ns.Print(tostring(report.count - #details) .. " further omissions; detail storage capped at 40.") end
end

function ns.PrintCaptureCheck()
    ns.Print(ns.version .. " capture check; no Save, Restore or reload performed.")
    local result = ns.CheckCapture()
    if not result.ready then ns.Print("SETUP REQUIRED: " .. tostring(result.reason)); return end
    ns.Print(tostring(result.checked) .. " loaded, protected variables checked; " .. tostring(#result.failures) .. " blocked.")
    ns.PrintCaptureFailures(result.failures)
    ns.PrintCaptureOmissions(result.omissions, "Current capture projection (not saved)")
    if #result.failures == 0 then ns.Print("Persistable live data is copyable now. This is not a persistence or recovery test.") end
    local snapshot = ns.GetAuthoritativeSnapshot()
    ns.PrintCaptureOmissions(snapshot and snapshot.captureOmissions, "Last committed Save")
    local coverage = ns.GetRecoveryCoverage()
    ns.Print("Missing at last recovery for currently loaded addons: " .. tostring(coverage.missingVariables) .. " (separate from the current capture check).")
    local missing = coverage.missingDetails
    for index = 1, math.min(40, #missing) do
        local item = missing[index]
        ns.Print("Missing: " .. diagnosticText(item.addon) .. " (" .. diagnosticText(item.scope) .. "), "
            .. diagnosticText(item.variable) .. ": " .. diagnosticText(item.reason))
    end
    if #missing > 40 then ns.Print(tostring(#missing - 40) .. " more missing variables (output capped).") end
    for index = 1, math.min(40, #coverage.unloadedAddons) do
        ns.Print("Not loaded: " .. diagnosticText(coverage.unloadedAddons[index]) .. "; not captured, existing checkpoint/fallback data retained.")
    end
    if #coverage.unloadedAddons > 40 then ns.Print(tostring(#coverage.unloadedAddons-40) .. " more unloaded addons.") end
    ns.Print("Unavailable recovery inputs for unloaded addons: " .. #coverage.unloadedMissingDetails .. " (not active missing coverage).")
    for index = 1, math.min(40, #coverage.unloadedMissingDetails) do
        local item = coverage.unloadedMissingDetails[index]
        ns.Print("Unloaded / no recovery input: " .. diagnosticText(item.addon) .. " (" .. diagnosticText(item.scope) .. "), " .. diagnosticText(item.variable))
    end
    ns.Print("First blocking failure per variable; bounded omission details. No values printed or live data changed. Unusual keys are redacted; long paths shortened. No checkpoint adopted.")
end

function ns.PrintDifferences()
    if not ns.HasSnapshot() then ns.Print("No protected snapshot to compare."); return end
    local differences = ns.GetLiveDifferences()
    if #differences.variables == 0 then
        ns.Print("Compared loaded, protected variables match the snapshot.")
        return
    end
    ns.Print("Live data differs in " .. plural(differences.addonCount, "addon") .. ". These are data differences, not proof of unsaved user settings or a failed restore.")
    for index = 1, math.min(20, #differences.variables) do
        local item = differences.variables[index]
        ns.Print(item.addon .. " (" .. item.scope .. "): " .. item.path)
    end
    if #differences.variables > 20 then ns.Print(tostring(#differences.variables - 20) .. " more differing variables.") end
    ns.Print("One differing path per variable is shown; persistable data is compared. Nonpersistent fields are listed by /wtfix check. No values are printed.")
end

local function loginLine()
    if not ns.GetPreparationState().ready then
        ns.Print(ns.version .. " • SETUP REQUIRED • " .. ns.GetPreparationState().reason)
        return
    end
    if WTFIX_DB.chatStatus == false then return end
    local presentation = ns.GetStatusPresentation(false)
    local s = presentation.summary
    if presentation.state == "READY" then
        ns.Print(ns.version .. " • Snapshot restored • " .. s.protectedAddons .. " addons protected")
    else
        ns.Print(ns.version .. " • " .. presentation.label .. " • /wtfix status")
    end
end

local frame = CreateFrame("Frame")
frame:RegisterEvent("PLAYER_LOGIN")
frame:SetScript("OnEvent", function(self)
    loginLine()
    self:UnregisterEvent("PLAYER_LOGIN")
end)
