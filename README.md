# show-me — Claude Code Plugin

Visual context sharing between AI assistants and users.

Like Morpheus to Neo — "show me":
- **show**: AI displays content for the user (files in Neovim, URLs in browser, commands in tmux)
- **look**: AI observes what the user is viewing (screen context, active panes)

These are complementary - look verifies what show displayed.

## Requirements

### Required

- **tmux** - Terminal multiplexer for pane management and context capture
  - Used by both `show` and `look` commands
  - `show` creates a dedicated "show" session for content display
  - `look` captures pane content and displays hierarchy

### Optional Enhancements

- **nvim-remote** - Enhanced Neovim socket integration
  - Provides automatic socket detection and richer editor status
  - Without it: show-me uses calculated socket paths (works fine)
  - With it: More flexible socket discovery across multiple Neovim instances

- **Browser** - For URL display (Firefox preferred, configurable via SHOW_BROWSER)

## Installation

### Claude Code (and GitHub Copilot CLI)

> **Note:** GitHub Copilot CLI supports the same `--plugin-dir` flag — these instructions work for both tools.

Load directly from a local clone:

```bash
claude --plugin-dir /path/to/show-me
```

Or install via a marketplace that includes show-me:

```bash
/plugin marketplace add mbailey/plugins
/plugin install show-me@mbailey
```

### metool

```bash
mt package install show-me
```

## Commands

### show

Display content for the user:

```bash
show path/to/file.py          # Open file in Neovim
show path/to/file.py:42       # Open file at line 42
show https://example.com      # Open URL in browser
show "cmd:git status"         # Run command in shell pane
```

### look

Observe what the user is viewing:

```bash
look                          # Capture current pane context
look --hierarchy              # Show tmux session/window/pane layout
```

## Optional Integrations

### nvim-remote (optional)

If nvim-remote is available, show-me uses it for enhanced features:

- **Auto socket detection**: Finds the best Neovim socket automatically
- **Richer status**: More detailed editor state in `look` output

Without nvim-remote, show-me:
- Uses calculated socket paths: `/tmp/nvim-tmux-pane-<pane_id>`
- Uses direct `nvim --server` commands for file operations
- **All core features work fully**

## Privacy

The `look` command captures screen content. Use responsibly and only when contextually appropriate.

## Why not just a tmux skill?

Most of what `show` does today is implemented with tmux, so it's natural to
ask whether this should just be a tmux skill that agents drive directly.
We chose `show` as the user-facing verb on purpose:

- **It captures user intent, not implementation.** "Show me this thing" is
  the verb the user actually means. Whether the thing lands in tmux,
  Neovim, or a browser tab is incidental and may change.
- **It's a deliberately narrow safety surface.** `show` accepts a small
  set of targets — file, URL, `cmd:`, `pane:`, `diff` — and rejects
  everything else. Granting an agent permission to run `show` is
  meaningfully narrower than granting it raw tmux access (which can
  send keys to any pane, kill sessions, run arbitrary commands).
- **It spans multiple backends.** URLs go to a browser, files go to
  Neovim, panes are managed in tmux. A "tmux skill" wouldn't cover the
  browser/editor cases without bending the name out of shape.
- **A separate tmux skill exists for tmux itself.** When agents *do*
  need direct tmux help — debugging layouts, authoring scripts — the
  `tmux:tmux` skill covers that. The two are complementary, not
  redundant.

So `show-me` stays the user-verb skill and command surface; tmux stays
the underlying mechanism. The boundary between them is the safety
boundary.

## See Also

- [SKILL.md](skills/show-me/SKILL.md) - Claude Code skill for AI integration
