# Source layout

The public source tree separates the WTFix runtime and platform preparation tools:

- `addon/WTFix/` — in-game WTFix runtime.
- `launcher/` — Windows launcher and preparation source.
- `launcher/Companion/WTFix_Data/` — Windows companion template.
- `linux/` — Linux preparation source.
- `linux/Companion/WTFix_Data/` — Linux companion template.
- `docs/` — installation, preparation, troubleshooting and other public documentation.

This repository is a public source export.

For normal installation, use the packaged downloads from GitHub Releases or CurseForge rather than GitHub's automatically generated source archives.

## Windows packages

### `WTFix-Full-0.9.2.zip`

Contains:

- WTFix addon runtime
- Windows launcher
- companion template
- preparation components

### `WTFix-Launcher-0.9.2.zip`

Contains:

- Windows launcher
- companion template
- preparation components

It does **not** contain the WTFix runtime.

## Linux packages

### `WTFix-Linux-Full-0.9.2.zip`

Contains:

- WTFix addon runtime
- `prepare.py`
- `preparation.py`
- companion template
- Linux setup documentation

### `WTFix-Linux-Prepare-0.9.2.zip`

Contains:

- `prepare.py`
- `preparation.py`
- companion template
- Linux setup documentation

It does **not** contain the WTFix runtime.

Native Linux/Wine validation is still pending.

## CurseForge package

`WTFix-Addon-0.9.2.zip` contains only the WTFix addon runtime and is used for the CurseForge distribution route.

Installing the addon alone does not prepare recovery.

## Current version

Product version: **0.9.2**

Bridge protocol: **1**

Snapshot schema: **1**

See `docs/export-manifest.json` for the private implementation authority commit and per-file SHA256 mapping.

Generated player data, local recovery history, private tests, backups and local build output are excluded from the public source export.
