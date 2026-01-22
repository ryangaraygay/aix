#!/usr/bin/env python3
"""
Compute three-way merges between local files and updated AIX templates.

This is deterministic. It does not overwrite local files unless --apply is set.
"""

import argparse
import hashlib
import json
import os
import subprocess
from pathlib import Path
from typing import Any, Dict, List, Optional, Tuple


def _git_root() -> Path:
    result = subprocess.run(
        ["git", "rev-parse", "--show-toplevel"],
        capture_output=True,
        text=True,
    )
    if result.returncode == 0:
        return Path(result.stdout.strip())
    return Path.cwd()


def _sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(8192), b""):
            digest.update(chunk)
    return digest.hexdigest()


def _read_manifest(path: Path) -> Dict[str, Any]:
    if not path.exists():
        raise FileNotFoundError(f"Manifest not found: {path}")
    return json.loads(path.read_text())


def _merge_three_way(local: Path, base: Path, new: Path) -> Tuple[int, str]:
    result = subprocess.run(
        ["git", "merge-file", "-p", str(local), str(base), str(new)],
        capture_output=True,
        text=True,
    )
    return result.returncode, result.stdout


def _write_output(path: Path, content: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(content)


def _resolve_framework_root(path: Optional[str]) -> Path:
    if path:
        return Path(path)
    env_path = os.environ.get("AIX_FRAMEWORK")
    if env_path:
        return Path(env_path)
    return Path.home() / "tools" / "aix"


def sync(args: argparse.Namespace) -> Dict[str, Any]:
    repo_root = Path(args.repo_root) if args.repo_root else _git_root()
    framework_root = _resolve_framework_root(args.framework_root)
    manifest_path = Path(args.manifest) if args.manifest else repo_root / ".aix" / "manifest.json"
    output_dir = Path(args.output_dir) if args.output_dir else repo_root / ".aix" / "sync"
    apply_changes = args.apply

    manifest = _read_manifest(manifest_path)
    results: List[Dict[str, Any]] = []

    for entry in manifest.get("files", []):
        rel_path = entry.get("path")
        source_ref = entry.get("source")
        if not rel_path or not source_ref:
            results.append({
                "path": rel_path,
                "status": "invalid_entry",
            })
            continue

        local_path = repo_root / rel_path
        base_path = repo_root / ".aix" / "snapshots" / rel_path
        new_path = framework_root / source_ref

        status = None
        action = None
        output_path = None
        applied = False

        if not new_path.exists():
            status = "upstream_missing"
            action = "review_removal"
        elif not local_path.exists():
            status = "local_missing"
            action = "restore_from_upstream"
            if apply_changes:
                _write_output(local_path, new_path.read_text())
                applied = True
            else:
                output_path = output_dir / rel_path
                _write_output(output_path, new_path.read_text())
        elif not base_path.exists():
            status = "no_snapshot"
            action = "manual_review"
        else:
            base_hash = _sha256(base_path)
            local_hash = _sha256(local_path)
            new_hash = _sha256(new_path)

            if new_hash == base_hash and local_hash == base_hash:
                status = "unchanged"
                action = "none"
            elif new_hash == base_hash and local_hash != base_hash:
                status = "local_modified_only"
                action = "none"
            elif local_hash == base_hash and new_hash != base_hash:
                status = "update_available"
                action = "apply_upstream"
                if apply_changes:
                    _write_output(local_path, new_path.read_text())
                    applied = True
                else:
                    output_path = output_dir / rel_path
                    _write_output(output_path, new_path.read_text())
            else:
                merge_code, merged = _merge_three_way(local_path, base_path, new_path)
                if merge_code == 0:
                    status = "merge_clean"
                    action = "apply_merge"
                    if apply_changes:
                        _write_output(local_path, merged)
                        applied = True
                    else:
                        output_path = output_dir / rel_path
                        _write_output(output_path, merged)
                elif merge_code == 1:
                    status = "merge_conflict"
                    action = "manual_merge"
                    output_path = output_dir / rel_path
                    _write_output(output_path, merged)
                else:
                    status = "merge_error"
                    action = "manual_review"

        results.append({
            "path": rel_path,
            "status": status,
            "action": action,
            "output": str(output_path) if output_path else None,
            "applied": applied,
            "capability": entry.get("capability"),
        })

    summary = {}
    for item in results:
        summary[item["status"]] = summary.get(item["status"], 0) + 1

    return {
        "repo_root": str(repo_root),
        "framework_root": str(framework_root) if framework_root.exists() else None,
        "manifest": str(manifest_path),
        "output_dir": str(output_dir),
        "applied": apply_changes,
        "summary": summary,
        "results": results,
    }


def main() -> None:
    parser = argparse.ArgumentParser(description="Compute AIX sync merge proposals")
    parser.add_argument("--repo-root", help="Path to repo root")
    parser.add_argument("--framework-root", help="Path to AIX framework repo")
    parser.add_argument("--manifest", help="Path to manifest.json")
    parser.add_argument("--output-dir", help="Directory for merge outputs")
    parser.add_argument("--apply", action="store_true", help="Apply clean merges to local files")
    parser.add_argument("--json", action="store_true", help="Output JSON")
    args = parser.parse_args()

    report = sync(args)
    if args.json:
        print(json.dumps(report, indent=2))
    else:
        print("AIX Sync Report")
        print(f"- Repo: {report['repo_root']}")
        print(f"- Framework: {report.get('framework_root')}")
        print(f"- Manifest: {report['manifest']}")
        print(f"- Output Dir: {report['output_dir']}")
        print(f"- Apply: {report['applied']}")
        print("Summary:")
        for key, value in sorted(report["summary"].items()):
            print(f"- {key}: {value}")


if __name__ == "__main__":
    main()
