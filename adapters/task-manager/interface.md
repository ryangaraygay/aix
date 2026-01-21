# Task Manager Interface

AIX defines a provider-agnostic interface for task management. Implementations can target different backends (GitHub Issues, Linear, Jira, custom boards, etc.).

## Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                    AIX TASK MANAGER INTERFACE                    │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐             │
│  │  get-task   │  │ create-task │  │ update-task │  Core CRUD  │
│  └─────────────┘  └─────────────┘  └─────────────┘             │
│                                                                 │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐             │
│  │ start-task  │  │ close-task  │  │comment-task │  Lifecycle  │
│  └─────────────┘  └─────────────┘  └─────────────┘             │
│                                                                 │
│  ┌─────────────┐  ┌─────────────┐                               │
│  │ priorities  │  │relate-task  │                   Advanced   │
│  └─────────────┘  └─────────────┘                               │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
                              │
                    implements│
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                       IMPLEMENTATIONS                            │
│                                                                 │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐             │
│  │   GitHub    │  │   Linear    │  │    Jira     │             │
│  │   Issues    │  │             │  │             │             │
│  └─────────────┘  └─────────────┘  └─────────────┘             │
│                                                                 │
│  ┌─────────────┐  ┌─────────────┐                               │
│  │   Ebblyn    │  │   Custom    │                               │
│  │   Boards    │  │   Board     │                               │
│  └─────────────┘  └─────────────┘                               │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

## Core Operations

### get-task

Retrieve tasks by ID, search, or get next priority task.

**Inputs:**
| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `id` | string | no | Task ID (full or partial) |
| `search` | string | no | Text search query |
| `list` | string | no | Filter by list/column name |
| `priority` | enum | no | Filter by priority level |
| `tags` | string | no | Comma-separated tag names |
| `done` | boolean | no | Filter by completion status |
| `limit` | number | no | Max results (default: 10) |

**Outputs:**
| Field | Type | Description |
|-------|------|-------------|
| `task` | object | Single task (when fetching by ID) |
| `tasks` | array | Task list (when searching) |
| `total` | number | Total matching tasks |

**Modes:**
- **By ID**: `get-task <id>` - Get specific task
- **Search**: `get-task --search "query"` - Search tasks
- **Next**: `get-task` (no args) - Get highest priority undone task

---

### create-task

Create a new task.

**Inputs:**
| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `title` | string | yes | Task title |
| `description` | string | no | Task description (markdown) |
| `priority` | enum | no | urgent\|high\|medium\|low\|none |
| `list` | string | no | Initial list/column |
| `tags` | string | no | Comma-separated tag names |
| `related_to` | string | no | Related task ID |
| `relation_type` | enum | no | blocks\|blocked_by\|depends_on\|parent\|child |

**Outputs:**
| Field | Type | Description |
|-------|------|-------------|
| `task` | object | Created task with ID |

---

### update-task

Update task fields.

**Inputs:**
| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `id` | string | yes | Task ID |
| `title` | string | no | New title |
| `description` | string | no | New description |
| `priority` | enum | no | New priority |
| `list` | string | no | Move to list |
| `position` | string | no | Position in list: top\|bottom\|N |
| `done` | boolean | no | Mark done/undone |
| `tags` | string | no | Replace all tags |
| `add_tag` | string | no | Add single tag |
| `remove_tag` | string | no | Remove single tag |

**Outputs:**
| Field | Type | Description |
|-------|------|-------------|
| `task` | object | Updated task |

---

### start-task

Start working on a task (move to "In Progress" equivalent).

**Inputs:**
| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `id` | string | yes | Task ID |

**Outputs:**
| Field | Type | Description |
|-------|------|-------------|
| `task` | object | Updated task in "Doing" state |

**Side Effects:**
- Moves task to "In Progress" / "Doing" list
- Sets `start_date` if supported

---

### close-task

Complete a task with closing comment.

**Inputs:**
| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `id` | string | yes | Task ID |
| `comment` | string | yes | Completion summary |

**Outputs:**
| Field | Type | Description |
|-------|------|-------------|
| `success` | boolean | Whether task was closed |

**Side Effects:**
- Adds completion comment
- Marks task as done
- Optionally moves to "Done" list

---

### comment-task

Add a comment to a task.

**Inputs:**
| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `id` | string | yes | Task ID |
| `comment` | string | yes | Comment content (markdown) |

**Outputs:**
| Field | Type | Description |
|-------|------|-------------|
| `comment_id` | string | Created comment ID |

---

### priorities

Get strategically prioritized task list.

**Inputs:**
| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `tag` | string | no | Filter by tag |
| `lists` | string | no | Comma-separated list names |
| `limit` | number | no | Max results (default: 10) |

**Outputs:**
| Field | Type | Description |
|-------|------|-------------|
| `priorities` | array | Ranked tasks with blocking info |
| `blocked_items` | array | Tasks that are blocked |

**Sorting Algorithm:**
1. In-progress tasks first
2. Tasks blocking more others ranked higher
3. Priority level as tiebreaker

---

### relate-task

Create/remove relations between tasks.

**Inputs:**
| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `id` | string | yes | Source task ID |
| `target_id` | string | yes | Target task ID |
| `type` | enum | yes | blocks\|blocked_by\|depends_on\|parent\|child |
| `action` | enum | no | add\|remove (default: add) |

**Outputs:**
| Field | Type | Description |
|-------|------|-------------|
| `relation` | object | Created/removed relation |

---

## Data Structures

### Task Object

```yaml
task:
  id: string              # Unique identifier
  title: string           # Task title
  description: string     # Markdown description
  priority: enum          # urgent|high|medium|low|none
  done: boolean           # Completion status
  list:                   # Current list/column
    id: string
    name: string
  tags:                   # Applied tags
    - id: string
      name: string
      color: string
  relations:              # Task relations (optional)
    - id: string
      type: string        # blocks|blocked_by|depends_on|parent|child
      direction: string   # outgoing|incoming
      other_task:
        id: string
        title: string
        done: boolean
  created_at: datetime
  updated_at: datetime
  start_date: datetime    # When work started (optional)
  due_date: datetime      # Due date (optional)
```

### Priority Levels

| Level | Value | When to Use |
|-------|-------|-------------|
| `urgent` | 4 | Security, data loss, production down |
| `high` | 3 | Core functionality broken |
| `medium` | 2 | Normal work |
| `low` | 1 | Polish, minor improvements |
| `none` | 0 | No priority set |

### Relation Types

| Type | Meaning |
|------|---------|
| `blocks` | This task blocks another |
| `blocked_by` | This task is blocked by another |
| `depends_on` | This task depends on another |
| `parent` | This task is a parent of another |
| `child` | This task is a child of another |

---

## Implementing an Adapter

### Required Files

```
adapters/task-manager/{provider}/
├── README.md           # Setup instructions
├── config.md           # Configuration options
└── scripts/            # Skill scripts
    ├── get-task.sh
    ├── create-task.sh
    ├── update-task.sh
    ├── start-task.sh
    ├── close-task.sh
    ├── comment-task.sh
    ├── priorities.sh
    └── relate-task.sh
```

### Script Requirements

Each script must:

1. **Accept standard inputs** as command-line arguments
2. **Output JSON** to stdout (or formatted text with `--format`)
3. **Exit codes**:
   - `0` = success
   - `1` = error (with message to stderr)
4. **Handle authentication** via environment variables

### Example: GitHub Issues Adapter

```bash
# adapters/task-manager/github/scripts/get-task.sh

#!/bin/bash
set -euo pipefail

# Load config
source "$(git rev-parse --show-toplevel)/.aix/env/github.env"

ISSUE_NUMBER="$1"

# Fetch issue
gh issue view "$ISSUE_NUMBER" --json number,title,body,state,labels,assignees

exit 0
```

### Environment Variables

Each adapter defines its required environment variables:

```bash
# .aix/env/github.env
GITHUB_TOKEN=ghp_xxxx
GITHUB_REPO=owner/repo

# .aix/env/linear.env
LINEAR_API_KEY=lin_api_xxxx
LINEAR_TEAM_ID=TEAM

# .aix/env/jira.env
JIRA_URL=https://company.atlassian.net
JIRA_EMAIL=user@company.com
JIRA_API_TOKEN=xxxx
JIRA_PROJECT=PROJ
```

---

## Skill Templates

Generic skill templates that delegate to the configured adapter:

### get-task Skill Template

```yaml
---
name: get-task
description: Retrieve tasks - get by ID, search, or fetch next priority.
             Delegates to configured task manager adapter.
metadata:
  invocation: both
  requires: Task manager adapter configured
  inputs: |
    - id: string (optional, task ID)
    - search: string (optional, text search)
    - list: string (optional, filter by list name)
  outputs: |
    - task: object (single task)
    - tasks: array (search results)
---

# Get Task

Retrieve tasks from your configured task manager.

## Prerequisites

1. Task manager adapter configured in `.aix/config.yaml`:
   ```yaml
   task_manager:
     adapter: github  # or: linear, jira, ebblyn
   ```

2. Adapter credentials in `.aix/env/{adapter}.env`

## Execution

The skill delegates to the adapter script:

```bash
./.aix/adapters/task-manager/${ADAPTER}/scripts/get-task.sh [args]
```

## See Also

- [Task Manager Interface](../adapters/task-manager/interface.md)
```

---

## Configuration

Projects configure their task manager in `.aix/config.yaml`:

```yaml
# .aix/config.yaml
task_manager:
  adapter: github       # Which adapter to use
  auto_close: true      # Close tasks when PR merges
  sync_status: true     # Sync task status with workflow phase
```

---

## Provider Comparison

| Feature | GitHub | Linear | Jira | Ebblyn |
|---------|--------|--------|------|--------|
| get-task | ✅ | ✅ | ✅ | ✅ |
| create-task | ✅ | ✅ | ✅ | ✅ |
| update-task | ✅ | ✅ | ✅ | ✅ |
| start-task | ✅ | ✅ | ✅ | ✅ |
| close-task | ✅ | ✅ | ✅ | ✅ |
| comment-task | ✅ | ✅ | ✅ | ✅ |
| priorities | ⚠️ | ✅ | ⚠️ | ✅ |
| relate-task | ⚠️ | ✅ | ✅ | ✅ |
| Blocking analysis | ❌ | ✅ | ⚠️ | ✅ |
| Batch operations | ❌ | ✅ | ✅ | ✅ |

Legend: ✅ Full support | ⚠️ Partial/workaround | ❌ Not supported

---

## See Also

- [Skills Registry](../../tiers/0-seed/skills/_index.md)
- [Audit Framework](../../docs/guides/audit-framework.md)
