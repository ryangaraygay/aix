#!/usr/bin/env bash
#
# Post-Compact Hook (SessionStart with "compact" matcher)
#
# Reads .aix-handoff.md and outputs JSON with additionalContext for Claude Code
# to inject into the session context after compaction.
#
# Claude Code Hook Events:
#   - Trigger: SessionStart (with matcher for compaction)
#   - Output: JSON with additionalContext
#

# Don't use strict mode - we want the hook to succeed even if parts fail
# set -euo pipefail

HANDOFF_FILE=".aix-handoff.md"

# Function to escape string for JSON (fallback if jq not available)
json_escape() {
    local str="$1"
    # Escape backslashes, quotes, newlines, tabs, and other control chars
    str="${str//\\/\\\\}"      # backslash
    str="${str//\"/\\\"}"      # double quote
    str="${str//$'\n'/\\n}"    # newline
    str="${str//$'\r'/\\r}"    # carriage return
    str="${str//$'\t'/\\t}"    # tab
    printf '%s' "$str"
}

# Build the context string
build_context() {
    echo "## COMPACTION RECOVERY NOTICE"
    echo ""
    echo "This session resumed after context compaction."
    echo ""
    echo "### MANDATORY: Before Any Action"
    echo ""
    echo "1. Read the handoff state below carefully"
    echo "2. Check TaskList for pending work"
    echo "3. DO NOT push or create PRs without user approval"
    echo ""

    if [ -f "$HANDOFF_FILE" ]; then
        echo "---"
        echo ""
        cat "$HANDOFF_FILE" 2>/dev/null || echo "(Failed to read handoff file)"
        echo ""
    else
        echo "### WARNING: No .aix-handoff.md found"
        echo ""
        echo "Run these commands to gather state:"
        echo "- git status"
        echo "- git log --oneline -5"
        echo "- git branch --show-current"
        echo ""
    fi
}

# Main execution
main() {
    # Capture context
    local context
    context=$(build_context)

    # Try jq first, fall back to manual escaping
    local escaped_context
    if command -v jq >/dev/null 2>&1; then
        escaped_context=$(printf '%s' "$context" | jq -Rs '.' 2>/dev/null)
        if [ -z "$escaped_context" ] || [ "$escaped_context" = "null" ]; then
            # jq failed, use fallback
            escaped_context="\"$(json_escape "$context")\""
        fi
    else
        # No jq available, use fallback
        escaped_context="\"$(json_escape "$context")\""
    fi

    # Output JSON to stdout
    printf '{"hookSpecificOutput":{"hookEventName":"SessionStart","additionalContext":%s}}' "$escaped_context"
}

# Run main and exit with success regardless
main
exit 0
