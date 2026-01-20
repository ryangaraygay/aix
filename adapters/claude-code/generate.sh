#!/bin/bash
# Generate Claude Code files from aix framework
# Usage: ./aix/adapters/claude-code/generate.sh [tier]

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
AIX_DIR="$REPO_ROOT/.aix"
CLAUDE_DIR="$REPO_ROOT/.claude"

# Default tier
TIER="${1:-0}"

echo "Generating Claude Code files for Tier $TIER..."

# Ensure .aix exists
if [ ! -d "$AIX_DIR" ]; then
    echo "Error: .aix directory not found. Run /aix-init first."
    exit 1
fi

# Create CLAUDE.md symlink
if [ -L "$REPO_ROOT/CLAUDE.md" ] || [ -f "$REPO_ROOT/CLAUDE.md" ]; then
    rm "$REPO_ROOT/CLAUDE.md"
fi
ln -s .aix/constitution.md "$REPO_ROOT/CLAUDE.md"
echo "✓ Created CLAUDE.md symlink"

# Create .claude directory
mkdir -p "$CLAUDE_DIR"

# Create agents symlink (Claude Code expects .claude/agents/ directory)
if [ -L "$CLAUDE_DIR/agents" ] || [ -d "$CLAUDE_DIR/agents" ]; then
    rm -rf "$CLAUDE_DIR/agents"
fi
if [ -d "$AIX_DIR/roles" ]; then
    ln -s ../.aix/roles "$CLAUDE_DIR/agents"
    echo "✓ Created .claude/agents symlink -> .aix/roles"
fi

# Create skills symlink
if [ -L "$CLAUDE_DIR/skills" ] || [ -d "$CLAUDE_DIR/skills" ]; then
    rm -rf "$CLAUDE_DIR/skills"
fi
if [ -d "$AIX_DIR/skills" ]; then
    ln -s ../.aix/skills "$CLAUDE_DIR/skills"
    echo "✓ Created .claude/skills symlink -> .aix/skills"
fi

echo ""
echo "Claude Code setup complete!"
echo ""
echo "Files created:"
echo "  - CLAUDE.md -> .aix/constitution.md"
echo "  - .claude/agents/ -> .aix/roles/"
echo "  - .claude/skills/ -> .aix/skills/"
