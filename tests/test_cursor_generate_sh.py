"""Tests for adapters/cursor/generate.sh.

Covers end-to-end install (symlinks resolve, subagents emitted) and the
H-001 regression guard: failures inside aix-generate.py must propagate, not
be silently swallowed.
"""

from __future__ import annotations

import os
import subprocess
from pathlib import Path

import pytest

from conftest import REPO_ROOT


GENERATE_SH = REPO_ROOT / "adapters/cursor/generate.sh"


def _run_generate(repo: Path, *extra_args: str, env: dict | None = None) -> subprocess.CompletedProcess:
    return subprocess.run(
        ["bash", str(GENERATE_SH), "0", *extra_args],
        cwd=repo,
        capture_output=True,
        text=True,
        env=env,
    )


def test_generate_sh_creates_expected_structure(aix_source_repo: Path) -> None:
    result = _run_generate(aix_source_repo)
    assert result.returncode == 0, (
        f"generate.sh failed (exit {result.returncode}):\n"
        f"stdout:\n{result.stdout}\nstderr:\n{result.stderr}"
    )

    agents_md = aix_source_repo / "AGENTS.md"
    assert agents_md.is_symlink(), "AGENTS.md should be a symlink"
    assert agents_md.resolve().is_file(), (
        f"AGENTS.md target {agents_md.resolve()} should resolve to a real file"
    )

    skills = aix_source_repo / ".cursor/skills"
    assert skills.is_symlink(), ".cursor/skills should be a symlink"
    assert skills.resolve().is_dir(), ".cursor/skills target should resolve to a real dir"

    workflows = aix_source_repo / ".cursor/rules/workflows"
    assert workflows.is_symlink(), ".cursor/rules/workflows should be a symlink"
    assert workflows.resolve().is_dir(), (
        ".cursor/rules/workflows target should resolve to a real dir"
    )

    agents_dir = aix_source_repo / ".cursor/agents"
    assert agents_dir.is_dir(), ".cursor/agents/ should exist"
    role_files = list(agents_dir.glob("*.md"))
    assert role_files, (
        ".cursor/agents/ should contain at least one subagent .md file. "
        "Empty here means the generator silently failed (H-001 regression)."
    )


def test_generate_sh_propagates_python_failure(aix_source_repo: Path, tmp_path: Path) -> None:
    """Regression guard for H-001.

    If aix-generate.py exits non-zero, generate.sh must also exit non-zero —
    a silent install yields an empty .cursor/agents/ that looks fine but is broken.

    This test substitutes a stub aix-generate.py that always exits 1 and asserts
    generate.sh propagates the failure. If the `||` fallback ever sneaks back
    into generate.sh, this test fails loudly.
    """
    failing_stub = tmp_path / "fake-scripts"
    failing_stub.mkdir()
    stub_py = failing_stub / "aix-generate.py"
    stub_py.write_text(
        "#!/usr/bin/env python3\n"
        "import sys\n"
        "print('simulated generator failure', file=sys.stderr)\n"
        "sys.exit(1)\n"
    )
    stub_py.chmod(0o755)

    # Repoint .aix/scripts at the failing stub
    scripts_link = aix_source_repo / ".aix/scripts"
    scripts_link.unlink()
    scripts_link.symlink_to(failing_stub)

    result = _run_generate(aix_source_repo)
    assert result.returncode != 0, (
        "generate.sh should propagate aix-generate.py failures (exit non-zero). "
        "Got exit 0 — the `||` silencer pattern likely regressed. (H-001)\n"
        f"stdout:\n{result.stdout}\nstderr:\n{result.stderr}"
    )


def test_generate_sh_idempotent(aix_source_repo: Path) -> None:
    """Running generate.sh twice should succeed both times and leave equivalent output."""
    first = _run_generate(aix_source_repo)
    assert first.returncode == 0, f"first run failed:\n{first.stderr}"

    # Snapshot key file mtimes/contents before second run
    role_file = aix_source_repo / ".cursor/agents/coder.md"
    snapshot = role_file.read_text()

    second = _run_generate(aix_source_repo)
    assert second.returncode == 0, f"second run failed:\n{second.stderr}"

    # Hash-skip in aix-generate.py should leave unchanged file as-is
    assert role_file.read_text() == snapshot, "second run mutated unchanged role file"


def test_hooks_off_by_default(aix_source_repo: Path) -> None:
    """Without --enable-hooks, no .cursor/hooks.json should be emitted."""
    result = _run_generate(aix_source_repo)
    assert result.returncode == 0
    assert not (aix_source_repo / ".cursor/hooks.json").exists(), (
        "Hooks must be opt-in; .cursor/hooks.json should not appear without --enable-hooks"
    )


def test_hooks_emit_only_pre_compact(aix_source_repo: Path) -> None:
    """With --enable-hooks, hooks.json should contain preCompact only — sessionStart was
    removed (H-002 fix) pending matcher-value confirmation. Guards against the
    sessionStart hook re-appearing without the matcher work being done.
    """
    import json

    result = _run_generate(aix_source_repo, "--enable-hooks")
    assert result.returncode == 0, f"generate.sh --enable-hooks failed:\n{result.stderr}"

    hooks_file = aix_source_repo / ".cursor/hooks.json"
    assert hooks_file.is_file(), ".cursor/hooks.json should exist with --enable-hooks"

    config = json.loads(hooks_file.read_text())
    assert config.get("version") == 1
    assert "preCompact" in config["hooks"], "preCompact hook should be present"
    assert "sessionStart" not in config["hooks"], (
        "sessionStart hook was removed (H-002) — re-introducing it without confirming "
        "Cursor's matcher value for compact-restart events would fire post-compact.sh "
        "on every session start, not just compact-triggered ones."
    )
