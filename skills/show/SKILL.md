---
name: show
description: Displays files, URLs, command output or your tmux pane for the user to see. Use whenever USER makes a request like "show me" or "show yourself"
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

**Tip:** Prefer ranges (`file:start-end`) over single lines for code.

## Implementation

```bash
${CLAUDE_PLUGIN_ROOT}/bin/show $ARGUMENTS
```
