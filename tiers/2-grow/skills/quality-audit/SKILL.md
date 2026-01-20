---
name: quality-audit
description: Code quality analysis including module sizes, cyclomatic complexity, and test coverage gaps.
metadata:
  invocation: both
  inputs: |
    - scope: string (optional, default: all)
    - coverage: boolean (optional, run tests with coverage, default: false)
  outputs: |
    - report: string (markdown format summary of code quality)
---

# Quality Audit

Evaluates the health and maintainability of the codebase.

## Features

- **Module Size Enforcement**: Validates file lengths against limits
- **Complexity Analysis**: Cyclomatic complexity checks
- **Coverage Audit**: Highlights critical paths lacking tests
- **Tech Debt Identification**: Scans for TODOs and deprecated patterns

## Usage

```
/quality-audit
/quality-audit --coverage
```

## Checks Performed

### 1. Module Size Limits

Default thresholds (customize in constitution):

| Category | Soft Cap (Warn) | Hard Block |
|----------|-----------------|------------|
| Components/Pages | 500 lines | 750 lines |
| Hooks/Utils | 200 lines | 300 lines |
| Services | 300 lines | 500 lines |

```bash
# Find large files
find src -name "*.ts" -o -name "*.tsx" | xargs wc -l | sort -rn | head -20
```

### 2. Complexity Analysis

Check with ESLint:

```javascript
// .eslintrc rules to enable
{
  "rules": {
    "complexity": ["warn", 10],
    "max-depth": ["warn", 4],
    "max-lines-per-function": ["warn", 50],
    "max-params": ["warn", 4]
  }
}
```

### 3. Test Coverage

```bash
# Jest/Vitest
npm test -- --coverage

# Check coverage thresholds
# Recommend: 80% lines, 70% branches for critical paths
```

Focus areas:
- Core business logic
- API endpoints
- Data transformations
- Auth/security code

### 4. Tech Debt Markers

Search for:

```bash
# TODOs and FIXMEs
grep -rn "TODO\|FIXME\|HACK\|XXX" src/

# Deprecated patterns
grep -rn "@deprecated" src/

# Console logs (should be removed in prod)
grep -rn "console.log\|console.debug" src/
```

### 5. Code Duplication

Look for:
- Copy-pasted code blocks (3+ similar lines)
- Repeated patterns that could be abstracted
- Multiple implementations of same logic

## Output Format

```markdown
# Quality Audit Report

**Date**: 2026-01-19
**Scope**: Full codebase

## Summary

| Metric | Value | Status |
|--------|-------|--------|
| Files > soft cap | 3 | ⚠️ |
| Files > hard cap | 0 | ✅ |
| Avg complexity | 4.2 | ✅ |
| Test coverage | 72% | ⚠️ |
| TODO count | 15 | ℹ️ |

## Large Files (Need Attention)

| File | Lines | Cap | Action |
|------|-------|-----|--------|
| src/components/Dashboard.tsx | 520 | 500 | Split into smaller components |
| src/services/api.ts | 480 | 500 | Extract domain-specific services |

## Complex Functions

| Function | File | Complexity | Recommendation |
|----------|------|------------|----------------|
| processOrder | orders.ts:45 | 15 | Break into smaller steps |
| validateForm | form.ts:120 | 12 | Extract validation rules |

## Coverage Gaps

Critical paths missing tests:
- `src/auth/login.ts` - 0% coverage
- `src/api/payments.ts` - 30% coverage

## Tech Debt

| Type | Count | Examples |
|------|-------|----------|
| TODOs | 15 | Various files |
| console.log | 8 | Should remove for prod |
| Deprecated | 2 | Old API usage |

## Recommendations

1. **High Priority**
   - Add tests for auth/payments
   - Split Dashboard.tsx

2. **Medium Priority**
   - Reduce processOrder complexity
   - Address TODO backlog

3. **Low Priority**
   - Remove console.log statements
```

## References

- Constitution (Module size limits)
- Testing guide
