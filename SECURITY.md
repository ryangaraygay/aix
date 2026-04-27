# Security Policy

## Reporting a vulnerability

Please report security vulnerabilities **privately** via GitHub Security Advisories:

→ https://github.com/ryangaraygay/aix/security/advisories/new

Do not open a public issue for vulnerabilities. Public disclosure before a fix is ready puts users at risk.

**Expected response time**: best effort within 7 days for initial acknowledgment. aix is a small project — please be patient.

## What's in scope

- `bootstrap.sh`, `add-adapter.sh`, `adopt.sh`, `upgrade.sh` — installation/setup scripts
- `adapters/*/generate.sh` — adapter installers
- `scripts/aix-generate.py`, `scripts/aix-manifest.py`, etc. — Python utilities
- The capability registry and tier files (`tiers/`, `skills/`)

## Trust model — please read

aix's design intentionally executes code on your machine. Three things to be explicit about:

### 1. Setup scripts run shell commands locally

`bootstrap.sh` and the adapter `generate.sh` scripts run shell commands during install (file copies, symlinks, git operations). They do not download or execute remote code. Inspect them before running if you're cautious — they're <200 lines each.

### 2. aix hooks execute arbitrary code in your AI tool

When you adopt a hook (`.aix/hooks/<name>.sh`), the adapter generators wire it into your AI tool's hook configuration (`.claude/settings.json`, `.cursor/hooks.json`, etc.). The AI tool will execute these scripts at the configured lifecycle events.

**Implication**: if you wouldn't run a script in your shell, don't put it in `.aix/hooks/`. If you adopt aix updates that change hook scripts, treat them like any other dependency change — diff and review before regenerating.

### 3. Adapter-generated config mirrors source files

Generators copy/transform files from `.aix/` into tool-native locations. They don't add behavior beyond what's in the source. The trust boundary is at `.aix/` — once a file is there, it can be wired into your tools by `generate.sh`.

## Known limitations

Documented in [`docs/ROADMAP.md`](docs/ROADMAP.md). These aren't security vulnerabilities per se but are upstream tool behaviors that affect what aix can guarantee:

- Cursor 2.5 silently coerces subagent `model:` when the parent agent is on Auto
- Cursor hooks are flagged beta by upstream
