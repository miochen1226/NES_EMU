#!/bin/bash

# ============================================================
# 腳本位置：專案目錄/ci_scripts/ci_post_clone.sh
# 目的：在 Xcode Cloud 環境中擷取 Git Log 並發送 Discord 通知
# ============================================================

DISCORD_WEBHOOK="https://discord.com/api/webhooks/1504314067114790932/Y9pWPtitNsphk49rdbK8ooDlAMvsoND_iG290iJ6eh5zzLrmZS_24YC0DGERECkqjTMK"
SCHEME="NES_EMU"

# 1. 處理 Xcode Cloud 的 Shallow Clone 問題
git fetch --unshallow --tags 2>/dev/null || git fetch --tags

# 2. 獲取版本資訊 (方案二優化：識別 1.0.3(35) 格式)
# 優先抓取符合「數字.數字.數字(數字)」格式的最新 Tag
TAG_NAME=$(git tag --sort=-creatordate | grep -E '[0-9]+\.[0-9]+\.[0-9]+\([0-9]+\)' | head -n 1)

if [ -z "$TAG_NAME" ]; then
    # 如果抓不到新格式，則抓取任何既有 Tag 或使用 Initial_Build
    TAG_NAME=$(git describe --tags --abbrev=0 2>/dev/null || echo "Initial_Build")
fi

if [ "$TAG_NAME" = "Initial_Build" ]; then
    COMMIT_RANGE="HEAD"
else
    COMMIT_RANGE="$TAG_NAME..HEAD"
fi

# 3. 擷取並處理 Changelog
CHANGELOG_RAW=$(git log "$COMMIT_RANGE" --first-parent --no-merges --pretty=format:'%s' | while read -r line; do
    if [[ "$line" =~ ^#[0-9]+- ]]; then
        echo "• $line"
    fi
done | sort -u)

if [ -z "$CHANGELOG_RAW" ]; then
    CHANGELOG_RAW="無更新說明"
fi

# 將換行符轉義為 \n 以符合 JSON 格式
CHANGELOG_ESCAPED=$(echo "$CHANGELOG_RAW" | sed 's/\\/\\\\/g' | sed 's/"/\\"/g' | awk '{printf "%s\\n", $0}' | sed 's/\\n$//')

# 將原始內容存檔供 ci_post_xcodebuild.sh 讀取
echo "$CHANGELOG_RAW" > ../changelog_temp.txt

# 4. 發送「準備打包」通知
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

echo "✅ Git Log 擷取完成並已發送 Discord 通知。"