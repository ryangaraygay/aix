#!/bin/bash
# Generate Kiro CLI files from aix framework
# Usage: ./adapters/kiro-cli/generate.sh [tier]
#
# Supports two patterns:
# 1. Bootstrapped repos: files copied flat to .aix/
# 2. Submodule repos: tier structure at .aix/tiers/

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
AIX_DIR="$REPO_ROOT/.aix"
KIRO_DIR="$REPO_ROOT/.kiro"

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

echo "Generating Kiro CLI files for Tier $TIER..."

# Ensure .aix exists
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
    echo "Detected submodule structure"
else
    CONSTITUTION_PATH=".aix/constitution.md"
    SKILLS_PATH="../.aix/skills"
    echo "Detected bootstrapped structure"
fi

# Create AGENTS.md symlink (Kiro auto-loads this like CLAUDE.md)
if [ -L "$REPO_ROOT/AGENTS.md" ] || [ -f "$REPO_ROOT/AGENTS.md" ]; then
    rm "$REPO_ROOT/AGENTS.md"
fi
ln -s "$CONSTITUTION_PATH" "$REPO_ROOT/AGENTS.md"
echo "✓ Created AGENTS.md symlink -> $CONSTITUTION_PATH"

# Create .kiro directory
mkdir -p "$KIRO_DIR"

# Create skills symlink
if [ -L "$KIRO_DIR/skills" ] || [ -d "$KIRO_DIR/skills" ]; then
    rm -rf "$KIRO_DIR/skills"
fi
if [ -d "$AIX_DIR/skills" ] || [ -d "$AIX_DIR/$TIER_PATH/skills" ] 2>/dev/null; then
    ln -s "$SKILLS_PATH" "$KIRO_DIR/skills"
    echo "✓ Created .kiro/skills symlink -> $SKILLS_PATH"
fi

# Generate agent JSON files via aix-generate.py
if [ -f "$AIX_DIR/scripts/aix-generate.py" ]; then
    echo "Generating agent configurations..."
    python3 "$AIX_DIR/scripts/aix-generate.py" --adapter kiro 2>/dev/null || true
fi

echo ""
echo "Kiro CLI setup complete!"
echo ""
echo "Files created:"
echo "  - AGENTS.md -> $CONSTITUTION_PATH"
echo "  - .kiro/skills/ -> $SKILLS_PATH"
echo "  - .kiro/agents/*.json (generated roles)"
