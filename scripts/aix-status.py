#!/usr/bin/env python3
"""
Report AIX status for the current repo.

Deterministic and safe to run locally.
"""

import argparse
import json
import os
import subprocess
from pathlib import Path
from typing import Any, Dict, List


def _git_root() -> Path:
    result = subprocess.run(
        ["git", "rev-parse", "--show-toplevel"],
        capture_output=True,
        text=True,
    )
    if result.returncode == 0:
        return Path(result.stdout.strip())
    return Path.cwd()


def _read_tier_yaml(path: Path) -> Dict[str, Any]:
    data: Dict[str, Any] = {}
    adopted: List[str] = []
    if not path.exists():
        return data
    in_adopted = False
    for line in path.read_text().splitlines():
        if line.strip().startswith("#") or not line.strip():
            continue
        if line.startswith("adopted:"):
            in_adopted = True
            continue
        if in_adopted:
            if line.startswith("  - "):
                adopted.append(line.replace("  - ", "").strip())
                continue
            if not line.startswith(" "):
                in_adopted = False
        if ":" in line and not line.startswith(" "):
            key, value = line.split(":", 1)
            data[key.strip()] = value.strip()
    if adopted:
        data["adopted"] = adopted
    return data


def _framework_version(framework_root: Path) -> str:
    result = subprocess.run(
        ["git", "-C", str(framework_root), "rev-parse", "--short", "HEAD"],
        capture_output=True,
        text=True,
    )
    if result.returncode == 0:
        return result.stdout.strip()
    return "unknown"


def _count_files(path: Path) -> int:
    if not path.exists():
        return 0
    return sum(1 for _ in path.rglob("*") if _.is_file())


def _load_manifest(path: Path) -> Dict[str, Any]:
    if not path.exists():
        return {}
    return json.loads(path.read_text())


def _guardrail_status(repo_root: Path) -> List[str]:
    guardrails = [
        "docs/architecture/overview.md",
        "docs/architecture/constraints.md",
        "docs/architecture/ownership.md",
    ]
    missing = []
    for rel in guardrails:
        if not (repo_root / rel).exists():
            missing.append(rel)
    return missing


def status_report(args: argparse.Namespace) -> Dict[str, Any]:
    repo_root = Path(args.repo_root) if args.repo_root else _git_root()
    aix_dir = repo_root / ".aix"
    tier_path = aix_dir / "tier.yaml"
    manifest_path = aix_dir / "manifest.json"
    snapshots_path = aix_dir / "snapshots"

    if args.framework_root:
        framework_root = Path(args.framework_root)
    else:
        env_path = os.environ.get("AIX_FRAMEWORK")
        framework_root = Path(env_path) if env_path else Path.home() / "tools" / "aix"

    registry_path = framework_root / "registry.tsv"

    tier = _read_tier_yaml(tier_path)
    manifest = _load_manifest(manifest_path)

    report = {
        "repo_root": str(repo_root),
        "tier": tier.get("tier"),
        "tier_name": tier.get("name"),
        "aix_version": tier.get("aix_version") or manifest.get("aix_version"),
        "framework_root": str(framework_root) if framework_root.exists() else None,
        "framework_version": _framework_version(framework_root) if framework_root.exists() else None,
        "registry_path": str(registry_path) if registry_path.exists() else None,
        "manifest_path": str(manifest_path) if manifest_path.exists() else None,
        "manifest_files": len(manifest.get("files", [])) if manifest else 0,
        "snapshot_files": _count_files(snapshots_path),
        "guardrails_missing": _guardrail_status(repo_root),
        "adopted": tier.get("adopted", []),
    }

    capabilities = sorted(
        {
            entry.get("capability")
            for entry in manifest.get("files", [])
            if entry.get("capability")
        }
    )
    report["capabilities"] = capabilities

    suggestions = []
    if report["guardrails_missing"]:
        suggestions.append("Adopt architecture guardrails (Tier 1) or add docs/architecture/*.")
    if report["framework_version"] and report["aix_version"]:
        if report["framework_version"] != report["aix_version"]:
            suggestions.append("Run aix-sync to merge upstream updates.")
    if not manifest_path.exists():
        suggestions.append("Manifest missing. Run bootstrap/upgrade or re-init manifest.")
    report["suggestions"] = suggestions

    return report


def print_text(report: Dict[str, Any]) -> None:
    print("AIX Status")
    print(f"- Repo: {report['repo_root']}")
    print(f"- Tier: {report.get('tier')} ({report.get('tier_name')})")
    print(f"- AIX Version: {report.get('aix_version')}")
    print(f"- Framework Version: {report.get('framework_version')}")
    print(f"- Registry: {report.get('registry_path') or 'missing'}")
    print(f"- Manifest: {report.get('manifest_path') or 'missing'}")
    print(f"- Manifest Files: {report.get('manifest_files')}")
    print(f"- Snapshot Files: {report.get('snapshot_files')}")
    missing = report.get("guardrails_missing") or []
    print(f"- Guardrails Missing: {', '.join(missing) if missing else 'none'}")
    adopted = report.get("adopted") or []
    print(f"- Adopted: {', '.join(adopted) if adopted else 'none'}")
    caps = report.get("capabilities") or []
    print(f"- Capabilities: {', '.join(caps) if caps else 'none'}")
    if report.get("suggestions"):
        print("Suggestions:")
        for suggestion in report["suggestions"]:
            print(f"- {suggestion}")


def main() -> None:
    parser = argparse.ArgumentParser(description="Report AIX status")
    parser.add_argument("--repo-root", help="Path to repo root")
    parser.add_argument("--framework-root", help="Path to AIX framework repo")
    parser.add_argument("--json", action="store_true", help="Output JSON")
    args = parser.parse_args()

    report = status_report(args)
    if args.json:
        print(json.dumps(report, indent=2))
    else:
        print_text(report)


if __name__ == "__main__":
    main()
