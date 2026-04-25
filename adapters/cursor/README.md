# Cursor adapter

Generates Cursor IDE / `cursor-agent` CLI configuration from aix capabilities.

## What it emits

| Output | Source |
|---|---|
| `AGENTS.md` (symlink) | `.aix/constitution.md` |
| `.cursor/agents/<role>.md` | `.aix/roles/<role>.md` (via `scripts/aix-generate.py`) |
| `.cursor/rules/workflows/` (symlink) | `.aix/workflows/` |
| `.cursor/skills/` (symlink) | `.aix/skills/` |
| `.cursor/hooks.json` (opt-in) | `.aix/hooks/` |
| `.cursor/mcp.json` (pass-through) | `.aix/mcp.json` if present |

## Usage

```bash
./adapters/cursor/generate.sh         # default (no hooks)
./adapters/cursor/generate.sh 0 --enable-hooks
```

## Cursor-specific limitations

These are the differences a user picking Cursor will feel that other aix adapters do not exhibit. See `docs/adapter-capabilities.md` for the full cross-adapter matrix.

### 1. No per-subagent tool allowlist

Cursor subagents have only a `readonly` boolean — there is no per-agent tool allowlist field analogous to Claude's `tools: [Read, Grep]`. If a role needs tighter restriction than "full read/write" or "readonly", Cursor cannot enforce it.

The `tools:` mapping in `adapter.yaml` is therefore informational only. (Body-text substitution of canonical → native tool names is not performed for markdown adapters today; the canonical names like `Read` and `Bash` survive in the rendered subagent body.)

### 2. Hooks are beta

`.cursor/hooks.json` is generated only when `--enable-hooks` is passed. Schema is pinned to `version: 1` (Cursor 1.7+). Cursor flags hooks as beta and the schema may change.

### 3. Subagent `model:` is silently ignored when parent agent is Auto

Cursor 2.5 has a documented bug: when the parent agent runs on `auto`, subagent `model:` frontmatter is ignored and execution falls back to Composer. The same fallback happens:

- When the user lacks access to the requested model (free-tier accounts with premium model IDs)
- For level-2 nested subagents — they always fall back to `composer-1.5` regardless of plan

This affects which model set you should pick:

- **`default.yaml`** — `auto` + Composer mix. Predictable on free, paid, and Auto-mode. Recommended unless you have a specific reason otherwise.
- **`pro.yaml`** and **`top-tier.yaml`** — pin premium models (Opus/GPT-5.x). The frontmatter is only honored when you run the parent agent on a pinned non-Auto model (e.g., `cursor-agent --model claude-opus-4-7-medium`). Otherwise Cursor silently downgrades to Composer.

Forum references: [151134](https://forum.cursor.com/t/cursor-rules-and-sub-agent-calls-do-not-work-when-agent-model-is-set-to-auto-or-composer-1/151134), [152440](https://forum.cursor.com/t/sub-agent-ignoring-model-configuration-in-version-2-5/152440), [150846](https://forum.cursor.com/t/my-subagents-cant-be-used-in-auto-model/150846).

### 4. Workflow invocation uses `@<name>` (file-ref, not formal Manual rule)

Workflows live under `.cursor/rules/workflows/` (symlinked to `.aix/workflows/`). Empirically (April 2026), `@<workflow-name>` works — Cursor reads the file and uses its content. **However**, the symlinked workflow files do *not* register as formal Cursor "Manual rules" because they lack the `.mdc` frontmatter Cursor expects (`description`, `globs`, `alwaysApply`). They behave as plain file references reached via `@`-mention, not as rule activations that show up in Cursor's rules UI.

**What we lose**: Workflows don't appear in the Cursor rules UI alongside other project rules; agents won't surface them as discoverable "available rules" in some surfaces; rule-specific telemetry (if any) won't fire.

**Possible future improvement**: generate `.mdc` wrappers in `.cursor/rules/workflows/` that have proper Cursor frontmatter and reference the canonical body in `.aix/workflows/`. Trade-offs:

- ✓ Workflows would register as formal Manual rules.
- ✗ Breaks the single-source-of-truth-via-symlink model — wrappers need regeneration on every workflow change.
- ✗ Cursor `.mdc` rules don't (currently) support an `@include` directive, so the wrapper would need to inline the body, creating drift risk.
- ✗ Adds another generated artifact to keep in sync.

For now we accept the file-ref behavior; revisit if Cursor adds an `@include` directive or if users report missing rule-discoverability is causing problems.

File references (`@filename`) work the same as in Claude Code, OpenCode, Kiro — only the rule-activation surface is Cursor-specific.

### 5. Folder-format rules are buggy as of early 2026

Cursor docs describe a `.cursor/rules/<name>/RULE.md` folder format. Multiple bug reports in late 2025 / early 2026 say it fails to register. We emit flat `<name>.mdc` instead. Revisit when the folder bug is fixed upstream.

### 6. Plugin-bundled skills don't load in headless CLI

A Cursor 2.5 quirk — skills inside a Plugin load in IDE but not in `cursor-agent` headless mode. We don't emit Plugins, so this doesn't affect aix users directly. Mentioned for users assembling their own plugin bundles.

## Model sets

Three model sets ship with the adapter:

| Set | When to use | Model strategy |
|---|---|---|
| `default` | Default. Works on Free (Hobby) and on Auto-mode paid accounts. | `auto` for orchestration; `composer-2` / `composer-2-fast` for execution roles. |
| `pro` | Paid account; you run the parent agent pinned to a non-Auto model. | Solid premium mix: Sonnet 4.6 + Opus 4.7 medium + GPT-5.4. |
| `top-tier` | Quality matters more than cost. Same parent-agent-pinned requirement. | Opus 4.7 thinking variants + Codex high. |

Pick a set with `aix-generate.py --adapter cursor --model-set <name>`.

### Empirically verified (April 2026, Hobby/Auto)

Subagent dispatch verified end-to-end on Cursor Free (Hobby) tier with parent on Auto: `analyst`, `coder`, and `reviewer` subagents were enumerated, dispatched, and each returned an answer in ~1.5s. As predicted by quirk #3 above, all three were coerced to `composer-2-fast` regardless of the per-role `model:` frontmatter — confirming `default.yaml`'s composer-first design is correct for Hobby/Auto users.

## Verifying the install

After running `generate.sh`:

```bash
ls -la AGENTS.md .cursor/skills .cursor/rules/workflows  # symlinks resolve
ls .cursor/agents/                                       # subagent files emitted
yamllint adapter.yaml                                    # if you edit the config
```

For live verification with `cursor-agent`:

```bash
agent -p "List the named subagents available in this project with their descriptions." --output-format json
```

## Sources

- Cursor subagents: https://cursor.com/docs/subagents
- Cursor 2.4 changelog: https://cursor.com/changelog/2-4
- Cursor 2.5 changelog: https://cursor.com/changelog/2-5
- Rules: https://cursor.com/docs/rules
- Hooks: https://cursor.com/docs/hooks
- MCP: https://cursor.com/docs/context/mcp
- Skills: https://cursor.com/docs/context/skills
