---
name: accessibility-audit
description: WCAG AA compliance verification including keyboard navigation, focus states, and touch targets.
compatibility: Requires axe-core or pa11y. Optional - screen reader testing
metadata:
  invocation: both
  inputs: |
    - scope: string (optional, all|component|page, default: all)
    - level: string (optional, A|AA|AAA, default: AA)
    - url: string (optional, specific page to audit)
  outputs: |
    - report: string (markdown accessibility analysis)
    - violations: array (WCAG violations with severity)
---

# Accessibility Audit

WCAG compliance verification for inclusive design.

## Features

- **WCAG Compliance**: Level A, AA, and AAA checks
- **Keyboard Navigation**: Tab order, focus traps, skip links
- **Screen Reader**: ARIA labels, semantic HTML, alt text
- **Visual**: Color contrast, text sizing, motion preferences
- **Touch**: Target sizes, touch-friendly interactions

## Checks Performed

### 1. Keyboard Navigation

| Check | WCAG | Severity |
|-------|------|----------|
| All interactive elements focusable | 2.1.1 | Critical |
| Visible focus indicator | 2.4.7 | High |
| No keyboard traps | 2.1.2 | Critical |
| Logical tab order | 2.4.3 | Medium |
| Skip to content link | 2.4.1 | Medium |

### 2. Screen Reader Support

| Check | WCAG | Severity |
|-------|------|----------|
| Images have alt text | 1.1.1 | High |
| Form inputs have labels | 1.3.1 | High |
| ARIA roles used correctly | 4.1.2 | High |
| Heading hierarchy | 1.3.1 | Medium |
| Link purpose clear | 2.4.4 | Medium |

### 3. Visual Design

| Check | WCAG | Threshold |
|-------|------|-----------|
| Text contrast | 1.4.3 | 4.5:1 (AA) |
| Large text contrast | 1.4.3 | 3:1 (AA) |
| UI component contrast | 1.4.11 | 3:1 (AA) |
| Text resizable to 200% | 1.4.4 | No loss |
| Respects prefers-reduced-motion | 2.3.3 | AAA |

### 4. Touch Targets

| Check | Guideline | Minimum Size |
|-------|-----------|--------------|
| Interactive elements | WCAG 2.5.5 | 44x44px |
| Spacing between targets | Best practice | 8px |

## Usage

```bash
# Full audit (WCAG AA)
./scripts/accessibility-audit.sh

# Specific level
./scripts/accessibility-audit.sh --level AAA

# Specific page
./scripts/accessibility-audit.sh --url /dashboard
```

## Output Format

```markdown
## Accessibility Audit Report

**Level:** WCAG 2.1 AA
**Pages Scanned:** 12
**Date:** 2025-01-20

### Summary

| Severity | Count | Status |
|----------|-------|--------|
| Critical | 0 | ✅ |
| High | 3 | ⚠️ |
| Medium | 8 | ⚠️ |
| Low | 12 | ℹ️ |

### Violations

#### HIGH: Missing form labels (1.3.1)

**Files affected:** 2
- `src/components/SearchInput.tsx:23`
- `src/components/FilterDropdown.tsx:45`

**Fix:** Add `aria-label` or associated `<label>` element

#### MEDIUM: Insufficient color contrast (1.4.3)

**Elements:** 5 text instances
**Ratio:** 3.2:1 (required: 4.5:1)

**Fix:** Darken text color from #767676 to #595959

### Keyboard Navigation

| Page | Tab Order | Focus Visible | Skip Link |
|------|-----------|---------------|-----------|
| Home | ✅ | ✅ | ✅ |
| Dashboard | ✅ | ⚠️ Missing on cards | ✅ |
| Settings | ✅ | ✅ | ❌ Missing |

### Recommendations

1. Add visible focus styles to card components
2. Implement skip-to-content on settings page
3. Review color palette for contrast compliance
```

## Prerequisites

### Required

- Node.js
- axe-core or pa11y

### Optional

| Tool | Purpose |
|------|---------|
| pa11y | Automated WCAG testing |
| axe-core | Browser-based testing |
| NVDA/VoiceOver | Manual screen reader testing |

## See Also

- [WCAG 2.1 Guidelines](https://www.w3.org/WAI/WCAG21/quickref/)
- [Audit Framework](../../docs/guides/audit-framework.md)
