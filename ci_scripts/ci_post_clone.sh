#!/bin/bash

# ============================================================
# 腳本位置：專案目錄/ci_scripts/ci_post_clone.sh
# 目的：在 Xcode Cloud 環境中擷取 Git Log 並發送 Discord 通知
# ============================================================

# 1. 配置
DISCORD_WEBHOOK="https://discord.com/api/webhooks/1494864601500618783/ubSTg2Y_uS_pKvjTKSRHWm8vaBkO8Y4bvunh07l9EQUQqp_daQWX-CYtwaXGiQEru3ZF"
SCHEME="Recruit"

# 2. 處理 Xcode Cloud 的 Shallow Clone 問題
# 必須 fetch tags 才能讓 git describe 與 git log 運作
git fetch --unshallow --tags

# 3. 獲取版本資訊
# 取得最近的 Tag 名稱
TAG_NAME=$(git describe --tags --abbrev=0 2>/dev/null || echo "Initial_Build")
# 格式化版本號 (假設 Tag 格式為 Build_v5.9.47(8))
VERSION=$(echo "$TAG_NAME" | sed -E 's/Build_v(.+)\((.+)\)/\1 (\2)/')

# 4. 擷取 Changelog (延用 Fastfile 的過濾邏輯)
CHANGELOG=$(git log "$TAG_NAME..HEAD" --merges --pretty=format:'%s' | while read -r line; do
    # 擷取分支名稱
    BRANCH=$(echo "$line" | sed -E "s/Merge branch '(.+)' into.*/\1/; s/Merge pull request #[0-9]+ from .+\/(.+)/\1/")
    
    # 過濾環境分支與無意義標題
    if [[ ! "$BRANCH" =~ ^(release|main|master|develop|Release)/ ]] && [[ "$BRANCH" != "$line" ]]; then
        echo "• $BRANCH"
    fi
done | sort -u | paste -sd "\\n" -)

# 如果沒有內容，給予預設值
if [ -z "$CHANGELOG" ]; then
    CHANGELOG="無更新說明"
fi

# 將 Changelog 存檔，以便後續 ci_post_xcodebuild.sh 讀取 (若有需要)
echo "$CHANGELOG" > ../changelog_temp.txt

# 5. 組裝 JSON 並發送 Discord 通知
# 這裡發送的是「開始打包」的預告
PAYLOAD=$(cat <<EOF
{
  "embeds": [{
    "title": "🍎 Xcode Cloud 流程啟動 — 準備打包 🏗️",
    "color": 3447003,
    "description": "**專案名稱：** ${SCHEME}\n**目前基準 Tag：** ${TAG_NAME}\n**預計版本：** ${VERSION}\n**觸發 Commit：** ${CI_COMMIT}\n\n**待處理更新內容：**\n${CHANGELOG}"
  }]
}
EOF
)

curl -H "Content-Type: application/json" -X POST -d "$PAYLOAD" "$DISCORD_WEBHOOK"

echo "✅ Git Log 擷取完成並已發送 Discord 通知。"