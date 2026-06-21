# Changelog

All notable changes to show-me will be documented in this file.

## [Unreleased]

### Fixed

- **Rapid/concurrent `show-me <file>` calls no longer each spawn a new nvim
  pane (SHOW-110).** The SHOW-22 pane-reuse detection was safe for human-paced
  use but not for a high-rate caller (e.g. taskmaster's show-on-create firing
  for several new tasks at once): concurrent invocations each ran
  `find_nvim_show_pane` before any sibling had bound a live socket, so all of
  them created their own pane — three new tasks, three neovim panes. Two
  changes close the gap:
  - A **per-window mutex** (portable `mkdir` lock; macOS has no `flock(1)`)
    serialises the find-or-create-and-start sequence, so the first caller
    brings up one pane and the rest reuse it. Best-effort: outside tmux, on a
    dead-holder lock, or after a 30s ceiling it proceeds unlocked rather than
    hang. Different windows use different locks, so concurrent foremen don't
    block each other.
  - `find_nvim_show_pane` is now **non-destructive**: it no longer deletes a
    socket whose pane is still running nvim (a slow cold start), which had been
    orphaning a starting instance and forcing a duplicate pane. Only a pane
    with no nvim is treated as stale.
  - The new-nvim responsiveness wait is now configurable via
    `SHOW_NVIM_STARTUP_TIMEOUT` (default 10s, was a hard-coded 3s). It
    early-exits the moment nvim answers, so the higher ceiling only costs time
    on a genuine startup failure — but it stops a slow cold start from
    returning before nvim is reusable.

## [3.0.2] - 2026-05-19

### Added

- **`--cwd PATH` runs `cmd:` targets in a specified directory (SHOW-102).**
  `show-me --cwd /path/to/repo "cmd:make test"` runs the command in `PATH`
  instead of the caller's working directory. The command is wrapped as
  `cd -- "<PATH>" && <cmd>` so behaviour is identical whether show-me
  creates a new pane or reuses an existing one, and a reused pane's prior
  working directory is left unchanged. PATH is validated before any tmux
  pane is created or reused: a missing directory is a hard error
  (`show-me: --cwd: no such directory: <PATH>`, non-zero exit, no pane) —
  show-me never silently falls back to the caller's cwd. `--cwd` is a
  documented no-op for file/URL targets (accepted, ignored, target opens
  normally), keeping the flag composable in scripts with mixed targets.
  The emitted human line and `--format json` handle still show the user's
  original command, not the `cd` wrapper (no SHOW-92 regression).

### Fixed

- **`--restack` now identifies the leader positionally (SHOW-104).**
  `do_restack()` previously assumed the leader was `TMUX_PANE` — the pane
  the command runs in. That holds for `show` (the agent runs it from its
  own leader pane) but not for `--restack`, which is human-invoked from a
  content/shell pane. The leader was misidentified, so `select-layout
main-vertical` sized the real (top-left) leader as the large main pane
  while `resize-pane` shrank the wrong pane — leaving the leader at ~70%
  and content at ~30%, backwards. `--restack` now resolves the leader
  positionally (topmost pane in the leftmost column, `pane_left == 0` with
  the smallest `pane_top`), which is layout-stable and matches how the
  stacked layout is constructed, so the leader is pinned to ~30% no matter
  which pane invoked the command. `create_stacked_pane()`'s `TMUX_PANE`
  use is unchanged — it is correct in practice (run from the leader pane).

## [3.0.1] - 2026-05-17

### Added

- **`--restack` flag re-applies a layout to existing panes (SHOW-98).**
  `show-me --restack` takes no target: it redraws the panes already in the
  window into a layout and exits, creating no new pane and showing nothing —
  a "redraw to stacked" button for panes that have drifted after manual
  splits/closes/resizes. With no argument it uses the configured default
  layout (`SHOW_LAYOUT`, `stacked` when unset); an optional argument
  overrides it (`show-me --restack below`) and accepts the same values as
  `--layout`. `stacked`/`right`/`left` map to `main-vertical` (leader ~30%),
  `below`/`above` to `main-horizontal`; unsupported layouts and running
  outside tmux exit non-zero with an actionable message. The stacked
  rebalance was extracted into a shared `restack_layout()` so
  `create_stacked_pane()` and `--restack` no longer duplicate the tmux
  commands. Shell completion for the flag is out of scope here and tracked
  in SHOW-100.

## [3.0.0] - 2026-05-16

### Added

- **Agents are now taught the `cmd:` handle (SHOW-92 follow-up).** The
  machine-readable handle (`[pane %NN]` suffix and `--format json`) shipped
  in v2.3.5, but the skills agents load didn't mention it. Added follow-up
  guidance to both `skills/show/SKILL.md` and `skills/show-me/SKILL.md` so
  agents know to capture the pane and follow up rather than treating `cmd:`
  as fire-and-forget. Docs-only; no behaviour change to the binary.

### Changed

- **BREAKING (SHOW-58): the commands have been renamed.** `show` is now
  **`show-me`** and `look` is now **`look-at`**. The plugin is still named
  `show-me` and still ships exactly two skills (`show-me` and `look-at`),
  which can each be enabled/disabled independently. This is a deliberate
  major version bump (SemVer): every `show <target>` invocation must become
  `show-me <target>`, and every `look [options]` must become
  `look-at [options]`. Flags, layouts, env vars (`SHOW_*`), and behaviour
  are otherwise unchanged -- only the command names differ.

  **Why:** `look` was _silently broken_ -- homebrew util-linux ships
  `/opt/homebrew/.../bin/look` earlier in PATH, so agents calling `look`
  got dictionary output with no error. `show` squats a generic verb and is
  a latent future-clash risk. `show-me` / `look-at` are both clash-free and
  mirror the plugin name.

  **Migration:**
  - Replace `show ...` -> `show-me ...` and `look ...` -> `look-at ...` in
    your scripts, skills, aliases, and docs.
  - `bin/show` is **kept temporarily as a loud error stub**: it prints a
    message pointing at `show-me` and exits non-zero (127). It does **not**
    silently delegate -- stale callers fail loudly and obviously instead of
    getting wrong behaviour. This stub is a migration aid and will be
    removed in a future release; do not depend on it.
  - `bin/look` is **removed outright** -- it was already shadowed by system
    `look`, so an error stub there would never execute.

  **Rollout coordination:** the taskmaster skill spawns workers via
  `show --layout stacked cmd:'tm task work TASK-ID'`. After this rename
  that invocation hits the `show` error stub and task workers break.
  Updating taskmaster to call `show-me` is tracked as the linked
  follow-up **TM-844** and must land before or together with this release.

### Removed

- **`bin/look` deleted (SHOW-58).** Use `look-at` instead. (It was already
  non-functional in practice -- shadowed by homebrew/system `look` on PATH.)

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
