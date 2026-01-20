#!/bin/bash
# Git worktree setup script
#
# Usage: ./.aix/scripts/worktree-setup.sh <feature-name>
#
# Creates a worktree for parallel development with isolated branch.

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Help
if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
    echo "Usage: ./.aix/scripts/worktree-setup.sh <feature-name>"
    echo ""
    echo "Creates a git worktree for parallel development:"
    echo "  - Worktree at ../<feature-name>"
    echo "  - Branch: feat/<feature-name> from origin/dev (or origin/main)"
    echo ""
    echo "Examples:"
    echo "  ./.aix/scripts/worktree-setup.sh add-search"
    echo "  ./.aix/scripts/worktree-setup.sh fix-login-bug"
    exit 0
fi

# Require feature name
if [ -z "${1:-}" ]; then
    echo -e "${RED}Error: Feature name required${NC}"
    echo "Usage: ./.aix/scripts/worktree-setup.sh <feature-name>"
    exit 1
fi

FEATURE_NAME="$1"

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

# Sanitize feature name
SANITIZED_NAME=$(echo "$FEATURE_NAME" | tr -cd '[:alnum:]_-')
if [ -z "$SANITIZED_NAME" ]; then
    echo -e "${RED}Error: Feature name contains no valid characters${NC}"
    exit 1
fi

WORKTREE_PATH="../$SANITIZED_NAME"
BRANCH_NAME="feat/$SANITIZED_NAME"

# Check if worktree already exists
if [ -d "$WORKTREE_PATH" ]; then
    echo -e "${RED}Error: Directory already exists: $WORKTREE_PATH${NC}"
    exit 1
fi

# Check if branch already exists
if git show-ref --verify --quiet "refs/heads/$BRANCH_NAME"; then
    echo -e "${RED}Error: Branch already exists: $BRANCH_NAME${NC}"
    echo "Delete it first with: git branch -D $BRANCH_NAME"
    exit 1
fi

# Determine base branch (prefer dev, fall back to main)
git fetch origin
if git show-ref --verify --quiet "refs/remotes/origin/dev"; then
    BASE_BRANCH="origin/dev"
elif git show-ref --verify --quiet "refs/remotes/origin/main"; then
    BASE_BRANCH="origin/main"
else
    echo -e "${RED}Error: Neither origin/dev nor origin/main found${NC}"
    exit 1
fi

echo "Creating worktree..."
echo "  Path: $WORKTREE_PATH"
echo "  Branch: $BRANCH_NAME"
echo "  Base: $BASE_BRANCH"
echo ""

# Create worktree
git worktree add -b "$BRANCH_NAME" "$WORKTREE_PATH" "$BASE_BRANCH"

echo ""
echo -e "${GREEN}✅ Worktree created successfully${NC}"
echo ""
echo "Next steps:"
echo "  cd $WORKTREE_PATH"
echo "  # Install dependencies (npm install, pip install, etc.)"
echo "  # Start working on your feature"
echo ""
echo "When done:"
echo "  # From main repo:"
echo "  ./.aix/scripts/worktree-cleanup.sh $SANITIZED_NAME"
