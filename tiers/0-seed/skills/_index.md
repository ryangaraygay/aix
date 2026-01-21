# Skill Registry

Skills are reusable, atomic tasks defined following the [Agent Skills specification](https://agentskills.io/specification). Each skill is a folder containing a `SKILL.md` file with standardized frontmatter and step-by-step instructions.

## Tier 0 (Seed) Skills

*Core skills available at the foundation tier.*

| Skill | Description | Invocation |
|-------|-------------|------------|
| *(none yet)* | Skills in Tier 0 are inherited from higher tiers as needed | |

## Available Skills by Tier

Skills are organized by tier. Higher tiers include all skills from lower tiers.

### Tier 1 (Sprout)

| Skill | Description | Invocation |
|-------|-------------|------------|
| *(see tier 1 index)* | | |

### Tier 2 (Grow)

| Skill | Description | Invocation |
|-------|-------------|------------|
| [agent-browser](../../2-grow/skills/agent-browser/SKILL.md) | Browser automation for smoke tests | user, model |
| [wrap-up](../../2-grow/skills/wrap-up/SKILL.md) | Session wrap-up check before ending | user |
| [promote](../../2-grow/skills/promote/SKILL.md) | Create release branch from dev | user |
| [pr-merged](../../2-grow/skills/pr-merged/SKILL.md) | Post-PR merge summary | user |
| [security-audit](../../2-grow/skills/security-audit/SKILL.md) | Dependency, secrets, OWASP analysis | user, model |
| [quality-audit](../../2-grow/skills/quality-audit/SKILL.md) | Module size, complexity, coverage | user, model |

### Tier 3 (Scale)

| Skill | Description | Invocation |
|-------|-------------|------------|
| *(see tier 3 index)* | | |

## Directory Structure

Each skill follows the Agent Skills specification:

```
skill-name/
└── SKILL.md           # Required - skill definition
    ├── scripts/       # Optional - helper scripts
    ├── references/    # Optional - detailed docs
    └── assets/        # Optional - templates, data files
```

## SKILL.md Format

```yaml
---
name: skill-name              # Required, must match directory name
description: What this skill  # Required, 1-1024 characters
             does and when    # Include keywords for agent recognition
             to use it.
compatibility: Environment    # Optional, system requirements
               requirements
mode: aix-local-only |        # Optional, AIX-specific mode constraint
      aix-factor-only |
      aix-local-preferred
metadata:                     # Optional, custom properties
  invocation: user | model | both
  requires: env/file.env
  inputs: |
    - param: type (notes)
  outputs: |
    - output: type
---

[Step-by-step instructions, examples, error handling]
```

## Invocation Types

- **user**: Explicitly requested by user (e.g., "run wrap-up")
- **model**: AI recognizes situation where skill applies
- **both**: Either invocation method

## AIX Mode Constraints

Some skills only make sense in certain contexts:

| Mode | Description |
|------|-------------|
| `aix-local-only` | Only useful in interactive local sessions (e.g., wrap-up) |
| `aix-factor-only` | Only useful in autonomous aix-factor runs |
| `aix-local-preferred` | Works in both, but most useful locally |
| *(none)* | Works equally well in both contexts |

## How to Invoke a Skill

### Reading the Skill

1. Open the `SKILL.md` file
2. Check `compatibility` for requirements
3. Check `metadata.requires` for dependencies
4. Read `metadata.inputs` for parameters
5. Follow the Execution section

### Running Commands

Execute the commands in the Execution section, substituting inputs as needed.

**From any subdirectory**: Use repo root paths:

```bash
# Works from any directory in the repo
./scripts/skill-name.sh --help
```

### Pre-Invocation Checklist

| Step | Action |
|------|--------|
| 1 | Read `SKILL.md` Execution section for exact syntax |
| 2 | Check script's `--help` if available |
| 3 | Match your parameters to documented `inputs:` in frontmatter |
| 4 | Don't infer flags from prompt terminology |

## Adding New Skills

1. Create folder: `tiers/{tier}/skills/skill-name/`
2. Create `SKILL.md` with required frontmatter
3. Include: Purpose, Prerequisites, Execution, Output, Error Handling
4. Update this `_index.md` or tier-specific index with the new skill
5. Test with at least one AI tool

## Task Management Skills

Task management skills (get-task, create-task, etc.) are **provider-specific**.

AIX defines the interface; implementations live in your project or aix-factor.

See: [Task Manager Interface](../../../adapters/task-manager/interface.md)

## Cross-Tool Compatibility

This skills directory can be symlinked for compatibility with multiple AI tools:

```bash
# Example symlinks (create in your project)
ln -s .aix/skills .claude/skills
ln -s .aix/skills .opencode/skills
```
