---
name: privacy-audit
description: Privacy compliance verification including PII detection, local-first validation, and data retention checks.
compatibility: Requires grep/ast-grep for code analysis
metadata:
  invocation: both
  inputs: |
    - scope: string (optional, all|frontend|backend|database, default: all)
    - framework: string (optional, gdpr|ccpa|hipaa, default: gdpr)
  outputs: |
    - report: string (markdown privacy analysis)
    - pii_locations: array (files containing PII handling)
---

# Privacy Audit

Privacy compliance and data protection verification.

## Features

- **PII Detection**: Identify handling of personal data
- **Local-First Validation**: Verify data stays on device when expected
- **Data Retention**: Check for proper data lifecycle management
- **Consent Tracking**: Verify consent mechanisms
- **Third-Party Data Sharing**: Detect external data transmission

## Checks Performed

### 1. PII Detection

| Data Type | Pattern | Risk Level |
|-----------|---------|------------|
| Email addresses | `email`, `@`, regex patterns | Medium |
| Phone numbers | `phone`, `tel`, digit patterns | Medium |
| Names | `firstName`, `lastName`, `fullName` | Low |
| Addresses | `address`, `street`, `city` | Medium |
| SSN/ID numbers | `ssn`, `national_id`, digit patterns | Critical |
| Financial data | `creditCard`, `bankAccount` | Critical |
| Health data | `diagnosis`, `prescription` | Critical |

### 2. Local-First Compliance

| Check | Expected | Severity |
|-------|----------|----------|
| PII stored locally only | No server transmission | High |
| Encryption at rest | Local storage encrypted | High |
| No cloud sync without consent | Explicit opt-in | Critical |

### 3. Data Retention

| Check | Requirement |
|-------|-------------|
| Deletion mechanism exists | User can delete data |
| Retention period defined | Data not kept indefinitely |
| Automatic cleanup | Old data purged |

### 4. Third-Party Analysis

| Check | Detection |
|-------|-----------|
| Analytics scripts | Google Analytics, Mixpanel, etc. |
| Tracking pixels | Facebook, LinkedIn, etc. |
| CDN data exposure | External resource loading |
| API data sharing | PII in external API calls |

## Usage

```bash
# Full privacy audit
./scripts/privacy-audit.sh

# Specific framework
./scripts/privacy-audit.sh --framework hipaa

# Backend only
./scripts/privacy-audit.sh --scope backend
```

## Output Format

```markdown
## Privacy Audit Report

**Framework:** GDPR
**Date:** 2025-01-20

### PII Inventory

| Data Type | Locations | Storage | Transmission |
|-----------|-----------|---------|--------------|
| Email | 5 files | Local + Server | ⚠️ API calls |
| Name | 3 files | Local + Server | API calls |
| Phone | 1 file | Local only | ✅ None |

### Local-First Compliance

| Feature | Status | Notes |
|---------|--------|-------|
| Offline functionality | ✅ | Works without network |
| Local encryption | ⚠️ | Missing for user prefs |
| Sync consent | ✅ | Explicit opt-in |

### Third-Party Services

| Service | Data Shared | Consent Required |
|---------|-------------|------------------|
| Google Analytics | Page views | ✅ Cookie consent |
| Stripe | Payment info | ✅ Transaction consent |
| Sentry | Error logs | ⚠️ May contain PII |

### Data Retention

| Data | Retention | Deletion | Status |
|------|-----------|----------|--------|
| User accounts | Indefinite | Manual | ⚠️ Add auto-purge |
| Session logs | 30 days | Automatic | ✅ |
| Analytics | 2 years | Automatic | ✅ |

### Recommendations

1. **CRITICAL**: Encrypt user preferences in localStorage
2. **HIGH**: Scrub PII from Sentry error logs
3. **MEDIUM**: Add account deletion automation after 2 years inactivity
```

## Prerequisites

- grep or ast-grep for code analysis
- Understanding of applicable privacy framework

## See Also

- [Security Audit](../../2-grow/skills/security-audit/SKILL.md)
- [GDPR Requirements](https://gdpr.eu/checklist/)
- [Audit Framework](../../docs/guides/audit-framework.md)
