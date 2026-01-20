# Tech Stack

> This document defines **how** you're building - the technologies and patterns used.

## Overview

| Layer | Technology | Version |
|-------|------------|---------|
| Runtime | [Node.js / Python / Go / etc.] | [version] |
| Framework | [React / Next.js / FastAPI / etc.] | [version] |
| Database | [PostgreSQL / MongoDB / SQLite / etc.] | [version] |
| Styling | [Tailwind / CSS Modules / etc.] | [version] |
| Testing | [Jest / Vitest / Pytest / etc.] | [version] |

## Architecture

### Pattern
[Monolith / Microservices / Serverless / etc.]

### Structure
```
project/
├── src/
│   ├── components/    # [Description]
│   ├── services/      # [Description]
│   ├── utils/         # [Description]
│   └── ...
├── tests/
└── ...
```

## Key Dependencies

### Core
| Package | Purpose |
|---------|---------|
| [package-name] | [Why you need it] |
| [package-name] | [Why you need it] |

### Development
| Package | Purpose |
|---------|---------|
| [package-name] | [Why you need it] |
| [package-name] | [Why you need it] |

## Development Environment

### Prerequisites
- [Requirement 1, e.g., Node.js 20+]
- [Requirement 2, e.g., Docker]

### Setup
```bash
# Clone and install
git clone [repo]
cd [project]
[package-manager] install

# Start development
[command to start dev server]
```

### Environment Variables
| Variable | Purpose | Required |
|----------|---------|----------|
| `DATABASE_URL` | Database connection | Yes |
| `API_KEY` | External API access | No |

## Code Standards

### Language
- [TypeScript / JavaScript / Python / etc.]
- [Strict mode? Type checking?]

### Linting
- [ESLint / Prettier / Black / etc.]
- Config: [location]

### Formatting
- [Tabs vs spaces, line length, etc.]

## Testing Strategy

### Unit Tests
- Framework: [Jest / Vitest / Pytest]
- Location: `[path]`
- Run: `[command]`

### Integration Tests
- Framework: [Same or different]
- Location: `[path]`
- Run: `[command]`

### E2E Tests (if applicable)
- Framework: [Playwright / Cypress / etc.]
- Location: `[path]`
- Run: `[command]`

## Deployment

### Target
[Vercel / AWS / Hetzner / Self-hosted / etc.]

### Process
[CI/CD? Manual? Describe the flow]

### Environments
| Environment | URL | Purpose |
|-------------|-----|---------|
| Development | localhost:3000 | Local dev |
| Staging | [url] | Testing |
| Production | [url] | Live |

## Constraints

### Performance
- [Target load times, bundle size limits, etc.]

### Browser Support
- [Modern only? IE11? Mobile?]

### Accessibility
- [WCAG level target]

## Decisions Log

Document significant technology decisions:

### [Decision Title]
- **Date**: [When decided]
- **Context**: [Why this came up]
- **Decision**: [What you chose]
- **Alternatives**: [What else you considered]
- **Rationale**: [Why this choice]

---

*Last updated: [Date]*
