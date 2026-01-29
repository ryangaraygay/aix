---
name: worktree-init
description: Generate a project-specific worktree.yaml config with detected services and ports.
compatibility: Requires local repo access
mode: aix-local-only
metadata:
  invocation: user
  inputs: |
    - scope: string (optional, root|packages|apps, default: root)
    - port_start: number (optional, base port for first service, default: 3000)
  outputs: |
    - config_path: string (.aix/config/worktree.yaml)
    - summary: string (services and ports detected)
---

# Worktree Init

Generate a `.aix/config/worktree.yaml` tailored to this repo.

> **Mode**: AIX-local only. This skill inspects the local filesystem.

## Purpose

Use this when setting up worktrees for a new project or after adding services.

## Detection Heuristics

- **Services**
  - `package.json` (Node apps/packages)
  - `next.config.*` (Next.js)
  - `vite.config.*` (Vite)
  - `pyproject.toml` (Python)
  - `requirements.txt` (Python)

- **Package manager**
  - `pnpm-lock.yaml` → pnpm
  - `package-lock.json` → npm
  - `yarn.lock` → yarn
  - `bun.lockb` → bun

## Output

The skill proposes:

1. **services** list with:
   - `name`
   - `path`
   - `port_env`
   - `base_port`
   - `env_file`
   - optional `env_refs`
2. **package_manager** if detected
3. **symlinks** suggestions for shared secrets
4. Schema header: `# yaml-language-server: $schema=worktree.schema.json`

## Execution Steps

1. Scan repository for service candidates.
2. Detect package manager from lockfiles.
3. Assign base ports starting from `port_start`.
4. Draft `.aix/config/worktree.yaml` and present summary.
5. Ask the user to confirm or edit before writing.

## Example Invocation

```
/worktree-init
```

## Notes

- The user must confirm before writing files.
- If multiple services share the same port, prompt for corrections.
- Keep changes minimal and follow existing repo conventions.
