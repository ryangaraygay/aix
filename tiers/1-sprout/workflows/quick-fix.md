# Quick-Fix Workflow

A streamlined workflow for small, well-understood changes that don't need full analysis.

```
IMPLEMENT ──✓──> REVIEW ──✓──> COMPLETE
         Tests         Issues
         pass          resolved
```

## When to Use

- Typo fixes
- Small bug fixes with obvious solutions
- Single-file changes
- Config updates
- Simple refactors (rename, move)

## When NOT to Use

Use the **standard workflow** instead if:
- Multiple files affected
- Solution isn't immediately obvious
- Architectural decisions needed
- New feature (even small)
- Risk of breaking other things

> When in doubt, use standard workflow. The time spent on analysis often saves debugging time later.

## Phases

### Phase 1: IMPLEMENT

**Role**: coder

**Purpose**: Make the fix directly.

**Steps**:
1. Understand the issue
2. Identify the fix location
3. **Write failing test first** (TDD - see below)
4. Make the change
5. Run tests to verify fix works

**Outputs**:
- Failing test that reproduces the bug
- Fixed code
- Passing tests

**Gate**: Tests pass before proceeding to review.

#### TDD Requirement for Bug Fixes

> **Bug fixes require TDD**: Write a failing test FIRST, then fix.

```
1. Write test that reproduces the bug
2. Run test → confirm it FAILS (proves bug exists)
3. Implement fix
4. Run test → confirm it PASSES
5. Commit test + fix together
```

**Why TDD for bugs:**
- Proves the bug exists before fixing
- Prevents regression (test catches if bug returns)
- Reviewer can verify the test actually tests the bug

**Reviewer will reject** bug fixes without a reproducing test.

---

### Phase 2: REVIEW

**Role**: reviewer

**Purpose**: Quick sanity check.

**Steps**:
1. Verify the change is small and focused
2. Check for obvious issues
3. Verify tests cover the change
4. Approve or request changes

**Outputs**:
- Quick review (less detailed than standard)
- Verdict

**Gate**: No CRITICAL issues.

---

### Phase 3: COMPLETE

**Role**: orchestrator (or user)

**Purpose**: Commit and push.

**Steps**:
1. Commit with clear message
2. Push (with user approval)

**Outputs**:
- Committed code

---

## Quick Reference

| Phase | Role | Gate |
|-------|------|------|
| Implement | coder | Tests pass |
| Review | reviewer | No critical issues |
| Complete | - | User approves |

## Escalation

If during quick-fix you discover:
- The issue is more complex than expected
- Multiple files need changes
- You're unsure about the right approach

**STOP** and switch to standard workflow. Don't force a complex fix through the quick path.

## Example Use Cases

### Good for Quick-Fix

```
- Fix typo in error message
- Update hardcoded value
- Add missing null check
- Fix off-by-one error (with clear cause)
- Update dependency version
```

### Not for Quick-Fix

```
- Fix bug with unclear cause
- Add new validation logic
- Refactor multiple functions
- Add new API parameter
- Performance optimization
```
