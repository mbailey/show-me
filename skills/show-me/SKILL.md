---
name: show-me
description: Visual context sharing. LOAD when user says "show me", "open in browser", or "look at".
---

# show-me

Display content for users (files, URLs, commands) or observe their screen context.

The plugin ships two top-level commands:

- **`show-me`** — display content for the user (files in Neovim, URLs in a browser, commands in a tmux pane)
- **`look-at`** — observe what the user is currently viewing (screen context, active panes)

## Quick Reference

| Command | Example | Description |
|---------|---------|-------------|
| `show-me <file>` | `show-me README.md:42` | Open file in Neovim at line |
| `show-me <file>` | `show-me main.py:10-20` | Open file highlighting line range |
| `show-me <url>` | `show-me github.com` | Open URL in browser |
| `show-me "cmd:..."` | `show-me "cmd:git log"` | Run command in shell pane |
| `show-me pane:self` | `show-me pane:self` | **Agent self-focus** — pull the user's focus to your own pane ("show yourself" / "where are you"). Uses `$TMUX_PANE` |
| `look-at` | `look-at -l 100` | Capture pane with last 100 lines of scrollback |
| `look-at -H` | `look-at -H` | Show tmux hierarchy only |

## When to Use

- User asks to open/display a file or URL (**For URLs: ALWAYS check Chrome MCP first**)
- User says "show me" or "look at my screen"
- User says "show yourself" / "where are you" / "I can't find you" (agent self-focus) → `show-me pane:self`
- Working in voice mode (hands-free interaction) — **highlight first, then narrate** the range you showed; see [Guided Voice Walkthroughs](references/walkthrough.md)
- Need to verify what user is viewing

## Showing URLs - Default Behavior

**URLs go to Chrome MCP by default. The `show-me` command is a fallback.**

### URL Navigation Decision Tree

```
User requests URL
    ↓
Check Chrome MCP available?
    ├─ Yes → navigate tool (interactive)
    └─ No  → show-me command (fallback)
```

### Standard Workflow

1. **Check**: `mcp__claude-in-chrome__tabs_context_mcp(createIfEmpty=true)`
2. **If available**:
   - Inform user: "Opening in Chrome - you may need to approve domain permissions"
   - Use `tabs_create_mcp` + `navigate` tools for interactive control
   - On timeout: "Chrome may be waiting for permission approval. Open in default browser instead?"
3. **If unavailable**: Use `show-me` command (opens default browser)

**Chrome MCP provides:**
- Interactive control (scroll, click, fill forms)
- Screenshots and page inspection
- Better for demos and automation

The `show-me` command is a fallback for when Chrome MCP is unavailable.

## Prefer Line Ranges Over Single Lines

When showing code to the user, **prefer ranges** (`file:start-end`) over single lines (`file:line`).

A single line rarely provides enough context. When pointing out a function, a bug, a block of logic, or a diff location, show the full range so the user sees the complete picture.

| Instead of | Use |
|------------|-----|
| `show-me main.py:42` | `show-me main.py:38-55` (show the whole function) |
| `show-me config.yaml:10` | `show-me config.yaml:8-15` (show the relevant block) |

**Rule of thumb:** If you know the start line, find where the section ends and use a range.

## Usage

**AI assistants:** Use bare `show-me` and `look-at` -- they're on PATH.

### show-me - Display Content

```bash
show-me README.md                    # Open file (uses user's default layout)
show-me src/main.py:42               # Open at line 42
show-me src/main.py:10-20            # Open highlighting lines 10-20 (preferred)
show-me bin/show-me#L124-162         # Highlight function (URL fragment syntax)
show-me https://github.com/repo      # Open URL
show-me "cmd:git status"             # Run command
show-me pane:15                      # Focus pane
show-me --hold 60 README.md          # Hold focus for 60s (visual conch)
show-me --layout right README.md     # Open in split pane to the right
show-me --here "cmd:make test"       # Split pane (default direction for type)
show-me --cwd /path/to/repo "cmd:make test"  # Run cmd: in a specific directory
show-me --format json "cmd:make"     # Run command, get a machine handle back
```

**`--cwd PATH`** runs a `cmd:` target in `PATH` instead of the caller's cwd
(wrapped as `cd -- "<PATH>" && <cmd>`). No-op for file/URL targets. A missing
directory is a hard error (`show-me: --cwd: no such directory: <PATH>`, no pane
created) — show-me never silently falls back to the caller's cwd.

**Layout:** You don't need to specify `--layout` — just call `show-me <target>`. The user's `SHOW_LAYOUT` env var controls where content appears. In split mode, subsequent file shows reuse the existing Neovim pane.

**Following up on a `cmd:` you ran.** The default human line ends with
`[pane %NN]`; `--format json` returns a one-line handle so you can inspect
the result instead of guessing:

```bash
show-me --format json "cmd:make test"
# {"pane":"%37","session":"main","window":"build","created":true,"status":"alive","cmd":"make test"}
tmux capture-pane -p -t %37        # read the output
```

Prefer `--format json` over scraping prose. Fields: `pane` (handle for
`tmux capture-pane`/`send-keys`), `session`/`window` (full names),
`created` (new vs reused), `status` (`alive`/`exited:<code>`/`unknown`),
`cmd`. See `references/commands.md` for the full reference.

### File Syntax Variants

All four forms are supported for specifying lines:

```bash
show-me file:line                    # Single line
show-me file:start-end               # Line range (preferred)
show-me file#Lline                   # URL fragment style
show-me file#Lstart-end              # URL fragment range
```

### look-at - Observe Context

```bash
look-at                              # Current pane
look-at -l 100                       # Last 100 lines
look-at -H                           # Hierarchy only
look-at %15,%16                      # Multiple panes
look-at window                       # All panes in window
```

## Documentation

- [Commands](references/commands.md) - Full command reference
- [Layouts](references/layouts.md) - Layout options and `SHOW_LAYOUT`
- [Guided Voice Walkthroughs](references/walkthrough.md) - Voice show-and-tell: the highlight-then-narrate loop, walkthrough etiquette, prepared tours
- [Troubleshooting](references/troubleshooting.md) - Common issues

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

# Step 3: If not connected or timeout, fall back to show-me command
show-me https://example.com
```

### Troubleshooting Chrome MCP

| Issue | Solution |
|-------|----------|
| `tabs_context_mcp` fails | Chrome extension not connected; use `show-me` command |
| Tab ID invalid | Call `tabs_context_mcp` to get fresh tab IDs |
| Extension disconnected mid-session | Graceful fallback to `show-me` command |
| No Chrome MCP tools available | MCP not configured; use `show-me` command |

### Setup

To use Chrome MCP:
1. Install the Claude-in-Chrome browser extension
2. Open Chrome and click the Claude extension icon
3. The extension connects to Claude Code via MCP

When the extension is not connected, `tabs_context_mcp` will fail, and you should fall back to the standard `show-me` command.

## Requirements

- **tmux**: Required for pane management
- **Neovim**: For file display (with socket support)
- **Browser**: For URL display (Firefox preferred, Chrome with MCP preferred for interactive control)
- **nvim-remote**: Optional, enhances Neovim integration
