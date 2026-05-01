---
name: show-me
description: Visual context sharing. LOAD when user says "show me", "open in browser", or "look at".
---

# show-me

Display content for users (files, URLs, commands) or observe their screen context.

## Quick Reference

| Command | Example | Description |
|---------|---------|-------------|
| `show <file>` | `show README.md:42` | Open file in Neovim at line |
| `show <file>` | `show main.py:10-20` | Open file highlighting line range |
| `show <url>` | `show github.com` | Open URL in browser |
| `show "cmd:..."` | `show "cmd:git log"` | Run command in shell pane |
| `look` | `look -l 100` | Capture pane content |
| `look -H` | `look -H` | Show tmux hierarchy only |

## When to Use

- User asks to open/display a file or URL (**For URLs: ALWAYS check Chrome MCP first**)
- User says "show me" or "look at my screen"
- Working in voice mode (hands-free interaction)
- Need to verify what user is viewing

## Showing URLs - Default Behavior

**URLs go to Chrome MCP by default. The `show` command is a fallback.**

### URL Navigation Decision Tree

```
User requests URL
    ↓
Check Chrome MCP available?
    ├─ Yes → navigate tool (interactive)
    └─ No  → show command (fallback)
```

### Standard Workflow

1. **Check**: `mcp__claude-in-chrome__tabs_context_mcp(createIfEmpty=true)`
2. **If available**:
   - Inform user: "Opening in Chrome - you may need to approve domain permissions"
   - Use `tabs_create_mcp` + `navigate` tools for interactive control
   - On timeout: "Chrome may be waiting for permission approval. Open in default browser instead?"
3. **If unavailable**: Use `show` command (opens default browser)

**Chrome MCP provides:**
- Interactive control (scroll, click, fill forms)
- Screenshots and page inspection
- Better for demos and automation

The `show` command is a fallback for when Chrome MCP is unavailable.

## Prefer Line Ranges Over Single Lines

When showing code to the user, **prefer ranges** (`file:start-end`) over single lines (`file:line`).

A single line rarely provides enough context. When pointing out a function, a bug, a block of logic, or a diff location, show the full range so the user sees the complete picture.

| Instead of | Use |
|------------|-----|
| `show main.py:42` | `show main.py:38-55` (show the whole function) |
| `show config.yaml:10` | `show config.yaml:8-15` (show the relevant block) |

**Rule of thumb:** If you know the start line, find where the section ends and use a range.

## Usage

**AI assistants:** Use bare `show` and `look` -- they're on PATH.

### show - Display Content

```bash
show README.md                    # Open file (uses user's default layout)
show src/main.py:42               # Open at line 42
show src/main.py:10-20            # Open highlighting lines 10-20 (preferred)
show bin/show#L124-162            # Highlight function (URL fragment syntax)
show https://github.com/repo      # Open URL
show "cmd:git status"             # Run command
show pane:15                      # Focus pane
show --hold 60 README.md          # Hold focus for 60s (visual conch)
show --layout right README.md     # Open in split pane to the right
show --here "cmd:make test"       # Split pane (default direction for type)
```

**Layout:** You don't need to specify `--layout` — just call `show <target>`. The user's `SHOW_LAYOUT` env var controls where content appears. In split mode, subsequent file shows reuse the existing Neovim pane.

### File Syntax Variants

All four forms are supported for specifying lines:

```bash
show file:line                    # Single line
show file:start-end               # Line range (preferred)
show file#Lline                   # URL fragment style
show file#Lstart-end              # URL fragment range
```

### look - Observe Context

```bash
look                              # Current pane
look -l 100                       # Last 100 lines
look -H                           # Hierarchy only
look %15,%16                      # Multiple panes
look window                       # All panes in window
```

## Documentation

- [Commands](docs/commands.md) - Full command reference
- [Voice Mode](docs/voice-mode.md) - Hands-free workflows
- [Troubleshooting](docs/troubleshooting.md) - Common issues

## Chrome Browser Integration (Reference)

This section provides additional details on Chrome MCP integration. **See "Showing URLs - Default Behavior" above for the primary workflow.**

### Chrome Domain Permissions

Chrome requires user approval for new domains (security feature).

**Best practices:**
- Before navigating: Inform user they may need to approve domain permissions
- On timeout: Explain likely cause - "Chrome may be waiting for permission approval"
- Offer fallback: "Would you like me to open in default browser instead?"

**Common issue:** If navigation times out, it's usually because the user didn't see or approve the Chrome domain permission prompt.

### Example: Show URL with Chrome MCP

```bash
# Step 1: Check if Chrome MCP is connected
# Call: mcp__claude-in-chrome__tabs_context_mcp(createIfEmpty=true)

# Step 2: If connected, inform user and navigate
# "Opening in Chrome - you may need to approve domain permissions"
# Call: mcp__claude-in-chrome__tabs_create_mcp (get a new tab)
# Call: mcp__claude-in-chrome__navigate with the URL and tabId

# Step 3: If not connected or timeout, fall back to show command
show https://example.com
```

### Troubleshooting Chrome MCP

| Issue | Solution |
|-------|----------|
| `tabs_context_mcp` fails | Chrome extension not connected; use `show` command |
| Tab ID invalid | Call `tabs_context_mcp` to get fresh tab IDs |
| Extension disconnected mid-session | Graceful fallback to `show` command |
| No Chrome MCP tools available | MCP not configured; use `show` command |

### Setup

To use Chrome MCP:
1. Install the Claude-in-Chrome browser extension
2. Open Chrome and click the Claude extension icon
3. The extension connects to Claude Code via MCP

When the extension is not connected, `tabs_context_mcp` will fail, and you should fall back to the standard `show` command.

## Requirements

- **tmux**: Required for pane management
- **Neovim**: For file display (with socket support)
- **Browser**: For URL display (Firefox preferred, Chrome with MCP preferred for interactive control)
- **nvim-remote**: Optional, enhances Neovim integration
