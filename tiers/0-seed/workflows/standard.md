# Standard Workflow

The default workflow for implementing features and fixes.

```
ANALYZE ──✓──> IMPLEMENT ──✓──> REVIEW ──✓──> COMPLETE
        User          Tests          Issues
        approves      pass           resolved
        approach
```

## When to Use

- Bug fixes
- Small to medium features
- Clear requirements

## Phases

### Phase 1: ANALYZE

**Role**: analyst

**Purpose**: Understand the problem and create a spec.

**Steps**:
1. Understand the request
2. Explore the codebase
3. Design the approach
4. Write the spec with acceptance criteria
5. Present to user for approval

**Outputs**:
- Spec at `docs/specs/feature-name.md`
- Clear acceptance criteria

**Gate**: User approves approach before proceeding.

---

### Phase 2: IMPLEMENT

**Role**: coder

**Purpose**: Build the solution according to spec.

**Steps**:
1. Read the spec thoroughly
2. Implement changes incrementally
3. Write tests for each acceptance criterion
4. Verify all tests pass
5. Self-review against spec

**Outputs**:
- Working code
- Passing tests
- Implementation summary

**Gate**: Tests pass before proceeding to review.

---

### Phase 3: REVIEW

**Role**: reviewer

**Purpose**: Verify quality and spec compliance.

**Steps**:
1. Read the spec
2. Review code changes
3. Verify acceptance criteria are met
4. Run tests
5. Document findings with severity

**Outputs**:
- Review with findings
- Verdict (approved/changes requested)

**Gate**: No CRITICAL or HIGH issues.

---

### Phase 4: COMPLETE

**Role**: orchestrator (or user)

**Purpose**: Finalize and merge.

**Steps**:
1. Create commit with clear message
2. Push changes (with user approval)
3. Create PR if applicable

**Outputs**:
- Committed code
- PR (if applicable)

**Gate**: User approves final changes.

---

## Handling Issues

### Review Finds Issues

If reviewer finds HIGH severity issues:
1. Return to IMPLEMENT phase
2. Coder addresses issues
3. Return to REVIEW phase
4. Repeat until approved

### Spec Needs Changes

If during implementation the spec seems wrong:
1. Stop implementation
2. Discuss with user
3. Update spec if needed
4. Continue implementation

### Blocked

If blocked (missing info, dependencies, permissions):
1. Document the blocker
2. Ask user for guidance
3. Wait for resolution

---

## Quick Reference

| Phase | Role | Gate |
|-------|------|------|
| Analyze | analyst | User approves spec |
| Implement | coder | Tests pass |
| Review | reviewer | No critical/high issues |
| Complete | - | User approves merge |
