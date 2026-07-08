# Guided Voice Walkthroughs

`show-me` is the primitive for voice **show-and-tell**: hands-free sessions where
the user is looking at their screen and you narrate by voice (`voicemode:converse`)
instead of typing. The flagship use is the **code walkthrough** — guiding a user
through a codebase, a change, or a document, section by section. The core move is
**highlight first, then speak**: put the content in front of the user, confirm they
can see it, then talk about it.

## The highlight-then-narrate loop

Every step of a voice walkthrough is the same beat:

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

## Walkthrough etiquette

Short, imperative rules for giving a voice walkthrough. Validated in live
teaching sessions — follow them all.

### Opening

1. **Establish what to show first.** Confirm with the user what they want walked
   through before diving in; don't assume scope.
2. **Open with a roadmap.** One spoken line mapping what you'll cover and in what
   order ("Three stops: the route, the validator, then the token code").
3. **Orient in the project.** Give the user the big picture of where a file sits —
   reveal it in their file tree (e.g. Neo-tree's `:Neotree reveal` if their Neovim
   has it) or say the path aloud in project terms ("this is under src/auth,
   next to the session code").

### Moving around

4. **Show ranges, not single lines.** `show-me file:start-end` — frame the whole
   function or block (see above).
5. **Let reuse do the walking.** Re-`show-me` the same file to slide the highlight;
   don't open new windows.
6. **Announce before jumping.** Warn by voice *before* moving to a different file or
   a distant section — never blindside the user with a "space jump."

   ```
   AI (voice): "Let's switch over to the config file for a second."
   AI: show-me config/settings.yaml:8-15
   AI (voice): "Can you see the database block? ... Good."
   AI (voice): "Host is localhost, port 5432, logging is on debug."
   ```

   Within a single file, moving the highlight a few sections down doesn't need a
   full announcement — the reuse keeps them oriented.
7. **Confirm before moving on.** Once something's shown and described, check the
   user has taken it in before advancing to the next stop.
8. **Verify with `look-at`.** When in doubt — especially when troubleshooting —
   read the pane back to confirm the right thing is actually on screen (see
   [look-at](#look-at--check-what-the-user-sees) below).
9. **Hold focus while you talk.** `show-me --hold <secs>` keeps the highlighted
   content on screen during a long narration (the visual conch — see below).

### Narrating

10. **Explain the "why," not just the "what."** Narrate intent and reasoning, not a
    line-by-line transcription.
11. **Anchor verbally.** The user may be listening, not looking — always say the
    symbol *name* and *location* ("the `validate` function, top of auth.py").
12. **Make it a dialogue.** Explicitly invite interruptions and questions; don't
    monologue.

### Working style

13. **Edit with your own tools, not Neovim.** The user *watches* in Neovim while
    you edit with your own, more-current tools — don't drive their editor to make
    changes.
14. **Be flexible.** Adapt style when the user asks, or when you hit difficulties.

### Closing

15. **Recap at the close.** A short spoken summary of what was covered and the
    takeaways.

**Diffs and git history** are their own workflow. `show-me diff` / `show-me diff:<ref>`
opens Neovim DiffView (requires diffview.nvim) for a quick look at changes; the full
git-walkthrough treatment (lazygit, history spelunking, teach-the-tool sessions) is
tracked separately (SHOW-128) and not covered here.

## Prepared tours — script ahead, guide live

Preparing a *good* walkthrough takes deep reading of the codebase or PR. Giving one
takes only `show-me`, `look-at`, and a voice channel. Split the two: have a **capable
model prepare a tour file** ahead of time, and any model — including a smaller,
cheaper one — **drive it live**.

### The tour file

A tour is a markdown file: a pinned header, a spoken roadmap, ordered stops, and a
recap. Each stop is one beat of the highlight-then-narrate loop, pre-verified.

```markdown
# Tour: How login works

- repo: ~/code/acme-api
- commit: 3f9c2ab        # ranges verified against this commit
- audience: new backend dev, knows Python, new to this codebase
- stops: 5 (~15 min)

Roadmap: "Five stops — the route, credential validation, the token
step, config, and where the tests live."

## Stop 1 — the login route, top of routes/auth.py
show: show-me routes/auth.py:12-30
say:
- Entry point for POST /login; thin by design — all logic lives in
  the auth service so the route stays testable.
- Note the rate-limit decorator: added after the March incident.
check: "Make sense why the route is this thin?"

## Stop 2 — validate_credentials, middle of services/auth.py
show: show-me services/auth.py:38-72
say:
- The why: constant-time comparison here prevents timing attacks.
...

## Recap
- Route is thin; service owns the logic; tokens are 15-minute JWTs.
- Rate limiting exists because of a real incident — check its test.
```

### Preparing a tour (the capable model)

- **Explore first, script second.** Read the code until you can tell the *story* —
  a tour is a narrative with 5–9 stops, not a file listing.
- **Pin the commit** in the header and **verify every line range against it**.
  Ranges rot; an unverified stop highlights the wrong code live.
- **Write anchors as spoken names** (rule 11): each stop's heading is the words the
  guide will say — symbol name plus location.
- **Write talking points as intent** (rule 10): the why, the history, the gotcha —
  things a guide couldn't improvise from the code alone.
- Save the tour wherever the session keeps notes (a `tours/` directory in the repo,
  or the task directory).

### Guiding a tour (any model)

- Speak the roadmap, then run each stop in order: **announce → run the `show:` line
  verbatim → speak the `say:` points in your own words → ask the `check:` → advance.**
- All the etiquette above applies — the tour file feeds the loop; it doesn't replace
  the dialogue.
- If the repo has moved past the pinned commit, re-verify ranges before starting
  (or ask for the tour to be re-prepared).
- If asked something the notes don't cover, say so and offer to follow up — **don't
  invent answers**. The prep model wrote the facts; the guide's job is delivery.

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
