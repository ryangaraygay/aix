---
name: performance-audit
description: Analyze application performance including bundle sizes, API latency, and database query efficiency.
compatibility: Requires Node.js. Optional - lighthouse, webpack-bundle-analyzer, clinic.js
metadata:
  invocation: both
  inputs: |
    - scope: string (optional, all|frontend|backend|database, default: all)
    - baseline: string (optional, path to previous audit for comparison)
    - budget: string (optional, path to performance budget file)
  outputs: |
    - report: string (markdown performance analysis)
    - metrics: object (key performance indicators)
---

# Performance Audit

Comprehensive performance analysis across frontend, backend, and database layers.

## Features

- **Bundle Analysis**: JavaScript/CSS bundle sizes, code splitting effectiveness
- **API Latency**: Endpoint response times, slow query detection
- **Database Efficiency**: Query analysis, N+1 detection, index usage
- **Runtime Profiling**: Memory usage, CPU hotspots, event loop lag
- **Core Web Vitals**: LCP, FID, CLS metrics (if applicable)

## Usage

### Manual Execution

```bash
# Full audit
./scripts/performance-audit.sh

# Specific scope
./scripts/performance-audit.sh --scope frontend

# Compare to baseline
./scripts/performance-audit.sh --baseline ./audits/baseline.json

# Check against budget
./scripts/performance-audit.sh --budget ./perf-budget.json
```

### AI Invocation

When invoked as a skill, the AI will:

1. Analyze bundle sizes and composition
2. Profile API endpoints for latency
3. Examine database queries for efficiency
4. Measure memory and CPU usage patterns
5. Generate prioritized recommendations

## Checks Performed

### 1. Frontend Bundle Analysis

```bash
# Analyze bundle composition
npx webpack-bundle-analyzer stats.json --mode static

# Check bundle sizes
npx size-limit
```

| Metric | Warning | Critical |
|--------|---------|----------|
| Main bundle | > 200KB | > 500KB |
| Total JS | > 500KB | > 1MB |
| Total CSS | > 100KB | > 250KB |
| Largest chunk | > 100KB | > 250KB |

### 2. API Latency

| Metric | Warning | Critical |
|--------|---------|----------|
| P50 response | > 100ms | > 500ms |
| P95 response | > 500ms | > 2s |
| P99 response | > 1s | > 5s |
| Error rate | > 1% | > 5% |

### 3. Database Efficiency

| Pattern | Detection | Impact |
|---------|-----------|--------|
| N+1 queries | Loop with repeated queries | High |
| Missing indexes | Sequential scans on large tables | High |
| Over-fetching | SELECT * with unused columns | Medium |
| Slow queries | Execution time > 100ms | High |
| Connection pool exhaustion | Wait time > 10ms | Critical |

### 4. Runtime Metrics

| Metric | Warning | Critical |
|--------|---------|----------|
| Heap usage | > 70% limit | > 90% limit |
| Event loop lag | > 100ms | > 500ms |
| GC pause | > 50ms | > 200ms |

### 5. Core Web Vitals (Frontend)

| Metric | Good | Needs Improvement | Poor |
|--------|------|-------------------|------|
| LCP (Largest Contentful Paint) | < 2.5s | 2.5-4s | > 4s |
| FID (First Input Delay) | < 100ms | 100-300ms | > 300ms |
| CLS (Cumulative Layout Shift) | < 0.1 | 0.1-0.25 | > 0.25 |

## Output Format

```markdown
## Performance Audit Report

**Scope:** all
**Date:** 2025-01-20T10:30:00Z
**Compared to:** baseline (2025-01-15)

### Bundle Analysis

| Bundle | Size | Gzipped | Change |
|--------|------|---------|--------|
| main.js | 245KB | 78KB | +12KB ⚠️ |
| vendor.js | 180KB | 58KB | -5KB ✅ |
| styles.css | 45KB | 12KB | +2KB |

**Tree-shaking opportunities:**
- lodash: Only 3 methods used, import specifically
- moment: Consider date-fns (smaller)

### API Latency

| Endpoint | P50 | P95 | P99 | Calls |
|----------|-----|-----|-----|-------|
| GET /api/cards | 45ms | 120ms | 450ms | 1.2k |
| POST /api/cards | 89ms | 340ms ⚠️ | 1.2s ❌ | 234 |

**Slow endpoints:**
- POST /api/cards: P99 > 1s, investigate DB writes

### Database Analysis

| Query | Avg Time | Calls | Issue |
|-------|----------|-------|-------|
| SELECT * FROM cards WHERE... | 12ms | 450 | Missing index on list_id |
| SELECT * FROM users... | 89ms ⚠️ | 120 | N+1 in card loading |

**Recommendations:**
1. Add index: `CREATE INDEX idx_cards_list_id ON cards(list_id)`
2. Use eager loading for user relations

### Runtime Metrics

| Metric | Current | Baseline | Status |
|--------|---------|----------|--------|
| Heap (avg) | 156MB | 142MB | ⚠️ +10% |
| Event loop lag | 12ms | 8ms | ✅ OK |
| GC frequency | 2.3/min | 2.1/min | ✅ OK |

### Summary

| Category | Score | Trend |
|----------|-------|-------|
| Bundle Size | 72/100 | ↓ -5 |
| API Latency | 85/100 | ↑ +3 |
| Database | 68/100 | → 0 |
| Runtime | 90/100 | ↓ -2 |
| **Overall** | **79/100** | ↓ -1 |

### Prioritized Recommendations

1. **HIGH**: Add missing database index (est. -40% query time)
2. **HIGH**: Fix N+1 query in card loading
3. **MEDIUM**: Tree-shake lodash imports (-15KB bundle)
4. **LOW**: Consider lazy loading for below-fold components
```

## Performance Budget

Define budgets in `perf-budget.json`:

```json
{
  "bundles": {
    "main.js": { "maxSize": "250KB", "maxGzip": "80KB" },
    "total": { "maxSize": "1MB", "maxGzip": "300KB" }
  },
  "api": {
    "p95": "500ms",
    "p99": "2s",
    "errorRate": "1%"
  },
  "database": {
    "slowQueryThreshold": "100ms",
    "maxConnectionWait": "10ms"
  },
  "webVitals": {
    "LCP": "2.5s",
    "FID": "100ms",
    "CLS": "0.1"
  }
}
```

## Prerequisites

### Required

- Node.js

### Optional Tools

| Tool | Purpose | Installation |
|------|---------|--------------|
| webpack-bundle-analyzer | Bundle visualization | `npm i -D webpack-bundle-analyzer` |
| size-limit | Bundle size tracking | `npm i -D size-limit` |
| clinic.js | Node.js profiling | `npm i -g clinic` |
| lighthouse | Web vitals | `npm i -g lighthouse` |
| pg_stat_statements | PostgreSQL query stats | PostgreSQL extension |

## Integration

### CI Pipeline

```yaml
performance-check:
  runs-on: ubuntu-latest
  steps:
    - uses: actions/checkout@v4
    - run: npm ci
    - run: npm run build
    - run: ./scripts/performance-audit.sh --budget perf-budget.json
    - uses: actions/upload-artifact@v4
      with:
        name: perf-report
        path: ./audits/latest.md
```

### Scheduled Monitoring

```yaml
# Run weekly performance baseline
schedule:
  - cron: '0 0 * * 0'
```

## See Also

- [Quality Audit](../quality-audit/SKILL.md) - Code quality metrics
- [Security Audit](../security-audit/SKILL.md) - Security scanning
- [Audit Framework](../../docs/guides/audit-framework.md) - Common patterns
