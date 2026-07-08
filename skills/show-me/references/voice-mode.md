# Voice Mode Workflows

`show-me` is the primitive for voice **show-and-tell**: hands-free sessions where
the user is looking at their screen and you narrate by voice (`voicemode:converse`)
instead of typing. The core move is **highlight first, then speak** — put the
content in front of the user, confirm they can see it, then talk about it.

## The highlight-then-narrate loop

This is the primary workflow. Every step of a voice walkthrough is the same beat:

1. **Highlight** — `show-me <file>:<start>-<end>` opens the file in the user's
   Neovim and highlights that line range.
2. **Narrate** — speak about the block you just highlighted.
3. **Repeat** — move the highlight to the next range and narrate again.

```
User (voice): "Walk me through the login handler"
AI: show-me src/auth/login.py:38-72
AI (voice): "This is validate_credentials. It takes the username and
            password, looks up the user, and hands off to the token step
            at the bottom — line 70."

User (voice): "OK, show me that token step"
AI: show-me src/auth/login.py:70-95
AI (voice): "Here's issue_token. It signs a JWT with the secret and sets
            a 15-minute expiry."
```

**Prefer ranges over single lines.** A single line rarely gives the user enough
context to follow. When you point at a function, a bug, or a block of logic, show
the whole range so the highlight frames the complete picture. (`show-me main.py:42`
→ `show-me main.py:38-55`.)

## Reuse moves the highlight

Re-running `show-me` with a new range **on the same file reuses the pane and moves
the highlight** — it does not open a new window. This is the cheap, clean way to
walk through a file section by section: the user's view stays put and the highlight
slides to wherever you're talking about.

```
AI: show-me src/server.py:1-40      # highlight the imports + setup
AI (voice): "Top of the file wires up the app and the middleware."

AI: show-me src/server.py:120-160   # SAME pane, highlight just moves down
AI (voice): "Now down here is the route table..."
```

Rely on this instead of closing and reopening. In split layouts, subsequent file
shows land in the existing Neovim pane by design (`SHOW_LAYOUT` controls where
content first appears).

## Announce before you jump

Reuse is seamless *within* a file. When you **change files** or jump to a **distant
section**, the highlight lands somewhere the user isn't expecting — so announce the
move first, and check they're with you before narrating.

```
AI (voice): "Let's switch over to the config file for a second."
AI: show-me config/settings.yaml:8-15
AI (voice): "Can you see the database block? ... Good."
AI (voice): "Host is localhost, port 5432, logging is on debug."
```

The etiquette:

- **Announce the jump** by voice *before* running `show-me`, so the user knows the
  view is about to change.
- **Check they can see it** ("can you see it?") before you start narrating a new
  file or a far-off section — don't talk to a highlight they haven't found yet.
- Within a single file, moving the highlight a few sections down doesn't need a
  full announcement — the reuse keeps them oriented.

## Focus hold — the visual conch

When VoiceMode auto-focus-pane is enabled (`VOICEMODE_AUTO_FOCUS_PANE=true`), the
speaking agent normally pulls tmux focus back to its **own** pane. In a show-and-tell
that's exactly wrong: you just highlighted something for the user and then speaking
yanks them off it before they've read it.

`show-me` solves this by writing a **focus-hold sentinel**. Every `show-me` writes
the hold duration to `~/.voicemode/focus-hold`; VoiceMode reads that sentinel and
**skips auto-focus** for that many seconds, so the freshly highlighted file stays on
screen while you speak. This is the "visual conch" — you took visual focus, and
speaking won't steal it back until the hold expires.

The `--hold SECONDS` flag sets the duration (default **30s**):

```
User (voice): "Show me the error log and read me the last failure"
AI: show-me --hold 60 /var/log/app.log
AI (voice): "Opened the error log — take your time. The last failure is a
            ConnectionRefused to the database on port 5432, two minutes ago."
# Focus stays on the log for 60s even though the agent spoke
```

Use a **longer** hold for something the user needs to read carefully (a document, a
stack trace); the default 30s is fine for a quick glance. The loop above works
whether or not auto-focus is enabled — the sentinel simply keeps highlight-then-
narrate from fighting the user for the screen when it is.

## look-at — check what the user sees

`look-at` reads a pane back so you can confirm context or answer "can you see this?"
It's the read side of show-and-tell.

```
User (voice): "I'm looking at something — can you see it?"
AI: look-at
AI (voice): "Yes — you're on the error logs, there's a ConnectionRefused
            from two minutes ago hitting the database on port 5432."
```

```
look-at                              # current pane
look-at -l 100                       # last 100 lines (scrollback for cmd output)
look-at -H                           # hierarchy: what panes/windows exist
look-at window                       # every pane in the window
```

## Command output

`show-me "cmd:..."` runs a command in a shell pane; read its output back with
`look-at -l` (or `--format json` for a machine handle — see the SKILL reference).

```
User (voice): "Run the tests and tell me what broke"
AI: show-me "cmd:pytest tests/ -v"
AI (voice): "Running the suite now."

[wait for it to finish]

AI: look-at -l 100
AI (voice): "23 ran, 21 passed. Two failures, both in test_auth.py —
            test_login_invalid_password and test_token_expiry."
```

## Tips

1. **Highlight before you speak** — never narrate a block you haven't put on screen.
2. **Prefer ranges** — `file:38-55`, not `file:42`; frame the whole thing.
3. **Let reuse do the walking** — re-`show-me` the same file to slide the highlight;
   don't open new windows.
4. **Announce file jumps** and check the user sees the new highlight first.
5. **Hold for reading** — `--hold 60` (or longer) when the user needs time; the
   sentinel keeps focus from snapping back to you.
6. **`look-at` to confirm** — use it to verify shared context before you narrate.
</content>
</invoke>
