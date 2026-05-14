#!/bin/bash

# ============================================================
# 腳本位置：專案目錄/ci_scripts/ci_post_clone.sh
# 目的：增加 Debug 資訊，打印完整區間 Commit 紀錄
# ============================================================

DISCORD_WEBHOOK="https://discord.com/api/webhooks/1504314067114790932/Y9pWPtitNsphk49rdbK8ooDlAMvsoND_iG290iJ6eh5zzLrmZS_24YC0DGERECkqjTMK"

# 1. 基礎設施與同步
git fetch --unshallow --tags 2>/dev/null || git fetch --tags

# ------------------------------------------------------------
# [DEBUG] 打印環境資訊
# ------------------------------------------------------------
echo "===== [DEBUG START] ====="
CURRENT_HEAD_HASH=$(git rev-parse HEAD)
CURRENT_HEAD_MSG=$(git log -1 --pretty=format:'%s')
echo "當前 HEAD Hash: $CURRENT_HEAD_HASH"
echo "當前 HEAD 訊息: $CURRENT_HEAD_MSG"

LATEST_TAG=$(git tag --sort=-version:refname | grep -E '[0-9]+\.[0-9]+\.[0-9]+\([0-9]+\)' | head -n 1)
if [ -n "$LATEST_TAG" ]; then
    TAG_HASH=$(git rev-parse "$LATEST_TAG")
    echo "識別到的基準 Tag: $LATEST_TAG"
    echo "該 Tag 指向的 Hash: $TAG_HASH"
    
    echo "--- 區間 [$LATEST_TAG..HEAD] 內的所有 Commit ---"
    # 這裡就是你要的：打印區間內所有 commit
    git log "$LATEST_TAG..HEAD" --first-parent --pretty=format:'%H | %s'
    echo -e "\n--------------------------------------------"
else
    echo "找不到符合格式的基準 Tag"
fi
echo "===== [DEBUG END] ====="
# ------------------------------------------------------------

# 2. 擷取 Changelog 邏輯 (維持區間依賴)
if [ -n "$LATEST_TAG" ]; then
    EXCLUDE_HASH=$(git rev-parse "$LATEST_TAG")
    
    # 使用區間抓取
    CHANGELOG=$(git log "$LATEST_TAG..HEAD" --first-parent --no-merges --pretty=format:'%H|%s' | while read -r line; do
        HASH=$(echo "$line" | cut -d'|' -f1)
        MSG=$(echo "$line" | cut -d'|' -f2)
        
        # 只要包含 #數字 且 不是 Tag 本身就抓
        if [[ "$MSG" =~ #[0-9]+ ]] && [ "$HASH" != "$EXCLUDE_HASH" ]; then
            echo "• $MSG"
        fi
    done | sort -u)
else
    CHANGELOG=$(git log -n 3 --pretty=format:'• %s')
fi

# 3. 備援與發送
[ -z "$CHANGELOG" ] && CHANGELOG="• 本次建置無新增 Issue 紀錄 (請檢查 Debug Log)"
echo "$CHANGELOG" > ../changelog_temp.txt

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