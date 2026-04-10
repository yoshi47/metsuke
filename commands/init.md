---
description: Customize metsuke configuration
allowed-tools: Bash(mkdir:*), Bash(cp:*), Bash(cat:*), Read(*), Edit(*)
---

# Metsuke Configuration

Customize your metsuke configuration. metsuke works out of the box with sensible defaults — use this command to add custom checks, modify messages, or change detection patterns.

## Steps

1. Check if `~/.config/metsuke/config.json` already exists
2. If it exists, show the current config and ask the user what they want to change
3. If it doesn't exist, copy the default config for editing:

```bash
mkdir -p ~/.config/metsuke
cp "${CLAUDE_PLUGIN_ROOT}/config/default.json" ~/.config/metsuke/config.json
```

4. Show the config and explain each setting:

### Configuration Reference

設定は `checks` 配列で構成されます。各チェックは以下のフィールドを持ちます:

```json
{
  "checks": [
    {
      "name": "impl_review",           // チェックの識別名（マーカーファイル名に使用）
      "enabled": true,                 // true/false — false で一時無効化（配列から削除不要）
      "trigger": "pre_commit",         // いつチェックするか（下記参照）
      "action": "block",              // チェック未完了時の動作（下記参照）
      "detection_patterns": [          // SubagentStop で検知するパターン（部分一致）
        "pr-review-toolkit"
      ],
      "message": "..."                 // チェック未完了時に表示するメッセージ
    }
  ]
}
```

#### trigger の種類

| trigger | 説明 |
|---|---|
| `pre_commit` | `git commit` 実行時にチェック（PreToolUse フック） |
| `plan_mode` | plan mode でのプロンプト送信時にリマインド（UserPromptSubmit フック） |

#### action の種類

| action | 説明 |
|---|---|
| `block` | ツール実行をブロック（`pre_commit` トリガーでのみ有効） |
| `remind` | メッセージを表示するのみ（ブロックしない） |

※ `plan_mode` + `block` の組み合わせは `remind` として扱われます。

#### カスタムチェックの追加例

セキュリティレビューチェックを追加する場合:

```json
{
  "name": "security_review",
  "enabled": true,
  "trigger": "pre_commit",
  "action": "block",
  "detection_patterns": ["security-review", "security-audit"],
  "message": "[metsuke] git commit blocked: セキュリティレビュー未実施\nセキュリティレビューを実行してください。"
}
```

5. Ask the user if they want to customize any settings (add/remove/modify checks), and help them edit the config file
