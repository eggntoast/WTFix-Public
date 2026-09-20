local _, ns = ...
if type(WTFIX_PREPARATION) == "table" then
    WTFIX_PREPARATION.diskConfig = WTFIX_DB
    WTFIX_PREPARATION.diskSnapshot = WTFIX_SNAPSHOT_DB
    WTFIX_PREPARATION.evidence = WTFIX_BRIDGE_EVIDENCE
    WTFIX_PREPARATION.legacyObserved = type(WTFIX_MIRROR_DB) == "table"
    WTFIX_PREPARATION.completed = true
end
WTFIX_DB, WTFIX_SNAPSHOT_DB, WTFIX_MIRROR_DB, WTFIX_BRIDGE_EVIDENCE = ns.config, ns.snapshot, ns.legacy, ns.evidence
ns.config, ns.snapshot, ns.legacy, ns.evidence = nil, nil, nil, nil
