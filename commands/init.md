---
description: Initialize metsuke configuration
allowed-tools: Bash(mkdir:*), Bash(cp:*), Bash(cat:*), Read(*), Edit(*)
---

# Metsuke Init

Initialize or reset the metsuke configuration file at `~/.config/metsuke/config.json`.

## Steps

1. Check if `~/.config/metsuke/config.json` already exists
2. If it exists, show the current config and ask the user if they want to reset it
3. If it doesn't exist (or user wants to reset), copy the default config:

```bash
mkdir -p ~/.config/metsuke
cp "${CLAUDE_PLUGIN_ROOT}/config/default.json" ~/.config/metsuke/config.json
```

4. Show the config and explain each setting:

### Configuration Reference

```json
{
  "impl_review": {
    "enabled": true,              // PR レビュー強制を有効にするか
    "block_commit": true,         // git commit をブロックするか (false = リマインドのみ)
    "block_message": "...",       // ブロック時に表示するメッセージ
    "detection_patterns": [       // SubagentStop で検知するパターン (部分一致)
      "pr-review-toolkit"
    ]
  },
  "plan_review": {
    "enabled": true,              // プランレビューリマインドを有効にするか
    "reminder_message": "...",    // plan mode 時のリマインドメッセージ
    "detection_patterns": [       // SubagentStop で検知するパターン (部分一致)
      "plan-document-reviewer"
    ]
  }
}
```

5. Ask the user if they want to customize any settings, and help them edit the config file
