# Refactoring Patterns

> Safe patterns for modifying existing code without breaking functionality or creating technical debt.

---

## 1. Interface-First Extraction

**When to use:** Adding alternative implementations of existing functionality.

**Pattern:** Extract an interface from the existing implementation BEFORE creating new implementations.

### Why Interface-First?

```
❌ WRONG ORDER:
1. Create new implementation
2. Notice it's similar to existing code
3. Try to extract common interface after the fact
4. Discover signatures don't match
5. Force one or both to change

✅ RIGHT ORDER:
1. Extract interface from existing implementation
2. Make existing class implement interface
3. Verify existing tests still pass
4. Create new implementation of same interface
5. Both implementations are interchangeable
```

### Example: Adding Daytona Executor

**Step 1: Extract interface from existing code**

```typescript
// interfaces/feature-executor.ts
// Derived from existing Executor class

export interface FeatureExecutor {
  runFeature(
    feature: Feature,
    env: ExecutionEnvironment,
    previousFeatures?: string[]
  ): Promise<FeatureResult>;

  runRemediation(
    failures: string[],
    env: ExecutionEnvironment,
    attempt: number
  ): Promise<RemediationResult>;
}
```

**Step 2: Make existing class implement interface**

```typescript
// executor.ts
export class Executor implements FeatureExecutor {
  // TypeScript will error if signatures don't match
  async runFeature(
    feature: Feature,
    env: ExecutionEnvironment,
    previousFeatures?: string[]
  ): Promise<FeatureResult> {
    // existing code...
  }
}
```

**Step 3: Create new implementation**

```typescript
// daytona-executor.ts
export class DaytonaExecutor implements FeatureExecutor {
  // Must match interface exactly
  async runFeature(
    feature: Feature,
    env: ExecutionEnvironment,
    previousFeatures?: string[]
  ): Promise<FeatureResult> {
    // new implementation...
  }
}
```

### Checklist

- [ ] Interface extracted from existing implementation (not designed in abstract)
- [ ] Existing class has `implements InterfaceName`
- [ ] Existing tests pass without modification
- [ ] New class has `implements InterfaceName`
- [ ] Consumer code uses interface type, not concrete class

---

## 2. Shared Code in Utilities

**When to use:** Multiple implementations need the same helper logic.

**Pattern:** Extract shared logic to utility modules instead of duplicating.

### Signs You Need Extraction

- Same method appears in multiple files (`grep -r "methodName"` returns 2+ hits)
- Copy-pasting code "just to get it working"
- Two classes have methods with same name doing same thing

### Example: Prompt Building

**Before (duplicated):**

```typescript
// executor.ts
private buildPrompt(feature: Feature): string {
  return `# Feature: ${feature.name}\n...`;
}

// daytona-executor.ts
private buildPrompt(feature: Feature): string {
  return `# Feature: ${feature.name}\n...`;  // Duplicate!
}
```

**After (extracted):**

```typescript
// shared/prompt-builder.ts
export function buildFeaturePrompt(
  feature: Feature,
  mode: ExecutionMode,
  previousFeatures: string[]
): string {
  // Single source of truth
}

// executor.ts
import { buildFeaturePrompt } from './shared/prompt-builder';

private buildPrompt(feature: Feature): string {
  return buildFeaturePrompt(feature, this.mode, this.previousFeatures);
}

// daytona-executor.ts
import { buildFeaturePrompt } from './shared/prompt-builder';

private buildPrompt(feature: Feature): string {
  return buildFeaturePrompt(feature, this.mode, this.previousFeatures);
}
```

### Where to Put Shared Code

| Type | Location | Example |
|------|----------|---------|
| Pure functions | `src/shared/` or `src/utils/` | `buildPrompt`, `formatToolCall` |
| Shared types | `src/types/` or `src/interfaces/` | `FeatureResult`, `ExecutorConfig` |
| Base classes | `src/base/` | `BaseExecutor` with common methods |
| Constants | `src/constants/` | `DEFAULT_TIMEOUT`, `RETRY_CONFIG` |

### Checklist

- [ ] `grep -r "functionName"` returns single location
- [ ] Shared module has own tests
- [ ] Callers import from shared module, don't copy code
- [ ] Changes to shared logic are tested by all consumers

---

## 3. Strangler Fig Pattern

**When to use:** Gradual migration from old architecture to new.

**Pattern:** Run old and new implementations in parallel, gradually shift traffic, delete old when done.

### Why Strangler Fig?

Big-bang rewrites fail because:
- You can't test the new system until it's complete
- Requirements change during rewrite
- Old system keeps getting fixes that new system doesn't have

Strangler fig lets you:
- Deploy incremental improvements
- Validate new code with real traffic
- Roll back individual pieces

### Example: Migrating to Daytona

**Phase 1: Add new path alongside old**

```typescript
// orchestrator.ts
async run(config: RunConfig): Promise<RunResult> {
  if (config.executor === 'daytona') {
    return this.runWithDaytona(config);  // New path
  }
  return this.runWithLocal(config);  // Old path (default)
}
```

**Phase 2: Shift traffic gradually**

```yaml
# config.yaml
executor: local  # Start with 0% Daytona

# Later...
executor: daytona  # 100% Daytona after validation
```

**Phase 3: Remove old path after validation**

```typescript
// orchestrator.ts (after migration complete)
async run(config: RunConfig): Promise<RunResult> {
  return this.runWithDaytona(config);  // Only new path
}
// Delete runWithLocal method
```

### Checklist

- [ ] New path is behind feature flag or config
- [ ] Old path remains default until validation
- [ ] Metrics/logs distinguish old vs new path
- [ ] Rollback is one config change away
- [ ] Old code deleted only after new code proven in production

---

## 4. Behavioral Seams

**When to use:** Splitting large modules into smaller ones.

**Pattern:** Split at natural behavioral boundaries, not arbitrary line counts.

### Wrong: Splitting by Line Count

```typescript
// ❌ File has 600 lines, split at line 300
// Results in two files with random, interleaved responsibilities
```

### Right: Splitting by Behavior

```typescript
// ✅ Identify distinct behaviors:
// - Scheduling (which features run when)
// - Execution (running a single feature)
// - Reporting (tracking progress, generating summaries)

// Split into:
// scheduler.ts - scheduling logic
// executor.ts - execution logic
// reporter.ts - reporting logic
```

### Finding Behavioral Seams

1. **List the responsibilities** of the module
2. **Group related methods** by responsibility
3. **Identify dependencies** between groups
4. **Extract groups** with minimal cross-dependencies

### Example: Splitting Orchestrator

**Before (monolithic):**

```typescript
// orchestrator.ts (600 lines)
class Orchestrator {
  // Scheduling
  private getReadyFeatures(): Feature[] { }
  private checkDeadlock(): boolean { }
  private markDone(name: string): void { }

  // Execution
  private runFeature(feature: Feature): Promise<Result> { }
  private runRemediation(failures: string[]): Promise<Result> { }

  // Reporting
  private logProgress(completed: number, total: number): void { }
  private generateSummary(): Summary { }
  private writeToFile(path: string): void { }
}
```

**After (split by behavior):**

```typescript
// scheduler.ts
class Scheduler {
  getReadyFeatures(): Feature[] { }
  checkDeadlock(): boolean { }
  markDone(name: string): void { }
}

// executor.ts
class Executor {
  runFeature(feature: Feature): Promise<Result> { }
  runRemediation(failures: string[]): Promise<Result> { }
}

// reporter.ts
class Reporter {
  logProgress(completed: number, total: number): void { }
  generateSummary(): Summary { }
  writeToFile(path: string): void { }
}

// orchestrator.ts (now just coordination)
class Orchestrator {
  constructor(
    private scheduler: Scheduler,
    private executor: Executor,
    private reporter: Reporter
  ) { }

  async run(): Promise<Result> {
    // Coordinates the three components
  }
}
```

### Checklist

- [ ] Each extracted module has single responsibility
- [ ] Minimal dependencies between modules
- [ ] No circular dependencies
- [ ] Each module is independently testable
- [ ] Original tests still pass after extraction

---

## Quick Reference

| Situation | Pattern |
|-----------|---------|
| Adding alternative implementation | Interface-First Extraction |
| Same code in multiple places | Shared Code in Utilities |
| Replacing old system with new | Strangler Fig |
| Large file needs splitting | Behavioral Seams |

---

*These patterns prioritize safety over speed. Rushing refactors creates more technical debt than it resolves.*
