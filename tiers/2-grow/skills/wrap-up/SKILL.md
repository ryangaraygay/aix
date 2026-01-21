---
name: wrap-up
description: |
  Session wrap-up check before ending. Surfaces forgotten work,
  interrupted tasks, uncommitted changes, or pending items.
  Use when ending a session to ensure nothing is left behind.
mode: aix-local-only
metadata:
  invocation: user
  inputs: |
    - none
  outputs: |
    - status: ALL SET | PENDING ITEMS | UNCOMMITTED WORK | TASK NOT CLOSED
    - completed: list of accomplished tasks
    - pending: list of incomplete items
    - task_status: associated task info and closure state (if task management configured)
---

# Wrap-up Skill

Quick session health check before ending. Surfaces forgotten work, interrupted tasks, or uncommitted changes.

> **Mode**: AIX-local only. This skill is for interactive sessions where a human is ending their work session.

## Trigger

`/wrap-up` or `/eod` or `/session-end`

## Execution

Perform these checks in order:

### 1. Todo List Status
- Check if TodoWrite was used this session
- Report any `in_progress` or `pending` items
- If no todo list was used, note "No task tracking used"

### 2. Git Status
Run `git status` and report:
- Current branch
- Uncommitted changes (staged or unstaged)
- Unpushed commits
- Whether branch is behind remote

### 3. Worktree Context
If working in a worktree or changes were copied to a worktree:
- Note which worktree has the work
- Whether original repo needs cleanup (e.g., `git restore`)

### 4. Associated Task Status (Optional)

> **Requires**: Task management integration (e.g., project board, issue tracker)

If task management is configured:

**Detection methods (in order):**
1. **ID in branch name**: If branch is `feat/{id}` or contains a task ID pattern, fetch that task
2. **Handoff file**: Check `.ai-handoff.md` for `## Task:` line
3. **Search by name**: Search task system for tasks matching the branch/worktree name

**If a task is found:**
- Report task title and ID
- Check if task is marked as `done`
- If NOT done, flag as pending item requiring closure

**Warn if:**
- Task exists but is not closed (work done but task not marked complete)
- Task is still "In Progress" but PR is merged

### 5. Conversation Review
Review the conversation for:
- Any user requests that weren't completed
- Interrupted tool calls or incomplete operations
- Questions asked by user that weren't answered
- Any "TODO" or "later" items mentioned

### 6. Handoff Update
If significant work was done or the user asks to "save to handoff":
- Update handoff file with current state
- Include current branch, change status, tests run, blockers, and next steps

## Output

```
## Session Wrap-up

### Completed
- [Bullet list of accomplished tasks]

### Pending
- [Any incomplete items, or "None"]

### Git Status
- Branch: [branch name]
- Changes: [summary or "Clean"]
- Sync: [ahead/behind/up-to-date]

### Associated Task
- Task: [title] (ID: [id]) or "None found" or "Task tracking not configured"
- Status: [Done ✓ | Open - needs closure]
- List: [current list name]

### Recommendation
[One of:]
- ALL SET - Safe to end session
- PENDING ITEMS - [brief description of what needs attention]
- UNCOMMITTED WORK - [files that need committing or discarding]
- TASK NOT CLOSED - [task title] still open, needs to be closed
```

## Error Handling

- If git is not available, skip git status check
- If in a non-git directory, note "Not a git repository"
- If task management API is unreachable, note "Could not check task status (API unavailable)"
- If task management is not configured, skip task status check
- Always complete the conversation review even if other checks fail

## Configuration

This skill can be enhanced with task management integration. See your project's configuration for available integrations:

| Integration | Configuration |
|-------------|---------------|
| GitHub Issues | Set up in `.ai/config.yaml` |
| Linear | Set up in `.ai/config.yaml` |
| Custom board | Provide API credentials in `.ai/env/` |
