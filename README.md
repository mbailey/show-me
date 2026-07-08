# show-me — Claude Code Plugin

Visual context sharing between AI assistants and users.

Like Morpheus to Neo — "show me":
- **show-me**: AI displays content for the user (files in Neovim, URLs in browser, commands in tmux)
- **look-at**: AI observes what the user is viewing (screen context, active panes)

These are complementary - `look-at` verifies what `show-me` displayed.

## Quickstart

```bash
git clone https://github.com/mbailey/show-me.git
claude --plugin-dir show-me          # load the plugin for this Claude Code session
```

Claude Code adds the plugin's `bin/` to `PATH` automatically for the agent, so
`show-me` and `look-at` are ready to use immediately from Claude Code. To call
them yourself from a regular shell (or from another Agent Skill runtime that
doesn't do this for you), add `bin/` to your `PATH`, e.g. via a symlink into
`~/.local/bin`:

```bash
ln -s "$(pwd)/show-me/bin/show-me" ~/.local/bin/show-me
ln -s "$(pwd)/show-me/bin/look-at" ~/.local/bin/look-at
```

## Requirements

### Required

- **tmux** - Terminal multiplexer for pane management and context capture
  - Used by both `show-me` and `look-at` commands
  - `show-me` creates a dedicated "show" session for content display
  - `look-at` captures pane content and displays hierarchy

### Optional Enhancements

- **nvim-remote** - Enhanced Neovim socket integration
  - Provides automatic socket detection and richer editor status
  - Without it: show-me uses calculated socket paths (works fine)
  - With it: More flexible socket discovery across multiple Neovim instances

- **Browser** - For URL display (Firefox preferred, configurable via SHOW_BROWSER)

> **Renamed in SHOW-58:** the commands are now `show-me` and `look-at` (was
> `show` / `look`). The old names clashed with system binaries — `look` was
> silently shadowed by util-linux's dictionary `look`. The namespaced names
> have no such clash. The old `show` binary is gone (its temporary migration
> stub was removed in SHOW-125) — calling it now is a plain command-not-found.
> `look` was never one of ours to remove — without our binary claiming the
> name, `look` now falls through to the system's util-linux dictionary lookup
> tool (not command-not-found, and not `look-at` either — use `look-at`
> explicitly). See
> [`skills/show-me/references/troubleshooting.md`](skills/show-me/references/troubleshooting.md).

## Installation

### Claude Code (and GitHub Copilot CLI)

> **Note:** GitHub Copilot CLI supports the same `--plugin-dir` flag — these instructions work for both tools.

Load directly from a local clone:

```bash
claude --plugin-dir /path/to/show-me
```

Or install via a marketplace that includes show-me:

```bash
/plugin marketplace add mbailey/skills
/plugin install show-me@mbailey
```

### metool

```bash
mt package install show-me
```

## Commands

### show-me

Display content for the user:

```bash
show-me path/to/file.py          # Open file in Neovim
show-me path/to/file.py:42       # Open file at line 42
show-me path/to/file.py:10-30    # Highlight lines 10-30 (preferred for code)
show-me path/to/file.py#L42      # URL-fragment style (same as :42)
show-me https://example.com      # Open URL in browser
show-me "cmd:git status"         # Run command in shell pane
show-me diff                     # DiffView of unstaged changes
show-me diff:main                # DiffView vs main branch
show-me "diff:main -- src/"      # DiffView vs main, scoped to src/
show-me pane:%23                 # Focus tmux pane (cross-session)
show-me pane:self                # Focus your own pane (agent self-focus)
```

### look-at

Observe what the user is viewing:

```bash
look-at                          # Capture current pane context
look-at --hierarchy              # Show tmux session/window/pane layout
```

### Layouts

By default, `show-me` uses the `stacked` layout: a leader pane on the left
with content panes accumulating to the right, in the current window. `--layout`
(or `SHOW_LAYOUT`) picks a different split, or restores the old separate "show"
window behavior with `--layout window`:

```bash
show-me --layout stacked "cmd:claude" # Default — stacked split, accumulate panes (great for teammate-style)
show-me --layout right README.md     # Split right (70% wide)
show-me --layout below "cmd:make"    # Split below (30% tall)
show-me --layout left  README.md     # Split left
show-me --layout above "cmd:date"    # Split above
show-me --layout window README.md    # Restore old behavior — separate "show" window
show-me --here README.md             # Shorthand: right for files, below for commands
show-me --restack                    # Re-tidy drifted panes back into the default layout
```

`SHOW_SPLIT_SIZE=40` overrides the direction default (e.g. `40` means 40%).

### Configuration

Environment variables (defaults shown):

| Variable           | Default       | Purpose                                                |
| ------------------ | ------------- | ------------------------------------------------------ |
| `SHOW_SESSION`     | (auto-detect) | Target tmux session                                    |
| `SHOW_WINDOW`      | `show`        | Window name for show output                            |
| `SHOW_LAYOUT`      | `stacked`     | Default layout: `right`/`below`/`left`/`above`/`stacked`/`window` |
| `SHOW_SPLIT_SIZE`  | (auto)        | Split percentage; overrides direction default          |
| `SHOW_BROWSER`     | (auto)        | Browser for URLs (`Firefox`, `Chrome`, `Safari`, …)    |
| `SHOW_FOCUS`       | `true`        | Switch focus to the show pane/window                   |
| `SHOW_ZOOM`        | `true`        | Zoom the pane after showing (window mode only)         |
| `SHOW_AUTO_ATTACH` | `true`        | Auto-attach the terminal if no tmux client is attached |

A few less-common flags worth knowing about (full detail in `show-me --help`):

| Flag                | Purpose                                                              |
| -------------------- | --------------------------------------------------------------------- |
| `--restack [LAYOUT]` | Re-apply a layout to panes already in the window (tidy drift), no new pane |
| `--format VALUE`     | `cmd:` output format: `human` (default) or `json`                     |
| `--hold SECONDS`     | Hold visual focus for N seconds (default: 30); resists VoiceMode auto-focus |
| `--cwd PATH`         | Run `cmd:` targets in `PATH` instead of the caller's cwd               |
| `-p, --pane ID`      | Target a specific pane ID                                              |
| `--no-attach`        | Don't auto-attach the terminal if no tmux client is attached           |

For the full reference (every option, every flag), see
[`skills/show-me/references/commands.md`](skills/show-me/references/commands.md)
or run `show-me --help`.

## Optional Integrations

### nvim-remote (optional)

If nvim-remote is available, show-me uses it for enhanced features:

- **Auto socket detection**: Finds the best Neovim socket automatically
- **Richer status**: More detailed editor state in `look-at` output

Without nvim-remote, show-me:
- Uses calculated socket paths: `/tmp/nvim-tmux-pane-<pane_id>`
- Uses direct `nvim --server` commands for file operations
- **All core features work fully**

## Privacy

The `look-at` command captures screen content. Use responsibly and only when contextually appropriate.

## Why not just a tmux skill?

Most of what `show-me` does today is implemented with tmux, so it's natural to
ask whether this should just be a tmux skill that agents drive directly.
We chose `show-me` as the user-facing verb on purpose:

- **It captures user intent, not implementation.** "Show me this thing" is
  the verb the user actually means. Whether the thing lands in tmux,
  Neovim, or a browser tab is incidental and may change.
- **It's a deliberately narrow safety surface.** `show-me` accepts a small
  set of targets — file, URL, `cmd:`, `pane:`, `diff` — and rejects
  everything else. Granting an agent permission to run `show-me` is
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

- [`skills/show-me/references/commands.md`](skills/show-me/references/commands.md) — full command reference (every flag, every target)
- [`skills/show-me/references/layouts.md`](skills/show-me/references/layouts.md) — layout reference (every layout option, defaults, nvim-reuse semantics)
- [`skills/show-me/references/walkthrough.md`](skills/show-me/references/walkthrough.md) — guided voice walkthroughs (highlight-then-narrate, etiquette, prepared tours, focus hold / visual conch)
- [`skills/show-me/references/troubleshooting.md`](skills/show-me/references/troubleshooting.md) — common issues and fixes
- [`skills/show-me/SKILL.md`](skills/show-me/SKILL.md) — Claude Code skill for AI integration
- [`CHANGELOG.md`](CHANGELOG.md) — release history
