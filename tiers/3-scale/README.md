# Tier 3: Scale

Additions for complex projects with parallel development and long-running AI sessions.

## When to Upgrade to Tier 3

- Multiple features developed in parallel
- Long AI sessions that hit context limits
- Need for strategic planning documents
- Team coordination across workstreams
- Complex bugs requiring systematic investigation
- Product ideation before technical implementation

## What's Added

### Roles

| Role | Purpose |
|------|---------|
| [debug](roles/debug.md) | Systematic bug investigation with root cause analysis and TDD-mandatory fixes |
| [product-designer](roles/product-designer.md) | Pre-implementation ideation, UX strategy, product spec creation |

### Scripts

| Script | Purpose |
|--------|---------|
| [worktree-setup.sh](scripts/worktree-setup.sh) | Create isolated worktree for parallel development |
| [worktree-cleanup.sh](scripts/worktree-cleanup.sh) | Remove worktree and clean up branches |
| [worktree-validate.sh](scripts/worktree-validate.sh) | Validate worktree config and port allocation |

### Config

| Config | Purpose |
|--------|---------|
| [worktree.schema.json](config/worktree.schema.json) | Schema for worktree.yaml validation |
| [worktree.yaml](config/worktree.yaml) | Worktree config template |

### Hooks

| Hook | Purpose |
|------|---------|
| [pre-compact.sh](hooks/pre-compact.sh) | Save workflow state before context compaction |
| [post-compact.sh](hooks/post-compact.sh) | Restore context after compaction |
| [validate-bash.sh](hooks/validate-bash.sh) | Block destructive database commands |

### Skills

| Skill | Purpose |
|-------|---------|
| [reflect](skills/reflect/) | Session retrospective with improvement proposals |
| [accessibility-audit](skills/accessibility-audit/) | WCAG AA compliance, keyboard nav, focus states |
| [privacy-audit](skills/privacy-audit/) | PII detection, local-first validation, data retention |
| [cognitive-audit](skills/cognitive-audit/) | Cognitive load, Miller's Law, jargon analysis |
| [delight-audit](skills/delight-audit/) | Brand voice, empty states, micro-interactions |
| [resilience-audit](skills/resilience-audit/) | Offline capability, state recovery, graceful degradation |
| [worktree-init](skills/worktree-init/) | Generate project-specific worktree config |

### Strategy Docs

| Template | Purpose |
|----------|---------|
| [roadmap.md](docs/roadmap.md) | Track strategic direction across time horizons |
| [capabilities.md](docs/capabilities.md) | Document what exists vs. what's planned |

## Installation

After upgrade, files are added to your project:

```bash
# Files added to .aix/scripts/
worktree-setup.sh
worktree-cleanup.sh
worktree-validate.sh

# Files added to .aix/hooks/
pre-compact.sh
post-compact.sh

# Files added to .aix/config/
worktree.schema.json
worktree.yaml

# Files added to .aix/skills/
worktree-init/

# Templates added to docs/
roadmap.md
capabilities.md
```

## Using Worktrees

Worktrees allow parallel development without branch switching.

### Create a worktree

```bash
# From main repo
./.aix/scripts/worktree-setup.sh my-feature

# Creates:
#   ../my-feature/     (worktree directory)
#   feat/my-feature    (new branch from origin/dev)
```

### Validate configuration

```bash
./.aix/scripts/worktree-validate.sh my-feature
```

### Work in the worktree

```bash
cd ../my-feature
# Install dependencies
# Make changes, commit, push
# Create PR
```

### Clean up

```bash
# From main repo (after PR merged)
./.aix/scripts/worktree-cleanup.sh my-feature
```

## Context Compaction Hooks

Long AI sessions may hit context limits, triggering compaction. These hooks preserve and restore state.

### Setup

Configure hooks in `.claude/settings.json`:

```json
{
  "hooks": {
    "PreCompact": [
      {
        "matcher": "",
        "hooks": ["./.aix/hooks/pre-compact.sh"]
      }
    ],
    "SessionStart": [
      {
        "matcher": "compact",
        "hooks": ["./.aix/hooks/post-compact.sh"]
      }
    ]
  }
}
```

### What gets saved

Before compaction, `pre-compact.sh` captures:
- Current branch
- Uncommitted changes
- Recent commits
- Existing PR info

### Recovery

After compaction, `post-compact.sh` injects this context, and the AI:
1. Reviews the handoff state
2. Confirms with you before resuming
3. Does NOT push or create PRs without approval

### Handoff file

State is stored in `.aix-handoff.md` (gitignored). You can also manually save state:

```
"save to handoff"
```

## Strategy Documents

### Roadmap

Track work across time horizons:
- **Now**: Current sprint, clear acceptance criteria
- **Next**: 1-3 months, scoped but not started
- **Later**: 3-6 months, directional
- **Future**: 6+ months, vision

### Capabilities

Document system state:
- What's implemented vs. planned
- Known limitations
- Deprecations

## Using New Roles

### Debug Role

For complex bugs that need systematic investigation:

```
"Use the debug role to investigate why the search returns empty results"

Debug agent will:
1. Gather info (error, stack trace, steps to reproduce)
2. Form hypotheses ranked by likelihood
3. Investigate systematically (binary search, logging, isolation)
4. Write failing test BEFORE fix (TDD mandatory)
5. Implement fix
6. Verify test passes
```

Time limits:
- Simple bug: 15-20 minutes
- Medium bug: 30-45 minutes
- Complex bug: 60 minutes, then escalate

### Product Designer Role

For pre-implementation ideation and UX planning:

```
"Help me design a feature for usage statistics"

Product designer will:
1. Explore existing code/docs to ground recommendations
2. Ask clarifying questions (who, what problem, why now)
3. Challenge assumptions, surface conflicts
4. Lock decisions explicitly
5. Create product/UX spec in docs/specs/
```

The product designer **does not write code**. Output is a spec file that the analyst picks up later.

## This is the Final Tier

Tier 3 (Scale) is the highest tier. It includes everything needed for complex, parallel development with AI assistance.

If you need additional capabilities beyond this tier, consider:
- Custom roles in `.aix/roles/`
- Custom workflows in `.aix/workflows/`
- Custom skills in `.aix/skills/`
- Project-specific hooks and scripts
