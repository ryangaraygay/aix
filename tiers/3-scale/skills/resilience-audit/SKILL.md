---
name: resilience-audit
description: Offline functionality and state recovery verification for graceful degradation commitment.
compatibility: Service Worker support, IndexedDB
metadata:
  invocation: both
  inputs: |
    - scope: string (optional, all|offline|recovery|sync, default: all)
    - simulate: boolean (optional, simulate network conditions, default: false)
  outputs: |
    - report: string (markdown resilience analysis)
    - gaps: array (resilience gaps identified)
---

# Resilience Audit

Verify graceful degradation and state recovery capabilities.

## Purpose

Ensure the application handles adverse conditions gracefully:
- Network outages
- Server errors
- Browser crashes
- Slow connections
- Interrupted operations

## Checks Performed

### 1. Offline Capability

| Check | Level | Description |
|-------|-------|-------------|
| Core read | Essential | View existing data offline |
| Core write | Enhanced | Queue changes for sync |
| Full offline | Complete | Work entirely offline |

### 2. State Recovery

| Check | Expectation |
|-------|-------------|
| Page refresh | State preserved |
| Browser crash | Draft recovery |
| Tab close/reopen | Session restore |
| Multi-tab sync | Consistent state |

### 3. Network Resilience

| Condition | Expected Behavior |
|-----------|-------------------|
| Slow 3G | Usable with feedback |
| Offline | Clear indication + queuing |
| Flaky connection | Retry with backoff |
| Server 500 | Graceful error + retry option |

### 4. Data Sync

| Check | Expectation |
|-------|-------------|
| Conflict resolution | Defined strategy |
| Sync status | Visible to user |
| Offline queue | Persisted |
| Retry logic | Exponential backoff |

## Usage

```bash
# Full resilience audit
./scripts/resilience-audit.sh

# Offline focus
./scripts/resilience-audit.sh --scope offline

# With network simulation
./scripts/resilience-audit.sh --simulate
```

## Output Format

```markdown
## Resilience Audit Report

**Date:** 2025-01-20

### Offline Capability

| Feature | Offline Status | Notes |
|---------|----------------|-------|
| View cards | ✅ Works | Cached in IndexedDB |
| Create card | ⚠️ Partial | Queued but no feedback |
| Search | ❌ Fails | Requires server |
| Settings | ✅ Works | Local storage |

### State Recovery

| Scenario | Status | Notes |
|----------|--------|-------|
| Page refresh | ✅ | URL state preserved |
| Form in progress | ⚠️ | Lost on refresh |
| Crash recovery | ❌ | No draft persistence |
| Tab sync | ✅ | Real-time sync works |

### Network Resilience

| Condition | Tested | Result |
|-----------|--------|--------|
| Offline indicator | ✅ | Shows banner |
| Retry button | ⚠️ | Only on some errors |
| Request timeout | ✅ | 30s with feedback |
| Exponential backoff | ❌ | Fixed 5s retry |

### Data Sync

| Check | Status |
|-------|--------|
| Sync queue visible | ❌ No UI |
| Conflict resolution | ✅ Last-write-wins |
| Offline queue persisted | ✅ IndexedDB |
| Sync on reconnect | ✅ Automatic |

### Recommendations

1. **HIGH**: Add draft persistence for forms
2. **HIGH**: Implement exponential backoff for retries
3. **MEDIUM**: Show pending sync count to users
4. **MEDIUM**: Add offline-capable search with local index
5. **LOW**: Add conflict resolution UI for complex cases
```

## Resilience Patterns

### Offline-First Architecture

```
┌─────────────────────────────────────────┐
│              Application                │
├─────────────────────────────────────────┤
│  ┌─────────┐  ┌─────────┐  ┌─────────┐ │
│  │ UI Layer│──│ Service │──│  Sync   │ │
│  │         │  │ Worker  │  │ Manager │ │
│  └─────────┘  └─────────┘  └─────────┘ │
│       │            │            │       │
│  ┌─────────────────────────────────────┐│
│  │           IndexedDB                 ││
│  │     (Source of Truth)               ││
│  └─────────────────────────────────────┘│
└─────────────────────────────────────────┘
                    │
              [Network]
                    │
              ┌─────────┐
              │ Server  │
              └─────────┘
```

### State Recovery Strategy

| Data Type | Storage | Recovery |
|-----------|---------|----------|
| User session | localStorage | Auto-restore |
| Form drafts | IndexedDB | Prompt to restore |
| Pending syncs | IndexedDB | Auto-retry |
| UI state | URL params | Bookmark-safe |

### Retry Strategy

```javascript
// Exponential backoff with jitter
const retryDelays = [1000, 2000, 4000, 8000, 16000];
const jitter = Math.random() * 1000;
const delay = retryDelays[attempt] + jitter;
```

## Prerequisites

- Service Worker support
- IndexedDB for offline storage
- Network Information API (optional)

## See Also

- [Performance Audit](../../2-grow/skills/performance-audit/SKILL.md)
- [Security Audit](../../2-grow/skills/security-audit/SKILL.md)
- [Audit Framework](../../docs/guides/audit-framework.md)
