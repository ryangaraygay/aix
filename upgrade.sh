#!/bin/bash
# Upgrade aix to a higher tier
# Usage: ~/Gitea/aix/upgrade.sh [target-tier]

set -e

AIX_FRAMEWORK="${AIX_FRAMEWORK:-$HOME/Gitea/aix}"
REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
AIX_DIR="$REPO_ROOT/.aix"
TIER_FILE="$AIX_DIR/tier.yaml"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Check if aix is initialized
if [ ! -d "$AIX_DIR" ]; then
    echo -e "${RED}Error: aix not initialized. Run bootstrap.sh first.${NC}"
    exit 1
fi

# Get current tier
if [ -f "$TIER_FILE" ]; then
    CURRENT_TIER=$(grep "^tier:" "$TIER_FILE" | cut -d' ' -f2)
else
    CURRENT_TIER=0
fi

# Determine target tier
TARGET_TIER="${1:-$((CURRENT_TIER + 1))}"

echo "Current tier: $CURRENT_TIER"
echo "Target tier: $TARGET_TIER"
echo ""

if [ "$TARGET_TIER" -le "$CURRENT_TIER" ]; then
    echo -e "${YELLOW}Already at tier $CURRENT_TIER. Nothing to upgrade.${NC}"
    exit 0
fi

# Map tier numbers to names
get_tier_name() {
    case $1 in
        0) echo "seed" ;;
        1) echo "sprout" ;;
        2) echo "grow" ;;
        3) echo "scale" ;;
        *) echo "unknown" ;;
    esac
}

# Upgrade one tier at a time
for ((tier = CURRENT_TIER + 1; tier <= TARGET_TIER; tier++)); do
    TIER_NAME=$(get_tier_name $tier)
    TIER_DIR="$AIX_FRAMEWORK/tiers/$tier-$TIER_NAME"

    if [ ! -d "$TIER_DIR" ]; then
        echo -e "${RED}Error: Tier $tier ($TIER_NAME) not found at $TIER_DIR${NC}"
        exit 1
    fi

    echo "Upgrading to Tier $tier ($TIER_NAME)..."

    # Copy roles
    if [ -d "$TIER_DIR/roles" ]; then
        echo "  Adding roles..."
        cp -n "$TIER_DIR/roles/"*.md "$AIX_DIR/roles/" 2>/dev/null || true
    fi

    # Copy workflows
    if [ -d "$TIER_DIR/workflows" ]; then
        echo "  Adding workflows..."
        cp -n "$TIER_DIR/workflows/"*.md "$AIX_DIR/workflows/" 2>/dev/null || true
    fi

    # Copy skills
    if [ -d "$TIER_DIR/skills" ]; then
        echo "  Adding skills..."
        for skill_dir in "$TIER_DIR/skills/"*/; do
            if [ -d "$skill_dir" ]; then
                skill_name=$(basename "$skill_dir")
                mkdir -p "$AIX_DIR/skills/$skill_name"
                cp -r "$skill_dir"* "$AIX_DIR/skills/$skill_name/"
            fi
        done
    fi

    # Copy hooks
    if [ -d "$TIER_DIR/hooks" ]; then
        echo "  Adding hooks..."
        mkdir -p "$REPO_ROOT/.husky"
        for hook in "$TIER_DIR/hooks/"*; do
            if [ -f "$hook" ]; then
                hook_name=$(basename "$hook")
                cp "$hook" "$REPO_ROOT/.husky/$hook_name"
                chmod +x "$REPO_ROOT/.husky/$hook_name"
            fi
        done
    fi

    # Copy CI templates (to .aix/ci, user copies to .github/workflows)
    if [ -d "$TIER_DIR/ci" ]; then
        echo "  Adding CI templates..."
        mkdir -p "$AIX_DIR/ci"
        cp -r "$TIER_DIR/ci/"* "$AIX_DIR/ci/"
        echo -e "  ${YELLOW}Note: Copy CI templates from .aix/ci/ to .github/workflows/${NC}"
    fi

    echo -e "  ${GREEN}Tier $tier complete${NC}"
done

# Update tier.yaml
cat > "$TIER_FILE" << EOF
tier: $TARGET_TIER
name: $(get_tier_name $TARGET_TIER)
upgraded_at: $(date -I)
history:
$(if [ -f "$TIER_FILE.bak" ]; then grep -A100 "^history:" "$TIER_FILE.bak" | tail -n +2; fi)
  - tier: $TARGET_TIER
    date: $(date -I)
    reason: upgraded via upgrade.sh
EOF

# Regenerate Claude Code files
echo ""
echo "Updating Claude Code integration..."
"$AIX_FRAMEWORK/adapters/claude-code/generate.sh" "$TARGET_TIER"

echo ""
echo -e "${GREEN}✅ Upgraded to Tier $TARGET_TIER ($(get_tier_name $TARGET_TIER))${NC}"
echo ""
echo "New files added to your project. Run 'git status' to see changes."
