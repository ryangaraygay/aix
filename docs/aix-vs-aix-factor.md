# AIX vs aix-factor: Strategy Analysis

*Planning document - not final decisions*

## The Question

Should AIX (local framework) and aix-factor (SaaS) be:
1. Same repo?
2. Separate repos with shared core?
3. aix-factor absorbs AIX entirely?

---

## What Each Is

| | AIX | aix-factor |
|---|-----|------------|
| **What** | Framework (constitution, roles, workflows, skills) | Service (orchestrator + compute) |
| **User** | Developer using Claude Code locally | User who wants spec → software |
| **Input** | Adopt progressively (tiers) | Upload product.md |
| **Compute** | Your machine / your Depot account | Managed (metered) |
| **Open source?** | Yes | Core yes, billing/auth maybe no |

---

## Relationship Models

### Model A: Monorepo
```
aix/
├── framework/        # The AIX framework (open source)
│   ├── tiers/
│   ├── adapters/
│   └── ...
├── factor/           # The aix-factor service
│   ├── orchestrator/
│   ├── api/
│   └── ...
└── docs/
```
**Pros**: Single source of truth, easy to keep in sync
**Cons**: Harder for community to contribute to just framework, versioning complexity

### Model B: Separate Repos, Shared Core
```
ryangaraygay/aix           # Framework (open source)
ryangaraygay/aix-factor    # Service (imports aix as dependency)
```
**Pros**: Clean separation, community contributes to framework, factor can move fast
**Cons**: Sync overhead, potential drift

### Model C: aix-factor Absorbs AIX
```
ryangaraygay/aix-factor    # Everything in one place
                           # Framework is just internal
```
**Pros**: Simplest, no sync issues
**Cons**: Lose community/halo effect, framework locked inside service

### Model D: AIX as Library, aix-factor as Consumer
```
aix = npm package / git submodule
aix-factor imports aix, adds orchestration layer
```
**Pros**: Cleanest separation, versioned dependency
**Cons**: More infrastructure to maintain

---

## Industry Precedents

| Framework | Managed Service | Relationship |
|-----------|-----------------|--------------|
| Kubernetes | GKE, EKS, AKS | Separate, K8s is CNCF open source |
| Docker | Docker Hub | Same company, different products |
| Terraform | Terraform Cloud | Same company, TF is open source |
| Next.js | Vercel | Same company, Next.js is open source |
| GitLab CE | GitLab EE/SaaS | Same repo, different editions |

**Pattern**: Framework is open source, service is commercial. Framework adoption drives service revenue.

---

## Halo Effect Analysis

**Benefits of open source AIX:**
- Developers discover AIX, some convert to aix-factor
- Community contributions improve the framework (which aix-factor uses)
- Credibility: "we use this ourselves"
- Talent pipeline: contributors become familiar with system
- Feedback loop: users report issues, suggest features

**Risks:**
- Maintenance burden
- Drift between framework and service
- Competitors fork and build competing services
- Community expects features that conflict with service direction

**Mitigation:**
- Clear governance (you're the maintainer, you decide)
- License choice (AGPL forces service competitors to open source)
- aix-factor uses released versions of AIX (not bleeding edge)
- Roadmap transparency

---

## Drift Risk Analysis

**What could drift:**
- Roles/workflows evolve differently for local vs cloud
- Skills that only make sense in one context
- Constitution rules that conflict

**How to prevent:**
- aix-factor CONSUMES AIX, doesn't fork it
- Any aix-factor-specific additions are in factor repo, not framework
- Regular sync: factor tests against AIX releases
- Clear boundary: AIX = what to do, factor = how to run it at scale

---

## Recommendation

**Model B: Separate Repos, Shared Core**

```
ryangaraygay/aix                    # Open source framework
├── tiers/                          # Progressive adoption
├── adapters/                       # Claude Code integration
├── docs/
└── LICENSE (MIT or AGPL?)

ryangaraygay/aix-factor             # Service (source-available or closed)
├── orchestrator/                   # Core logic
├── api/                            # Web API
├── cli/                            # Local CLI
├── defaults/                       # Default tech-stack, etc.
├── .aix/ → submodule or copy       # Uses AIX framework
└── LICENSE (commercial?)
```

**Why:**
1. AIX gets community love, contributions, adoption
2. aix-factor can move fast, iterate on service
3. Clean boundary: framework vs orchestration
4. Halo effect works: AIX users → aix-factor customers
5. AGPL on AIX protects against "take and compete"

---

## License Strategy

| Repo | License | Rationale |
|------|---------|-----------|
| AIX | AGPL-3.0 | Copyleft: competitors must open source their changes |
| aix-factor (orchestrator) | Source-available or proprietary | Protect the service business |
| aix-factor (CLI) | MIT | Let people run locally, drives adoption |

---

## Versioning Strategy

```
AIX releases: v1.0, v1.1, v2.0 (semver)
aix-factor pins to AIX version: "requires aix >= 1.0"

When AIX updates:
1. aix-factor tests against new version
2. If compatible, bump dependency
3. If breaking, document migration path
```

---

## Summary

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Separate repos? | **Yes** | Clean separation, community contribution |
| Maintain AIX? | **Yes** | Halo effect, contributions, credibility |
| Relationship | **aix-factor consumes AIX** | Framework stable, service iterates |
| AIX license | **AGPL-3.0** | Protects against competitors |
| Drift mitigation | **Versioned dependency + governance** | You control both |

---

## Open Questions

1. Should aix-factor CLI be in AIX repo or factor repo?
2. How to handle AIX features that only make sense for factor?
3. Contribution guidelines: what goes where?
4. When to cut AIX v1.0 stable release?

---

## License Deep Dive: Weighing Alternatives

### Option 1: MIT (Fully Permissive)

**What it means**: Anyone can use, modify, sell, close-source, no obligations.

| Pros | Cons |
|------|------|
| Maximum adoption - no friction | Competitors can take and build closed service |
| Enterprises love MIT (legal simplicity) | No protection, pure goodwill |
| More contributors (no license concerns) | Amazon/Google could "AWS it" |
| Community goodwill | Your contributions benefit competitors equally |

**Who does this**: React, Vue, Next.js, Tailwind

**Business model required**: Pure service differentiation (brand, speed, support). Framework is loss leader.

**Risk scenario**: BigCorp forks AIX, builds "AIX Enterprise" with proprietary features, doesn't contribute back.

---

### Option 2: AGPL-3.0 (Copyleft)

**What it means**: Anyone can use, but if they run it as a service, they must open source their changes.

| Pros | Cons |
|------|------|
| Protects against "cloud strip-mining" | Some enterprises avoid AGPL (legal complexity) |
| Competitors must open source their changes | Fewer casual contributors |
| Level playing field | "Scary" license perception |
| Community improvements come back | May slow initial adoption |

**Who does this**: MongoDB (was AGPL, now SSPL), Grafana, GitLab

**Business model**: Dual license (AGPL for open source, commercial for enterprises who want different terms).

**Risk scenario**: Slower adoption because enterprises hesitate. But competitors can't take without giving back.

---

### Option 3: Fully Closed Source

**What it means**: No public repo, proprietary, you control everything.

| Pros | Cons |
|------|------|
| Maximum control | Zero community contribution |
| No competitors can copy | No halo effect |
| All value captured | No free marketing/adoption |
| Simple (no license decisions) | "Black box" trust issues |

**Who does this**: Devin (Cognition), most enterprise SaaS

**Business model**: Pure SaaS, charge for everything.

**Risk scenario**: Slower growth, miss out on community innovation, no developer goodwill.

---

### Option 4: Source-Available (BSL, Elastic License, etc.)

**What it means**: Code is visible, but restricted commercial use. Often converts to open source after time delay.

| Pros | Cons |
|------|------|
| Transparency without exploitation | "Fake open source" criticism |
| Competitors can't run competing service | Community distrust |
| Can convert to open later | Complex license terms |
| Protects SaaS business model | Legal ambiguity in some cases |

**Who does this**: HashiCorp (BSL), Elastic, Sentry

**Business model**: Protect service revenue, allow self-hosting for non-competing uses.

---

### Comparison Matrix

| Factor | MIT | AGPL | Closed | Source-Available |
|--------|-----|------|--------|------------------|
| **Adoption speed** | 🟢 Fast | 🟡 Medium | 🔴 Slow | 🟡 Medium |
| **Community contributions** | 🟢 High | 🟡 Medium | 🔴 None | 🔴 Low |
| **Competitor protection** | 🔴 None | 🟢 Strong | 🟢 Total | 🟢 Strong |
| **Enterprise acceptance** | 🟢 High | 🟡 Medium | 🟢 High | 🟡 Medium |
| **Halo effect** | 🟢 High | 🟡 Medium | 🔴 None | 🔴 Low |
| **Legal simplicity** | 🟢 Simple | 🟡 Complex | 🟢 Simple | 🔴 Complex |

---

### Recommendation: AGPL + Dual License

**For AIX (framework):**
- Default: **AGPL-3.0**
- Offer commercial license for enterprises who want to embed without AGPL obligations

**For aix-factor (service):**
- Core orchestrator: **AGPL-3.0** (same as AIX, they're connected)
- Billing/auth/SaaS layer: **Proprietary** (doesn't need to be open)

**Why this combo:**
1. AGPL protects against cloud strip-mining
2. Dual license captures enterprise $ who want different terms
3. Community still gets full framework
4. Competitors can use but must contribute back
5. SaaS-specific code (billing) stays proprietary

---

### Dual License Model

```
┌─────────────────────────────────────────────────────────┐
│                         AIX                             │
│                                                         │
│   Open Source (AGPL-3.0)     Commercial License        │
│   ─────────────────────      ──────────────────        │
│   • Free                     • $X/year                 │
│   • Must share changes       • No AGPL obligations     │
│   • For open source use      • For closed products     │
│   • Community support        • Priority support        │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

**Who pays for commercial license:**
- Enterprises embedding AIX in proprietary tools
- Companies who don't want AGPL obligations
- Those wanting priority support/SLA

**Who uses AGPL:**
- Individual developers
- Open source projects
- aix-factor itself (you own both, no conflict)

---

### Decision Framework

| If you prioritize... | Choose |
|----------------------|--------|
| Maximum adoption | MIT |
| Community protection | AGPL |
| Maximum control | Closed |
| Transparency + protection | Source-Available |
| Adoption + protection | **AGPL + Dual License** |

---

---

## AGPL AIX + Closed aix-factor: No Conflict

### Why It Works

**You own both = you make the rules for yourself.**

AGPL only binds OTHER people using your code. As copyright holder:
- License AIX to public as AGPL ✅
- License AIX to yourself under any terms ✅
- Build closed aix-factor using your own AIX ✅

```
AGPL says: "If you use this in a network service, open source it"

But: Copyright holder can grant exceptions to themselves.

Result:
- Competitor uses AIX → must open source (AGPL applies)
- YOU use AIX in aix-factor → you grant yourself exception
```

### Industry Precedent

| Company | Open Source | Closed Service | Conflict? |
|---------|-------------|----------------|-----------|
| MongoDB | Server (SSPL) | Atlas | No |
| GitLab | CE (MIT) | EE + GitLab.com | No |
| Grafana | Grafana (AGPL) | Grafana Cloud | No |

### Contributor License Agreement (CLA)

**Caveat**: If others contribute to AIX, they hold copyright on their code.

**Solution**: CLA that grants you rights:
> "You grant us rights to use your contribution under any license,
> including in proprietary products."

Standard practice for all dual-license projects.

### Final License Structure

| Component | License | Notes |
|-----------|---------|-------|
| AIX framework | **AGPL-3.0** | Protects community |
| aix-factor service | **Closed** | Protects business |
| aix-factor CLI | **MIT** (optional) | Drives adoption |
| Contributions | **CLA required** | Enables dual licensing |

---

## What's Next to Plan

1. **Boundary definition**: What goes in AIX vs aix-factor?
2. **aix-factor MVP scope**: Minimum for first paying customer
3. **Sequencing**: Build order, dependencies
4. **Pricing model**: How to charge for aix-factor

---

## Boundary Definition: AIX vs aix-factor

### Core Principle

> **AIX = What to do (framework)**
> **aix-factor = How to run it at scale (service)**

### Detailed Breakdown

| Component | AIX | aix-factor | Rationale |
|-----------|-----|------------|-----------|
| Constitution (CLAUDE.md) | ✅ | uses | Core framework |
| Roles (analyst, coder, reviewer...) | ✅ | uses | Core framework |
| Workflows (feature, quick-fix...) | ✅ | uses | Core framework |
| Skills (audit, test, docs...) | ✅ | uses | Core framework |
| Tiers (seed → scale) | ✅ | n/a | Local adoption path |
| Claude Code adapter | ✅ | uses | Integration layer |
| bootstrap.sh, upgrade.sh | ✅ | n/a | Local setup |
| --- | --- | --- | --- |
| Orchestrator (planning, spawning) | | ✅ | Service logic |
| Depot/compute integration | | ✅ | Service infrastructure |
| API (REST endpoints) | | ✅ | Service interface |
| CLI (`aix-factor run`) | | ✅ | Service client |
| Defaults (tech-stack, design) | | ✅ | Service convenience |
| Web UI | | ✅ | Service interface |
| Auth, billing, users | | ✅ | Service business |
| Board integrations (later) | | ✅ | Service feature |

### Visual

```
┌─────────────────────────────────────────────────────────────┐
│                         AIX (AGPL)                          │
│                                                             │
│  ┌───────────┐ ┌───────────┐ ┌───────────┐ ┌───────────┐  │
│  │Constitution│ │   Roles   │ │ Workflows │ │  Skills   │  │
│  └───────────┘ └───────────┘ └───────────┘ └───────────┘  │
│                                                             │
│  ┌───────────┐ ┌───────────┐                               │
│  │   Tiers   │ │ Adapters  │  (Claude Code, future: others)│
│  └───────────┘ └───────────┘                               │
│                                                             │
└─────────────────────────────────────────────────────────────┘
                              │
                         consumes
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                     aix-factor (Closed)                     │
│                                                             │
│  ┌───────────┐ ┌───────────┐ ┌───────────┐                │
│  │Orchestrator│ │    API    │ │    CLI    │                │
│  └───────────┘ └───────────┘ └───────────┘                │
│                                                             │
│  ┌───────────┐ ┌───────────┐ ┌───────────┐                │
│  │ Defaults  │ │  Compute  │ │  Web UI   │                │
│  │(tech,design)│ │ (Depot)   │ │           │                │
│  └───────────┘ └───────────┘ └───────────┘                │
│                                                             │
│  ┌───────────┐ ┌───────────┐                               │
│  │   Auth    │ │  Billing  │  (SaaS layer)                 │
│  └───────────┘ └───────────┘                               │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### Gray Areas (Decisions Needed)

| Component | Option A (AIX) | Option B (aix-factor) | Recommendation |
|-----------|----------------|----------------------|----------------|
| **Feature spec template** | Generic template | Opinionated defaults | AIX (generic), factor adds defaults |
| **Meta-orchestrator prompt** | Generic guidance | Full implementation | AIX (guidance), factor (implementation) |
| **Board adapters** | Interface only | Full implementations | AIX (interface), factor (implementations) |
| **Compaction hooks** | Generic hooks | Cloud-specific | AIX (local), factor (cloud version) |

### Dependency Direction

```
aix-factor ──depends on──▶ AIX

Never:
AIX ──depends on──▶ aix-factor
```

AIX must work standalone. aix-factor adds value on top.

---

## aix-factor MVP Scope

### Minimum for First Value

| Must Have | Nice to Have | Later |
|-----------|--------------|-------|
| Product.md input | Web UI | Board integrations |
| Planning session (feature breakdown) | Multiple defaults | Linear/Jira adapters |
| Single feature team | Parallel teams | User auth |
| Depot compute | Self-hosted option | Billing |
| PR output | Preview deploys | Team collaboration |
| CLI trigger | API trigger | |

### MVP User Journey

```
1. User has: product.md, GitHub repo, Depot account (or uses ours)

2. User runs:
   $ aix-factor run --repo github.com/user/project product.md

3. aix-factor:
   a. Clones repo
   b. Runs planning session → creates specs/features/*.md
   c. For each feature: runs implementation session
   d. Creates PRs

4. User reviews PRs, merges

5. (Later: auto-deploy, preview URLs, etc.)
```

### MVP Architecture

```
┌──────────────────────────────────────────────┐
│              aix-factor MVP                  │
│                                              │
│  cli.py                                      │
│    │                                         │
│    ▼                                         │
│  orchestrator.py                             │
│    │                                         │
│    ├── run_planning_session()                │
│    │     └── depot claude "break down spec"  │
│    │                                         │
│    └── run_feature_session(feature)          │
│          └── depot claude "implement X"      │
│                                              │
│  .aix/ (copied from AIX framework)           │
│    ├── constitution.md                       │
│    ├── roles/                                │
│    ├── workflows/                            │
│    └── skills/                               │
│                                              │
└──────────────────────────────────────────────┘
```

---

## Build Sequencing

| Phase | What | Output | Validates |
|-------|------|--------|-----------|
| **0** | Finalize AIX framework (extract from ebblyn/.ai) | Clean AIX repo | Framework works standalone |
| **1** | Create aix-factor repo, copy AIX | Skeleton | Separation works |
| **2** | Orchestrator core (planning + 1 team) | `orchestrator.py` | End-to-end flow |
| **3** | CLI wrapper | `aix-factor run` | User interface |
| **4** | Test on simple spec (L1) | Working app from spec | Core value |
| **5** | Parallel teams | Multiple features at once | Scale |
| **6** | API + Web UI | Non-CLI access | SaaS ready |
| **7** | Auth + billing | Monetization | Business |

### Current Status

- [x] AIX framework exists (in this repo, needs cleanup)
- [x] Vision doc written
- [x] Depot validated with ebblyn/.ai
- [ ] **Phase 0**: Extract clean AIX from ebblyn/.ai
- [ ] Phase 1-7: aix-factor

---

## Pricing Model (Brainstorm)

### Options

| Model | How It Works | Pros | Cons |
|-------|--------------|------|------|
| **Usage-based** | $/feature or $/session | Fair, scales with value | Hard to predict costs |
| **Subscription** | $/month for N features | Predictable | May not match value |
| **Hybrid** | Base + overage | Predictable + fair | Complex |
| **Compute pass-through** | Depot cost + margin | Transparent | Low margin |

### Comparison to Market

| Competitor | Pricing |
|------------|---------|
| Devin | $500/mo enterprise, $20/mo Devin 2.0 |
| Replit Agent | $25-200/mo based on plan |
| Lovable | $25-100/mo based on credits |

### Initial Recommendation

**Hybrid: Subscription + usage**

```
Free tier:     1 project, 3 features/month (validate product)
Pro:           $49/mo, 20 features/month, then $2/feature
Team:          $199/mo, 100 features/month, then $1.50/feature
Enterprise:    Custom
```

**Why:**
- Free tier gets users in door
- Subscription covers base costs
- Usage captures value from heavy users
- Simpler than pure usage (predictable-ish)

---

## Open Questions

1. **Phase 0 scope**: What exactly needs extraction/cleanup from ebblyn/.ai?
2. **Defaults**: What tech stack/design system for MVP defaults?
3. **Depot account**: Users bring their own vs managed pool?
4. **Feature sizing**: How does orchestrator know when a feature is "too big"?

---

---

## Phase 0: Gap Analysis - AIX vs ebblyn/.ai

### Overview (Refined)

| Component | ebblyn/.ai | Current AIX | Gap | Action |
|-----------|------------|-------------|-----|--------|
| **Roles** | 10 roles (400-600 lines) | 7 roles (100-200 lines) | 2 missing + depth | Extract debug, product-designer; expand all |
| **Workflows** | 4 workflows | 3 workflows | 1 missing + depth | Extract refactor; enhance feature/quick-fix |
| **Skills** | 35 skills | 3 skills | ~7 core to extract | Focus on audits, agent-browser |
| **Hooks** | Compaction hooks | None | Missing | Extract to Tier 3 |
| **Scripts** | Worktree setup/cleanup | In Tier 3 | ✅ | Already present |

**Removed from extraction**: `test` (deprecated), `sync-roles` (Claude Code only), `intake` (unused)

---

### Skills Gap Analysis

#### Category A: Generic - Extract to AIX

| Skill | Purpose | AIX-local | aix-factor | Notes |
|-------|---------|-----------|------------|-------|
| **agent-browser** | Browser automation | ✅ | ✅ | Needs Playwright; Depot: install on first run, `--resume` preserves |
| **wrap-up** | Session health check | ✅ | ❌ | Interactive mode only |
| **pr-merged** | Post-merge summary | ✅ | ✅ | Review for generalization |
| **dev-start** | Start local dev env | ✅ | ❌ | Local only |
| **promote** | Release branch, version bump | ✅ | ✅ | Review for generalization |
| **deploy** | Deploy to production | ✅ | ✅ | Review for generalization |
| **reflect** | Session retrospective | ✅ | Later | For system self-improvement |
| ~~test~~ | ~~Run test suite~~ | ❌ | ❌ | **REMOVED** - deprecated, never used |
| ~~sync-roles~~ | ~~Multi-adapter sync~~ | ❌ | ❌ | **REMOVED** - Claude Code only focus |

#### Category B: Audit Frameworks

All follow same pattern: collect metrics → apply rules → generate report → suggest fixes.

| Skill | Purpose | Core/Optional |
|-------|---------|---------------|
| **quality-audit** | Module size, complexity, coverage | **Core** |
| **security-audit** | OWASP, dependencies, secrets | **Core** |
| **performance-audit** | Bundle size, API latency, DB queries | **Core** |
| **accessibility-audit** | WCAG AA, keyboard nav, focus | Optional |
| **privacy-audit** | PII detection, local-first | Optional |
| **cognitive-audit** | Miller's Law, decision fatigue | Optional |
| **delight-audit** | Brand voice, empty states | Optional |
| **resilience-audit** | Offline, state recovery | Optional |

**Recommendation**: Create `AuditFramework` base class in AIX. Core audits in main tier, optional audits as extras.

#### Category C: Task Management - Extract as Interfaces (15 skills)

Generic patterns that need abstraction layer for multiple providers (Ebblyn, Linear, Jira, GitHub Projects):

| Skill | Pattern | Interface |
|-------|---------|-----------|
| ebblyn-get-task | Task retrieval/search | `TaskQuery` |
| ebblyn-create-task | Task creation | `TaskCreation` |
| ebblyn-update-task | Task modification | `TaskUpdate` |
| ebblyn-start-task | Task lifecycle start | `TaskLifecycle.start()` |
| ebblyn-close-task | Task lifecycle end | `TaskLifecycle.close()` |
| ebblyn-comment-task | Task comments | `TaskComments` |
| ebblyn-attach-task | File/image attachments | `TaskAttachments` |
| ebblyn-relate-task | Task relations | `TaskRelations` |
| ebblyn-priorities | Priority calculation | `TaskPrioritization` |
| ebblyn-organize | Board health analysis | `BoardHealth` |
| ebblyn-align | Strategic alignment | `StrategicAlignment` |
| ebblyn-batch-update | Bulk operations | `BulkOperations` |
| ebblyn-batch-reorder | Card ordering | `CardOrdering` |
| ebblyn-board-structure | Board structure query | `BoardQuery` |
| ebblyn-setup-docs-board | Wiki setup | `WikiSetup` |

**Recommendation**: Define `TaskManager` interface in AIX. Implementations stay in aix-factor.

#### Category D: System-Specific Adapters (3 skills)

| Skill | System | AIX Action |
|-------|--------|------------|
| review-permissions | Claude Code | Keep (Claude Code only focus) |
| triage-production | Glitchtip | Extract pattern, support multiple monitoring |
| docs-update | Wiki | Extract pattern, support multiple wiki systems |

---

### Roles Gap Analysis

#### Missing Roles (Need to create in Tier 3)

| Role | Purpose | Lines in Ebblyn | Why Important |
|------|---------|-----------------|---------------|
| **debug** | Systematic bug investigation | 456 | 7-step methodology, hypothesis ranking, TDD-mandatory |
| **product-designer** | Pre-implementation ideation | 503 | Bridges user ideas → technical planning |
| ~~intake~~ | ~~Fast feedback capture~~ | ~~267~~ | **REMOVED** - rarely used in practice |

#### Existing Roles - Enhancement Needed

| Role | Current AIX | Ebblyn | Key Additions Needed |
|------|-------------|--------|----------------------|
| **analyst** | 135 lines | 643 lines | Infrastructure isolation, delivery surfaces, DB migration analysis, multidimensional analysis |
| **coder** | 165 lines | 477 lines | Prisma guidance, module size limits, security checklist, test spec verification |
| **reviewer** | 230 lines | 380 lines | Verification requirements, test type checking, TDD compliance, delivery surfaces |
| **tester** | 190 lines | 408 lines | Edge case taxonomy, coverage recovery, loop awareness, flaky test prevention |
| **docs** | 215 lines | 341 lines | Internal vs external branching, wiki hierarchy, card lifecycle |
| **triage** | 160 lines | 199 lines | Reproduction validation, duplicate search, severity classification |
| **orchestrator** | 160 lines | 342 lines | Database sharing logic, approval gates, debt logging, skills invocation |

---

### Workflows Gap Analysis

#### Missing Workflow

| Workflow | Purpose | Priority |
|----------|---------|----------|
| **refactor.md** | Infrastructure/architecture changes (optional triage, no manual verify, internal docs only) | HIGH |

#### Feature Gaps in Existing Workflows

| Gap | AIX-local | aix-factor | Priority |
|-----|-----------|------------|----------|
| **Manual verification gate** | ✅ Yes (interactive) | ❌ No (autonomous) | HIGH |
| **Process cleanup phase** | ✅ Yes | ❓ Depot unclear | MEDIUM |
| **TDD enforcement example** | ✅ Yes | ✅ Yes | MEDIUM |
| **Database isolation strategy** | Optional (shared OK) | **Strict** (proper seeding, no shared DB) | HIGH |
| **Infrastructure impact analysis** | ✅ Yes | ✅ Yes | MEDIUM |
| **Loop state tracking format** | ✅ Yes | ✅ Yes | MEDIUM |
| **Context compaction recovery** | ✅ Yes | N/A (session persistence) | LOW |

**Key difference**: aix-factor runs autonomously (no manual verification gate), but requires strict database isolation (no shared DB option like AIX-local allows).

---

## Phase 0 Extraction Checklist

### Phase 0a: Skills Extraction

**Core Skills (AIX-local):**
- [ ] Extract `wrap-up` skill → `tiers/2-grow/skills/wrap-up/` (interactive mode only)
- [ ] Extract `promote` skill → `tiers/2-grow/skills/promote/` (review for generalization)
- [ ] Extract `deploy` skill → `tiers/2-grow/skills/deploy/` (review for generalization)
- [ ] Extract `pr-merged` skill → `tiers/2-grow/skills/pr-merged/`
- [ ] Extract `reflect` skill → `tiers/3-scale/skills/reflect/` (later: system self-improvement)

**Browser Automation:**
- [ ] Extract `agent-browser` → `tiers/3-scale/skills/agent-browser/`
- [ ] Document: Playwright dependency, Depot `--resume` pattern for persistence

**Audit Framework:**
- [ ] Create audit framework base → `tiers/2-grow/skills/audit-framework/`
- [ ] Extract core audits: quality, security, performance
- [ ] Extract optional audits: accessibility, privacy, cognitive, delight, resilience → extras/

### Phase 0b: Task Management Interfaces

- [ ] Define `TaskManager` interface → `adapters/task-manager/interface.md`
- [ ] Define skill templates that use interface (provider-agnostic)
- [ ] Document: implementations stay in aix-factor or user's adapter

### Phase 0c: Roles

**New Roles:**
- [ ] Create `debug` role → `tiers/3-scale/roles/debug.md`
- [ ] Create `product-designer` role → `tiers/3-scale/roles/product-designer.md`

**Expand Existing (leverage ebblyn/.ai comprehensive content):**
- [ ] Expand `analyst` (135→400+ lines) - strip Ebblyn-specific, keep patterns
- [ ] Expand `coder` (165→300+ lines)
- [ ] Expand `reviewer` (230→350+ lines)
- [ ] Expand `tester` (190→300+ lines)
- [ ] Expand `docs` (215→300+ lines)
- [ ] Expand `triage` (160→200+ lines)
- [ ] Expand `orchestrator` (160→300+ lines)

### Phase 0d: Workflows

- [ ] Create `refactor` workflow → `tiers/2-grow/workflows/refactor.md`
- [ ] Add manual verification gate to `feature.md` (AIX-local only, conditional)
- [ ] Add TDD enforcement example to `quick-fix.md`
- [ ] Add database isolation section to `feature.md` (note: strict for aix-factor)
- [ ] Add infrastructure impact analysis to `feature.md`
- [ ] Update `_index.md` with loop state tracking format

### Phase 0e: Hooks & Scripts

- [ ] Add compaction hooks → `tiers/3-scale/hooks/`
- [ ] Verify worktree scripts work standalone

### Phase 0f: Documentation

- [ ] Update tier READMEs with new content
- [ ] Create skill development guide
- [ ] Create role customization guide
- [ ] Update CONTRIBUTING.md

---

## Extraction Priority Matrix

| Priority | Items | Rationale |
|----------|-------|-----------|
| **P0** | debug role, product-designer role, refactor workflow | Core gaps blocking real usage |
| **P1** | Core audits (quality/security/performance), expand analyst/reviewer/coder | Quality improvement |
| **P2** | Task manager interface, agent-browser | Extensibility, automation |
| **P3** | Remaining skills, optional audits, documentation | Polish |

---

## AIX-local vs aix-factor Behavior Matrix

| Feature | AIX-local | aix-factor |
|---------|-----------|------------|
| **Manual verification gate** | ✅ Interactive | ❌ Autonomous |
| **Database isolation** | Optional (shared OK) | **Strict** (seeding required) |
| **wrap-up skill** | ✅ Useful | ❌ N/A |
| **dev-start skill** | ✅ Useful | ❌ N/A |
| **Process cleanup** | ✅ Local processes | ❓ Depot handles |
| **Context compaction** | Hooks preserve state | Session persistence |
| **Playwright install** | Manual | Auto on first run, `--resume` preserves |

---

## Summary

The ebblyn/.ai system represents **~9,000+ lines of battle-tested patterns** that could accelerate AIX by 3-6 months if properly extracted and generalized.

**Key insights:**
1. Most of ebblyn/.ai IS generic - Ebblyn-specific parts are isolated in skills
2. Roles should leverage comprehensive ebblyn content (strip specifics, keep patterns)
3. AIX-local vs aix-factor have different requirements (interactive vs autonomous)
4. Depot session persistence (`--resume`) solves dependency installation for agent-browser

**Next step**: Begin Phase 0c with roles - extract `debug` and `product-designer`, then expand existing roles using ebblyn/.ai as source.
