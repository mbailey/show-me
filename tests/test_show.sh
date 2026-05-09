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
    handle_url()  { echo "URL"; }
    handle_file() { echo "FILE"; }
    handle_diff() { echo "DIFF"; }
    handle_command() { echo "CMD"; }
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
if grep -q '\[\[ "$layout" != "stacked" \]\]' <<<"$file_block"; then
  fail "handle_file: stacked-skip guard still present (file shows should reuse nvim under stacked)"
else
  pass "handle_file: stacked allows nvim reuse (SHOW-68)"
fi

# handle_diff: same scan, but the guard MUST still be present (SHOW-62 isolation).
diff_block=$(awk '/^handle_diff\(\) \{/,/^}/' "$SHOW")
if grep -q '\[\[ "$layout" != "stacked" \]\]' <<<"$diff_block"; then
  pass "handle_diff: stacked-skip guard preserved (avoids SHOW-62 hijack)"
else
  fail "handle_diff: stacked-skip guard missing (diffs would hijack reused nvim — SHOW-62 regression)"
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

# --- Summary ---
echo ""
echo "===================="
TOTAL=$((PASS + FAIL + SKIP))
echo "Results: $PASS passed, $FAIL failed, $SKIP skipped ($TOTAL total)"

if [[ $FAIL -gt 0 ]]; then
  exit 1
fi
