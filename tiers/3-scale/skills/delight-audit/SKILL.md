---
name: delight-audit
description: Brand voice and delight verification for empty states, error messages, and micro-interactions.
compatibility: No special requirements
metadata:
  invocation: both
  inputs: |
    - scope: string (optional, all|empty-states|errors|micro, default: all)
    - brand-guide: string (optional, path to brand guidelines)
  outputs: |
    - report: string (markdown delight analysis)
    - opportunities: array (areas for improvement)
---

# Delight Audit

Verify brand voice consistency and identify delight opportunities.

## Purpose

Ensure the product feels polished, consistent, and delightful. Cover often-neglected areas that impact user perception.

## Checks Performed

### 1. Empty States

| Check | Expectation |
|-------|-------------|
| Visual present | Not just text |
| Helpful copy | Explains what to do |
| Action available | CTA to populate |
| Tone consistent | Matches brand voice |

### 2. Error Messages

| Check | Expectation |
|-------|-------------|
| User-friendly language | No technical jargon |
| Actionable guidance | How to fix |
| Appropriate tone | Not blaming user |
| Recovery path | Clear next steps |

### 3. Loading States

| Check | Expectation |
|-------|-------------|
| Skeleton/placeholder | Not empty void |
| Progress indication | User knows it's working |
| Reasonable timeout | Fallback for slow loads |

### 4. Micro-interactions

| Check | Expectation |
|-------|-------------|
| Hover states | Visual feedback |
| Click feedback | Immediate response |
| Transitions | Smooth, not jarring |
| Success celebrations | Acknowledge achievements |

### 5. Copy Consistency

| Check | Detection |
|-------|-----------|
| Button text patterns | "Save" vs "Submit" vs "Done" |
| Capitalization | Title Case vs Sentence case |
| Punctuation | Periods in UI text |
| Terminology | Consistent naming |

## Usage

```bash
# Full audit
./scripts/delight-audit.sh

# Focus on empty states
./scripts/delight-audit.sh --scope empty-states

# With brand guidelines
./scripts/delight-audit.sh --brand-guide ./brand/guidelines.md
```

## Output Format

```markdown
## Delight Audit Report

**Date:** 2025-01-20

### Empty States

| Screen | Visual | Copy | Action | Status |
|--------|--------|------|--------|--------|
| No cards | ✅ Illustration | ⚠️ Generic | ✅ CTA | ⚠️ |
| No search results | ❌ None | ⚠️ | ❌ None | ❌ |
| Empty inbox | ✅ Icon | ✅ Friendly | ✅ CTA | ✅ |

### Error Messages

| Error | Current | Suggested |
|-------|---------|-----------|
| 404 | "Page not found" | "We couldn't find that page. Maybe it moved?" + home link |
| Network | "Network error" | "Couldn't connect. Check your internet and try again." |
| Validation | "Invalid input" | Specific field guidance |

### Loading States

| Context | Current | Recommendation |
|---------|---------|----------------|
| Card list | Spinner | Skeleton cards |
| Image upload | None | Progress bar |
| Search | Spinner | Skeleton + "Searching..." |

### Micro-interactions

| Element | Hover | Click | Focus | Status |
|---------|-------|-------|-------|--------|
| Primary button | ✅ | ✅ | ✅ | ✅ |
| Card | ⚠️ Subtle | ✅ | ❌ None | ⚠️ |
| Link | ✅ | N/A | ⚠️ Weak | ⚠️ |

### Copy Consistency

| Pattern | Occurrences | Recommendation |
|---------|-------------|----------------|
| "Save" vs "Submit" | 12 vs 5 | Standardize on "Save" |
| Title Case buttons | 8 | Use Sentence case |
| Periods in labels | 3 | Remove for consistency |

### Delight Opportunities

1. **Empty search**: Add illustration + helpful suggestions
2. **First card created**: Celebration animation
3. **Streak achieved**: Badge or confetti
4. **Onboarding complete**: Welcome message

### Recommendations

1. **HIGH**: Fix empty search results state
2. **HIGH**: Add skeletons for list loading
3. **MEDIUM**: Standardize button copy
4. **LOW**: Add subtle celebrations for milestones
```

## Brand Voice Guidelines

Document these for consistent review:

```markdown
## Voice Attributes

- **Friendly**: Warm, approachable, not corporate
- **Clear**: Simple language, no jargon
- **Encouraging**: Celebrate progress, don't blame

## Error Tone

- Acknowledge the problem
- Don't blame the user
- Offer clear next steps
- Add humor sparingly (never for serious errors)

## Empty State Tone

- Explain what belongs here
- Make it feel like potential, not absence
- Provide clear action
```

## See Also

- [Cognitive Audit](../cognitive-audit/SKILL.md) - Mental model clarity
- [Accessibility Audit](../accessibility-audit/SKILL.md) - Inclusive design
- [Audit Framework](../../docs/guides/audit-framework.md)
