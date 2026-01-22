# Claude Code Adapter

This adapter generates Claude Code-specific files from aix framework components.

## What It Generates

| Source | Generated | Purpose |
|--------|-----------|---------|
| `.aix/constitution.md` | `CLAUDE.md` (symlink) | Entry point for Claude |
| `.aix/roles/*.md` | `.claude/agents/` (symlink) | Agent type definitions |
| `.aix/skills/` | `.claude/skills/` (symlink) | Skill availability |

## Usage

After `/aix-init`, the adapter runs automatically. To regenerate manually:

```bash
# If AIX is a submodule
./.aix/adapters/claude-code/generate.sh 0

# If AIX is installed elsewhere
$AIX_FRAMEWORK/adapters/claude-code/generate.sh 0
```

## Files

### CLAUDE.md

Symlink to `.aix/constitution.md`. Claude Code reads this as the project instruction file.

### .claude/agents/

Defines available agent types based on your tier's roles. Each role is a file.

```markdown
# Example role file: .aix/roles/analyst.md
## Identity
[role definition]
```

### .claude/skills/

Symlink to `.aix/skills/` directory, making skills available to Claude Code.

## Manual Setup

If you prefer manual setup:

```bash
# Create CLAUDE.md symlink
ln -s .aix/constitution.md CLAUDE.md

# Create .claude directory
mkdir -p .claude

# Create agents symlink (adjust path if using submodule tiers)
ln -s ../.aix/roles .claude/agents

# Create skills symlink
ln -s ../.aix/skills .claude/skills

```
