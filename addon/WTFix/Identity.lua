local _, ns = ...

-- Qualification only. These functions never initialize preparation, apply
-- SavedVariables, choose snapshot generations, or write a migration/binding.
local function public(value)
    return not (type(issecretvalue) == "function" and issecretvalue(value))
end
local function name(value)
    return public(value) and type(value) == "string" and value ~= ""
        and value ~= "Unknown" and value ~= UNKNOWNOBJECT and value ~= UNKNOWN
        and not value:find("[%c]")
end
-- A directory hyphen represents the separator, not permission to erase name
-- boundaries (Ann-Abe must never qualify as Anna-Be).
local function normalize(value) return (value:gsub("%-", " "):gsub(" +", " "):match("^ *(.-) *$")) end
local function call(fn, ...)
    if type(fn) ~= "function" then return nil end
    local ok, a, b = pcall(fn, ...)
    if ok and public(a) and public(b) then return a, b end
end
local function fullName(first, second, regional)
    if not name(first) then return nil end
    if not regional then return first, first end -- second return is normally a realm
    local combined = first
    if name(second) then
        -- Some Forever builds return the combined name in the first slot.
        local spaceSuffix, dashSuffix = " " .. second, "-" .. second
        if first:sub(-#spaceSuffix) ~= spaceSuffix and first:sub(-#dashSuffix) ~= dashSuffix then
            combined = first .. " " .. second
        end
    end
    local firstPart, surname = combined:match("^([^ %-]+)[ %-]+(.+)$")
    if not name(firstPart) or not name(surname) then return nil end
    return firstPart .. " " .. surname, firstPart
end

function ns.ObservePlayerIdentity()
    local regional = call(RegionalUniqueNamesEnabled) == true
    local first, second = call(UnitNameUnmodified, "player")
    if not name(first) then first, second = call(UnitName, "player") end
    local unitFull, firstPart = fullName(first, second, regional)
    local guid = call(UnitGUID, "player")
    if type(guid) ~= "string" or not guid:match("^Player%-%d+%-%x+$") then guid = nil end
    local guidFull, guidFirst
    if guid and type(GetPlayerInfoByGUID) == "function" then
        local lookedUp = call(function()
            local _, _, _, _, _, result = GetPlayerInfoByGUID(guid)
            return result
        end)
        guidFull, guidFirst = fullName(lookedUp, nil, regional)
    end
    if unitFull and guidFull and normalize(unitFull) ~= normalize(guidFull) then
        return {ready=false, code="IDENTITY_CONFLICT", guid=guid}
    end
    local resolved = unitFull or guidFull
    if not resolved then return {ready=false, code="IDENTITY_PENDING", guid=guid, regional=regional} end
    return {ready=true, code="IDENTITY_AVAILABLE", fullName=resolved,
        firstName=firstPart or guidFirst, guid=guid, regional=regional,
        source=unitFull and "unit-name" or "player-guid-name"}
end

function ns.QualifyPreparedCharacter(characters, identity)
    if not identity.ready then return nil, identity.code end
    if type(characters) ~= "table" then return nil, "METADATA" end
    local found
    for _, row in pairs(characters) do
        if type(row) ~= "table" or not name(row.name) or not name(row.realm) then return nil, "METADATA" end
        if normalize(row.name) == normalize(identity.fullName) then
            if found then return nil, "CHARACTER_AMBIGUOUS" end
            found = {realm=row.realm, name=row.name}
        end
    end
    return found, found and "CHARACTER_MATCHED" or "CHARACTER_NOT_PREPARED"
end

function ns.QualifyCharacterCheckpointKey(snapshot, identity, realm, confirmedBinding)
    if not identity.ready or type(realm) ~= "string" or realm == "" then return nil, "IDENTITY_PENDING" end
    local canonical = realm .. "/" .. identity.fullName
    local records = type(snapshot) == "table" and snapshot.characters
    if type(records) ~= "table" then records = {} end
    local candidates = {}
    for key, record in pairs(records) do
        if type(key) == "string" and type(record) == "table" then
            local storedRealm, storedName = key:match("^([^/]+)/(.+)$")
            if storedRealm == realm and (normalize(storedName) == normalize(identity.fullName)
                or (identity.regional and storedName == identity.firstName)) then
                candidates[#candidates + 1] = {key=key, generation=tonumber(record.generation) or 0,
                    full=normalize(storedName) == normalize(identity.fullName)}
            end
        end
    end
    table.sort(candidates, function(a,b) return a.key < b.key end)
    if confirmedBinding ~= nil then
        -- This parameter is an explicitly confirmed association, never inferred
        -- from a matching first name, newest generation, or the last login.
        if type(confirmedBinding) ~= "table" or not identity.guid
            or confirmedBinding.guid ~= identity.guid or confirmedBinding.fullName ~= identity.fullName
            or confirmedBinding.realm ~= realm then return nil, "BINDING_CONFLICT", candidates end
        for _, choice in ipairs(candidates) do
            if choice.key == confirmedBinding.key then return choice.key, "CONFIRMED_KEY", candidates end
        end
        if #candidates == 0 and confirmedBinding.hasCheckpoint == false and confirmedBinding.key == canonical then
            return canonical, "NEW_CHARACTER", candidates
        end
        return nil, "BOUND_RECORD_MISSING", candidates
    end
    if #candidates == 0 then return canonical, "NEW_CHARACTER", candidates end
    if #candidates == 1 and candidates[1].full then return candidates[1].key, "EXACT_FULL_NAME", candidates end
    return nil, "KEY_CONFIRMATION_REQUIRED", candidates
end
