#!/usr/bin/env bash
# Tests for the show-me command
# Run: make test

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SHOW="${SCRIPT_DIR}/../bin/show-me"
LOOK="${SCRIPT_DIR}/../bin/look-at"

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

# --- Concurrent file shows converge on one nvim pane (SHOW-110) ---
echo ""
echo "Concurrent reuse (SHOW-110):"

# The per-window find-or-create mutex must exist.
if declare -f acquire_show_lock >/dev/null 2>&1 && declare -f release_show_lock >/dev/null 2>&1; then
  pass "acquire_show_lock/release_show_lock functions exist"
else
  fail "acquire_show_lock/release_show_lock functions exist"
fi

# find_nvim_show_pane must NOT unconditionally rm an unresponsive socket — it
# should spare a pane that is still running nvim (slow cold start). Scan the
# function body and assert the rm is guarded by a pane-command check.
fnsp_block=$(awk '/^find_nvim_show_pane\(\) \{/,/^}/' "$SHOW")
if grep -q 'pane_current_command' <<<"$fnsp_block"; then
  pass "find_nvim_show_pane spares still-starting nvim (non-destructive, SHOW-110)"
else
  fail "find_nvim_show_pane non-destructive guard missing (would orphan a starting nvim)"
fi

# Integration: fire three file shows concurrently at one window; expect exactly
# one nvim pane (leader + 1 = 2 panes). The bug produced one pane per call (4).
if [[ -n "${TMUX:-}" ]] && command -v nvim >/dev/null 2>&1; then
  cc_sess="smtest-show110-$$"
  tmux kill-session -t "$cc_sess" 2>/dev/null || true
  tmux new-session -d -s "$cc_sess" -x 220 -y 60
  cc_leader=$(tmux list-panes -t "$cc_sess" -F '#{pane_id}' | head -1)
  cc_tmp=$(mktemp -d)
  for n in 1 2 3; do printf '# f%s\n' "$n" > "$cc_tmp/f$n.md"; done

  for n in 1 2 3; do
    TMUX_PANE="$cc_leader" "$SHOW" "$cc_tmp/f$n.md" >/dev/null 2>&1 &
  done
  wait
  sleep 2  # let any just-started nvim settle before counting

  cc_panes=$(tmux list-panes -t "$cc_sess" -F '#{pane_id}' 2>/dev/null | wc -l | tr -d ' ')
  if [[ "$cc_panes" -eq 2 ]]; then
    pass "3 concurrent file shows reuse one nvim pane (2 panes total)"
  else
    fail "3 concurrent file shows created $cc_panes panes (expected 2: leader + 1 nvim)"
  fi

  # Tidy: remove sockets for the test panes, kill the session, drop temp files.
  cc_sockdir=$(get_socket_dir)
  tmux list-panes -t "$cc_sess" -F '#{pane_id}' 2>/dev/null | while read -r p; do
    rm -f "${cc_sockdir}/nvim-show-pane-${p#%}" 2>/dev/null || true
  done
  tmux kill-session -t "$cc_sess" 2>/dev/null || true
  rm -rf "$cc_tmp"
else
  skip "concurrent reuse integration (needs tmux + nvim)"
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

# --- --restack flag (SHOW-98 impl-002) ---
echo ""
echo "--restack flag (SHOW-98 impl-002):"

# do_restack() handler must exist as a reusable function.
if grep -q '^do_restack() {' "$SHOW"; then
  pass "do_restack(): function defined"
else
  fail "do_restack(): function not defined"
fi

# main() must parse a --restack flag.
if grep -qE '^\s*--restack\)' "$SHOW"; then
  pass "main(): --restack parsed in argument loop"
else
  fail "main(): --restack not parsed in argument loop"
fi

# --restack must be handled before the "No target specified" check (no target).
main_block=$(awk '/^main\(\) \{/,/^}/' "$SHOW")
restack_ln=$(grep -n 'restack_mode" == true' <<<"$main_block" | head -1 | cut -d: -f1)
notarget_ln=$(grep -n 'No target specified' <<<"$main_block" | head -1 | cut -d: -f1)
if [[ -n "$restack_ln" && -n "$notarget_ln" && "$restack_ln" -lt "$notarget_ln" ]]; then
  pass "main(): --restack handled before the no-target check"
else
  fail "main(): --restack not handled before the no-target check"
fi

# do_restack(): layout precedence is explicit arg > SHOW_LAYOUT > stacked,
# validated via the same validator as --layout.
dr_block=$(awk '/^do_restack\(\) \{/,/^}/' "$SHOW")
if grep -q 'layout="$SHOW_LAYOUT"' <<<"$dr_block" \
   && grep -q 'layout="stacked"' <<<"$dr_block"; then
  pass "do_restack(): falls back to SHOW_LAYOUT then stacked"
else
  fail "do_restack(): missing SHOW_LAYOUT/stacked fallback"
fi
if grep -q 'validate_layout "$layout"' <<<"$dr_block"; then
  pass "do_restack(): validates layout via validate_layout()"
else
  fail "do_restack(): does not validate via validate_layout()"
fi

# Behavioral: --restack outside tmux exits non-zero with an actionable
# message, mirroring the stacked-layout error.
rs_out=$(env -u TMUX -u TMUX_PANE "$SHOW" --restack 2>&1) && rs_rc=0 || rs_rc=$?
if [[ "$rs_rc" -ne 0 ]] && grep -q 'requires running inside tmux' <<<"$rs_out"; then
  pass "--restack outside tmux: non-zero exit + actionable message"
else
  fail "--restack outside tmux: expected non-zero + tmux message (rc=$rs_rc, out=$rs_out)"
fi

# Behavioral: --restack needs no target (must not emit the no-target error).
if grep -q 'No target specified' <<<"$rs_out"; then
  fail "--restack still requires a target (got: $rs_out)"
else
  pass "--restack requires no target"
fi

# Behavioral: an invalid layout argument is rejected like --layout.
ri_out=$(env -u TMUX -u TMUX_PANE "$SHOW" --restack bogus 2>&1) && ri_rc=0 || ri_rc=$?
if [[ "$ri_rc" -ne 0 ]] && grep -q 'Invalid layout: bogus' <<<"$ri_out"; then
  pass "--restack rejects an invalid layout argument"
else
  fail "--restack rejects invalid layout (rc=$ri_rc, out=$ri_out)"
fi

# --- restack_layout() non-stacked mappings (SHOW-98 impl-003) ---
echo ""
echo "restack_layout non-stacked mappings (SHOW-98 impl-003):"

rl_block=$(awk '/^restack_layout\(\) \{/,/^}/' "$SHOW")

# right/left must arrange main-vertical (alongside stacked, leader ~30% width).
if grep -qE '^\s*stacked\|right\|left\)' <<<"$rl_block" \
   && grep -q 'select-layout .* main-vertical' <<<"$rl_block" \
   && grep -q 'resize-pane .* -x 30%' <<<"$rl_block"; then
  pass "restack_layout(): stacked/right/left -> main-vertical + leader 30% width"
else
  fail "restack_layout(): missing stacked/right/left main-vertical mapping"
fi

# below/above must arrange main-horizontal, leader-relative.
if grep -qE '^\s*below\|above\)' <<<"$rl_block" \
   && grep -q 'select-layout .* main-horizontal' <<<"$rl_block" \
   && grep -q 'resize-pane .* -y 70%' <<<"$rl_block"; then
  pass "restack_layout(): below/above -> main-horizontal + leader 70% height"
else
  fail "restack_layout(): missing below/above main-horizontal mapping"
fi

# Unsupported layout (window/here/other) -> clear message, non-zero, and no
# destructive tmux call in that arm.
default_arm=$(awk '/^\s*\*\)/,/;;/' <<<"$rl_block")
if grep -q 'does not support layout' <<<"$default_arm" \
   && grep -q 'return 1' <<<"$default_arm" \
   && ! grep -qE 'tmux (kill|select-layout|resize-pane)' <<<"$default_arm"; then
  pass "restack_layout(): unsupported layout -> clear message, no destructive action"
else
  fail "restack_layout(): unsupported-layout arm missing message/return or is destructive"
fi

# Behavioral: an unsupported-but-valid layout (window) does not crash; outside
# tmux it surfaces the tmux requirement (the unsupported message needs tmux).
rw_out=$(env -u TMUX -u TMUX_PANE "$SHOW" --restack window 2>&1) && rw_rc=0 || rw_rc=$?
if [[ "$rw_rc" -ne 0 ]] && ! grep -q 'No target specified' <<<"$rw_out"; then
  pass "--restack window: non-zero exit, no target required"
else
  fail "--restack window: expected non-zero without no-target error (rc=$rw_rc, out=$rw_out)"
fi

# --- --restack leader detection from a content pane (SHOW-104) ---
echo ""
echo "--restack leader detection (SHOW-104):"

# Regression: `show-me --restack` is human-invoked, typically from a CONTENT
# pane (Mike's shell), not the leader. The old code took TMUX_PANE to be the
# leader, so resize-pane targeted the content pane: leader stayed ~70% wide
# and content shrank to 30% -- backwards. The leader must be identified
# positionally (top-left pane), so invoking from a content pane still pins
# the *leader* to ~30%.
if [[ -n "${TMUX:-}" ]]; then
  rk_win=$(tmux new-window -d -P -F '#{window_id}')
  rk_leader=$(tmux list-panes -t "$rk_win" -F '#{pane_id}' | head -1)
  rk_content=$(tmux split-window -t "$rk_leader" -h -P -F '#{pane_id}')

  # Invoke --restack as if from the CONTENT pane (TMUX_PANE=$rk_content).
  rk_rc=0
  rk_out=$(TMUX_PANE="$rk_content" "$SHOW" --restack stacked 2>&1) || rk_rc=$?

  # Read back geometry. Leader is the top-left pane (pane_left == 0).
  rk_win_w=$(tmux display-message -p -t "$rk_win" '#{window_width}')
  rk_leader_w=$(tmux list-panes -t "$rk_win" \
    -F '#{pane_left} #{pane_width}' | awk '$1 == 0 { print $2; exit }')
  rk_content_w=$(tmux list-panes -t "$rk_win" \
    -F '#{pane_left} #{pane_width}' | awk '$1 != 0 { print $2; exit }')

  if [[ "$rk_rc" -eq 0 && -n "$rk_leader_w" && -n "$rk_content_w" \
        && "$rk_leader_w" -lt "$rk_content_w" \
        && $(( rk_leader_w * 100 / rk_win_w )) -lt 50 ]]; then
    pass "--restack from a content pane pins the leader to ~30% (leader=${rk_leader_w}/${rk_win_w})"
  else
    fail "--restack from a content pane pins the leader to ~30% (rc=$rk_rc, leader=${rk_leader_w}, content=${rk_content_w}, win=${rk_win_w}, out=$rk_out)"
  fi

  tmux kill-window -t "$rk_win" 2>/dev/null || true
else
  skip "--restack leader detection (not in tmux)"
fi

# --- --help + CHANGELOG document --restack (SHOW-98 impl-004) ---
echo ""
echo "--restack docs (SHOW-98 impl-004):"

help_out=$("$SHOW" --help 2>&1)

# --help Options must list the --restack flag.
if grep -qE -- '--restack \[?LAYOUT' <<<"$help_out"; then
  pass "--help documents the --restack flag"
else
  fail "--help does not document --restack"
fi

# --help must describe the default-layout behavior for --restack.
if grep -qi 'restack' <<<"$help_out" \
   && grep -qiE 'configured default layout|SHOW_LAYOUT' <<<"$help_out"; then
  pass "--help describes --restack default-layout behavior"
else
  fail "--help does not describe --restack default-layout behavior"
fi

# NOTE: a "CHANGELOG documents --restack" assertion intentionally does NOT
# live here. A changelog entry is immutable history -- once written it cannot
# regress -- so such a check has no ongoing value in a permanent suite, only
# runs forever asserting a historical fact, and is fragile to release
# mechanics (`make release` moves [Unreleased] into a versioned section).
# That "did we document the feature?" gate belongs in the task harness as a
# one-time acceptance check, which it had (SHOW-98 impl-004), not here.

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

# --- --cwd flag (SHOW-102) ---
echo ""
echo "--cwd flag (SHOW-102):"

# --cwd appears in --help Options
if "$SHOW" --help 2>&1 | grep -qE -- '--cwd PATH'; then
  pass "--help documents --cwd"
else
  fail "--help documents --cwd"
fi

# Invalid --cwd: hard error, non-zero exit, exact message, before any tmux
# work (no tmux session needed -- validation happens before pane creation).
bad_dir="/does/not/exist/$$"
cwd_rc=0
cwd_out=$("$SHOW" --cwd "$bad_dir" "cmd:pwd" 2>&1) || cwd_rc=$?
if [[ "$cwd_rc" -ne 0 ]]; then
  pass "--cwd invalid path exits non-zero"
else
  fail "--cwd invalid path exits non-zero (rc=$cwd_rc)"
fi
if [[ "$cwd_out" == "show-me: --cwd: no such directory: $bad_dir" ]]; then
  pass "--cwd invalid path prints the exact error message"
else
  fail "--cwd invalid path prints the exact error message (got: $cwd_out)"
fi

if [[ -n "${TMUX:-}" ]]; then
  cwd_tmp=$(mktemp -d)
  # Resolve like show-me does (pwd -P) so the comparison holds where
  # /tmp is a symlink (e.g. macOS /tmp -> /private/tmp).
  cwd_tmp_real=$(cd -- "$cwd_tmp" && pwd -P)

  # Invalid --cwd creates NO pane.
  panes_before=$(tmux list-panes -a -F '#{pane_id}' | sort)
  "$SHOW" --cwd "$bad_dir" "cmd:pwd" >/dev/null 2>&1 || true
  panes_after=$(tmux list-panes -a -F '#{pane_id}' | sort)
  if [[ "$panes_before" == "$panes_after" ]]; then
    pass "--cwd invalid path creates no pane"
  else
    fail "--cwd invalid path creates no pane (panes changed)"
  fi

  # Valid --cwd: the command runs in PATH (pane output shows the dir).
  c_out=$("$SHOW" --layout stacked --cwd "$cwd_tmp" "cmd:pwd" 2>/dev/null) || true
  c_pane=$(grep -oE '\[pane (%[0-9]+)\]' <<<"$c_out" | grep -oE '%[0-9]+' || true)
  if [[ -n "$c_pane" ]]; then
    # Poll: -J joins wrapped lines so a long temp path matches even when
    # the pane width wraps it. tr -d removes any residual wrap whitespace.
    pane_pwd=""
    for _ in 1 2 3 4 5 6 7 8 9 10; do
      sleep 0.3
      if tmux capture-pane -p -J -t "$c_pane" 2>/dev/null \
           | tr -d ' \n' | grep -qF "$(printf '%s' "$cwd_tmp_real" | tr -d ' ')"; then
        pane_pwd="found"
        break
      fi
    done
    if [[ -n "$pane_pwd" ]]; then
      pass "--cwd runs cmd: in the given directory"
    else
      fail "--cwd runs cmd: in the given directory (pane lacked $cwd_tmp_real)"
    fi
    # Emitted handle shows the user's original command, not the cd wrapper.
    if grep -qE 'Executed: pwd in ' <<<"$c_out" && ! grep -q 'cd -- ' <<<"$c_out"; then
      pass "--cwd handle shows original command (no cd wrapper leaked)"
    else
      fail "--cwd handle shows original command (got: $c_out)"
    fi
    tmux kill-pane -t "$c_pane" 2>/dev/null || true
  else
    fail "--cwd runs cmd: in the given directory (no pane emitted: $c_out)"
  fi

  # File/URL target: --cwd is a documented no-op (no error, opens normally).
  cwd_file="$cwd_tmp/note.txt"
  echo "hello" > "$cwd_file"
  nf_rc=0
  nf_out=$("$SHOW" --layout stacked --cwd "$cwd_tmp" "$cwd_file" 2>&1) || nf_rc=$?
  if [[ "$nf_rc" -eq 0 ]] && ! grep -q 'no such directory' <<<"$nf_out"; then
    pass "--cwd is a no-op for file targets (no error)"
  else
    fail "--cwd is a no-op for file targets (rc=$nf_rc, out=$nf_out)"
  fi
  # Tidy any panes the file open created in the show window.
  tmux list-panes -a -F '#{pane_id} #{pane_current_command}' 2>/dev/null \
    | awk '/ nvim$/{print $1}' | while read -r p; do
        tmux kill-pane -t "$p" 2>/dev/null || true
      done

  rm -rf "$cwd_tmp"
else
  skip "--cwd integration tests (not in tmux)"
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

# --- SHOW-131: extmark highlight, not a live visual selection ---
# The line-range highlight must be a passive buffer extmark that survives
# scrolling and keypresses, NOT a live visual-line selection
# (":<start><CR>V<end>G") whose cursor is one end of the selection (which
# extended on scroll and died on keypress). Regression guard: source-scan
# bin/show-me for the fix's shape.
echo ""
echo "SHOW-131 extmark highlight:"

# The old visual-mode keystrokes must be gone everywhere in the script.
if grep -qE 'V\$\{end_line\}G' "$SHOW"; then
  fail "highlight still uses a live visual-line selection (V\${end_line}G)"
else
  pass "no live visual-line selection keystrokes remain"
fi

# A single shared helper factors the highlight so the two call sites can't drift.
if grep -qE '^highlight_line_range\(\) \{' "$SHOW"; then
  pass "highlight_line_range helper exists"

  hlr_block=$(awk '/^highlight_line_range\(\) \{/,/^}/' "$SHOW")
  # Dedicated namespace, cleared before each apply, so reuse MOVES the highlight.
  if grep -q 'show_me_highlight' <<<"$hlr_block" \
     && grep -q 'nvim_buf_clear_namespace' <<<"$hlr_block"; then
    pass "helper clears the show_me_highlight namespace (reuse moves the highlight)"
  else
    fail "helper missing show_me_highlight namespace clear"
  fi

  # Applies a buffer extmark over the range.
  if grep -q 'nvim_buf_set_extmark' <<<"$hlr_block"; then
    pass "helper applies a buffer extmark"
  else
    fail "helper does not use nvim_buf_set_extmark"
  fi

  # Never enters visual mode.
  if grep -qE 'V\$\{end_line\}G' <<<"$hlr_block"; then
    fail "helper still enters visual mode"
  else
    pass "helper stays in normal mode (no visual selection)"
  fi
else
  fail "highlight_line_range helper exists"
fi

# Both line-range call sites delegate to the helper.
hlr_calls=$(grep -cE 'highlight_line_range "\$socket_path"' "$SHOW")
if [[ "$hlr_calls" -eq 2 ]]; then
  pass "both call sites use highlight_line_range ($hlr_calls found)"
else
  fail "expected 2 highlight_line_range call sites, found $hlr_calls"
fi

# --- Summary ---
echo ""
echo "===================="
TOTAL=$((PASS + FAIL + SKIP))
echo "Results: $PASS passed, $FAIL failed, $SKIP skipped ($TOTAL total)"

if [[ $FAIL -gt 0 ]]; then
  exit 1
fi
