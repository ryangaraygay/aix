---
name: aix-sync
description: Sync local AIX files with newer framework changes without overwriting local edits.
metadata:
  invocation: user
  inputs: |
    - framework_path: string (optional) - path to AIX framework repo
    - dry_run: boolean (optional) - analyze only, no changes
  outputs: |
    - update report with version drift and proposed changes
---

# Skill: aix-sync

Update a repo's AIX files to the latest framework state while preserving local adaptations.

## Principles

- Never overwrite local edits without explicit approval.
- Prefer additive changes and safe merges.
- If unsure, propose a plan and ask.

## Procedure

1. **Resolve framework path**
   - Use input `framework_path`, else `$AIX_FRAMEWORK`, else `~/tools/aix`.
2. **Read current state**
   - `.aix/tier.yaml` for `tier`, `adopted`, and `aix_version` (if present).
   - `.aix/manifest.json` and `.aix/snapshots/` if available.
3. **Read framework registry**
   - Use `<framework>/registry.tsv` to enumerate capabilities.
4. **Compute installed capabilities**
   - All capabilities with `tier <= current tier`.
   - Plus any in `adopted`.
5. **Detect updates**
   - Compare framework files to local files for installed capabilities.
   - Classify each file as `missing`, `unchanged`, or `modified`.
6. **Propose changes**
   - `missing`: propose adopt or copy.
   - `unchanged`: safe to replace with new template.
   - `modified`: propose a three-way merge if snapshots exist, otherwise an AI merge with explicit approval.

## Deterministic Helper

Use the sync script to generate merge proposals:

```bash
python3 .aix/scripts/aix-sync.py --framework-root <path> --json
```

This writes proposed merges to `.aix/sync/` and returns a JSON summary. Apply clean merges only after review:

```bash
python3 .aix/scripts/aix-sync.py --framework-root <path> --apply
```

## File Mapping

Use capability type to map framework paths to local paths:
- `skill` -> `.aix/skills/<name>/`
- `role` -> `.aix/roles/<file>`
- `workflow` -> `.aix/workflows/<file>`
- `hook` -> `.aix/hooks/<file>`
- `docs` -> `docs/...` (from registry subpath)
- `ci` -> `.aix/ci/<file>`
- `script` -> `.aix/scripts/<file>`

## Output

Provide a concise report:
- Current AIX version vs framework version
- New capabilities available for the current tier
- Files to add, update, or review
- A proposed change plan
