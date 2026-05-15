# Changelog

All notable changes to show-me will be documented in this file.

## [Unreleased]

## [2.3.5] - 2026-05-16

### Added

- **`show cmd:` returns a machine-readable handle (SHOW-92).** The default
  human line now ends with `[pane %NN]` so an agent can `tmux capture-pane
  -t %NN` and follow up — `cmd:` is no longer fire-and-forget. New
  `--format json` flag (and `SHOW_FORMAT` env var) emits a one-line JSON
  handle with `pane`, full `session`/`window` names, `window_index`,
  `pane_index`, `created` (new pane vs reused), `layout`, `status`
  (best-effort liveness), and `cmd`. Existing interactive usage is
  unchanged apart from the additive `[pane %NN]` suffix.

## [2.3.4] - 2026-05-13

### Changed

- **Default layout is now `stacked` (SHOW-86).** With no `SHOW_LAYOUT` env var
  and no `--layout` flag, `show` opens content as a stacked split — a leader
  pane on the left, content panes accumulating to the right. File shows
  reuse the existing Neovim pane (SHOW-68); `cmd:` shows create a new pane
  per call. To restore the pre-2.4 separate-window behavior, set
  `SHOW_LAYOUT=window` in your shell, or pass `--layout window` per call.
  Help text, `docs/commands.md`, and the new [`docs/layouts.md`](docs/layouts.md)
  reflect the change. Minor bump because this is a user-visible default flip.

### Added

- **`docs/layouts.md`** — full layout reference: every option, nvim-reuse
  semantics, when to pick which. Linked from `README.md` and `docs/commands.md`.

## [2.3.3] - 2026-05-13

### Added

- **GitHub Actions CI workflow** — `make test` now runs on Ubuntu and macOS for every push and pull request, catching cross-platform regressions before merge.
- **`make lint` target** — runs `shellcheck` over `bin/show` and `bin/look` (plus `.gitignore` cleanup for editor/OS noise).
- **"Why not just a tmux skill?" rationale** in the README, explaining where `show` adds value over hand-rolled tmux commands.

### Changed

- **README and `commands.md` brought to feature parity with `bin/show --help`** — flags, env vars, and layout values are now documented consistently across all three surfaces.
- **Code-hygiene pass on `bin/show` and `bin/look`** — quoting fixes (defence-in-depth against filename-with-quote injection in the `nvim --listen` send-keys path), removal of an unused `reused_pane` variable, and small readability improvements. No behaviour change.

### Fixed

- **Stacked layout now reuses existing nvim for file shows (SHOW-68).** Previously,
  `show --layout stacked file.md` always created a new nvim pane, even when one
  already existed — so subsequent file shows accumulated stacked nvim panes
  instead of replacing the buffer. This was an intentional design choice for
  teammate-style accumulation (SHOW-54), but it's wrong for file shows. The
  guard has been relaxed in `handle_file` only: file shows reuse existing nvim
  under any split layout. `handle_command` (cmd: spawns) keeps its create-new-
  pane behavior so teammate accumulation under stacked is unaffected.
  `handle_diff` keeps the stacked-skip guard to avoid the SHOW-62 hijack.
  Two regression tests added.

### Security

- **Filename misclassified as URL → opened typo-squat domain.** `show README.md`
  (and any bare filename with a dot in it) was matched by the domain-detection
  regex and opened as `https://README.md/` in the user's browser. The `.md`
  TLD (Moldova) is squatted and was redirecting to a sponsored "deals" landing
  page. Same risk applied to other valid-TLD-shaped extensions (`.js`/`.py`/
  `.sh`/`.rs` etc.).

  `detect_and_handle` now classifies a target as a file when it has an
  explicit path prefix (`/`, `./`, `../`, `~`), exists locally, or ends in a
  common file extension that overlaps with a TLD. Bare-domain shorthand
  (`show github.com`) still works for non-conflicting TLDs. To reach a URL
  whose host literally ends in one of those extensions, use the explicit
  scheme: `show https://example.md/`.

  Added 16 classification regression tests in `tests/test_show.sh`.

## [2.3.2] - 2026-05-03

### Changed

- `bin/release` is now interactive when called with no args: shows current version, suggests next-patch as default, accepts `m`/`M` for minor/major or an explicit `X.Y.Z`. Matches `claude-plugin-release` convention.
- `bin/release` refuses to release when there are no commits since the last release tag (Layer 1: git check). Prevents accidental empty release commits.
- `bin/release` refuses to release when `[Unreleased]` is empty AND no commits exist since the last tag. When commits DO exist but `[Unreleased]` is empty, it lists the commit titles and prompts for confirmation. Override with `--allow-empty` if intentional.

### Fixed

- VERSION constant in bin/show now matches plugin.json (was stuck at 1.4.0 since v2.0.0). Added drift-check to make test.
- `make release` now bumps `bin/show` VERSION and `.claude-plugin/plugin.json` `.version` atomically in a single commit (prevents drift at the source). See `RELEASING.md`.

## [2.3.1] - 2026-05-03

## [2.3.0] - 2026-05-03

### Added

- **Stacked layout** (`--layout stacked` / `SHOW_LAYOUT=stacked`) — each `show` call adds a new pane to a cascading right-hand stack instead of replacing the previous one. Uses the tmux teammate-layout algorithm: first pane splits the leader horizontally (leader keeps 30%, content gets 70%); subsequent panes split the middle teammate, alternating vertical/horizontal, then rebalance via `select-layout main-vertical`. Closes the gap noted in v2.1.0 where stacked was "coming soon".

## [2.2.0] - 2026-04-20

### Fixed

- **Split pane targeting** — splits now anchor to the agent's pane (`$TMUX_PANE`) instead of the user's active pane, so clicking around doesn't change where the next `show` splits

### Changed

- **Direction-aware split sizes** — side splits (right/left) default to 70% for content-heavy file viewing; top/bottom splits (above/below) default to 30% for compact command output. `SHOW_SPLIT_SIZE` env var overrides when set.

## [2.1.0] - 2026-04-20

### Added

- **Split pane layouts** — `show --layout right file.py` opens content in a split pane beside the conversation instead of switching to a separate window. Supports `right`, `below`, `left`, `above`, `window` (original behavior), and `stacked` (coming soon)
- **`--here` shorthand** — `show --here file.py` opens in a split pane using the content-type default direction (right for files, below for commands)
- **`SHOW_LAYOUT` env var** — controls the default layout mode. LLMs just call `show <target>` and the user's preference is applied automatically
- **`SHOW_SPLIT_SIZE` env var** — controls split pane percentage (overrides direction defaults: 70% for side splits, 30% for top/bottom)
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
