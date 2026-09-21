local addonName, ns = ...

local function rawFallback(tableValue, name)
    if type(tableValue) ~= "table" then return false end
    if rawget(tableValue, name) == nil then return false end
    local ok, copied, err = ns.DeepCopy(tableValue[name])
    if not ok then return false, err end
    _G[name] = copied
    return true
end

local function applyEntry(variableName, entry)
    local ok, value, err = ns.CopyEntryValue(entry)
    if not ok then return false, err end
    _G[variableName] = value
    return true
end

local function restoreProtectedState()
    ns.nativeSnapshotAtRestore = ns.DescribeSnapshot(WTFIX_SNAPSHOT_DB)
    local preparation = ns.InitializePreparation()
    if not preparation.ready then
        ns.restoreStats = { launcherDetected=false, warnings={}, protectedAddons=0, snapshotSource="none" }
        return
    end
    ns.EnsureConfig()
    if ns.Broker and ns.Broker.icon and ns.Broker.icon.Refresh then ns.Broker.icon:Refresh("WTFix", WTFIX_DB.minimap) end
    local snapshot, snapshotSource = ns.GetAuthoritativeSnapshot()
    local bootstrap = type(WTFIX_BOOTSTRAP) == "table" and WTFIX_BOOTSTRAP or {}

    if snapshot and snapshotSource ~= "native" then
        local ok, copied, err = ns.DeepCopy(snapshot)
        if ok then
            WTFIX_SNAPSHOT_DB = copied
            snapshot = copied
        else
            snapshot = nil
            snapshotSource = "none"
            ns.bootstrapSnapshotError = tostring(err)
        end
    end

    local fallbackAccount = bootstrap.fallback and bootstrap.fallback.account or {}
    local fallbackCharacterRecord = ns.GetBootstrapCharacterRecord()
    local fallbackCharacter = fallbackCharacterRecord and fallbackCharacterRecord.addons or {}
    local characterKey = ns.GetCharacterKey()
    local snapshotCharacter = snapshot and characterKey and snapshot.characters and snapshot.characters[characterKey] or nil

    local stats = {
        snapshotSource = snapshotSource,
        snapshotGeneration = snapshot and (tonumber(snapshot.generation) or 0) or 0,
        snapshotVariables = 0,
        fallbackVariables = 0,
        fallbackDetails = {},
        missingVariables = 0,
        missingDetails = {},
        warnings = {},
        protectedAddons = 0,
        launcherDetected = bootstrap.generated == true,
    }
    for _, warning in ipairs(bootstrap.warnings or {}) do
        stats.warnings[#stats.warnings + 1] = warning
    end

    for addon, target in pairs(ns.GetTargets()) do
        if ns.IsProtectedAddon(addon) then
            stats.protectedAddons = stats.protectedAddons + 1
            local snapAccount = snapshot and snapshot.account and snapshot.account.addons and snapshot.account.addons[addon]
            local snapCharacter = snapshotCharacter and snapshotCharacter.addons and snapshotCharacter.addons[addon]
            local fallAccount = type(fallbackAccount[addon]) == "table" and fallbackAccount[addon] or nil
            local fallCharacter = type(fallbackCharacter[addon]) == "table" and fallbackCharacter[addon] or nil

            local scopes = {
                { name = "account", names = target.account, snapshot = snapAccount, fallback = fallAccount },
                { name = "character", names = target.character, snapshot = snapCharacter, fallback = fallCharacter },
            }

            for _, scope in ipairs(scopes) do
                for _, variableName in ipairs(type(scope.names) == "table" and scope.names or {}) do
                    local entry = scope.snapshot and scope.snapshot.entries and scope.snapshot.entries[variableName]
                    if entry then
                        local ok, err = applyEntry(variableName, entry)
                        if ok then
                            stats.snapshotVariables = stats.snapshotVariables + 1
                        else
                            stats.warnings[#stats.warnings + 1] = addon .. ": " .. variableName .. " (" .. tostring(err) .. ")"
                        end
                    else
                        local ok, err = rawFallback(scope.fallback, variableName)
                        if ok then
                            stats.fallbackVariables = stats.fallbackVariables + 1
                            stats.fallbackDetails[#stats.fallbackDetails + 1] = { addon=addon, scope=scope.name, variable=variableName }
                        else
                            if err then
                                stats.warnings[#stats.warnings + 1] = addon .. ": " .. variableName .. " (" .. tostring(err) .. ")"
                            end
                            stats.missingVariables = stats.missingVariables + 1
                            stats.missingDetails[#stats.missingDetails + 1] = {
                                addon = addon, scope = scope.name, variable = variableName,
                                reason = err or "no snapshot entry or usable bootstrap fallback at recovery",
                            }
                        end
                    end
                end
            end
        end
    end

    ns.restoreStats = stats
    ns.bootstrapGenerated = bootstrap.generated == true
end

local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:SetScript("OnEvent", function(self, event, loadedAddon)
    if event ~= "ADDON_LOADED" or loadedAddon ~= addonName then return end
    self:UnregisterEvent("ADDON_LOADED")
    restoreProtectedState()
end)
