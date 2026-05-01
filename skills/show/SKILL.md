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

**Options:**
- `--layout VALUE` — Where to show content. Values: `right`, `below`, `left`, `above`, `window`, `stacked`
- `--here` — Show in a split pane beside the conversation (shorthand for content-type default direction)
- `--hold SECONDS` — Hold visual focus for N seconds (default: 30). Prevents VoiceMode auto-focus from switching away while the user reads.
- `--no-zoom` — Don't zoom the pane after showing (useful in split mode)

**Layout:** You don't need to specify `--layout` — the user's `SHOW_LAYOUT` env var controls the default. Just call `show <target>` and the right thing happens. Override with `--layout` only when you have a reason to.

**Tip:** Prefer ranges (`file:start-end`) over single lines for code.
**Tip:** In split mode, subsequent file shows reuse the existing Neovim pane instead of creating new splits.

## Implementation

`show` is already on PATH — for Bash tool calls, just run `show <target>` directly. No need for an absolute path (versioned plugin paths go stale on upgrade).

```bash
${CLAUDE_PLUGIN_ROOT}/bin/show $ARGUMENTS
```
