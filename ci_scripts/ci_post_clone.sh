#!/bin/bash

# ============================================================
# 腳本位置：專案目錄/ci_scripts/ci_post_clone.sh
# 核心邏輯：支援「分支合併」與「主線提交」雙重識別
# ============================================================

DISCORD_WEBHOOK="https://discord.com/api/webhooks/1504314067114790932/Y9pWPtitNsphk49rdbK8ooDlAMvsoND_iG290iJ6eh5zzLrmZS_24YC0DGERECkqjTMK"

# 1. 強制同步所有分支資訊 (重要：否則看不到 origin/#xxx 分支名)
git fetch --unshallow --tags 2>/dev/null || git fetch --tags
git fetch --all

# 2. 識別基準 Tag
LATEST_TAG=$(git tag --sort=-version:refname | grep -E '[0-9]+\.[0-9]+\.[0-9]+\([0-9]+\)' | head -n 1)

# ------------------------------------------------------------
# 3. 核心 Changelog 擷取邏輯
# ------------------------------------------------------------
if [ -n "$LATEST_TAG" ]; then
    
    # --- A. 擷取「已合併分支」的名稱 (#數字) ---
    MERGED_FEATURES=$(git branch -r | grep -oE '#[0-9]+[^[:space:]]*' | while read -r branch_name; do
        # 判定 A: 這個分支是否已經在 HEAD 的歷史中 (已合併)
        # 判定 B: 這個分支的 Tip Commit 是否位於 LATEST_TAG 之後 (新內容)
        if git merge-base --is-ancestor "origin/$branch_name" HEAD; then
            BRANCH_HASH=$(git rev-parse "origin/$branch_name")
            IS_NEW=$(git log "$LATEST_TAG..HEAD" --format=%H | grep "$BRANCH_HASH")
            if [ -n "$IS_NEW" ]; then
                echo "• [已合併] 分支 $branch_name"
            fi
        fi
    done)

    # --- B. 擷取「主線直接提交」的 Commit (#數字) ---
    DIRECT_COMMITS=$(git log "$LATEST_TAG..HEAD" --no-merges --pretty=format:'%s' | grep -E '#[0-9]+' | while read -r line; do
        echo "• $line"
    done)

    # 合併兩者並去重
    CHANGELOG=$(printf "%s\n%s" "$MERGED_FEATURES" "$DIRECT_COMMITS" | grep -v '^$' | sort -u)

else
    # 備援：若無 Tag 則顯示最近 5 筆
    CHANGELOG=$(git log -n 5 --no-merges --pretty=format:'• %s')
fi

# ------------------------------------------------------------
# 4. 準備通知內容
# ------------------------------------------------------------
[ -z "$CHANGELOG" ] && CHANGELOG="• 本次建置無新增 Issue 紀錄"
echo "$CHANGELOG" > ../changelog_temp.txt

TARGET_TAG="1.0.3(${CI_BUILD_NUMBER:-0})"
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