#!/bin/bash
#
# PreToolUse Hook - Validate Bash commands before execution
#
# Enforces safety rules for destructive operations.
# Multiple worktrees may share databases - destructive ops need explicit approval.
#
# Claude Code Hook Events:
#   - Trigger: PreToolUse (tool: Bash)
#   - Output: JSON with hookSpecificOutput containing permissionDecision
#
# Exit codes:
#   0 = success (JSON response contains the decision)
#   non-zero = hook error (stderr shown to Claude, tool proceeds)
#
# Permission decisions (in hookSpecificOutput.permissionDecision):
#   "allow" = bypass permission system, proceed with tool
#   "deny"  = block tool execution with reason
#   "ask"   = prompt user for confirmation
#

set -euo pipefail

# Read hook input from stdin
INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // ""' 2>/dev/null || echo "")

# Output JSON response in Claude Code's expected format
respond() {
    local decision="$1"
    local reason="${2:-}"

    if [ -n "$reason" ]; then
        jq -n --arg d "$decision" --arg r "$reason" \
            '{
                "hookSpecificOutput": {
                    "hookEventName": "PreToolUse",
                    "permissionDecision": $d,
                    "permissionDecisionReason": $r
                }
            }'
    else
        jq -n --arg d "$decision" \
            '{
                "hookSpecificOutput": {
                    "hookEventName": "PreToolUse",
                    "permissionDecision": $d
                }
            }'
    fi
}

# =============================================================================
# BLOCKED - Destructive database operations
# =============================================================================

# Prisma migrate reset (drops and recreates database)
if echo "$COMMAND" | grep -qiE 'prisma\s+migrate\s+reset'; then
    respond "deny" "BLOCKED: prisma migrate reset detected. This drops the entire database. Get explicit user approval first."
    exit 0
fi

# Prisma db push with destructive flags
if echo "$COMMAND" | grep -qiE 'prisma\s+db\s+push' && echo "$COMMAND" | grep -qiE '(--force-reset|--accept-data-loss)'; then
    respond "deny" "BLOCKED: Destructive prisma db push flag detected. Get explicit user approval first."
    exit 0
fi

# Raw SQL destructive commands (only in SQL execution contexts)
if echo "$COMMAND" | grep -qiE '(psql|mysql|prisma\s+db\s+execute)' && echo "$COMMAND" | grep -qiE '(DROP\s+(DATABASE|TABLE|SCHEMA)|TRUNCATE\s+TABLE)'; then
    respond "deny" "BLOCKED: Destructive SQL command detected. Get explicit user approval first."
    exit 0
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
