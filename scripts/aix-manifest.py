#!/usr/bin/env python3
"""
Manage AIX manifest and snapshots.

Deterministic helper for bootstrap/upgrade/adopt scripts.
"""

import argparse
import hashlib
import json
from datetime import date
from pathlib import Path
from typing import Any, Dict, Optional


def _today() -> str:
    return date.today().isoformat()


def _load_manifest(path: Path) -> Dict[str, Any]:
    if path.exists():
        return json.loads(path.read_text())
    return {"manifest_version": 1, "files": []}


def _save_manifest(path: Path, data: Dict[str, Any]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    data.setdefault("manifest_version", 1)
    data.setdefault("files", [])
    path.write_text(json.dumps(data, indent=2) + "\n")


def _sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(8192), b""):
            digest.update(chunk)
    return digest.hexdigest()


def _relpath(path: Path, root: Path) -> str:
    if not path.is_absolute():
        return str(path)
    return str(path.resolve().relative_to(root.resolve()))


def _source_ref(source: Path, framework_root: Optional[Path]) -> str:
    if framework_root is None:
        return str(source)
    try:
        return str(source.resolve().relative_to(framework_root.resolve()))
    except ValueError:
        return str(source)


def init_manifest(args: argparse.Namespace) -> None:
    manifest_path = Path(args.manifest)
    data = _load_manifest(manifest_path)
    data.setdefault("installed_at", _today())
    data["updated_at"] = _today()
    if args.aix_version:
        data["aix_version"] = args.aix_version
    _save_manifest(manifest_path, data)


def touch_manifest(args: argparse.Namespace) -> None:
    manifest_path = Path(args.manifest)
    data = _load_manifest(manifest_path)
    data["updated_at"] = _today()
    if args.aix_version:
        data["aix_version"] = args.aix_version
    _save_manifest(manifest_path, data)


def record_file(
    manifest_path: Path,
    repo_root: Path,
    source: Path,
    dest: Path,
    capability: Optional[str],
    framework_root: Optional[Path],
    aix_version: Optional[str],
) -> None:
    data = _load_manifest(manifest_path)
    data.setdefault("files", [])

    dest_path = dest
    if not dest_path.is_absolute():
        dest_path = (repo_root / dest_path).resolve()

    if not dest_path.exists():
        return

    dest_rel = _relpath(dest_path, repo_root)
    if any(entry.get("path") == dest_rel for entry in data["files"]):
        return

    snapshot_root = repo_root / ".aix" / "snapshots"
    snapshot_path = snapshot_root / dest_rel
    snapshot_path.parent.mkdir(parents=True, exist_ok=True)

    if not snapshot_path.exists():
        if source.exists():
            snapshot_path.write_bytes(source.read_bytes())
        else:
            snapshot_path.write_bytes(dest_path.read_bytes())

    entry = {
        "path": dest_rel,
        "source": _source_ref(source, framework_root),
        "sha256": _sha256(snapshot_path),
    }
    if capability:
        entry["capability"] = capability

    data["files"].append(entry)
    data["updated_at"] = _today()
    if aix_version:
        data["aix_version"] = aix_version

    _save_manifest(manifest_path, data)


def record(args: argparse.Namespace) -> None:
    record_file(
        manifest_path=Path(args.manifest),
        repo_root=Path(args.repo_root),
        source=Path(args.source),
        dest=Path(args.dest),
        capability=args.capability,
        framework_root=Path(args.framework_root) if args.framework_root else None,
        aix_version=args.aix_version,
    )


def record_dir(args: argparse.Namespace) -> None:
    source_root = Path(args.source_root)
    dest_root = Path(args.dest_root)
    repo_root = Path(args.repo_root)
    manifest_path = Path(args.manifest)
    framework_root = Path(args.framework_root) if args.framework_root else None

    if not source_root.exists():
        return

    for source_path in source_root.rglob("*"):
        if source_path.is_dir():
            continue
        rel = source_path.relative_to(source_root)
        dest_path = dest_root / rel
        record_file(
            manifest_path=manifest_path,
            repo_root=repo_root,
            source=source_path,
            dest=dest_path,
            capability=args.capability,
            framework_root=framework_root,
            aix_version=args.aix_version,
        )


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description="Manage AIX manifest and snapshots")
    subparsers = parser.add_subparsers(dest="command", required=True)

    init_parser = subparsers.add_parser("init", help="Initialize manifest")
    init_parser.add_argument("--manifest", required=True)
    init_parser.add_argument("--aix-version")
    init_parser.set_defaults(func=init_manifest)

    touch_parser = subparsers.add_parser("touch", help="Update manifest timestamps")
    touch_parser.add_argument("--manifest", required=True)
    touch_parser.add_argument("--aix-version")
    touch_parser.set_defaults(func=touch_manifest)

    record_parser = subparsers.add_parser("record", help="Record a single file")
    record_parser.add_argument("--manifest", required=True)
    record_parser.add_argument("--repo-root", required=True)
    record_parser.add_argument("--source", required=True)
    record_parser.add_argument("--dest", required=True)
    record_parser.add_argument("--capability")
    record_parser.add_argument("--framework-root")
    record_parser.add_argument("--aix-version")
    record_parser.set_defaults(func=record)

    record_dir_parser = subparsers.add_parser("record-dir", help="Record a directory tree")
    record_dir_parser.add_argument("--manifest", required=True)
    record_dir_parser.add_argument("--repo-root", required=True)
    record_dir_parser.add_argument("--source-root", required=True)
    record_dir_parser.add_argument("--dest-root", required=True)
    record_dir_parser.add_argument("--capability")
    record_dir_parser.add_argument("--framework-root")
    record_dir_parser.add_argument("--aix-version")
    record_dir_parser.set_defaults(func=record_dir)

    return parser


def main() -> None:
    parser = build_parser()
    args = parser.parse_args()
    args.func(args)


if __name__ == "__main__":
    main()
