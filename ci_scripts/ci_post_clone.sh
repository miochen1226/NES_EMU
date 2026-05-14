#!/bin/bash

# 1. 配置
DISCORD_WEBHOOK="https://discord.com/api/webhooks/1504314067114790932/Y9pWPtitNsphk49rdbK8ooDlAMvsoND_iG290iJ6eh5zzLrmZS_24YC0DGERECkqjTMK"
SCHEME="NES_EMU"

# 2. 處理 Shallow Clone 確保能看到舊 Tag
git fetch --unshallow --tags 2>/dev/null || git fetch --tags

# 3. 獲取版本資訊 (精準識別帶括號格式)
# 優先抓取符合 1.x.x(x) 格式的最新 Tag
TAG_NAME=$(git tag --sort=-creatordate | grep -E '[0-9]+\.[0-9]+\.[0-9]+\([0-9]+\)' | head -n 1)

if [ -z "$TAG_NAME" ]; then
    TAG_NAME=$(git describe --tags --abbrev=0 2>/dev/null || echo "Initial_Build")
fi

COMMIT_RANGE="$([ "$TAG_NAME" = "Initial_Build" ] && echo "HEAD" || echo "$TAG_NAME..HEAD")"

# 4. 擷取並轉義 Changelog (處理 JSON 特殊字元防止發送失敗)
CHANGELOG_RAW=$(git log "$COMMIT_RANGE" --first-parent --no-merges --pretty=format:'%s' | while read -r line; do
    [[ "$line" =~ ^#[0-9]+- ]] && echo "• $line"
done | sort -u)

[ -z "$CHANGELOG_RAW" ] && CHANGELOG_RAW="無更新說明"
CHANGELOG_ESCAPED=$(echo "$CHANGELOG_RAW" | sed 's/\\/\\\\/g; s/"/\\"/g' | awk '{printf "%s\\n", $0}' | sed 's/\\n$//')

echo "$CHANGELOG_RAW" > ../changelog_temp.txt

# 5. 發送通知
# 注意：預計版本在這裡顯示為 "Xcode Cloud 自動編號"，因為確切數字要編譯後才知道
PAYLOAD=$(cat <<EOF
{
  "embeds": [{
    "title": "🍎 Xcode Cloud 流程啟動 — 準備打包 🏗️",
    "color": 3447003,
    "description": "**專案名稱：** ${SCHEME}\n**目前基準 Tag：** ${TAG_NAME}\n**觸發 Commit：** ${CI_COMMIT}\n\n**待處理更新內容：**\n${CHANGELOG_ESCAPED}"
  }]
}
EOF
)
curl -H "Content-Type: application/json" -X POST -d "$PAYLOAD" "$DISCORD_WEBHOOK"