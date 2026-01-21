#!/bin/bash
#
# PreToolUse Hook - Validate Bash commands before execution
#
# Enforces safety rules for destructive operations.
# Multiple worktrees may share databases - destructive ops need explicit approval.
#
# Claude Code Hook Events:
#   - Trigger: PreToolUse (tool: Bash)
#   - Output: JSON with decision (allow/block) and optional reason
#
# Exit codes:
#   0 = allow (proceed with tool)
#   2 = block (deny with message to Claude)
#

set -euo pipefail

# Read hook input from stdin
INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // ""' 2>/dev/null || echo "")

# Output JSON response
respond() {
    local decision="$1"
    local reason="${2:-}"

    if [ -n "$reason" ]; then
        jq -n --arg d "$decision" --arg r "$reason" \
            '{"decision": $d, "reason": $r}'
    else
        jq -n --arg d "$decision" '{"decision": $d}'
    fi
}

# =============================================================================
# BLOCKED - Destructive database operations
# =============================================================================

# Prisma migrate reset (drops and recreates database)
if echo "$COMMAND" | grep -qiE 'prisma\s+migrate\s+reset'; then
    respond "block" "BLOCKED: prisma migrate reset detected. This drops the entire database. Get explicit user approval first."
    exit 2
fi

# Prisma db push with destructive flags
if echo "$COMMAND" | grep -qiE 'prisma\s+db\s+push' && echo "$COMMAND" | grep -qiE '(--force-reset|--accept-data-loss)'; then
    respond "block" "BLOCKED: Destructive prisma db push flag detected. Get explicit user approval first."
    exit 2
fi

# Raw SQL destructive commands (only in SQL execution contexts)
if echo "$COMMAND" | grep -qiE '(psql|mysql|prisma\s+db\s+execute)' && echo "$COMMAND" | grep -qiE '(DROP\s+(DATABASE|TABLE|SCHEMA)|TRUNCATE\s+TABLE)'; then
    respond "block" "BLOCKED: Destructive SQL command detected. Get explicit user approval first."
    exit 2
fi

# =============================================================================
# WARNED - Allow but inform Claude of concerns
# =============================================================================

# Non-migration schema changes
if echo "$COMMAND" | grep -qiE 'prisma\s+db\s+push' && ! echo "$COMMAND" | grep -qiE '(--force-reset|--accept-data-loss)'; then
    respond "allow" "WARNING: prisma db push without migrations. Consider using 'prisma migrate dev' instead for reproducible schema changes."
    exit 0
fi

# Direct package.json edits (should use package manager commands)
if echo "$COMMAND" | grep -qiE '(cat|echo|sed|awk).*package\.json'; then
    respond "allow" "WARNING: Appears to modify package.json directly. Use 'npm/pnpm add/remove' commands instead to keep lockfile in sync."
    exit 0
fi

# =============================================================================
# DEFAULT - Allow all other commands
# =============================================================================

respond "allow"
exit 0
