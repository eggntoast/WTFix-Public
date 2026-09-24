local _, ns = ...
WTFIX_PREPARATION = nil
ns.config, ns.snapshot, ns.legacy, ns.evidence = WTFIX_DB, WTFIX_SNAPSHOT_DB, WTFIX_MIRROR_DB, WTFIX_BRIDGE_EVIDENCE
WTFIX_DB, WTFIX_SNAPSHOT_DB, WTFIX_MIRROR_DB, WTFIX_BRIDGE_EVIDENCE = nil, nil, nil, nil
