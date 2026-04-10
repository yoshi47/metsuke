---
description: Show current metsuke workflow compliance status
allowed-tools: Bash(*metsuke*), Bash(ls:*), Bash(cat:*), Bash(jq:*), Bash(test:*)
---

# Metsuke Status

Check the current workflow compliance status for this session.

## Steps

1. Read the session ID from the debug log: `cat ${TMPDIR:-/tmp}/metsuke/debug.log | grep SessionStart | tail -1` to find the current session ID.

2. Read all configured checks dynamically:

```bash
jq -r '.checks[] | "\(.name)\t\(.enabled // true)\t\(.trigger)\t\(.action)"' ~/.config/metsuke/config.json
```

3. For each check, test the marker file and display as a checklist:

```bash
# For each check name from step 2:
test -f "${TMPDIR:-/tmp}/metsuke/${SESSION_ID}.${NAME}-done" && echo "[x]" || echo "[ ]"
```

Display format:
```
- [x] impl_review (pre_commit/block)
- [ ] plan_review (plan_mode/remind)
- Skip mode: active/inactive
```

Include `enabled: false` checks with a note: `- [-] security_review (disabled)`

4. Show skip status: check if `${TMPDIR:-/tmp}/metsuke/${SESSION_ID}.skip` exists.

5. Show the debug log tail if it exists: `tail -20 ${TMPDIR:-/tmp}/metsuke/debug.log 2>/dev/null`
