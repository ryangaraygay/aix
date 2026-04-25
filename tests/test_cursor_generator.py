"""Tests for the cursor branch in scripts/aix-generate.py.

Covers the subagent frontmatter shape: required keys, omitted keys (Cursor
doesn't accept `tools` or `reasoningEffort`), and the readonly heuristic
(empirically verified against Cursor 2.5: only Write/Edit/MultiEdit/NotebookEdit
gate readonly, not Bash).
"""

from __future__ import annotations

from pathlib import Path

from conftest import parse_frontmatter


REQUIRED_KEYS = {"name", "description", "model", "readonly", "is_background"}
DISALLOWED_KEYS = {"tools", "reasoningEffort"}


def test_subagent_files_emitted_for_tier0_roles(cursor_generated: Path) -> None:
    agents = cursor_generated / ".cursor/agents"
    assert agents.is_dir(), ".cursor/agents/ should exist after generation"
    expected = {"analyst.md", "coder.md", "reviewer.md"}
    actual = {p.name for p in agents.glob("*.md")}
    assert expected.issubset(actual), f"missing roles: {expected - actual}"


def test_frontmatter_has_required_keys_and_omits_disallowed(cursor_generated: Path) -> None:
    for role in ("analyst", "coder", "reviewer"):
        fm = parse_frontmatter(cursor_generated / f".cursor/agents/{role}.md")
        missing = REQUIRED_KEYS - fm.keys()
        present_disallowed = DISALLOWED_KEYS & fm.keys()
        assert not missing, f"{role}: missing required frontmatter keys: {missing}"
        assert not present_disallowed, (
            f"{role}: emitted Cursor-unsupported keys: {present_disallowed}. "
            "Cursor subagents have no per-agent tools allowlist; reasoning level "
            "is encoded in the model name suffix instead of a separate field."
        )


def test_role_with_write_tool_emits_readonly_false(cursor_generated: Path) -> None:
    # coder source frontmatter has tools including Write
    fm = parse_frontmatter(cursor_generated / ".cursor/agents/coder.md")
    assert fm["readonly"] is False, (
        "coder has Write in its tool list and must emit readonly: false; "
        "if True, the readonly heuristic regressed."
    )


def test_role_without_write_or_edit_emits_readonly_true(cursor_generated: Path) -> None:
    # reviewer source frontmatter is [Read, Bash, Grep, Glob] — no Write/Edit
    fm = parse_frontmatter(cursor_generated / ".cursor/agents/reviewer.md")
    assert fm["readonly"] is True, (
        "reviewer has no Write/Edit/MultiEdit/NotebookEdit and must emit readonly: true. "
        "If False, the heuristic likely re-added Bash to the write_tools set "
        "(empirically verified that Cursor 2.5's readonly does not gate Bash)."
    )


def test_is_background_default_false(cursor_generated: Path) -> None:
    for role in ("analyst", "coder", "reviewer"):
        fm = parse_frontmatter(cursor_generated / f".cursor/agents/{role}.md")
        assert fm["is_background"] is False, (
            f"{role}: is_background should default to False (sync dispatch)"
        )


def test_model_field_populated_from_default_model_set(cursor_generated: Path) -> None:
    """Default model set assigns auto/composer to roles; verify it lands in frontmatter."""
    expected = {
        "analyst": "composer-2",
        "coder": "composer-2-fast",
        "reviewer": "composer-2",
    }
    for role, model in expected.items():
        fm = parse_frontmatter(cursor_generated / f".cursor/agents/{role}.md")
        assert fm["model"] == model, (
            f"{role}: model should be {model!r} per default.yaml, got {fm['model']!r}"
        )
