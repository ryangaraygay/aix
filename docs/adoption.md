# AIX Adoption Guide

How to add AIX to your project.

---

## TL;DR

```bash
# Most projects: bootstrap (copy)
curl -fsSL https://aix.dev/install | bash

# AIX contributors: submodule
git submodule add git@github.com:ebblyn/aix.git .aix
```

---

## Adoption Paths

### 1. Bootstrap (Recommended)

**For:** Most projects adopting AIX

**How it works:**
- Downloads `bootstrap.sh` and runs it
- Copies Tier 0 files into your project's `.aix/` directory
- Sets up `.claude/` integration (symlinks, settings.json)
- Files are yours - no external dependencies after setup

```bash
# Current (while repo is private)
git clone git@github.com:ebblyn/aix.git ~/tools/aix
cd my-project
~/tools/aix/bootstrap.sh

# Future (when public)
curl -fsSL https://aix.dev/install | bash

# With version pinning (planned)
AIX_VERSION=1.2.0 curl -fsSL https://aix.dev/install | bash
```

**After bootstrap:**
```
my-project/
├── CLAUDE.md              → .aix/constitution.md
├── .claude/
│   ├── agents/            → .aix/roles/
│   ├── skills/            → .aix/skills/
│   └── settings.json      # hooks configured
├── .aix/
│   ├── constitution.md
│   ├── config.yaml
│   ├── tier.yaml          # tracks current tier
│   ├── hooks/             # compaction management
│   ├── workflows/
│   ├── roles/
│   └── skills/
└── docs/
    ├── product.md
    ├── tech-stack.md
    └── design.md
```

**Upgrading:**
```bash
# Via skill (inside Claude Code)
/aix-init upgrade

# Or via script
~/tools/aix/upgrade.sh 2   # upgrade to Tier 2
```

**Pros:**
- Self-contained after setup
- Simple git workflow (just files)
- Works with any language/stack
- No submodule complexity

**Cons:**
- Can get stale (upgrade manually)
- No automatic sync with AIX updates

---

### 2. Submodule

**For:**
- Repos that BUILD or EXTEND AIX (e.g., aix-factor)
- Contributors to AIX itself
- Projects that need bleeding-edge AIX

**How it works:**
- `.aix/` is a git submodule pointing to the AIX repo
- Full tier structure available at `.aix/tiers/`
- Changes to AIX can be contributed back

```bash
cd my-project
git submodule add git@github.com:ebblyn/aix.git .aix
./.aix/adapters/claude-code/generate.sh 0
```

**After submodule:**
```
my-project/
├── CLAUDE.md              → .aix/tiers/0-seed/constitution.md
├── .claude/
│   ├── agents/            → .aix/tiers/0-seed/roles/
│   ├── skills/            → .aix/tiers/0-seed/skills/
│   └── settings.json
├── .aix/                   # git submodule
│   ├── tiers/
│   │   ├── 0-seed/
│   │   ├── 1-sprout/
│   │   ├── 2-grow/
│   │   └── 3-scale/
│   ├── adapters/
│   ├── bootstrap.sh
│   └── upgrade.sh
└── .gitmodules
```

**Updating:**
```bash
cd .aix
git fetch origin
git checkout origin/main
cd ..
./.aix/adapters/claude-code/generate.sh 0
```

**Pros:**
- Always has full framework
- Can contribute changes back
- Tight coupling for AIX development

**Cons:**
- Complex git workflow
- Detached HEAD issues
- Larger repo size
- Submodule learning curve

---

## Decision Matrix

| If you are... | Use |
|---------------|-----|
| Adding AIX to a new/existing project | **Bootstrap** |
| Building tools that use AIX (like aix-factor) | **Submodule** |
| Contributing to AIX itself | **Submodule** |
| Experimenting with AIX | **Bootstrap** |
| Running AIX in CI/CD | **Bootstrap** (simpler) |

---

## NOT Planned

These approaches were considered but rejected:

| Approach | Why Not |
|----------|---------|
| **npm/pip package** | Adds runtime dependency, language-specific |
| **Single binary** | Maintenance burden, distribution complexity |
| **GitHub template** | Only works for new repos, no upgrade path |
| **Docker image** | Overkill for what's essentially config files |

AIX is fundamentally **methodology files** (markdown, yaml, shell scripts). Keeping it as files that get copied or submoduled is the simplest, most portable approach.

---

## Version Management

**Current:** No versioning (main branch)

**Planned:**
```yaml
# .aix/tier.yaml
tier: 2
name: grow
aix_version: 1.2.0  # pinned version
upgraded_at: 2026-01-21
```

The `/aix-init upgrade` skill will:
1. Check current version vs latest
2. Show changelog of what's new
3. Upgrade if user confirms

---

## Compaction Hooks (Tier 0)

All adoption paths include compaction hooks as a Tier 0 capability:

- `pre-compact.sh` - Saves workflow state to `.aix-handoff.md` before context compaction
- `post-compact.sh` - Restores context after compaction

This ensures long-running AI sessions don't lose critical state.

---

## See Also

- [README.md](../README.md) - Overview
- [CONTRIBUTING.md](../CONTRIBUTING.md) - How to contribute to AIX
- [Tier 0 Hooks](../tiers/0-seed/hooks/_index.md) - Compaction hook details
