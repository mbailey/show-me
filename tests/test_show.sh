#!/usr/bin/env bash
# Tests for the show-me command
# Run: make test

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SHOW="${SCRIPT_DIR}/../bin/show-me"
LOOK="${SCRIPT_DIR}/../bin/look-at"
SHOW_STUB="${SCRIPT_DIR}/../bin/show"

PASS=0
FAIL=0
SKIP=0

pass() { PASS=$((PASS + 1)); echo "  ✓ $1"; }
fail() { FAIL=$((FAIL + 1)); echo "  ✗ $1"; }
skip() { SKIP=$((SKIP + 1)); echo "  - $1 (skipped)"; }

# Check prerequisites
if ! command -v tmux >/dev/null 2>&1; then
  echo "ERROR: tmux required for tests"
  exit 1
fi

echo "Testing show-me command"
echo "===================="

# --- Argument parsing ---
echo ""
echo "Argument parsing:"

# Test help output
if "$SHOW" --help 2>&1 | grep -q "Usage:"; then
  pass "--help shows usage"
else
  fail "--help shows usage"
fi

# Test pane:self resolution
if [[ -n "${TMUX_PANE:-}" ]]; then
  # We're in tmux — pane:self should resolve
  output=$("$SHOW" pane:self 2>&1) || true
  if echo "$output" | grep -q "Focused pane"; then
    pass "pane:self resolves to current pane"
  else
    fail "pane:self resolves to current pane (got: $output)"
  fi
else
  skip "pane:self (not in tmux)"
fi

# Test URL detection
echo ""
echo "URL detection:"

if [[ -x "$SHOW" ]]; then
  pass "show-me command is executable"
else
  fail "show-me command is executable"
fi

# --- Target classification (URL vs file) ---
# Source the script (main is guarded) and stub the handlers so we can probe
# detect_and_handle without actually opening anything.
echo ""
echo "Target classification:"

# Run classification probes in a subshell so stubs don't leak.
classify_target() {
  (
    # shellcheck disable=SC1090
    source "$SHOW" >/dev/null 2>&1 || true
    # shellcheck disable=SC2329  # stubs replace the real handlers; called via detect_and_handle
    handle_url()  { echo "URL"; }
    # shellcheck disable=SC2329
    handle_file() { echo "FILE"; }
    # shellcheck disable=SC2329
    handle_diff() { echo "DIFF"; }
    # shellcheck disable=SC2329
    handle_command() { echo "CMD"; }
    # shellcheck disable=SC2329
    handle_pane()  { echo "PANE"; }
    detect_and_handle "$1" "" "" "" ""
  )
}

expect_classify() {
  local target="$1" expected="$2"
  local got
  got=$(classify_target "$target" 2>/dev/null || true)
  if [[ "$got" == "$expected" ]]; then
    pass "classify '$target' -> $expected"
  else
    fail "classify '$target' -> expected $expected, got '$got'"
  fi
}

# Real URLs always classified as URL
expect_classify "https://example.com" URL
expect_classify "http://example.com" URL
expect_classify "github.com" URL
expect_classify "docs.python.org" URL

# Path-prefixed targets are always files
expect_classify "/tmp/foo.txt" FILE
expect_classify "./foo.md" FILE
expect_classify "../bar.json" FILE
# shellcheck disable=SC2088  # literal "~/notes.md" — testing that classifier doesn't expand it
expect_classify "~/notes.md" FILE

# Filenames that look like domains must NOT be opened as URLs.
# Regression guard for the readme.md TLD typo-squat redirect chain
# (show README.md -> https://README.md/ -> sponsored junk site).
expect_classify "README.md" FILE
expect_classify "package.json" FILE
expect_classify "tsconfig.json" FILE
expect_classify "pyproject.toml" FILE
expect_classify "index.html" FILE
expect_classify "config.yaml" FILE
expect_classify "main.py" FILE
expect_classify "app.js" FILE

# --- Look command ---
echo ""
echo "Testing look-at command"
echo "===================="

if [[ -x "$LOOK" ]]; then
  pass "look-at command is executable"
else
  fail "look-at command is executable"
fi

if "$LOOK" --help 2>&1 | grep -q "Usage\|look"; then
  pass "--help shows usage"
else
  fail "--help shows usage"
fi

# Test hierarchy mode (requires tmux)
if [[ -n "${TMUX:-}" ]]; then
  output=$("$LOOK" -H 2>&1) || true
  if echo "$output" | grep -q "Tmux\|session\|window"; then
    pass "-H shows tmux hierarchy"
  else
    fail "-H shows tmux hierarchy (got: $output)"
  fi
else
  skip "-H hierarchy (not in tmux)"
fi

# --- Migration stub (SHOW-58) ---
# bin/show was renamed to bin/show-me. The old name is kept ONLY as a loud,
# non-zero error stub pointing users to show-me -- it must NOT delegate.
echo ""
echo "Migration stub (SHOW-58):"

if [[ -x "$SHOW_STUB" ]]; then
  pass "bin/show stub is executable"
else
  fail "bin/show stub is executable"
fi

stub_out=$("$SHOW_STUB" README.md 2>&1) || stub_rc=$?
stub_rc=${stub_rc:-0}
if [[ "$stub_rc" -ne 0 ]]; then
  pass "bin/show stub exits non-zero (got: $stub_rc)"
else
  fail "bin/show stub exits non-zero (got: $stub_rc)"
fi

if grep -qi "renamed to .show-me\|show-me <target>" <<<"$stub_out"; then
  pass "bin/show stub points users to show-me"
else
  fail "bin/show stub points users to show-me (got: $stub_out)"
fi

# Must NOT silently delegate: a real `show README.md` would try tmux/nvim
# and emit show-me's output. The stub must not produce that.
if ! grep -qi "Focused pane\|Opening\|tmux is required for show-me" <<<"$stub_out"; then
  pass "bin/show stub does not delegate to show-me"
else
  fail "bin/show stub does not delegate to show-me (got: $stub_out)"
fi

# --- Skills structure ---
echo ""
echo "Plugin structure:"

# SHOW-58: skills/show retired (folded into the show-me skill); skills/look
# renamed to skills/look-at. The plugin ships exactly two skills: show-me + look-at.
if [[ ! -e "${SCRIPT_DIR}/../skills/show" ]]; then
  pass "skills/show retired (renamed: show-me command lives in skills/show-me)"
else
  fail "skills/show still exists (should be retired by SHOW-58)"
fi

if [[ ! -e "${SCRIPT_DIR}/../skills/look" ]]; then
  pass "skills/look removed (renamed to skills/look-at)"
else
  fail "skills/look still exists (should be renamed to skills/look-at)"
fi

if [[ -f "${SCRIPT_DIR}/../skills/look-at/SKILL.md" ]]; then
  pass "skills/look-at/SKILL.md exists"
else
  fail "skills/look-at/SKILL.md exists"
fi

if [[ -f "${SCRIPT_DIR}/../skills/show-me/SKILL.md" ]]; then
  pass "skills/show-me/SKILL.md exists"
else
  fail "skills/show-me/SKILL.md exists"
fi

if [[ ! -d "${SCRIPT_DIR}/../commands" ]]; then
  pass "commands/ directory removed (migrated to skills)"
else
  fail "commands/ directory still exists (should be migrated to skills)"
fi

if grep -qE "^name:[[:space:]]*show-me[[:space:]]*$" "${SCRIPT_DIR}/../skills/show-me/SKILL.md" 2>/dev/null; then
  pass "show-me skill frontmatter name is 'show-me'"
else
  fail "show-me skill frontmatter name is 'show-me'"
fi

if grep -qE "^name:[[:space:]]*look-at[[:space:]]*$" "${SCRIPT_DIR}/../skills/look-at/SKILL.md" 2>/dev/null; then
  pass "look-at skill frontmatter name is 'look-at'"
else
  fail "look-at skill frontmatter name is 'look-at'"
fi

if grep -q "^description:" "${SCRIPT_DIR}/../skills/show-me/SKILL.md" 2>/dev/null \
   && grep -q "^description:" "${SCRIPT_DIR}/../skills/look-at/SKILL.md" 2>/dev/null; then
  pass "show-me and look-at skills have description frontmatter"
else
  fail "show-me and look-at skills have description frontmatter"
fi

# No bare `show `/`look ` invocations remain in skills/docs (SHOW-58 acceptance).
# Match command-position usage: start-of-codeblock-line or after "AI: ".
if ! grep -rnE '(^|`|\$ |AI: )(show|look)( |$)' \
     "${SCRIPT_DIR}/../skills" "${SCRIPT_DIR}/../README.md" 2>/dev/null \
     | grep -vE 'show-me|look-at' | grep -q .; then
  pass "no bare 'show '/'look ' invocations in skills/ or README"
else
  fail "bare 'show '/'look ' invocation found (should be show-me/look-at)"
  grep -rnE '(^|`|\$ |AI: )(show|look)( |$)' \
     "${SCRIPT_DIR}/../skills" "${SCRIPT_DIR}/../README.md" 2>/dev/null \
     | grep -vE 'show-me|look-at' || true
fi

# --- Layout validation ---
echo ""
echo "Layout validation:"

# Source the script to access functions
# shellcheck disable=SC1090  # $SHOW is dynamic per test invocation
source "$SHOW"

if is_split_layout "right"; then
  pass "is_split_layout recognizes 'right'"
else
  fail "is_split_layout recognizes 'right'"
fi

if is_split_layout "below"; then
  pass "is_split_layout recognizes 'below'"
else
  fail "is_split_layout recognizes 'below'"
fi

if ! is_split_layout "window"; then
  pass "is_split_layout rejects 'window'"
else
  fail "is_split_layout rejects 'window'"
fi

if ! is_split_layout ""; then
  pass "is_split_layout rejects empty string"
else
  fail "is_split_layout rejects empty string"
fi

# --- Pane reuse detection (SHOW-22) ---
echo ""
echo "Pane reuse detection (SHOW-22):"

# Test find_nvim_show_pane function exists
if declare -f find_nvim_show_pane >/dev/null 2>&1; then
  pass "find_nvim_show_pane function exists"
else
  fail "find_nvim_show_pane function exists"
fi

# Test that find_nvim_show_pane returns 1 when no Neovim panes exist
if [[ -n "${TMUX:-}" ]]; then
  # We're in tmux, so list-panes will work; but there should be no show-managed sockets
  # for panes in this test environment
  if ! find_nvim_show_pane >/dev/null 2>&1; then
    pass "find_nvim_show_pane returns 1 when no Neovim panes exist"
  else
    # There might actually be a show-managed pane — that's OK in a real tmux session
    skip "find_nvim_show_pane (show-managed pane may exist in test session)"
  fi
else
  skip "find_nvim_show_pane no-pane test (not in tmux)"
fi

# Test stale socket cleanup
socket_dir=$(get_socket_dir)
stale_socket="${socket_dir}/nvim-show-pane-99999"
# Create a stale socket file (regular file, not a real socket — simulates stale)
if [[ -n "${TMUX:-}" ]]; then
  # Only run stale socket test inside tmux where list-panes works
  # The function checks -S (socket), so a regular file won't match — that's correct behavior
  touch "$stale_socket" 2>/dev/null
  if ! find_nvim_show_pane >/dev/null 2>&1; then
    pass "find_nvim_show_pane skips non-socket files"
  else
    skip "find_nvim_show_pane stale socket (unexpected match)"
  fi
  rm -f "$stale_socket" 2>/dev/null || true
else
  skip "stale socket cleanup (not in tmux)"
fi

# Test that window mode is unaffected by reuse logic
if ! is_split_layout "window"; then
  pass "window mode does not trigger split reuse logic"
else
  fail "window mode does not trigger split reuse logic"
fi

# --- Stacked nvim reuse for file shows (SHOW-68) ---
# Verify the reuse-skip guard for stacked has been removed from handle_file
# (file shows reuse existing nvim under any split layout) but is preserved in
# handle_diff (diffs always get their own pane to avoid SHOW-62 hijack).

# handle_file: scan from the function definition to the next `^}` and assert
# that the stacked-skip guard is NOT present in that range.
file_block=$(awk '/^handle_file\(\) \{/,/^}/' "$SHOW")
# shellcheck disable=SC2016  # literal source-code pattern — variables must NOT expand
if grep -q '\[\[ "$layout" != "stacked" \]\]' <<<"$file_block"; then
  fail "handle_file: stacked-skip guard still present (file shows should reuse nvim under stacked)"
else
  pass "handle_file: stacked allows nvim reuse (SHOW-68)"
fi

# handle_diff: same scan, but the guard MUST still be present (SHOW-62 isolation).
diff_block=$(awk '/^handle_diff\(\) \{/,/^}/' "$SHOW")
# shellcheck disable=SC2016  # literal source-code pattern — variables must NOT expand
if grep -q '\[\[ "$layout" != "stacked" \]\]' <<<"$diff_block"; then
  pass "handle_diff: stacked-skip guard preserved (avoids SHOW-62 hijack)"
else
  fail "handle_diff: stacked-skip guard missing (diffs would hijack reused nvim — SHOW-62 regression)"
fi

# --- restack_layout() extraction (SHOW-98 impl-001) ---
echo ""
echo "restack_layout extraction (SHOW-98):"

# restack_layout() must exist as a reusable function.
if grep -q '^restack_layout() {' "$SHOW"; then
  pass "restack_layout(): function defined"
else
  fail "restack_layout(): function not defined"
fi

# create_stacked_pane() must delegate to restack_layout() and no longer inline
# the select-layout / resize-pane tmux calls (no duplicated tmux commands).
csp_block=$(awk '/^create_stacked_pane\(\) \{/,/^}/' "$SHOW")
if grep -q 'restack_layout "\$window_id" "\$leader_pane" stacked' <<<"$csp_block"; then
  pass "create_stacked_pane(): delegates to restack_layout()"
else
  fail "create_stacked_pane(): does not call restack_layout()"
fi
if grep -q 'select-layout .* main-vertical' <<<"$csp_block"; then
  fail "create_stacked_pane(): still inlines select-layout (duplicated tmux call)"
else
  pass "create_stacked_pane(): rebalance no longer inlined"
fi

# The extracted function must hold the stacked rebalance logic.
rl_block=$(awk '/^restack_layout\(\) \{/,/^}/' "$SHOW")
if grep -q 'select-layout .* main-vertical' <<<"$rl_block" \
   && grep -q 'resize-pane .* -x 30%' <<<"$rl_block"; then
  pass "restack_layout(): holds stacked rebalance (main-vertical + leader 30%)"
else
  fail "restack_layout(): missing stacked rebalance logic"
fi

# --- cmd: machine-readable handle (SHOW-92) ---
echo ""
echo "cmd: handle (SHOW-92):"

# --format appears in --help Options
if "$SHOW" --help 2>&1 | grep -qE -- '--format VALUE'; then
  pass "--help documents --format"
else
  fail "--help documents --format"
fi

# Invalid --format value is rejected before any pane is touched (no tmux needed)
fmt_out=$("$SHOW" --format bogus "cmd:true" 2>&1) || true
if grep -q "Invalid format: bogus" <<<"$fmt_out"; then
  pass "--format rejects invalid value"
else
  fail "--format rejects invalid value (got: $fmt_out)"
fi

# json_escape: backslash and double-quote are escaped (unit, sourced)
escape_out=$(
  # shellcheck disable=SC1090
  source "$SHOW" >/dev/null 2>&1 || true
  json_escape 'a\b"c'
)
if [[ "$escape_out" == 'a\\b\"c' ]]; then
  pass "json_escape escapes backslash and quote"
else
  fail "json_escape escapes backslash and quote (got: $escape_out)"
fi

if [[ -n "${TMUX:-}" ]]; then
  # Default (human) line ends with [pane %NN] and the pane is real/capturable
  h_out=$("$SHOW" --layout stacked "cmd:echo SHOW92_MARKER" 2>/dev/null) || true
  h_pane=$(grep -oE '\[pane (%[0-9]+)\]' <<<"$h_out" | grep -oE '%[0-9]+' || true)
  if [[ -n "$h_pane" ]] && grep -qE '\[pane %[0-9]+\]$' <<<"$h_out"; then
    pass "human cmd: line ends with [pane %NN]"
  else
    fail "human cmd: line ends with [pane %NN] (got: $h_out)"
  fi
  if [[ -n "$h_pane" ]] && tmux capture-pane -p -t "$h_pane" >/dev/null 2>&1; then
    pass "emitted pane ID is capturable via tmux"
  else
    fail "emitted pane ID is capturable via tmux (pane: ${h_pane:-none})"
  fi
  [[ -n "$h_pane" ]] && tmux kill-pane -t "$h_pane" 2>/dev/null || true

  # --format json: one line, required keys, created=true for a fresh split
  j_out=$("$SHOW" --layout stacked --format json "cmd:echo SHOW92_JSON" 2>/dev/null) || true
  j_pane=$(grep -oE '"pane":"(%[0-9]+)"' <<<"$j_out" | grep -oE '%[0-9]+' || true)
  if [[ "$(wc -l <<<"$j_out" | tr -d ' ')" == "1" ]] \
     && grep -q '"pane":"%' <<<"$j_out" \
     && grep -q '"session":"' <<<"$j_out" \
     && grep -q '"window":"' <<<"$j_out" \
     && grep -q '"status":"' <<<"$j_out"; then
    pass "--format json emits one-line handle with required keys"
  else
    fail "--format json emits one-line handle with required keys (got: $j_out)"
  fi
  if grep -q '"created":true' <<<"$j_out"; then
    pass "created=true for a freshly split pane"
  else
    fail "created=true for a freshly split pane (got: $j_out)"
  fi
  # Validate it parses as JSON when a parser is available
  if command -v jq >/dev/null 2>&1; then
    if jq -e . >/dev/null 2>&1 <<<"$j_out"; then
      pass "--format json output is valid JSON (jq)"
    else
      fail "--format json output is valid JSON (jq) (got: $j_out)"
    fi
  else
    skip "json validity (jq not installed)"
  fi
  [[ -n "$j_pane" ]] && tmux kill-pane -t "$j_pane" 2>/dev/null || true
else
  skip "cmd: handle pane/json tests (not in tmux)"
fi

# --- Version drift check (SHOW-64) ---
echo ""
echo "Version drift check (SHOW-64):"

manifest_file="${SCRIPT_DIR}/../.claude-plugin/plugin.json"
if [[ -f "$manifest_file" ]] && command -v jq >/dev/null 2>&1; then
  bin_version=$("$SHOW" --version 2>/dev/null | awk '{print $NF}')
  manifest_version=$(jq -r .version "$manifest_file")
  if [[ "$bin_version" == "$manifest_version" ]]; then
    pass "bin/show-me VERSION matches plugin.json (${bin_version})"
  else
    fail "VERSION drift: bin/show-me=${bin_version}, plugin.json=${manifest_version}"
  fi
else
  skip "version drift check (jq or plugin.json missing)"
fi

# --- docs/commands.md env-var drift check ---
# Every SHOW_* env var documented in `bin/show-me --help` should be in
# docs/commands.md, and vice versa. Catches the kind of drift the
# 2026-05-10 review found (SHOW_LAYOUT/SHOW_AUTO_ATTACH absent from docs).
echo ""
echo "Docs drift check (SHOW_* env vars):"

commands_doc="${SCRIPT_DIR}/../docs/commands.md"
if [[ -f "$commands_doc" ]]; then
  # Extract SHOW_* names from --help "Environment:" block
  help_vars=$("$SHOW" --help 2>/dev/null \
    | awk '/^Environment:/{flag=1; next} flag' \
    | grep -oE '^[[:space:]]+SHOW_[A-Z_]+' \
    | awk '{print $1}' | sort -u)
  # Extract SHOW_* names from the docs Environment Variables table
  # shellcheck disable=SC2016  # backtick-delimited markdown var names — literal regex
  doc_vars=$(grep -oE '`SHOW_[A-Z_]+`' "$commands_doc" | tr -d '`' | sort -u)

  # Symmetric difference
  only_in_help=$(comm -23 <(echo "$help_vars") <(echo "$doc_vars"))
  only_in_doc=$(comm -13 <(echo "$help_vars") <(echo "$doc_vars"))

  if [[ -z "$only_in_help" && -z "$only_in_doc" ]]; then
    pass "docs/commands.md SHOW_* env vars match bin/show-me --help"
  else
    msg="docs/commands.md drift vs --help:"
    [[ -n "$only_in_help" ]] && msg+=" missing in docs: $(echo "$only_in_help" | tr '\n' ' ')"
    [[ -n "$only_in_doc" ]] && msg+=" missing in --help: $(echo "$only_in_doc" | tr '\n' ' ')"
    fail "$msg"
  fi
else
  skip "docs drift check (docs/commands.md missing)"
fi

# --- Summary ---
echo ""
echo "===================="
TOTAL=$((PASS + FAIL + SKIP))
echo "Results: $PASS passed, $FAIL failed, $SKIP skipped ($TOTAL total)"

if [[ $FAIL -gt 0 ]]; then
  exit 1
fi
