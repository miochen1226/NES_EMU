#!/bin/bash

# ============================================================
# 腳本位置：專案目錄/ci_scripts/ci_post_clone.sh
# ============================================================

DISCORD_WEBHOOK="https://discord.com/api/webhooks/1504314067114790932/Y9pWPtitNsphk49rdbK8ooDlAMvsoND_iG290iJ6eh5zzLrmZS_24YC0DGERECkqjTMK"

# 1. 處理 Shallow Clone 確保 Git 歷史完整
git fetch --unshallow --tags 2>/dev/null || git fetch --tags

# 2. 獲取基準 Tag
PREVIOUS_TAG=$(git tag --sort=-creatordate | grep -E '[0-9]+\.[0-9]+\.[0-9]+\([0-9]+\)' | head -n 1)
[ -z "$PREVIOUS_TAG" ] && PREVIOUS_TAG=$(git describe --tags --abbrev=0 2>/dev/null || echo "Initial_Build")

# 3. 擷取 Changelog
# 修改重點：使用 grep -E '#[0-9]+' 來匹配 commit 內容
COMMIT_RANGE="$([ "$PREVIOUS_TAG" = "Initial_Build" ] && echo "HEAD" || echo "$PREVIOUS_TAG..HEAD")"
CHANGELOG=$(git log "$COMMIT_RANGE" --first-parent --no-merges --pretty=format:'%s' | while read -r line; do
    if [[ "$line" =~ #[0-9]+ ]]; then
        echo "• $line"
    fi
done | sort -u)

# 備援：若無特定格式則抓取最新 3 筆，確保訊息不為空
if [ -z "$CHANGELOG" ]; then
    CHANGELOG=$(git log -n 3 --pretty=format:'• %s')
fi

# 將 Changelog 存入暫存檔供 post_xcodebuild 使用
echo "$CHANGELOG" > ../changelog_temp.txt

# 4. 準備 Discord JSON
MARKETING_VERSION="1.0.3"
TARGET_TAG="${MARKETING_VERSION}(${CI_BUILD_NUMBER:-0})"
CHANGELOG_ESCAPED=$(echo "$CHANGELOG" | sed 's/\\/\\\\/g; s/"/\\"/g' | awk '{printf "%s\\n", $0}' | sed 's/\\n$//')

PAYLOAD=$(cat <<EOF
{
  "embeds": [{
    "title": "🏗️ Xcode Cloud 開始建置 [Build #${CI_BUILD_NUMBER}]",
    "color": 3447003,
    "description": "**預計版本:** ${TARGET_TAG}\n**基準 Tag:** ${PREVIOUS_TAG}\n\n**更新內容:**\n${CHANGELOG_ESCAPED}"
  }]
}
EOF
)

# 發送通知
echo "$PAYLOAD" | curl -H "Content-Type: application/json" -X POST -d @- "$DISCORD_WEBHOOK"