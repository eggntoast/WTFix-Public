# WTFix

> [!IMPORTANT]
> **WTFix is retired.**
>
> Blizzard fixed the WoW Forever SavedVariables persistence bug that WTFix was created to work around. Current Forever builds now persist addon SavedVariables normally without WTFix, confirmed in native-client testing on **26 September 2026**.
>
> **WTFix 0.9.3 is the final recovery release.** It is preserved here for historical/reference purposes and is no longer recommended for current WoW Forever builds.

## Final status

WTFix existed to protect addon settings while WoW Forever's SavedVariables persistence was unreliable.

That underlying client problem has now been fixed, so the recovery layer, early-load bridge and platform preparation workflow are no longer needed for normal SavedVariables persistence.

The source, documentation and previous release packages remain available so existing installations can be understood or removed safely and the engineering history is preserved.

No macOS port or further platform expansion is planned for the retired recovery product.

## Existing installations

### Windows

With WoW completely closed, run the included **`Uninstall WTFix.cmd`** to remove WTFix preparation and managed dependency entries.

The current Windows uninstaller preserves:

- the WTFix runtime
- SavedVariables
- local WTFix history/configuration

Remove the runtime separately through CurseForge, another addon manager, or your manual installation method if you no longer want it installed.

### Linux

WTFix 0.9.3 does not include an automatic Linux uninstall workflow.

Preserve your SavedVariables and review the historical [Linux preparation guide](docs/linux-preparation.md) before changing prepared files manually.

## Final release

**[WTFix 0.9.3](https://github.com/eggntoast/WTFix-Public/releases/tag/v0.9.3)** remains available as the final historical release.

Its release assets and checksums are preserved unchanged.

## Historical documentation

The following documentation describes WTFix 0.9.3 as it operated before retirement:

- [Windows installation & setup](docs/installation.md)
- [Linux installation & preparation](docs/linux-preparation.md)
- [Save, Restore & pending settings](docs/usage.md)
- [Preparation & ownership](docs/preparation.md)
- [Troubleshooting](docs/troubleshooting.md)
- [Source layout](docs/source-layout.md)
- [Licenses & third-party notices](docs/licenses.md)

## License

WTFix remains available under the **MIT License**.

Bundled third-party components retain their respective licenses, copyrights and notices.
