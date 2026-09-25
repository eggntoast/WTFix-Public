from __future__ import annotations

import hashlib
import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
errors: list[str] = []


def fail(message: str) -> None:
    errors.append(message)


manifest_path = ROOT / "docs" / "export-manifest.json"
manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
version = str(manifest["product_version"])
bridge_protocol = int(manifest["bridge_protocol"])

# Public implementation must continue to match the release export manifest exactly.
for entry in manifest["implementation_files"]:
    path = ROOT / entry["public_path"]
    if not path.is_file():
        fail(f"missing manifest file: {entry['public_path']}")
        continue

    data = path.read_bytes()
    actual_size = len(data)
    actual_sha = hashlib.sha256(data).hexdigest().upper()

    if actual_size != int(entry["bytes"]):
        fail(
            f"size mismatch: {entry['public_path']} "
            f"(expected {entry['bytes']}, got {actual_size})"
        )
    if actual_sha != str(entry["sha256"]).upper():
        fail(
            f"SHA256 mismatch: {entry['public_path']} "
            f"(expected {entry['sha256']}, got {actual_sha})"
        )

# Version/protocol declarations that should move together for a release.
expected_fragments = {
    "addon/WTFix/WTFix.toc": [
        f"## Version: {version}",
        f"## X-WTFix-Bridge-Protocol: {bridge_protocol}",
    ],
    "addon/WTFix/Core.lua": [f'ns.version = "{version}"'],
    "launcher/Launcher.ps1": [f"$version = '{version}'"],
    "launcher/WTFix.ps1": [
        f'$WTFixVersion = "{version}"',
        f"$BridgeProtocol = {bridge_protocol}",
    ],
    "linux/preparation.py": [f'VERSION = "{version}"'],
    "launcher/Companion/WTFix_Data/WTFix_Data.toc": [
        f"## X-WTFix-Bridge-Protocol: {bridge_protocol}"
    ],
    "linux/Companion/WTFix_Data/WTFix_Data.toc": [
        f"## X-WTFix-Bridge-Protocol: {bridge_protocol}"
    ],
}

for relative, fragments in expected_fragments.items():
    text = (ROOT / relative).read_text(encoding="utf-8")
    for fragment in fragments:
        if fragment not in text:
            fail(f"missing expected declaration in {relative}: {fragment}")

# Markdown is normalized to LF so small edits do not become whole-file diffs.
for path in ROOT.rglob("*.md"):
    data = path.read_bytes()
    if b"\r\n" in data:
        fail(f"CRLF found in Markdown file: {path.relative_to(ROOT).as_posix()}")

attributes = (ROOT / ".gitattributes").read_text(encoding="utf-8")
if "*.md text eol=lf" not in attributes:
    fail(".gitattributes does not enforce LF for Markdown")

# Check relative Markdown links/images against the tracked tree.
link_re = re.compile(r"!?\[[^\]]*\]\(([^)]+)\)")
for path in ROOT.rglob("*.md"):
    text = path.read_text(encoding="utf-8")
    for match in link_re.finditer(text):
        target = match.group(1).strip()
        if (
            not target
            or target.startswith("#")
            or re.match(r"^[a-z][a-z0-9+.-]*:", target, re.IGNORECASE)
        ):
            continue

        clean = target.split("#", 1)[0].split("?", 1)[0]
        if not clean:
            continue

        resolved = (path.parent / clean).resolve()
        try:
            resolved.relative_to(ROOT.resolve())
        except ValueError:
            fail(
                f"relative Markdown link escapes repository: "
                f"{path.relative_to(ROOT).as_posix()} -> {target}"
            )
            continue

        if not resolved.exists():
            fail(
                f"broken relative Markdown link: "
                f"{path.relative_to(ROOT).as_posix()} -> {target}"
            )

if errors:
    print("WTFix public export validation FAILED:")
    for error in errors:
        print(f" - {error}")
    sys.exit(1)

print(
    f"WTFix public export validation passed: "
    f"version {version}, {len(manifest['implementation_files'])} manifest files."
)
