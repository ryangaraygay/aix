# AIX Roadmap

> Known issues, planned improvements, and future ideas for AIX.

---

## Known Issues

### Cursor adapter — workflows reachable but not registered as formal Manual rules

**Adapter:** `cursor` · **Status:** Open (current behavior; design discussion in [#13](https://github.com/ryangaraygay/aix/issues/13))

The cursor adapter symlinks `.cursor/rules/workflows/` → `.aix/workflows/`. Cursor reads the workflow files via `@<name>` file references but doesn't register them as formal Manual rules (no `.mdc` frontmatter). Workflows are reachable but don't appear in Cursor's rules UI.

The broader design question — how *all* adapters should expose workflows to their target tools — is tracked in [#13](https://github.com/ryangaraygay/aix/issues/13). Current cursor-specific trade-offs documented in `adapters/cursor/README.md` §4.

### Cursor adapter — subagent `model:` ignored when parent agent is on Auto

**Adapter:** `cursor`
**Component:** `adapters/cursor/model-sets/`, Cursor 2.5 itself
**Status:** Open (upstream Cursor bug, documented in adapter README)

**Problem:**
Cursor 2.5 silently flattens subagent `model:` frontmatter to the parent agent's effective model when the parent runs on Auto, when the user lacks access to the requested model, or for level-2 nested subagents.

**Impact:**
The `pro` and `top-tier` model sets only honor their pinned premium models when the parent agent is on a pinned non-Auto model. On Auto-mode (default for Hobby tier), all subagents collapse to `composer-2-fast`. Documented in `adapters/cursor/README.md` §3.

**Resolution path:**
Wait for upstream Cursor fix. Tracked in forum threads [151134](https://forum.cursor.com/t/cursor-rules-and-sub-agent-calls-do-not-work-when-agent-model-is-set-to-auto-or-composer-1/151134), [152440](https://forum.cursor.com/t/sub-agent-ignoring-model-configuration-in-version-2-5/152440), [150846](https://forum.cursor.com/t/my-subagents-cant-be-used-in-auto-model/150846).

---

### Husky Git Hooks Setup Gap

**Tier:** 1 (Sprout)
**Component:** `upgrade.sh`, `.husky/`
**Status:** Resolved

**Problem:**
The upgrade script adds `.husky/` directory with pre-commit hooks, but doesn't:
1. Check if `package.json` exists
2. Install husky as a dependency
3. Run `husky install` to register the hooks

**Impact:**
Git hooks don't work for projects that don't already have husky configured.

**Resolution:**
Implemented conditional logic in `upgrade.sh`:
- If `package.json` exists: use `.husky/` and remind user to install husky
- If no `package.json`: install hooks directly to `.git/hooks/`

---

### New Skills/Roles Require Session Restart

**Tier:** All
**Component:** `upgrade.sh`, `adopt.sh`, `sync.sh`, Claude Code integration
**Status:** Open (Known Limitation)

**Problem:**
When new skills or roles (sub-agents) are adopted via `aix-init upgrade`, `adopt`, or `sync`, the existing Claude Code session cannot detect them. A new session is required.

**Impact:**
Users may be confused when newly added skills or roles aren't available immediately after running upgrade/adopt/sync commands.

**Workaround:**
Start a new Claude Code session after adding new skills or roles.

**Note:**
This is a Claude Code limitation, not an AIX bug. Claude Code reads configuration at session start.

---

## Planned Improvements

### Legacy Codebase Workflows

**Tier:** 2 (Grow)
**Component:** `workflows/`
**Status:** Planned

Workflows for safely working with existing codebases that lack tests or have unclear behavior.

**Planned Workflows:**

| Workflow | Purpose |
|----------|---------|
| `codebase-audit` | Analyze existing codebase - security, dependencies, architecture, risk areas |
| `characterize` | Write characterization tests capturing current behavior before refactoring |
| `safe-refactor` | Transform code while preserving behavior (uses characterization tests as safety net) |

**Use Cases:**
- Legacy codebase modernization
- Taking over projects with no tests
- Refactoring tightly-coupled code safely

---

## Future Ideas

### Characterization Test Skill

**Tier:** 2 (Grow)
**Component:** `skills/`
**Status:** Idea

AI-driven generation of behavior-capturing tests for existing code. Documents what code *does* (not what it *should* do) as a safety net before refactoring.

---

### Codebase Audit Skill

**Tier:** 2 (Grow)
**Component:** `skills/`
**Status:** Idea

Automated analysis skill that produces actionable report:
- Security scan results
- Dependency audit
- Architecture coupling assessment
- High-risk change areas
- Recommended approach

---

## Contributing

To add items to this roadmap:
1. Open an issue in the repository
2. Reference the issue number here
3. Include: tier, component, status, problem, and recommended solution
