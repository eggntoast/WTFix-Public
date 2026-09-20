# Preparation, ownership and limitations

## What the launcher does

With WoW closed, preparation checks runtime/bridge compatibility, selects the account, archives its existing Lua recovery inputs, prepares WTFix_Data and manages dependency entries in relevant addon TOCs. It then opens Battle.net on Forever Beta and displays successful completion. Dismiss the window with Enter, Ctrl+C or its close button.

Preparation does not need a resident helper. It does not modify WoW executables or inject code.

## Why there are two addons

- **WTFix** is the runtime, owned by its addon manager or manual installer.
- **WTFix_Data** is the launcher's companion, containing generated preparation and a `Disk` directory junction pointing to the selected account's SavedVariables directory.

The junction lets normal addon-file loading read the current WTFix snapshot file after reload, including when WoW replaces that file. Keep both addons enabled. Installing the runtime alone does not prepare the bridge.

The launcher also writes its own `WTFix_Bridge.lua` evidence marker beside the snapshot. Generated metadata and marker carry matching preparation identifiers. A missing snapshot file is initialized minimally; existing snapshot files are not overwritten by launcher preparation. The game still writes its own SavedVariables normally.

## Trust and compatibility

Bridge protocol 1 is independent of the WTFix product version. Compatible combinations may work together; incompatible combinations stop before changing preparation, junctions or managed TOCs.

The runtime requires valid metadata, supported protocol, a completed disk read, matching identifiers and a uniquely prepared character name before trusting preparation. Its character check is not authenticated account identity. Choose the correct account; duplicate names, new characters or stale/copied directories can prevent reliable identification.

Among valid snapshot candidates, the highest generation wins; current/native wins ties, followed by disk and bootstrap. Launcher bootstrap data is a pre-launch fallback. Changed addon files do not automatically become trusted checkpoints.

## When to prepare again

Close WoW and rerun the launcher after adding/updating managed addons, changing installation/account, or when preparation is missing or rejected. New characters need usable local folders before preparation can recognize them.

Setup archives only inputs present when it runs. It is not a continuous version history or a substitute for an independent WTF backup.

## Ownership and removal

Ordinary launcher operation never replaces an installed runtime. Full installs one only when absent. Updating the runtime remains the responsibility of its owner.

The 0.8.8 uninstaller removes WTFix_Data and managed dependency entries. It preserves the runtime, SavedVariables, marker and local history/configuration. Remove the runtime separately through its manager when desired. Avoid recursive deletion through the Disk junction.

Logs, configuration and preparation backups are kept under `%LOCALAPPDATA%\WTFix`. Review these for personal paths/data before sharing them.
