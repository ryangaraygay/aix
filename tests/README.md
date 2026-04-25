# Tests

Pytest-based tests for aix.

## Running

Set up a venv once:

```bash
python3 -m venv .venv
.venv/bin/pip install -r requirements-dev.txt
```

Then run tests:

```bash
.venv/bin/pytest tests/
```

If `python3 -m venv` fails on Debian/Ubuntu with a missing-pip error, install the venv extra: `sudo apt install python3-pip python3.12-venv` (adjust version to match your `python3 --version`).

## Adding a test

Drop a `test_*.py` file in this directory. Use the fixtures from `conftest.py`:

- `aix_source_repo` — fresh tmp git repo with `.aix/` symlinking into this checkout's tier-0 sources (constitution, roles, workflows, hooks) plus tier-1 skills (the lowest tier with real `SKILL.md` files). Use this when you need to invoke a generator from scratch.
- `cursor_generated` — same as above with `aix-generate.py --adapter cursor` already run; yields the repo path. Use this when inspecting generated cursor output.

## Test philosophy

Tests should target real failure modes — regressions of bugs we have actually seen or could plausibly hit. Examples in scope:

- Generator output shape (frontmatter keys, readonly heuristic per-role)
- Generator failure propagation (no silent failures that look like success)
- Symlink correctness (target resolves to a real file/dir)

Out of scope (vanity):

- "File exists" assertions without inspecting content
- "Doesn't crash" assertions without verifying side effects
- Mocking out the generator and unit-testing branches in isolation
