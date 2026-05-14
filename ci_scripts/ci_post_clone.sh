#!/bin/bash

# ============================================================
# 腳本位置：專案目錄/ci_scripts/ci_post_clone.sh
# 功能：自動版本偵測 + 分支感知 Changelog + Discord 通知
# ============================================================

DISCORD_WEBHOOK="https://discord.com/api/webhooks/1504314067114790932/Y9pWPtitNsphk49rdbK8ooDlAMvsoND_iG290iJ6eh5zzLrmZS_24YC0DGERECkqjTMK"

# 1. 環境同步
git fetch --unshallow --tags 2>/dev/null || git fetch --tags
git fetch --all

# 2. 自動偵測 Xcode 專案中的版本號 (Marketing Version)
# 邏輯：從 .xcodeproj 裡抓取 MARKETING_VERSION 設定
PROJECT_FILE=$(find .. -name "project.pbxproj" | head -n 1)
if [ -f "$PROJECT_FILE" ]; then
    DETECTED_VERSION=$(grep -m 1 "MARKETING_VERSION" "$PROJECT_FILE" | cut -d'=' -f2 | tr -d ' ;"' | xargs)
fi
MARKETING_VERSION=${DETECTED_VERSION:-"1.0.5"} # 抓不到則預設 1.0.5

# 3. 識別基準 Tag (用於計算區間)
LATEST_TAG=$(git tag --sort=-version:refname | grep -E '[0-9]+\.[0-9]+\.[0-9]+\([0-9]+\)' | head -n 1)

# ------------------------------------------------------------
# 4. 核心 Changelog 擷取邏輯 (分支溯源法)
# ------------------------------------------------------------
if [ -n "$LATEST_TAG" ]; then
    
    # --- A. 擷取「已合併分支」名稱 (#數字) ---
    MERGED_FEATURES=$(git branch -r | grep -oE '#[0-9]+[^[:space:]]*' | while read -r branch_name; do
        # 判定 A: 這個分支是否已合併至 HEAD
        if git merge-base --is-ancestor "origin/$branch_name" HEAD; then
            BRANCH_HASH=$(git rev-parse "origin/$branch_name")
            # 判定 B: 這個分支的末端 Commit 是否位於基準 Tag 之後
            IS_NEW=$(git log "$LATEST_TAG..HEAD" --format=%H | grep "$BRANCH_HASH")
            if [ -n "$IS_NEW" ]; then
                echo "• [已合併] 分支 $branch_name"
            fi
        fi
    done)

    # --- B. 擷取「主線直接提交」紀錄 (#數字) ---
    DIRECT_COMMITS=$(git log "$LATEST_TAG..HEAD" --no-merges --pretty=format:'%s' | grep -E '#[0-9]+' | while read -r line; do
        echo "• $line"
    done)

    # 合併結果並去重
    CHANGELOG=$(printf "%s\n%s" "$MERGED_FEATURES" "$DIRECT_COMMITS" | grep -v '^$' | sort -u)

else
    # 備援：若無基準 Tag 則顯示最近 5 筆
    CHANGELOG=$(git log -n 5 --no-merges --pretty=format:'• %s')
fi

# ------------------------------------------------------------
# 5. 發送通知
# ------------------------------------------------------------
[ -z "$CHANGELOG" ] && CHANGELOG="• 本次建置無新增 Issue 紀錄"
echo "$CHANGELOG" > ../changelog_temp.txt

TARGET_TAG="${MARKETING_VERSION}(${CI_BUILD_NUMBER:-0})"
CHANGELOG_ESCAPED=$(echo "$CHANGELOG" | sed 's/\\/\\\\/g; s/"/\\"/g' | awk '{printf "%s\\n", $0}' | sed 's/\\n$//')

PAYLOAD=$(cat <<EOF
{
  "embeds": [{
    "title": "🏗️ Xcode Cloud 開始建置 [Build #${CI_BUILD_NUMBER}]",
    "color": 3447003,
    "description": "**預計版本:** ${TARGET_TAG}\n**基準 Tag:** ${LATEST_TAG:-"Initial"}\n\n**更新內容:**\n${CHANGELOG_ESCAPED}"
  }]
}
EOF
)

echo "$PAYLOAD" | curl -H "Content-Type: application/json" -X POST -d @- "$DISCORD_WEBHOOK"

# 打印 Debug 資訊到 Xcode Cloud Log
echo "===== 建置資訊 ====="
echo "偵測到版本號: $MARKETING_VERSION"
echo "最終 Tag: $TARGET_TAG"
echo "基準 Tag: $LATEST_TAG"
echo "Changelog:\n$CHANGELOG"
echo "===================="