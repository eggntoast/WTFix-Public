# Source layout

The public layout separates runtime and launcher source:

- `addon/WTFix/`: runtime files, embedded libraries and runtime media.
- `launcher/`: Windows entry points and PowerShell launcher source.
- `launcher/Companion/WTFix_Data/`: launcher-owned companion template.
- `docs/`, README, CHANGELOG and LICENSE: public documentation.

This repository is a source export. Use packaged downloads from GitHub Releases or CurseForge for installation.

Full packaging places the runtime at `AddOn/WTFix/` beside launcher scripts and the companion at `Companion/WTFix_Data/`.

Launcher-only uses the same launcher/companion layout with no runtime payload.

The CurseForge addon ZIP contains `WTFix/` at its root.

GitHub distributes the Full and Launcher ZIPs.

Product version: **0.9.0**

Bridge protocol: **1**

See `export-manifest.json` for the private implementation authority commit and per-file SHA256 mapping.

Generated player data, directory junctions, private development tests, recovery history and local build packages are not public source-export inputs.