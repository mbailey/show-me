# Changelog

All notable changes to show-me will be documented in this file.

## [Unreleased]

## [2.1.0] - 2026-04-20

### Added

- **Split pane layouts** — `show --layout right file.py` opens content in a split pane beside the conversation instead of switching to a separate window. Supports `right`, `below`, `left`, `above`, `window` (original behavior), and `stacked` (coming soon)
- **`--here` shorthand** — `show --here file.py` opens in a split pane using the content-type default direction (right for files, below for commands)
- **`SHOW_LAYOUT` env var** — controls the default layout mode. LLMs just call `show <target>` and the user's preference is applied automatically
- **`SHOW_SPLIT_SIZE` env var** — controls split pane percentage (default: 70%)
- **Neovim pane reuse** — in split mode, subsequent file shows reuse the existing Neovim pane instead of creating new splits
- **Stale socket cleanup** — crashed Neovim instances are detected and their sockets cleaned up automatically

### Changed

- `below` and `above` layouts use full-width splits (tmux `-f` flag), giving command output the full terminal width
- Version bump to 1.4.0

## [2.0.5] - 2026-03-13

### Added

- **`--hold` flag** — `show --hold 60 file.md` holds visual focus for 60 seconds, preventing VoiceMode auto-focus from switching away while the user reads
- Hold duration written to sentinel file so VoiceMode reads the exact value per show command
- Configurable default via `SHOW_HOLD_SECONDS` env var (default: 30s)
- Skill docs updated with visual conch workflow and examples

## [2.0.4] - 2026-03-13

### Added

- **Visual conch** — when show takes focus, it writes a sentinel file (`~/.voicemode/focus-hold`) that tells VoiceMode auto-focus to back off for 30 seconds, preventing the speaking agent from yanking the user away before they've read what was shown

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
