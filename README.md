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

## What Makes aix Special

- Agents/roles, skills, and hooks are first-class; there are richer collections elsewhere, and aix is designed to integrate them, not replace them.
- Compaction-aware by default: hooks persist/restore context for Claude Code sessions.
- Constitution + workflows are familiar; the difference is the combination with roles/skills/hooks and how they are enforced together.
- Progressive enforcement: start minimal, grow as the project matures, or simplify later.
- Safe evolution: adopt improvements from newer AIX versions without overwriting local customizations.
- Primary support is Claude Code; other tool integrations (symlinks for constitutions/skills) are possible but not the current focus.

---

## Progressive Tiers

aix grows with your project:

| Tier | Name | When | What You Get |
|------|------|------|--------------|
| 0 | **Seed** | Starting out | Constitution, 3 roles, 1 workflow, compaction hooks |
| 1 | **Sprout** | Patterns emerging | + tester, docs, quick-fix workflow, git hooks |
| 2 | **Grow** | Team/CI needed | + GitHub Actions, orchestrator, audits, agent-browser |
| 3 | **Scale** | Complex/parallel | + worktrees, validate-bash hook, advanced audits |

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

## Adoption

**Most projects:** Bootstrap copies files into your project (simple, self-contained)

```bash
# Current (while private)
git clone git@github.com:ebblyn/aix.git ~/tools/aix
cd my-project
~/tools/aix/bootstrap.sh

# Future (when public)
curl -fsSL https://aix.dev/install | bash
```

**AIX contributors:** Submodule for tight coupling

```bash
git submodule add git@github.com:ebblyn/aix.git .aix
./.aix/adapters/claude-code/generate.sh 0
```

See **[docs/adoption.md](docs/adoption.md)** for full details on adoption paths, version management, and decision matrix.

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
│   ├── agents/            # → .aix/roles/
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

## License

AGPL-3.0 - See [LICENSE](LICENSE)
