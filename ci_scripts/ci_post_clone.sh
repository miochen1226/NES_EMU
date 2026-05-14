#!/bin/bash

# 1. 配置
DISCORD_WEBHOOK="https://discord.com/api/webhooks/1504314067114790932/Y9pWPtitNsphk49rdbK8ooDlAMvsoND_iG290iJ6eh5zzLrmZS_24YC0DGERECkqjTMK"

# 2. Git 處理
git fetch --unshallow --tags 2>/dev/null || git fetch --tags

# 3. 獲取基準 Tag (用於計算 Changelog)
PREVIOUS_TAG=$(git tag --sort=-creatordate | grep -E '[0-9]+\.[0-9]+\.[0-9]+\([0-9]+\)' | head -n 1)
[ -z "$PREVIOUS_TAG" ] && PREVIOUS_TAG="Initial_Build"

# 4. 決定本次產出的版號 (優先用系統注入的 40)
MARKETING_VERSION="1.0.3" 
CURRENT_BUILD_NUMBER=${CI_BUILD_NUMBER:-"Unknown"}
TARGET_TAG="${MARKETING_VERSION}(${CURRENT_BUILD_NUMBER})"

# 5. 擷取 Changelog
COMMIT_RANGE="$([ "$PREVIOUS_TAG" = "Initial_Build" ] && echo "HEAD" || echo "$PREVIOUS_TAG..HEAD")"
CHANGELOG=$(git log "$COMMIT_RANGE" --first-parent --no-merges --pretty=format:'%s' | while read -r line; do
    [[ "$line" =~ ^#[0-9]+- ]] && echo "• $line"
done | sort -u)
[ -z "$CHANGELOG" ] && CHANGELOG="無更新說明"
echo "$CHANGELOG" > ../changelog_temp.txt

# 6. 發送通知
CHANGELOG_ESCAPED=$(echo "$CHANGELOG" | sed 's/\\/\\\\/g; s/"/\\"/g' | awk '{printf "%s\\n", $0}' | sed 's/\\n$//')
PAYLOAD=$(cat <<EOF
{
  "embeds": [{
    "title": "🏗️ Xcode Cloud 開始建置 [Build #${CURRENT_BUILD_NUMBER}]",
    "color": 3447003,
    "description": "**預計產出版本:** ${TARGET_TAG}\n**基準 Tag:** ${PREVIOUS_TAG}\n\n**更新內容:**\n${CHANGELOG_ESCAPED}"
  }]
}
EOF
)
curl -H "Content-Type: application/json" -X POST -d "$PAYLOAD" "$DISCORD_WEBHOOK"