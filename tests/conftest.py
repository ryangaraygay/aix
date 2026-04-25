"""Shared fixtures for aix tests.

Provides tmp git repos with .aix/ symlinking into the checkout's tier sources,
so generator runs can be exercised end-to-end without polluting the real repo.
"""

from __future__ import annotations

import subprocess
from pathlib import Path

import pytest
import yaml

REPO_ROOT = Path(__file__).resolve().parent.parent


def parse_frontmatter(path: Path) -> dict:
    """Parse YAML frontmatter from a markdown file with --- delimiters."""
    text = path.read_text()
    if not text.startswith("---\n"):
        raise ValueError(f"No frontmatter delimiter at start of {path}")
    parts = text.split("---\n", 2)
    if len(parts) < 3:
        raise ValueError(f"Could not split frontmatter in {path}")
    return yaml.safe_load(parts[1])


@pytest.fixture
def aix_source_repo(tmp_path: Path) -> Path:
    """Create a tmp git repo with .aix/ symlinking into this checkout's sources.

    Layout matches the bootstrapped pattern (flat, no tiers/ subdir). Skills come
    from tier-1 because tier-0 ships only an _index.md catalog with no real
    SKILL.md files.
    """
    aix = tmp_path / ".aix"
    aix.mkdir()

    (aix / "adapters").symlink_to(REPO_ROOT / "adapters")
    (aix / "scripts").symlink_to(REPO_ROOT / "scripts")
    (aix / "constitution.md").symlink_to(REPO_ROOT / "tiers/0-seed/constitution.md")
    (aix / "roles").symlink_to(REPO_ROOT / "tiers/0-seed/roles")
    (aix / "skills").symlink_to(REPO_ROOT / "tiers/1-sprout/skills")
    (aix / "workflows").symlink_to(REPO_ROOT / "tiers/0-seed/workflows")
    (aix / "hooks").symlink_to(REPO_ROOT / "tiers/0-seed/hooks")

    # generate.sh and aix-generate.py both call `git rev-parse --show-toplevel`
    # to find the repo root; without git init this lands somewhere unexpected.
    subprocess.run(["git", "init", "-q"], cwd=tmp_path, check=True)

    return tmp_path


@pytest.fixture
def cursor_generated(aix_source_repo: Path) -> Path:
    """Run `aix-generate.py --adapter cursor` against the source repo, return its path."""
    subprocess.run(
        [
            "python3",
            str(REPO_ROOT / "scripts/aix-generate.py"),
            "--adapter",
            "cursor",
            "--repo-root",
            str(aix_source_repo),
        ],
        check=True,
        capture_output=True,
    )
    return aix_source_repo
