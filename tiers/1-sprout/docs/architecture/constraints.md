# Architecture Constraints

> Guardrails that keep the system consistent and maintainable.

## Invariants (Must Hold)

- [Example: All API routes live under src/api]
- [Example: No direct DB access from UI]

## Preferred Patterns

- [Example: Use repository pattern for data access]
- [Example: Event-driven side effects via job queue]

## Forbidden Patterns

- [Example: No global state outside store layer]
- [Example: Avoid circular imports between domains]

## Performance Constraints

- [Example: API p95 < 300ms]
- [Example: Client bundle < 300kb gz]

## Security Constraints

- [Example: All user inputs validated at boundary]
- [Example: No secrets in client code]

## Testing Requirements

- [Example: All new modules must include unit tests]
- [Example: Critical flows require integration tests]

## Compatibility Constraints

- [Example: Support last 2 major browser versions]
- [Example: Node 20+]

---

*Last updated: [Date]*
