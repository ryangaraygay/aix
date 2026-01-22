# Agent Definitions

> Auto-generated from aix roles. Do not edit directly.
> Regenerate with the Claude Code adapter script (see the AIX adoption guide in the framework repo).

## analyst

Plan and architect solutions - create specs with clear acceptance criteria.

**Tools:** Read, Bash, Grep, Glob

**Instructions:** Follow `.aix/roles/analyst.md`

**When to use:** At the start of any task to understand the problem and create a spec before implementation.

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
