---
name: quality-audit
description: Code quality analysis including module sizes, cyclomatic complexity, and test coverage gaps.
compatibility: Requires npm/pnpm, eslint. Optional - vitest/jest for coverage.
metadata:
  invocation: both
  inputs: |
    - scope: string (optional, all|backend|frontend, default: all)
    - coverage: boolean (optional, run tests with coverage, default: false)
  outputs: |
    - report: string (markdown format summary of code quality)
---

# Quality Audit

Evaluates the health and maintainability of the codebase.

## Features

- **Module Size Enforcement**: Validates file lengths against configured limits
- **Complexity Analysis**: Cyclomatic complexity via ESLint rules
- **Coverage Audit**: Highlights critical paths lacking test protection
- **Tech Debt Identification**: Scans for TODOs and deprecated patterns
- **Dead Code Detection**: Identifies unused exports and unreachable code

## Usage

### Manual Execution

\`\`\`bash
# Run full audit
./scripts/quality-audit.sh

# Specific scope
./scripts/quality-audit.sh --scope frontend

# Include coverage analysis
./scripts/quality-audit.sh --coverage
\`\`\`

### AI Invocation

When invoked as a skill, the AI will:

1. Run ESLint with complexity rules
2. Check file sizes against limits
3. Scan for TODO/FIXME/HACK comments
4. Optionally run tests with coverage
5. Generate severity-classified report

## Checks Performed

### 1. Module Size Limits

Validates files against configurable limits:

| Category | Soft Cap (Warn) | Hard Block |
|----------|-----------------|------------|
| Controllers/Pages/Components | 500 lines | 750 lines |
| Hooks/Utils | 200 lines | 300 lines |
| Services | 300 lines | 500 lines |

Configure in your project's ESLint or custom config.

### 2. Complexity Analysis

ESLint rules checked:

\`\`\`javascript
{
  "rules": {
    "complexity": ["warn", 10],
    "max-depth": ["warn", 4],
    "max-lines-per-function": ["warn", 50],
    "max-nested-callbacks": ["warn", 3]
  }
}
\`\`\`

### 3. Test Coverage

Coverage thresholds:

| Metric | Target |
|--------|--------|
| Statements | 80% |
| Branches | 75% |
| Functions | 80% |
| Lines | 80% |

Focus on critical paths:
- Authentication/authorization
- Payment processing
- Data validation
- Core business logic

### 4. Tech Debt Markers

Scans for:
- \`TODO:\` - Planned improvements
- \`FIXME:\` - Known bugs to fix
- \`HACK:\` - Temporary workarounds
- \`XXX:\` - Attention needed
- \`@deprecated\` - Deprecated code

### 5. Dead Code Detection

Identifies:
- Unused exports
- Unreachable code paths
- Unused variables (beyond eslint basic checks)
- Orphaned files

## Output Format

\`\`\`markdown
## Quality Audit Report

**Scope:** all
**Date:** 2025-01-20T10:30:00Z

### Module Sizes

| File | Lines | Limit | Status |
|------|-------|-------|--------|
| src/components/Dashboard.tsx | 520 | 500 | ⚠️ WARN |
| src/services/UserService.ts | 780 | 500 | ❌ BLOCK |

### Complexity

| File | Function | Complexity | Limit |
|------|----------|------------|-------|
| src/utils/parser.ts | parseInput | 15 | 10 |

### Tech Debt

| Type | Count | Files |
|------|-------|-------|
| TODO | 23 | 15 |
| FIXME | 8 | 5 |
| HACK | 3 | 2 |

### Coverage (if enabled)

| Metric | Current | Target | Status |
|--------|---------|--------|--------|
| Statements | 72% | 80% | ⚠️ |
| Branches | 68% | 75% | ⚠️ |
| Functions | 85% | 80% | ✅ |
| Lines | 73% | 80% | ⚠️ |

### Uncovered Critical Paths

- \`src/auth/validateToken.ts\` - 0% coverage
- \`src/payments/processCharge.ts\` - 45% coverage

### Summary

- **Blocking:** 1 (file over hard limit)
- **Warnings:** 5
- **Tech Debt Items:** 34

### Recommendations

1. Split UserService.ts into smaller modules
2. Add tests for validateToken.ts
3. Refactor parseInput to reduce complexity
\`\`\`

## Prerequisites

### Required

- Node.js with npm or pnpm
- ESLint configured in project

### Optional

| Tool | Purpose | Installation |
|------|---------|--------------|
| vitest/jest | Coverage analysis | Already in most projects |
| eslint-plugin-unused-imports | Dead code | \`npm i -D eslint-plugin-unused-imports\` |
| madge | Circular dependencies | \`npm i -g madge\` |

## Configuration

### ESLint Setup

\`\`\`javascript
// eslint.config.js or .eslintrc
{
  "extends": ["eslint:recommended"],
  "rules": {
    "complexity": ["warn", 10],
    "max-depth": ["warn", 4],
    "max-lines": ["warn", { "max": 500, "skipBlankLines": true }],
    "max-lines-per-function": ["warn", 50]
  }
}
\`\`\`

### Coverage Configuration

\`\`\`javascript
// vitest.config.ts
export default {
  test: {
    coverage: {
      provider: 'v8',
      reporter: ['text', 'json', 'html'],
      thresholds: {
        statements: 80,
        branches: 75,
        functions: 80,
        lines: 80
      }
    }
  }
}
\`\`\`

## Integration

### CI Pipeline

\`\`\`yaml
quality-audit:
  runs-on: ubuntu-latest
  steps:
    - uses: actions/checkout@v4
    - run: npm ci
    - run: npm run lint
    - run: npm run test -- --coverage
    - run: ./scripts/quality-audit.sh
\`\`\`

### Pre-commit Hook

\`\`\`bash
# .husky/pre-commit
# Check only staged files
FILES=\$(git diff --cached --name-only --diff-filter=ACM | grep -E '\.(ts|tsx|js|jsx)\$')
if [ -n "\$FILES" ]; then
  npx eslint \$FILES
fi
\`\`\`

## Refactoring Guidelines

When files exceed limits, refactor at **behavioral seams**:

1. **Extract by responsibility** - One module, one job
2. **Extract by data type** - Group operations on same data
3. **Extract utilities** - Pure functions with no side effects
4. **Extract hooks** - Reusable React logic

**Don't:**
- Split arbitrarily at line counts
- Create too many tiny modules
- Over-abstract for hypothetical needs

## See Also

- [Module Architecture Guide](../../docs/guides/module-architecture.md)
- [Testing Guide](../../docs/guides/testing.md)
- [Audit Framework](../../docs/guides/audit-framework.md)
