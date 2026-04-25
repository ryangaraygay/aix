#!/bin/bash
# Generate Cursor files from aix framework
# Usage: ./adapters/cursor/generate.sh [tier] [--enable-hooks]
#
# Supports two patterns:
# 1. Bootstrapped repos: files copied flat to .aix/
# 2. Submodule repos: tier structure at .aix/tiers/

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
AIX_DIR="$REPO_ROOT/.aix"
CURSOR_DIR="$REPO_ROOT/.cursor"

TIER="${1:-0}"
ENABLE_HOOKS=false
for arg in "$@"; do
    [ "$arg" = "--enable-hooks" ] && ENABLE_HOOKS=true
done

get_tier_name() {
    case $1 in
        0) echo "seed" ;;
        1) echo "sprout" ;;
        2) echo "grow" ;;
        3) echo "scale" ;;
        *) echo "seed" ;;
    esac
}

echo "Generating Cursor files for Tier $TIER..."

if [ ! -d "$AIX_DIR" ]; then
    echo "Error: .aix directory not found. Run bootstrap.sh first."
    exit 1
fi

# Detect structure: submodule (has tiers/) vs bootstrapped (flat)
if [ -d "$AIX_DIR/tiers" ]; then
    TIER_NAME=$(get_tier_name $TIER)
    TIER_PATH="tiers/$TIER-$TIER_NAME"
    CONSTITUTION_PATH=".aix/$TIER_PATH/constitution.md"
    SKILLS_PATH="../.aix/$TIER_PATH/skills"
    WORKFLOWS_PATH="../../.aix/$TIER_PATH/workflows"
    HOOKS_DIR="$AIX_DIR/$TIER_PATH/hooks"
    HOOKS_CMD_PATH="./.aix/$TIER_PATH/hooks"
    echo "Detected submodule structure"
else
    TIER_PATH=""
    CONSTITUTION_PATH=".aix/constitution.md"
    SKILLS_PATH="../.aix/skills"
    WORKFLOWS_PATH="../../.aix/workflows"
    HOOKS_DIR="$AIX_DIR/hooks"
    HOOKS_CMD_PATH="./.aix/hooks"
    echo "Detected bootstrapped structure"
fi

# AGENTS.md symlink (idempotent; warn if exists with different target)
AGENTS_TARGET="$REPO_ROOT/AGENTS.md"
if [ -L "$AGENTS_TARGET" ]; then
    CURRENT=$(readlink "$AGENTS_TARGET")
    if [ "$CURRENT" != "$CONSTITUTION_PATH" ]; then
        echo "⚠ AGENTS.md exists pointing to $CURRENT (expected $CONSTITUTION_PATH); leaving as-is"
    else
        echo "✓ AGENTS.md symlink already correct"
    fi
elif [ -f "$AGENTS_TARGET" ]; then
    echo "⚠ AGENTS.md is a regular file (not a symlink); leaving as-is"
else
    ln -s "$CONSTITUTION_PATH" "$AGENTS_TARGET"
    echo "✓ Created AGENTS.md symlink -> $CONSTITUTION_PATH"
fi

mkdir -p "$CURSOR_DIR/agents"

# Skills symlink
if [ -L "$CURSOR_DIR/skills" ] || [ -d "$CURSOR_DIR/skills" ]; then
    rm -rf "$CURSOR_DIR/skills"
fi
if [ -d "$AIX_DIR/skills" ] || [ -n "$TIER_PATH" -a -d "$AIX_DIR/$TIER_PATH/skills" ]; then
    ln -s "$SKILLS_PATH" "$CURSOR_DIR/skills"
    echo "✓ Created .cursor/skills symlink -> $SKILLS_PATH"
fi

# Workflows symlink (under .cursor/rules so Cursor sees workflows as @-invokable rules)
# .cursor/rules dir is created on demand here, only when there are workflows to expose.
if [ -d "$AIX_DIR/workflows" ] || [ -n "$TIER_PATH" -a -d "$AIX_DIR/$TIER_PATH/workflows" ]; then
    mkdir -p "$CURSOR_DIR/rules"
    if [ -L "$CURSOR_DIR/rules/workflows" ] || [ -d "$CURSOR_DIR/rules/workflows" ]; then
        rm -rf "$CURSOR_DIR/rules/workflows"
    fi
    ln -s "$WORKFLOWS_PATH" "$CURSOR_DIR/rules/workflows"
    echo "✓ Created .cursor/rules/workflows symlink -> $WORKFLOWS_PATH"
fi

# Subagents — emitted by aix-generate.py.
# Unlike the claude-code adapter (which symlinks roles directly because the
# canonical aix frontmatter shape matches Claude's), Cursor needs frontmatter
# transformation (name/description/model/readonly/is_background) so we always
# run the generator. Errors must propagate — a silent failure here yields an
# empty .cursor/agents/ that looks fine but breaks the install.
#
# Note: bootstrap.sh also invokes aix-generate.py (line ~235) with stderr
# suppressed; this second invocation is the authoritative one. Re-runs are
# cheap because the generator hash-skips unchanged files.
GENERATOR="$AIX_DIR/scripts/aix-generate.py"
if [ -f "$GENERATOR" ]; then
    python3 "$GENERATOR" --adapter cursor --repo-root "$REPO_ROOT"
else
    echo "Error: aix-generate.py not found at $GENERATOR" >&2
    exit 1
fi

# Hooks (opt-in). Only the preCompact hook is wired today — sessionStart with
# matcher: "compact" (claude's pattern) needs Cursor matcher-value confirmation
# before we can emit it safely. See docs/ROADMAP.md for the deferred work.
HOOKS_FILE="$CURSOR_DIR/hooks.json"
if [ "$ENABLE_HOOKS" = true ] && [ -d "$HOOKS_DIR" ] && [ -f "$HOOKS_DIR/pre-compact.sh" ]; then
    cat > "$HOOKS_FILE" << EOF
{
  "version": 1,
  "hooks": {
    "preCompact": [
      {
        "command": "$HOOKS_CMD_PATH/pre-compact.sh",
        "type": "command"
      }
    ]
  }
}
EOF
    echo "✓ Created .cursor/hooks.json (opt-in)"
fi

# MCP pass-through
if [ -f "$AIX_DIR/mcp.json" ]; then
    cp "$AIX_DIR/mcp.json" "$CURSOR_DIR/mcp.json"
    echo "✓ Copied .aix/mcp.json -> .cursor/mcp.json"
fi

echo ""
echo "Cursor setup complete!"
echo ""
echo "Files created:"
echo "  - AGENTS.md -> $CONSTITUTION_PATH"
echo "  - .cursor/agents/ (subagents)"
echo "  - .cursor/skills -> $SKILLS_PATH"
echo "  - .cursor/rules/workflows -> $WORKFLOWS_PATH"
if [ -f "$HOOKS_FILE" ]; then
    echo "  - .cursor/hooks.json (hooks: $HOOKS_CMD_PATH)"
fi
if [ -f "$CURSOR_DIR/mcp.json" ]; then
    echo "  - .cursor/mcp.json"
fi
