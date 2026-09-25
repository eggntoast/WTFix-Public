# What's New

## 0.9.3

- Separated recovery status from its next action, with read-only Recovery Details and cause-specific setup help.
- Unqualified recovery data is shown as not checked, rather than appearing missing.

- Fixed cold-start character recognition when Forever supplies the character name only after addons initialize.
- Added an in-game character-link flow with record selection, explicit confirmation and Reload Now/Later controls. Linked characters can recover early on subsequent cold starts.
- Recognizes full two-part character names and preserves existing short-name checkpoints without merging or deleting records.
- Distinguishes waiting for a character, linking and reloading from genuinely invalid preparation.

If prompted, link your character to the checkpoint you recognize and reload once.
No new snapshot is saved by linking. Windows and Linux preparation remain compatible;
there is no bridge protocol or snapshot schema change.

## 0.9.2

- Added Linux recovery preparation, with explicit game-folder/account selection, verified backups and interrupted-setup recovery. Start WoW through your usual launcher afterward.
- Corrected ZIP paths for portable extraction on Windows and Linux.
- Aligned the Protected Addons **SNAPSHOT** heading with its values across panel sizes and UI scales.

Linux users: choose **Linux Full** for the addon plus preparation tools, or **Linux Prepare** if the addon is already installed. Windows users keep the existing Full/Launcher packages. Linux preparation needs Python 3.10+; follow its bundled setup guide. Save Snapshot remains the explicit way to adopt settings into your trusted checkpoint.

## 0.9.1

- More reliable recovery of character-specific files when Forever presents a different realm number or spacing in a two-part character name. Ambiguous matches are not guessed.
- Save checks the complete checkpoint against recovery limits before replacing the previous checkpoint.

## 0.9.0

- Safer snapshots for addons that mix settings with temporary runtime values, with compatibility improvements for EllesmereUI and Prat chat history.
- Recovery preparation now preserves binary and non-UTF-8 SavedVariables data, including Questie-style binary stores.
- Protected addons that are installed but not loaded now show **Not loaded** instead of incorrectly reducing active recovery coverage.
- Improved `/wtfix check` details identify capture problems and distinguish them from unavailable recovery inputs.
- New **Recovery** and **About** tabs, with What's New and a copyable bug-report link inside the WTFix panel.

Update both the addon and launcher, then run the updated launcher once with WoW closed to refresh preparation. Updating the addon alone leaves older generated bootstrap data in place. This prevents new encoding corruption; it does not repair already-corrupted settings. Preserve known-good backups before attempting recovery.

Save Snapshot remains the explicit way to adopt a new trusted checkpoint. Ordinary reloads and Restore continue using that checkpoint.
