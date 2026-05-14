#!/bin/bash

# 1. 配置
DISCORD_WEBHOOK="https://discord.com/api/webhooks/1504314067114790932/Y9pWPtitNsphk49rdbK8ooDlAMvsoND_iG290iJ6eh5zzLrmZS_24YC0DGERECkqjTMK"

# 2. 處理 Shallow Clone
git fetch --unshallow --tags 2>/dev/null || git fetch --tags

# 3. 獲取版本資訊
# 偵錯：印出目前 Git 裡所有的 Tag 狀況
ALL_TAGS=$(git tag --sort=-creatordate | head -n 5 | paste -sd ", " -)
TAG_NAME=$(git tag --sort=-creatordate | grep -E '[0-9]+\.[0-9]+\.[0-9]+\([0-9]+\)' | head -n 1)
[ -z "$TAG_NAME" ] && TAG_NAME=$(git describe --tags --abbrev=0 2>/dev/null || echo "Initial_Build")

# 4. 偵錯：檢查 Xcode Cloud 注入的變數
# 這裡是關鍵，看看 CI_BUILD_NUMBER 到底是 5 還是 38
DEBUG_INFO="Build編號: ${CI_BUILD_NUMBER:-未定義} | 工作流: ${CI_WORKFLOW_ID:-未知}"

# 5. 擷取 Changelog
COMMIT_RANGE="$([ "$TAG_NAME" = "Initial_Build" ] && echo "HEAD" || echo "$TAG_NAME..HEAD")"
CHANGELOG=$(git log "$COMMIT_RANGE" --first-parent --no-merges --pretty=format:'%s' | while read -r line; do
    [[ "$line" =~ ^#[0-9]+- ]] && echo "• $line"
done | sort -u)
[ -z "$CHANGELOG" ] && CHANGELOG="無更新說明"
echo "$CHANGELOG" > ../changelog_temp.txt

# 轉義 JSON
CHANGELOG_ESCAPED=$(echo "$CHANGELOG" | sed 's/\\/\\\\/g; s/"/\\"/g' | awk '{printf "%s\\n", $0}' | sed 's/\\n$//')

# 6. 發送通知
PAYLOAD=$(cat <<EOF
{
  "embeds": [{
    "title": "🍎 [Debug模式] Xcode Cloud 啟動",
    "color": 3447003,
    "description": "**基準 Tag:** ${TAG_NAME}\n**系統注入編號:** ${CI_BUILD_NUMBER}\n**Debug詳情:** ${DEBUG_INFO}\n**最近Tags:** ${ALL_TAGS}\n\n**待處理更新:**\n${CHANGELOG_ESCAPED}"
  }]
}
EOF
)
curl -H "Content-Type: application/json" -X POST -d "$PAYLOAD" "$DISCORD_WEBHOOK"