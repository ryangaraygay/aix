# Anti-Patterns to Avoid

> Common implementation mistakes that lead to technical debt, regressions, and maintenance burden. Review before implementing changes to existing code.

---

## 1. Code Duplication Across Implementations

**Mistake:** Creating multiple classes/modules that implement similar logic independently.

**Example:**
```typescript
// executor.ts
private buildPrompt(feature: Feature): string {
  return `# Feature: ${feature.name}\n...40 lines...`;
}

// daytona-executor.ts (DUPLICATE)
private buildPrompt(feature: Feature): string {
  return `# Feature: ${feature.name}\n...40 lines...`;  // Same logic!
}

// run-orchestrator.ts (TRIPLICATE)
private buildPrompt(feature: Feature): string {
  return `# Feature: ${feature.name}\n...40 lines...`;  // Same logic again!
}
```

**The Issue:** When logic needs to change, you must find and update all copies. Copies drift apart over time, creating inconsistent behavior.

**Prevention:**
- Extract shared logic to utility modules: `src/shared/prompt-builder.ts`
- Define interfaces and share implementations through composition
- Use `grep -r "functionName"` to check for duplicates before writing new code

**Detection:** Run `grep -r "methodName" src/` - if the same method appears in multiple files, extract it.

---

## 2. Interface Created But Not Implemented

**Mistake:** Defining an interface as part of architectural planning, then writing classes that don't actually implement it.

**Example:**
```typescript
// interfaces/feature-executor.ts
export interface FeatureExecutor {
  runFeature(feature: Feature, env: ExecutionEnvironment): Promise<FeatureResult>;
  runRemediation(failures: string[], env: ExecutionEnvironment): Promise<RemediationResult>;
}

// executor.ts - Does NOT implement FeatureExecutor
export class Executor {
  // Has same methods, but different signatures and no `implements` clause
  async runFeature(feature: Feature, previousFeatures: string[]): Promise<FeatureResult>
}

// daytona-executor.ts - Also does NOT implement FeatureExecutor
export class DaytonaExecutor {
  // Similar but incompatible method signatures
}
```

**The Issue:** The interface provides false confidence that swapping implementations is easy. In reality, the implementations have incompatible signatures and can't be used interchangeably.

**Prevention:**
- Always add `implements InterfaceName` to the class declaration
- TypeScript will enforce signature compatibility
- If the interface doesn't fit, update the interface, don't work around it

**Detection:** Search for interface definitions and verify each listed implementation actually uses `implements`.

---

## 3. Removing Existing Functionality During "Improvements"

**Mistake:** Simplifying or refactoring code and inadvertently dropping capabilities that existed in the original.

**Example:**
```typescript
// Original orchestrator.ts (531 lines) had:
// - B3: Retry logic with configurable categories
// - B5: Escalation parsing from session output
// - B7: Learnings collection across features
// - B8: Remediation loop with verification
// - Cost cap enforcement
// - State persistence for crash recovery

// New run-orchestrator.ts (491 lines) has:
// - Basic feature execution
// - PR creation
// - (Missing all B3-B8 capabilities!)
```

**The Issue:** The new "cleaner" code looks simpler, but lost battle-tested functionality. Users who depended on retry logic or learnings collection suddenly find features broken.

**Prevention:**
- **Capability Inventory**: Before modifying existing code, document all capabilities with file:line references
- **Spec must list preservation**: Acceptance criteria should include "all existing capabilities preserved"
- **If removing capability, explain in Out of Scope**: Make it explicit, not accidental

**Detection:** Compare line counts. If new version is significantly shorter, verify functionality wasn't lost.

---

## 4. Silent Fallbacks Instead of Explicit Rejection

**Mistake:** Falling back to a default value when input is invalid instead of rejecting it.

**Example:**
```typescript
// BAD - attacker's invalid URL silently becomes safe default
function getReturnUrl(input: string): string {
  if (!isValidUrl(input)) {
    return '/dashboard';  // Silent fallback masks the attack
  }
  return input;
}

// GOOD - invalid input is rejected explicitly
function getReturnUrl(input: string): string {
  if (!isValidUrl(input)) {
    throw new Error(`Invalid return URL: ${input}`);
  }
  return input;
}
```

**The Issue:** Silent fallbacks:
- Mask attack attempts (can't log/detect them)
- Hide bugs (invalid data flows through unnoticed)
- Make debugging harder (symptoms appear far from cause)

**Prevention:**
- Reject invalid input with errors, don't silently substitute defaults
- Log rejected inputs for security monitoring
- Only use defaults for truly optional/missing values, not malformed ones

---

## 5. Assuming "Small" Edits Are Safe

**Mistake:** Making "minor" changes and skipping verification because they seem trivial.

**Example:**
```typescript
// "Just deleting a few lines, what could go wrong?"
function processData(items: Item[]) {
  for (const item of items) {
    if (item.status === 'active') {
      // Deleted some code here...
    }  // <-- Oops, left a dangling brace
  }
}
```

**The Issue:** Even simple deletions can:
- Leave trailing commas that break syntax
- Leave unclosed braces `}` or parentheses `)`
- Remove error handling that was there for a reason
- Break control flow in subtle ways

**Prevention:**
- **Always run verification** (`npm run build`, `tsc --noEmit`) after every edit
- **Read the surrounding context** before deleting
- **Run tests** even for "trivial" changes

---

## 6. Committing Without Runtime Verification

**Mistake:** Committing after TypeScript compiles and tests pass, without actually running the application.

**Example:**
```bash
# Tests pass!
npm test  # ✅ 47 tests passing

# TypeScript compiles!
npm run build  # ✅ No errors

git commit -m "feat: add new filter"  # Committed!

# But in the browser:
# TypeError: Cannot read property 'filter' of undefined
```

**The Issue:** TypeScript and tests verify different things than runtime behavior:
- Tests often mock API calls that behave differently in reality
- TypeScript doesn't catch runtime nullability issues
- Build success doesn't mean the feature actually works

**Prevention:**
- **Test in browser/runtime** before committing
- **Make real API calls** (via curl or browser devtools)
- **Wait for manual verification** when implementing UI features

---

## Quick Reference

| Anti-Pattern | Detection | Prevention |
|--------------|-----------|------------|
| Code duplication | `grep -r "methodName"` | Extract to shared module |
| Interface not implemented | Search for `implements` | Add clause to class |
| Lost capabilities | Compare line counts | Capability inventory in spec |
| Silent fallbacks | Search for `|| default` | Throw errors for invalid input |
| Skipped verification | Review process | Always run build + tests |
| No runtime check | Review process | Manual verification before commit |

---

*Based on lessons learned from production incidents. Update this guide when new anti-patterns are discovered.*
