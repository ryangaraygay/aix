# Subsystem Ownership

> Defines ownership boundaries to prevent architectural drift.

## Ownership Model

Each subsystem has a primary owner. Owners are responsible for:
- Architectural consistency within their domain
- Reviewing changes that cross boundaries
- Keeping related docs updated

## Ownership Map

| Subsystem | Owner | Paths | Allowed Dependencies | Review Required |
|-----------|-------|-------|----------------------|-----------------|
| [name] | [team/role] | [src/... ] | [list] | [Yes/No] |

## Cross-Boundary Rules

- [Example: Any changes touching 2+ subsystems require integration review]
- [Example: Shared models live in src/shared and are owned by Platform]

## How to Propose Changes

- [Process for adding/changing ownership boundaries]
- [Where to document new decisions]

---

*Last updated: [Date]*
