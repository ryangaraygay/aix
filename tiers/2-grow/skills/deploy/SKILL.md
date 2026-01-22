---
name: deploy
description: Deploy application to target environment. Supports preview, staging, and production deployments with pre-flight checks.
compatibility: Requires deployment platform CLI (coolify, vercel, fly, etc.) or container runtime (docker)
mode: aix-local-preferred
metadata:
  invocation: user
  inputs: |
    - environment: string (required, preview|staging|production)
    - app: string (optional, app name for monorepos)
    - dry-run: boolean (optional, validate without deploying)
    - force: boolean (optional, skip confirmation for non-production)
  outputs: |
    - url: string (deployed application URL)
    - deployment_id: string (platform-specific deployment ID)
---

# Deploy

Deploy application to a target environment with safety checks.

> **Mode**: AIX-local preferred. Interactive confirmation is most useful for humans.
> Can work in automated pipelines with appropriate flags for non-interactive deployments.

## Purpose

Use this skill when:
- Deploying to preview for PR review
- Deploying to staging for QA
- Deploying to production for release

## Safety Gates

| Environment | Checks Required | Confirmation |
|-------------|-----------------|--------------|
| `preview` | Build passes | None |
| `staging` | Build + Tests pass | None |
| `production` | All CI green + Tag exists | **Required** |

## Execution

### Manual Steps

```bash
# 1. Verify current state
git status                    # Clean working tree
git log --oneline -1          # Correct commit

# 2. Check CI status
gh run list --limit 3         # All checks passing

# 3. Deploy
./scripts/deploy.sh --env production

# 4. Verify deployment
curl -I https://your-app.example.com/health
```

### With Deploy Script

```bash
# Preview deployment (auto-confirm)
./scripts/deploy.sh --env preview

# Staging deployment
./scripts/deploy.sh --env staging

# Production deployment (requires confirmation)
./scripts/deploy.sh --env production

# Dry run - validate without deploying
./scripts/deploy.sh --env production --dry-run

# Monorepo: specific app
./scripts/deploy.sh --env staging --app api
```

## Pre-flight Checks

Before deploying, the script verifies:

| Check | Preview | Staging | Production |
|-------|---------|---------|------------|
| Working tree clean | ⚠️ Warn | ⚠️ Warn | ❌ Block |
| On release branch | - | - | ✅ Required |
| CI checks passing | - | ✅ Required | ✅ Required |
| Version tag exists | - | - | ✅ Required |
| No open blockers | - | - | ✅ Required |

## Example Output

```
Deploy Pre-flight Checks
========================

Environment: production
App: web
Commit: abc1234 (v1.3.0)
Branch: main

Checks:
  ✅ Working tree clean
  ✅ On main branch
  ✅ CI checks passing (12/12)
  ✅ Version tag exists (v1.3.0)
  ✅ No blocking issues

Ready to deploy to production.
This will affect live users.

Continue? [y/N]: y

Deploying...
  Building image...
  Pushing to registry...
  Updating service...
  Waiting for health check...

✅ Deployment complete!

URL: https://your-app.example.com
Deployment ID: dep_abc123xyz
Health: OK (200ms response)

Rollback command (if needed):
  ./scripts/deploy.sh --rollback dep_abc123xyz
```

## Rollback

If issues are discovered after deployment:

```bash
# Rollback to previous deployment
./scripts/deploy.sh --rollback

# Rollback to specific deployment
./scripts/deploy.sh --rollback dep_previous_id
```

## Platform Integration

This skill is platform-agnostic. Implementations should support:

| Platform | CLI | Notes |
|----------|-----|-------|
| Coolify | `coolify-cli` | Self-hosted |
| Vercel | `vercel` | Serverless |
| Fly.io | `fly` | Edge deployment |
| Railway | `railway` | PaaS |
| Docker | `docker compose` | Container-based |
| Kubernetes | `kubectl` | Container orchestration |

## Implementation Notes

Projects implementing this skill should:

1. **Create a deploy script** at `./scripts/deploy.sh`
2. **Configure environment variables** for platform authentication
3. **Set up health check endpoints** for deployment verification
4. **Document rollback procedures** specific to your platform

See your project's deployment configuration for specific details.

## See Also

- [Promote Skill](../promote/SKILL.md) - Create release branches
- [PR Merged Skill](../pr-merged/SKILL.md) - Post-merge summary
