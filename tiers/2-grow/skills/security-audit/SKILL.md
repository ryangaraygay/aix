---
name: security-audit
description: Codebase-wide security analysis including dependencies, secrets, and OWASP Top 10 vulnerabilities.
metadata:
  invocation: both
  inputs: |
    - scope: string (optional, default: all)
    - quick: boolean (optional, skip heavy scans, default: false)
  outputs: |
    - report: string (markdown format summary of vulnerabilities)
---

# Security Audit

Performs a comprehensive security scan of the codebase.

## Features

- **Dependency Audit**: Checks for known vulnerabilities in dependencies
- **Secret Detection**: Scans for accidentally committed secrets
- **Auth Flow Analysis**: Identifies unprotected routes and hardcoded credentials
- **Input Validation**: Detects endpoints missing validation
- **SAST (Static Analysis)**: Analyzes code for common security patterns (OWASP)

## Usage

```
/security-audit
/security-audit --quick
```

## Checks Performed

### 1. Dependency Vulnerabilities

```bash
# npm/yarn projects
npm audit --audit-level=high

# pnpm projects
pnpm audit --audit-level=high
```

### 2. Secret Detection

Look for patterns:
- API keys: `[A-Za-z0-9_]{20,}`
- AWS keys: `AKIA[0-9A-Z]{16}`
- Private keys: `-----BEGIN.*PRIVATE KEY-----`
- Passwords in config: `password\s*[:=]\s*['"][^'"]+['"]`

Files to check:
- `.env*` files (should be gitignored)
- Config files
- Source code

### 3. OWASP Top 10

| Category | What to Check |
|----------|---------------|
| Injection | Raw SQL, eval(), exec() |
| Broken Auth | Hardcoded credentials, weak tokens |
| Sensitive Data | Unencrypted storage, logging PII |
| XXE | XML parsing with external entities |
| Broken Access | Missing auth checks on routes |
| Misconfig | Debug mode in prod, default creds |
| XSS | Unescaped user input in HTML |
| Deserialization | Unsafe JSON.parse, pickle |
| Components | Known vulnerable dependencies |
| Logging | Insufficient audit trails |

### 4. Code Patterns to Flag

```javascript
// Dangerous patterns
eval(userInput)                    // Code injection
exec(command)                      // Command injection
innerHTML = userInput              // XSS
SELECT * WHERE id = ${userId}      // SQL injection
fs.readFile(userPath)              // Path traversal
```

## Output Format

```markdown
# Security Audit Report

**Date**: 2026-01-19
**Scope**: Full codebase

## Summary
| Severity | Count |
|----------|-------|
| Critical | 0     |
| High     | 2     |
| Medium   | 5     |
| Low      | 12    |

## Critical/High Findings

### H-001: Hardcoded API Key
- **File**: src/config/api.ts:23
- **Issue**: AWS access key exposed in source
- **Fix**: Move to environment variable

### H-002: SQL Injection Risk
- **File**: src/db/queries.ts:45
- **Issue**: String interpolation in SQL query
- **Fix**: Use parameterized queries

## Recommendations
1. [Priority actions]
2. [Secondary actions]
```

## Optional Tools

For deeper analysis, install:

- `trivy` - Container and filesystem scanning
- `gitleaks` - Git history secret detection
- `njsscan` - Node.js security scanner
- `semgrep` - Semantic code analysis
