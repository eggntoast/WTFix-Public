local _, ns = ...

local function snapshotTime()
    local snapshot = ns.GetAuthoritativeSnapshot()
    return snapshot and tonumber(snapshot.createdAt) or nil
end

function ns.GetStatusState(checkLive)
    local stats = ns.restoreStats or {}
    if not ns.GetPreparationState().ready then return "SETUP_REQUIRED" end
    if not stats.launcherDetected then return "NO_LAUNCHER" end
    if type(stats.warnings) == "table" and #stats.warnings > 0 then return "WARNING" end
    if not ns.HasSnapshot() then return "NO_SNAPSHOT" end
    if (tonumber(stats.fallbackVariables) or 0) > 0 or (tonumber(stats.missingVariables) or 0) > 0 then return "PARTIAL" end
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
    return {
        state = ns.GetStatusState(checkLive),
        protectedAddons = tonumber(stats.protectedAddons) or 0,
        snapshotGeneration = snapshot and (tonumber(snapshot.generation) or 0) or 0,
        lastSaved = formatWhen(snapshotTime()),
        source = source,
        launcherDetected = stats.launcherDetected == true,
        snapshotVariables = tonumber(stats.snapshotVariables) or 0,
        fallbackVariables = tonumber(stats.fallbackVariables) or 0,
        missingVariables = tonumber(stats.missingVariables) or 0,
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
        return { state="SETUP_REQUIRED", label="SETUP REQUIRED", kind="danger", compact="Run the launcher",
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
            detail = "Some protected variables used disk fallback or are missing.",
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
            label = "Launcher not detected",
            kind = "warning",
            compact = "Cold-start recovery unavailable",
            detail = "Launch through WTFix Launcher.cmd for cold-start recovery.",
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

function ns.PrintStatus()
    local presentation = ns.GetStatusPresentation(true)
    local s = presentation.summary
    ns.Print(ns.version)
    ns.Print("Status: " .. presentation.label .. " • " .. presentation.compact)
    ns.Print("Preparation: " .. ns.GetPreparationState().reason)
    ns.Print("Last saved: " .. s.lastSaved)
    ns.Print("Protected addons: " .. s.protectedAddons)
    ns.Print("Recovery source: " .. tostring(s.source))
    ns.Print("Snapshot generation: " .. tostring(s.snapshotGeneration)
        .. " (restored " .. tostring(ns.restoreStats and ns.restoreStats.snapshotGeneration or 0) .. ")")
    ns.Print("Native at file load: " .. tostring(ns.nativeSnapshotAtFileLoad))
    ns.Print("Native config at file load: " .. tostring(ns.nativeConfigAtFileLoad))
    ns.Print("Native at recovery: " .. tostring(ns.nativeSnapshotAtRestore))
    ns.Print("Disk at file load: " .. tostring(ns.diskSnapshotAtFileLoad))
    ns.Print("Disk bridge: " .. (ns.diskReadObserved and "Loaded" or "Unavailable"))
    if WTFIX_BOOTSTRAP and WTFIX_BOOTSTRAP.snapshotFile then
        ns.Print("Bootstrap snapshot file: " .. WTFIX_BOOTSTRAP.snapshotFile)
    end
    ns.Print("Cold-start recovery: " .. (ns.GetPreparationState().ready and "Ready" or "SETUP REQUIRED"))
    if s.differences and s.differences.addonCount > 0 then
        ns.Print("Live data differs in " .. plural(s.differences.addonCount, "addon") .. ". This may be settings or runtime data; /wtfix diff lists the variables.")
    end
    if s.warnings > 0 then
        ns.Print("Restore warnings: " .. tostring(s.warnings))
    end
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
    ns.Print("One differing path per variable is shown. No values are printed; no fields are excluded from Save or Restore.")
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
