---
description: Display files, URLs, or command output for the user to see
argument-hint: <target>
---

# /show-me:show

Display content for the user to view in the appropriate application.

## Usage

```
/show-me:show <target>
```

## Targets

- `<file>` - Open file in Neovim
- `<file>:<line>` - Open file at specific line
- `<file>:<start>-<end>` - Open file highlighting a line range (preferred for showing code sections)
- `<file>#L<line>` - Open file at specific line (URL fragment style)
- `<file>#L<start>-<end>` - Open file highlighting a line range (URL fragment style)
- `http://...` or `https://...` - Open URL in browser
- `cmd:<command>` - Run command in shell pane
- `pane:<id>` - Focus tmux pane by ID

## Examples

```
/show-me:show README.md
/show-me:show src/main.py:42
/show-me:show src/main.py:10-30
/show-me:show https://github.com/owner/repo
/show-me:show cmd:git status
```

**Tip:** Prefer ranges (`file:start-end`) over single lines when showing functions, blocks, or sections of code.

## Implementation

Run the show command from this plugin:

```bash
${CLAUDE_PLUGIN_ROOT}/bin/show $ARGUMENTS
```
