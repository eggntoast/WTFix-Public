# WTFix

SavedVariables recovery for **World of Warcraft: Forever (Windows)**.

Save a trusted addon setup, restore it when needed, and keep that checkpoint through reloads and future logins. WTFix 0.8.8 supports addons declaring standard account or per-character SavedVariables. Coverage depends on the addon and the data it exposes.

**Windows setup is required. Installing the addon alone does not prepare recovery.** Until preparation succeeds, WTFix shows **SETUP REQUIRED** and disables Save and Restore.

## Choose your installation

| You want to… | Use |
| --- | --- |
| Install everything from GitHub | `WTFix-Full-0.8.8.zip` |
| Prepare a compatible runtime installed through CurseForge | `WTFix-Launcher-0.8.8.zip` |

GitHub offers the Full and Launcher ZIPs. The addon/runtime package is distributed through CurseForge. Use the named GitHub ZIPs from the public repository's Releases area when available. GitHub's automatic **Source code** downloads are developer source, not the ready-to-run Full installer.

Start with the [installation guide](docs/installation.md). Then read [Save, Restore and pending settings](docs/usage.md).

## How it works

With WoW closed, the launcher prepares a separate companion addon, backs up recovery inputs and opens Battle.net. Click Play there. The launcher is not a background service.

Keep both **WTFix** and **WTFix_Data** enabled. Once preparation is valid, ordinary reloads and cold starts can recover the checkpoint without another launcher run. Refresh preparation after relevant installation/account changes or when setup is required.

The launcher preserves an already-installed compatible WTFix runtime. It does not upgrade or downgrade that runtime. See [preparation and ownership](docs/preparation.md).

## Important boundaries

- Save Snapshot captures declared SavedVariables at the time you confirm it.
- Later addon writes do not silently update the trusted checkpoint.
- Restore discards unsaved changes for protected addons.
- Some addons need their own Apply/Reload cycle before their pending settings can be captured. Follow the [six-step workflow](docs/usage.md#addons-with-pending-settings).
- Deleting another addon's SavedVariables is not a normal WTFix workflow.
- WTFix cannot repair an independent persistence failure inside another addon.

Use `/wtfix` to open the panel, `/wtfix status` for readiness and recovery details, and `/wtfix diff` to inspect differences.

See [troubleshooting](docs/troubleshooting.md), [changes](CHANGELOG.md), and [licenses](docs/licenses.md).
