# aix

**AI development, less painful.**

A progressive framework for AI-assisted software development. Start simple, grow with your project.

---

## What is aix?

aix provides the **methodology DNA** for working effectively with AI coding assistants. It's not another AI tool—it's the structure that makes AI tools work better.

### Core Innovation

The **constitution + workflow + role** trinity with **approval gates** and **progressive enforcement**.

| What Others Do | What aix Adds |
|----------------|---------------|
| Agent orchestration | **Workflow phases + approval gates** |
| Spec-driven dev | **Role separation + quality enforcement** |
| AI coding | **Methodology** - the "how" not just "do" |

---

## Three Horizons

```
HORIZON 1 (Now)     → Framework for Claude Code (terminal, human-in-the-loop)
HORIZON 2 (Next)    → Agent SDK automation (headless, webhooks)
HORIZON 3 (Future)  → SaaS (upload docs → deployed app)
```

---

## Progressive Tiers

aix grows with your project:

| Tier | Name | When | What You Get |
|------|------|------|--------------|
| 0 | **Seed** | Starting out | Constitution, 3 roles, 1 workflow |
| 1 | **Sprout** | Patterns emerging | + hooks, tester, docs, quick-fix workflow |
| 2 | **Grow** | Team/CI needed | + GitHub Actions, orchestrator, audits |
| 3 | **Scale** | Complex/parallel | + worktrees, strategy docs, task management |

---

## Quick Start

### New Project

```bash
# Create your project directory
mkdir my-project && cd my-project

# Bootstrap aix (run from your project directory)
~/Gitea/aix/bootstrap.sh

# Open Claude Code
claude
```

### Existing Project

```bash
cd my-existing-project
~/Gitea/aix/bootstrap.sh
```

### Upgrading

Once initialized, use the skill:
```
/aix-init upgrade
```

The init skill will:
1. Detect your tech stack (or ask)
2. Generate appropriate tier structure
3. Create input document templates
4. Set up Claude Code integration

---

## Input Documents

Every project needs these (templates provided):

| Document | Purpose |
|----------|---------|
| `product.md` | Vision, values, what matters |
| `tech-stack.md` | Technology choices |
| `design.md` | Visual identity (optional) |

---

## Directory Structure

After `/aix-init`, your project will have:

```
your-project/
├── CLAUDE.md              # → .aix/constitution.md
├── .claude/
│   ├── agents.md          # Generated from roles
│   └── skills/            # → .aix/skills/
├── .aix/
│   ├── constitution.md    # Principles
│   ├── config.yaml        # Settings
│   ├── tier.yaml          # Current tier + history
│   ├── workflows/         # How work flows
│   ├── roles/             # Who does what
│   └── skills/            # Reusable automation
└── docs/
    ├── product.md
    ├── tech-stack.md
    └── design.md
```

---

## Philosophy

From [Human+AI Value Creation](https://ryangaraygay.com/describe-design-decide-develop-a-framework-for-building-things/):

> The bottleneck in software creation is shifting from "coding speed" to the human ability to **Describe and Design** high-value systems.

aix embodies this: you focus on the "why" and "what", AI handles the "how".

---

## Status

**Early development.** Extracted from [Ebblyn](https://github.com/ryangaraygay/ebblyn), a production system built in 30 days using this methodology.

---

## License

AGPL-3.0 - See [LICENSE](LICENSE)
