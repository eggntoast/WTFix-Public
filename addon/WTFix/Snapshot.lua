local _, ns = ...

local MAX_DEPTH = 128
local MAX_NODES = 250000

local function copyValue(value, state, depth)
    local valueType = type(value)
    if valueType == "nil" or valueType == "boolean" or valueType == "number" or valueType == "string" then
        return true, value
    end
    if valueType ~= "table" then
        return false, nil, "unsupported value type: " .. valueType
    end
    if depth > MAX_DEPTH then return false, nil, "maximum table depth exceeded" end
    if state.visiting[value] then return false, nil, "cyclic table detected" end
    if state.copied[value] then return true, state.copied[value] end

    state.nodes = state.nodes + 1
    if state.nodes > MAX_NODES then return false, nil, "snapshot is too large" end

    local result = {}
    state.visiting[value] = true
    state.copied[value] = result

    for key, child in pairs(value) do
        local kt = type(key)
        if kt ~= "string" and kt ~= "number" and kt ~= "boolean" then
            state.visiting[value] = nil
            state.copied[value] = nil
            return false, nil, "unsupported table key type: " .. kt
        end
        local ok, copied, err = copyValue(child, state, depth + 1)
        if not ok then
            state.visiting[value] = nil
            state.copied[value] = nil
            return false, nil, err
        end
        result[key] = copied
    end

    state.visiting[value] = nil
    return true, result
end

function ns.DeepCopy(value)
    return copyValue(value, { visiting = {}, copied = {}, nodes = 0 }, 0)
end

local function childPath(path, key)
    if type(key) == "string" and key:match("^[%a_][%w_]*$") then
        return path .. "." .. key:sub(1, 80)
    end
    if type(key) == "number" then return path .. "[" .. tostring(key) .. "]" end
    -- Do not print arbitrary chat text, hyperlinks or other data used as keys.
    return path .. "[" .. type(key) .. " key]"
end

local function firstDifference(a, b, path, seen, depth)
    if type(a) ~= type(b) then return path end
    if type(a) ~= "table" then return a ~= b and path or nil end
    seen = seen or {}
    depth = depth or 0
    if seen[a] == b then return nil end
    -- A snapshot has bounded depth; an unexpectedly deep live structure cannot
    -- match it. Keep diagnostics safe even for malformed live addon tables.
    if depth > MAX_DEPTH then return path end
    seen[a] = b
    for key, value in pairs(a) do
        local difference = firstDifference(value, rawget(b, key), childPath(path, key), seen, depth + 1)
        if difference then return difference end
    end
    for key in pairs(b) do
        if rawget(a, key) == nil then return childPath(path, key) end
    end
    return nil
end

function ns.EntryFromValue(value)
    if value == nil then return true, { state = "nil" } end
    local ok, copied, err = ns.DeepCopy(value)
    if not ok then return false, nil, err end
    return true, { state = "value", value = copied }
end

function ns.CopyEntryValue(entry)
    if type(entry) ~= "table" then return false, nil, "invalid entry" end
    if entry.state == "nil" then return true, nil end
    if entry.state ~= "value" then return false, nil, "invalid entry state" end
    return ns.DeepCopy(entry.value)
end

local function ensureSnapshot(candidate)
    candidate.schema = ns.schema
    candidate.generation = tonumber(candidate.generation) or 0
    candidate.createdAt = tonumber(candidate.createdAt) or 0
    candidate.createdByVersion = candidate.createdByVersion or ns.version
    if type(candidate.account) ~= "table" then candidate.account = {} end
    if type(candidate.account.addons) ~= "table" then candidate.account.addons = {} end
    if type(candidate.characters) ~= "table" then candidate.characters = {} end
    if type(candidate.manifest) ~= "table" then candidate.manifest = {} end
end

function ns.GetNativeSnapshot()
    if ns.IsSnapshotValid(WTFIX_SNAPSHOT_DB) then return WTFIX_SNAPSHOT_DB end
    return nil
end

function ns.GetBootstrapSnapshot()
    local snapshot = type(WTFIX_BOOTSTRAP) == "table" and WTFIX_BOOTSTRAP.snapshot or nil
    if ns.IsSnapshotValid(snapshot) then return snapshot end
    return nil
end

function ns.GetAuthoritativeSnapshot()
    if not ns.GetPreparationState().ready then return nil, "none" end
    -- Current in-memory/native wins ties, then the fresh disk read, then the
    -- static launcher copy. Save can therefore advance beyond both inputs.
    local winner, source = ns.GetNativeSnapshot(), "native"
    local disk = ns.IsSnapshotValid(ns.diskSnapshot) and ns.diskSnapshot or nil
    if disk and (not winner or disk.generation > winner.generation) then winner, source = disk, "disk" end
    local bootstrap = ns.GetBootstrapSnapshot()
    if bootstrap and (not winner or bootstrap.generation > winner.generation) then winner, source = bootstrap, "bootstrap" end
    return winner, winner and source or "none"
end

local function copyManifest()
    local manifest = {}
    for addon, target in pairs(ns.GetTargets()) do
        local account, character = {}, {}
        for i, name in ipairs(type(target.account) == "table" and target.account or {}) do account[i] = name end
        for i, name in ipairs(type(target.character) == "table" and target.character or {}) do character[i] = name end
        manifest[addon] = { account = account, character = character }
    end
    return manifest
end

local function updateScope(candidateAddons, addon, names, warnings)
    if type(names) ~= "table" or #names == 0 then return end
    local previous = candidateAddons[addon]
    local record = type(previous) == "table" and previous or {}
    record.addonVersion = ns.GetAddonVersion(addon)
    if type(record.entries) ~= "table" then record.entries = {} end

    for _, variableName in ipairs(names) do
        local ok, entry, err = ns.EntryFromValue(_G[variableName])
        if ok then
            record.entries[variableName] = entry
        else
            warnings[#warnings + 1] = addon .. ": " .. variableName .. " (" .. tostring(err) .. ")"
        end
    end
    candidateAddons[addon] = record
end

function ns.SaveCurrentSettings()
    if not ns.CanSave() then
        return false, nil, ns.GetPreparationState().reason
    end
    local old = ns.GetAuthoritativeSnapshot()
    local candidate
    if old then
        local ok, copied, err = ns.DeepCopy(old)
        if not ok then return false, nil, "could not clone current snapshot: " .. tostring(err) end
        candidate = copied
    else
        candidate = {}
    end

    ensureSnapshot(candidate)
    local warnings = {}
    local now = ns.Now()
    local nextGeneration = math.max(tonumber(candidate.generation) or 0, 0) + 1
    candidate.generation = nextGeneration
    candidate.createdAt = now
    candidate.createdByVersion = ns.version
    candidate.manifest = copyManifest()
    candidate.account.generation = nextGeneration
    candidate.account.savedAt = now
    if type(candidate.account.addons) ~= "table" then candidate.account.addons = {} end

    local characterKey = ns.GetCharacterKey()
    if characterKey and type(candidate.characters[characterKey]) ~= "table" then candidate.characters[characterKey] = {} end
    local characterRecord = characterKey and candidate.characters[characterKey] or nil
    if characterRecord then
        characterRecord.generation = nextGeneration
        characterRecord.savedAt = now
        if type(characterRecord.addons) ~= "table" then characterRecord.addons = {} end
    end

    local capturedAddons = 0
    for addon, target in pairs(ns.GetTargets()) do
        if ns.IsProtectedAddon(addon) and ns.IsAddonLoaded(addon) then
            capturedAddons = capturedAddons + 1
            updateScope(candidate.account.addons, addon, target.account, warnings)
            if characterRecord then updateScope(characterRecord.addons, addon, target.character, warnings) end
        end
    end

    ns.lastSaveResult = {
        generation = nextGeneration,
        warnings = warnings,
        capturedAddons = capturedAddons,
        characterKey = characterKey,
    }

    if #warnings > 0 then
        return false, ns.lastSaveResult,
            "snapshot was not saved because " .. tostring(#warnings) .. " protected value(s) could not be copied"
    end

    WTFIX_SNAPSHOT_DB = candidate
    return true, ns.lastSaveResult
end

function ns.HasSnapshot()
    return ns.GetAuthoritativeSnapshot() ~= nil
end

function ns.GetLiveDifferences()
    local result = { addons = {}, variables = {}, addonCount = 0 }
    local snapshot = ns.GetAuthoritativeSnapshot()
    if not snapshot then return result end
    local charKey = ns.GetCharacterKey()
    local charRecord = charKey and snapshot.characters and snapshot.characters[charKey] or nil

    for addon, target in pairs(ns.GetTargets()) do
        if ns.IsProtectedAddon(addon) and ns.IsAddonLoaded(addon) then
            local accountRecord = snapshot.account and snapshot.account.addons and snapshot.account.addons[addon]
            local characterAddon = charRecord and charRecord.addons and charRecord.addons[addon]
            local scopes = {
                { record = accountRecord, names = target.account, name = "account" },
                { record = characterAddon, names = target.character, name = "character" },
            }
            for _, scope in ipairs(scopes) do
                for _, variableName in ipairs(type(scope.names) == "table" and scope.names or {}) do
                    local entry = scope.record and scope.record.entries and scope.record.entries[variableName]
                    if entry then
                        local difference
                        if entry.state == "nil" and _G[variableName] ~= nil then
                            difference = variableName
                        elseif entry.state == "value" then
                            difference = firstDifference(_G[variableName], entry.value, variableName)
                        end
                        if difference then
                            if not result.addons[addon] then result.addonCount = result.addonCount + 1 end
                            result.addons[addon] = true
                            result.variables[#result.variables + 1] = {
                                addon = addon, variable = variableName, scope = scope.name, path = difference,
                            }
                        end
                    end
                end
            end
        end
    end
    table.sort(result.variables, function(a, b)
        return a.addon .. "/" .. a.scope .. "/" .. a.variable < b.addon .. "/" .. b.scope .. "/" .. b.variable
    end)
    return result
end

function ns.LiveDiffersFromSnapshot()
    return #ns.GetLiveDifferences().variables > 0
end
