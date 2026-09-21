# Preparation, ownership and limitations

## What the launcher does

With WoW closed, preparation checks runtime/bridge compatibility, selects the account, archives existing Lua recovery inputs, prepares WTFix_Data and manages dependency entries in relevant addon TOCs.

It then opens Battle.net on Forever Beta and displays successful completion.

Preparation does not need a resident helper. It does not modify WoW executables or inject code.

## Why there are two addons

- **WTFix** is the runtime, owned by its addon manager or manual installer.
- **WTFix_Data** is the launcher's companion, containing generated preparation and a `Disk` directory junction pointing to the selected account's SavedVariables directory.

Keep both enabled.

Installing the runtime alone does not prepare the bridge.

## Byte-safe SavedVariables preparation

WTFix 0.9.0 reads SavedVariables source files as raw bytes when generating recovery bootstrap data.

Binary and non-UTF-8 string data is embedded without character-set transcoding. This matters for addons that store compact or binary data inside SavedVariables.

An optional UTF-8 BOM is accepted. UTF-16 source is rejected rather than silently transcoded.

When updating from 0.8.8, run the 0.9.0 launcher once with WoW closed so preparation is regenerated.

This prevents new corruption. It cannot reconstruct data already corrupted by an older generated preparation.

## Trust and compatibility

Bridge protocol 1 is independent of the WTFix product version.

The runtime requires valid preparation metadata, a supported protocol, completed disk input, matching preparation identifiers and a prepared character match before trusting recovery.

Among valid snapshot candidates, the highest generation wins. Current/native wins ties, followed by disk and bootstrap.

Launcher bootstrap data is fallback input. It does not silently become a new trusted checkpoint.

## When to prepare again

Close WoW and rerun the launcher after:

- adding or updating managed addons
- changing the installation or selected account
- adding characters requiring preparation
- preparation being missing or rejected
- a release explicitly requiring regenerated preparation

Setup archives inputs present when it runs. It is not a continuous backup system.

## Ownership and removal

Ordinary launcher operation never replaces an installed compatible runtime. Full installs one only when the runtime is absent.

Updating the runtime remains the responsibility of its addon manager or manual installer.

The current uninstaller removes WTFix_Data and managed dependency entries. It preserves the runtime, SavedVariables, marker and local history/configuration.

Remove the runtime separately through its manager when desired.

Avoid recursive deletion through the Disk junction.

Logs, configuration and preparation backups are kept under `%LOCALAPPDATA%\WTFix`. Review them for personal paths or data before sharing.