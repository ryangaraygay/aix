#!/bin/bash
#
# Post-Compact Hook (SessionStart with "compact" matcher)
#
# Reads .aix-handoff.md and outputs JSON with additionalContext for Claude Code
# to inject into the session context after compaction.
#
# Format: {"hookSpecificOutput": {"hookEventName": "SessionStart", "additionalContext": "..."}}

set -euo pipefail

HANDOFF_FILE=".aix-handoff.md"

# Build the context string
build_context() {
    echo ""
    echo "## COMPACTION RECOVERY NOTICE"
    echo ""
    echo "This session resumed after context compaction."
    echo ""
    echo "### MANDATORY: Before Any Action"
    echo ""
    echo "1. **DO NOT push or create PRs** without explicit user approval"
    echo "2. **Review the handoff state below**"
    echo "3. **Confirm with user** before resuming work"
    echo ""

    if [ -f "$HANDOFF_FILE" ]; then
        echo "---"
        echo ""
        cat "$HANDOFF_FILE"
        echo ""
    else
        echo "### WARNING: No .aix-handoff.md found"
        echo ""
        echo "Gather state manually:"
        echo ""
        echo '```bash'
        echo "git status                    # Check uncommitted changes"
        echo "git log --oneline -5          # Recent commits"
        echo "git branch --show-current     # Current branch"
        echo 'gh pr list --head $(git branch --show-current)  # Check for existing PR'
        echo '```'
        echo ""
    fi
}

# Capture context and convert to JSON
CONTEXT=$(build_context)

# Use jq to properly escape the string for JSON
if command -v jq &> /dev/null; then
    ESCAPED_CONTEXT=$(printf '%s' "$CONTEXT" | jq -Rs '.')
else
    # Fallback: basic escaping
    ESCAPED_CONTEXT=$(printf '%s' "$CONTEXT" | sed 's/\\/\\\\/g; s/"/\\"/g; s/$/\\n/' | tr -d '\n')
    ESCAPED_CONTEXT="\"$ESCAPED_CONTEXT\""
fi

# Output JSON to stdout for Claude Code to inject into context
printf '{"hookSpecificOutput":{"hookEventName":"SessionStart","additionalContext":%s}}\n' "$ESCAPED_CONTEXT"

echo "Post-compaction context prepared" >&2
exit 0
