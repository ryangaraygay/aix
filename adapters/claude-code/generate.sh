#!/bin/bash
# Generate Claude Code files from aix framework
# Usage: ./aix/adapters/claude-code/generate.sh [tier]
#
# Supports two patterns:
# 1. Bootstrapped repos: files copied flat to .aix/
# 2. Submodule repos: tier structure at .aix/tiers/

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
AIX_DIR="$REPO_ROOT/.aix"
CLAUDE_DIR="$REPO_ROOT/.claude"

# Default tier
TIER="${1:-0}"

# Map tier to name
get_tier_name() {
    case $1 in
        0) echo "seed" ;;
        1) echo "sprout" ;;
        2) echo "grow" ;;
        3) echo "scale" ;;
        *) echo "seed" ;;
    esac
}

echo "Generating Claude Code files for Tier $TIER..."

# Ensure .aix exists
if [ ! -d "$AIX_DIR" ]; then
    echo "Error: .aix directory not found. Run bootstrap.sh first."
    exit 1
fi

# Detect structure: submodule (has tiers/) vs bootstrapped (flat)
if [ -d "$AIX_DIR/tiers" ]; then
    # Submodule pattern - use tier paths
    TIER_NAME=$(get_tier_name $TIER)
    TIER_PATH="tiers/$TIER-$TIER_NAME"
    CONSTITUTION_PATH=".aix/$TIER_PATH/constitution.md"
    ROLES_PATH="../.aix/$TIER_PATH/roles"
    SKILLS_PATH="../.aix/$TIER_PATH/skills"
    HOOKS_DIR="$AIX_DIR/$TIER_PATH/hooks"
    HOOKS_CMD_PATH="./.aix/$TIER_PATH/hooks"
    echo "Detected submodule structure"
else
    # Bootstrapped pattern - flat structure
    CONSTITUTION_PATH=".aix/constitution.md"
    ROLES_PATH="../.aix/roles"
    SKILLS_PATH="../.aix/skills"
    HOOKS_DIR="$AIX_DIR/hooks"
    HOOKS_CMD_PATH="./.aix/hooks"
    echo "Detected bootstrapped structure"
fi

# Create CLAUDE.md symlink
if [ -L "$REPO_ROOT/CLAUDE.md" ] || [ -f "$REPO_ROOT/CLAUDE.md" ]; then
    rm "$REPO_ROOT/CLAUDE.md"
fi
ln -s "$CONSTITUTION_PATH" "$REPO_ROOT/CLAUDE.md"
echo "✓ Created CLAUDE.md symlink -> $CONSTITUTION_PATH"

# Create .claude directory
mkdir -p "$CLAUDE_DIR"

# Create agents symlink (Claude Code expects .claude/agents/ directory)
if [ -L "$CLAUDE_DIR/agents" ] || [ -d "$CLAUDE_DIR/agents" ]; then
    rm -rf "$CLAUDE_DIR/agents"
fi
# Check if roles directory exists at the expected path
ROLES_FULL_PATH="$REPO_ROOT/.claude/$ROLES_PATH"
if [ -d "${ROLES_FULL_PATH#$REPO_ROOT/.claude/}" ] || [ -d "$AIX_DIR/roles" ] || [ -d "$AIX_DIR/$TIER_PATH/roles" ] 2>/dev/null; then
    ln -s "$ROLES_PATH" "$CLAUDE_DIR/agents"
    echo "✓ Created .claude/agents symlink -> $ROLES_PATH"
fi

# Create skills symlink
if [ -L "$CLAUDE_DIR/skills" ] || [ -d "$CLAUDE_DIR/skills" ]; then
    rm -rf "$CLAUDE_DIR/skills"
fi
if [ -d "$AIX_DIR/skills" ] || [ -d "$AIX_DIR/$TIER_PATH/skills" ] 2>/dev/null; then
    ln -s "$SKILLS_PATH" "$CLAUDE_DIR/skills"
    echo "✓ Created .claude/skills symlink -> $SKILLS_PATH"
fi

# Generate settings.json with hooks configuration
# Format: {"EventName": [{"matcher": "pattern", "hooks": [{"type": "command", "command": "..."}]}]}
# Matcher is a string (regex pattern), not an object
SETTINGS_FILE="$CLAUDE_DIR/settings.json"

if [ -d "$HOOKS_DIR" ] && [ "$(ls -A "$HOOKS_DIR" 2>/dev/null)" ]; then
    echo "Generating .claude/settings.json with hooks..."

    # Start building JSON
    HOOKS_JSON=""

    # Check for pre-compact hook (runs on both manual and auto compaction)
    if [ -f "$HOOKS_DIR/pre-compact.sh" ]; then
        HOOKS_JSON="$HOOKS_JSON\"PreCompact\": [{\"hooks\": [{\"type\": \"command\", \"command\": \"$HOOKS_CMD_PATH/pre-compact.sh\"}]}],"
    fi

    # Check for post-compact hook (SessionStart with matcher "compact")
    if [ -f "$HOOKS_DIR/post-compact.sh" ]; then
        HOOKS_JSON="$HOOKS_JSON\"SessionStart\": [{\"matcher\": \"compact\", \"hooks\": [{\"type\": \"command\", \"command\": \"$HOOKS_CMD_PATH/post-compact.sh\"}]}],"
    fi

    # Check for validate-bash hook (PreToolUse with matcher "Bash")
    if [ -f "$HOOKS_DIR/validate-bash.sh" ]; then
        HOOKS_JSON="$HOOKS_JSON\"PreToolUse\": [{\"matcher\": \"Bash\", \"hooks\": [{\"type\": \"command\", \"command\": \"$HOOKS_CMD_PATH/validate-bash.sh\"}]}],"
    fi

    # Remove trailing comma and wrap
    HOOKS_JSON="${HOOKS_JSON%,}"

    if [ -n "$HOOKS_JSON" ]; then
        cat > "$SETTINGS_FILE" << EOF
{
  "\$schema": "https://json.schemastore.org/claude-code-settings.json",
  "hooks": {
    $HOOKS_JSON
  }
}
EOF
        echo "✓ Created .claude/settings.json with hooks"
    fi
else
    # No hooks, create minimal settings
    if [ ! -f "$SETTINGS_FILE" ]; then
        cat > "$SETTINGS_FILE" << EOF
{
  "\$schema": "https://json.schemastore.org/claude-code-settings.json"
}
EOF
        echo "✓ Created .claude/settings.json (no hooks)"
    fi
fi

echo ""
echo "Claude Code setup complete!"
echo ""
echo "Files created:"
echo "  - CLAUDE.md -> $CONSTITUTION_PATH"
echo "  - .claude/agents/ -> $ROLES_PATH"
echo "  - .claude/skills/ -> $SKILLS_PATH"
if [ -f "$SETTINGS_FILE" ]; then
    echo "  - .claude/settings.json (hooks: $HOOKS_CMD_PATH)"
fi
