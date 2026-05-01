---
name: look
description: Observe what the user is currently viewing (screen context)
---

# /show-me:look

Capture what the user is currently viewing with tmux hierarchy and pane content.

## Targets

- (none) — Current pane content
- `%<id>` — Specific pane by ID
- `%1,%2,%3` — Multiple panes
- `window` — All panes in current window

## Options

- `-l, --lines N` — Lines of scrollback
- `-H, --hierarchy` — Hierarchy only (no content)
- `-p, --preserve-blanks` — Keep exact spacing

## Implementation

Run via the Bash tool. `look` is on PATH (Claude Code adds plugin `bin/` to PATH automatically; for other Agent Skill runtimes, the user must put `bin/look` on PATH themselves, e.g. via a symlink into `~/.local/bin`).

```bash
look [options] [target]
```
