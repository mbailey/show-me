# Layouts

Reference for every `show-me` layout option, what it does, and when to pick it.

## Default

Since version 2.4.0, the default layout is **`stacked`**. With no `--layout`
flag and no `SHOW_LAYOUT` env var, `show-me` opens content as a stacked split in
the current tmux window.

To restore the pre-2.4 behavior (separate "show" window), set:

```bash
export SHOW_LAYOUT=window
```

…or pass `--layout window` per invocation.

## All options

| Layout    | Split direction | nvim reuse for files | New pane per `cmd:`  | Best for                                          |
| --------- | --------------- | -------------------- | -------------------- | ------------------------------------------------- |
| `stacked` | Right column, panes stack vertically | Yes (single nvim pane reused) | Yes (each cmd adds a pane) | Multi-show workflows, teammate panes, accumulating context. **Default.** |
| `right`   | Right of current pane | Yes | No (replaces existing pane) | Side-by-side reading while you keep typing on the left |
| `left`    | Left of current pane  | Yes | No                          | Same as right, opposite side |
| `below`   | Below current pane    | Yes | No                          | Wide single-line output (git log, tail -f)  |
| `above`   | Above current pane    | Yes | No                          | Same as below, opposite side |
| `window`  | Separate "show" window | Yes (replace-on-show) | Yes (in show window) | Pre-2.4 default. Use when you don't want any split in your current window. |

Notes:

- "nvim reuse for files" means a second `show-me file.md` lands the new buffer in
  the existing nvim pane rather than creating a fresh one. This is what makes
  the "show me X then show me Y replaces X" workflow work.
- "New pane per `cmd:`" is the teammate-accumulation behavior: each
  `show-me cmd:foo` creates its own pane so output history is preserved.
- `stacked` is the only layout where files and commands behave differently
  (files reuse, commands accumulate). The others either reuse for everything
  (`right`/`below`/`left`/`above`) or use the separate show window for
  everything (`window`).

## Selecting a layout

In priority order:

1. **`--layout VALUE`** on the command line (per-invocation override)
2. **`--here`** — shorthand for the content-type direction (`right` for files,
   `below` for commands). Use when you want a quick split without thinking
   about which direction.
3. **`SHOW_LAYOUT` env var** — your shell-wide default
4. **Built-in default** — `stacked`

Example:

```bash
# Built-in default
show-me README.md                    # stacked split, reuses nvim

# Shell-wide default
export SHOW_LAYOUT=right
show-me README.md                    # right split

# Per-invocation override
show-me --layout below README.md     # below split, ignores env var

# --here shorthand
show-me --here README.md             # right (because it's a file)
show-me --here cmd:make              # below (because it's a command)

# Escape hatch to pre-2.4 behavior
SHOW_LAYOUT=window show-me README.md # separate "show" window
```

## Split size

`SHOW_SPLIT_SIZE` (or per-call `--split-size`) overrides the default split
percentage:

- `right`/`left`: 70% wide
- `below`/`above`: 30% tall
- `stacked`: leader pane 30%, content stack 70% (rebalanced as panes are added)

## See also

- [`commands.md`](commands.md) — full command reference, including `look-at`
- [`troubleshooting.md`](troubleshooting.md) — common issues (tmux not
  running, Neovim socket, etc.)
- Source: [`bin/show-me`](../bin/show-me), function `validate_layout` and the
  `handle_file` / `handle_command` / `handle_diff` dispatchers
