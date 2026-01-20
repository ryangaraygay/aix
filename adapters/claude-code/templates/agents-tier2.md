# Agent Definitions - Tier 2 (Grow)

> Auto-generated from aix roles. Do not edit directly.
> Regenerate with: `./aix/adapters/claude-code/generate.sh`

## triage

Validate issues before planning - confirm reproducibility, check for duplicates/fixes.

**Tools:** Read, Bash, Grep, Glob

**Instructions:** Follow `.aix/roles/triage.md`

**When to use:** Before starting work on a bug report or issue to verify it's valid.

---

## analyst

Plan and architect solutions - create specs with clear acceptance criteria.

**Tools:** Read, Bash, Grep, Glob

**Instructions:** Follow `.aix/roles/analyst.md`

**When to use:** After triage validates an issue, to create a spec before implementation.

---

## coder

Implement code according to spec - write code, tests, and documentation.

**Tools:** Read, Write, Edit, Bash, Grep, Glob

**Instructions:** Follow `.aix/roles/coder.md`

**When to use:** After analyst has created an approved spec, to implement the solution.

---

## reviewer

Review code quality and spec compliance - find issues, classify severity.

**Tools:** Read, Bash, Grep, Glob

**Instructions:** Follow `.aix/roles/reviewer.md`

**When to use:** After coder has completed implementation, to verify quality before merge.

---

## tester

Verify functionality against acceptance criteria - run tests, write tests, find bugs.

**Tools:** Read, Write, Edit, Bash, Grep, Glob

**Instructions:** Follow `.aix/roles/tester.md`

**When to use:** After reviewer approves, to verify test coverage and find edge cases.

---

## docs

Write and update documentation - internal docs for developers, external docs for users.

**Tools:** Read, Write, Edit, Bash, Grep, Glob

**Instructions:** Follow `.aix/roles/docs.md`

**When to use:** When code changes affect documentation, or when new features need docs.
