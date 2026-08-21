# shellcheck shell=bash
# socket-dir.sh - shared socket-directory logic for the show-me package
#
# Sourced, not executed. Single source of truth for the directory where
# show-me creates Neovim listen sockets and where look-at discovers them.
# Shared so producer and consumer cannot drift (issue #33: look-at carried
# a hardcoded /tmp path that never matched what show-me creates, so socket
# reads silently fell back to a screen-scrape).

# Get private socket directory for security
# Returns user-private directory instead of world-readable /tmp
#
# Trailing slashes are stripped (macOS sets TMPDIR with one), so derived
# socket paths compare equal as strings across producers and consumers.
get_socket_dir() {
  local dir
  if [[ -n "${TMPDIR:-}" && -d "$TMPDIR" ]]; then
    dir="$TMPDIR"
  elif [[ -n "${XDG_RUNTIME_DIR:-}" && -d "$XDG_RUNTIME_DIR" ]]; then
    dir="$XDG_RUNTIME_DIR"
  else
    dir="$HOME/.local/run"
    mkdir -p "$dir" && chmod 700 "$dir"
  fi
  while [[ "$dir" == */ && "$dir" != "/" ]]; do dir="${dir%/}"; done
  echo "$dir"
}
