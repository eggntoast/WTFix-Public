# WTFix

### SavedVariables recovery for **World of Warcraft: Forever (Windows)**

**Save the addon setup you trust. Restore it when something goes wrong. Keep it through reloads and future logins.**

![WTFix — Protect & Restore Addon Settings](https://media.forgecdn.net/attachments/1961/533/wtfix-snapshot-ready-png.png)

> WTFix creates an explicit trusted checkpoint of your addon SavedVariables and restores that checkpoint until **you** choose to replace it.

---

## Download

### GitHub — recommended for a complete installation

**[Download WTFix 0.8.8](https://github.com/eggntoast/WTFix-Public/releases/tag/v0.8.8)**

| Package | Use |
| --- | --- |
| `WTFix-Full-0.8.8.zip` | **Recommended for a fresh installation.** Includes the addon runtime, launcher and preparation components. |
| `WTFix-Launcher-0.8.8.zip` | For users who already have a compatible WTFix runtime installed. |

> Do **not** use GitHub's automatically generated **Source code** ZIP/TAR files as installation packages. Use the named WTFix downloads from the Releases page.

The CurseForge addon/runtime release is currently pending approval.

---

## What WTFix does

WTFix is designed around one simple idea:

**save a known-good addon setup and keep it trusted until you explicitly save another one.**

It supports addons declaring standard:

- account-wide SavedVariables
- per-character SavedVariables
- combinations of both

Coverage depends on what each addon actually stores in its declared SavedVariables.

### Save

**Save Current Settings → Save Snapshot → Reload Now**

The selected addon settings become your trusted recovery checkpoint.

### Restore

**Restore Saved Settings → Prepare Restore → Reload Now**

WTFix restores the trusted checkpoint and discards unsaved changes for protected addons.

---

## Windows preparation is required

Installing the addon runtime alone does **not** prepare recovery.

With WoW closed, run:

`WTFix Launcher.cmd`

The launcher prepares the recovery environment, verifies the disk bridge, backs up recovery inputs and opens Battle.net.

Until preparation succeeds, WTFix clearly shows:

> **SETUP REQUIRED**

and keeps **Save** and **Restore** disabled.

After successful preparation:

- keep both **WTFix** and **WTFix_Data** enabled
- normal `/reload` works
- relogs and full client restarts work
- the launcher does **not** remain running in the background
- you do **not** need to run it before every WoW session

See the full [installation guide](docs/installation.md).

---

## Addons with their own Apply / Reload button

Some addons keep changed settings in private working state until their own **Apply** or **Reload** action writes those settings into SavedVariables.

For those addons:

1. Disable WTFix protection for that addon.
2. Make the intended settings changes.
3. Use the addon's own Reload/Apply mechanism.
4. Verify the settings survived the reload.
5. Re-enable WTFix protection.
6. Explicitly **Save Snapshot** in WTFix.

Re-enabling protection alone does **not** adopt the changed settings.

**Save Snapshot** is the explicit action that makes the new state part of the trusted checkpoint.

This is a generic workflow for addons that delay writing their settings. Deleting another addon's SavedVariables is **not** part of the normal WTFix workflow.

See [Save, Restore and pending settings](docs/usage.md).

---

## Commands

| Command | Purpose |
| --- | --- |
| `/wtfix` | Open the WTFix panel |
| `/wtfix status` | Show preparation, checkpoint and recovery status |
| `/wtfix diff` | Show SavedVariable paths that differ from the trusted checkpoint |

A difference is not automatically a problem. Addons may update counters, caches, history and other session data after login.

---

## Recovery model

WTFix deliberately does **not** silently trust later changes.

- Save Snapshot captures declared SavedVariables when you explicitly save.
- Later addon writes do not silently replace the trusted checkpoint.
- Re-enabling protection does not automatically adopt changed data.
- Restore returns protected addons to the saved checkpoint.
- If preparation cannot be trusted, WTFix fails closed instead of pretending recovery is active.

---

## WTFix 0.8.8

- Separates addon runtime ownership from launcher-owned preparation.
- Preserves a compatible runtime installed through an addon manager.
- Adds fail-closed **SETUP REQUIRED** behavior.
- Supports the first snapshot immediately after valid preparation.
- Enables Restore once a valid checkpoint exists.
- Checks bridge compatibility independently of the WTFix product version.
- Preserves recovery through Save/reload, ordinary reload, Restore, relogs and cold starts.
- Provides separate Full and Launcher installation packages.

See the full [changelog](CHANGELOG.md).

---

## Documentation

- [Installation & setup](docs/installation.md)
- [Save, Restore & pending settings](docs/usage.md)
- [Preparation & ownership](docs/preparation.md)
- [Troubleshooting](docs/troubleshooting.md)
- [Source layout](docs/source-layout.md)
- [Licenses & third-party notices](docs/licenses.md)

---

## License

WTFix is released under the **MIT License**.

Bundled third-party components retain their respective licenses, copyrights and notices.

---

### Built for recovery, not guesswork.

**Save a setup you trust. Keep control over when it changes. Restore it when you need it.**
