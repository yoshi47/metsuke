---
description: Skip review enforcement for this session
allowed-tools: Bash(mkdir:*), Bash(touch:*), Bash(cat:*)
---

# Skip Review

⚠️ **Warning**: This bypasses review enforcement for the current session. Use only for hotfixes or trivial changes.

Steps:
1. Read the session ID: `cat /tmp/metsuke/debug.log | grep SessionStart | tail -1` to find the current session ID
2. Create the skip marker: `mkdir -p /tmp/metsuke && touch "/tmp/metsuke/<SESSION_ID>.skip"` (replace `<SESSION_ID>` with the actual value)
3. Confirm to the user that review enforcement is disabled for this session
