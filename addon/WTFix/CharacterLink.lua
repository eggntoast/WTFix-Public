local _, ns = ...

-- Character links are configuration, not checkpoints. They contain no addon
-- values and never infer ownership from a first name or snapshot generation.
local fields = {"version", "guid", "fullName", "firstName", "regional", "realm", "key", "hasCheckpoint"}
local function sameLink(a, b)
    if type(a) ~= "table" or type(b) ~= "table" then return false end
    for _, field in ipairs(fields) do if a[field] ~= b[field] then return false end end
    return true
end
function ns.GetIdentityRealm()
    local value = GetRealmID and GetRealmID() or (GetRealmName and GetRealmName())
    return value ~= nil and tostring(value) or ""
end
local function readLink(config, guid)
    if type(config) ~= "table" or config.characterLinks == nil then return nil end
    if type(config.characterLinks) ~= "table" then return nil, "BINDING_CONFLICT" end
    local value = config.characterLinks[guid]
    if value == nil then return nil end
    if type(value) ~= "table" or value.version ~= 1 or value.guid ~= guid
        or type(value.fullName) ~= "string" or value.fullName == "" or value.fullName:find("[%c/]")
        or type(value.firstName) ~= "string" or value.firstName == ""
        or type(value.regional) ~= "boolean" or type(value.realm) ~= "string"
        or value.realm == "" or type(value.key) ~= "string" or type(value.hasCheckpoint) ~= "boolean" then return nil, "BINDING_CONFLICT" end
    if (value.regional and (value.fullName:match("^([^ %-]+) .+$") ~= value.firstName))
        or (not value.regional and value.firstName ~= value.fullName) then return nil, "BINDING_CONFLICT" end
    return value
end
function ns.CopyRecoveryConfig()
    local native = WTFIX_DB
    local ok, config = ns.DeepCopy(ns.configAdopted and native or ns.diskConfig or native)
    if not ok or type(config) ~= "table" then return false end
    if config.characterLinks ~= nil and type(config.characterLinks) ~= "table" then return false end
    if type(native) == "table" and native.characterLinks ~= nil then
        if type(native.characterLinks) ~= "table" then return false end
        config.characterLinks = config.characterLinks or {}
        for guid, link in pairs(native.characterLinks) do
            local existing = config.characterLinks[guid]
            if existing and not sameLink(existing, link) then return false end
            local copied, value = ns.DeepCopy(link)
            if not copied then return false end
            config.characterLinks[guid] = value
        end
    end
    return true, config
end
function ns.ResolveRecoveryIdentity(p)
    local observed = ns.ObservePlayerIdentity()
    if observed.code == "IDENTITY_CONFLICT" then return nil, nil, observed.code end
    local binding
    if observed.guid then
        local native, nativeError = readLink(WTFIX_DB, observed.guid)
        local disk, diskError = readLink(p.diskConfig, observed.guid)
        if nativeError or diskError or (native and disk and not sameLink(native, disk)) then
            return nil, nil, "BINDING_CONFLICT"
        end
        binding = native or disk
        if binding then
            for _, config in pairs({WTFIX_DB, p.diskConfig}) do
                if type(config) == "table" and type(config.characterLinks) == "table" then
                    for otherGUID, other in pairs(config.characterLinks) do
                        if otherGUID ~= observed.guid and type(other) == "table" and other.realm == binding.realm
                            and (other.key == binding.key or other.fullName == binding.fullName) then
                            return nil, nil, "BINDING_CONFLICT"
                        end
                    end
                end
            end
            if binding.realm ~= ns.GetIdentityRealm() or binding.regional ~= observed.regional
                or (observed.ready and (observed.fullName ~= binding.fullName or observed.firstName ~= binding.firstName)) then
                return nil, nil, "BINDING_CONFLICT"
            end
            if not observed.ready then
                observed = {ready=true, code="IDENTITY_AVAILABLE", source="confirmed-player-guid",
                    guid=observed.guid, fullName=binding.fullName, firstName=binding.firstName, regional=binding.regional}
            end
        end
    end
    if not observed.ready then return nil, nil, observed.code end
    -- A name reused by a different GUID must not bypass an existing association
    -- merely because the unit-name API happened to be available on this load.
    if observed.guid then
        for _, config in pairs({WTFIX_DB, p.diskConfig}) do
            if type(config) == "table" and type(config.characterLinks) == "table" then
                for guid, other in pairs(config.characterLinks) do
                    if guid ~= observed.guid and type(other) == "table" and other.realm == ns.GetIdentityRealm()
                        and other.fullName == observed.fullName then return nil, nil, "BINDING_CONFLICT" end
                end
            end
        end
    end
    return observed, binding
end

-- Called after the early restoration window has closed. Qualifying a name here
-- is useful for linking, but must NEVER reinject into initialized addon tables.
function ns.CheckIdentityAtLogin()
    local prior = ns.GetPreparationState()
    if prior.ready then
        local current = ns.ObservePlayerIdentity()
        local identity = prior.identity
        if not current.ready or not identity or current.fullName ~= identity.fullName
            or current.guid ~= identity.guid or current.regional ~= identity.regional then
            ns.preparation = {ready=false, code="IDENTITY_CONFLICT",
                reason="The login identity does not match early recovery. Do not Save; preserve the recovery files and report /wtfix status."}
        end
    elseif prior.code == "IDENTITY_PENDING" then
        ns.InitializePreparation(true)
    end
end

local function refreshPanel()
    if ns.Panel and ns.Panel.Refresh then ns.Panel:Refresh(false) end
end
local function choicesFor(context)
    if #context.choices > 0 then return context.choices end
    return {{key=context.key, generation=0}}
end
function ns.GetCharacterLinkOffer()
    -- A late command cannot turn an earlier rejection into early recovery.
    local prior = ns.GetPreparationState()
    if prior.code == "IDENTITY_CONFLICT" then return nil, prior.reason end
    if ns.pendingReload and ns.pendingReload ~= "identity" then return nil, "Complete the pending Save or Restore reload before linking." end
    ns.InitializePreparation(true)
    local context = ns.characterLinkContext
    local observed = ns.ObservePlayerIdentity()
    if not context or not observed.ready or not observed.guid
        or context.identity.guid ~= observed.guid or context.identity.fullName ~= observed.fullName then
        return nil, "A verified full name, player GUID and valid preparation are required. " .. ns.GetPreparationState().reason
    end
    local ok, offer = ns.DeepCopy(context)
    if not ok then return nil, "The character link could not be safely copied." end
    offer.choices = choicesFor(offer)
    return offer
end
function ns.ConfirmCharacterLink(offer, index)
    if type(offer) ~= "table" or type(index) ~= "number" or not offer.choices[index] then return false, "Invalid character link selection." end
    local current, err = ns.GetCharacterLinkOffer()
    if not current then return false, err end
    local choice = offer.choices[index]
    if not ns.CheckpointDataEqual(current, offer) then return false, "Recovery inputs changed. Run /wtfix bind again." end
    if current.binding and current.binding.key ~= choice.key then return false, "An existing link cannot be silently reassigned." end
    local identity = current.identity
    local link = {version=1, guid=identity.guid, fullName=identity.fullName, firstName=identity.firstName,
        regional=identity.regional, realm=current.realm, key=choice.key,
        hasCheckpoint=current.snapshot ~= nil and current.snapshot.characters[choice.key] ~= nil}
    -- Check both sources for another GUID already claiming this checkpoint.
    for _, config in pairs({WTFIX_DB, ns.diskConfig}) do
        if type(config) == "table" and type(config.characterLinks) == "table" then
            for guid, other in pairs(config.characterLinks) do
                if guid ~= identity.guid and type(other) == "table" and other.realm == link.realm
                    and (other.key == link.key or other.fullName == link.fullName) then
                    return false, "Another character is linked to that record. No data changed."
                end
            end
        end
    end
    -- Complete every fallible copy BEFORE modifying persistent globals. Preserve
    -- the selected whole checkpoint (including other characters) for disk write;
    -- do not capture live values, increment a generation, or apply addon globals.
    local okConfig, config = ns.CopyRecoveryConfig()
    local okSnapshot, snapshot = ns.DeepCopy(current.snapshot)
    if not okConfig or type(config) ~= "table" or not okSnapshot then return false, "Recovery storage could not be safely retained." end
    if config.characterLinks ~= nil and type(config.characterLinks) ~= "table" then return false, "Character link storage is invalid." end
    config.characterLinks = config.characterLinks or {}
    config.characterLinks[identity.guid] = link
    -- Keep the config object used by the broker/UI. No observer runs between
    -- these assignments; neither source snapshot nor any character record is edited.
    for key in pairs(WTFIX_DB) do WTFIX_DB[key] = nil end
    for key, value in pairs(config) do WTFIX_DB[key] = value end
    if current.source ~= "native" and snapshot then WTFIX_SNAPSHOT_DB = snapshot end
    ns.configAdopted = true
    ns.pendingReload = "identity"
    ns.preparation = {ready=false, code="RELOAD_REQUIRED", character=current.character,
        checkpointKey=choice.key, identity=identity,
        reason="Character linked. Reload once to recover before protected addons initialize. No new snapshot was saved."}
    refreshPanel()
    return true
end
function ns.NoteCharacterCheckpointSaved(key)
    local identity = ns.GetPreparationState().identity
    local links = type(WTFIX_DB) == "table" and WTFIX_DB.characterLinks
    local link = identity and identity.guid and type(links) == "table" and links[identity.guid]
    if type(link) == "table" and link.key == key then link.hasCheckpoint = true end
end
local function safeLabel(value) return tostring(value):gsub("|", "||"):gsub("[%c]", "?"):sub(1, 140) end
function ns.PrintCharacterLink(argument)
    local offer, err = ns.GetCharacterLinkOffer()
    if not offer then ns.Print(err); return end
    local index = tonumber(argument)
    if not index then
        ns.Print("Link " .. safeLabel(offer.identity.fullName) .. " to its checkpoint. No settings are captured or applied.")
        for i, choice in ipairs(offer.choices) do
            ns.Print(i .. ": " .. safeLabel(choice.key) .. " (character generation " .. choice.generation .. ")")
        end
        ns.Print("Use /wtfix bind NUMBER, then confirm. Choose the record you recognize, not simply the highest generation.")
        refreshPanel()
        return
    end
    local choice = offer.choices[index]
    if not choice or index % 1 ~= 0 then ns.Print("Invalid selection. Use /wtfix bind to list the available records."); return end
    if not ns.ShowConfirm then ns.Print("Open WTFix after login before linking this character."); return end
    ns.ShowConfirm("Link This Character", safeLabel(offer.identity.fullName) .. " -> " .. safeLabel(choice.key)
        .. "\nCharacter generation " .. choice.generation .. ".\nRetain this checkpoint and all other character records. No live settings will be saved. Reload afterward for recovery.", "Link Character", function()
        local ok, reason = ns.ConfirmCharacterLink(offer, index)
        if not ok then ns.Print(reason); return end
        ns.Print("Character linked; checkpoint unchanged. Reload for early recovery.")
        ns.ShowReloadRequired("identity")
    end)
end
