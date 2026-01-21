---
name: pr-merged
description: |
  Post-PR merge summary and cleanup handoff. Provides session summary,
  lists accomplishments, notes created tasks, and confirms handoff to user
  for local branch/worktree cleanup.
mode: aix-local-only
metadata:
  invocation: user
  inputs: |
    - none (uses conversation context)
  outputs: |
    - summary: what was accomplished
    - tasks_created: any tasks created during session
    - cleanup_note: confirmation user handles local cleanup
---

# PR Merged Skill

Generate a concise summary after a PR is merged, acknowledging user will handle local cleanup.

> **Mode**: AIX-local only. This skill provides session closure for interactive work.

## Trigger

`/pr-merged` or when user says "PR merged" or "merged and cleaned up"

## Execution

### 1. Gather Context

Review the conversation to identify:
- The PR that was merged (title, number, URL if available)
- The branch name that was merged
- Key changes/accomplishments from the session

### 2. Check for Created Tasks

Search conversation for:
- Any tasks created via task management integration
- Task IDs and titles
- Task priorities

### 3. Generate Summary

Provide a structured summary:

```
## Session Summary

**PR Merged:** [PR title] (#[number])
**Branch:** [branch name]

### Completed
- [Bullet list of key accomplishments]

### Code Changes
- [Files/areas modified]

### Tasks Created
- [Task title] ([ID]) - [priority]
- or "None"

### Cleanup
User handling local branch and worktree cleanup.

---

Anything else needed?
```

## Output Guidelines

- Keep summary concise (not exhaustive)
- Focus on meaningful accomplishments, not every file touched
- Group related changes together
- Always end with "Anything else needed?" to prompt user

## Example Output

```
## Session Summary

**PR Merged:** feat(auth): add OAuth2 support (#248)
**Branch:** feat/oauth-integration

### Completed
- Implemented OAuth2 authentication flow
- Added Google and GitHub providers
- Created session management with refresh tokens
- Added user profile sync from OAuth providers

### Code Changes
- src/auth/ - OAuth2 client and handlers
- src/middleware/auth.ts - session validation
- src/routes/auth.ts - OAuth callback endpoints
- tests/auth/ - integration tests

### Tasks Created
- Add Microsoft OAuth provider (abc123) - MEDIUM
- Rate limit OAuth endpoints (def456) - LOW

### Cleanup
User handling local branch and worktree cleanup.

---

Anything else needed?
```

## Error Handling

- If PR details not in conversation, use branch name as identifier
- If no tasks were created, say "None"
- If conversation context is limited (e.g., after compaction), do best effort summary

## Related Skills

- `/wrap-up` - Pre-session-end health check
- `/promote` - Create release PR from dev to main
