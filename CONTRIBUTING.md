# Contributing to WTFix

Thanks for helping improve WTFix.

## Before reporting a bug

Use the GitHub bug-report form and include the information it asks for.

For recovery or setup problems, `/wtfix status` is usually the most useful first diagnostic. For Save/capture problems, also include `/wtfix check`.

Review logs and command output before posting them publicly. SavedVariables, logs and recovery data can contain personal paths or addon data. Do not attach full SavedVariables or private backup objects unless you have reviewed them and they are specifically needed.

## Code, platform ports and larger changes

`WTFix-Public` is a curated public source export. The canonical implementation is maintained separately and exported here for releases.

Before doing substantial work, open an issue describing the problem or proposed change. A public fork or branch is useful for review, especially for platform-specific work that needs native testing.

Please include:

- the WTFix version you started from
- operating system and relevant version
- WoW Forever client/build information
- what you changed and why
- how you tested it
- any native-client or platform-specific evidence

Do not assume that a public-source patch will be merged verbatim. Accepted changes may be integrated into the canonical implementation first and then exported back to this repository.

## Recovery invariants

Changes must preserve WTFix's recovery model:

- **Save Snapshot** is the explicit trust/adoption boundary
- later writes must not silently replace the trusted checkpoint
- unsafe or untrusted preparation fails closed
- recovery must remain early enough to protect addons before they initialize
- the addon runtime and preparation-owned WTFix_Data companion have separate ownership
- SavedVariables preparation must remain byte-preserving, including binary and non-UTF-8 data
- ambiguous character or recovery identities must not be guessed

## Documentation and small fixes

Documentation fixes, reproduction details and focused issue reports are welcome.

For normal installation, use the named release packages rather than GitHub's automatically generated source archives.
