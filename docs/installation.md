# Installation and setup

WTFix 0.8.8 is for WoW Forever on Windows. The Windows launcher and the in-game runtime are both needed for prepared recovery.

Before installation or an upgrade, close WoW and keep an independent backup of your WTF account data. Setup also creates a verified recovery-input archive, but this is not a continuous backup of every subsequent change.

## Route A: install everything from GitHub

1. Download `WTFix-Full-0.8.8.zip` when the approved release is available.
2. Extract the entire ZIP into a normal folder outside WoW's AddOns directory. Keep all extracted files together; do not run directly inside the ZIP.
3. With WoW closed, run `WTFix Launcher.cmd`.
4. Confirm the correct Forever installation and account when prompted. If no account/character folder exists yet, log into that character once, exit WoW, and run setup again.
5. Require a successful completion screen showing the recovery input backup verified and disk bridge prepared. If setup fails, follow its message; do not assume protection is ready.
6. Battle.net should be on Forever Beta. Click Play, then enable both WTFix and WTFix_Data and log into the prepared character.
7. Open `/wtfix`. Valid setup without a checkpoint shows **Setup ready**. Configure your addons and create your first snapshot using the [usage guide](usage.md).

Full installs the runtime only when `Interface/AddOns/WTFix` is absent. It preserves a compatible existing runtime. If an existing runtime is incompatible, update it through its owner before preparing again.

## Route B: CurseForge addon plus Launcher

1. Install/update the WTFix runtime through CurseForge when that listing is available.
2. Download and fully extract `WTFix-Launcher-0.8.8.zip`.
3. Close WoW, then run its `WTFix Launcher.cmd`.
4. Follow steps 4–7 in Route A.

The Launcher package has no runtime. It refuses preparation if the runtime is missing. Installing through CurseForge alone leaves **SETUP REQUIRED** until Windows preparation succeeds.

The addon/runtime package is distributed through CurseForge. GitHub provides the Full and Launcher packages; addon-only is not a separate GitHub installation route.

## Later launches and updates

After successful preparation, you may start WoW normally through Battle.net; rerunning the launcher for every session is unnecessary. Run it again with WoW closed after adding/updating managed addons, changing the installation or selected account, adding characters that need preparation, or seeing SETUP REQUIRED. Addon updates can replace the load-order entries that setup manages.

The runtime must be updated separately through its addon manager or manual installation. A same-version Full package does not replace an existing runtime.

## Upgrading from 0.8.7 or earlier

The old runtime contains launcher-owned files, including a disk junction. Do not blindly overlay it with an addon-manager update.

For a 0.8.7 installation, with WoW closed and account data backed up, use that version's **Uninstall WTFix.cmd** to remove its old runtime/junction while retaining SavedVariables. Then install 0.8.8 using Route A or B. Retire the old launcher afterward. For earlier or uncertain layouts, seek migration help before deleting folders.

The 0.8.8 uninstaller removes preparation and managed dependency entries while preserving the runtime and SavedVariables. See [ownership and removal](preparation.md#ownership-and-removal).
