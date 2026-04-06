# metsuke (目付)

Claude Code plugin that enforces CLAUDE.md workflow compliance through hooks.

Named after the Edo-period inspector (目付) who monitored whether officials followed the rules — metsuke does the same for your AI coding agent.

## What it does

### Hard enforcement: PR review before commit

Blocks `git commit` if `pr-review-toolkit:review-pr` hasn't been run in the current session.

```
[metsuke] git commit blocked: レビュー未実施
pr-review-toolkit:review-pr を実行してください。
```

### Soft enforcement: Plan review reminder

In plan mode, injects a reminder to run plan-document-reviewer before presenting the plan to the user.

## How it works

```
SessionStart     → Clear markers, initialize tracking
PreToolUse(Bash) → Detect "git commit", block if no review marker
SubagentStop     → Detect pr-review-toolkit / plan-document-reviewer completion, create marker
UserPromptSubmit → Inject plan review reminder in plan mode
```

State is tracked via simple marker files in `/tmp/metsuke/`:

```
/tmp/metsuke/
├── <session-id>.pr-review-done     # Created when PR review completes
├── <session-id>.plan-review-done   # Created when plan review completes
└── <session-id>.skip               # Created by /metsuke:skip-review
```

## Install

```
/plugin install metsuke@metsuke-plugin
```

Or add to your `settings.json`:

```json
{
  "enabledPlugins": {
    "metsuke@metsuke-plugin": true
  },
  "extraKnownMarketplaces": {
    "metsuke-plugin": {
      "source": {
        "source": "github",
        "repo": "yoshi47/metsuke"
      }
    }
  }
}
```

## Configuration

Run `/metsuke:init` to create the config file at `~/.config/metsuke/config.json`:

```json
{
  "impl_review": {
    "enabled": true,
    "block_commit": true,
    "block_message": "[metsuke] git commit blocked: レビュー未実施\n...",
    "detection_patterns": ["pr-review-toolkit"]
  },
  "plan_review": {
    "enabled": true,
    "reminder_message": "[metsuke] プラン作成後は plan-document-reviewer で...",
    "detection_patterns": ["plan-document-reviewer"]
  }
}
```

All settings are optional — without a config file, sensible defaults are used.

## Commands

| Command | Description |
|---------|-------------|
| `/metsuke:init` | Create or reset configuration |
| `/metsuke:status` | Show current workflow compliance status |
| `/metsuke:skip-review` | Bypass review enforcement for this session |

## Escape hatches

- `/metsuke:skip-review` — creates a skip marker for the current session
- `METSUKE_SKIP=1` — environment variable to disable all enforcement

## Debug

Logs are written to `/tmp/metsuke/debug.log`. All hook stdin payloads are logged for troubleshooting.

## Known limitations

- Git aliases (e.g., `git ci`) bypass the commit gate
- Plan review is soft enforcement only (no blocking mechanism exists for plan presentation)
- SubagentStop payload format needs verification — the tracker checks multiple fields (`agent_type`, `agent_id`, `subagent_type`) as a safeguard

## License

MIT
