# Tier 0 Hooks - Context Management

Foundational hooks for managing Claude Code context and state persistence.

## Available Hooks

| Hook | Event | Purpose |
|------|-------|---------|
| [pre-compact.sh](./pre-compact.sh) | PreCompact | Save workflow state before context compaction |
| [post-compact.sh](./post-compact.sh) | SessionStart | Restore context after compaction |

## Why Tier 0?

Compaction handling is foundational for any autonomous agent work:
- Long implementations will hit context limits
- Without state preservation, compaction loses critical workflow context
- These hooks ensure continuity across context boundaries

## Installation

These hooks are automatically configured when you run `bootstrap.sh` or `upgrade.sh`.

The hooks are added to `.aix/hooks/` and configured in `.claude/settings.json`:

```json
{
  "hooks": {
    "PreCompact": [
      {
        "type": "command",
        "command": "./.aix/hooks/pre-compact.sh"
      }
    ],
    "SessionStart": [
      {
        "type": "command",
        "command": "./.aix/hooks/post-compact.sh",
        "matcher": "compact"
      }
    ]
  }
}
```

## How It Works

1. **Before compaction** - `pre-compact.sh` captures:
   - Git branch and status
   - Uncommitted changes
   - Recent commits
   - Existing PR info
   - Saves to `.aix-handoff.md`

2. **After compaction** - `post-compact.sh`:
   - Reads `.aix-handoff.md`
   - Injects recovery context with checklist
   - Reminds agent to verify state before continuing

## Handoff File Format

The `.aix-handoff.md` file (gitignored) preserves workflow state:

```markdown
## Current Phase: implementation
## Completed By: coder
## Status: in_progress
## Summary: Implementing feature X

<!-- COMPACTION_SNAPSHOT_START -->
## Compaction Snapshot
- Timestamp: 2026-01-21T10:30:00Z
- Branch: feat/add-search
- Uncommitted Files: 3

### Uncommitted Changes
```
M  src/components/Search.tsx
A  tests/search.test.ts
```
<!-- COMPACTION_SNAPSHOT_END -->
```

## See Also

- [Tier 3 Hooks](../../3-scale/hooks/_index.md) - Additional safety hooks (validate-bash)
