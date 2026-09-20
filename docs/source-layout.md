# Source layout

The public layout separates editable runtime and launcher source:

- `addon/WTFix/`: runtime files, including embedded-library notices.
- `launcher/`: unchanged Windows entry points and PowerShell scripts.
- `launcher/Companion/WTFix_Data/`: unchanged companion template.
- `docs/`, README, CHANGELOG and LICENSE: user and distribution documentation.

This is a source export. Use packaged downloads for installation.

Full packaging places the runtime at `AddOn/WTFix/` beside the launcher scripts, and the companion at `Companion/WTFix_Data/`. Launcher-only uses the same layout with no AddOn payload. The CurseForge addon ZIP has `WTFix/` at its root. GitHub distributes only Full and Launcher ZIPs. These paths are required by the unchanged 0.8.8 scripts; do not assume the curated source tree is itself a Full installation.

Product version: 0.8.8. Bridge protocol: 1. See export-manifest.json for the implementation commit and per-file SHA256 mapping. Generated data, junctions, user settings, development evidence and old packages are not source-export inputs.
