---
name: security-audit
description: Codebase-wide security analysis including dependencies, secrets, and OWASP Top 10 vulnerabilities.
compatibility: Requires npm/pnpm. Optional tools - trivy, gitleaks, njsscan for deeper analysis.
metadata:
  invocation: both
  inputs: |
    - scope: string (optional, all|backend|frontend, default: all)
    - quick: boolean (optional, skip heavy scans, default: false)
    - fix: boolean (optional, attempt auto-fix for dependencies, default: false)
  outputs: |
    - report: string (markdown format summary of vulnerabilities)
---

# Security Audit

Performs a comprehensive security scan of the codebase.

## Features

- **Dependency Audit**: Checks for known vulnerabilities in npm/pnpm dependencies
- **Secret Detection**: Scans for accidentally committed secrets (API keys, tokens, passwords)
- **Auth Flow Analysis**: Identifies unprotected routes and hardcoded credentials
- **Input Validation**: Detects endpoints missing validation and raw req.body usage
- **SAST (Static Analysis)**: Analyzes code for common security patterns (OWASP Top 10)
- **Container Scanning**: Checks Dockerfiles and images for vulnerabilities

## Usage

### Manual Execution

\`\`\`bash
# Run full audit
./scripts/security-audit.sh

# Quick mode (dependencies + secrets only)
./scripts/security-audit.sh --quick

# Specific scope
./scripts/security-audit.sh --scope backend

# Attempt auto-fix
./scripts/security-audit.sh --fix
\`\`\`

### AI Invocation

When invoked as a skill, the AI will:

1. Run dependency audit (\`npm audit\` or \`pnpm audit\`)
2. Scan for hardcoded secrets using regex patterns
3. Check for common OWASP vulnerabilities:
   - SQL injection patterns
   - XSS vulnerabilities
   - Command injection
   - Path traversal
   - Insecure deserialization
4. Analyze authentication patterns
5. Generate severity-classified report

## Checks Performed

### 1. Dependency Vulnerabilities

\`\`\`bash
# npm
npm audit --json

# pnpm
pnpm audit --json
\`\`\`

Checks against:
- NPM Advisory Database
- GitHub Security Advisories
- Snyk Vulnerability Database (if integrated)

### 2. Secret Detection

Scans for patterns like:
- API keys (\`api_key\`, \`apikey\`, \`API_KEY\`)
- Tokens (\`token\`, \`bearer\`, \`jwt\`)
- Passwords (\`password\`, \`passwd\`, \`secret\`)
- AWS credentials (\`AKIA\`, \`aws_secret\`)
- Private keys (\`-----BEGIN.*PRIVATE KEY-----\`)

Files excluded:
- \`node_modules/\`
- \`.env.example\`, \`.env.template\`
- Test fixtures with known fake values

### 3. Auth Analysis

Checks for:
- Routes without authentication middleware
- Hardcoded credentials in source
- JWT without expiration
- Weak password policies

### 4. Input Validation

Scans for:
- Direct \`req.body\` usage without validation
- Missing sanitization on user input
- SQL string concatenation
- Shell command construction with user input

### 5. OWASP Top 10

| Category | Detection |
|----------|-----------|
| Injection | SQL/NoSQL/Command injection patterns |
| Broken Auth | Weak session management |
| XSS | Unescaped output, innerHTML usage |
| Insecure Direct Object Ref | Predictable IDs without auth |
| Security Misconfiguration | Debug mode, verbose errors |
| Sensitive Data Exposure | PII in logs, unencrypted storage |
| Missing Function Level Access | Admin routes without checks |
| CSRF | Forms without tokens |
| Known Vulnerabilities | Outdated dependencies |
| Unvalidated Redirects | Open redirect patterns |

## Output Format

\`\`\`markdown
## Security Audit Report

**Scope:** all
**Date:** 2025-01-20T10:30:00Z

### Dependency Vulnerabilities

| Package | Severity | CVE | Fix Available |
|---------|----------|-----|---------------|
| lodash | HIGH | CVE-2021-23337 | Yes (4.17.21) |

### Secret Detection

⚠️ 2 potential secrets found

| File | Line | Pattern |
|------|------|---------|
| src/config.ts | 45 | Hardcoded API key |

### Auth Analysis

✅ All routes protected

### Input Validation

⚠️ 3 issues found

| File | Line | Issue |
|------|------|-------|
| src/api/users.ts | 23 | Unvalidated req.body |

### Summary

- **Critical:** 0
- **High:** 1
- **Medium:** 2
- **Low:** 4

### Recommendations

1. Update lodash to 4.17.21
2. Move API key to environment variable
3. Add input validation middleware
\`\`\`

## Prerequisites

### Required

- Node.js with npm or pnpm

### Optional (for deeper analysis)

| Tool | Purpose | Installation |
|------|---------|--------------|
| gitleaks | Secret detection | \`brew install gitleaks\` |
| trivy | Container scanning | \`brew install trivy\` |
| njsscan | Node.js SAST | \`pip install njsscan\` |
| semgrep | Pattern matching | \`pip install semgrep\` |

## Integration

### CI Pipeline

\`\`\`yaml
security-audit:
  runs-on: ubuntu-latest
  steps:
    - uses: actions/checkout@v4
    - run: npm ci
    - run: npm audit --audit-level=high
    - run: npx gitleaks detect --no-git
\`\`\`

### Pre-commit Hook

\`\`\`bash
# .husky/pre-commit
./scripts/security-audit.sh --quick || {
  echo "Security issues found. Fix before committing."
  exit 1
}
\`\`\`

## See Also

- [OWASP Top 10](https://owasp.org/www-project-top-ten/)
- [npm audit documentation](https://docs.npmjs.com/cli/commands/npm-audit)
- [Audit Framework](../../docs/guides/audit-framework.md)
