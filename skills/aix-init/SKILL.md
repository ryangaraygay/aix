---
name: aix-init
description: Initialize or upgrade aix framework in a project. Detects tech stack, generates appropriate tier structure, and sets up Claude Code integration.
metadata:
  invocation: user
  inputs: |
    - upgrade: boolean (optional) - run upgrade flow instead of init
    - tier: number (optional) - target tier for upgrade
  outputs: |
    - .aix/ directory with framework files
    - CLAUDE.md symlink
    - .claude/ directory with agents.md and skills symlink
    - docs/product.md, docs/tech-stack.md, docs/design.md templates
---

# Skill: aix-init

Initialize or upgrade the aix framework in your project.

## Usage

```
/aix-init           # Initialize new project
/aix-init upgrade   # Upgrade existing project to next tier
```

## Init Flow

### 1. Detect Existing Setup

Check if `.aix/` already exists:
- If yes, offer upgrade flow
- If no, proceed with init

### 2. Analyze Project

If existing codebase:
```
[Analyzing existing codebase...]

Detected tech stack:
  - Runtime: Node.js 20
  - Framework: React + Vite
  - Testing: Vitest
  - Styling: Tailwind CSS

Is this correct? [Yes / Edit]
```

If no code:
```
No existing code detected. What are you building?
  [ ] Web application (frontend + backend)
  [ ] API/Backend only
  [ ] CLI tool
  [ ] Library/Package
  [ ] Other
```

### 3. Determine Starting Tier

Based on:
- Project complexity (files, dependencies)
- Team size (git contributors)
- Existing CI/CD

Usually starts at Tier 0 (Seed).

### 4. Generate Structure

```bash
# Create .aix directory
mkdir -p .aix/{roles,workflows,skills,state}

# Copy tier files
cp -r aix/tiers/0-seed/* .aix/

# Create tier.yaml
cat > .aix/tier.yaml << EOF
tier: 0
name: seed
initialized_at: $(date -I)
history:
  - tier: 0
    date: $(date -I)
    reason: initial setup
EOF
```

### 5. Generate Input Documents

If not present, create templates:
- `docs/product.md` - from template
- `docs/tech-stack.md` - from detection or template
- `docs/design.md` - from template (optional)

### 6. Setup Claude Code

```bash
# Run Claude Code adapter
./aix/adapters/claude-code/generate.sh 0
```

Creates:
- `CLAUDE.md` symlink
- `.claude/agents.md`
- `.claude/skills/` symlink

### 7. Summary

```
aix initialized at Tier 0 (Seed)

Created:
  .aix/
  ├── constitution.md
  ├── config.yaml
  ├── tier.yaml
  ├── roles/
  │   ├── analyst.md
  │   ├── coder.md
  │   └── reviewer.md
  └── workflows/
      └── standard.md

  CLAUDE.md → .aix/constitution.md
  .claude/agents.md

  docs/
  ├── product.md (template - please fill in)
  ├── tech-stack.md
  └── design.md (template - optional)

Next steps:
1. Fill in docs/product.md with your vision
2. Review docs/tech-stack.md
3. Start working: describe what you want to build

Run /aix-init upgrade when ready for more structure.
```

## Upgrade Flow

### 1. Check Current Tier

Read `.aix/tier.yaml` for current tier.

### 2. Analyze Project Signals

```yaml
inference_signals:
  contributors_30d: [count git authors]
  parallel_branches: [count active branches]
  files_changed_weekly: [estimate from git log]
  has_ci: [check for .github/workflows or similar]
  has_tests: [check for test files]
  test_coverage: [if measurable]
```

### 3. Recommend Next Tier

Based on signals:
- Multiple contributors → Tier 2+
- Parallel branches → Tier 3
- No CI but active development → Tier 2
- Growing complexity → Tier 1

### 4. Present Upgrade Options

```
Your project is at Tier 0 (Seed).

Based on analysis:
  - 3 contributors this month
  - 2 parallel branches
  - No CI/CD yet

Recommended: Upgrade to Tier 1 (Sprout)

This will add:
  [x] tester role
  [x] docs role
  [x] quick-fix workflow
  [x] pre-commit hooks (file sizes, focused tests)
  [x] test skill
  [x] commit skill

Proceed? [Yes / Customize / Skip]
```

### 5. Apply Upgrade

```bash
# Add tier additions
cp -r aix/tiers/1-sprout/* .aix/

# Update tier.yaml
# Update .claude/agents.md
# Setup hooks if applicable
```

### 6. Summary

```
Upgraded to Tier 1 (Sprout)

Added:
  - .aix/roles/tester.md
  - .aix/roles/docs.md
  - .aix/workflows/quick-fix.md
  - .husky/pre-commit
  - .aix/skills/test/
  - .aix/skills/commit/

Updated:
  - .aix/tier.yaml
  - .claude/agents.md

Next tier (Tier 2 - Grow) adds:
  - GitHub Actions CI
  - orchestrator and triage roles
  - feature workflow with full phases
  - audit skills
```

## Tech Stack Detection

### Node.js/JavaScript
- Check `package.json` for framework (react, next, express, etc.)
- Check for TypeScript (`tsconfig.json`)
- Check test framework (jest, vitest, mocha)
- Check styling (tailwind, styled-components, css modules)

### Python
- Check `requirements.txt`, `pyproject.toml`, `setup.py`
- Check for framework (fastapi, django, flask)
- Check test framework (pytest, unittest)

### Go
- Check `go.mod`
- Check for framework (gin, echo, fiber)

### Other
- Look for common config files
- Ask user if unclear

## Error Handling

### Already Initialized
```
aix is already initialized at Tier [N].
Run /aix-init upgrade to upgrade, or delete .aix/ to reinitialize.
```

### Unsupported Project Type
```
Unable to detect project type. Please specify:
  [ ] Web application
  [ ] API
  [ ] CLI
  [ ] Library
  [ ] Other: ___
```

### Upgrade Not Available
```
You're at Tier 3 (Scale) - the highest tier.
No further upgrades available.
```
