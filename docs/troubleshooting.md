# Troubleshooting

## Checking identity

WTFix is waiting for WoW Forever to expose the current character identity.

Recovery has not been applied for this login while this state is active. Do not Save replacement settings simply to clear the message.

If the state does not resolve after login finishes, preserve the current recovery data and include `/wtfix status` in a bug report.

## Link required

WTFix has identified the character but needs an explicit association with an existing saved character record.

Click **Link Character** and select the record you recognize by its stored name, last-saved time and generation.

No record is selected automatically. Do not choose a record merely because it has the highest generation.

Linking:

- does not Save Snapshot
- does not capture current addon settings
- does not merge or delete character records
- does not advance the trusted snapshot generation

After a successful link, WTFix will show **Reload required**.

## Reload required

Click **Reload Now** when you are ready.

After Character Linking, the reload allows WTFix to use the confirmed character association during the early recovery window before protected addons initialize.

If Reload required follows a Save or Restore operation instead, complete that pending reload before starting another recovery action.

## Recovery blocked

Click **View Problem** and follow the reason-specific guidance.

A blocked recovery state means WTFix found a conflict or recovery input that it cannot safely accept. Preserve the existing recovery files and trusted checkpoint.

Do not Save a replacement snapshot, delete SavedVariables or guess another character record merely to clear the blocked state.

## SETUP REQUIRED

Preparation has not been accepted for the current installation/account.

### Windows

Close WoW and run the current compatible:

`WTFix Launcher.cmd`

### Linux

Close WoW and run the current Linux preparation tool again using the intended game folder and exact account.

Keep WTFix_Data enabled.

Check the exact reason with:

`/wtfix status`

Do not bypass the setup gate or assume addon installation alone means recovery is prepared.

## Save fails

Run:

`/wtfix check`

This checks currently loaded protected SavedVariables using the same persistable-data projection used by Save.

It does **not** Save, Restore, reload, advance the checkpoint or adopt current settings.

The output can identify:

- addon and version
- account or character scope
- SavedVariable name
- failing path
- failure reason
- runtime-only values that will be omitted
- missing recovery inputs
- protected addons that are not currently loaded

When reporting a problem, include the complete `/wtfix check` output and exact addon version.

## Runtime-only values

WTFix can omit nested runtime-only `function`, `userdata` and `thread` values while retaining ordinary persistent scalar/table data.

These omissions are reported.

Unsupported roots, unsafe keys, cycles and structural/resource failures still block Save.

## Binary or non-UTF-8 SavedVariables

Current preparation preserves SavedVariables source as raw bytes.

When upgrading directly from 0.8.8 on Windows:

1. update the runtime
2. update the launcher
3. close WoW
4. run the current launcher once

Updating only the addon does not regenerate old bootstrap preparation.

Current preparation prevents new encoding corruption. It cannot reconstruct already-corrupted data. Preserve known-good backups.

## Installed addon shows Not loaded

This means WTFix knows about the protected addon but it is not currently loaded.

It may be disabled, unavailable for the current game type or waiting to load on demand.

Existing checkpoint/fallback data is retained.

This condition does not by itself count as active missing recovery coverage.

## Newly installed addon is missing from Protected Addons

Close WoW completely and refresh preparation.

### Windows

Run:

`WTFix Launcher.cmd`

### Linux

Run the Linux preparation tool again for the intended installation/account.

You do not need to reinstall WTFix simply because a newly installed addon was not present during earlier preparation.

## Missing runtime or incompatible version

The Windows Launcher package and Linux Prepare package do not contain the WTFix runtime.

Install the runtime through CurseForge/manual installation or use the appropriate Full package when the runtime is absent.

Existing compatible runtimes are not replaced by ordinary preparation.

## Windows preparation fails

Read the launcher error and:

`%LOCALAPPDATA%\WTFix\WTFix-last.log`

Confirm:

- the correct WoW location
- the intended account
- WoW is fully closed

Use `Change WoW Location.cmd` when necessary.

Do not delete snapshots or SavedVariables simply to suppress an error.

## Linux preparation fails

Confirm:

- Python 3.10 or newer is available
- the selected folder is the Forever folder containing `WowB.exe`
- the exact intended account folder was supplied
- WoW is fully closed
- the game and state paths are writable by the current user

If `.wtfix-preparation.lock` remains after an interrupted preparation, keep WoW closed and follow the rollback procedure in the [Linux guide](linux-preparation.md).

Do **not** delete the lock simply to bypass a conflict.

Do **not** delete another addon's SavedVariables as a generic repair.

## Settings revert

Protected ordinary reloads deliberately restore the trusted checkpoint.

Use Save Snapshot when you intentionally want to adopt a new configuration.

For addons that commit settings only through their own Apply/Reload workflow, see the [usage guide](usage.md).

## Live data differs immediately after login

This can be counters, caches or session history.

Inspect:

`/wtfix diff`

A differing path does not automatically mean recovery failed.

## Getting help

Open:

`/wtfix → About → Report a Bug`

or visit:

https://github.com/eggntoast/WTFix-Public/issues

Include:

- WTFix version
- operating system
- package used
- affected addon and version
- `/wtfix status`
- `/wtfix check` for Save/capture issues
- exact reproduction steps

Never post full SavedVariables, recovery archives or logs without reviewing them for personal information first.
