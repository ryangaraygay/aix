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

if git -C "$AIX_FRAMEWORK" rev-parse --git-dir > /dev/null 2>&1; then
    AIX_VERSION="$(git -C "$AIX_FRAMEWORK" rev-parse --short HEAD)"
else
    AIX_VERSION="unknown"
fi
MANIFEST_TOOL="$AIX_FRAMEWORK/scripts/aix-manifest.py"

# Create directories
mkdir -p "$REPO_ROOT/.aix/skills"
mkdir -p "$REPO_ROOT/.aix/scripts"
mkdir -p "$REPO_ROOT/.claude"
mkdir -p "$REPO_ROOT/docs"

# Copy Tier 0 files
echo "Copying Tier 0 (Seed) files..."
cp -r "$AIX_FRAMEWORK/tiers/0-seed/"* "$REPO_ROOT/.aix/"
if [ -f "$MANIFEST_TOOL" ]; then
    python3 "$MANIFEST_TOOL" init \
        --manifest "$REPO_ROOT/.aix/manifest.json" \
        --aix-version "$AIX_VERSION"
    python3 "$MANIFEST_TOOL" record-dir \
        --manifest "$REPO_ROOT/.aix/manifest.json" \
        --repo-root "$REPO_ROOT" \
        --framework-root "$AIX_FRAMEWORK" \
        --source-root "$AIX_FRAMEWORK/tiers/0-seed" \
        --dest-root "$REPO_ROOT/.aix" \
        --capability "seed-base" \
        --aix-version "$AIX_VERSION"
fi

# Make hooks executable
if [ -d "$REPO_ROOT/.aix/hooks" ]; then
    chmod +x "$REPO_ROOT/.aix/hooks/"*.sh 2>/dev/null || true
fi

# Copy doc templates
echo "Copying document templates..."
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
        fi
    done
}
copy_docs_recursive "$AIX_FRAMEWORK/docs/templates" "$REPO_ROOT/docs"
if [ -f "$MANIFEST_TOOL" ]; then
    python3 "$MANIFEST_TOOL" record-dir \
        --manifest "$REPO_ROOT/.aix/manifest.json" \
        --repo-root "$REPO_ROOT" \
        --framework-root "$AIX_FRAMEWORK" \
        --source-root "$AIX_FRAMEWORK/docs/templates" \
        --dest-root "$REPO_ROOT/docs" \
        --capability "docs-templates" \
        --aix-version "$AIX_VERSION"
fi

# Copy core skills (for upgrades and sync)
echo "Copying core skills..."
cp -r "$AIX_FRAMEWORK/skills/"* "$REPO_ROOT/.aix/skills/"
if [ -f "$MANIFEST_TOOL" ]; then
    python3 "$MANIFEST_TOOL" record-dir \
        --manifest "$REPO_ROOT/.aix/manifest.json" \
        --repo-root "$REPO_ROOT" \
        --framework-root "$AIX_FRAMEWORK" \
        --source-root "$AIX_FRAMEWORK/skills" \
        --dest-root "$REPO_ROOT/.aix/skills" \
        --capability "core-skills" \
        --aix-version "$AIX_VERSION"
fi

# Copy core scripts
echo "Copying core scripts..."
cp -r "$AIX_FRAMEWORK/scripts/"* "$REPO_ROOT/.aix/scripts/"
if [ -f "$MANIFEST_TOOL" ]; then
    python3 "$MANIFEST_TOOL" record-dir \
        --manifest "$REPO_ROOT/.aix/manifest.json" \
        --repo-root "$REPO_ROOT" \
        --framework-root "$AIX_FRAMEWORK" \
        --source-root "$AIX_FRAMEWORK/scripts" \
        --dest-root "$REPO_ROOT/.aix/scripts" \
        --capability "core-scripts" \
        --aix-version "$AIX_VERSION"
fi

# Create tier.yaml
cat > "$REPO_ROOT/.aix/tier.yaml" << EOF
tier: 0
name: seed
aix_version: $AIX_VERSION
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
echo "  └── skills/ (aix-init, aix-sync)"
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
