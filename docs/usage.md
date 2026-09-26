> [!IMPORTANT]
> **Historical documentation — WTFix is retired.**
>
> Blizzard fixed the WoW Forever SavedVariables persistence bug that WTFix 0.9.3 was created to work around. This document is retained for existing installations and historical/reference use only. WTFix is no longer recommended for current Forever builds. See the [project README](../README.md).

# Save, Restore and pending settings

## Readiness

| Panel state | Save | Restore | Meaning |
| --- | --- | --- | --- |
| SETUP REQUIRED | Disabled | Disabled | Preparation is missing or cannot be trusted; protected recovery is blocked. |
| Setup ready / No snapshot saved | Enabled | Disabled | Preparation is valid; create your first checkpoint. |
| Snapshot ready | Enabled | Enabled | A valid protected checkpoint is available. |

Warnings and partial coverage need attention even when preparation is ready. Check `/wtfix status`.

## 0.9.3 recovery states

The header can also show transitional or blocked recovery states:

- **Checking identity** — WTFix is waiting for Forever to expose the character identity. Recovery has not been applied for that login while this state is active.
- **Link required** — use **Link Character** and explicitly select the saved character record you recognize. No record is chosen automatically.
- **Reload required** — complete the pending reload. After Character Linking, this lets WTFix recover early on the next load using the confirmed character association.
- **Recovery blocked** — open **View Problem** and preserve the existing recovery data. WTFix will not guess through an identity, configuration or checkpoint conflict.

Character Linking is configuration, not a new checkpoint. It does not capture current addon settings, merge or delete character records, or advance the snapshot generation. **Save Snapshot** remains the explicit way to adopt live settings into the trusted checkpoint.

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
