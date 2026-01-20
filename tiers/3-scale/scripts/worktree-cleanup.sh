#!/bin/bash
# Git worktree cleanup script
#
# Usage: ./.aix/scripts/worktree-cleanup.sh <feature-name>
#
# Removes a worktree and optionally deletes the branch.

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Help
if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
    echo "Usage: ./.aix/scripts/worktree-cleanup.sh <feature-name>"
    echo ""
    echo "Removes a worktree created by worktree-setup.sh:"
    echo "  - Removes worktree at ../<feature-name>"
    echo "  - Optionally deletes branch feat/<feature-name>"
    echo ""
    echo "Options:"
    echo "  --keep-branch    Don't delete the branch after cleanup"
    echo ""
    echo "Examples:"
    echo "  ./.aix/scripts/worktree-cleanup.sh add-search"
    echo "  ./.aix/scripts/worktree-cleanup.sh add-search --keep-branch"
    exit 0
fi

# Parse arguments
KEEP_BRANCH=false
FEATURE_NAME=""

for arg in "$@"; do
    case $arg in
        --keep-branch)
            KEEP_BRANCH=true
            ;;
        -*)
            echo -e "${RED}Unknown option: $arg${NC}"
            exit 1
            ;;
        *)
            FEATURE_NAME="$arg"
            ;;
    esac
done

# Require feature name
if [ -z "$FEATURE_NAME" ]; then
    echo -e "${RED}Error: Feature name required${NC}"
    echo "Usage: ./.aix/scripts/worktree-cleanup.sh <feature-name>"
    exit 1
fi

# Verify we're in a git repository
if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    echo -e "${RED}Error: Not inside a git repository${NC}"
    exit 1
fi

# Must be in main worktree
MAIN_REPO=$(git worktree list --porcelain | grep -m1 '^worktree ' | cut -d' ' -f2)
CURRENT_DIR=$(pwd)
if [ "$CURRENT_DIR" != "$MAIN_REPO" ]; then
    echo -e "${RED}Error: Must run from main worktree${NC}"
    echo ""
    echo "You are in: $CURRENT_DIR"
    echo "Main repo:  $MAIN_REPO"
    exit 1
fi

SANITIZED_NAME=$(echo "$FEATURE_NAME" | tr -cd '[:alnum:]_-')
WORKTREE_PATH="../$SANITIZED_NAME"
BRANCH_NAME="feat/$SANITIZED_NAME"

# Check if worktree exists
if [ ! -d "$WORKTREE_PATH" ]; then
    echo -e "${YELLOW}Warning: Worktree directory not found: $WORKTREE_PATH${NC}"
else
    echo "Removing worktree at $WORKTREE_PATH..."

    # Check for uncommitted changes
    if [ -d "$WORKTREE_PATH/.git" ] || [ -f "$WORKTREE_PATH/.git" ]; then
        UNCOMMITTED=$(cd "$WORKTREE_PATH" && git status --porcelain 2>/dev/null | wc -l | tr -d ' ')
        if [ "$UNCOMMITTED" -gt 0 ]; then
            echo -e "${YELLOW}Warning: $UNCOMMITTED uncommitted changes in worktree${NC}"
            read -p "Continue anyway? (y/N) " -n 1 -r
            echo
            if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                echo "Aborted."
                exit 1
            fi
        fi
    fi

    # Remove worktree
    git worktree remove "$WORKTREE_PATH" --force
    echo -e "${GREEN}✓ Worktree removed${NC}"
fi

# Optionally delete branch
if [ "$KEEP_BRANCH" = false ]; then
    if git show-ref --verify --quiet "refs/heads/$BRANCH_NAME"; then
        echo "Deleting branch $BRANCH_NAME..."
        git branch -D "$BRANCH_NAME"
        echo -e "${GREEN}✓ Branch deleted${NC}"
    else
        echo -e "${YELLOW}Branch $BRANCH_NAME not found (may have been merged/deleted)${NC}"
    fi
else
    echo -e "${YELLOW}Keeping branch $BRANCH_NAME as requested${NC}"
fi

# Prune worktree references
git worktree prune

echo ""
echo -e "${GREEN}✅ Cleanup complete${NC}"
