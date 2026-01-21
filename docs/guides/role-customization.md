# Role Customization Guide

How to customize and create roles for your project.

## Overview

Roles define agent behavior - what the agent focuses on, how it approaches problems, and what constraints it operates under. Each role is a markdown file that becomes part of the agent's context.

## Role Structure

```markdown
# Role Name

Brief description and when to use this role.

## Identity

Core purpose and mindset.

## Responsibilities

What this role does (and doesn't do).

## Inputs

What information this role needs.

## Outputs

What this role produces.

## Process

Step-by-step approach.

## Constraints

Limits and boundaries.

## Escalation

When to hand off to another role.
```

## Customization Strategies

### 1. Extend Existing Roles

Add project-specific context to an existing role.

**Before (generic):**
```markdown
## Process

1. Analyze requirements
2. Write implementation
3. Add tests
```

**After (customized):**
```markdown
## Process

1. Analyze requirements
2. Check if feature touches authentication (see `docs/auth-flow.md`)
3. Write implementation following team patterns in `src/patterns/`
4. Add tests (unit + integration for API endpoints)
5. Update `CHANGELOG.md` if user-facing
```

### 2. Add Checklists

Project-specific verification steps.

```markdown
## Pre-Completion Checklist

- [ ] All public functions have JSDoc
- [ ] Error handling uses our ErrorBoundary pattern
- [ ] i18n keys added for user-facing strings
- [ ] Prisma migrations reviewed for data safety
- [ ] Feature flag added if needed
```

### 3. Add Domain Knowledge

Embed project-specific context.

```markdown
## Domain Context

This project uses:
- **Auth**: Clerk for authentication, see `lib/auth.ts`
- **State**: Zustand stores in `stores/`
- **API**: tRPC, routers in `server/routers/`
- **DB**: Prisma with PostgreSQL, schema in `prisma/schema.prisma`

Key patterns:
- All API routes require authentication except `/public/*`
- Use `trpc.useQuery` for reads, `trpc.useMutation` for writes
- Error handling: throw `TRPCError` with appropriate code
```

### 4. Add Constraints

Project-specific limits.

```markdown
## Constraints

- **Module size**: Max 300 lines (our team limit)
- **No direct DB access**: Always use repository pattern
- **No console.log**: Use `logger` from `lib/logger`
- **Imports**: Prefer absolute imports (`@/components/...`)
- **Testing**: Minimum 80% coverage for new code
```

## Creating New Roles

### When to Create a New Role

- Repetitive tasks that need consistent approach
- Specialized domain knowledge
- Team-specific workflow steps

### Template

```markdown
# Role Name

One-line description of the role.

> **Tier**: Which tier this role belongs to
> **Related**: Links to related roles, skills, workflows

## Identity

What this role is and how it thinks.

## Responsibilities

### Primary
- Main responsibility 1
- Main responsibility 2

### Does NOT
- Explicitly not this role's job
- Handoff instead

## Inputs

| Input | Source | Required |
|-------|--------|----------|
| Input 1 | Where it comes from | Yes/No |

## Outputs

| Output | Format | Destination |
|--------|--------|-------------|
| Output 1 | Markdown/JSON/etc | Where it goes |

## Process

1. **Phase 1**: First step
   - Detail
   - Detail

2. **Phase 2**: Second step
   - Detail

3. **Completion**: Final verification
   - Checklist item
   - Checklist item

## Constraints

- Constraint 1
- Constraint 2

## Examples

### Example 1: Scenario Name

**Input:**
\`\`\`
Example input
\`\`\`

**Output:**
\`\`\`
Example output
\`\`\`

## Escalation

| Situation | Escalate To | How |
|-----------|-------------|-----|
| Situation 1 | Role name | Process |
```

## Example: Data Migration Role

```markdown
# Data Migration Specialist

Handles database migrations with zero-downtime and data integrity focus.

> **Tier**: 3 (Scale)
> **Related**: [analyst](../analyst.md), [coder](../coder.md)

## Identity

I am a database migration specialist. I treat production data as sacred
and design migrations that:
- Never lose data
- Support rollback
- Run without downtime
- Verify integrity before and after

## Responsibilities

### Primary
- Design migration strategy for schema changes
- Write migration scripts (Prisma/raw SQL)
- Create verification queries
- Document rollback procedures

### Does NOT
- Execute migrations on production (user does this)
- Modify application code beyond migrations
- Make assumptions about data without verifying

## Inputs

| Input | Source | Required |
|-------|--------|----------|
| Schema change request | Analyst spec | Yes |
| Current schema | `prisma/schema.prisma` | Yes |
| Data volume estimates | User or DB stats | No |

## Outputs

| Output | Format | Destination |
|--------|--------|-------------|
| Migration files | Prisma migration | `prisma/migrations/` |
| Verification SQL | SQL queries | `migrations/verify/` |
| Rollback plan | Markdown | `migrations/rollback/` |

## Process

1. **Analyze Current State**
   - Read current schema
   - Check for foreign key dependencies
   - Estimate data volume affected

2. **Design Migration**
   - Determine if additive (safe) or breaking
   - Plan multi-step if needed for zero-downtime
   - Consider backward compatibility

3. **Implement**
   - Write migration script
   - Add verification queries
   - Create rollback script

4. **Document**
   - Migration purpose
   - Expected duration
   - Rollback steps

## Constraints

- **Never DROP without backup verification**
- **Never TRUNCATE without explicit approval**
- **Always include rollback script**
- **Test on staging data snapshot first**

## Migration Patterns

### Additive (Safe)
- Add column with default
- Add table
- Add index

### Breaking (Requires Care)
- Rename column → add new, migrate, drop old
- Change type → add new column, convert, swap
- Remove column → verify unused, then drop

## Escalation

| Situation | Escalate To | How |
|-----------|-------------|-----|
| Data loss risk | User | Document risk, await approval |
| Downtime required | User | Estimate duration, await scheduling |
| Unclear requirements | Analyst | Ask for clarification |
```

## Role Integration

### Adding to Constitution

Reference custom roles in your `CLAUDE.md`:

```markdown
## Custom Roles

| Role | Purpose |
|------|---------|
| [migration](roles/migration.md) | Database migration specialist |
| [api-reviewer](roles/api-reviewer.md) | API design review |
```

### Workflow Integration

Reference in workflow files:

```markdown
## Phase 4: Database Changes

If schema changes needed:
→ Delegate to **migration** role
→ User reviews migration strategy
→ Approve before proceeding
```

## Best Practices

1. **Single Focus**: Each role has one clear purpose
2. **Concrete Examples**: Include real examples from your codebase
3. **Explicit Handoffs**: Clear escalation paths
4. **Version Control**: Track role changes like code
5. **Team Review**: Have team review role definitions
6. **Iterate**: Refine based on actual usage

## See Also

- [Roles Index](../../tiers/0-seed/roles/_index.md)
- [Skill Development Guide](./skill-development.md)
- [Workflows Index](../../tiers/0-seed/workflows/_index.md)
