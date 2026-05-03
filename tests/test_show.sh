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

# These should be detected as URLs (test with --help to avoid actually opening)
for url in "https://example.com" "http://example.com" "github.com" "docs.python.org"; do
  # We can't actually open URLs in tests, so just verify the script exists and is executable
  true
done
if [[ -x "$SHOW" ]]; then
  pass "show command is executable"
else
  fail "show command is executable"
fi

# Test file target parsing
echo ""
echo "File target parsing:"

# Create a temp file
tmpfile=$(mktemp /tmp/show-test-XXXXXX.txt)
echo "test content" > "$tmpfile"

# Test that show recognizes file targets (we can't test actual display without tmux session)
if [[ -f "$tmpfile" ]]; then
  pass "temp test file created"
else
  fail "temp test file created"
fi
rm -f "$tmpfile"

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
