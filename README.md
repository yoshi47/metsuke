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

## Getting started

### 1. Install

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

### 2. Initialize config

```
/metsuke:init
```

This creates `~/.config/metsuke/config.json` with default settings. **metsuke will not enforce anything until you run init.** Customize the config to match your workflow — messages, detection patterns, and which rules to enable are all configurable.

### 3. Done

metsuke is now active. It will block `git commit` without a review and remind you about plan reviews in plan mode.

## Configuration

`~/.config/metsuke/config.json`:

```json
{
  "impl_review": {
    "enabled": true,
    "block_commit": true,
    "block_message": "[metsuke] git commit blocked: ...",
    "detection_patterns": ["pr-review-toolkit"]
  },
  "plan_review": {
    "enabled": true,
    "reminder_message": "[metsuke] プラン作成後は ...",
    "detection_patterns": ["plan-document-reviewer"]
  }
}
```

| Key | Description | Default |
|-----|-------------|---------|
| `impl_review.enabled` | Enable PR review enforcement | `true` |
| `impl_review.block_commit` | Block git commit without review | `true` |
| `impl_review.block_message` | Message shown when commit is blocked | (Japanese) |
| `impl_review.detection_patterns` | Patterns to detect review completion in SubagentStop | `["pr-review-toolkit"]` |
| `plan_review.enabled` | Enable plan review reminders | `true` |
| `plan_review.reminder_message` | Reminder injected in plan mode | (Japanese) |
| `plan_review.detection_patterns` | Patterns to detect plan review completion | `["plan-document-reviewer"]` |

## How it works

```
SessionStart     → Clear markers, initialize tracking
PreToolUse(Bash) → Detect "git commit", block if no review marker
SubagentStop     → Detect review completion, create marker
UserPromptSubmit → Inject plan review reminder in plan mode
```

State is tracked via marker files in `/tmp/metsuke/`:

```
/tmp/metsuke/
├── <session-id>.pr-review-done     # Created when PR review completes
├── <session-id>.plan-review-done   # Created when plan review completes
└── <session-id>.skip               # Created by /metsuke:skip-review
```

## Commands

| Command | Description |
|---------|-------------|
| `/metsuke:init` | Create or reset configuration (run this first!) |
| `/metsuke:status` | Show current workflow compliance status |
| `/metsuke:skip-review` | Bypass review enforcement for this session |

## Escape hatches

- `/metsuke:skip-review` — creates a skip marker for the current session
- `METSUKE_SKIP=1` — environment variable to disable all enforcement

## Debug

Logs are written to `/tmp/metsuke/debug.log`.

## Known limitations

- Git aliases (e.g., `git ci`) bypass the commit gate
- Plan review is soft enforcement only (no blocking mechanism for plan presentation)
- SubagentStop payload format needs verification — the tracker checks multiple fields as a safeguard

## License

MIT
