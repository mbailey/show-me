# Troubleshooting

Common issues and solutions for show-me commands.

## show-me: File doesn't open

1. Check if Neovim socket exists:
```bash
nvim-socket list              # From neovim package
ls /tmp/nvim-tmux-pane-*      # Socket files
```

2. Verify tmux is running:
```bash
tmux list-sessions
```

3. Check the show session exists:
```bash
tmux has-session -t show 2>/dev/null && echo "exists"
```

## show-me: URL doesn't open

Verify browser availability:
```bash
which firefox                 # macOS/Linux
ls /Applications/Firefox.app  # macOS
```

Set a custom browser:
```bash
export SHOW_BROWSER=Chrome
show-me https://example.com
```

## look-at: Empty output

1. Ensure you're in a tmux session:
```bash
echo $TMUX                    # Should show tmux socket path
```

2. Check pane has content:
```bash
tmux capture-pane -p          # Direct tmux capture
```

3. Try with scrollback:
```bash
look-at -l 50                 # Get last 50 lines
```

## look-at: Neovim not detected

1. Verify Neovim is running with socket:
```bash
nvim --listen /tmp/nvim-tmux-pane-15 file.txt
```

2. Check socket is responsive:
```bash
nvim --server /tmp/nvim-tmux-pane-15 --remote-expr "1"
```

3. List available sockets:
```bash
ls /tmp/nvim-tmux-pane-*
```

## look-at: Wrong pane captured

1. Check which pane you're in:
```bash
echo $TMUX_PANE               # Current pane ID
```

2. Use hierarchy to find the right pane:
```bash
look-at -H                    # Shows all panes with IDs
```

3. Target specific pane:
```bash
look-at %15                   # Capture pane %15 specifically
```

## "show: command has been renamed" / `look` returns dictionary words

The commands were renamed to `show-me` and `look-at` (SHOW-58) so they no
longer clash with system binaries:

- Calling `show` now prints a migration error and exits non-zero. Update the
  invocation to `show-me`.
- The old `look` was silently shadowed by the system `look` (util-linux
  dictionary lookup), so it could return dictionary words instead of pane
  content. Use `look-at` — it has no system clash.

```bash
which show-me look-at         # Confirm the renamed commands are on PATH
```

If `show-me` / `look-at` are not found, check the install:

```bash
ls ~/.metool/bin/show-me ~/.metool/bin/look-at      # If installed via metool
ls ${CLAUDE_PLUGIN_ROOT}/bin/show-me                # From Claude Code's Bash tool, when installed as a plugin
```

## Requirements Check

```bash
# Required
tmux -V                       # tmux version
nvim --version | head -1      # Neovim version

# Optional
which firefox                 # Browser for URLs
which nvim-remote             # Enhanced Neovim support
```
