#!/bin/bash

# ============================================================
# 腳本位置：專案目錄/ci_scripts/ci_post_clone.sh
# ============================================================

# 1. 配置
DISCORD_WEBHOOK="https://discord.com/api/webhooks/1504314067114790932/Y9pWPtitNsphk49rdbK8ooDlAMvsoND_iG290iJ6eh5zzLrmZS_24YC0DGERECkqjTMK"
SCHEME="NES_EMU"

# 2. 處理 Xcode Cloud 的 Shallow Clone 問題
git fetch --unshallow --tags 2>/dev/null || git fetch --tags

# 3. 獲取版本資訊
# 優先找 1.0.4(1) 格式的 Tag
TAG_NAME=$(git tag --list "*([0-9]*)" --sort=-creatordate | head -n 1)

if [ -z "$TAG_NAME" ]; then
    TAG_NAME=$(git describe --tags --abbrev=0 2>/dev/null || echo "Initial_Build")
fi

# 定義 Commit 範圍
if [ "$TAG_NAME" = "Initial_Build" ]; then
    COMMIT_RANGE="HEAD"
else
    COMMIT_RANGE="$TAG_NAME..HEAD"
fi

# 4. 擷取符合 #222-修改項目 格式的 Changelog
CHANGELOG=$(git log "$COMMIT_RANGE" --first-parent --no-merges --pretty=format:'%s' | while read -r line; do
    if [[ "$line" =~ ^#[0-9]+- ]]; then
        echo "• $line"
    fi
done | sort -u | paste -sd "\\n" -)

if [ -z "$CHANGELOG" ]; then
    CHANGELOG="無更新說明"
fi

# 將 Changelog 存檔，以便後續 ci_post_xcodebuild.sh 讀取
echo "$CHANGELOG" > ../changelog_temp.txt

# 5. 發送「開始打包」通知
PAYLOAD=$(cat <<EOF
{
  "embeds": [{
    "title": "🍎 Xcode Cloud 流程啟動 — 準備打包 🏗️",
    "color": 3447003,
    "description": "**專案名稱：** ${SCHEME}\n**目前基準 Tag：** ${TAG_NAME}\n**觸發 Commit：** ${CI_COMMIT}\n\n**待處理更新內容：**\n${CHANGELOG}"
  }]
}
EOF
)

curl -H "Content-Type: application/json" -X POST -d "$PAYLOAD" "$DISCORD_WEBHOOK"

echo "✅ Git Log 擷取完成並已發送 Discord 通知。"