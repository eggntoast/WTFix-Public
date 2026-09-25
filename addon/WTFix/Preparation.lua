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
function ns.InitializePreparation(refresh)
    if ns.preparation and not refresh then return ns.preparation end
    ns.characterLinkContext = nil
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
    -- Transport evidence is distinct from character qualification. A pending
    -- name does not make a successfully read disk bridge disappear.
    ns.diskConfig, ns.diskSnapshot = p.diskConfig, p.diskSnapshot
    ns.diskReadObserved = true
    ns.diskSnapshotAtFileLoad = ns.DescribeSnapshot(p.diskSnapshot)
    local identity, binding, identityError = ns.ResolveRecoveryIdentity(p)
    if not identity then
        ns.preparation = {ready=false, code=identityError,
            reason=identityError == "IDENTITY_PENDING"
                and "Waiting for the character name. Recovery has not run."
                or "The stored character link conflicts with current identity. Recovery is blocked; /wtfix status."}
        return ns.preparation
    end
    local matchedCharacter, characterError = ns.QualifyPreparedCharacter(p.characters, identity)
    if not matchedCharacter then
        return reject(characterError, "This full character name is not uniquely prepared. Exit WoW and run the setup tool for the correct account.")
    end
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
    if not ns.CopyRecoveryConfig() then return reject("CONFIG", "Recovery configuration conflicts or cannot be safely copied. Preserve the recovery files; do not Save a replacement.") end
    local snapshot, source = ns.SelectRecoverySnapshot(WTFIX_SNAPSHOT_DB, p.diskSnapshot, b.snapshot)
    -- Never link or recover through a checkpoint that cannot be retained whole.
    local okSnapshot, snapshotCopy = ns.DeepCopy(snapshot)
    if not okSnapshot then return reject("SNAPSHOT", "The selected checkpoint cannot be safely copied. Preserve the recovery files and report /wtfix status.") end
    local realm = ns.GetIdentityRealm()
    local key, keyCode, choices = ns.QualifyCharacterCheckpointKey(snapshot, identity, realm, binding)
    if not key and keyCode ~= "KEY_CONFIRMATION_REQUIRED" then
        return reject(keyCode, "The linked checkpoint record is missing or inconsistent. Recovery is blocked; do not Save a replacement.")
    end
    ns.characterLinkContext = {identity=identity, character=matchedCharacter, realm=realm,
        key=key, choices=choices, snapshot=snapshotCopy, source=source, preparationID=p.id, binding=binding}
    local code = not key and "LINK_REQUIRED" or ((ns.pendingReload == "identity" or (ns.recoveryWindowClosed and not ns.recoveryPerformed)) and "RELOAD_REQUIRED" or "READY")
    ns.preparation = {ready=code == "READY", code=code,
        reason=code == "LINK_REQUIRED" and "Confirm this character's checkpoint with /wtfix bind. No settings have been restored."
            or code == "RELOAD_REQUIRED" and "Use /wtfix bind to link this character, then reload once for early recovery. No late recovery was performed."
            or "Prepared full character name matched (account not verified)",
        binding="unique-character-name", character=matchedCharacter, identity=identity, checkpointKey=key,
        characterLinked=binding ~= nil}

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
