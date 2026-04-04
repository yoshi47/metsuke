---
description: Show current metsuke workflow compliance status
allowed-tools: Bash(*metsuke*), Bash(ls:*), Bash(cat:*)
---

# Metsuke Status

Check the current workflow compliance status for this session.

Run: `ls -la /tmp/metsuke/ 2>/dev/null | grep "$(echo $CLAUDE_SESSION_ID 2>/dev/null || echo unknown)"` to list markers for this session.

Display as a checklist:
- [ ] or [x] PR Review (pr-review-done marker)
- [ ] or [x] Plan Review (plan-review-done marker)
- Skip mode: active/inactive (skip marker)

Also show the debug log tail if it exists: `tail -20 /tmp/metsuke/debug.log 2>/dev/null`
