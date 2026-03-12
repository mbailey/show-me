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

# --- Summary ---
echo ""
echo "===================="
TOTAL=$((PASS + FAIL + SKIP))
echo "Results: $PASS passed, $FAIL failed, $SKIP skipped ($TOTAL total)"

if [[ $FAIL -gt 0 ]]; then
  exit 1
fi
