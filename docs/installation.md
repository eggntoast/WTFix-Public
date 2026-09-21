# Installation and setup

WTFix 0.9.0 is for WoW Forever on Windows. The Windows launcher and the in-game runtime are both needed for prepared recovery.

Before installation or an upgrade, close WoW and keep an independent backup of your WTF account data. Setup also creates a verified recovery-input archive, but this is not a continuous backup of every subsequent change.

## Route A: install everything from GitHub

1. Download `WTFix-Full-0.9.0.zip` from the current GitHub release.
2. Extract the entire ZIP into a normal folder outside WoW's AddOns directory. Keep all extracted files together; do not run directly inside the ZIP.
3. With WoW closed, run `WTFix Launcher.cmd`.
4. Confirm the correct Forever installation and account when prompted. If no account/character folder exists yet, log into that character once, exit WoW, and run setup again.
5. Require a successful completion screen showing the recovery input backup verified and disk bridge prepared.
6. Battle.net should be on Forever Beta. Click Play, then keep both WTFix and WTFix_Data enabled and log into the prepared character.
7. Open `/wtfix`. Configure your addons and create your trusted snapshot using the [usage guide](usage.md).

Full installs the runtime only when `Interface/AddOns/WTFix` is absent. It preserves a compatible existing runtime.

## Route B: CurseForge addon plus Launcher

1. Install or update the WTFix runtime through CurseForge.
2. Download and fully extract `WTFix-Launcher-0.9.0.zip` from GitHub.
3. Close WoW.
4. Run `WTFix Launcher.cmd`.
5. Require successful backup and disk-bridge preparation.
6. Start WoW and keep both WTFix and WTFix_Data enabled.

The Launcher package contains no runtime. Installing the CurseForge addon by itself does not prepare recovery.

## Updating from 0.8.8

WTFix 0.9.0 changes both the runtime and launcher.

1. Update or install the 0.9.0 WTFix runtime.
2. Replace the old launcher files with the 0.9.0 launcher.
3. Close WoW completely.
4. Run the 0.9.0 `WTFix Launcher.cmd` once.
5. Require successful preparation.
6. Start WoW normally.

This launcher rerun is required because 0.9.0 changes how SavedVariables source is embedded into generated recovery preparation.

Older launchers could transcode binary or non-UTF-8 SavedVariables data. 0.9.0 reads raw bytes and preserves them without text-encoding conversion.

0.9.0 prevents new corruption. It cannot infer or reconstruct settings already corrupted by an older preparation. Preserve known-good backups before attempting recovery.

## Later launches and updates

After successful preparation, you may start WoW normally through Battle.net. The launcher does not need to run before every session.

Run it again with WoW closed after:

- adding or updating managed addons
- changing the WoW installation or selected account
- adding characters that require preparation
- seeing SETUP REQUIRED
- updating to a release whose notes explicitly require regenerated preparation

The runtime must still be updated separately through its addon manager or manual installation.

## Upgrading from 0.8.7 or earlier

Older runtime layouts may contain launcher-owned files, including a disk junction. Do not blindly overlay an old installation.

For a 0.8.7 installation, with WoW closed and account data backed up, use that version's **Uninstall WTFix.cmd** to remove its old runtime/junction while retaining SavedVariables. Then install current WTFix using Route A or B and retire the old launcher.

For earlier or uncertain layouts, seek migration help before deleting folders.

The current uninstaller removes preparation and managed dependency entries while preserving the runtime and SavedVariables. See [ownership and removal](preparation.md#ownership-and-removal).