---
name: Cursor adapter plan
description: Working note for the feat/cursor-adapter branch. Delete once the adapter ships.
---

# Cursor adapter — implementation plan

Working note for the `feat/cursor-adapter` branch. Delete once the adapter ships.

## 1. Cursor capability snapshot (verified April 2026)

The previous version of this plan was **significantly out of date**. Verified against current Cursor docs and changelogs:

**Sub-agents — first-class as of Cursor 2.4 (Jan 22, 2026)**
- Project: `.cursor/agents/<name>.md`. User-global: `~/.cursor/agents/`.
- YAML frontmatter: `name`, `description`, `model`, `readonly`, `is_background`. Body = persona instructions.
- Cursor 2.5 (Feb 17, 2026) added a Plugins/Marketplace bundling agents+skills+hooks+rules+MCP, plus async/nested agent spawning.
- Sources: [cursor.com/docs/subagents](https://cursor.com/docs/subagents), [cursor.com/changelog/2-4](https://cursor.com/changelog/2-4), [cursor.com/changelog/2-5](https://cursor.com/changelog/2-5).
- **Implication**: roles map cleanly to subagents *with per-role model selection*. The earlier "no per-role model" gap is resolved.

**Rules (`.cursor/rules/*.mdc`)**
- YAML frontmatter: `description`, `globs`, `alwaysApply`. Activation: Always (`alwaysApply: true`), Auto-Attached (globs match), Agent-Requested (description-driven), Manual.
- Both flat `<name>.mdc` and folder-per-rule `<name>/RULE.md` are documented.
- **Pragmatic call: emit flat `.mdc`.** Multiple Dec 2025 / early-2026 forum reports say the folder format fails to register ([report 1](https://forum.cursor.com/t/project-rules-documented-rule-md-folder-format-not-working-only-undocumented-mdc-format-works/145907), [report 2](https://forum.cursor.com/t/new-cursor-rules-directory-format-not-working/147086)). Revisit when fixed.
- Legacy `.cursorrules` (single root file) is deprecated but still read.

**AGENTS.md / CLAUDE.md**
- Both IDE and CLI natively read `AGENTS.md` and `CLAUDE.md` at repo root as project guidance ([cursor.com/docs/rules](https://cursor.com/docs/rules), [cursor.com/docs/cli/using](https://cursor.com/docs/cli/using)).

**CLI (`cursor-agent` / `cursor agent`)**
- Print mode: `cursor-agent -p "..." --output-format json|stream-json|text`. Reads the same rules/agents/skills/hooks/MCP/AGENTS.md as the IDE.
- Cursor 2.4 explicitly gave the CLI "full parity with editor hooks." **CLI-first design needs no rework for IDE later.**
- Known gap: skills bundled inside Plugins load in IDE but not headless CLI (Feb 2026 forum bug). Loose `.cursor/skills/<name>/SKILL.md` works in both — that's our target.

**Hooks (beta, v1.7+)**
- `.cursor/hooks.json` (project) and `~/.cursor/hooks.json` (user). Events: `sessionStart`, `sessionEnd`, `preToolUse`, `postToolUse`, `beforeShellExecution`, `afterShellExecution`, `beforeMCPExecution`, `afterMCPExecution`, `beforeReadFile`, `afterFileEdit`, `beforeSubmitPrompt`, `preCompact`, `afterAgentResponse`, `stop`, plus Tab hooks. Schema: `{version: 1, hooks: { event: [{command, type, timeout, failClosed, matcher}] }}`. Exit 2 = block.
- Beta — pin `version: 1`.

**MCP**
- `.cursor/mcp.json` (project) / `~/.cursor/mcp.json` (global), root key `mcpServers`. ~40 active-tool ceiling.

**Skills — `.cursor/skills/` is native; `.claude/skills/` is a compat shim**
- Cursor reads from `.cursor/skills/`, `.agents/skills/`, plus user-global variants natively. For compatibility it also loads from `.claude/skills/`, `.codex/skills/` ([cursor.com/docs/context/skills](https://cursor.com/docs/context/skills)).
- Compat path has known reliability bugs ([forum, Feb 2026](https://forum.cursor.com/t/cursor-agent-cli-does-not-register-skills-from-plugins-ide-does-parity-gap/158947)).
- **Target**: symlink `.cursor/skills/` → `../.aix/skills/`. Optionally also `.claude/skills/` for users who run Claude Code on the same repo.

## 2. aix → Cursor mapping (final)

| aix concept | Cursor target | Notes |
|---|---|---|
| `constitution.md` | `AGENTS.md` symlink → `.aix/constitution.md` | Per Cursor docs, `AGENTS.md` is read by both IDE and CLI as primary guidance. No `.cursor/rules/` mirror needed. If we observe under-weighting in some mode later, revisit. |
| Roles (`analyst`, `coder`, `reviewer`, ...) | `.cursor/agents/<role>.md` (subagents, with per-role `model`) | Frontmatter: `name`, `description`, `model`, `readonly`, `is_background`. Body = role markdown. |
| Workflows | `.cursor/rules/workflows/` symlink → `.aix/workflows/` | Cursor sees them as Manual rules, invokable via `@<name>`. Single source of truth stays in `.aix/`. |
| Skills | `.cursor/skills/` symlink → `.aix/skills/`. Optional secondary `.claude/skills/` symlink for cross-tool. | Native path. |
| Model sets | Honored per-role via subagent `model` frontmatter. | Same expressiveness as Claude Code / Kiro. |
| Hooks | `.cursor/hooks.json` generated from `.aix/hooks/` | **Opt-in** flag (default off) since Cursor hooks are still beta. |
| MCP | `.cursor/mcp.json` (pass-through if `.aix/mcp.json` exists) | Optional. |
| Tools | Body-text substitution only (`replace_tool_names_in_body`) | Subagent frontmatter has no per-agent tool allowlist field — only `readonly` boolean. Document this. |

## 3. Resolved decisions (was §5 "open questions")

1. **IDE + CLI** — both. CLI-first; verified that this does not lock us out of IDE.
2. **Default role activation** — moot. Roles are now subagents (dispatched), not always-applied rules.
3. **Rules folder format** — flat `.mdc`. Revisit when folder-format bugs are fixed.
4. **Skills location** — `.cursor/skills/` primary, `.claude/skills/` optional secondary symlink (off by default; user-flag).
5. **Model sets** — fully supported via subagent `model` field.
6. **Hooks** — opt-in flag (`--enable-hooks` or similar). Default off.
7. **AGENTS.md collision** — non-issue. Both kiro and cursor symlink to the same target (`.aix/constitution.md`); shared symlinks are fine.

## 4. Remaining gaps to document in adapter README

Six Cursor-only quirks. Items (1), (2), and (6) are the ones users will actually feel.

1. **No per-subagent tool allowlist.** Cursor subagents have only a `readonly` boolean. Claude/Kiro/OpenCode/Factory all support per-agent tool restriction (`tools: [Read, Grep]` or equivalent). Cursor: full read/write OR readonly. That's it.
2. **Hooks are beta.** Pinned to `version: 1`; schema may shift. Among aix adapters only Claude wires hooks today, so this is "Cursor's are beta" rather than "Cursor lacks them."
3. **`is_background` field on subagents** — Cursor 2.5 async/nested-agent feature. Not a limitation, just a Cursor-specific frontmatter field.
4. **Folder-format rule bug** — `.cursor/rules/<name>/RULE.md` is documented but reportedly broken in early 2026. We dodge by emitting flat `.mdc`. Implementation pothole, not a design limit.
5. **Plugin-bundled skills don't load in headless CLI** — Cursor 2.5 IDE-only design quirk. We don't emit Plugins, so this only matters for users assembling their own.
6. **Subagent `model:` is silently ignored when parent is Auto.** Cursor 2.5 bug: when the parent agent runs on `auto`, subagent model frontmatter is ignored and Cursor falls back to Composer. Same fallback happens when the user lacks access to the requested model (free tier with premium IDs) and unconditionally for level-2 nested subagents (forum threads: [151134](https://forum.cursor.com/t/cursor-rules-and-sub-agent-calls-do-not-work-when-agent-model-is-set-to-auto-or-composer-1/151134), [152440](https://forum.cursor.com/t/sub-agent-ignoring-model-configuration-in-version-2-5/152440), [150846](https://forum.cursor.com/t/my-subagents-cant-be-used-in-auto-model/150846)). **Implication for model sets**: `default.yaml` is auto+composer (predictable everywhere); `pro.yaml` and `top-tier.yaml` only honor their pinned premium models when the parent agent is set to a non-Auto model.

## 5. Concrete file plan

### New files

**`adapters/cursor/adapter.yaml`**
```yaml
adapter: cursor
version: 1

output:
  agents: .cursor/agents      # subagent .md files (Cursor 2.4+)
  skills: .cursor/skills      # symlink target
  rules: .cursor/rules        # workflow symlink lives here

skills:
  strategy: symlink
  also_symlink_claude: false  # opt-in for cross-tool users

model_sets:
  enabled: true
  default: default

roles:
  format: markdown            # same as claude/opencode; cursor frontmatter shape is handled by an `adapter_name == "cursor"` branch in the generator
  filename: "{name}.md"

hooks:
  enabled: false              # opt-in; Cursor hooks still beta
  config_path: .cursor/hooks.json

mcp:
  enabled: true
  config_path: .cursor/mcp.json

# Cursor-native tool names (used for body-text substitution only;
# subagent frontmatter has no tool allowlist field)
tools:
  Read: read_file
  Write: edit_file
  Edit: edit_file
  Bash: run_terminal_cmd
  Grep: grep
  Glob: file_search
```

**`adapters/cursor/generate.sh`**
- Mirror `adapters/claude-code/generate.sh` structure (detect bootstrapped vs submodule layout).
- Symlink `AGENTS.md` → `.aix/constitution.md` (idempotent; if exists and points elsewhere, warn).
- Create `.cursor/{agents,rules,skills}` dirs.
- Symlink `.cursor/skills` → `../.aix/skills`.
- Symlink `.cursor/rules/workflows` → `../../.aix/workflows`.
- Run `aix-generate.py --adapter cursor` to emit `.cursor/agents/*.md`.
- If `--enable-hooks` and `.aix/hooks/` exists, write `.cursor/hooks.json`.
- If `.aix/mcp.json` exists, copy/symlink to `.cursor/mcp.json`.

**No `templates/` directory.** Initial design assumed templated emission but the implementation hardcodes both the subagent frontmatter shape (in `scripts/aix-generate.py` cursor branch) and the hook config (heredoc in `generate.sh`). Templates added then removed pre-merge — see commit history.

**`adapters/cursor/model-sets/{default,budget,mid,pro}.yaml`**
- Same shape as claude-code's model-sets. Per-role `model:` consumed by the new cursor branch in the generator and emitted into subagent frontmatter.

**`adapters/cursor/README.md`**
- Document the gaps from §4 explicitly (no per-agent tool allowlist; hooks beta; skills-in-plugins CLI gap).

### Changes to `scripts/aix-generate.py`

Cursor uses `format: markdown` (same as claude-code, factory, opencode). The Cursor-specific frontmatter shape is added by branching on `adapter_name == "cursor"` inside the existing markdown path — same pattern opencode uses today (see `aix-generate.py:239,247`).

- Add an `adapter_name == "cursor"` branch in `generate_output_file()` that emits:
  ```yaml
  ---
  name: <role>
  description: <from role frontmatter>
  model: <from model-set>
  readonly: <true if role has no Write/Edit/Bash in tools, else false>
  is_background: false
  ---
  <body, with replace_tool_names_in_body applied>
  ```
- Skip the `tools:` array (Cursor subagents have no per-agent allowlist field — only the `readonly` boolean).
- Still run `replace_tool_names_in_body` so prose mentions Cursor-native tool names.

### Changes to `add-adapter.sh`

Add to the `case "$ADAPTER_INPUT"` switch:
```sh
cursor)
    ADAPTER_KEY="cursor"
    ADAPTER_DIR="cursor"
    ENTRYPOINT="AGENTS.md"
    ;;
```
Update `usage()` to list `cursor`. The shared `AGENTS.md` symlink is fine when both `kiro` and `cursor` are enabled (same target).

### Changes to `bootstrap.sh`

- Add `Cursor` to the `select_adapter` menu.
- Add `cursor) ADAPTER_DIR="cursor" ;;` in the adapter-dir case.
- Add `cursor)` arm to the entry-point case (symlink AGENTS.md, then call `adapters/cursor/generate.sh 0`).
- Add the trailing structure-summary block for cursor (`.cursor/agents/`, `.cursor/rules/`, `.cursor/skills/`).

### Changes to docs

- **`docs/ROADMAP.md` / `README.md`**: add row to the adapter table — `cursor | .cursor/agents/*.md | AGENTS.md | hooks (opt-in, beta) | per-role model: yes`.
- Note Cursor-specific limitations from §4.

## 6. Progressive implementation & verification plan

Build in stages. Each stage ends with **one** live `cursor-agent -p` call that confirms Cursor recognizes the new artifact. Cost stance: be reasonable, but prioritize quality and time over cost — we're not running hundreds of calls.

### Test directory

`/tmp/aix-cursor-test/` (clean scratch). Avoids polluting the aix repo working tree with generated `.cursor/` artifacts. Workflow: run `adapters/cursor/generate.sh` against the scratch dir, pointing it at this aix repo as the source.

### Stages

| # | Build | Static verify (no live call) | Live verify (1 `cursor-agent -p` call) |
|---|---|---|---|
| **0** | `adapters/cursor/{adapter.yaml, generate.sh, model-sets/, README.md}` skeleton | `yamllint adapter.yaml`; `bash -n generate.sh` | — |
| **1** | Add `adapter_name == "cursor"` branch to `scripts/aix-generate.py` (Cursor-shaped frontmatter on top of `format: markdown`) | Run `aix-generate.py --adapter cursor --dry-run` → inspect emitted `.cursor/agents/*.md` frontmatter & body | — |
| **2** | `generate.sh` creates `AGENTS.md` symlink → `.aix/constitution.md` | `ls -la AGENTS.md`; target resolves | `agent -p "Quote the first line of your project guidance/constitution." --output-format text` → must reference constitution content |
| **3** | Subagents emitted to `.cursor/agents/*.md` | `for f in .cursor/agents/*.md; do head -10 "$f"; done` — all frontmatter parses | `agent -p "List the named subagents available in this project with their descriptions." --output-format json` → enumerates our roles |
| **4** | Workflows symlink: `.cursor/rules/workflows` → `../../.aix/workflows` | `ls -la .cursor/rules/workflows/` resolves; one workflow visible | `agent -p "Read the @standard workflow and summarize its first step in one sentence." --output-format text` |
| **5** | Skills symlink: `.cursor/skills` → `../.aix/skills` | `ls -la .cursor/skills/` resolves | `agent -p "What skills do you have access to in this project?" --output-format text` → lists skills |
| **6** | Opt-in hooks: `.cursor/hooks.json` with no-op `sessionStart` that touches a marker | `jq . .cursor/hooks.json` parses | Any one-shot `agent -p "hello"` → `test -f /tmp/cursor-hook-marker` |
| **7** | MCP pass-through (skip if no `.aix/mcp.json`) | `jq . .cursor/mcp.json` parses | — (skip live; covered by IDE later) |
| **8** | End-to-end smoke | — | See "Smoke test spec" below |

### Cross-cutting checks (run at every stage)

- **Idempotency**: `generate.sh` run twice produces identical output / no errors.
- **Symlink hygiene**: every emitted symlink resolves with `readlink -f`.

### Smoke test spec (stage 8)

> **Spec**: Create `hello.py` with `def greet(name: str) -> str` returning `f"Hello, {name}!"`, plus `test_hello.py` asserting `greet("aix") == "Hello, aix!"`.
> **Workflow**: `@standard`.
> **Delegation**: analyst (confirm spec) → coder (implement) → reviewer (final pass).
> **End state**: both files exist; `python -m pytest test_hello.py` passes; agent's response names each subagent it dispatched to.

**Pass criteria (we verify, not the agent):**
- `hello.py` exists, contains `def greet`
- `test_hello.py` exists
- `python -m pytest test_hello.py` exits 0
- Agent's stdout mentions all three subagents (analyst, coder, reviewer)

### Cost-control rules

- Each stage gate is **one** call. If it fails, diagnose from output before retrying.
- Use `--output-format json` when grepping structured fields; `text` otherwise.
- No exploratory "let me just check" calls — file inspection first.
- If we run out of Auto credits mid-stage, pause and surface to user (they'll upgrade rather than truncate the work).

## 7. Critical files to read when resuming

- `docs/cursor-adapter-plan.md` (this file)
- `scripts/aix-generate.py`
- `adapters/claude-code/{adapter.yaml,generate.sh}`
- `adapters/kiro-cli/{adapter.yaml,generate.sh}`
- `add-adapter.sh`
- `bootstrap.sh`

## 8. Sources

- Cursor subagents: [cursor.com/docs/subagents](https://cursor.com/docs/subagents)
- Cursor 2.4 changelog (subagents, CLI hook parity): [cursor.com/changelog/2-4](https://cursor.com/changelog/2-4)
- Cursor 2.5 changelog (Plugins, async agents): [cursor.com/changelog/2-5](https://cursor.com/changelog/2-5)
- Rules: [cursor.com/docs/rules](https://cursor.com/docs/rules), [cursor.com/docs/context/rules](https://cursor.com/docs/context/rules)
- CLI / headless: [cursor.com/docs/cli/using](https://cursor.com/docs/cli/using), [cursor.com/docs/cli/headless](https://cursor.com/docs/cli/headless)
- Skills: [cursor.com/docs/context/skills](https://cursor.com/docs/context/skills)
- Hooks: [cursor.com/docs/hooks](https://cursor.com/docs/hooks)
- MCP: [cursor.com/docs/context/mcp](https://cursor.com/docs/context/mcp)
- Folder-format rule bugs: [forum thread 1](https://forum.cursor.com/t/project-rules-documented-rule-md-folder-format-not-working-only-undocumented-mdc-format-works/145907), [forum thread 2](https://forum.cursor.com/t/new-cursor-rules-directory-format-not-working/147086)
- Plugins-skills CLI gap: [forum.cursor.com/t/cursor-agent-cli-does-not-register-skills-from-plugins-ide-does-parity-gap/158947](https://forum.cursor.com/t/cursor-agent-cli-does-not-register-skills-from-plugins-ide-does-parity-gap/158947)
