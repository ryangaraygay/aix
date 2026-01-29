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

### Task-Level Execution Model

> **Invoke coder once per task, not once for all tasks.** This minimizes context per invocation and enables parallel execution.

| Role | Granularity | Parallelism |
|------|-------------|-------------|
| Coder | Per task | Yes, for `[P]` tasks within a phase |
| Reviewer | Per phase | No (sequential phases) |
| Tester | Once at end | No |

**Execution flow for each phase:**

```
Phase N tasks from plan (e.g., T001[P], T002[P], T003, T004[P])
       │
       ├── Parallel: Spawn CODER for T001, T002, T004 (marked [P])
       │             └── Each coder implements ONE task
       │
       ├── Sequential: After T001/T002 complete, CODER for T003 (if dependent)
       │
       └── When all phase tasks complete:
           └── REVIEWER reviews entire phase
           └── If issues: spawn coder(s) to fix, then re-review phase
           └── Move to next phase

After all phases complete:
  └── TESTER runs full integration/e2e tests
```

**Example prompt to coder (single task):**

```
Implement task T001 from the plan at `.aix/plans/feature-name/plan.md`.

Task: Create types.ts
- Define Event interface
- Define TimeSlot type
- Export all types

This is ONE task. Do NOT implement other tasks.
Report completion status when done.
```

### Orchestration State Management

#### Primary: Built-in Task Management (Claude Code)

When `TaskCreate`/`TaskList`/`TaskUpdate` tools are available:

```
Setup phase:
  TaskCreate for each task from plan (T001, T002, etc.)
  TaskUpdate to set dependencies (blockedBy/blocks)

Execution loop:
  TaskList → identify unblocked tasks in current phase
  TaskUpdate → mark tasks as in_progress
  Spawn parallel coder Tasks for [P] items
  TaskUpdate → mark completed as coders finish

  When all phase tasks completed → invoke reviewer
  If reviewer finds issues → spawn coder to fix, re-review

  Move to next phase, repeat

  When all phases completed → invoke tester
```

#### Fallback: State-File Tracking (Generic)

When task management tools are unavailable:

```
Use .aix/state/task-progress.md for tracking (NOT plan files):
  - Create: .aix/state/task-progress.md
  - Track completed tasks: "Completed: T001, T002"
  - Track current phase: "Current Phase: 2"
  - Read plan for task definitions, state file for progress

Execution loop:
  Read plan → identify tasks in current phase
  Read state file → identify completed tasks
  Spawn parallel coder Tasks for incomplete [P] items
  Update state file with completed tasks

  When all phase tasks completed → invoke reviewer
  If reviewer finds issues → spawn coder to fix, re-review

  Move to next phase, repeat

  When all phases complete → invoke tester
```

> **Note:** Never edit plan file checkboxes for progress tracking. Plans document decisions, not progress.

### Loop Execution (Per Phase)

```
┌─────────────────────────────────────────────────────────────┐
│                    PHASE N ITERATION                         │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  CODER(s) - one per task, parallel for [P] tasks            │
│  ├── Read assigned task from plan                           │
│  ├── Implement that ONE task                                │
│  ├── Write/update tests for that task                       │
│  ├── Run tests locally                                      │
│  └── Report completion                                      │
│                                                             │
│  (orchestrator waits for all phase tasks to complete)       │
│                                                             │
│  REVIEWER - once per phase                                  │
│  ├── Review all completed tasks in phase together           │
│  ├── Check spec compliance                                  │
│  ├── Check code quality                                     │
│  ├── Classify findings by severity                          │
│  └── Output: APPROVED or CHANGES_REQUESTED                  │
│                                                             │
│  If CHANGES_REQUESTED:                                      │
│  └── Spawn coder(s) to fix specific issues                  │
│  └── Re-review phase                                        │
│                                                             │
│  When phase approved → move to next phase                   │
│                                                             │
└─────────────────────────────────────────────────────────────┘

After all phases complete:
┌─────────────────────────────────────────────────────────────┐
│  TESTER - once at end                                       │
│  ├── Run full automated test suite                          │
│  ├── Verify acceptance criteria                             │
│  ├── Test integration between phases                        │
│  └── Output: PASS or BUGS_FOUND                             │
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

> **For autonomous/non-interactive runs**: Default to "fix now" for < 10 min fixes.
> Defer > 10 min fixes (no user to ask).

### Verification Strategy

Test run strategy varies by test type:

| Test Type | When to Write | When to Run | Notes |
|-----------|---------------|-------------|-------|
| **Unit** | ALWAYS | Local (before PR) | Fast, no deps |
| **Component** | ALWAYS | Local (before PR) | Mocked, fast |
| **Integration** | Default: write | CI (PR check) | Real DB, slower |
| **E2E** | Default: write | CI (PR check) | Real app, slowest |
| **Smoke (agent-browser)** | For UI changes | CI (PR check) | Versioned browser tests |

> For UI-heavy changes, consider adding agent-browser smoke tests.
> These are versioned and reusable, replacing manual verification.

### Database Isolation

> **When schema changes are involved, consider database isolation.**

| Migration Type | Shared DB OK? | Notes |
|----------------|---------------|-------|
| **Additive** (new table, nullable column, index) | ✅ Yes | Safe, no impact on others |
| **Breaking** (drop, rename, type change) | ❌ No | Requires isolated database |

**For breaking migrations:**
1. Analyst flags `isolation_required: true` in spec
2. Create isolated database for this work
3. Test migration on isolated DB
4. Document migration path for production

> **For autonomous/non-interactive runs**: Database isolation is STRICT. Always use isolated/seeded databases.

### Infrastructure Impact

> **Never bundle infrastructure changes with feature work.**

Infrastructure changes (Docker, CI/CD, networking) have different risk profiles and require separate review.

**If the feature involves infrastructure:**
1. Create separate task for infrastructure changes
2. Complete infrastructure changes first
3. Then proceed with feature work

**Infrastructure checklist:**
- [ ] No Docker/Compose changes bundled with features
- [ ] Volume names use dashes (not underscores)
- [ ] Network changes tested in isolation

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
│     IMPLEMENTATION (Phase-by-Phase)     │
│                                         │
│  For each phase:                        │
│  ┌────────┐ ┌────────┐ ┌────────┐       │
│  │CODER(1)│ │CODER(2)│ │CODER(n)│ [P]   │
│  └────┬───┘ └────┬───┘ └────┬───┘       │
│       └──────────┼──────────┘           │
│                  ▼                      │
│           ┌──────────┐                  │
│           │ REVIEWER │ (per phase)      │
│           └──────────┘                  │
│                  │                      │
│       ┌──────────┴──────────┐           │
│       │ issues?             │           │
│       ▼                     ▼           │
│   fix & re-review     next phase        │
│                                         │
│  After all phases:                      │
│           ┌────────┐                    │
│           │ TESTER │ (once at end)      │
│           └────────┘                    │
│                                         │
│  Exit: clean or escalate                │
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

---

## Iteration Limits

| Loop | Max Iterations | On Exceed |
|------|----------------|-----------|
| Coder → Reviewer → Tester | 5 | Escalate to user |

Feature workflow allows more iterations than standard/quick-fix due to complexity. After 5 iterations without resolution, escalate.

---

## Exit Status

When workflow cannot converge, report using this format:

```
EXIT_STATUS: needs_human_review
REASON: [specific reason]
ATTEMPTS: [number of iterations]
LAST_ISSUES: [list of unresolved issues with severity codes]
```

**Example:**
```
EXIT_STATUS: needs_human_review
REASON: Tester found edge case that requires architectural decision
ATTEMPTS: 4
LAST_ISSUES: [H-001: Race condition in concurrent updates, M-002: Test flaky on CI]
```

---

## Verification Checklist

Before marking workflow complete, verify:

- [ ] All tests pass (unit, component, integration)
- [ ] No CRITICAL or HIGH severity issues remain
- [ ] All acceptance criteria from spec are met
- [ ] Tester has verified edge cases

---

## When Running Under Orchestration

When this workflow is executed by an external orchestrator (e.g., AIX-Factor):

**DO NOT:**
- Check CI status (orchestrator handles this)
- Create or manage PRs (orchestrator handles this)
- Push to remote (orchestrator handles this)
- Check GitHub Actions (orchestrator handles this)

**Focus on:** triage → analyst → implement loop → docs → commit locally

The orchestrator handles push, PR creation, and external verification.
