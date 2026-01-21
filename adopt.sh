#!/bin/bash
# Adopt individual capabilities from higher tiers without full upgrade
# Usage: ~/Gitea/aix/adopt.sh <capability-name>
#        ~/Gitea/aix/adopt.sh --list

set -e

AIX_FRAMEWORK="${AIX_FRAMEWORK:-$HOME/Gitea/aix}"
REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
AIX_DIR="$REPO_ROOT/.aix"
TIER_FILE="$AIX_DIR/tier.yaml"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
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

# Capability registry - maps name to tier/type/path
# Format: "name:tier:type:subpath"
declare -a CAPABILITIES=(
    # Tier 1 - Sprout
    "test:1:skill:skills/test"
    "commit:1:skill:skills/commit"
    "tester:1:role:roles/tester.md"
    "docs:1:role:roles/docs.md"
    "quick-fix:1:workflow:workflows/quick-fix.md"
    "pre-commit:1:hook:hooks/pre-commit"

    # Tier 2 - Grow
    "agent-browser:2:skill:skills/agent-browser"
    "security-audit:2:skill:skills/security-audit"
    "quality-audit:2:skill:skills/quality-audit"
    "performance-audit:2:skill:skills/performance-audit"
    "wrap-up:2:skill:skills/wrap-up"
    "promote:2:skill:skills/promote"
    "pr-merged:2:skill:skills/pr-merged"
    "deploy:2:skill:skills/deploy"
    "triage:2:role:roles/triage.md"
    "orchestrator:2:role:roles/orchestrator.md"
    "feature:2:workflow:workflows/feature.md"
    "refactor:2:workflow:workflows/refactor.md"
    "ci-node:2:ci:ci/ci-node.yml"
    "ci-python:2:ci:ci/ci-python.yml"
    "ci-go:2:ci:ci/ci-go.yml"

    # Tier 3 - Scale
    "reflect:3:skill:skills/reflect"
    "accessibility-audit:3:skill:skills/accessibility-audit"
    "privacy-audit:3:skill:skills/privacy-audit"
    "cognitive-audit:3:skill:skills/cognitive-audit"
    "delight-audit:3:skill:skills/delight-audit"
    "resilience-audit:3:skill:skills/resilience-audit"
    "debug:3:role:roles/debug.md"
    "product-designer:3:role:roles/product-designer.md"
    "validate-bash:3:hook:hooks/validate-bash.sh"
    "worktree-setup:3:script:scripts/worktree-setup.sh"
    "worktree-cleanup:3:script:scripts/worktree-cleanup.sh"
)

# List available capabilities
list_capabilities() {
    echo -e "${CYAN}Available capabilities to adopt:${NC}"
    echo ""

    local last_tier=""
    local cap_name cap_tier cap_type cap_subpath
    for cap in "${CAPABILITIES[@]}"; do
        IFS=':' read -r cap_name cap_tier cap_type cap_subpath <<< "$cap"

        # Print tier header
        if [ "$cap_tier" != "$last_tier" ]; then
            case $cap_tier in
                1) echo -e "${YELLOW}Tier 1 (Sprout):${NC}" ;;
                2) echo -e "${YELLOW}Tier 2 (Grow):${NC}" ;;
                3) echo -e "${YELLOW}Tier 3 (Scale):${NC}" ;;
            esac
            last_tier="$cap_tier"
        fi

        # Check if already adopted
        local status=""
        if is_adopted "$cap_name"; then
            status="${GREEN}[adopted]${NC}"
        fi

        printf "  %-25s %-10s %s\n" "$cap_name" "($cap_type)" "$status"
    done

    echo ""
    echo "Usage: $0 <capability-name>"
    echo "Example: $0 agent-browser"
}

# Check if capability is already adopted
is_adopted() {
    local name="$1"
    local cap_name cap_tier cap_type cap_subpath

    # Check tier.yaml for adopted list
    if [ -f "$TIER_FILE" ] && grep -q "^  - $name$" "$TIER_FILE" 2>/dev/null; then
        return 0
    fi

    # Check if files exist
    for cap in "${CAPABILITIES[@]}"; do
        IFS=':' read -r cap_name cap_tier cap_type cap_subpath <<< "$cap"
        if [ "$cap_name" = "$name" ]; then
            case $cap_type in
                skill)
                    [ -d "$AIX_DIR/skills/$(basename "$cap_subpath")" ] && return 0
                    ;;
                role)
                    [ -f "$AIX_DIR/roles/$(basename "$cap_subpath")" ] && return 0
                    ;;
                workflow)
                    [ -f "$AIX_DIR/workflows/$(basename "$cap_subpath")" ] && return 0
                    ;;
                hook)
                    [ -f "$AIX_DIR/hooks/$(basename "$cap_subpath")" ] && return 0
                    ;;
                ci)
                    [ -f "$AIX_DIR/ci/$(basename "$cap_subpath")" ] && return 0
                    ;;
                script)
                    [ -f "$AIX_DIR/scripts/$(basename "$cap_subpath")" ] && return 0
                    ;;
            esac
        fi
    done

    return 1
}

# Find capability info
find_capability() {
    local name="$1"
    for cap in "${CAPABILITIES[@]}"; do
        IFS=':' read -r cap_name tier type subpath <<< "$cap"
        if [ "$cap_name" = "$name" ]; then
            echo "$tier:$type:$subpath"
            return 0
        fi
    done
    return 1
}

# Get tier name
get_tier_name() {
    case $1 in
        0) echo "seed" ;;
        1) echo "sprout" ;;
        2) echo "grow" ;;
        3) echo "scale" ;;
        *) echo "unknown" ;;
    esac
}

# Adopt a capability
adopt_capability() {
    local name="$1"

    # Find capability
    local info
    info=$(find_capability "$name") || {
        echo -e "${RED}Error: Unknown capability '$name'${NC}"
        echo "Run '$0 --list' to see available capabilities."
        exit 1
    }

    local cap_tier cap_type cap_subpath
    IFS=':' read -r cap_tier cap_type cap_subpath <<< "$info"
    local tier_name=$(get_tier_name "$cap_tier")
    local source_dir="$AIX_FRAMEWORK/tiers/$cap_tier-$tier_name"
    local source_path="$source_dir/$cap_subpath"

    # Check if already adopted
    if is_adopted "$name"; then
        echo -e "${YELLOW}Capability '$name' is already adopted.${NC}"
        exit 0
    fi

    echo -e "${CYAN}Adopting '$name' from Tier $cap_tier ($tier_name)...${NC}"
    echo "  Type: $cap_type"
    echo "  Source: $source_path"
    echo ""

    # Verify source exists
    if [ ! -e "$source_path" ]; then
        echo -e "${RED}Error: Source not found at $source_path${NC}"
        exit 1
    fi

    # Copy based on type
    case $cap_type in
        skill)
            local skill_name=$(basename "$cap_subpath")
            local dest_dir="$AIX_DIR/skills/$skill_name"
            echo "  Copying skill to $dest_dir..."
            mkdir -p "$dest_dir"
            cp -r "$source_path/"* "$dest_dir/"
            echo -e "  ${GREEN}✓ Skill copied${NC}"

            # Symlink is already set up by bootstrap (.claude/skills -> .aix/skills)
            echo -e "  ${GREEN}✓ Skill available via .claude/skills/${NC}"
            ;;

        role)
            local role_file=$(basename "$cap_subpath")
            local dest_file="$AIX_DIR/roles/$role_file"
            echo "  Copying role to $dest_file..."
            cp "$source_path" "$dest_file"
            echo -e "  ${GREEN}✓ Role copied${NC}"

            # Symlink is already set up by bootstrap (.claude/agents -> .aix/roles)
            echo -e "  ${GREEN}✓ Role available via .claude/agents/${NC}"
            ;;

        workflow)
            local workflow_file=$(basename "$cap_subpath")
            local dest_file="$AIX_DIR/workflows/$workflow_file"
            echo "  Copying workflow to $dest_file..."
            cp "$source_path" "$dest_file"
            echo -e "  ${GREEN}✓ Workflow copied${NC}"
            ;;

        hook)
            local hook_file=$(basename "$cap_subpath")
            local dest_file="$AIX_DIR/hooks/$hook_file"
            echo "  Copying hook to $dest_file..."
            mkdir -p "$AIX_DIR/hooks"
            cp "$source_path" "$dest_file"
            chmod +x "$dest_file"
            echo -e "  ${GREEN}✓ Hook copied${NC}"
            echo -e "  ${YELLOW}Note: Ensure .claude/settings.json references hooks${NC}"
            ;;

        ci)
            local ci_file=$(basename "$cap_subpath")
            local dest_file="$AIX_DIR/ci/$ci_file"
            echo "  Copying CI template to $dest_file..."
            mkdir -p "$AIX_DIR/ci"
            cp "$source_path" "$dest_file"
            echo -e "  ${GREEN}✓ CI template copied${NC}"
            echo -e "  ${YELLOW}Note: Copy to .github/workflows/ to activate${NC}"
            ;;

        script)
            local script_file=$(basename "$cap_subpath")
            local dest_file="$AIX_DIR/scripts/$script_file"
            echo "  Copying script to $dest_file..."
            mkdir -p "$AIX_DIR/scripts"
            cp "$source_path" "$dest_file"
            chmod +x "$dest_file"
            echo -e "  ${GREEN}✓ Script copied${NC}"
            ;;
    esac

    # Update tier.yaml to track adopted capabilities
    echo ""
    echo "  Updating tier.yaml..."

    # Add adopted section if not present
    if ! grep -q "^adopted:" "$TIER_FILE" 2>/dev/null; then
        echo "" >> "$TIER_FILE"
        echo "adopted:" >> "$TIER_FILE"
    fi

    # Add capability to adopted list
    echo "  - $name" >> "$TIER_FILE"
    echo -e "  ${GREEN}✓ Tracked in tier.yaml${NC}"

    echo ""
    echo -e "${GREEN}✅ Successfully adopted '$name'${NC}"

    # Type-specific post-install notes
    case $cap_type in
        skill)
            echo ""
            echo "To use this skill:"
            echo "  /$name"
            ;;
        role)
            echo ""
            echo "This role is now available for Task tool delegation:"
            echo "  subagent_type: \"$(basename "$cap_subpath" .md)\""
            ;;
    esac
}

# Main
case "${1:-}" in
    --list|-l|list)
        list_capabilities
        ;;
    --help|-h|help|"")
        echo "Usage: $0 <capability-name>"
        echo "       $0 --list"
        echo ""
        echo "Adopt individual capabilities from higher tiers without full upgrade."
        echo ""
        echo "Options:"
        echo "  --list, -l    List all available capabilities"
        echo "  --help, -h    Show this help"
        echo ""
        echo "Example:"
        echo "  $0 agent-browser    # Adopt browser automation skill"
        echo "  $0 tester           # Adopt tester role"
        ;;
    *)
        adopt_capability "$1"
        ;;
esac
