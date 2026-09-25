# Preparation, ownership and limitations

## What preparation does

With WoW closed, preparation:

- checks runtime and bridge compatibility
- selects the intended account
- archives existing recovery inputs
- prepares WTFix_Data
- manages dependency entries in relevant addon TOCs
- verifies the disk bridge and generated preparation data

On **Windows**, the launcher then opens Battle.net on Forever Beta and displays successful completion.

On **Linux**, the preparation tool completes setup only. It does not launch Battle.net, Wine, Proton or WoW.

Preparation does not require a resident helper. It does not modify WoW executables or inject code.

## Why there are two addons

- **WTFix** is the in-game runtime, owned by its addon manager or manual installer.
- **WTFix_Data** is the preparation-owned companion and disk bridge.

Keep both enabled after successful preparation.

On Windows, the companion uses a directory junction named `Disk`.

On Linux, the companion uses a POSIX directory symlink named `Disk`.

Both point to the selected account's SavedVariables directory.

Installing the WTFix runtime alone does not prepare recovery.

## Byte-safe SavedVariables preparation

WTFix reads SavedVariables source as raw bytes when generating recovery bootstrap data.

Binary and non-UTF-8 data is preserved without character-set transcoding.

An optional UTF-8 BOM is accepted. UTF-16 input is rejected rather than silently converted.

This prevents new encoding corruption. It cannot reconstruct data already corrupted by older preparation.

## Trust and compatibility

Product version, bridge protocol and snapshot schema are separate contracts.

WTFix 0.9.3 continues to use:

- bridge protocol **1**
- snapshot schema **1**

The runtime requires valid preparation metadata, a supported protocol, completed disk input, matching preparation identifiers and a prepared character match before trusting recovery.

If preparation cannot be trusted, WTFix fails closed with:

**SETUP REQUIRED**

Preparation/bootstrap data is recovery input. It does not silently become a new trusted checkpoint.

**Save Snapshot remains the explicit adoption boundary.**

## When to prepare again

Close WoW and refresh preparation after:

- installing a new addon that you want WTFix to protect
- updating an addon whose SavedVariables declarations may have changed
- changing the installation or selected account
- adding characters requiring preparation
- preparation being missing or rejected
- a release explicitly requiring regenerated preparation

Preparation does not need to run before every normal WoW session.

## Ownership and removal

Ordinary preparation never replaces an installed compatible runtime.

Updating the runtime remains the responsibility of its addon manager or manual installer.

### Windows

The current Windows uninstaller removes WTFix_Data and managed dependency entries.

It preserves:

- the WTFix runtime
- SavedVariables
- the preparation marker
- local history/configuration

Windows logs, configuration and preparation backups are kept under:

`%LOCALAPPDATA%\WTFix`

### Linux

Linux preparation does not install, update or downgrade the WTFix runtime.

Private preparation state defaults to:

`$XDG_STATE_HOME/wtfix`

or, when `XDG_STATE_HOME` is unset:

`~/.local/state/wtfix`

Linux 0.9.3 does not include an automatic uninstall workflow. See the [Linux installation and preparation guide](linux-preparation.md) before changing prepared files manually.

Review logs, backups and SavedVariables before sharing them publicly because they may contain personal paths or addon data.
