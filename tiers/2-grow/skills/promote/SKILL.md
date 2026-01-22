---
name: promote
description: Create a release branch from dev and open a PR to main. Analyzes commits to suggest semantic version bump.
compatibility: Requires git and gh CLI
mode: aix-local-preferred
metadata:
  invocation: user
  inputs: |
    - version: string (optional, X.Y.Z format - auto-suggested if not provided)
    - dry-run: boolean (optional, preview without changes)
    - yes: boolean (optional, auto-confirm prompts)
  outputs: |
    - branch: string (created branch name, e.g., release/v1.2.3)
    - pr_url: string (GitHub PR URL)
---

# Promote

Create a release branch from dev and open a PR to main (GitFlow release process).

> **Mode**: AIX-local preferred. Interactive version selection is most useful for humans.
> Can work in automated pipelines with `--yes` for non-interactive releases.

## Purpose

Use this skill when:
- Ready to release from dev to main
- Want to freeze a snapshot for release
- Need to trigger the release pipeline

## How It Works

```
dev ──────●──────●──────●──────> (keeps moving)
           \
            └── release/v1.2.3 ──PR──> main
                     │
                     ├── CI gate verifies
                     ├── Auto-merge when checks pass
                     └── On merge: tag created, release notes generated
```

The release branch is a frozen snapshot. Once created, it doesn't change even if dev continues receiving commits.

## Version Suggestion

The script analyzes commits since the last release tag to suggest a semantic version bump:

| Commit Pattern | Version Bump | Example |
|----------------|--------------|---------|
| `BREAKING CHANGE` or `feat!:` | **Major** | 1.2.3 → 2.0.0 |
| `feat:` | **Minor** | 1.2.3 → 1.3.0 |
| `fix:`, `chore:`, etc. | **Patch** | 1.2.3 → 1.2.4 |

## Execution

### Manual Steps (if no script provided)

```bash
# 1. Ensure on dev and up to date
git checkout dev
git pull origin dev

# 2. Determine version
git tag --sort=-version:refname | head -5  # See recent tags
# Analyze commits: git log --oneline $(git describe --tags --abbrev=0)..HEAD

# 3. Create release branch
VERSION="1.3.0"
git checkout -b release/v${VERSION}
git push -u origin release/v${VERSION}

# 4. Create PR to main
gh pr create --base main --title "Release v${VERSION}" --body "Release v${VERSION}"
```

### With Promote Script

```bash
# Analyze commits and suggest version (interactive)
./scripts/promote.sh

# Specify version explicitly
./scripts/promote.sh --version 2.0.0

# Auto-confirm (for CI/automation)
./scripts/promote.sh --yes

# Dry run - preview without changes
./scripts/promote.sh --dry-run
```

## Example Output

```
Preflight checks...
Fetching latest from origin...
Last release: v1.2.2

Analyzing commits since v1.2.2...

  Commits: 15 total
    Features: 3
    Fixes: 8
    Other: 4

Recent commits:
  abc1234 feat(cards): add comment support
  def5678 fix(drag): prevent duplication
  ...

Suggested version: v1.3.0 (minor: 3 new feature(s))

Accept suggested version? [Y/n/custom]:

Creating release branch: release/v1.3.0
  Source: origin/dev (abc1234)
Pushing to origin...
Creating PR to main...

Release branch created!
  Branch: release/v1.3.0
  PR: https://github.com/your-org/your-repo/pull/123

Next steps:
  1. Wait for CI checks to pass
  2. PR merges when checks pass (or manual merge)
  3. On merge: tag created, release notes generated
```

## What Happens After

1. **PR Created**: `release/v1.3.0` → `main`
2. **CI Gate**: Workflow verifies tests pass
3. **Merge**: PR merges (auto or manual depending on setup)
4. **Version Tag**: `v1.3.0` tag created automatically
5. **Release Notes**: Changelog generated from commits

## Troubleshooting

### Branch Already Exists

```bash
# Delete and retry
git push origin --delete release/vX.Y.Z
./scripts/promote.sh
```

### PR Already Open

Close or merge the existing release PR first. Only one release should be in flight at a time.

### CI Not Passing

The release gate will fail if CI hasn't passed for the release commit. Wait for tests to complete on dev, then retry.

## Implementation Notes

Projects implementing this skill should:

1. **Create a promote script** at `./scripts/promote.sh` (or similar)
2. **Configure CI workflows** to:
   - Run verification on release PRs
   - Create tags on merge to main
   - Generate release notes

See your project's CI configuration for specific workflow files.
