# Troubleshooting

Common issues and solutions for show-me commands.

## show: File doesn't open

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

## show: URL doesn't open

Verify browser availability:
```bash
which firefox                 # macOS/Linux
ls /Applications/Firefox.app  # macOS
```

Set a custom browser:
```bash
export SHOW_BROWSER=Chrome
show https://example.com
```

## look: Empty output

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
look -l 50                    # Get last 50 lines
```

## look: Neovim not detected

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

## look: Wrong pane captured

1. Check which pane you're in:
```bash
echo $TMUX_PANE               # Current pane ID
```

2. Use hierarchy to find the right pane:
```bash
look -H                       # Shows all panes with IDs
```

3. Target specific pane:
```bash
look %15                      # Capture pane %15 specifically
```

## Command path issues

The system `look` command (dictionary lookup) may shadow this package:

```bash
# Check which look is being used
which look
type look

# Use full path if needed
~/.metool/bin/look
${CLAUDE_PLUGIN_ROOT}/bin/look
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
