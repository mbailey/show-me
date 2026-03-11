# show-me

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

### Claude Code

Load directly from a local clone:

```bash
claude --plugin-dir /path/to/show-me
```

Or install via a marketplace that includes show-me:

```bash
/plugin marketplace add <marketplace-source>
/plugin install show-me@<marketplace-name>
```

### GitHub Copilot CLI

```bash
copilot plugin install mbailey/show-me
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

## See Also

- [SKILL.md](SKILL.md) - Claude Code skill for AI integration
