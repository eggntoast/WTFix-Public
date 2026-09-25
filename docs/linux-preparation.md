# WTFix 0.9.3 — Linux preparation

WTFix protects a saved checkpoint of your addon settings. The Linux preparation
tool connects the in-game addon to the selected account's SavedVariables files.
After setup, start WoW through your usual game manager. WTFix does not select or
start Wine, Proton, Battle.net, Lutris, Bottles or Steam for you.

## Choose a package

- **WTFix-Linux-Full-0.9.3.zip:** the addon, preparation tools and companion template.
  With WoW closed, copy the bundled `AddOn/WTFix` folder into the game's
  `Interface/AddOns` directory. If an addon manager owns your installed WTFix,
  update it through that manager instead.
- **WTFix-Linux-Prepare-0.9.3.zip:** preparation tools and companion template for
  users who already have the WTFix addon installed.

Extract the entire ZIP into a user-owned tools directory outside `Interface/AddOns`.
Keep `prepare.py`, `preparation.py` and `Companion` together. All commands below
run from that extracted directory. The preparation tool never installs, replaces
or downgrades an existing addon runtime.

The ordinary **WTFix-Full** and **WTFix-Launcher** packages contain the Windows
launcher. Use the Linux packages for the commands in this guide.

## Before you start

- Install Python 3.10 or newer. No additional Python packages are needed.
- Log into the intended character at least once, then completely exit WoW. This
  creates the account and character directories needed for preparation.
- Find the game folder containing `WowB.exe`, `Interface` and `WTF`.
- Find your exact account folder name under that game's `WTF/Account` directory.
  Choose the account you actually play; the tool does not guess it.
- Close every WoW instance before preparation. Run as the user who owns the
  installation, without `sudo`.

The tool and game must have access to the same installation and SavedVariables
paths. For sandboxed game managers, allow access to those paths. The filesystem
must support directory symlinks and file/directory renames. Linked addons or linked
WTF input trees are refused rather than skipped; the selected game root itself
may resolve through a link.

## Prepare recovery

Replace the example game path and account below with your actual values. Keep
paths containing spaces inside quotes.

```sh
python3 -B ./prepare.py \
  --wow-folder '/path/to/World of Warcraft/_classic_beta_' \
  --account 'YOUR_ACCOUNT_FOLDER' --dry-run
```

The dry run validates the inputs without changing files. Check the installation
and account printed by the tool, then prepare with WoW still closed:

```sh
python3 -B ./prepare.py \
  --wow-folder '/path/to/World of Warcraft/_classic_beta_' \
  --account 'YOUR_ACCOUNT_FOLDER' --confirm-wow-closed
```

On success, the tool reports **PREPARATION COMPLETE**, the verified backup location
and the directory-bridge verification. Start the game through your usual manager.

In-game, open `/wtfix` or use `/wtfix status`:

- **SETUP REQUIRED:** recovery is not prepared for this character. Save and Restore
  are disabled. Follow the reported reason and rerun setup with WoW closed.
- **Setup ready:** preparation is usable, but there is no saved checkpoint yet.
  Configure your addons and use Save Current Settings to create one.
- **Snapshot ready:** an existing checkpoint is available for recovery and Restore.

The disk bridge should report **Loaded**. A message that the prepared character
name matched is a consistency check, not account authentication. Always select
the correct account during setup. Duplicate or unrecognized character names are
not guessed; a new character may require another preparation run after its
folders have been created.

## Daily use

To adopt your current settings, choose **Save Current Settings → Save Snapshot →
Reload Now**. To discard unsaved changes, choose **Restore Saved Settings → Prepare
Restore → Reload Now**. Ordinary reloads and cold starts continue using the trusted
checkpoint; you do not need to run preparation before every session.

Run preparation again after installing addons with SavedVariables, after addon
updates replace managed TOCs, when changing the prepared account, or when WTFix
reports that setup is required. Keep both **WTFix** and **WTFix_Data** enabled.

Some addons keep edits private until their own Reload/Apply action. For those:

1. Disable WTFix protection for that addon.
2. Make the intended settings changes.
3. Use the addon's own Reload/Apply mechanism.
4. Verify the settings survived.
5. Re-enable WTFix protection.
6. Explicitly Save Snapshot in WTFix.

Re-enabling protection alone does not adopt changed data. Later addon writes do
not silently update the trusted checkpoint. This workflow requires the addon to
persist correctly itself; deleting its SavedVariables is not a normal WTFix step.

## Backups and files managed by setup

Setup verifies byte-for-byte backups of selected-account SavedVariables and
relevant original TOCs before applying changes. Backups default to
`$XDG_STATE_HOME/wtfix` or `~/.local/state/wtfix`. To choose another private directory
outside the game, add `--state-dir '/absolute/private/backup-directory'` to the
preparation command. Existing state directories must be private (mode 0700).

Backup manifests list source paths, byte sizes and SHA256 hashes. Saved byte
objects are stored under `objects/`. Backups contain private addon data: do not
publish them. Backups and journals are retained; setup does not prune them or
silently promote them into a trusted checkpoint.

The tool manages `Interface/AddOns/WTFix_Data`, its directory symlink `Disk`, the
bridge marker and relevant TOC load-order entries. It creates a minimal
`WTFix.lua` only if that file is absent. Existing snapshot files, `.bak` files and
other addons' SavedVariables are not rewritten by preparation. SavedVariables
are read as raw bytes, preserving binary and non-UTF-8 data.

## If preparation is interrupted

**Keep WoW closed after a preparation error or while `.wtfix-preparation.lock`
exists in the game folder.** Caught apply errors attempt rollback. A terminated
process can leave a journal and lock for explicit recovery:

```sh
python3 -B ./prepare.py \
  --wow-folder '/path/to/World of Warcraft/_classic_beta_' \
  --rollback-interrupted --confirm-wow-closed
```

Rollback restores the pre-preparation state only when affected files still match
its original/new byte records. If another writer changed them, rollback refuses
to overwrite that newer data. Preserve the files and journal for diagnosis;
do not delete the lock to bypass a conflict or delete another addon's settings.
The runtime does not inspect the preparation lock, so do not launch the game
until preparation or rollback finishes successfully.

## Troubleshooting

- **Runtime missing or incompatible:** install/update the addon explicitly, and
  use compatible preparation tools. Product version and bridge protocol are separate.
- **No uniquely prepared character:** log in once and exit, check the chosen account,
  and inspect duplicate character folders. Do not remove settings merely to pass setup.
- **Linked, unreadable or unexpectedly named input:** inspect the reported path.
  Setup stops instead of taking an incomplete backup or guessing ownership.
- **Unexpected companion content:** preserve it for review; setup does not delete
  unknown files in `WTFix_Data`.
- **Resource limit:** inputs are limited to 64 MiB per file and 256 MiB per input
  tree. Escaped generated data can also reach the file limit. Report the affected
  file and limit for help; do not truncate SavedVariables to bypass the check.
- **Disk bridge unavailable:** check both addons are enabled, the selected account,
  the `WTFix_Data/Disk` target, and game-manager filesystem access, then rerun setup
  with WoW closed. Do not Save until setup is ready.

For support, include the tool error, WTFix version, game manager/filesystem and
`/wtfix status`. For capture problems, add `/wtfix check`. Review diagnostics for
personal information before posting; do not attach private backup objects.

[Report a bug](https://github.com/eggntoast/WTFix-Public/issues)

NS

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
