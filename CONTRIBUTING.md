# Contributing to AIX

Thank you for your interest in contributing to AIX! This document provides guidelines and instructions for contributing.

## Table of Contents

- [Code of Conduct](#code-of-conduct)
- [Getting Started](#getting-started)
- [How to Contribute](#how-to-contribute)
- [Development Setup](#development-setup)
- [Project Structure](#project-structure)
- [Contribution Types](#contribution-types)
- [Pull Request Process](#pull-request-process)
- [Style Guidelines](#style-guidelines)
- [License](#license)

## Code of Conduct

This project follows a standard code of conduct. Be respectful, inclusive, and constructive in all interactions.

## Getting Started

1. Fork the repository
2. Clone your fork: `git clone https://github.com/YOUR_USERNAME/aix.git`
3. Create a feature branch: `git checkout -b feat/your-feature`
4. Make your changes
5. Submit a pull request

## How to Contribute

### Reporting Issues

- Check existing issues before creating a new one
- Use the issue template if available
- Provide clear reproduction steps
- Include relevant context (OS, tool version, etc.)

### Suggesting Features

- Open an issue with the `enhancement` label
- Describe the use case and expected behavior
- Consider impact on existing users

### Code Contributions

- Follow the [pull request process](#pull-request-process)
- Include tests for new functionality
- Update documentation as needed

## Development Setup

AIX is a framework of markdown files and shell scripts. No build step required.

### Prerequisites

- Git
- Bash (for scripts)
- Optional: Claude Code CLI for testing

### Testing Changes

1. Create a test project:
   ```bash
   mkdir test-project && cd test-project
   git init
   ```

2. Bootstrap with your local AIX:
   ```bash
   /path/to/your/aix/bootstrap.sh
   ```

3. Test your changes

## Project Structure

```
aix/
├── tiers/                    # Progressive adoption tiers
│   ├── 0-seed/               # Foundation (constitution, core roles)
│   ├── 1-sprout/             # Growing (tester, docs, quick-fix)
│   ├── 2-grow/               # Established (CI, audits, feature workflow)
│   └── 3-scale/              # Complex (worktrees, compaction, strategy)
├── adapters/                 # Tool-specific integrations
│   ├── claude-code/          # Claude Code adapter
│   └── task-manager/         # Task management interface
├── docs/                     # Documentation
│   ├── guides/               # How-to guides
├── bootstrap.sh              # Initial setup script
└── upgrade.sh                # Tier upgrade script
```

## Contribution Types

### Roles

Roles define agent behavior. See [Role Customization Guide](docs/guides/role-customization.md).

- Location: `tiers/{tier}/roles/`
- Format: Markdown with structured sections
- Test: Use in a real project

### Skills

Skills are reusable tasks. See [Skill Development Guide](docs/guides/skill-development.md).

- Location: `tiers/{tier}/skills/{skill-name}/SKILL.md`
- Format: Agent Skills specification
- Test: Execute steps manually and with AI

### Workflows

Workflows coordinate multi-phase work.

- Location: `tiers/{tier}/workflows/`
- Format: Markdown with phases and decision points
- Test: Run through complete workflow

### Hooks

Hooks extend behavior at lifecycle events.

- Location: `tiers/{tier}/hooks/`
- Format: Shell scripts with JSON I/O
- Test: Trigger via Claude Code hooks

### Documentation

- Location: `docs/` or tier `README.md`
- Keep examples up to date
- Link to related content

## Pull Request Process

### Before Submitting

1. **Read existing docs**: Understand the patterns
2. **Check tier placement**: New content goes in appropriate tier
3. **Test changes**: Verify in a real project
4. **Update indexes**: Add to `_index.md` files

### PR Requirements

1. **Clear title**: `feat: add lint skill` or `docs: update role guide`
2. **Description**: What and why
3. **Testing**: How you verified the changes
4. **Documentation**: Update affected docs

### Review Process

1. Maintainer reviews within 1-2 weeks
2. Address feedback promptly
3. Once approved, maintainer merges

## Style Guidelines

### Markdown

- Use ATX headers (`#`, `##`, etc.)
- Code blocks with language specifier
- Tables for structured data
- Links between related docs

### Shell Scripts

```bash
#!/bin/bash
set -euo pipefail

# Clear comments
# Consistent formatting
```

### Naming

- Roles: lowercase with hyphens (`product-designer.md`)
- Skills: lowercase with hyphens (`security-audit/`)
- Workflows: lowercase with hyphens (`quick-fix.md`)

### Commit Messages

Follow conventional commits:

- `feat: add new skill`
- `fix: correct typo in analyst role`
- `docs: update CONTRIBUTING`
- `chore: reorganize folder structure`

## Adding New Tiers

New tiers should be discussed in an issue first. Tiers follow the progression:

1. **Seed**: Absolute essentials
2. **Sprout**: Quality basics
3. **Grow**: Team collaboration
4. **Scale**: Complex projects

## License

By contributing to AIX, you agree that your contributions will be licensed under the project's AGPL-3.0 license.

### Contributor License Agreement

For significant contributions, you may be asked to sign a CLA that grants the project maintainers rights to use your contribution under any license. This enables dual-licensing if needed.

## Questions?

- Open an issue for questions
- Check existing issues and documentation first
- Be patient - maintainers have other responsibilities

Thank you for contributing to AIX!
