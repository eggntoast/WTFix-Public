#!/usr/bin/env python3
"""WTFix Linux preparation. Requires Python 3.10 or newer."""
import argparse
import os
from pathlib import Path
import sys

sys.dont_write_bytecode = True
from preparation import PreparationError, VERSION, plan, prepare, rollback


def assert_game_closed(proc=Path("/proc")):
    if sys.platform != "linux":
        raise PreparationError("Apply/rollback requires Linux. Use --dry-run for host inspection.")
    # Advisory observation, not proof across PID namespaces. Explicit owner
    # confirmation is also required; never kill a client or launch a runner.
    for pid in proc.iterdir():
        if not pid.name.isdigit():
            continue
        try:
            if pid.stat().st_uid != os.getuid():
                continue
            args = (pid / "cmdline").read_bytes().split(b"\0")
            if any(arg.replace(b"\\", b"/").rsplit(b"/", 1)[-1].lower() == b"wowb.exe" for arg in args):
                raise PreparationError("WowB.exe is running. Close it yourself before preparation.")
        except FileNotFoundError:
            continue  # Process exited between enumeration and read.
        except PermissionError as error:
            raise PreparationError("Cannot inspect user processes; no preparation performed") from error


def main(argv=None):
    parser = argparse.ArgumentParser(description=f"WTFix {VERSION} Linux preparation")
    parser.add_argument("--wow-folder", required=True, type=Path)
    parser.add_argument("--account", help="Exact WTF/Account folder name; never auto-selected")
    parser.add_argument("--state-dir", type=Path, default=Path(os.environ.get("XDG_STATE_HOME", Path.home() / ".local/state")) / "wtfix")
    parser.add_argument("--dry-run", action="store_true", help="Read/validate only; no files written")
    parser.add_argument("--confirm-wow-closed", action="store_true")
    parser.add_argument("--rollback-interrupted", action="store_true", help="Restore a journaled preparation only when original/new bytes still match")
    args = parser.parse_args(argv)
    try:
        if args.rollback_interrupted:
            if args.dry_run or not args.confirm_wow_closed:
                raise PreparationError("Rollback requires --confirm-wow-closed and cannot be combined with --dry-run")
            assert_game_closed()
            path = rollback(args.wow_folder)
            print(f"Preparation rolled back. Journal retained: {path}. No game was launched.")
            return 0
        if not args.account:
            raise PreparationError("Specify --account with the exact intended account folder name")
        template = Path(__file__).resolve().parent / "Companion/WTFix_Data"
        if not template.exists():
            template = Path(__file__).resolve().parents[2] / "Companion/WTFix_Data"
        p = plan(args.wow_folder, args.account, template)
        print(f"Installation: {p['wow']}\nSelected account folder: {args.account}")
        print(f"{len(p['targets'])} addon targets; {len(p['characters'])} unique prepared character names (account not authenticated).")
        if args.dry_run:
            print("DRY RUN ONLY. No files changed. Run again with --confirm-wow-closed to prepare recovery.")
            return 0
        if not args.confirm_wow_closed:
            raise PreparationError("Exit WoW in every session, then pass --confirm-wow-closed")
        result = prepare(p, args.state_dir, assert_game_closed)
        print("PREPARATION COMPLETE")
        print(f"Recovery input backup verified: {result['backup']}")
        print(f"Directory bridge and preparation files verified. TOC updates: {result['toc_updates']}")
        print("Start WoW through your normal manager. Check /wtfix status before using Save/Restore.")
        return 0
    except (PreparationError, OSError, ValueError, UnicodeError) as error:
        print(f"PREPARATION NOT COMPLETED: {error}", file=sys.stderr)
        return 1
    except KeyboardInterrupt:
        print("Cancelled. If a transaction lock remains, keep WoW closed and inspect the rollback instructions.", file=sys.stderr)
        return 130


if __name__ == "__main__":
    sys.dont_write_bytecode = True
    raise SystemExit(main())
