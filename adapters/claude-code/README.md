# Claude Code Adapter

This adapter generates Claude Code-specific files from aix framework components.

## What It Generates

| Source | Generated | Purpose |
|--------|-----------|---------|
| `.aix/constitution.md` | `CLAUDE.md` (symlink) | Entry point for Claude |
| `.aix/roles/*.md` | `.claude/agents.md` | Agent type definitions |
| `.aix/skills/` | `.claude/skills/` (symlink) | Skill availability |

## Usage

After `/aix-init`, run:

```bash
# Generate Claude Code files
./aix/adapters/claude-code/generate.sh
```

Or this is done automatically by `/aix-init`.

## Files

### CLAUDE.md

Symlink to `.aix/constitution.md`. Claude Code reads this as the project instruction file.

### .claude/agents.md

Defines available agent types based on your tier's roles. Example:

```markdown
## analyst
- Description: Plan and architect solutions
- Tools: Read, Bash, Grep, Glob
- Instructions: Follow .aix/roles/analyst.md

## coder
- Description: Implement code according to spec
- Tools: Read, Write, Edit, Bash, Grep, Glob
- Instructions: Follow .aix/roles/coder.md
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

# Create skills symlink
ln -s ../.aix/skills .claude/skills

# Copy agents.md template and customize
cp aix/adapters/claude-code/templates/agents.md .claude/agents.md
```
