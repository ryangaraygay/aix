---
name: commit
description: Create a git commit with conventional commit message format. Analyzes changes and suggests commit message.
metadata:
  invocation: user
  inputs: |
    - message: string (optional) - override generated message
    - type: string (optional) - commit type (feat, fix, docs, etc.)
  outputs: |
    - Git commit created
    - Commit hash
---

# Skill: commit

Create a well-formatted git commit.

## Usage

```
/commit                    # Auto-generate message from changes
/commit "message here"     # Use provided message
/commit --type fix         # Specify commit type
```

## Commit Types

| Type | When to Use |
|------|-------------|
| `feat` | New feature |
| `fix` | Bug fix |
| `docs` | Documentation only |
| `style` | Formatting, no code change |
| `refactor` | Code change that neither fixes nor adds |
| `test` | Adding or updating tests |
| `chore` | Maintenance, dependencies |

## Execution

### 1. Check Status

```bash
git status
git diff --cached --stat
```

If nothing staged:
```
No changes staged for commit.

Unstaged changes:
  [list modified files]

Stage changes with: git add <files>
Or stage all with: git add -A
```

### 2. Analyze Changes

Look at staged diff to understand:
- What files changed
- What kind of change (new, modified, deleted)
- The nature of changes (feature, fix, refactor, etc.)

### 3. Generate Message

Format: `type(scope): description`

```
feat(auth): add password reset flow

- Add forgot password endpoint
- Add email template for reset link
- Add reset token validation
```

### 4. Confirm with User

```
Proposed commit:

  feat(auth): add password reset flow

  - Add forgot password endpoint
  - Add email template for reset link
  - Add reset token validation

Files to commit:
  - src/auth/reset.ts (new)
  - src/email/templates/reset.html (new)
  - src/auth/routes.ts (modified)

Proceed? [Yes / Edit message / Cancel]
```

### 5. Create Commit

```bash
git commit -m "$(cat <<'EOF'
feat(auth): add password reset flow

- Add forgot password endpoint
- Add email template for reset link
- Add reset token validation
EOF
)"
```

### 6. Report

```
Committed: abc1234

feat(auth): add password reset flow

3 files changed, 150 insertions(+), 10 deletions(-)
```

## Message Guidelines

### Do

- Start with lowercase
- Use imperative mood ("add" not "added")
- Keep first line under 72 characters
- Explain what and why, not how
- Reference issues if applicable: `fixes #123`

### Don't

- End with period
- Use vague messages: "update", "fix bug", "changes"
- Include file names (that's in the diff)
- Be overly verbose

## Examples

### Good Messages

```
feat(api): add rate limiting to public endpoints
fix(auth): prevent session fixation on login
docs(readme): add deployment instructions
refactor(db): extract query builder to separate module
test(auth): add integration tests for OAuth flow
chore(deps): upgrade express to 4.18.2
```

### Bad Messages

```
update files
fix bug
WIP
asdf
changes to auth module
Fixed the thing that was broken
```

## Pre-commit Hooks

If pre-commit hooks are installed (Tier 1+), they run automatically.

If hooks fail:
```
Pre-commit hook failed:

[hook output]

Fix the issues and try again, or:
  git commit --no-verify  # Skip hooks (not recommended)
```
