---
name: Adapter capability matrix
description: What each aix adapter supports, side-by-side. Source of truth for "does X support Y?" questions.
---

# Adapter capability matrix

What each aix adapter supports, side-by-side. Use this when picking an adapter for a project, or when authoring a new adapter to see what conventions exist.

| Capability | claude-code | cursor | factory | kiro-cli | opencode | agentskills |
|---|---|---|---|---|---|---|
| **Entrypoint file** (constitution symlink target) | `CLAUDE.md` | `AGENTS.md` | `GEMINI.md` | `AGENTS.md` | `AGENTS.md` | — |
| **Sub-agent dir** (first-class personas) | `.claude/agents/` | `.cursor/agents/` | `.factory/droids/` | `.kiro/agents/` | `.opencode/agent/` | — |
| **Role file format** | markdown | markdown | markdown | json | markdown | — |
| **Per-role model** | ✓ | ⚠ honored only when parent agent is non-Auto (Cursor 2.5 bug) | ✓ | ✓ | ✓ | n/a |
| **Per-role tool allowlist** | ✓ array | ✗ `readonly` boolean only | ✓ array | ✓ `allowedTools` array | ✓ boolean object | n/a |
| **Skills dir** | `.claude/skills/` | `.cursor/skills/` (+ `.claude/`, `.codex/` compat) | `.factory/skills/` | `.kiro/skills/` | `.opencode/skills/` | `.agent/skills/` |
| **Skills strategy** | symlink | symlink | symlink | symlink | symlink | symlink |
| **Hooks generation** | ✓ stable (`.claude/settings.json`) | ✓ opt-in, beta (`.cursor/hooks.json`) | ✗ | ✗ | ✗ | ✗ |
| **MCP pass-through** | (manual) | ✓ planned (`.cursor/mcp.json`) | (manual) | (manual) | (manual) | n/a |
| **Workflow surface** | files / slash commands | `@<rule-name>` Manual rules | files | files | files | n/a |
| **Async / background agents** | ✗ | ✓ `is_background` field (Cursor 2.5) | ✗ | ✗ | ✗ | n/a |
| **CLI / IDE parity** | CLI + IDE | CLI + IDE (one known plugin-skill gap) | CLI | CLI | CLI | n/a |

## Notes per adapter

### claude-code
- Most mature adapter; reference for how aix concepts map.
- Hooks block in `.claude/settings.json` is stable.
- Sub-agent frontmatter: `name`, `description`, `model`, `tools`.

### cursor
- Sub-agents shipped Cursor 2.4 (Jan 2026); plugins/marketplace + async agents in 2.5 (Feb 2026).
- Sub-agent frontmatter: `name`, `description`, `model`, `readonly`, `is_background`. **No `tools` array** — only `readonly` boolean restricts capability.
- Reads `.claude/skills/` and `.codex/skills/` as compat shims (with reliability bugs as of Feb 2026).
- See `docs/cursor-adapter-plan.md` for full design notes.

### factory
- Entrypoint is `GEMINI.md` (factory's convention).
- Sub-agent dir is `.factory/droids/` (terminology choice).

### kiro-cli
- Role files are JSON, not markdown — only adapter that diverges here.
- `allowedTools` field carries per-agent tool restriction.

### opencode
- Tool list is a boolean object (`{read: true, write: true}`) instead of an array.
- Default model set targets `codex-5.3`.

### agentskills
- Skills-only adapter — no roles, no model sets, no entrypoint. For projects that only want to share skills across tools.

## Cursor-specific quirks (only adapter affected)

These are the differences a user picking Cursor will feel that no other adapter exhibits:

1. **No per-role tool allowlist** — only `readonly` boolean. Can't say "this role gets Read+Grep only."
2. **Hooks are beta** — pinned to `version: 1`, may change.
3. **Subagent `model:` ignored on Auto parent** — Cursor 2.5 bug. When parent agent is on `auto` (or user lacks access to the requested model, or subagent is level-2 nested), Cursor silently falls back to Composer regardless of frontmatter. Affects which Cursor model set is reliable: `default` (auto + composer) is robust everywhere; `pro` / `top-tier` only honor their pins when parent is pinned non-Auto.
4. **`@<name>` for invoking workflows** — file refs (`@filename`) work the same as everywhere; rule activation via `@<rule-name>` is Cursor-specific syntax.
5. **`.cursor/rules/<name>/RULE.md` folder format is buggy** as of early 2026 — emit flat `.mdc` instead.
6. **Plugin-bundled skills don't load in headless CLI** — only loose `.cursor/skills/<name>/SKILL.md` works in both surfaces.

## Cross-cutting observations

- **Per-role tool restriction**: Cursor is the only adapter without it. Everyone else (Claude, Kiro, OpenCode, Factory) supports per-agent tool allowlists in some form.
- **Hooks**: only Claude is stable today. Cursor is beta. Kiro/OpenCode/Factory don't generate hook config at all.
- **Sub-agents**: universal — every adapter except agentskills supports first-class personas.
- **Skills via SKILL.md (open spec)**: Claude, Cursor, Codex (compat). Other adapters use their own skill paths but the same symlink strategy.

## Update policy

This matrix is the source of truth. When adding a new adapter or shipping a capability change:

1. Update the matrix row.
2. Update `docs/ROADMAP.md` if the adapter table there is out of sync.
3. If a Cursor-specific quirk changes (e.g., `tools` array support added), update `adapters/cursor/README.md` and the cursor row here.
