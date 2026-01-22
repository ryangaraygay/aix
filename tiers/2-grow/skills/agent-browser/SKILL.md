---
name: agent-browser
description: Automates browser interactions for web testing, form filling, screenshots, and data extraction. Use for smoke tests, E2E testing, and replacing manual verification.
allowed-tools: Bash(agent-browser:*)
---

# Browser Automation with agent-browser

Browser automation skill for automated smoke tests, E2E testing, and verification workflows.

## Installation

```bash
# Install agent-browser CLI (Playwright-based)
npm install -g agent-browser

# Install browser dependencies
npx playwright install chromium
```

> **For remote/headless runners**: First run installs dependencies.
> Use `--resume` flag on subsequent runs to preserve installation.

## Quick Start

```bash
agent-browser open <url>        # Navigate to page
agent-browser snapshot -i       # Get interactive elements with refs
agent-browser click @e1         # Click element by ref
agent-browser fill @e2 "text"   # Fill input by ref
agent-browser close             # Close browser
```

## Core Workflow

1. Navigate: `agent-browser open <url>`
2. Snapshot: `agent-browser snapshot -i` (returns elements with refs like `@e1`, `@e2`)
3. Interact using refs from the snapshot
4. Re-snapshot after navigation or significant DOM changes

## Commands

### Navigation
```bash
agent-browser open <url>      # Navigate to URL
agent-browser back            # Go back
agent-browser forward         # Go forward
agent-browser reload          # Reload page
agent-browser close           # Close browser
```

### Snapshot (page analysis)
```bash
agent-browser snapshot            # Full accessibility tree
agent-browser snapshot -i         # Interactive elements only (recommended)
agent-browser snapshot -c         # Compact output
agent-browser snapshot -d 3       # Limit depth to 3
agent-browser snapshot -s "#main" # Scope to CSS selector
```

### Interactions (use @refs from snapshot)
```bash
agent-browser click @e1           # Click
agent-browser dblclick @e1        # Double-click
agent-browser focus @e1           # Focus element
agent-browser fill @e2 "text"     # Clear and type
agent-browser type @e2 "text"     # Type without clearing
agent-browser press Enter         # Press key
agent-browser press Control+a     # Key combination
agent-browser hover @e1           # Hover
agent-browser check @e1           # Check checkbox
agent-browser uncheck @e1         # Uncheck checkbox
agent-browser select @e1 "value"  # Select dropdown
agent-browser scroll down 500     # Scroll page
agent-browser scrollintoview @e1  # Scroll element into view
agent-browser drag @e1 @e2        # Drag and drop
agent-browser upload @e1 file.pdf # Upload files
```

### Get Information
```bash
agent-browser get text @e1        # Get element text
agent-browser get html @e1        # Get innerHTML
agent-browser get value @e1       # Get input value
agent-browser get attr @e1 href   # Get attribute
agent-browser get title           # Get page title
agent-browser get url             # Get current URL
agent-browser get count ".item"   # Count matching elements
agent-browser get box @e1         # Get bounding box
```

### Check State
```bash
agent-browser is visible @e1      # Check if visible
agent-browser is enabled @e1      # Check if enabled
agent-browser is checked @e1      # Check if checked
```

### Screenshots & PDF
```bash
agent-browser screenshot          # Screenshot to stdout
agent-browser screenshot path.png # Save to file
agent-browser screenshot --full   # Full page
agent-browser pdf output.pdf      # Save as PDF
```

### Wait
```bash
agent-browser wait @e1                     # Wait for element
agent-browser wait 2000                    # Wait milliseconds
agent-browser wait --text "Success"        # Wait for text
agent-browser wait --url "**/dashboard"    # Wait for URL pattern
agent-browser wait --load networkidle      # Wait for network idle
agent-browser wait --fn "window.ready"     # Wait for JS condition
```

### Semantic Locators (alternative to refs)
```bash
agent-browser find role button click --name "Submit"
agent-browser find text "Sign In" click
agent-browser find label "Email" fill "user@test.com"
agent-browser find first ".item" click
agent-browser find nth 2 "a" text
```

### Browser Settings
```bash
agent-browser set viewport 1920 1080      # Set viewport size
agent-browser set device "iPhone 14"      # Emulate device
agent-browser set geo 37.7749 -122.4194   # Set geolocation
agent-browser set offline on              # Toggle offline mode
agent-browser set media dark              # Emulate color scheme
```

### JavaScript
```bash
agent-browser eval "document.title"   # Run JavaScript
```

## Example: Smoke Test

```bash
# Navigate and verify page loads
agent-browser open https://example.com
agent-browser wait --load networkidle
agent-browser snapshot -i

# Check key elements exist
agent-browser is visible @e1  # Header
agent-browser is visible @e2  # Navigation

# Take screenshot for record
agent-browser screenshot smoke-test.png
agent-browser close
```

## Example: Form Submission Test

```bash
agent-browser open https://example.com/form
agent-browser snapshot -i
# Output: textbox "Email" [ref=e1], textbox "Password" [ref=e2], button "Submit" [ref=e3]

agent-browser fill @e1 "user@example.com"
agent-browser fill @e2 "password123"
agent-browser click @e3
agent-browser wait --load networkidle
agent-browser snapshot -i  # Check result
```

## Example: Authentication with Saved State

```bash
# Login once
agent-browser open https://app.example.com/login
agent-browser snapshot -i
agent-browser fill @e1 "username"
agent-browser fill @e2 "password"
agent-browser click @e3
agent-browser wait --url "**/dashboard"
agent-browser state save auth.json

# Later sessions: load saved state
agent-browser state load auth.json
agent-browser open https://app.example.com/dashboard
```

## Use in CI/Workflows

### Creating Versioned Smoke Tests

Create smoke test scripts in your repo:

```bash
# tests/smoke/login-flow.sh
#!/bin/bash
agent-browser open "$BASE_URL/login"
agent-browser snapshot -i
agent-browser fill @e1 "$TEST_USER"
agent-browser fill @e2 "$TEST_PASS"
agent-browser click @e3
agent-browser wait --url "**/dashboard"
agent-browser screenshot tests/smoke/screenshots/login-success.png
echo "Login smoke test passed"
```

### Running in CI

```yaml
# .github/workflows/smoke-tests.yml
- name: Run smoke tests
  run: |
    npm install -g agent-browser
    npx playwright install chromium
    ./tests/smoke/login-flow.sh
```

## Debugging

```bash
agent-browser open example.com --headed   # Show browser window
agent-browser console                     # View console messages
agent-browser errors                      # View page errors
agent-browser highlight @e1               # Highlight element
```

## JSON Output (for parsing)

```bash
agent-browser snapshot -i --json
agent-browser get text @e1 --json
```
