# AIX Vision

> **aix-factor: From vibe coding to vibe engineering.**

*Status: WIP - validating with Depot, closing gaps between ebblyn/.ai and .aix*

## The Journey

AIX is designed to evolve through three phases:

### Phase 1: Human-on-the-Loop (Today)
Developer runs Claude Code locally with AIX framework. Human acts as meta-orchestrator:
- Breaks down features into tasks
- Manages task board (Ebblyn, Linear, Jira)
- Spawns parallel AI teams on worktrees
- Reviews and approves at gates

AI teams execute workflows autonomously; human supervises and intervenes at gates.

This is how AIX works today with the tiered system (Seed → Sprout → Grow → Scale).

### Phase 2: Autonomous Teams (Near-term)
Claude Code runs in managed sandboxes (e.g., Depot Agents). Meta-orchestration still human, but teams fully autonomous:
- Orchestrator pulls next task from board, spawns session: `depot claude --session-id <task> --repository <repo> --wait "implement per spec"`
- Session executes full workflow (triage → analyst → coder → reviewer → tester → docs)
- Creates PR, waits for approval gates
- Human oversight on promotions/releases/deployments

Human remains on-the-loop but only at gates, not during execution.

```
Orchestrator (Python script)
    │
    ├── depot claude --session-id task-1 --wait ...  → PR #1
    ├── depot claude --session-id task-2 --wait ...  → PR #2
    └── depot claude --session-id task-N --wait ...  → PR #N
```

### Phase 3: aix-factor (Long-term)
Meta-orchestration gradually replaced by AI. Human moves around-the-loop:
- AI maintains board alignment (ebblyn-align, ebblyn-priorities)
- AI breaks down features and manages dependencies
- AI resolves merge conflicts using product knowledge
- Humans become observers (factory oversight, not on the line)
- Gates remain for critical decisions, humans handle exceptions

## Architecture

### Two Orchestration Layers

```
┌─────────────────────────────────────────────────────────────┐
│                    META-ORCHESTRATOR                        │
│                  (Human + Task Board)                       │
│                                                             │
│  • Feature breakdown and prioritization                     │
│  • Dependency management between features                   │
│  • Team spawning (which worktree works on what)            │
│  • Board alignment (ebblyn-align, ebblyn-priorities)       │
└─────────────────────────────────────────────────────────────┘
                              │
              ┌───────────────┼───────────────┐
              │               │               │
              ▼               ▼               ▼
┌─────────────────┐ ┌─────────────────┐ ┌─────────────────┐
│   AI TEAM 1     │ │   AI TEAM 2     │ │   AI TEAM N     │
│ (Depot Session) │ │ (Depot Session) │ │ (Depot Session) │
│                 │ │                 │ │                 │
│ Claude Code +   │ │ Claude Code +   │ │ Claude Code +   │
│ AIX Framework:  │ │ AIX Framework:  │ │ AIX Framework:  │
│ • Workflows     │ │ • Workflows     │ │ • Workflows     │
│ • Roles         │ │ • Roles         │ │ • Roles         │
│ • Skills        │ │ • Skills        │ │ • Skills        │
│ • Gates         │ │ • Gates         │ │ • Gates         │
└─────────────────┘ └─────────────────┘ └─────────────────┘
```

### Why Wrap Claude Code (Not SDK Rebuild)

Claude Code provides massive leverage:
- Natural language understanding
- Tool execution (Read, Write, Edit, Bash, etc.)
- Context management and compaction
- Built-in safety boundaries
- CLAUDE.md loading (AIX constitution automatically injected)
- MCP support for external tools
- Session persistence and resumption

Building with SDK from scratch would lose this leverage. Instead:
- Managed service or container wraps Claude Code CLI
- AIX framework provides structure (workflows, roles, gates)
- Orchestrator handles: pick up task → start session → monitor → handle output

### Infrastructure Options

| Option | Best For | Trade-off |
|--------|----------|-----------|
| **Depot Agents** | MVP, validation, convenience | $0.60/hr managed vs ~$0.04/hr raw EC2 |
| **Self-hosted (cco + Docker)** | Scale, cost optimization | More ops overhead |
| **Claude Code on Web** | Quick tasks, no local setup | No automation API |

**Depot Agents** (recommended for Phase 2):
- 2 vCPU, 4GB RAM per sandbox
- Claude Code pre-installed with updates
- Git/GitHub integration built-in
- Session persistence across interactions
- OAuth or API key authentication
- Web UI for monitoring
- CLI automation: `depot claude --session-id X --repository Y --wait "prompt"`

The ~15x premium over raw EC2 buys operational simplicity. For MVP, focus on validating the concept, not building infrastructure.

### Parallel Teams in Practice

Today's workflow with 4-8 parallel teams:

```
Main Repo (dev branch)
    │
    ├── ../feature-auth/      (Team 1: Authentication)
    ├── ../feature-dashboard/ (Team 2: Dashboard)
    ├── ../feature-export/    (Team 3: Export)
    └── ../feature-api/       (Team 4: API endpoints)
```

Each team:
1. Gets assigned feature from board
2. Creates worktree (`worktree-setup.sh`)
3. Runs full workflow with role delegation
4. Creates PR to dev
5. Handles review feedback
6. Cleans up after merge (`worktree-cleanup.sh`)

Meta-orchestrator manages the board, not the individual teams.

## The Product Loop

```
┌─────────────────────────────────────────────────────────────┐
│                                                             │
│    ┌──────────┐    ┌──────────┐    ┌──────────┐           │
│    │  Users   │───▶│  Voting  │───▶│ Priority │           │
│    │          │    │          │    │ Pipeline │           │
│    └──────────┘    └──────────┘    └──────────┘           │
│         ▲                               │                  │
│         │                               ▼                  │
│    ┌──────────┐                   ┌──────────┐            │
│    │ Features │◀────────────────── │  Board   │            │
│    │ Launched │                   │ (Tasks)  │            │
│    └──────────┘                   └──────────┘            │
│         ▲                               │                  │
│         │                               ▼                  │
│    ┌──────────┐    ┌──────────┐    ┌──────────┐           │
│    │  Deploy  │◀───│   Gates  │◀───│ AI Teams │           │
│    │          │    │ (Human)  │    │          │           │
│    └──────────┘    └──────────┘    └──────────┘           │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

1. **Users vote** on features they want
2. **Votes feed into priority pipeline** (meta-orchestrator aligns board)
3. **AI teams pick up prioritized tasks** and execute
4. **Human gates** approve promotions/releases/deployments
5. **Features launch** to users
6. **Loop continues** - new feedback, new votes, new features

## Merge Conflict Resolution

When parallel teams create conflicting changes:

1. **Detection**: CI or merge attempt identifies conflict
2. **Context gathering**: Agent reviews both PRs, understands intent
3. **Product knowledge**: Agent has access to specs, understands features
4. **Resolution**: Agent proposes resolution that preserves both intents
5. **Verification**: Tests run, reviewer validates
6. **Human gate**: Final approval before merge

This requires agents with deep product knowledge - not just code diffing.

## What's TBD

- **Cost optimization**: When to move from managed (Depot) to self-hosted
- **Team sizing**: Optimal number of parallel teams per project
- **Failure recovery**: When a team gets stuck or produces bad output
- **Observability**: Monitoring aix-factor throughput and quality
- **Self-hosted alternative**: cco + Docker orchestration for cost-sensitive scale

## Market Positioning

### The Gap

| Category | Examples | What They Do | Limitation |
|----------|----------|--------------|------------|
| **Vibe Coding** | Lovable, Replit, Bolt, v0 | Prompt → prototype | 60-70% solutions, security issues, unmaintainable |
| **Local Autonomous** | Auto-Claude, claude-flow | Multi-agent orchestration | Local only (for now), no board integration |
| **Traditional Dev** | Human engineers | Production systems | Slow, expensive |
| **aix-factor** | This | Production systems via AI factory | - |

### Why Not Vibe Coding?

- 40% more critical security vulnerabilities (METR study)
- 50% need major rewrites within 6 months
- "Zombie apps" - functional but unmaintainable
- Hit walls at production: no CI/CD, infra-as-code, governance
- "Like a capable junior developer" - needs oversight for architecture

### aix-factor Differentiation

| Feature | Vibe Coding | aix-factor |
|---------|-------------|------------|
| Role separation (reviewer catches coder mistakes) | ❌ | ✅ |
| TDD enforcement (failing test before fix) | ❌ | ✅ |
| CI/CD integration | ❌ | ✅ |
| Security audits in workflow | ❌ | ✅ |
| Human gates at critical points | ❌ | ✅ |
| Board/task management integration | ❌ | ✅ |
| Self-improvement (reflect skill) | ❌ | ✅ |

### Competitive Landscape

| Player | What They Do | Gap |
|--------|--------------|-----|
| **Devin** (Cognition) | Autonomous agent, $500/mo enterprise | 15% success on complex tasks, no board integration |
| **Augment Code** | Context engine, enterprise monorepos | Autocomplete focus, not workflows |
| **Auto-Claude** | Multi-agent, QA loop, worktrees | Local only, no cloud, no board |
| **claude-flow** | Agent swarms, MCP | Orchestration only, no workflow enforcement |

**Why Anthropic probably won't compete directly:**
- Business model is infrastructure (API/SDK), not vertical SaaS
- "Platform not product" - they partner with Atlassian, Notion, Figma
- They benefit from ecosystem - more tools using Claude = more API revenue

**aix-factor's moat**: Board integration + workflow enforcement + production-grade quality gates.

## Principles

1. **Progressive enhancement**: Start simple (Tier 0), add complexity as needed
2. **Leverage existing tools**: Claude Code, not SDK rebuild
3. **Human oversight decreases gradually**: Gates, then observers, then exception handling
4. **Quality over speed**: Gates exist for a reason
5. **Self-improvement**: reflect skill proposes improvements to the system itself

---

## Current Status

**Validated:**
- ✅ Depot Agents can run ebblyn/.ai workflows
- ✅ Sub-agent orchestration works (quick-fix workflow)
- ✅ Commit, push, PR creation works

**In Progress:**
- 🚧 Board integration (Ebblyn API → task pickup)
- 🚧 Extract ebblyn/.ai → standalone .aix framework
- 🚧 Automated session spawning from board

**Next:**
- Orchestrator script (poll board → spawn Depot sessions → monitor)
- Cost optimization research (self-hosted alternatives)

---

*This vision describes where AIX is headed. Today, start with the tiered framework and human-on-the-loop. The infrastructure for autonomous teams and aix-factor is being built.*
