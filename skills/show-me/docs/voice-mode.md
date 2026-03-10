# Voice Mode Workflows

These commands are designed for hands-free voice interaction where typing is inconvenient.

## Basic file review workflow

```
User (voice): "Show me the main config file"
AI: show config/settings.yaml
AI (voice): "I've opened settings.yaml in Neovim for you"

User (voice): "What's in there?"
AI: look
AI (voice): "I can see the database configuration with host localhost
            port 5432, and logging set to debug level..."
```

## Code navigation workflow

```
User (voice): "Open the user authentication module"
AI: show src/auth/login.py
AI (voice): "I've opened the login module"

User (voice): "Go to where we handle the JWT tokens"
AI: show src/auth/login.py:156
AI (voice): "Jumped to line 156 where JWT validation happens"

User (voice): "What does that function look like?"
AI: look -l 30
AI (voice): "The validate_token function takes a token string,
            decodes it using the secret key, checks expiration..."
```

## Command output workflow

```
User (voice): "Show me what containers are running"
AI: show "cmd:docker ps"
AI (voice): "Running docker ps now"

User (voice): "What do you see?"
AI: look
AI (voice): "There are 3 containers running: postgres on port 5432,
            redis on 6379, and nginx on port 80"
```

## Debugging workflow

```
User (voice): "Run the tests and show me the output"
AI: show "cmd:pytest tests/ -v"
AI (voice): "Running pytest with verbose output"

[wait for tests to complete]

User (voice): "Did they pass?"
AI: look -l 100
AI (voice): "I can see 23 tests ran. 21 passed, but 2 failed.
            The failures are in test_auth.py - test_login_invalid_password
            and test_token_expiry. Want me to show you those test files?"
```

## Multi-pane observation

```
User (voice): "What's happening in all my panes?"
AI: look window
AI (voice): "You have 3 panes open. Pane 15 has Neovim editing main.py,
            pane 16 shows the output of your last git status, and
            pane 17 has a Python REPL with some test variables loaded."
```

## Context verification

```
User (voice): "I'm looking at something, can you see it?"
AI: look
AI (voice): "Yes, I can see you're viewing the error logs.
            There's a ConnectionRefused error from 2 minutes ago
            when trying to connect to the database on port 5432."
```

## Tips for Voice Mode

1. **Be specific**: "Show me the config file" vs "Show me settings.yaml"
2. **Use line numbers**: "Go to line 42" or "Open main.py at line 100"
3. **Request scrollback**: "Look at the last 100 lines" for command output
4. **Check hierarchy first**: "Show me what panes I have open" uses `look -H`
