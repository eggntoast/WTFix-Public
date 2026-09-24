# WTFix 0.9.2 — Linux preparation

Native Linux/Wine validation is still pending.
Host tests cover its preparation contracts, backups, interruption recovery and
byte preservation. They do not prove a particular runner follows the bridge.
Use a disposable installation until that environment passes the procedure below.
Product version is 0.9.2; bridge protocol and snapshot schema remain 1.

## Choose a package

- **WTFix-Linux-Full-0.9.2.zip:** preparation tools, companion template and addon.
  With WoW closed, install the bundled `AddOn/WTFix` folder into the disposable
  game's `Interface/AddOns`. If an addon manager already owns WTFix, update the
  runtime through that manager instead of copying an older bundled runtime over it.
- **WTFix-Linux-Prepare-0.9.2.zip:** preparation tools and companion template only,
  for a runtime already installed through an addon manager or another package.

Extract the complete package into a normal user-owned tools directory outside
`Interface/AddOns`. Keep `prepare.py`, `preparation.py` and `Companion` together.
The tools never install, update or downgrade an existing runtime. Neither package
contains a Wine runner, Python interpreter or background service. The ordinary
`WTFix-Full` and `WTFix-Launcher` packages contain the **Windows** launcher.

## Scope and ownership

`linux/prepare.py` is a thin Linux CLI. `preparation.py` contains the portable
planning, generation, backup and transaction logic. Python 3.10+ standard library
only; no Wine libraries or third-party Python packages. Linux, not a distro name,
is the platform boundary. A filesystem visible and writable to both preparation
and the selected game runner is required. Flatpak/container visibility and Wine's
handling of the directory link must be demonstrated in each tested environment.

The user selects the exact folder containing `WowB.exe` and the exact account
folder. There is no prefix discovery, remembered account, runner selection, game
launch, terminal spawning, service, elevation or process termination. Process
inspection is advisory and limited to visible processes for the current user;
PID namespaces, other users and races prevent proof that no game is running.
Run from the host session that owns the installation, close every game instance,
and explicitly confirm this before applying or rolling back preparation.

The runtime must already be installed. Preparation never installs, replaces or
downgrades `Interface/AddOns/WTFix`. Runtime and companion protocol compatibility
are checked before writes; product version equality is not required. The only
game-side writes are relevant managed TOCs, launcher-owned `WTFix_Data`, the bridge
marker, a minimal `WTFix.lua` **only if absent**, and private transaction journals.
Existing `WTFix.lua`, `.bak` and third-party SavedVariables are never rewritten.

The companion uses a relative POSIX **directory** symlink to the selected account's
SavedVariables directory. Replacing a file inside that directory keeps the bridge
current. There are no file hardlinks or symlinks. The exact canonical companion
template is used, including its WoW TOC path syntax. Whether the Windows client
inside a particular runner follows this POSIX link is a native acceptance gate.

Issue [#5](https://github.com/eggntoast/WTFix-Public/issues/5) informed the Linux
filesystem approach. This slice deliberately leaves its prefix and game-launch
integration out. It does not adopt a separate Linux snapshot implementation.

## Prepare with WoW closed

From the repository, substitute the actual **disposable** paths and exact account:

```sh
python3 -B linux/prepare.py \
  --wow-folder '/absolute/disposable/WoW/_classic_beta_' \
  --account 'TEST_ACCOUNT' --state-dir '/absolute/private-test-state' --dry-run

python3 -B linux/prepare.py \
  --wow-folder '/absolute/disposable/WoW/_classic_beta_' \
  --account 'TEST_ACCOUNT' --state-dir '/absolute/private-test-state' \
  --confirm-wow-closed
```

In a Linux release archive, run `prepare.py` from its extracted folder
instead. No executable permission or shell wrapper is required. A dry run writes
nothing and does not claim recovery is prepared. Without `--state-dir`, private
state defaults to `$XDG_STATE_HOME/wtfix` or `~/.local/state/wtfix`, outside the game.

Selected-account inputs and all relevant original TOCs are backed up as verified
SHA256-addressed byte objects with a per-run inventory. Directory modes are 0700;
new files are 0600 on POSIX. Existing state directories must already be private.
Backups contain private addon data: do not publish or put them in an addon package.
The tool retains backups and journals without automatic retention pruning.

## Contracts preserved

- SavedVariables source is read as bytes and transported in ASCII Lua literals
  using three-digit decimal escapes. Python never decodes or executes that source.
  The unchanged data-only Lua parser qualifies bootstrap input.
- Primary and `.bak` snapshot candidates are passed to the same Lua import and
  authority code as Windows. Backup objects and transaction journals are never
  recovery candidates. Ordinary preparation does not adopt live settings.
- Explicit Save Snapshot remains the adoption boundary. The runtime continues to
  enforce readiness and snapshot semantics, including first Save without a snapshot.
- Character roster uniqueness is checked across all locally visible account
  folders, with spaces/hyphens removed and conservative case folding. Physical
  realm/name tuples are preserved for fallback. This is **not account authentication**;
  absent/inaccessible accounts or another installation cannot establish active-account
  identity. Runtime reports “account not verified” exactly as on Windows.
- All relevant installed TOC variants are considered as in the canonical preparer.
  Their union remains a prepared declaration inventory, not proof an addon is loaded.
  No runtime/companion ownership changes and no bridge protocol change are introduced.

## Current limits

Paths below the selected root must be ordinary directories/files, except the owned
companion `Disk` link. Linked addons, linked WTF trees, unreadable inputs, ambiguous
case aliases and unexpected companion content cause refusal, not silent omission.
The explicitly selected root itself may resolve through a link. Mount points are
not symlinks, but their actual permissions, rename, durability and link behavior
still matter. Native Linux filesystems are the first validation target; NTFS/exFAT,
network filesystems and sandboxed runners are not yet qualified.

A compatible runtime, an account SavedVariables directory and at least one uniquely
prepared character directory must exist. A new user must log in once and exit to
create those directories. Input limits are 64 MiB per file and 256 MiB per selected
account. These are explicit preparer resource limits, not claims about WoW limits.
Generated source can hit the file limit after escape expansion and will be refused
before active preparation changes. Unknown existing companion files are retained
for manual review. There is no uninstall, GUI, automatic link remediation or pruning.

## Interrupted preparation

Preparation stages a complete companion, verifies immutable backup objects and
writes a durable operation journal before creating `.wtfix-preparation.lock` in
the selected game folder. It rechecks the plan and process observation at commit
boundaries. Multi-file preparation is not an atomic filesystem transaction.
**Keep WoW closed while preparation runs, after an error, or while a lock exists.**
The unchanged runtime does not inspect this lock.

Caught apply errors attempt conflict-checked rollback. A killed process leaves the
lock/journal for explicit recovery; a new preparation refuses to proceed. To restore
the pre-preparation filesystem state, while the disposable game remains closed:

```sh
python3 -B linux/prepare.py \
  --wow-folder '/absolute/disposable/WoW/_classic_beta_' \
  --rollback-interrupted --confirm-wow-closed
```

Rollback first verifies all affected bytes against original/new journal hashes.
It refuses conflicting newer data instead of overwriting it. Rejected and previous
companions are retained in the private journal. Never remove the lock to bypass a
conflict or delete another addon's SavedVariables. Diagnose the conflict first.
Failures before the lock can leave scratch journals/backups but no active changes.
Successful runs retain history; nothing automatically reads it back into a checkpoint.

Journals and SHA256 checks detect changes; they are not authentication against a
malicious same-user writer. File preconditions cannot eliminate all concurrent-write
races. Per-file replace, directory rename and POSIX fsync reduce interruption risk;
actual power-loss behavior on a particular filesystem is not host-test proof.

## Validation and unresolved integrity work

Run the portable fixture suite with an actual Lua 5.1 executable:

```sh
python3 -B tests/LinuxPreparation.py --lua /usr/bin/lua5.1
```

On Windows it injects Windows junctions and a fixture process guard; production
apply remains Linux-only. On Linux it exercises the real POSIX symlink backend.
The same fixtures load generated data through the unchanged companion and runtime.
The canonical binary regression checks all byte values, invalid UTF-8, BOM-in-data,
2 MiB length-prefixed strings, newer-backup authority, explicit Save and disk restore.
These are host/harness results, not native-client SavedVariables serialization proof.

Two existing recovery-integrity questions remain explicitly outside this slice:
(1) whether rejected preparation can subsequently overwrite checkpoint storage in
the native client, and (2) stronger qualification/reporting when a structurally valid
higher-generation candidate has invalid contents. No Lua change or native observation
in this slice resolves them. Filesystem backup preservation is separate from in-game
recovery adoption. Neither backups nor this transaction mechanism should be presented
as a fix for those runtime questions.

## Smallest isolated native Linux acceptance

1. Run the host suite on Linux first. Use a disposable game installation and runner
   prefix, with fresh test WTF data and a test character; do not use
   the trusted installation for native validation. Install the 0.9.2 runtime and one known
   settings addon. Record runner, filesystem, Python and client versions.
2. Close the disposable game. Dry-run then apply with explicit folder/account.
   Inspect the backup manifest and `readlink` target. Confirm the runtime and all
   pre-existing SavedVariables hashes are unchanged by preparation.
3. Start via the existing runner. Check preparation ready, Disk bridge Loaded and
   the expected test character. Save one harmless non-default setting, reload,
   and verify it plus the new generation. Perform one ordinary reload and one full
   cold start without preparation; the same checkpoint must recover from disk.
4. Change that setting without saving, Prepare Restore and reload; the checkpoint
   must return without generation advancement. Capture status and any Lua errors.

This establishes only that runner/filesystem combination. It is not universal Wine,
Proton, Lutris, Bottles or Flatpak acceptance. Do not run a rejected-preparation
shutdown experiment against trusted data; that remains a separate isolated proof.
