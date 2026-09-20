local _, ns = ...

-- This runs before BootstrapData/Core. Keep evidence of the native loader's
-- input before defaults or recovery can obscure it.
function ns.DescribeSnapshot(value)
    if type(value) ~= "table" then return type(value) end
    return "schema " .. tostring(value.schema) .. ", generation " .. tostring(value.generation)
end
ns.nativeSnapshotAtFileLoad = ns.DescribeSnapshot(WTFIX_SNAPSHOT_DB)
ns.nativeConfigAtFileLoad = type(WTFIX_DB)

-- Read the data subset emitted by WoW's SavedVariables serializer. Never execute
-- imported text: a damaged primary/backup must not prevent the runtime loading.
function ns.ReadSavedVariables(source)
    if type(source) ~= "string" or #source > 64 * 1024 * 1024 then
        return nil, "SavedVariables input exceeds the supported size"
    end
    local pos, count = 1, 0
    local function fail(message) error(message .. " at byte " .. pos, 0) end
    local function skip()
        while true do
            local _, last = source:find("^%s+", pos)
            if last then pos = last + 1 end
            if source:sub(pos, pos + 1) ~= "--" then return end
            local newline = source:find("\n", pos + 2, true)
            pos = newline and newline + 1 or #source + 1
        end
    end
    local function take(text)
        skip()
        if source:sub(pos, pos + #text - 1) ~= text then return false end
        pos = pos + #text
        return true
    end
    local function expect(text) if not take(text) then fail("expected " .. text) end end
    local function identifier()
        skip()
        local value = source:match("^[_%a][_%w]*", pos)
        if value then pos = pos + #value end
        return value
    end
    local escapes = { a = "\a", b = "\b", f = "\f", n = "\n", r = "\r", t = "\t", v = "\v" }
    local function quoted()
        local quote = source:sub(pos, pos)
        pos = pos + 1
        local result = {}
        while pos <= #source do
            local c = source:sub(pos, pos)
            pos = pos + 1
            if c == quote then return table.concat(result) end
            if c == "\n" or c == "\r" then fail("unescaped newline in string") end
            if c == "\\" then
                c = source:sub(pos, pos)
                pos = pos + 1
                if c:match("%d") then
                    local digits = c
                    for _ = 1, 2 do
                        local nextChar = source:sub(pos, pos)
                        if not nextChar:match("%d") then break end
                        digits = digits .. nextChar
                        pos = pos + 1
                    end
                    local byte = tonumber(digits)
                    if byte > 255 then fail("invalid string escape") end
                    c = string.char(byte)
                elseif c == "\r" or c == "\n" then
                    if c == "\r" and source:sub(pos, pos) == "\n" then pos = pos + 1 end
                    c = "\n"
                elseif escapes[c] then
                    c = escapes[c]
                elseif c ~= "\\" and c ~= '"' and c ~= "'" then
                    fail("unsupported string escape")
                end
            end
            result[#result + 1] = c
        end
        fail("unterminated string")
    end
    local value
    value = function(depth)
        skip()
        count = count + 1
        if depth > 128 or count > 1000000 then fail("SavedVariables complexity limit exceeded") end
        local c = source:sub(pos, pos)
        if c == '"' or c == "'" then return quoted() end
        if c == "{" then
            pos = pos + 1
            local result, index = {}, 1
            while not take("}") do
                local key, child
                if take("[") then
                    key = value(depth + 1)
                    if key == nil or type(key) == "table" then fail("invalid table key") end
                    expect("]")
                    expect("=")
                    child = value(depth + 1)
                else
                    local start = pos
                    key = identifier()
                    if key and take("=") then
                        child = value(depth + 1)
                    else
                        pos = start
                        key, index = index, index + 1
                        child = value(depth + 1)
                    end
                end
                result[key] = child
                if not take(",") and not take(";") then expect("}"); return result end
            end
            return result
        end
        if c:match("[%d%+%-%.]") then
            local token = source:match("^[^%s,;}%]]+", pos)
            local number = token and tonumber(token)
            if not number or number ~= number or math.abs(number) == math.huge then fail("invalid number") end
            pos = pos + #token
            return number
        end
        local word = identifier()
        if word == "true" then return true end
        if word == "false" then return false end
        if word == "nil" then return nil end
        fail("expected serialized value")
    end
    local ok, result = pcall(function()
        local env = {}
        while true do
            skip()
            if pos > #source then return env end
            local name = identifier()
            if not name then fail("expected SavedVariables name") end
            expect("=")
            env[name] = value(0)
            take(";")
        end
    end)
    if ok then return result end
    return nil, result
end

function ns.IsSnapshotValid(snapshot)
    local function validAddons(addons)
        if type(addons) ~= "table" then return false end
        for name, record in pairs(addons) do
            if type(name) ~= "string" or type(record) ~= "table" or type(record.entries) ~= "table" then return false end
            for variable, entry in pairs(record.entries) do
                if type(variable) ~= "string" or type(entry) ~= "table" then return false end
                if entry.state ~= "nil" and (entry.state ~= "value" or entry.value == nil) then return false end
            end
        end
        return true
    end
    if not (type(snapshot) == "table" and snapshot.schema == 1
        and type(snapshot.generation) == "number" and snapshot.generation >= 0
        and snapshot.generation < math.huge and snapshot.generation % 1 == 0
        and type(snapshot.account) == "table" and validAddons(snapshot.account.addons)
        and type(snapshot.characters) == "table" and type(snapshot.manifest) == "table") then return false end
    for key, record in pairs(snapshot.characters) do
        if type(key) ~= "string" or type(record) ~= "table" or not validAddons(record.addons) then return false end
    end
    return true
end

function ns.ImportBootstrapSnapshot(env, filename)
    local boot = WTFIX_BOOTSTRAP
    if type(boot.config) ~= "table" and type(env.WTFIX_DB) == "table" then boot.config = env.WTFIX_DB end
    local candidate = env.WTFIX_SNAPSHOT_DB
    if ns.IsSnapshotValid(candidate) then
        if not ns.IsSnapshotValid(boot.snapshot) or candidate.generation > boot.snapshot.generation then
            boot.snapshot = candidate
            boot.snapshotFile = filename
        end
    elseif candidate ~= nil then
        boot.warnings[#boot.warnings + 1] = filename .. ": invalid protected snapshot"
    end
end
