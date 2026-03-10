# Changelog

All notable changes to show-me will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [2.0.0] - 2026-03-10

### Changed

- **Renamed plugin from `show-and-tell` to `show-me`** (SAT-36)
  - Plugin name, skill namespace, and command prefixes all updated
  - GitHub repo renamed from `mbailey/show-and-tell` to `mbailey/show-me`
  - Old repo URL redirects automatically
  - Existing users should uninstall `show-and-tell` and install `show-me`

### Added

- **Add line range highlighting** (SAT-6)
  - Highlight multiple lines when opening files in Neovim
  - Support colon syntax: `show file.py:10-20` for lines 10-20
  - Support URL fragment syntax: `show file.py#L10-20`
  - Use Neovim visual line mode for clear highlighting
  - Maintain backward compatibility with single line syntax (`:42` or `#L42`)

### Changed

- **Prioritize Chrome MCP for URL navigation** (SAT-16)
  - Guide AI to check Chrome MCP first when showing URLs
  - Add decision tree for URL navigation flow
  - Use show command as fallback when Chrome MCP unavailable
  - Include domain permission handling guidance for Chrome

## [1.0.4] - 2026-01-07

### Added

- **Configurable tmux session/window targeting** (SAT-12)
  - Auto-detect current tmux session instead of hardcoded "show" session
  - Add `-w/--window` flag and `SHOW_WINDOW` env var for window configuration
  - Add `--no-focus` flag to prevent switching focus to show window
  - Add `--no-zoom` flag to prevent auto-zooming the pane
  - Add `--no-attach` flag to prevent auto-attaching terminal
  - Session resolution priority: CLI flag → env var → current session → attached session → any session → create new
  - Tmux availability check with install instructions for macOS, Ubuntu, Fedora

### Changed

- **Security: Private socket directory** (SAT-12)
  - Neovim sockets now use `$TMPDIR` (macOS) or `$XDG_RUNTIME_DIR` (Linux) instead of world-readable `/tmp`
  - Fallback to `$HOME/.local/run` with 0700 permissions
  - Socket naming: `nvim-show-pane-{id}` in private directory

- **Simplified behavior** (SAT-12)
  - Removed nvim-remote auto-detection for predictable file opening
  - Show only connects to Neovim instances it created
  - All files open in the configured session:window, not arbitrary Neovim instances

- **Improved output** (SAT-12)
  - Location reporting: "Opened file.txt in session:window" format
  - Help text updated with new options and behavior

### Breaking Changes

- Default session changes from "show" to current session
  - **Migration**: Set `SHOW_SESSION=show` to restore previous behavior
- Neovim socket paths moved to private directory
  - **Impact**: External tools referencing old socket paths need updating
- nvim-remote auto-detection no longer used by default
  - **Impact**: Files always open in configured session, not arbitrary Neovim

## [1.0.3] - 2026-01-03

### Changed

- Updated plugin metadata
- Removed SKILL.md from repository

### Removed

- Removed internal report file

## [1.0.2] - 2026-01-03

### Added

- Makefile with release target for streamlined releases

## [1.0.1] - 2026-01-02

### Added

- **Chrome Browser Integration** (SAT-5)
  - Prefer Claude-in-Chrome MCP for URL handling when available
  - Documentation for Chrome browser integration in SKILL.md

### Changed

- **Documentation restructure** (SAT-4)
  - Split SKILL.md into minimal index + detailed docs/
  - Improved organization and readability

## [1.0.0] - 2025-12-30

### Added

- **Auto-attach terminal functionality** (SAT-3)
  - Automatically open terminal window if tmux session has no attached clients
  - Configurable via `SHOW_AUTO_ATTACH` environment variable (default: true)
  - macOS: Uses AppleScript to open Terminal.app
  - Linux: Supports gnome-terminal, kitty, alacritty, xterm, konsole

### Fixed

- **Show command tmux session creation** (SAT-3)
  - Properly create tmux session when it doesn't exist
  - Better error reporting on failures
  - Fixed session window creation logic

### Changed

- Simplified documentation: nvim-remote is optional
- Updated skill description for clarity

## Initial Release - 2025-12-29

### Added

- Core show command for displaying files, URLs, and command output
- File opening in Neovim with line number support (`:line` and `#Lline` formats)
- URL opening in browser (auto-detect or configured)
- Command execution in tmux panes (`cmd:command` syntax)
- Pane focus (`pane:id` syntax)
- Neovim remote socket support for file opening
- Optional nvim-remote integration for smart Neovim selection
- Multi-platform support (macOS, Linux)
- Configuration via environment variables and CLI flags
- Claude Code plugin integration
- Comprehensive documentation and skill files
