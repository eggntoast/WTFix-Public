# Changelog

## 0.9.1

- More reliable character-specific recovery when Forever's in-game character name and internal character-folder identity differ. Ambiguous matches are not guessed.
- Save now validates the complete assembled checkpoint against recovery limits before replacing the previous trusted checkpoint. If validation fails, the previous checkpoint remains intact.
## 0.9.0

- Safer snapshots for addons that mix settings with temporary runtime values, with compatibility improvements for EllesmereUI and Prat chat history.
- Recovery preparation now preserves binary and non-UTF-8 SavedVariables data, including Questie-style binary stores.
- Protected addons that are installed but not loaded now show **Not loaded** instead of incorrectly reducing active recovery coverage.
- Improved `/wtfix check` details identify capture problems and distinguish them from unavailable recovery inputs.
- Added **Recovery** and **About** tabs with current changes and a copyable bug-report link.

### Updating from 0.8.8

Update both the addon/runtime and launcher, then run the 0.9.0 launcher once with WoW closed to regenerate preparation.

Updating the addon alone leaves older generated bootstrap data in place.

0.9.0 prevents new encoding corruption but cannot reconstruct SavedVariables data already corrupted by an older preparation. Preserve known-good backups when recovery may be required.

## 0.8.8

- Separate the addon runtime from launcher-owned preparation so a compatible installed runtime is preserved.
- Show SETUP REQUIRED and block Save/Restore when preparation cannot be trusted.
- Allow the first Save after valid setup, with Restore available once a valid checkpoint exists.
- Check bridge compatibility independently of the product version.
- Provide Full and Launcher-only installation packages.
- Retain disk recovery across Save/reload, ordinary reload, Restore and subsequent cold starts.