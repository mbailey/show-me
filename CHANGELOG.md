# Changelog

All notable changes to show-me will be documented in this file.

## [Unreleased]

## [2.0.5] - 2026-03-13

## [2.0.4] - 2026-03-13

## [2.0.3] - 2026-03-13

### Improved

- Skill docs now trigger on "show yourself" — agents understand `pane:self` without extra prompting
- Fixed broken `make release` command (updated to `claude-plugin-release`)

## [2.0.2] - 2026-03-12

### Fixed

- Cross-session pane switching now targets the user's actual terminal client instead of the agent's, so focus lands where you're looking

## [2.0.1] - 2026-03-12

### Added

- **Git diff viewer** — `show diff` opens DiffView in Neovim for unstaged changes; `show diff:main` compares against a branch
- **Cross-session focus** — `show pane:<id>` and `show pane:self` work across tmux sessions, not just within the current one
- **Copilot CLI support** — plugin works with GitHub Copilot CLI using the same `--plugin-dir` flag
- **Test framework** — `make test` runs the test suite

### Changed

- Commands migrated to skills format for cross-tool portability (works with Claude Code, Copilot CLI, and other adopters of the Agent Skills standard)
- Renamed from `show-and-tell` to `show-me` (old GitHub URL redirects automatically)
- Line range highlighting: `show file.py:10-20` or `show file.py#L10-20`
- Chrome MCP preferred for URL navigation when available

## [1.0.4] - 2026-01-07

### Added

- **Configurable targeting** — choose which tmux session and window to open files in
  - `-s/--session`, `-w/--window` flags and matching env vars
  - `--no-focus`, `--no-zoom`, `--no-attach` for controlling behavior
  - Smart session detection: current session > attached > any > create new

### Changed

- Neovim sockets moved to private directory (`$TMPDIR` or `$XDG_RUNTIME_DIR`) for security
- Show only connects to Neovim instances it created — predictable, no surprises

## [1.0.0] - 2025-12-30

### Added

- **show** command — display files, URLs, and command output for users to see
  - Open files in Neovim with line number support (`:42` or `#L42`)
  - Open URLs in browser (auto-detects or uses configured browser)
  - Run commands in tmux panes (`cmd:command`)
  - Focus tmux panes (`pane:id`)
- Auto-attach terminal if tmux session has no clients (macOS Terminal.app, Linux terminal emulators)
- Works on macOS and Linux
- Claude Code plugin with `/show-me:show` and `/show-me:look` skills
