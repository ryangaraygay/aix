# AIX Roadmap

> Known issues, planned improvements, and future ideas for AIX.

---

## Known Issues

### Husky Git Hooks Setup Gap

**Tier:** 1 (Sprout)
**Component:** `upgrade.sh`, `.husky/`
**Status:** Open

**Problem:**
The upgrade script adds `.husky/` directory with pre-commit hooks, but doesn't:
1. Check if `package.json` exists
2. Install husky as a dependency
3. Run `husky install` to register the hooks

**Impact:**
Git hooks don't work for projects that don't already have husky configured.

**Options:**
| Approach | Pros | Cons |
|----------|------|------|
| Use `.git/hooks/` directly | No dependencies, works everywhere | Harder to share (not in repo by default) |
| Create minimal `package.json` | Works with existing husky pattern | Assumes Node.js project |
| Conditional husky | Only add if `package.json` exists | Hooks missing for non-Node projects |
| Shell-based hook manager | Language agnostic | Another tool to learn |

**Recommendation:**
Check if `package.json` exists before adding `.husky/`. If not, either skip or use `.git/hooks/` directly with a setup script.

---

## Planned Improvements

_None currently tracked._

---

## Future Ideas

_None currently tracked._

---

## Contributing

To add items to this roadmap:
1. Open an issue in the repository
2. Reference the issue number here
3. Include: tier, component, status, problem, and recommended solution
