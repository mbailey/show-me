#!/usr/bin/env bash
# Tests for the show command
# Run: make test

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SHOW="${SCRIPT_DIR}/../bin/show"
LOOK="${SCRIPT_DIR}/../bin/look"

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

echo "Testing show command"
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
  pass "show command is executable"
else
  fail "show command is executable"
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
echo "Testing look command"
echo "===================="

if [[ -x "$LOOK" ]]; then
  pass "look command is executable"
else
  fail "look command is executable"
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

# --- Skills structure ---
echo ""
echo "Plugin structure:"

if [[ -f "${SCRIPT_DIR}/../skills/show/SKILL.md" ]]; then
  pass "skills/show/SKILL.md exists"
else
  fail "skills/show/SKILL.md exists"
fi

if [[ -f "${SCRIPT_DIR}/../skills/look/SKILL.md" ]]; then
  pass "skills/look/SKILL.md exists"
else
  fail "skills/look/SKILL.md exists"
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

if grep -q "name:" "${SCRIPT_DIR}/../skills/show/SKILL.md" 2>/dev/null; then
  pass "show skill has name frontmatter"
else
  fail "show skill has name frontmatter"
fi

if grep -q "description:" "${SCRIPT_DIR}/../skills/show/SKILL.md" 2>/dev/null; then
  pass "show skill has description frontmatter"
else
  fail "show skill has description frontmatter"
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
    pass "bin/show VERSION matches plugin.json (${bin_version})"
  else
    fail "VERSION drift: bin/show=${bin_version}, plugin.json=${manifest_version}"
  fi
else
  skip "version drift check (jq or plugin.json missing)"
fi

# --- docs/commands.md env-var drift check ---
# Every SHOW_* env var documented in `bin/show --help` should be in
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
    pass "docs/commands.md SHOW_* env vars match bin/show --help"
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
