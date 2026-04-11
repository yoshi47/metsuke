# metsuke (目付)

Claude Code plugin that enforces CLAUDE.md workflow compliance through hooks.

Named after the Edo-period inspector (目付) who monitored whether officials followed the rules — metsuke does the same for your AI coding agent.

## What it does

### Hard enforcement: PR review before commit

Blocks `git commit` if `pr-review-toolkit:review-pr` hasn't been run in the current session.

```
[metsuke] git commit blocked: レビュー未実施
pr-review-toolkit:review-pr を実行してください。

回避: /metsuke:skip-review または METSUKE_SKIP=1
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

### 2. Done

metsuke is now active. It blocks `git commit` without a review and reminds about plan reviews in plan mode using default settings.

### 3. Customize (optional)

```
/metsuke:configure
```

Creates `~/.config/metsuke/config.json` for customization. See [Configuration](#configuration) below.

## Configuration

metsuke works with no configuration. To customize, run `/metsuke:configure` to create `~/.config/metsuke/config.json`:

```json
{
  "commit_aliases": [],
  "checks": [
    {
      "name": "impl_review",
      "enabled": true,
      "trigger": "pre_commit",
      "action": "block",
      "detection_patterns": ["pr-review-toolkit"],
      "message": "[metsuke] git commit blocked: レビュー未実施\npr-review-toolkit:review-pr を実行してください。"
    },
    {
      "name": "plan_review",
      "enabled": true,
      "trigger": "plan_mode",
      "action": "remind",
      "detection_patterns": ["plan-document-reviewer"],
      "message": "[metsuke] プラン作成後は plan-document-reviewer でレビューしてからユーザーに提示してください。"
    }
  ]
}
```

| Field | Description |
|-------|-------------|
| `commit_aliases` | Regex patterns for custom git commit aliases (e.g., `["\\bgit\\s+ci(\\s|$)"]`) |
| `checks[].name` | Check identifier (used in marker filenames) |
| `checks[].enabled` | Enable/disable without removing from array |
| `checks[].trigger` | `pre_commit` (blocks at git commit) or `plan_mode` (reminds in plan mode) |
| `checks[].action` | `block` (pre_commit only) or `remind` |
| `checks[].detection_patterns` | Substring patterns matched against SubagentStop payload |
| `checks[].message` | Message shown when check is unsatisfied |

## How it works

```
SessionStart     → Clear markers, initialize tracking
PreToolUse(Bash) → Detect "git commit", block if no review marker
SubagentStop     → Detect review completion, create marker
UserPromptSubmit → Inject plan review reminder in plan mode
```

State is tracked via marker files in `${TMPDIR}/metsuke/`:

```
${TMPDIR}/metsuke/
├── <session-id>.impl_review-done    # Created when PR review completes
├── <session-id>.plan_review-done    # Created when plan review completes
└── <session-id>.skip                # Created by /metsuke:skip-review
```

## Skills

| Skill | Description |
|-------|-------------|
| `/metsuke:configure` | Customize configuration |
| `/metsuke:status` | Show current workflow compliance status |
| `/metsuke:skip-review` | Bypass review enforcement for this session |

## Escape hatches

- `/metsuke:skip-review` — creates a skip marker for the current session
- `METSUKE_SKIP=1` — environment variable to disable all enforcement

## Debug

Logs are written to `${TMPDIR}/metsuke/debug.log`.

## Known limitations

- Git aliases (e.g., `git ci`) bypass the commit gate by default. Add custom patterns to `commit_aliases` in config to catch them.
- Plan review is soft enforcement only (no blocking mechanism for plan presentation)
- SubagentStop payload format is not fully documented by Claude Code — the tracker checks multiple fields as a safeguard

## License

MIT
