local addonName, ns = ...

ns.version = "0.9.0"
ns.author = "NS"
ns.addonName = addonName
ns.media = "Interface\\AddOns\\WTFix\\Media\\"
ns.brandTitle = "|cffc9f3ffW|r|cffafeaffT|r|cff8ee1ffF|r|cff70d7ffi|r|cff50ccffx|r"
ns.schema = 1

local function safeString(value)
    if value == nil then return "" end
    return tostring(value)
end

local function ensureConfig()
    if ns.GetPreparationState().ready and type(ns.diskConfig) == "table" then
        -- Keep the table referenced by Broker/UI at file load; adopt verified
        -- configuration only after the own ADDON_LOADED readiness check.
        if type(WTFIX_DB) ~= "table" then WTFIX_DB = {} end
        for key in pairs(WTFIX_DB) do WTFIX_DB[key] = nil end
        for key, value in pairs(ns.diskConfig) do WTFIX_DB[key] = value end
    end
    if type(WTFIX_DB) ~= "table" then
        local bootstrapConfig = type(WTFIX_BOOTSTRAP) == "table" and WTFIX_BOOTSTRAP.config or nil
        WTFIX_DB = type(bootstrapConfig) == "table" and bootstrapConfig or {}
    end
    WTFIX_DB.schema = ns.schema
    if type(WTFIX_DB.minimap) ~= "table" then WTFIX_DB.minimap = {} end
    if WTFIX_DB.minimap.hide == nil then WTFIX_DB.minimap.hide = false end
    if WTFIX_DB.minimap.minimapPos == nil then WTFIX_DB.minimap.minimapPos = 220 end
    if WTFIX_DB.chatStatus == nil then WTFIX_DB.chatStatus = true end
    if type(WTFIX_DB.protectedAddons) ~= "table" then WTFIX_DB.protectedAddons = {} end
    if type(WTFIX_DB.ui) ~= "table" then WTFIX_DB.ui = {} end
end

ensureConfig()
ns.EnsureConfig = ensureConfig

function ns.GetCharacterKey()
    local name = UnitName and UnitName("player") or nil
    if not name or name == "" then return nil end
    local realmID = GetRealmID and GetRealmID() or nil
    if realmID then return safeString(realmID) .. "/" .. name end
    local realmName = GetRealmName and GetRealmName() or ""
    return safeString(realmName) .. "/" .. name
end

function ns.NormalizeRealm(value)
    value = string.lower(safeString(value))
    return (value:gsub("[%s%-_]", ""))
end

function ns.GetBootstrapCharacterRecord()
    local bootstrap = type(WTFIX_BOOTSTRAP) == "table" and WTFIX_BOOTSTRAP or nil
    local chars = bootstrap and bootstrap.fallback and bootstrap.fallback.characters
    if type(chars) ~= "table" then return nil end

    local name = UnitName and UnitName("player") or ""
    local realmID = GetRealmID and safeString(GetRealmID()) or ""
    local realmName = GetRealmName and safeString(GetRealmName()) or ""
    for _, record in pairs(chars) do
        if type(record) == "table" and record.characterName == name then
            local folder = safeString(record.realmFolder)
            if folder == realmID or ns.NormalizeRealm(folder) == ns.NormalizeRealm(realmName) then
                return record
            end
        end
    end
    return nil
end

function ns.CountTargets()
    local count = 0
    local targets = type(WTFIX_BOOTSTRAP) == "table" and WTFIX_BOOTSTRAP.targets or nil
    for _ in pairs(type(targets) == "table" and targets or {}) do count = count + 1 end
    return count
end

function ns.GetTargets()
    local targets = type(WTFIX_BOOTSTRAP) == "table" and WTFIX_BOOTSTRAP.targets or nil
    return type(targets) == "table" and targets or {}
end

function ns.IsProtectedAddon(addon)
    return WTFIX_DB.protectedAddons[addon] ~= false
end

function ns.IsAddonLoaded(addon)
    if C_AddOns and C_AddOns.IsAddOnLoaded then
        local ok, loaded = pcall(C_AddOns.IsAddOnLoaded, addon)
        if ok then return loaded == true end
    end
    if IsAddOnLoaded then
        local ok, loaded = pcall(IsAddOnLoaded, addon)
        if ok then return loaded == true or loaded == 1 end
    end
    return true
end

function ns.GetAddonVersion(addon)
    local value
    if C_AddOns and C_AddOns.GetAddOnMetadata then
        local ok, result = pcall(C_AddOns.GetAddOnMetadata, addon, "Version")
        if ok then value = result end
    elseif GetAddOnMetadata then
        local ok, result = pcall(GetAddOnMetadata, addon, "Version")
        if ok then value = result end
    end
    return value and tostring(value) or nil
end

function ns.Now()
    if GetServerTime then
        local ok, value = pcall(GetServerTime)
        if ok and type(value) == "number" then return value end
    end
    if time then
        local ok, value = pcall(time)
        if ok and type(value) == "number" then return value end
    end
    return 0
end

function ns.Print(message)
    print("|cff63d7ffWTFix|r " .. tostring(message or ""))
end

SLASH_WTFIX1 = "/wtfix"
SlashCmdList.WTFIX = function(message)
    message = string.lower((message or ""):match("^%s*(.-)%s*$") or "")
    if message == "status" then
        if ns.PrintStatus then ns.PrintStatus() else ns.Print("status is not ready yet") end
        return
    end
    if message == "diff" then
        if ns.PrintDifferences then ns.PrintDifferences() else ns.Print("comparison is not ready yet") end
        return
    end
    if message == "check" then
        if ns.PrintCaptureCheck then ns.PrintCaptureCheck() else ns.Print("capture check is not ready yet") end
        return
    end
    if message == "" then
        if ns.SettingsCompat and ns.SettingsCompat.Toggle then ns.SettingsCompat.Toggle() else ns.Print("settings are not ready yet") end
        return
    end
    ns.Print("use /wtfix, /wtfix status, /wtfix diff or /wtfix check")
end
