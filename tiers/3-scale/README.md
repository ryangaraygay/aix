# Tier 3: Scale

Additions for complex projects with parallel development and long-running AI sessions.

## When to Upgrade to Tier 3

- Multiple features developed in parallel
- Long AI sessions that hit context limits
- Need for strategic planning documents
- Team coordination across workstreams

## What's Added

### Scripts

| Script | Purpose |
|--------|---------|
| [worktree-setup.sh](scripts/worktree-setup.sh) | Create isolated worktree for parallel development |
| [worktree-cleanup.sh](scripts/worktree-cleanup.sh) | Remove worktree and clean up branches |

### Hooks

| Hook | Purpose |
|------|---------|
| [pre-compact.sh](hooks/pre-compact.sh) | Save workflow state before context compaction |
| [post-compact.sh](hooks/post-compact.sh) | Restore context after compaction |

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

# Files added to .aix/hooks/
pre-compact.sh
post-compact.sh

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

## This is the Final Tier

Tier 3 (Scale) is the highest tier. It includes everything needed for complex, parallel development with AI assistance.

If you need additional capabilities beyond this tier, consider:
- Custom roles in `.aix/roles/`
- Custom workflows in `.aix/workflows/`
- Custom skills in `.aix/skills/`
- Project-specific hooks and scripts
