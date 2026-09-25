"""Protocol-1 preparation core. No game launch or Lua execution.

Filesystem policy is deliberately narrower than the Windows launcher: the selected
root may resolve through a link, but links inside input trees are rejected, except
the owned companion Disk directory link. This avoids incomplete scans/backups.
"""
from __future__ import annotations

import codecs
import hashlib
import json
import os
from pathlib import Path
import re
import stat
import uuid

VERSION = "0.9.3"
PROTOCOL = 1
TEMPLATE_FILES = {"Begin.lua", "End.lua", "BootstrapData.lua", "WTFix_Data.toc"}
LOCK = ".wtfix-preparation.lock"
MAX_FILE = 64 * 1024 * 1024
MAX_INPUT = 256 * 1024 * 1024


class PreparationError(RuntimeError):
    pass


def digest(data):
    return hashlib.sha256(data).hexdigest()


def linked(path):
    info = path.lstat()
    return stat.S_ISLNK(info.st_mode) or bool(getattr(info, "st_file_attributes", 0) & 0x400)


def exists(path):
    return os.path.lexists(path)


def ordinary(path, directory=False):
    if linked(path) or not (path.is_dir() if directory else path.is_file()):
        raise PreparationError(f"Expected an ordinary {'directory' if directory else 'file'}: {path}")


def read(path):
    ordinary(path)
    if path.stat().st_size > MAX_FILE:
        raise PreparationError(f"Input exceeds 64 MiB file limit: {path}")
    with path.open("rb") as stream:
        data = stream.read(MAX_FILE + 1)
    if len(data) > MAX_FILE:
        raise PreparationError(f"Input grew beyond file limit: {path}")
    return data


def children(path):
    ordinary(path, True)
    items = sorted(path.iterdir(), key=lambda p: p.name)
    folded = set()
    for item in items:
        key = item.name.casefold()
        if key in folded:
            raise PreparationError(f"Case-ambiguous paths in {path}")
        folded.add(key)
        if linked(item):
            raise PreparationError(f"Linked input is unsupported: {item}")
    return items


def tree(path, budget=None):
    """No silent permission failures and no link-following recursive glob."""
    if budget is None:
        budget = [MAX_INPUT]
    result = {}
    for item in children(path):
        if item.is_dir():
            result.update(tree(item, budget))
        else:
            data = read(item)
            budget[0] -= len(data)
            if budget[0] < 0:
                raise PreparationError(f"Input tree exceeds 256 MiB budget: {path}")
            result[item] = data
    return result


def compatible(data):
    matches = re.findall(rb"^## X-WTFix-Bridge-Protocol:\s*(\d+)\s*$", data, re.M)
    if len(matches) != 1 or int(matches[0]) != PROTOCOL:
        raise PreparationError("Incompatible bridge protocol. Update runtime and preparation tool; nothing was prepared.")


def lua_bytes(data):
    # The outer Lua literal transports bytes unchanged to the canonical parser.
    return '"' + ''.join(chr(b) if 32 <= b <= 126 and b not in (34, 92)
                         else "\\%03d" % b for b in data) + '"'


def lua_text(text):
    return lua_bytes(text.encode("utf-8", "strict"))


def toc_text(data):
    for bom, encoding in ((codecs.BOM_UTF8, "utf-8"), (codecs.BOM_UTF16_LE, "utf-16-le"),
                          (codecs.BOM_UTF16_BE, "utf-16-be")):
        if data.startswith(bom):
            return data[len(bom):].decode(encoding), encoding, bom
    try:
        return data.decode("utf-8"), "utf-8", b""
    except UnicodeDecodeError:
        # Latin-1 is a lossless byte mapping for ASCII TOC directives. It is NOT
        # a SavedVariables decoder. Untouched non-UTF-8 TOC bytes remain exact.
        return data.decode("latin-1"), "latin-1", b""


def patch_toc(data):
    text, encoding, bom = toc_text(data)
    lines = text.splitlines(keepends=True)
    optional = re.compile(r"^(\s*##\s*OptionalDeps\s*:\s*)([^\r\n]*)(\r?\n|\r)?$", re.I)
    marker = bool(re.search(r"^\s*##\s*X-WTFix-Managed:\s*1\s*$", text, re.M | re.I))
    for line in lines:
        match = optional.match(line)
        if match and any(dep.strip().casefold() == "wtfix" for dep in match[2].split(",")):
            return data
    newline = "\r\n" if "\r\n" in text else "\n" if "\n" in text else "\r" if "\r" in text else "\n"
    for index, line in enumerate(lines):
        match = optional.match(line)
        if match:
            deps = [d.strip() for d in match[2].split(",") if d.strip()]
            lines[index] = match[1] + ", ".join(deps + ["WTFix"]) + (match[3] or newline)
            if not marker:
                lines.insert(index + 1, "## X-WTFix-Managed: 1" + newline)
            break
    else:
        lines.insert(0, "## OptionalDeps: WTFix" + newline +
                     ("" if marker else "## X-WTFix-Managed: 1" + newline))
    return bom + ''.join(lines).encode(encoding)


def character_roster(accounts, selected):
    rows = []
    for account in children(accounts):
        if not account.is_dir():
            continue
        for realm in children(account):
            if not realm.is_dir() or realm.name.casefold() == "savedvariables":
                continue
            for char in children(realm):
                if char.is_dir():
                    key = char.name.replace(" ", "").replace("-", "").casefold()
                    if not key:
                        raise PreparationError("Empty normalized character name")
                    rows.append((account.name, realm.name, char.name, key))
    counts = {}
    for row in rows:
        counts[row[3]] = counts.get(row[3], 0) + 1
    admitted = [(realm, name) for account, realm, name, key in rows
                if account == selected and counts[key] == 1]
    if not admitted:
        raise PreparationError("No uniquely prepared character names. Log in once, exit, then select the correct account.")
    return rows, admitted


def companion_state(root):
    if not exists(root):
        return None
    ordinary(root, True)
    result = {}
    for path in root.iterdir():
        if path.name == "Disk" and linked(path):
            # Record lexical target: a broken bridge can be replaced safely.
            result["Disk"] = {"link": os.readlink(path)}
        elif path.name in TEMPLATE_FILES:
            result[path.name] = {"sha256": digest(read(path))}
        else:
            raise PreparationError(f"Unexpected companion content; preserve it for review: {path}")
    if set(result) - {"Disk"} != TEMPLATE_FILES:
        raise PreparationError("Incomplete existing companion; inspect it before preparing again")
    compatible(read(root / "WTFix_Data.toc"))
    return result


def plan(wow, account_name, template):
    wow = Path(wow).expanduser().resolve(strict=True)
    template = Path(template).resolve(strict=True)
    if account_name in ("", ".", "..") or any(c in account_name for c in "/\\\0"):
        raise PreparationError("Account must be one exact folder name, not a path")
    ordinary(wow, True)
    ordinary(wow / "WowB.exe")
    for part in ("Interface", "Interface/AddOns", "WTF", "WTF/Account"):
        ordinary(wow / part, True)
    addons = wow / "Interface/AddOns"
    runtime = addons / "WTFix"
    if not runtime.exists():
        raise PreparationError("WTFix runtime is missing. Install the compatible addon first; preparation never installs or updates it.")
    compatible(read(runtime / "WTFix.toc"))
    runtime_files = tree(runtime)
    template_files = tree(template)
    if {p.relative_to(template).as_posix() for p in template_files} != TEMPLATE_FILES:
        raise PreparationError("Companion template inventory does not match protocol-1 template")
    compatible(template_files[template / "WTFix_Data.toc"])
    old_companion = companion_state(addons / "WTFix_Data")
    account = wow / "WTF/Account" / account_name
    ordinary(account, True)
    ordinary(account / "SavedVariables", True)
    rows, characters = character_roster(wow / "WTF/Account", account_name)
    inputs = tree(account)
    saved = {p: b for p, b in inputs.items() if p.parent.name == "SavedVariables"
             and re.search(r"\.lua(?:\.bak)?$", p.name, re.I)}
    for path in saved:
        if path.name.casefold() in ("wtfix.lua", "wtfix.lua.bak", "wtfix_bridge.lua") and path.name not in (
                "WTFix.lua", "WTFix.lua.bak", "WTFix_Bridge.lua"):
            raise PreparationError(f"Noncanonical casing for an owned SavedVariables path: {path}")
    if sum(map(len, inputs.values())) > MAX_INPUT:
        raise PreparationError("Selected account exceeds 256 MiB input limit")
    marker = account / "SavedVariables/WTFix_Bridge.lua"
    if marker in saved and not saved[marker].startswith(b"-- WTFix bridge protocol 1"):
        raise PreparationError("Bridge marker belongs to unmanaged data")
    definitions, tocs = {}, {}
    # Do not silently skip symlinked addons or unreadable TOCs.
    for folder in addons.iterdir():
        if folder.name.casefold() in ("wtfix", "wtfix_data") and folder.name not in ("WTFix", "WTFix_Data"):
            raise PreparationError(f"Noncanonical casing for an owned addon path: {folder}")
        if folder.name in ("WTFix", "WTFix_Data"):
            continue
        if linked(folder):
            raise PreparationError(f"Linked addon unsupported: {folder}")
        if not folder.is_dir():
            continue
        target = {"account": [], "character": []}
        for path in children(folder):
            if path.suffix.casefold() != ".toc" or not path.is_file():
                continue
            data = read(path)
            relevant = False
            for line in toc_text(data)[0].splitlines():
                match = re.match(r"^\s*##\s*(SavedVariables|SavedVariablesPerCharacter)\s*:\s*(.*)$", line, re.I)
                if not match:
                    continue
                relevant = True
                scope = "account" if match[1].lower() == "savedvariables" else "character"
                for name in filter(None, (s.strip() for s in match[2].split(","))):
                    if not re.fullmatch(r"[A-Za-z_][A-Za-z0-9_]*", name):
                        raise PreparationError(f"Unsupported declaration {name!r} in {path}")
                    if name not in target[scope]:
                        target[scope].append(name)
            if relevant:
                tocs[path] = data
        if target["account"] or target["character"]:
            definitions[folder.name] = target
    # A casing alias could turn a nominal third-party path into an owned path.
    names = [p.name.casefold() for p in addons.iterdir()]
    if len(names) != len(set(names)):
        raise PreparationError("Case-ambiguous addon folders")
    expected_files = {name.casefold() + ".lua": name + ".lua" for name in definitions}
    for path in saved:
        expected = expected_files.get(path.name.casefold())
        if expected and path.name != expected:
            raise PreparationError(f"SavedVariables filename casing differs from its addon folder: {path}")
    return dict(wow=wow, account=account, template=template, characters=characters,
                roster=rows, inputs=inputs, saved=saved, tocs=tocs, targets=definitions,
                runtime=runtime_files, templates=template_files, old=old_companion)


def bootstrap(p, preparation_id):
    lines = [f"-- Generated by WTFix {VERSION} Linux preparation.",
             f'WTFIX_PREPARATION = {{protocol=1, id={lua_text(preparation_id)}, binding="unique-character-name", characters={{']
    lines.extend(f'{{realm={lua_text(realm)},name={lua_text(name)}}},' for realm, name in p["characters"])
    lines.extend(['}}', 'WTFIX_PREPARATION.bootstrap = function(ns)',
                  'WTFIX_BOOTSTRAP = {generated=true,diskBridge=true,launcherVersion=' + lua_text(VERSION) +
                  ',targets={},snapshot=nil,config=nil,warnings={},fallback={account={},characters={}}}'])
    for addon, target in sorted(p["targets"].items()):
        scopes = ','.join(scope + '={' + ','.join(lua_text(n) for n in target[scope]) + '}'
                          for scope in ("account", "character"))
        lines.append(f'WTFIX_BOOTSTRAP.targets[{lua_text(addon)}] = {{{scopes}}}')

    def add(path, assignment):
        if path not in p["saved"]:
            return False
        lines.extend(['do', 'local env, err = ns.ReadSavedVariables(' + lua_bytes(p["saved"][path]) + ')',
                      'if env then', assignment, 'else',
                      'WTFIX_BOOTSTRAP.warnings[#WTFIX_BOOTSTRAP.warnings+1] = ' + lua_text(path.name) +
                      ' .. ": " .. tostring(err)', 'end', 'end'])
        return True

    sv = p["account"] / "SavedVariables"
    for filename in ("WTFix.lua", "WTFix.lua.bak"):
        add(sv / filename, f'ns.ImportBootstrapSnapshot(env,{lua_text(filename)})')
    for addon, target in sorted(p["targets"].items()):
        if target["account"]:
            add(sv / (addon + ".lua"), f'WTFIX_BOOTSTRAP.fallback.account[{lua_text(addon)}] = env')
    # Preserve directory tuple verbatim; only preparation performs normalized matching.
    directories = sorted({f.parent for f in p["saved"] if f.parent != sv})
    for directory in directories:
        lines.extend(['do', 'local record = {realmFolder=' + lua_text(directory.parent.parent.name) +
                      ',characterName=' + lua_text(directory.parent.name) + ',addons={}}',
                      'WTFIX_BOOTSTRAP.fallback.characters[#WTFIX_BOOTSTRAP.fallback.characters+1] = record'])
        for addon, target in sorted(p["targets"].items()):
            if target["character"]:
                add(directory / (addon + ".lua"), f'record.addons[{lua_text(addon)}] = env')
        lines.append('end')
    lines.append('end')
    return ('\n'.join(lines) + '\n').encode("ascii")


def sync_dir(path):
    if os.name == "posix":
        fd = os.open(path, os.O_RDONLY | os.O_DIRECTORY)
        try:
            os.fsync(fd)
        finally:
            os.close(fd)


def write_new(path, data, mode=0o600):
    fd = os.open(path, os.O_WRONLY | os.O_CREAT | os.O_EXCL, mode)
    with os.fdopen(fd, "wb") as stream:
        stream.write(data)
        stream.flush()
        os.fsync(stream.fileno())
    sync_dir(path.parent)


def atomic(path, data, mode=0o600):
    pending = path.with_name(path.name + "." + uuid.uuid4().hex + ".tmp")
    try:
        write_new(pending, data, mode)
        os.replace(pending, path)
        sync_dir(path.parent)
    finally:
        if exists(pending):
            pending.unlink()


def safe_private_directory(path):
    path = Path(os.path.abspath(path))
    missing = []
    current = path
    while not exists(current):
        missing.append(current)
        current = current.parent
    # Existing ancestor links could redirect backup/journal writes.
    for ancestor in (current, *current.parents):
        ordinary(ancestor, True)
    for item in reversed(missing):
        item.mkdir(mode=0o700)
    ordinary(path, True)
    if os.name == "posix" and path.stat().st_mode & 0o077:
        raise PreparationError(f"State directory must be private (mode 0700): {path}")
    return path


def backup(p, state, txid):
    state = Path(os.path.abspath(state))
    if state == p["wow"] or p["wow"] in state.parents:
        raise PreparationError("Backup state must be outside the WoW installation")
    state = safe_private_directory(state)
    objects = safe_private_directory(state / "objects")
    records = []
    # Include original TOCs as well as every selected-account SV input.
    for path, data in sorted({**p["saved"], **p["tocs"]}.items()):
        sha = digest(data)
        target = objects / sha
        if not exists(target):
            write_new(target, data)
        if read(target) != data:
            raise PreparationError(f"Backup verification failed: {target}")
        records.append(dict(path=path.relative_to(p["wow"]).as_posix(), sha256=sha, bytes=len(data)))
    manifest = dict(version=VERSION, format=1, installation=str(p["wow"]),
                    account=p["account"].name, id=txid, files=records)
    path = state / (txid + ".json")
    write_new(path, json.dumps(manifest, indent=2).encode("utf-8"))
    if json.loads(read(path)) != manifest:
        raise PreparationError("Backup manifest verification failed")
    return path


def directory_link(path, target):
    path.symlink_to(target, target_is_directory=True)


def contained(wow, relative):
    path = Path(relative)
    if path.is_absolute() or ".." in path.parts or "\\" in relative or ":" in relative:
        raise PreparationError("Unsafe journal path")
    result = wow / path
    for parent in result.parents:
        if parent == wow:
            break
        ordinary(parent, True)
    return result


def rollback(wow):
    """Explicit recovery after an interrupted run. Conflict-check before restoring.

    This is a local crash journal, not an authentication mechanism. Refuse files
    changed by another writer rather than overwriting newly created user data.
    """
    wow = Path(wow).resolve(strict=True)
    txid = read(wow / LOCK).decode("ascii")
    if not re.fullmatch(r"[0-9a-f]{32}", txid):
        raise PreparationError("Invalid transaction lock; inspect manually")
    txn = wow / (".wtfix-preparation-" + txid)
    ordinary(txn, True)
    journal = json.loads(read(txn / "journal.json"))
    if journal["id"] != txid:
        raise PreparationError("Journal identity mismatch")
    final = wow / "Interface/AddOns/WTFix_Data"
    ordinary(final.parent.parent, True)
    ordinary(final.parent, True)
    ordinary(txn / "previous", True)
    previous = txn / "previous/WTFix_Data"
    current = companion_state(final)
    old = companion_state(previous)
    if current not in (None, journal["old"], journal["new"]) or old not in (None, journal["old"]):
        raise PreparationError("Companion changed since preparation; rollback refused")
    if journal["old"] is not None and current != journal["old"] and old != journal["old"]:
        raise PreparationError("Original companion unavailable; rollback refused")
    if old is not None and current == journal["old"]:
        raise PreparationError("Ambiguous original companion; rollback refused")
    changes = []
    for index, entry in enumerate(journal["edits"]):
        path = contained(wow, entry["path"])
        # Only the declared operation classes may be restored from the journal.
        rel = path.relative_to(wow).parts
        allowed = (len(rel) == 4 and rel[:2] == ("Interface", "AddOns") and path.suffix.casefold() == ".toc") or (
            len(rel) == 5 and rel[:2] == ("WTF", "Account") and rel[3] == "SavedVariables"
            and rel[4] in ("WTFix.lua", "WTFix_Bridge.lua"))
        if not allowed:
            raise PreparationError("Unsupported journal operation")
        before = read(txn / f"before-{index}") if entry["before"] is not None else None
        after = read(txn / f"after-{index}")
        if (digest(before) if before is not None else None) != entry["before"] or digest(after) != entry["after"]:
            raise PreparationError("Journal bytes failed verification")
        actual = read(path) if exists(path) else None
        if actual not in (before, after):
            raise PreparationError(f"Concurrent data change; rollback refused: {path}")
        changes.append((path, before, entry["mode"]))
    if current == journal["new"]:
        rejected = txn / "rejected"
        if not exists(rejected):
            rejected.mkdir(mode=0o700)
        ordinary(rejected, True)
        if exists(rejected / "WTFix_Data"):
            raise PreparationError("Rollback destination occupied; inspect the journal")
        # Preserve the complete rejected companion rather than deleting a tree.
        # A second interruption cannot leave a half-deleted live companion.
        os.replace(final, rejected / "WTFix_Data")
        sync_dir(final.parent)
        sync_dir(rejected)
    if old is not None:
        if exists(final):
            raise PreparationError("Ambiguous original companion; rollback refused")
        os.replace(previous, final)
        sync_dir(previous.parent)
        sync_dir(final.parent)
    for path, before, mode in reversed(changes):
        if before is None:
            if exists(path):
                path.unlink()
                sync_dir(path.parent)
        else:
            atomic(path, before, mode)
    sync_dir(final.parent)
    sync_dir(wow)
    (wow / LOCK).unlink()
    sync_dir(wow)
    # Retain the private journal as evidence; no recursive cleanup of unknown data.
    return txn


def prepare(p, state, guard, link=directory_link, observe=lambda point: None):
    """guard is platform process observation; link is injectable for host fixtures."""
    guard()
    wow = p["wow"]
    # Re-scan before locking/writing; catch stale input/roster/template plans.
    if plan(wow, p["account"].name, p["template"]) != p:
        raise PreparationError("Inputs changed; re-plan before preparing")
    if exists(wow / LOCK):
        raise PreparationError("Preparation lock exists. Keep WoW closed and inspect/rollback the interrupted transaction.")
    txid = uuid.uuid4().hex
    manifest = backup(p, state, txid)
    observe("backed-up")
    guard()
    if plan(wow, p["account"].name, p["template"]) != p:
        raise PreparationError("Inputs changed during backup; preparation stopped")
    txn = wow / (".wtfix-preparation-" + txid)
    txn.mkdir(mode=0o700)
    stage = txn / "stage/WTFix_Data"
    stage.parent.mkdir(mode=0o700)
    stage.mkdir(mode=0o700)
    (txn / "previous").mkdir(mode=0o700)
    final = wow / "Interface/AddOns/WTFix_Data"
    sv = p["account"] / "SavedVariables"
    # Equal directory depth gives the staged and installed link the same target.
    relative_target = os.path.relpath(sv, final)
    link(stage / "Disk", relative_target)
    if (stage / "Disk").resolve() != sv:
        raise PreparationError("Staged directory bridge resolved to the wrong target")
    for source, data in p["templates"].items():
        write_new(stage / source.name, bootstrap(p, txid) if source.name == "BootstrapData.lua" else data)
    sync_dir(stage.parent)
    edits = []
    for path, before in sorted(p["tocs"].items()):
        after = patch_toc(before)
        if after != before:
            edits.append((path, before, after))
    primary = sv / "WTFix.lua"
    if primary not in p["saved"]:
        edits.append((primary, None, b"WTFIX_DB = {}\n"))
    marker = sv / "WTFix_Bridge.lua"
    evidence = f'-- WTFix bridge protocol 1\nWTFIX_BRIDGE_EVIDENCE = {{protocol=1,id={lua_text(txid)}}}\n'.encode("ascii")
    edits.append((marker, p["saved"].get(marker), evidence))
    journal = dict(id=txid, old=p["old"], new=companion_state(stage), edits=[])
    for index, (path, before, after) in enumerate(edits):
        if before is not None:
            write_new(txn / f"before-{index}", before)
        write_new(txn / f"after-{index}", after)
        journal["edits"].append(dict(path=path.relative_to(wow).as_posix(),
            before=digest(before) if before is not None else None, after=digest(after),
            mode=stat.S_IMODE(path.stat().st_mode) if before is not None else 0o600))
    write_new(txn / "journal.json", json.dumps(journal, indent=2).encode("utf-8"))
    observe("staged")
    guard()
    if plan(wow, p["account"].name, p["template"]) != p:
        raise PreparationError("Inputs changed during staging; preparation stopped")
    # The complete durable journal exists before acquiring the commit lock.
    write_new(wow / LOCK, txid.encode("ascii"))
    try:
        observe("locked")
        for index, (path, before, after) in enumerate(edits):
            contained(wow, path.relative_to(wow).as_posix())
            if (read(path) if exists(path) else None) != before:
                raise PreparationError(f"Concurrent modification: {path}")
            if before is None:
                write_new(path, after)
            else:
                atomic(path, after, journal["edits"][index]["mode"])
            observe(f"edit-{index}")
        guard()
        if companion_state(final) != p["old"]:
            raise PreparationError("Existing companion changed during preparation")
        if exists(final):
            os.replace(final, txn / "previous/WTFix_Data")
            sync_dir(final.parent)
            sync_dir(txn / "previous")
        observe("old-moved")
        os.replace(stage, final)
        sync_dir(final.parent)
        sync_dir(stage.parent)
        observe("new-installed")
        if companion_state(final) != journal["new"] or read(final / "Disk/WTFix.lua") != read(primary):
            raise PreparationError("Installed companion/bridge verification failed")
        if read(final / "Disk/WTFix_Bridge.lua") != evidence:
            raise PreparationError("Installed bridge evidence verification failed")
        observe("verified")
    except (Exception, KeyboardInterrupt):
        rollback(wow)
        raise
    (wow / LOCK).unlink()
    sync_dir(wow)
    # Keep the private journal/previous companion for inspection. Never load it
    # as a candidate, and never automatically promote backup objects to authority.
    return dict(id=txid, backup=str(manifest), journal=str(txn), targets=len(p["targets"]),
                toc_updates=sum(path.suffix.casefold() == ".toc" for path, _, _ in edits))
