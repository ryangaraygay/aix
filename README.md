# AIX

**(pronounced "ay-eye-ex" or "ayks" like "aches" — your choice)**

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

- **Multi-tool**: First-class support for Claude Code, Kiro CLI, OpenCode, Factory, and Agent Skills — same methodology, any tool.
- **Adapter system**: Roles, skills, and constitution translate automatically to each tool's native format.
- **Model sets**: Configure which models power each role — swap between budget, mid, and pro tiers per adapter.
- Compaction-aware by default: hooks persist/restore context for Claude Code sessions.
- Progressive enforcement: start minimal, grow as the project matures, or simplify later.
- Safe evolution: adopt improvements from newer AIX versions without overwriting local customizations.

---

## Supported Adapters

| Adapter | Tool | Constitution | Roles | Skills | Model Sets |
|---------|------|-------------|-------|--------|------------|
| **claude-code** | Claude Code | `CLAUDE.md` symlink | `.claude/agents/` (markdown) | `.claude/skills/` symlink | default |
| **kiro-cli** | Kiro CLI | `AGENTS.md` symlink | `.kiro/agents/` (JSON) | `.kiro/skills/` symlink | budget, mid, pro |
| **opencode** | OpenCode | `AGENTS.md` symlink | `.opencode/agent/` (markdown) | `.opencode/skills/` symlink | antigravity |
| **factory** | Factory/Droid | `GEMINI.md` symlink | `.factory/droids/` (markdown) | `.factory/skills/` symlink | balanced, optimal, speed |
| **agentskills** | MCP-based tools | — | — | `.agent/skills/` symlink | — |

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

# Bootstrap aix (select your coding assistant)
~/tools/aix/bootstrap.sh

# Or specify adapter directly
ADAPTER=kiro ~/tools/aix/bootstrap.sh
```

### Existing Project

```bash
cd my-existing-project
~/tools/aix/bootstrap.sh
```

### With a Model Set

```bash
# Generate roles with a specific model set
python3 .aix/scripts/aix-generate.py --adapter kiro --model-set pro
```

### Upgrading

Once initialized, use the skill:
```
/aix-init upgrade
```

### Add Another Adapter

```bash
~/tools/aix/add-adapter.sh opencode
# or choose a model set
~/tools/aix/add-adapter.sh opencode --model-set codex-5.3
```

The init skill will:
1. Detect your tech stack (or ask)
2. Generate appropriate tier structure
3. Create input document templates
4. Set up your chosen adapter's integration

---

## Adoption

**Most projects:** Bootstrap copies files into your project (simple, self-contained)

```bash
git clone git@github.com:ryangaraygay/aix.git ~/tools/aix
cd my-project
~/tools/aix/bootstrap.sh
```

**AIX contributors:** Submodule for tight coupling

```bash
git submodule add git@github.com:ryangaraygay/aix.git .aix
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

After bootstrap, your project will have:

```
your-project/
├── .aix/                     # Core framework (adapter-agnostic)
│   ├── constitution.md       # Principles
│   ├── config.yaml           # Settings
│   ├── tier.yaml             # Current tier + adapter config
│   ├── workflows/            # How work flows
│   ├── roles/                # Who does what (canonical)
│   ├── skills/               # Reusable automation
│   └── adapters/             # Adapter configs + model sets
└── docs/
    ├── product.md
    ├── tech-stack.md
    └── design.md
```

Plus adapter-specific output (examples):

```
# Claude Code                  # Kiro CLI
CLAUDE.md → constitution        AGENTS.md → constitution
.claude/agents/ → roles         .kiro/agents/*.json (generated)
.claude/skills/ → skills        .kiro/skills/ → skills
```

---

## Philosophy

From [Human+AI Value Creation](https://ryangaraygay.com/describe-design-decide-develop-a-framework-for-building-things/):

> The bottleneck in software creation is shifting from "coding speed" to the human ability to **Describe and Design** high-value systems.

aix embodies this: you focus on the "why" and "what", AI handles the "how".

---

## License

AGPL-3.0 - See [LICENSE](LICENSE)
