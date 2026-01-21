---
name: cognitive-audit
description: Cognitive load analysis to verify clarity and focus commitment (Miller's Law, decision fatigue, jargon).
compatibility: No special requirements
metadata:
  invocation: both
  inputs: |
    - scope: string (optional, ui|docs|code, default: ui)
    - threshold: string (optional, strict|moderate|relaxed, default: moderate)
  outputs: |
    - report: string (markdown cognitive load analysis)
    - hotspots: array (high cognitive load areas)
---

# Cognitive Audit

Analyze cognitive load and mental model clarity.

## Purpose

Ensure users can understand and use the system without excessive mental effort. Based on cognitive psychology principles:

- **Miller's Law**: 7±2 items in working memory
- **Hick's Law**: Decision time increases with choices
- **Cognitive Load Theory**: Intrinsic, extraneous, germane load

## Checks Performed

### 1. Information Density

| Check | Threshold | Severity |
|-------|-----------|----------|
| Items per screen | ≤ 7 primary | High |
| Choices per decision | ≤ 5 options | Medium |
| Nested levels | ≤ 3 deep | Medium |
| Form fields visible | ≤ 7 at once | Medium |

### 2. Jargon and Clarity

| Check | Detection |
|-------|-----------|
| Technical terms without explanation | Acronyms, industry jargon |
| Inconsistent terminology | Same concept, different names |
| Ambiguous labels | Vague button/link text |
| Error message clarity | User-actionable guidance |

### 3. Navigation Complexity

| Check | Threshold |
|-------|-----------|
| Clicks to core action | ≤ 3 |
| Menu depth | ≤ 2 levels |
| Breadcrumb availability | Required for depth > 1 |

### 4. Decision Points

| Pattern | Risk |
|---------|------|
| Modal on modal | High cognitive load |
| Multiple CTAs | Decision paralysis |
| Unclear primary action | User confusion |
| Destructive actions without warning | Error prone |

## Usage

```bash
# Full UI audit
./scripts/cognitive-audit.sh

# Documentation focus
./scripts/cognitive-audit.sh --scope docs

# Strict thresholds
./scripts/cognitive-audit.sh --threshold strict
```

## Output Format

```markdown
## Cognitive Audit Report

**Scope:** UI
**Threshold:** Moderate
**Date:** 2025-01-20

### Information Density

| Page | Items | Status | Notes |
|------|-------|--------|-------|
| Dashboard | 12 | ⚠️ | Consider grouping |
| Settings | 8 | ⚠️ | Use tabs/sections |
| Card detail | 5 | ✅ | Good focus |

### Jargon Analysis

| Term | Occurrences | Suggestion |
|------|-------------|------------|
| "webhook" | 8 | Add tooltip or glossary |
| "idempotent" | 3 | Replace with "safe to retry" |
| "ETL" | 2 | Spell out on first use |

### Navigation Complexity

| Action | Current Clicks | Target | Status |
|--------|----------------|--------|--------|
| Create card | 2 | ≤ 3 | ✅ |
| Access settings | 3 | ≤ 3 | ✅ |
| Export data | 5 | ≤ 3 | ❌ |

### Decision Hotspots

| Location | Issue | Recommendation |
|----------|-------|----------------|
| Card actions menu | 8 options | Group into submenus |
| Onboarding | 3 equal CTAs | Highlight primary path |
| Delete confirmation | Double negative | Rephrase clearly |

### Recommendations

1. **HIGH**: Reduce dashboard items from 12 to 7 with smart grouping
2. **HIGH**: Add progressive disclosure to settings page
3. **MEDIUM**: Create glossary for technical terms
4. **LOW**: Shorten export data flow
```

## Cognitive Load Principles

### Miller's Law (7±2)

Working memory can hold 7±2 items. Apply to:
- Navigation menu items
- Form fields visible at once
- Options in a dropdown
- Steps in a wizard

### Hick's Law

`RT = a + b * log2(n)` where n = number of choices

More choices = longer decision time. Reduce by:
- Highlighting recommended option
- Progressive disclosure
- Smart defaults

### Cognitive Load Types

| Type | Description | Reduce By |
|------|-------------|-----------|
| Intrinsic | Inherent complexity | Break into steps |
| Extraneous | Poor design | Simplify UI |
| Germane | Learning effort | Good mental models |

## See Also

- [Delight Audit](../delight-audit/SKILL.md) - Brand voice and UX polish
- [Accessibility Audit](../accessibility-audit/SKILL.md) - Inclusive design
- [Audit Framework](../../docs/guides/audit-framework.md)
