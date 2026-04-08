---
name: look
description: "Captures the user's current screen context by reading tmux pane content, scrollback history, and window hierarchy. Use when the user says 'what's on my screen', 'look at my terminal', 'read my pane', 'check what I'm viewing', or when you need to observe the user's current terminal state before responding."
argument-hint: "[options] [target]"
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

```bash
${CLAUDE_PLUGIN_ROOT}/bin/look $ARGUMENTS
```
