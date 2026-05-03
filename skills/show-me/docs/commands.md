# Commands Reference

Full documentation for `show` and `look` commands.

## show - Display Content

Opens content for the user to view in the appropriate application.

```
Usage: show <target> [OPTIONS]

Targets:
  <file>                   Open file in Neovim
  <file>:<line>            Open file at specific line
  <file>:<start>-<end>     Highlight a line range (preferred for code sections)
  <file>#L<line>           Open file at specific line (URL fragment style)
  <file>#L<start>-<end>    Highlight a line range (URL fragment style)
  http://... https://...   Open URL in browser
  cmd:<command>            Run command in shell pane
  pane:<id>                Focus tmux pane by ID (cross-session)
  pane:self                Focus the current pane (agent self-focus)

Options:
  -s, --session NAME       Tmux session for show window (default: show)
  -p, --pane ID            Target specific pane ID
  --hold SECONDS           Hold visual focus for N seconds (default: 30)
  --no-focus               Don't switch focus to show window
  --no-zoom                Don't zoom the pane after showing
```

### Open files in Neovim

```bash
show README.md                    # Open file in Neovim
show src/main.py:42               # Open at line 42
show src/main.py:10-30            # Highlight lines 10-30 (preferred for code sections)
show src/main.py#L42              # Same as :42 (URL fragment style)
show src/main.py#L10-30           # Same as :10-30 (URL fragment style)
show ~/Code/project/config.yaml   # Absolute path
```

**Tip:** When showing a function, class, or block of code, use a range (`file:start-end`) rather than a single line. This gives the user full context without needing to scroll.

The show command:
- Uses nvim-remote to open files in existing Neovim instances
- Falls back to starting Neovim in the "show" tmux session
- Waits up to 3 seconds for Neovim socket to become available
- Supports line numbers in both `:N` and `#LN` formats

### Open URLs in browser

```bash
show https://github.com/owner/repo
show https://docs.python.org/3/library/asyncio.html
show github.com                   # Auto-adds https://
```

Opens in Firefox by default (falls back to system default browser).

### Run commands in shell pane

```bash
show "cmd:git status"             # Show git status
show "cmd:git diff HEAD~1"        # Show recent changes
show "cmd:ls -la"                 # List files
show "cmd:docker ps"              # Show running containers
show "cmd:pytest -v"              # Run tests with output
```

Commands run in the shell pane of the "show" tmux session, allowing the user to see live output.

### Focus specific pane

Focus works across tmux sessions -- if the target pane is in a different
session, show will switch the client to that session automatically.

```bash
show pane:15                      # Focus pane %15 (even in another session)
show pane:%23                     # With explicit % prefix
show pane:self                    # Focus agent's own pane (uses $TMUX_PANE)
```

The `pane:self` target is useful for multi-agent workflows where an agent
wants to pull the user's focus to its own tmux pane.

### Focus hold (visual conch)

When showing content, `--hold` tells VoiceMode auto-focus to not switch
away for the specified duration. This prevents the speaking agent from
yanking the user back before they've read what was shown.

```bash
show --hold 60 README.md          # Hold focus for 60s (long document)
show --hold 10 output.log         # Quick glance, 10s hold
show README.md                    # Default 30s hold
```

### Advanced options

```bash
show file.py -s dev               # Use "dev" session instead of "show"
show file.py -p %36               # Open in specific pane
show --no-focus file.py           # Open without switching focus
show --no-zoom file.py            # Open without zooming pane
```

## look - Observe Context

Captures what the user is currently viewing with tmux hierarchy and pane content.

```
Usage: look [OPTIONS] [TARGET]

Targets:
  (none)                   Current pane content
  %<id>                    Specific pane by ID
  %1,%2,%3                 Multiple panes (comma-separated)
  window                   All panes in current window
  <session>:<window>       All panes in specific window

Options:
  -l, --lines N            Lines of scrollback history (default: visible)
  -H, --hierarchy          Show tmux hierarchy only (no content)
  -p, --preserve-blanks    Preserve exact blank line spacing
```

### Basic observation

```bash
look                              # Current pane - visible screen
look -l 100                       # Last 100 lines of scrollback
look -l 500                       # More history for long output
```

### View tmux hierarchy only

```bash
look -H
```

Output example:
```
Tmux summary:
-> main: *claude[%15 %16], logs[%23] (attached)
  dev: editor[%30], tests[%31 %32]
  (in main:0 pane %15)
```

Legend:
- `->` indicates current session
- `*` indicates active window
- Pane IDs shown in brackets

### Multiple panes

```bash
look %15,%16                      # Two specific panes
look window                       # All panes in current window
look main:0                       # All panes in main session window 0
```

### Preserve formatting

```bash
look -p                           # Keep exact blank line spacing
look -p -l 50                     # With scrollback
```

### Output Format

The `look` command provides structured output:

```
Tmux summary:
-> main: *show[%15], claude[%16 %17] (attached)
  (in main:0 pane %15)

[Neovim detected in pane %15]
File: /Users/admin/project/src/main.py
Position: line 42, column 8
Mode: n
Tip: Use nvim-remote for full editor control

--- Pane %15 content ---
(Showing visible screen. Use -l 200 for more history)
[actual pane content here]
```

## Sensitive Content Detection

The `look` command automatically scans captured content for potentially sensitive information:

### Detected patterns

- Password assignments: `password = "..."`, `PASSWORD: ...`
- API keys: `api_key = "..."`, `API_KEY=...`
- Secrets/tokens: `secret = "..."`, `token = "..."`
- Long uppercase strings (20+ chars): Potential API keys
- Private keys: `-----BEGIN PRIVATE KEY-----`

### Warning output

When sensitive content is detected, look adds a warning:

```
Warning: Potential sensitive information detected
Consider reviewing before sharing. Use -H to show hierarchy only without content.
```

### Best practices

- Review output before sharing in logs or conversations
- Use `look -H` to get hierarchy without content when sensitive data may be present
- Be aware that terminal history may contain secrets from previous commands

## Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `SHOW_SESSION` | `show` | Default tmux session name for show window |
| `SHOW_BROWSER` | (auto) | Browser for URLs (e.g., `Firefox`, `Chrome`, `Safari`) |
| `SHOW_HOLD_SECONDS` | `30` | Default focus hold duration in seconds |
| `SHOW_FOCUS` | `true` | Switch focus to show window |
| `SHOW_ZOOM` | `true` | Zoom pane after showing content |
| `NVIM_SOCKET_PATH` | (auto) | Override Neovim socket path |

## Installation and Running Commands

### Finding the Commands

In normal use, `show` and `look` are on PATH and you call them as bare commands:

```bash
show <target>
look [options]
```

This works whether installed as a Claude Code plugin (which auto-adds `bin/` to the Bash tool's PATH) or via metool (which symlinks into `~/.metool/bin/`).

**Note:** The system has a `look` command (dictionary lookup) that may shadow this package's `look`. If `which look` resolves to `/usr/bin/look`, use the full path or reorder PATH.

### Checking Installation

```bash
which show look                                    # Check if in PATH
ls ~/.metool/bin/show ~/.metool/bin/look          # Check metool
ls ${CLAUDE_PLUGIN_ROOT}/bin/show                 # Check plugin (from inside Claude Code Bash tool)
```
