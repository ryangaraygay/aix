#!/bin/bash
# Upgrade aix to a higher tier
# Usage: ~/tools/aix/upgrade.sh [target-tier]

set -e

AIX_FRAMEWORK="${AIX_FRAMEWORK:-$HOME/tools/aix}"
REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
AIX_DIR="$REPO_ROOT/.aix"
TIER_FILE="$AIX_DIR/tier.yaml"

if git -C "$AIX_FRAMEWORK" rev-parse --git-dir > /dev/null 2>&1; then
    AIX_VERSION="$(git -C "$AIX_FRAMEWORK" rev-parse --short HEAD)"
else
    AIX_VERSION="unknown"
fi
MANIFEST_TOOL="$AIX_FRAMEWORK/scripts/aix-manifest.py"
MANIFEST_FILE="$AIX_DIR/manifest.json"

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

copy_docs_recursive() {
    local src_dir="$1"
    local dest_dir="$2"
    if [ ! -d "$src_dir" ]; then
        return 0
    fi
    find "$src_dir" -type f | while read -r src; do
        local rel="${src#$src_dir/}"
        local dest="$dest_dir/$rel"
        if [ ! -f "$dest" ]; then
            mkdir -p "$(dirname "$dest")"
            cp "$src" "$dest"
        else
            echo -e "    ${YELLOW}Skipped $rel (already exists)${NC}"
        fi
    done
}

init_manifest() {
    if [ -f "$MANIFEST_TOOL" ]; then
        python3 "$MANIFEST_TOOL" init \
            --manifest "$MANIFEST_FILE" \
            --aix-version "$AIX_VERSION"
    fi
}

record_manifest_dir() {
    local source_root="$1"
    local dest_root="$2"
    local capability="$3"
    if [ -f "$MANIFEST_TOOL" ]; then
        python3 "$MANIFEST_TOOL" record-dir \
            --manifest "$MANIFEST_FILE" \
            --repo-root "$REPO_ROOT" \
            --framework-root "$AIX_FRAMEWORK" \
            --source-root "$source_root" \
            --dest-root "$dest_root" \
            --capability "$capability" \
            --aix-version "$AIX_VERSION"
    fi
}

record_manifest_file() {
    local source_path="$1"
    local dest_path="$2"
    local capability="$3"
    if [ -f "$MANIFEST_TOOL" ]; then
        python3 "$MANIFEST_TOOL" record \
            --manifest "$MANIFEST_FILE" \
            --repo-root "$REPO_ROOT" \
            --framework-root "$AIX_FRAMEWORK" \
            --source "$source_path" \
            --dest "$dest_path" \
            --capability "$capability" \
            --aix-version "$AIX_VERSION"
    fi
}

init_manifest

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
        record_manifest_dir "$TIER_DIR/roles" "$AIX_DIR/roles" "tier-$tier-$TIER_NAME"
    fi

    # Copy workflows
    if [ -d "$TIER_DIR/workflows" ]; then
        echo "  Adding workflows..."
        cp -n "$TIER_DIR/workflows/"*.md "$AIX_DIR/workflows/" 2>/dev/null || true
        record_manifest_dir "$TIER_DIR/workflows" "$AIX_DIR/workflows" "tier-$tier-$TIER_NAME"
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
        record_manifest_dir "$TIER_DIR/skills" "$AIX_DIR/skills" "tier-$tier-$TIER_NAME"
    fi

    # Copy git hooks (pre-commit, commit-msg, etc.) to .husky
    if [ -d "$TIER_DIR/hooks" ]; then
        # Check if these are git hooks or Claude Code hooks
        if ls "$TIER_DIR/hooks/"*compact* 1>/dev/null 2>&1; then
            # Claude Code hooks (compaction) go to .aix/hooks/
            echo "  Adding Claude Code hooks..."
            mkdir -p "$AIX_DIR/hooks"
            for hook in "$TIER_DIR/hooks/"*; do
                if [ -f "$hook" ]; then
                    hook_name=$(basename "$hook")
                    cp "$hook" "$AIX_DIR/hooks/$hook_name"
                    chmod +x "$AIX_DIR/hooks/$hook_name"
                fi
            done
            record_manifest_dir "$TIER_DIR/hooks" "$AIX_DIR/hooks" "tier-$tier-$TIER_NAME"
            echo -e "  ${YELLOW}Note: Configure hooks in .claude/settings.json${NC}"
        else
            # Git hooks go to .husky
            echo "  Adding git hooks..."
            mkdir -p "$REPO_ROOT/.husky"
            for hook in "$TIER_DIR/hooks/"*; do
                if [ -f "$hook" ]; then
                    hook_name=$(basename "$hook")
                    cp "$hook" "$REPO_ROOT/.husky/$hook_name"
                    chmod +x "$REPO_ROOT/.husky/$hook_name"
                fi
            done
        fi
    fi

    # Copy scripts to .aix/scripts/
    if [ -d "$TIER_DIR/scripts" ]; then
        echo "  Adding scripts..."
        mkdir -p "$AIX_DIR/scripts"
        for script in "$TIER_DIR/scripts/"*; do
            if [ -f "$script" ]; then
                script_name=$(basename "$script")
                cp "$script" "$AIX_DIR/scripts/$script_name"
                chmod +x "$AIX_DIR/scripts/$script_name"
            fi
        done
        record_manifest_dir "$TIER_DIR/scripts" "$AIX_DIR/scripts" "tier-$tier-$TIER_NAME"
    fi

    # Copy doc templates to docs/
    if [ -d "$TIER_DIR/docs" ]; then
        echo "  Adding doc templates..."
        mkdir -p "$REPO_ROOT/docs"
        copy_docs_recursive "$TIER_DIR/docs" "$REPO_ROOT/docs"
        record_manifest_dir "$TIER_DIR/docs" "$REPO_ROOT/docs" "tier-$tier-$TIER_NAME"
    fi

    # Select and copy CI template based on tech-stack.md
    if [ -d "$TIER_DIR/ci" ]; then
        echo "  Selecting CI template..."
        mkdir -p "$AIX_DIR/ci"

        # Detect runtime from tech-stack.md
        TECH_STACK_FILE="$REPO_ROOT/docs/tech-stack.md"
        CI_TEMPLATE=""

        if [ -f "$TECH_STACK_FILE" ]; then
            # Parse Runtime row from tech-stack.md
            RUNTIME=$(grep -i "| Runtime" "$TECH_STACK_FILE" | head -1)

            if echo "$RUNTIME" | grep -qi "node\|javascript\|typescript"; then
                CI_TEMPLATE="ci-node.yml"
            elif echo "$RUNTIME" | grep -qi "python"; then
                CI_TEMPLATE="ci-python.yml"
            elif echo "$RUNTIME" | grep -qi "go\|golang"; then
                CI_TEMPLATE="ci-go.yml"
            fi
        fi

        if [ -n "$CI_TEMPLATE" ] && [ -f "$TIER_DIR/ci/$CI_TEMPLATE" ]; then
            cp "$TIER_DIR/ci/$CI_TEMPLATE" "$AIX_DIR/ci/ci.yml"
            record_manifest_file "$TIER_DIR/ci/$CI_TEMPLATE" "$AIX_DIR/ci/ci.yml" "tier-$tier-$TIER_NAME"
            echo -e "  ${GREEN}Selected $CI_TEMPLATE based on tech-stack.md${NC}"
        else
            # Fallback: copy all templates, let user choose
            cp -r "$TIER_DIR/ci/"* "$AIX_DIR/ci/"
            record_manifest_dir "$TIER_DIR/ci" "$AIX_DIR/ci" "tier-$tier-$TIER_NAME"
            echo -e "  ${YELLOW}Could not detect runtime. All CI templates copied to .aix/ci/${NC}"
        fi

        echo -e "  ${YELLOW}Note: Copy .aix/ci/ci.yml to .github/workflows/ci.yml${NC}"
    fi

    echo -e "  ${GREEN}Tier $tier complete${NC}"
done

# Sync core skills (framework-level)
if [ -d "$AIX_FRAMEWORK/skills" ]; then
    echo "Syncing core skills..."
    mkdir -p "$AIX_DIR/skills"
    for skill_dir in "$AIX_FRAMEWORK/skills/"*/; do
        if [ -d "$skill_dir" ]; then
            skill_name=$(basename "$skill_dir")
            if [ ! -d "$AIX_DIR/skills/$skill_name" ]; then
                mkdir -p "$AIX_DIR/skills/$skill_name"
                cp -r "$skill_dir"* "$AIX_DIR/skills/$skill_name/"
            fi
        fi
    done
    record_manifest_dir "$AIX_FRAMEWORK/skills" "$AIX_DIR/skills" "core-skills"
fi

# Sync core scripts (framework-level)
if [ -d "$AIX_FRAMEWORK/scripts" ]; then
    echo "Syncing core scripts..."
    mkdir -p "$AIX_DIR/scripts"
    for script in "$AIX_FRAMEWORK/scripts/"*; do
        if [ -f "$script" ]; then
            script_name=$(basename "$script")
            if [ ! -f "$AIX_DIR/scripts/$script_name" ]; then
                cp "$script" "$AIX_DIR/scripts/$script_name"
                chmod +x "$AIX_DIR/scripts/$script_name"
            fi
        fi
    done
    record_manifest_dir "$AIX_FRAMEWORK/scripts" "$AIX_DIR/scripts" "core-scripts"
fi

if [ -f "$MANIFEST_TOOL" ]; then
    python3 "$MANIFEST_TOOL" touch \
        --manifest "$MANIFEST_FILE" \
        --aix-version "$AIX_VERSION"
fi

# Update tier.yaml
cat > "$TIER_FILE" << EOF
tier: $TARGET_TIER
name: $(get_tier_name $TARGET_TIER)
aix_version: $AIX_VERSION
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
