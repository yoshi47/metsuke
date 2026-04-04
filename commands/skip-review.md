---
description: Skip review enforcement for this session
allowed-tools: Bash(mkdir:*), Bash(touch:*)
---

# Skip Review

⚠️ **Warning**: This bypasses review enforcement for the current session. Use only for hotfixes or trivial changes.

To skip, create the marker file:
```bash
mkdir -p /tmp/metsuke && touch "/tmp/metsuke/${SESSION_ID}.skip"
```

Replace `${SESSION_ID}` with the actual session ID from the environment.

After creating the marker, confirm to the user that review enforcement is disabled for this session.
