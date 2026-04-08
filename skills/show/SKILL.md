---
name: show
description: "Opens files in Neovim at specific lines, launches URLs in the browser, runs commands in a shell pane, or focuses tmux panes for visual display. Use when the user says 'show me', 'display', 'open this file', 'view', 'show yourself', 'look at this URL', or needs to visually present content on screen."
argument-hint: <target>
---

# /show-me:show

Display content for the user in the appropriate application.

## Targets

- `<file>` or `<file>:<line>` or `<file>:<start>-<end>` — Open in Neovim
- `<file>#L<line>` or `<file>#L<start>-<end>` — URL fragment style
- `http://...` or `https://...` — Open URL in browser
- `cmd:<command>` — Run command in shell pane
- `pane:<id>` — Focus tmux pane
- `pane:self` — Focus the agent's own pane (use for "show yourself")

**Options:**
- `--hold SECONDS` — Hold visual focus for N seconds (default: 30). Prevents VoiceMode auto-focus from switching away while the user reads.

**Tip:** Prefer ranges (`file:start-end`) over single lines for code.

## Implementation

```bash
${CLAUDE_PLUGIN_ROOT}/bin/show $ARGUMENTS
```
