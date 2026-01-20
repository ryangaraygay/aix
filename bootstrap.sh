#!/bin/bash
# Bootstrap aix in a new project
# Usage: curl -fsSL https://raw.githubusercontent.com/ryangaraygay/aix/main/bootstrap.sh | bash
#    or: ~/Gitea/aix/bootstrap.sh

set -e

# Where is the aix framework?
AIX_FRAMEWORK="${AIX_FRAMEWORK:-$HOME/Gitea/aix}"

# Detect if we're in a git repo
if git rev-parse --git-dir > /dev/null 2>&1; then
    REPO_ROOT="$(git rev-parse --show-toplevel)"
else
    REPO_ROOT="$(pwd)"
    echo "Not a git repo. Initializing git..."
    git init
fi

echo "Bootstrapping aix in: $REPO_ROOT"
echo "Using framework from: $AIX_FRAMEWORK"
echo ""

# Check if already initialized
if [ -d "$REPO_ROOT/.aix" ]; then
    echo "aix already initialized. Run /aix-init upgrade to upgrade."
    exit 0
fi

# Check framework exists
if [ ! -d "$AIX_FRAMEWORK/tiers/0-seed" ]; then
    echo "Error: aix framework not found at $AIX_FRAMEWORK"
    echo "Set AIX_FRAMEWORK environment variable to the aix repo location."
    exit 1
fi

# Create directories
mkdir -p "$REPO_ROOT/.aix/skills"
mkdir -p "$REPO_ROOT/.claude"
mkdir -p "$REPO_ROOT/docs"

# Copy Tier 0 files
echo "Copying Tier 0 (Seed) files..."
cp -r "$AIX_FRAMEWORK/tiers/0-seed/"* "$REPO_ROOT/.aix/"

# Copy doc templates
echo "Copying document templates..."
cp "$AIX_FRAMEWORK/docs/templates/"*.md "$REPO_ROOT/docs/"

# Copy aix-init skill (for upgrades)
echo "Copying aix-init skill..."
cp -r "$AIX_FRAMEWORK/skills/aix-init" "$REPO_ROOT/.aix/skills/"

# Create tier.yaml
cat > "$REPO_ROOT/.aix/tier.yaml" << EOF
tier: 0
name: seed
initialized_at: $(date -I)
history:
  - tier: 0
    date: $(date -I)
    reason: initial bootstrap
EOF

# Run Claude Code adapter
echo "Setting up Claude Code integration..."
"$AIX_FRAMEWORK/adapters/claude-code/generate.sh" 0

# Create .gitignore additions
if [ -f "$REPO_ROOT/.gitignore" ]; then
    if ! grep -q ".aix/state" "$REPO_ROOT/.gitignore"; then
        echo "" >> "$REPO_ROOT/.gitignore"
        echo "# aix state (ephemeral)" >> "$REPO_ROOT/.gitignore"
        echo ".aix/state/" >> "$REPO_ROOT/.gitignore"
        echo ".aix-handoff.md" >> "$REPO_ROOT/.gitignore"
    fi
else
    cat > "$REPO_ROOT/.gitignore" << EOF
# aix state (ephemeral)
.aix/state/
.aix-handoff.md
EOF
fi

echo ""
echo "✅ aix initialized at Tier 0 (Seed)"
echo ""
echo "Structure created:"
echo "  .aix/"
echo "  ├── constitution.md"
echo "  ├── config.yaml"
echo "  ├── tier.yaml"
echo "  ├── roles/ (analyst, coder, reviewer)"
echo "  ├── workflows/ (standard)"
echo "  └── skills/ (aix-init)"
echo ""
echo "  .claude/"
echo "  ├── agents -> .aix/roles"
echo "  └── skills -> .aix/skills"
echo ""
echo "  CLAUDE.md -> .aix/constitution.md"
echo ""
echo "  docs/"
echo "  ├── product.md   <- Fill this in!"
echo "  ├── tech-stack.md"
echo "  └── design.md"
echo ""
echo "Next steps:"
echo "  1. Fill in docs/product.md with your vision"
echo "  2. Review docs/tech-stack.md"
echo "  3. Open Claude Code and start building!"
echo ""
echo "Run /aix-init upgrade when ready for more structure."
