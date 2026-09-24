local _, ns = ...
ns.bridgeProtocol = 1
-- Never consume an old in-runtime bootstrap left by a previous installation.
WTFIX_BOOTSTRAP = nil

local function reject(code, reason)
    ns.preparation = { ready = false, code = code, reason = reason }
    ns.diskConfig, ns.diskSnapshot = nil, nil
    ns.diskReadObserved = false
    WTFIX_BOOTSTRAP = nil
    return ns.preparation
end

-- Forever's saved native identity uses spaces where its directory uses hyphens,
-- and its native realm ID is not the WTF realm-directory number. Never equate
-- those IDs. Match only a unique directory-backed character name.
local function normalizeName(value) return tostring(value or ""):gsub(" ", ""):gsub("%-", "") end

function ns.InitializePreparation()
    if ns.preparation then return ns.preparation end
    local p = WTFIX_PREPARATION
    if type(p) ~= "table" then return reject("ABSENT", "Run the WTFix setup tool with WoW closed to prepare recovery.") end
    if p.protocol ~= ns.bridgeProtocol then return reject("PROTOCOL", "Update the WTFix runtime and setup tool to compatible versions, then run setup.") end
    if type(p.id) ~= "string" or not p.id:match("^%x+$") or #p.id ~= 32
        or p.binding ~= "unique-character-name" or type(p.characters) ~= "table"
        or type(p.bootstrap) ~= "function" then
        return reject("METADATA", "Preparation metadata is invalid. Run the setup tool again.")
    end
    if p.completed ~= true then return reject("INCOMPLETE", "The preparation companion did not finish loading. Run setup again.") end
    local e = p.evidence
    if type(e) ~= "table" or e.protocol ~= ns.bridgeProtocol or e.id ~= p.id then
        return reject("BRIDGE_ID", "The disk bridge is missing or belongs to different preparation. Run setup again.")
    end
    if p.diskConfig ~= nil and type(p.diskConfig) ~= "table" then return reject("DISK", "The disk configuration is invalid. Run setup again.") end
    if p.diskSnapshot ~= nil and not ns.IsSnapshotValid(p.diskSnapshot) then return reject("DISK", "The disk snapshot is invalid. Run setup again.") end
    if type(p.diskConfig) ~= "table" and not ns.IsSnapshotValid(p.diskSnapshot) and p.legacyObserved ~= true then
        return reject("DISK", "The current snapshot file was not read. Run setup again.")
    end
    local name = UnitName and UnitName("player")
    local matches, matchedCharacter = 0, nil
    for _, character in pairs(p.characters) do
        if type(character) ~= "table" or type(character.name) ~= "string" or character.name == ""
            or type(character.realm) ~= "string" or character.realm == "" then
            return reject("METADATA", "The prepared character roster is invalid. Run setup again.")
        end
        if normalizeName(character.name) == "" then return reject("METADATA", "Invalid prepared character name. Run setup again.") end
        if name and normalizeName(character.name) == normalizeName(name) then
            matches = matches + 1
            matchedCharacter = { realm = character.realm, name = character.name }
        end
    end
    if matches ~= 1 then return reject("CHARACTER", "This character name is not uniquely prepared. Exit WoW and run the setup tool for the correct account.") end
    local ok = pcall(p.bootstrap, ns)
    local b = WTFIX_BOOTSTRAP
    if not ok or type(b) ~= "table" or b.generated ~= true or type(b.targets) ~= "table"
        or type(b.fallback) ~= "table" or type(b.fallback.account) ~= "table"
        or type(b.fallback.characters) ~= "table" or type(b.warnings) ~= "table" then
        return reject("BOOTSTRAP", "Generated recovery data is invalid. Run setup again.")
    end
    for addon, target in pairs(b.targets) do
        if type(addon) ~= "string" or type(target) ~= "table" then return reject("BOOTSTRAP", "Invalid recovery manifest. Run setup again.") end
        for _, scope in ipairs({"account", "character"}) do
            if type(target[scope]) ~= "table" then return reject("BOOTSTRAP", "Invalid recovery manifest. Run setup again.") end
            for index, name in pairs(target[scope]) do
                if type(index) ~= "number" or index < 1 or index % 1 ~= 0 or type(name) ~= "string" or not name:match("^[%a_][%w_]*$") then
                    return reject("BOOTSTRAP", "Invalid recovery variable declaration. Run setup again.")
                end
            end
        end
    end
    ns.diskConfig, ns.diskSnapshot = p.diskConfig, p.diskSnapshot
    ns.diskReadObserved = true
    ns.diskSnapshotAtFileLoad = ns.DescribeSnapshot(p.diskSnapshot)
    ns.preparation = { ready = true, code = "READY", reason = "Prepared character name matched (account not verified)",
        binding = "unique-character-name", character = matchedCharacter }
    return ns.preparation
end

function ns.GetPreparationState()
    return ns.preparation or {ready=false, code="NOT_CHECKED", reason="Preparation has not been checked yet."}
end

function ns.CanSave() return ns.GetPreparationState().ready end
function ns.CanRestore() return ns.CanSave() and ns.HasSnapshot() end

function ns.PrepareRestore()
    if not ns.CanRestore() then return false, "A verified preparation and valid snapshot are required." end
    ns.pendingReload = "restore"
    return true
end
