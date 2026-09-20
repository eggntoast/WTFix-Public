# Changelog

## 0.8.8

- Separate the addon runtime from launcher-owned preparation so a compatible installed runtime is preserved.
- Show SETUP REQUIRED and block Save/Restore when preparation cannot be trusted.
- Allow the first Save after valid setup, with Restore available once a valid checkpoint exists.
- Check bridge compatibility independently of the product version.
- Provide Full and Launcher-only installation packages.
- Retain disk recovery across Save/reload, ordinary reload, Restore and subsequent cold starts.
