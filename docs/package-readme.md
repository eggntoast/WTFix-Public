> [!IMPORTANT]
> **Historical documentation — WTFix is retired.**
>
> Blizzard fixed the WoW Forever SavedVariables persistence bug that WTFix 0.9.3 was created to work around. This document is retained for existing installations and historical/reference use only. WTFix is no longer recommended for current Forever builds. See the [project README](../README.md).

# WTFix 0.9.3

SavedVariables recovery for WoW Forever.

## Choose the right package

- **WTFix-Full-0.9.3.zip:** Windows launcher, preparation companion and addon.
- **WTFix-Launcher-0.9.3.zip:** Windows launcher and companion for users who already
  installed the addon through an addon manager.
- **WTFix-Addon-0.9.3.zip:** addon only. Installing the addon alone does not prepare recovery.
- **WTFix-Linux-Full-0.9.3.zip:** Linux preparation tools and addon.
- **WTFix-Linux-Prepare-0.9.3.zip:** Linux preparation tools for an existing addon installation.

Linux users: follow `README.md` inside the Linux package. It uses the included
`prepare.py` and requires Python 3.10 or newer. Start the game through your usual
manager after preparation; the Linux tool does not launch Wine, Proton or WoW.

## Windows setup

1. Completely exit WoW. Extract the whole package into a user-owned folder outside
   the installed `Interface/AddOns/WTFix` directory. Keep its files together.
2. Run **WTFix Launcher.cmd**. Select the correct game installation and account.
   If account/character folders do not exist yet, log in once and exit first.
3. Wait for **RECOVERY IS READY**, then click Play in Battle.net. The completion
   window can be dismissed when you are ready.
4. Keep **WTFix** and **WTFix_Data** enabled in-game. Open `/wtfix` to check setup.

Full installs the bundled runtime only when its destination is absent. Preparation
never overwrites or downgrades an existing runtime. To update an installed addon,
use its addon manager, or explicitly install the bundled `AddOn/WTFix` with WoW
closed. Launcher-only requires a compatible runtime to be installed first.

Use **Change WoW Location.cmd** to select a different installation. Preparation
backs up recovery inputs before managing the companion, directory bridge and
relevant TOC load-order entries. Existing SavedVariables are retained.

### Upgrading from 0.8.7

That older version kept its directory bridge inside the runtime. Do not overlay
it with a new runtime or delete folders through that bridge. With WoW closed,
first back up the selected `WTF/Account/<account>` directory outside the game.
Use the **old 0.8.7 Uninstall WTFix.cmd** for its one-time cleanup, then install
the current addon and prepare again. The current uninstaller retains the runtime
and is not a substitute for that legacy cleanup. If the old uninstaller is
unavailable, request migration help. Do not run the old launcher afterward.

## Save and Restore

- **SETUP REQUIRED:** Save and Restore are disabled. Follow the status reason and
  prepare recovery with WoW closed for the correct account.
- **Setup ready:** preparation is usable; create the first checkpoint after you
  configure your addons.
- **Snapshot ready:** a checkpoint is available for recovery and Restore.

Choose **Save Current Settings → Save Snapshot → Reload Now** to adopt your current
settings. Choose **Restore Saved Settings → Prepare Restore → Reload Now** to
discard unsaved changes. Later addon writes do not silently update the checkpoint.

Ordinary reloads and cold starts recover through the disk bridge without another
preparation run. Rerun setup after adding addons, after updates replace managed
TOCs, for a newly created character, or when WTFix reports setup is required.
Prepared character-name matching is a consistency check, not account authentication.

## Addons with their own Reload/Apply step

Some addons keep settings pending until they apply them. Use this workflow:

1. Disable WTFix protection for that addon.
2. Make the intended settings changes.
3. Use the addon's own Reload/Apply mechanism.
4. Verify the settings survived.
5. Re-enable WTFix protection.
6. Explicitly Save Snapshot in WTFix.

Re-enabling protection alone does not adopt changed data. This generic workflow
requires the addon itself to persist correctly. Deleting its SavedVariables is
not a normal WTFix step.

## Status and support

**Not loaded** means an addon is not currently running; existing checkpoint data
is retained. Live differences can include counters, caches and message history.
`/wtfix diff` lists differing paths; it does not save them. `/wtfix check` reports
capture problems separately from unavailable recovery inputs.

If setup fails, preserve the error and your settings. Do not delete `.lua` or
`.bak` files as a workaround, and do not Save defaults over a checkpoint you want
to recover. Backups can contain private data; review anything before sharing it.

**Uninstall WTFix.cmd** removes preparation and managed dependencies while retaining
the runtime and SavedVariables. Remove the runtime separately through its owner.

For a bug report, include the version, `/wtfix status`, and `/wtfix check` for a Save
problem. The About page provides a copyable Report a Bug link.

[Report a bug](https://github.com/eggntoast/WTFix-Public/issues)

See the included `CHANGELOG.md` for release changes.

## Character linking after an update

Forever may provide the player GUID before it provides the character name on a
fresh client start. WTFix can use a previously verified character link to recover
at that early point. A missing link is different from a broken disk bridge.

If WTFix shows **Link required**:

1. Open WTFix and click **Link Character** beside the status indicator.
2. Select the saved character record you recognize, checking its stored name,
   last-saved time and generation, then click **Link Selected Record**. No record
   is selected automatically. If you are unsure, cancel and ask for help; a higher
   generation alone does not prove that a record belongs to this character.
3. Choose **Reload Now** to apply recovery before other addons initialize. **Later**
   closes the prompt and leaves recovery pending; the header keeps a reload action.
   Reloading can replace current unsaved addon changes with saved settings.

**Details** shows read-only recovery information. **Setup Help** or **View Problem**
explains a blocked state and the appropriate next step. A dash for Last saved, or
**Not checked** beside an addon, means its recovery data has not been qualified;
it does not mean the saved data is gone. Detected addons is a manifest count, not
confirmation that recovery was applied.

Advanced fallback: `/wtfix bind` lists records; `/wtfix bind NUMBER` opens an explicit
confirmation. These commands use the same link checks as the GUI.

Linking does not capture current settings, advance the snapshot generation, merge
character records or delete older records. It retains the selected whole checkpoint
for the next startup. **Save Snapshot** remains the only way to adopt live settings.
The link is checked against the current GUID, full name when available, prepared
roster and native realm. It does not establish account ownership. Conflicting links
or ambiguous prepared names block recovery instead of guessing.

Do not delete SavedVariables to resolve a link problem. Keep both WTFix and WTFix
preparation data enabled. An incompatible bridge or genuinely missing preparation
still requires setup with WoW closed. Existing compatible preparation need not be
rerun just to install this runtime update.

NS
