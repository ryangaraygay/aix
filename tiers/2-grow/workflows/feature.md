# Feature Workflow

Full workflow for notable changes that require specification and approval.

## Overview

```
┌─────────┐     ┌─────────┐     ┌────────────────┐     ┌─────────┐     ┌─────────┐
│ TRIAGE  │────▶│ ANALYST │────▶│ IMPLEMENTATION │────▶│  DOCS   │────▶│   PR    │
└─────────┘  ✓  └─────────┘  ✓  │      LOOP      │  ✓  └─────────┘  ✓  └─────────┘
             │               │  └────────────────┘  │               │
        User approves   User approves          Tests pass      User approves
        issue valid     spec approach                          push & PR
```

## When to Use

- New feature implementation
- Significant behavior changes
- Architectural modifications
- Changes affecting multiple files
- Work requiring stakeholder approval

---

## Phase 1: Triage

**Role**: triage
**Purpose**: Validate the issue is real and worth addressing

### Actions

1. Read the issue/task description
2. Attempt to reproduce the issue
3. Check git history for recent related changes
4. Search for duplicate issues
5. Assess severity and impact

### Approval Gate: After Triage

```
╔══════════════════════════════════════════════════════════════╗
║  APPROVAL GATE: Triage Complete                              ║
╠══════════════════════════════════════════════════════════════╣
║                                                              ║
║  Issue: #123 - Modal not closing on Escape                   ║
║                                                              ║
║  Triage Result: VALID                                        ║
║    - Reproduced: Yes                                         ║
║    - Not a duplicate                                         ║
║    - Not recently fixed                                      ║
║    - Severity: High                                          ║
║                                                              ║
║  Options:                                                    ║
║    [A] Approve - proceed to spec                             ║
║    [B] Close - not worth addressing                          ║
║    [C] Need more info                                        ║
║                                                              ║
╚══════════════════════════════════════════════════════════════╝
```

---

## Phase 2: Spec (Analyst)

**Role**: analyst
**Purpose**: Design the solution with clear acceptance criteria

### Actions

1. Read triage findings
2. Explore codebase to understand context
3. Identify files that need modification
4. Design solution approach
5. Write spec with testable acceptance criteria
6. Define what's out of scope

### Outputs

Create: `.aix/plans/{feature}/plan.md`

```markdown
# Plan: [Feature Name]

## Task Reference
- Issue: #[id]
- Created: [date]

## Problem Statement
[User-facing description of the problem]

## Proposed Approach
[How we'll solve it]

### Files to Modify
| File | Change |
|------|--------|
| src/components/X.tsx | Add event listener |

### Implementation Steps
1. [Step 1]
2. [Step 2]

## Acceptance Criteria
- [ ] AC1: When [condition], then [result]
- [ ] AC2: When [condition], then [result]
- [ ] AC3: [Negative case handling]

## Out of Scope
- [Explicitly excluded item]

## Test Plan
- [ ] Unit test for [function]
- [ ] Manual verification of [behavior]
```

### Approval Gate: After Spec

```
╔══════════════════════════════════════════════════════════════╗
║  APPROVAL GATE: Spec Complete                                ║
╠══════════════════════════════════════════════════════════════╣
║                                                              ║
║  Plan: .aix/plans/modal-escape/plan.md                       ║
║                                                              ║
║  Approach: Add keydown listener to document, check for       ║
║            Escape key, call close handler                    ║
║                                                              ║
║  Files: 1 (ModalComponent.tsx)                               ║
║  Acceptance Criteria: 3                                      ║
║                                                              ║
║  Options:                                                    ║
║    [A] Approve - proceed to implementation                   ║
║    [B] Request changes - [provide feedback]                  ║
║    [C] Reject - different approach needed                    ║
║                                                              ║
╚══════════════════════════════════════════════════════════════╝
```

---

## Phase 3: Implementation Loop

**Roles**: coder, reviewer, tester
**Purpose**: Implement, review, and test until quality bar met

### Loop Execution

```
┌─────────────────────────────────────────────────────────────┐
│                    ITERATION N                               │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  CODER                                                      │
│  ├── Read spec and acceptance criteria                      │
│  ├── Implement changes (or fix feedback from prior loop)    │
│  ├── Write/update tests                                     │
│  ├── Run tests locally                                      │
│  └── Commit changes                                         │
│                                                             │
│  REVIEWER                                                   │
│  ├── Check spec compliance                                  │
│  ├── Check code quality                                     │
│  ├── Classify findings by severity                          │
│  └── Output: APPROVED or CHANGES_REQUESTED                  │
│                                                             │
│  TESTER                                                     │
│  ├── Run automated tests                                    │
│  ├── Verify acceptance criteria manually                    │
│  ├── Test edge cases                                        │
│  ├── Classify findings by severity                          │
│  └── Output: PASS or BUGS_FOUND                             │
│                                                             │
│  LOOP CONTROLLER                                            │
│  ├── Aggregate findings                                     │
│  ├── Check exit conditions                                  │
│  └── Decision: EXIT / LOOP / ESCALATE                       │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### Exit Conditions

- **Clean exit**: No critical, high, or medium issues
- **Escalate**: Max iterations reached, no progress, or timeout

### Low-Severity Issue Disposition

**Default: Fix now.** Only defer when the cost of fixing exceeds the cost of tracking.

#### Why Fix Now is the Default

The overhead of deferral is often underestimated:
- Time to discuss whether to defer
- Time to create and describe the debt card
- Noise in the backlog
- Context lost when someone picks it up later
- Time to re-understand the issue
- Risk it never gets done

For a 5-minute fix, this overhead easily exceeds the fix itself.

#### When to Defer Instead

Only defer when:
- The fix touches unrelated code (scope creep risk)
- The fix requires investigation beyond the current context
- The fix has non-trivial risk of regression
- The fix requires coordination with other work

#### Decision Heuristic

| Fix Effort | Risk | Action |
|------------|------|--------|
| < 10 min | Low | Fix now |
| < 10 min | High | Defer (explain risk) |
| > 10 min | Low | Ask user |
| > 10 min | High | Defer |

If in doubt: fix it. A fixed issue never needs to be discussed again.

> **For aix-factor (autonomous)**: Default to "fix now" for < 10 min fixes.
> Defer > 10 min fixes (no user to ask).

### Escalation Handling

```
╔══════════════════════════════════════════════════════════════╗
║  ESCALATION: Max Iterations Reached                          ║
╠══════════════════════════════════════════════════════════════╣
║                                                              ║
║  Iteration: 5 of 5                                           ║
║  Remaining Issues: 1 High                                    ║
║                                                              ║
║  H-001: Search returns duplicate results                     ║
║    Attempts: 3                                               ║
║                                                              ║
║  Options:                                                    ║
║    [A] Accept as debt - merge with known issue               ║
║    [B] Grant 2 more iterations                               ║
║    [C] Intervene - I'll look at the code                     ║
║    [D] Abort - discard changes                               ║
║                                                              ║
╚══════════════════════════════════════════════════════════════╝
```

---

## Phase 4: Documentation

**Role**: docs
**Purpose**: Update documentation if the change has user-facing impact

### When to Run

| Impact | Action |
|--------|--------|
| No docs needed | Skip this phase |
| Internal docs | Update developer documentation |
| External docs | Update user-facing documentation |
| Both | Update both |

---

## Phase 5: PR

**Role**: orchestrator
**Purpose**: Push changes and create pull request

### Pre-PR Approval Gate

```
╔══════════════════════════════════════════════════════════════╗
║  APPROVAL GATE: Ready for PR                                 ║
╠══════════════════════════════════════════════════════════════╣
║                                                              ║
║  Implementation Complete                                     ║
║    - Iterations: 3                                           ║
║    - Tests: 45 passed, 0 failed                              ║
║    - Acceptance Criteria: 3/3 passed                         ║
║    - Critical/High Issues: 0                                 ║
║                                                              ║
║  Options:                                                    ║
║    [A] Approve - push and create PR                          ║
║    [B] Request final changes                                 ║
║    [C] Abort                                                 ║
║                                                              ║
╚══════════════════════════════════════════════════════════════╝
```

### PR Actions

1. **Rebase and push**:
   ```bash
   git fetch origin && git rebase origin/dev
   git push -u origin <branch> --force-with-lease
   ```

2. **Create PR** (never merge locally):
   ```bash
   gh pr create --base dev
   ```

3. **After PR merged**:
   - Create tech debt cards for deferred issues
   - Close the original task

---

## Complete Flow Diagram

```
START
  │
  ▼
┌─────────────────┐
│    TRIAGE       │ ← role: triage
└─────────────────┘
  │
  ▼
┌─────────────────┐     ┌─────────────────┐
│ User Approval?  │──No─▶│     Close       │
└─────────────────┘     └─────────────────┘
  │ Yes
  ▼
┌─────────────────┐
│    ANALYST      │ ← role: analyst
└─────────────────┘
  │
  ▼
┌─────────────────┐     ┌─────────────────┐
│ User Approval?  │──No─▶│ Revise / Abort  │
└─────────────────┘     └─────────────────┘
  │ Yes
  ▼
┌─────────────────────────────────────────┐
│         IMPLEMENTATION LOOP             │
│                                         │
│  ┌────────┐  ┌──────────┐  ┌────────┐   │
│  │ CODER  │─▶│ REVIEWER │─▶│ TESTER │   │
│  └────────┘  └──────────┘  └────────┘   │
│       ▲                         │       │
│       └─────────────────────────┘       │
│         (if issues found)               │
└─────────────────────────────────────────┘
  │
  ▼
┌─────────────────┐
│ docs needed?    │
└─────────────────┘
  │ Yes        │ No
  ▼            │
┌─────────────────┐
│   DOCS role     │
└─────────────────┘
  │              │
  └──────────────┘
  ▼
┌─────────────────┐
│ User Approval?  │
└─────────────────┘
  │ Yes
  ▼
┌─────────────────┐
│   CREATE PR     │
└─────────────────┘
  │
  ▼
END
```
