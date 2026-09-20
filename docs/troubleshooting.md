# Troubleshooting

## SETUP REQUIRED

Close WoW and run the current compatible launcher for the correct installation/account. Keep WTFix_Data enabled. Check the exact preparation reason in `/wtfix status`. Do not bypass the gate or treat addon installation alone as successful setup.

If no character folders exist, log into the character once, exit, then prepare. If character names are ambiguous or the wrong account was prepared, review account selection instead of assuming the check authenticates your login.

## Missing runtime or incompatible version

Launcher-only does not include the runtime. Install it through an available addon package or use Full for a missing installation. Existing runtimes are never replaced by Full; update an incompatible runtime separately and rerun setup. See the [migration guide](installation.md#upgrading-from-087-or-earlier) for old in-runtime bridges.

## Preparation fails

Read the launcher error and `%LOCALAPPDATA%\WTFix\WTFix-last.log`. Confirm the location and that WoW is closed. Use Change WoW Location.cmd if needed. Do not delete snapshots, force-remove junctions, disable security controls or blindly elevate privileges to suppress an error. Keep existing backups.

## Settings revert

Ordinary protected reloads deliberately restore the saved checkpoint. Save a new checkpoint to keep intended changes. For edits committed only during the addon's own Apply/Reload, use the [pending-settings workflow](usage.md#addons-with-pending-settings).

If the addon cannot persist its own settings while excluded, that failure must be resolved independently. Do not delete its SavedVariables as a routine WTFix step.

## Live data differs immediately after login

This can be counters, caches or session history. Inspect `/wtfix diff`; a differing path alone does not prove failed recovery. Compare the intended setting and checkpoint generation.

## Getting help

Provide WTFix and launcher versions, the preparation reason, recovery source, snapshot generation, the affected addon/version and exact steps. Include whether the addon persists correctly while excluded. Never post full SavedVariables, recovery archives or logs without reviewing and removing personal data.
