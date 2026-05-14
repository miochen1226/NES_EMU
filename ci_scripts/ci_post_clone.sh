#!/bin/bash

# ============================================================
# 腳本位置：專案目錄/ci_scripts/ci_post_clone.sh
# 修正目標：精準過濾掉已經屬於舊版號的 Commit (#555, #99 等)
# ============================================================

DISCORD_WEBHOOK="https://discord.com/api/webhooks/1504314067114790932/Y9pWPtitNsphk49rdbK8ooDlAMvsoND_iG290iJ6eh5zzLrmZS_24YC0DGERECkqjTMK"

# 1. 確保完整 Git 歷史與 Tag
git fetch --unshallow --tags 2>/dev/null || git fetch --tags

# 2. 獲取最新的一個 Tag (使用版本號排序最穩)
LATEST_TAG=$(git tag --sort=-version:refname | grep -E '[0-9]+\.[0-9]+\.[0-9]+\([0-9]+\)' | head -n 1)

# 3. 擷取精準的 Changelog
if [ -n "$LATEST_TAG" ]; then
    echo "基準 Tag 識別為: $LATEST_TAG"
    # 取得 LATEST_TAG 指向的 Commit ID，我們要徹底排除它
    EXCLUDE_HASH=$(git rev-parse "$LATEST_TAG")
    
    # 邏輯說明：
    # git log $LATEST_TAG..HEAD : 抓取從標籤後到現在的所有紀錄
    # grep -v "$(git rev-list -n 1 $LATEST_TAG)" : 二次確保不包含標籤本身的 commit
    CHANGELOG=$(git log "$LATEST_TAG..HEAD" --first-parent --no-merges --pretty=format:'%H|%s' | while read -r line; do
        HASH=$(echo "$line" | cut -d'|' -f1)
        MSG=$(echo "$line" | cut -d'|' -f2)
        
        # 條件 1: 包含 #數字
        # 條件 2: Commit Hash 不能是舊標籤的 Hash
        if [[ "$MSG" =~ #[0-9]+ ]] && [ "$HASH" != "$EXCLUDE_HASH" ]; then
            echo "• $MSG"
        fi
    done | sort -u)
else
    echo "未找到舊標籤，顯示最近紀錄"
    CHANGELOG=$(git log -n 3 --pretty=format:'• %s')
fi

# 4. 備援機制 (如果區間內真的沒有 #數字 的 commit)
[ -z "$CHANGELOG" ] && CHANGELOG="• 本次建置無新增 Issue 紀錄"

# 存入暫存檔供 ci_post_xcodebuild.sh 使用
echo "$CHANGELOG" > ../changelog_temp.txt

# 5. 發送通知
MARKETING_VERSION="1.0.3"
TARGET_TAG="${MARKETING_VERSION}(${CI_BUILD_NUMBER:-0})"
CHANGELOG_ESCAPED=$(echo "$CHANGELOG" | sed 's/\\/\\\\/g; s/"/\\"/g' | awk '{printf "%s\\n", $0}' | sed 's/\\n$//')

PAYLOAD=$(cat <<EOF
{
  "embeds": [{
    "title": "🏗️ Xcode Cloud 開始建置 [Build #${CI_BUILD_NUMBER}]",
    "color": 3447003,
    "description": "**預計版本:** ${TARGET_TAG}\n**基準 Tag:** ${LATEST_TAG:-"無"}\n\n**更新內容:**\n${CHANGELOG_ESCAPED}"
  }]
}
EOF
)

echo "$PAYLOAD" | curl -H "Content-Type: application/json" -X POST -d @- "$DISCORD_WEBHOOK"