# Tier 3 Hooks - Safety & Validation

Advanced hooks for enterprise safety requirements.

> **Note:** Compaction hooks (pre-compact.sh, post-compact.sh) are now in [Tier 0](../../0-seed/hooks/_index.md) as foundational capabilities.

## Available Hooks

| Hook | Event | Purpose |
|------|-------|---------|
| [validate-bash.sh](./validate-bash.sh) | PreToolUse | Block destructive database commands |

## Installation

Add hooks to your Claude Code settings:

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
    ],
    "PreToolUse": [
      {
        "type": "command",
        "command": "./.aix/hooks/validate-bash.sh",
        "toolName": "Bash"
      }
    ]
  }
}
```

## Hook Types

### PreCompact Hook

Triggered before Claude Code compacts the conversation context.

**Input** (stdin):
```json
{
  "trigger": "auto" | "manual"
}
```

**Side Effect**: Updates `.ai-handoff.md` with git state snapshot.

### Post-Compact Hook (SessionStart)

Triggered when a new session starts after compaction.

**Input** (stdin):
```json
{
  "hookEventName": "SessionStart"
}
```

**Output** (stdout):
```json
{
  "hookSpecificOutput": {
    "hookEventName": "SessionStart",
    "additionalContext": "... context to inject ..."
  }
}
```

### Validate-Bash Hook (PreToolUse)

Triggered before executing Bash commands.

**Input** (stdin):
```json
{
  "tool_input": {
    "command": "the bash command"
  }
}
```

**Output** (stdout):
```json
{"decision": "allow"}
// or
{"decision": "block", "reason": "explanation"}
```

**Exit codes**:
- `0` = allow
- `2` = block

## Blocked Commands

The validate-bash hook blocks these destructive operations:

| Command | Why Blocked |
|---------|-------------|
| `prisma migrate reset` | Drops entire database |
| `prisma db push --force-reset` | Data loss |
| `DROP DATABASE/TABLE` | Irreversible |
| `TRUNCATE TABLE` | Data loss |

## Handoff File Format

The `.ai-handoff.md` file preserves workflow state:

```markdown
## Current Phase: implementation
## Completed By: coder
## Status: in_progress
## Summary: Implementing feature X

<!-- COMPACTION_SNAPSHOT_START -->
## Compaction Snapshot
- Timestamp: 2025-01-20T10:30:00Z
- Branch: feat/add-search
- Uncommitted Files: 3

### Uncommitted Changes
```
M  src/components/Search.tsx
M  src/api/search.ts
A  tests/search.test.ts
```

### Recent Commits
```
abc1234 feat: add search input
def5678 chore: update deps
```
<!-- COMPACTION_SNAPSHOT_END -->
```

## Writing Custom Hooks

1. Create executable script in `.aix/hooks/`
2. Read JSON from stdin
3. Output JSON to stdout (if required)
4. Use correct exit codes

```bash
#!/bin/bash
set -euo pipefail

# Read input
INPUT=$(cat)
VALUE=$(echo "$INPUT" | jq -r '.some_field')

# Do processing...

# Output response
jq -n '{"decision": "allow"}'
exit 0
```

## See Also

- [Claude Code Hooks Documentation](https://docs.anthropic.com/claude-code/hooks)
- [Worktree Scripts](../scripts/)
