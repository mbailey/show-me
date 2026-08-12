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
get_socket_dir() {
  if [[ -n "${TMPDIR:-}" && -d "$TMPDIR" ]]; then
    echo "$TMPDIR"
  elif [[ -n "${XDG_RUNTIME_DIR:-}" && -d "$XDG_RUNTIME_DIR" ]]; then
    echo "$XDG_RUNTIME_DIR"
  else
    local fallback="$HOME/.local/run"
    mkdir -p "$fallback" && chmod 700 "$fallback"
    echo "$fallback"
  fi
}
