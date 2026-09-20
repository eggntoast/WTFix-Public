# Save, Restore and pending settings

## Readiness

| Panel state | Save | Restore | Meaning |
| --- | --- | --- | --- |
| SETUP REQUIRED | Disabled | Disabled | Preparation is missing or cannot be trusted; protected recovery is blocked. |
| Setup ready / No snapshot saved | Enabled | Disabled | Preparation is valid; create your first checkpoint. |
| Snapshot ready | Enabled | Enabled | A valid protected checkpoint is available. |

Warnings and partial coverage need attention even when preparation is ready. Check `/wtfix status`.

## Save a trusted setup

Configure the addons you want protected. Click **Save Current Settings → Save Snapshot → Reload Now**.

Confirming Save captures current declared SavedVariables. Reload makes WoW write the checkpoint to disk and reloads the UI. Use the secure Reload Now button when out of combat.

A successful new Save replaces the trusted checkpoint. Settings changed afterward remain unsaved until you explicitly Save again. Ordinary reloads restore the checkpoint for protected addons.

## Restore a checkpoint

Click **Restore Saved Settings → Prepare Restore → Reload Now**.

Restore discards current unsaved changes for protected addons and applies the checkpoint during startup. It does not create a newer generation.

The protection checkbox controls which addons are included in recovery and capture. Excluded addons' existing checkpoint records are retained.

## Addons with pending settings

Some addons keep edits in private working state until their own Reload/Apply mechanism commits them to declared SavedVariables. This differs from settings already stored in SavedVariables that merely need a reload to take effect.

For an addon with pending settings:

1. Disable WTFix protection for that addon.
2. Make the intended addon settings changes.
3. Use the addon's own Reload/Apply mechanism.
4. Verify the intended settings survived the reload.
5. Re-enable WTFix protection for that addon.
6. Explicitly Save Snapshot in WTFix.

After step 6, use WTFix's Reload Now prompt to write the checkpoint.

Later addon writes do not silently alter the trusted checkpoint. Re-enabling protection alone does not adopt changed SavedVariables; explicit Save Snapshot adopts the new state. This is generic behavior, not an addon-specific exception.

During the excluded cycle, the addon must persist its own settings correctly. If they do not survive step 4, stop instead of saving defaults. WTFix cannot repair an independent addon persistence failure. Deleting another addon's SavedVariables is not a normal WTFix workflow.

## Understanding differences

**Snapshot ready** describes the checkpoint, not an exact match of every live value. Addons can change counters, caches and session history immediately after login.

A Saved row means checkpoint coverage. `/wtfix diff` lists differing variable paths without printing their values; differences may be settings or routine runtime data. Save only when you intend to adopt the current setup.
