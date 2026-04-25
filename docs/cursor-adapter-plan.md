# Cursor adapter — implementation plan

Working note for the `feat/cursor-adapter` branch. Delete once the adapter ships.

## 1. Cursor capability snapshot (April 2026)

**Rules (`.cursor/rules/*.mdc`)**
- YAML frontmatter: `description`, `globs`, `alwaysApply`. Four activation modes: Always (`alwaysApply: true`), Auto Attached (globs match), Agent Requested (description-driven), Manual.
- Nested rule directories supported. As of v2.2 the new canonical form is a folder with `RULE.md` + frontmatter, but `.mdc` files still work.
- Legacy `.cursorrules` (single file at repo root) is deprecated but still read.

**Agents / personas / modes**
- Built-in modes only: Agent / Plan / Ask / Debug. **No file-based custom-mode or per-project sub-agent system today** (community is asking for it; it is not shipped). There is no Cursor analogue of `.claude/agents/*.md`.
- `AGENTS.md` and `CLAUDE.md` at repo root are read by both IDE and CLI as top-level guidance.

**CLI (`cursor-agent` / `cursor agent`)**
- Install: `curl https://cursor.com/install -fsS | bash`. Print mode: `agent -p "..."`, `--output-format json|stream-json|text`. Reads the same `.cursor/rules/`, `AGENTS.md`, `CLAUDE.md`, and MCP config as the IDE.
- Config command: `cursor-agent cli config approvalMode auto`. Auth via `CURSOR_API_KEY`.

**Hooks (beta, v1.7+)**
- Config in `.cursor/hooks.json` (also user `~/.cursor/hooks.json`, enterprise system path). Events include `sessionStart`, `sessionEnd`, `preToolUse`, `postToolUse`, `beforeShellExecution`, `afterShellExecution`, `beforeMCPExecution`, `afterMCPExecution`, `beforeReadFile`, `afterFileEdit`, `beforeSubmitPrompt`, `preCompact`, `afterAgentResponse`, `stop`, plus Tab hooks. Schema: `{version: 1, hooks: { event: [{command, type, timeout, failClosed, matcher}] }}`. Stdin payload includes `conversation_id`, `model`, `workspace_roots`, `transcript_path`. Exit 2 = block.

**MCP**
- `.cursor/mcp.json` (project) and `~/.cursor/mcp.json` (global), root key `mcpServers`. ~40 active-tool ceiling.

**Model selection**
- Model is chosen globally per session in the IDE picker, or via `-m` on the CLI. **No per-rule, per-mode, or per-agent model field is honored.** Per-mode model selection is a still-open feature request.

**Skills**
- Cursor IDE/CLI agent reads skills from `.claude/skills/` honoring the SKILL.md spec (Anthropic open-standard skills). `.cursor/skills/` support is community-requested but not confirmed; safest target is `.claude/skills/`.

## 2. aix → Cursor mapping

| aix concept | Cursor target | Notes |
|---|---|---|
| `constitution.md` | `AGENTS.md` symlink at repo root (also `.cursor/rules/00-constitution.mdc` with `alwaysApply: true`) | AGENTS.md is read by IDE+CLI; mirroring it as an `alwaysApply` rule guarantees inclusion in Plan/Ask modes that some users report under-weight AGENTS.md. |
| Roles (`analyst`, `coder`, `reviewer`, ...) | `.cursor/rules/<role>.mdc` with `description` populated → "Agent Requested" activation | No first-class sub-agent slot exists. Description-driven rules let the agent self-select a role-shaped persona on demand. Body = role markdown body. |
| Workflows | `.cursor/rules/workflows/<name>.mdc` (Manual rules, invoked via `@<name>`) | |
| Skills | `.claude/skills/` symlink → `.aix/skills` (Cursor reads this natively today). Optionally also `.cursor/skills/` for forward-compat. | |
| Model sets | **No-op for per-role**. Adapter accepts `--model-set` but only emits a global hint (e.g. writes `.cursor/MODEL.md` or recommends `cursor-agent -m <model>`). | Be explicit in README. |
| Hooks | `.cursor/hooks.json` generated from `.aix/hooks/` | Map aix's `pre-compact.sh`/`post-compact.sh` → `preCompact` and `sessionStart`. Other aix hook events translate cleanly to Cursor's larger hook menu. |
| MCP | `.cursor/mcp.json` (pass-through if `.aix/mcp.json` exists) | Optional. |

## 3. Gaps / non-support

- **No per-role model**: model-sets degrade to a single global recommendation. The granularity Claude Code/Kiro give us is lost. Document this; don't pretend otherwise.
- **No first-class sub-agents**: roles become "Agent Requested" rules, not dispatchable agents. The model decides whether to "act as the reviewer"; we can't force it the way Claude's `/agents` does.
- **No tool-allowlist per role**: Cursor rules carry no tool field. `tools:` mapping in adapter.yaml becomes informational (only used for tool-name substitution in the rule body text via `replace_tool_names_in_body`).
- **Hooks are beta**: schema can change; pin `version: 1` and warn.
- **`.mdc` content-size limits**: community guidance says keep each rule under ~500 lines / a few KB; long role bodies may need trimming or splitting.

## 4. Concrete file plan

### New files

**`adapters/cursor/adapter.yaml`** (sketch)
```yaml
adapter: cursor
version: 1
output:
  agents: .cursor/rules        # rules dir doubles as "agents" output
  skills: .cursor/skills       # symlink (forward-compat)
  skills_alt: .claude/skills   # secondary symlink for native skill loading
roles:
  format: mdc                  # NEW format - rule .mdc with cursor frontmatter
  filename: "{name}.mdc"
  enabled: true
skills:
  strategy: symlink
model_sets:
  enabled: true                # accepted but only a global hint is emitted
  default: default
hooks:
  enabled: true
  config_path: .cursor/hooks.json
mcp:
  enabled: true
  config_path: .cursor/mcp.json
tools:                         # informational - used for body text substitution
  Read: read_file
  Write: edit_file
  Edit: edit_file
  Bash: run_terminal_cmd
  Grep: grep
  Glob: file_search
```

**`adapters/cursor/generate.sh`**
- Detect bootstrapped vs submodule layout (mirror claude-code/generate.sh).
- Symlink `AGENTS.md` → `.aix/constitution.md`.
- Create `.cursor/` dir; symlink `.cursor/skills` → `../.aix/skills` and `.claude/skills` → same.
- Run `aix-generate.py --adapter cursor` to emit `.cursor/rules/*.mdc`.
- If `.aix/hooks/pre-compact.sh` exists, write `.cursor/hooks.json` mapping `preCompact` and `sessionStart`.
- If `.aix/mcp.json` exists, copy/symlink to `.cursor/mcp.json`.

**`adapters/cursor/templates/`**
- `rules-tier0.md`, `rules-tier1.md`, `rules-tier2.md` — same role bodies as claude tiers but with the constitutional framing slightly altered for "Agent Requested" activation (so the description field is meaningful).
- `constitution-rule.mdc` — thin wrapper that frontmatters the constitution as `alwaysApply: true`.

**`adapters/cursor/model-sets/default.yaml`** (and budget/mid/pro for parity)
- Single role-keyed map; consumed only for tool-name substitution and a one-line model recommendation written into a `.cursor/MODEL.md` note.

### Changes to `scripts/aix-generate.py`

Today the script supports `format: markdown` and `format: json`. Add `format: mdc`:

- New function `generate_mdc_rule(role_name, frontmatter, body, adapter_config, model_config)` that emits Cursor frontmatter (`description`, `globs`, `alwaysApply`) instead of the Claude frontmatter (`name`, `description`, `model`, `tools`).
- Activation rules: if role frontmatter has `aix_activation: always` → `alwaysApply: true`; if it has `globs:` → auto-attach with that globs list; default → "Agent Requested" with `description` set from role description, `alwaysApply: false`, `globs: ""`.
- Drop the `model` and `tools` fields (Cursor ignores them); still run `replace_tool_names_in_body` so prose mentions Cursor-native tool names.
- Hook the new format into `generate_adapter()` next to the existing `if role_format == "json"` branch.
- Optional: special-case `adapter == "cursor"` to also emit `.cursor/MODEL.md` listing the model-set's role→model mapping as advisory text.

### Changes to `add-adapter.sh`

Add to the `case "$ADAPTER_INPUT"` switch:
```
cursor)
    ADAPTER_KEY="cursor"
    ADAPTER_DIR="cursor"
    ENTRYPOINT="AGENTS.md"
    ;;
```
Update `usage()` to list `cursor`. Note: if both `kiro` and `cursor` are enabled in the same repo they both want `AGENTS.md` (single symlink, both read it).

### Changes to `bootstrap.sh`

- Add option `6) Cursor` to the `select_adapter` menu.
- Add `cursor) ADAPTER_DIR="cursor" ;;` in the adapter-dir case.
- Add `cursor)` arm to the entry-point case (symlink AGENTS.md, then call `adapters/cursor/generate.sh 0`).
- Add the trailing structure-summary block for cursor (`.cursor/rules/`, `.cursor/skills/`).

### Changes to `docs/ROADMAP.md` and `README.md`

- Add a row to the adapter table: `cursor | .cursor/rules/*.mdc | AGENTS.md | hooks (beta) | model-sets advisory only`.
- Note Cursor-specific limitations: no per-role model, no sub-agents, hooks beta.

## 5. Open questions (decide before implementing)

1. **IDE only, CLI only, or both?** Plan above targets both (one fileset works for each). Confirm or scope down.
2. **Default role activation** — "Agent Requested" (description-driven, lean) vs "Always Apply" (guaranteed but bloats every prompt). Which default?
3. **`.cursor/rules/` flat vs folder-per-role** — Cursor 2.2+ prefers `<role>/RULE.md`. Pick flat `.mdc` (simpler, well-supported) or folder form (more future-proof)?
4. **Skills location** — `.claude/skills/` only (today's reality), `.cursor/skills/` (forward-looking but unread today), or both?
5. **Model sets** — keep as advisory-only, or drop the `model_sets` block from `adapter.yaml` entirely so users aren't misled?
6. **Hooks** — emit `.cursor/hooks.json` by default if `.aix/hooks/` exists, or opt-in via flag (since hooks are beta)?
7. **`AGENTS.md` collision** — if a repo enables both `kiro` and `cursor`, both want this symlink. Accept the shared symlink, or add adapter-priority logic in `add-adapter.sh`?

## Critical files to read when resuming

- `/Users/ryan/Github/aix/scripts/aix-generate.py`
- `/Users/ryan/Github/aix/adapters/claude-code/adapter.yaml`
- `/Users/ryan/Github/aix/adapters/claude-code/generate.sh`
- `/Users/ryan/Github/aix/add-adapter.sh`
- `/Users/ryan/Github/aix/bootstrap.sh`

## Sources

- Cursor Rules MDC reference: github.com/sanjeed5/awesome-cursor-rules-mdc
- Cursor docs: cursor.com/docs/{agent/plan-mode, cli/headless, cli/using, hooks, context/mcp}
- Skywork hooks 1.7 guide: skywork.ai/blog/how-to-cursor-1-7-hooks-guide
- Per-mode model FR: forum.cursor.com/t/default-model-selection-per-mode-agent-ask-plan-debug/150676
- Agent plugins / sub-agents thread: forum.cursor.com/t/agent-plugins-isolated-packaging-lifecycle-management-for-sub-agents-skills-hooks-rules-incl-agent-md-across-cursor-ide-cli/151250
- Skills support thread: forum.cursor.com/t/is-skills-supported/146837
