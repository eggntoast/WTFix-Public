# Troubleshooting

## SETUP REQUIRED

Close WoW and run the current compatible launcher for the correct installation/account.

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

WTFix 0.9.0 can omit nested runtime-only `function`, `userdata` and `thread` values while retaining ordinary persistent scalar/table data.

These omissions are reported.

Unsupported roots, unsafe keys, cycles and structural/resource failures still block Save.

## Binary or non-UTF-8 SavedVariables

0.9.0 fixes an older launcher behavior that could transcode binary or non-UTF-8 SavedVariables source.

When upgrading from 0.8.8:

1. update the runtime
2. update the launcher
3. close WoW
4. run the current launcher once

Updating only the addon does not regenerate old bootstrap preparation.

0.9.0 prevents new encoding corruption. It cannot reconstruct already-corrupted data. Preserve known-good backups.

## Installed addon shows Not loaded

This means WTFix knows about the protected addon but it is not currently loaded.

It may be disabled, unavailable for the current game type or waiting to load on demand.

Existing checkpoint/fallback data is retained.

This condition does not by itself count as active missing recovery coverage.

## Missing runtime or incompatible version

Launcher-only does not include the runtime.

Install the runtime through CurseForge or manual installation, or use Full when the runtime is absent.

Existing compatible runtimes are not replaced by ordinary launcher preparation.

## Preparation fails

Read the launcher error and:

`%LOCALAPPDATA%\WTFix\WTFix-last.log`

Confirm the WoW location and that WoW is closed.

Use `Change WoW Location.cmd` if necessary.

Do not delete snapshots or SavedVariables simply to suppress an error.

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

Open `/wtfix → About → Report a Bug` or visit:

https://github.com/eggntoast/WTFix-Public/issues

Include:

- WTFix version
- affected addon and version
- `/wtfix status`
- `/wtfix check` for Save/capture issues
- exact reproduction steps

Never post full SavedVariables, recovery archives or logs without reviewing them for personal information first.