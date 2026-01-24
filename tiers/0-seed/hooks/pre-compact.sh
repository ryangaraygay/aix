#!/usr/bin/env bash
#
# PreCompact Hook - Save workflow state before context compaction
#
# Updates .aix-handoff.md with a snapshot section containing current git state.
# The post-compact hook reads this file to restore context after compaction.
#
# Claude Code Hook Events:
#   - Trigger: PreCompact
#   - Output: Updates .aix-handoff.md file
#

# Don't use strict mode - we want the hook to succeed even if parts fail
# set -euo pipefail

HANDOFF_FILE=".aix-handoff.md"
SNAPSHOT_START="<!-- COMPACTION_SNAPSHOT_START -->"
SNAPSHOT_END="<!-- COMPACTION_SNAPSHOT_END -->"

# Read hook input from stdin (contains trigger info)
INPUT=$(cat 2>/dev/null || echo '{}')
TRIGGER=$(echo "$INPUT" | jq -r '.trigger // "unknown"' 2>/dev/null || echo "unknown")

# Capture git state (with fallbacks)
CURRENT_BRANCH=$(git branch --show-current 2>/dev/null || echo "unknown")
GIT_STATUS=$(git status --short 2>/dev/null || echo "(no changes)")
UNCOMMITTED_COUNT=$(echo "$GIT_STATUS" | grep -c '^' 2>/dev/null || echo "0")
RECENT_COMMITS=$(git log --oneline -5 2>/dev/null || echo "(no commits)")

# Check for existing PR (requires gh CLI)
EXISTING_PR="[]"
if command -v gh >/dev/null 2>&1; then
    EXISTING_PR=$(gh pr list --head "$CURRENT_BRANCH" --json number,title,url 2>/dev/null || echo "[]")
fi

# Capture worktree context
REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
WORKTREE_NAME=$(basename "$REPO_ROOT")
MAIN_REPO=$(git worktree list --porcelain 2>/dev/null | awk '/^worktree / {print $2; exit}' || echo "")
WORKTREE_RELATIVE="."
if [ -n "$MAIN_REPO" ] && [ "$REPO_ROOT" != "$MAIN_REPO" ]; then
    WORKTREE_RELATIVE="${REPO_ROOT#"$MAIN_REPO"/}"
fi

# Update handoff file with snapshot
update_handoff() {
    # If file exists, strip existing snapshot section
    if [ -f "$HANDOFF_FILE" ]; then
        awk -v start="$SNAPSHOT_START" -v end="$SNAPSHOT_END" '
            $0 == start { in_block = 1; next }
            $0 == end { in_block = 0; next }
            !in_block { print }
        ' "$HANDOFF_FILE" > "${HANDOFF_FILE}.tmp" 2>/dev/null
        mv "${HANDOFF_FILE}.tmp" "$HANDOFF_FILE" 2>/dev/null || true
    else
        # Create minimal handoff if none exists
        cat << 'EOF' > "$HANDOFF_FILE"
# Session Handoff

> Auto-generated before compaction.

## Status: interrupted

No handoff file existed. Please gather state manually.
EOF
    fi

    # Append fresh snapshot
    {
        printf '\n%s\n' "$SNAPSHOT_START"
        printf '## Compaction Snapshot\n'
        printf -- '- Timestamp: %s\n' "$(date -u +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null || date)"
        printf -- '- Trigger: %s\n' "$TRIGGER"
        printf -- '- Branch: %s\n' "$CURRENT_BRANCH"
        printf -- '- Worktree: %s\n' "$WORKTREE_NAME"
        printf -- '- Worktree Path: %s\n' "$WORKTREE_RELATIVE"
        printf -- '- Uncommitted Files: %s\n\n' "$UNCOMMITTED_COUNT"
        printf '### Uncommitted Changes\n```\n%s\n```\n\n' "$GIT_STATUS"
        printf '### Recent Commits\n```\n%s\n```\n\n' "$RECENT_COMMITS"
        printf '### Existing PR\n```json\n%s\n```\n' "$EXISTING_PR"
        printf '%s\n' "$SNAPSHOT_END"
    } >> "$HANDOFF_FILE"
}

update_handoff

echo "Handoff updated: $HANDOFF_FILE" >&2
exit 0
