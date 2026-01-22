# Skill Development Guide

How to create custom skills following the Agent Skills specification.

## Overview

Skills are reusable, atomic tasks defined in `SKILL.md` files. They follow the [Agent Skills specification](https://agentskills.io/specification) for cross-tool compatibility.

## Directory Structure

```
tiers/{tier}/skills/{skill-name}/
├── SKILL.md           # Required - skill definition
├── scripts/           # Optional - helper scripts
│   └── run.sh
├── references/        # Optional - detailed documentation
│   └── examples.md
└── assets/            # Optional - templates, data files
    └── template.json
```

## SKILL.md Format

### Required Fields

```yaml
---
name: skill-name              # Must match directory name
description: |                # 1-1024 characters
  What this skill does and when to use it.
  Include keywords for agent recognition.
---
```

### Optional Fields

```yaml
---
name: skill-name
description: What the skill does
compatibility: |              # System requirements
  Requires git and gh CLI.
  Optional: docker for containerized runs.
mode: aix-local-only |        # AIX-specific mode constraint
      aix-autonomous-only |   # (see Mode Constraints below)
      aix-local-preferred
metadata:                     # Custom properties
  invocation: user | model | both
  requires: env/credentials.env
  inputs: |
    - param: type (notes)
  outputs: |
    - output: type
---
```

## Skill Body Structure

After the frontmatter, include these sections:

### 1. Title and Purpose

```markdown
# Skill Name

Brief description of what this skill does.

## Purpose

Use this skill when:
- Condition 1
- Condition 2
- Condition 3
```

### 2. Prerequisites

```markdown
## Prerequisites

### Required
- Tool 1
- Tool 2

### Optional
| Tool | Purpose |
|------|---------|
| optional-tool | Enhanced feature |
```

### 3. Execution

```markdown
## Execution

### Manual Steps

\`\`\`bash
# Step-by-step commands
command1
command2
\`\`\`

### With Script

\`\`\`bash
./scripts/skill-name.sh [options]
./scripts/skill-name.sh --help
\`\`\`
```

### 4. Output Format

```markdown
## Output Format

\`\`\`markdown
## Expected Output

- Item 1
- Item 2
\`\`\`
```

### 5. Error Handling

```markdown
## Troubleshooting

### Common Error 1

**Symptom:** Error message
**Fix:** How to resolve
```

## Mode Constraints

Some skills only make sense in certain contexts:

| Mode | When to Use |
|------|-------------|
| `aix-local-only` | Interactive features (wrap-up, dev-start) |
| `aix-autonomous-only` | Autonomous/non-interactive runs (CI, remote agents) |
| `aix-local-preferred` | Works in both, best locally (promote, deploy) |
| *(none)* | Works equally well everywhere |

## Invocation Types

| Type | Description | Example |
|------|-------------|---------|
| `user` | Explicitly requested | `/wrap-up` |
| `model` | AI recognizes situation | Security audit on vulnerable code |
| `both` | Either invocation | Browser automation |

## Script Guidelines

### Bash Scripts

```bash
#!/bin/bash
set -euo pipefail

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --option)
            OPTION="$2"
            shift 2
            ;;
        --help)
            echo "Usage: $0 [--option value]"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

# Main logic
main() {
    echo "Running skill..."
}

main "$@"
```

### Exit Codes

| Code | Meaning |
|------|---------|
| 0 | Success |
| 1 | Error (show message) |
| 2 | Block (for hooks) |

## Testing Skills

### Manual Test

1. Read the SKILL.md
2. Execute the steps
3. Verify output matches expected format
4. Test error cases

### Automated Test

```bash
# Create test fixture
mkdir -p test-fixtures/skill-name

# Run skill
./scripts/skill-name.sh --option value

# Verify output
diff expected.md actual.md
```

## Example: Creating a Lint Skill

### 1. Create Directory

```bash
mkdir -p tiers/1-sprout/skills/lint
```

### 2. Create SKILL.md

```yaml
---
name: lint
description: Run linting for the project with auto-fix option.
compatibility: Requires eslint or similar linter installed
metadata:
  invocation: both
  inputs: |
    - fix: boolean (optional, auto-fix issues)
    - scope: string (optional, specific files or directories)
  outputs: |
    - issues: number (count of issues found)
    - fixed: number (count of auto-fixed issues)
---

# Lint

Run code linting to check for style and quality issues.

## Purpose

Use this skill when:
- Before committing changes
- After significant code changes
- To enforce code style

## Execution

\`\`\`bash
# Check all files
./scripts/lint.sh

# Auto-fix issues
./scripts/lint.sh --fix

# Specific scope
./scripts/lint.sh --scope src/components/
\`\`\`

## Output Format

\`\`\`
Linting...

src/api/users.ts
  12:5  warning  Unexpected console statement  no-console
  34:1  error    Missing return type           @typescript-eslint/explicit-function-return-type

Issues: 2 (1 error, 1 warning)
Auto-fixed: 0
\`\`\`
```

### 3. Create Script (Optional)

```bash
#!/bin/bash
set -euo pipefail

FIX=""
SCOPE="."

while [[ $# -gt 0 ]]; do
    case $1 in
        --fix) FIX="--fix"; shift ;;
        --scope) SCOPE="$2"; shift 2 ;;
        *) echo "Unknown: $1"; exit 1 ;;
    esac
done

npx eslint $FIX "$SCOPE"
```

### 4. Update Skills Index

Add to `tiers/0-seed/skills/_index.md`:

```markdown
| [lint](../../1-sprout/skills/lint/SKILL.md) | Run linting with auto-fix | user, model |
```

## Best Practices

1. **Single Responsibility**: Each skill does one thing well
2. **Clear Prerequisites**: List all requirements upfront
3. **Idempotent**: Running twice produces same result
4. **Error Messages**: Helpful, actionable error output
5. **Documentation**: Examples for common use cases
6. **Cross-Platform**: Consider macOS, Linux, Windows

## See Also

- [Skills Registry](../../tiers/0-seed/skills/_index.md)
- [Agent Skills Specification](https://agentskills.io/specification)
- [Role Customization Guide](./role-customization.md)
