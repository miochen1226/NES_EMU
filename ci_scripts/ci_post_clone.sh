#!/bin/bash

# ============================================================
# 腳本位置：專案目錄/ci_scripts/ci_post_clone.sh
# 修正：解決 line 56 語法錯誤，並確保抓取區間內容
# ============================================================

DISCORD_WEBHOOK="https://discord.com/api/webhooks/1504314067114790932/Y9pWPtitNsphk49rdbK8ooDlAMvsoND_iG290iJ6eh5zzLrmZS_24YC0DGERECkqjTMK"

# 1. 基礎設施與同步
git fetch --unshallow --tags 2>/dev/null || git fetch --tags

# 2. 識別基準 Tag
LATEST_TAG=$(git tag --sort=-version:refname | grep -E '[0-9]+\.[0-9]+\.[0-9]+\([0-9]+\)' | head -n 1)

echo "===== [DEBUG START] ====="
echo "當前 HEAD: $(git log -1 --pretty=format:'%H | %s')"
if [ -n "$LATEST_TAG" ]; then
    echo "基準 Tag: $LATEST_TAG ($(git rev-parse "$LATEST_TAG"))"
    echo "--- 區間紀錄 ---"
    git log "$LATEST_TAG..HEAD" --first-parent --pretty=format:'%H | %s'
    echo -e "\n----------------"
fi
echo "===== [DEBUG END] ====="

# 3. 擷取 Changelog
if [ -n "$LATEST_TAG" ]; then
    # 使用 grep 替代 [[ =~ ]] 以避免 shell 相容性語法錯誤
    CHANGELOG=$(git log "$LATEST_TAG..HEAD" --first-parent --no-merges --pretty=format:'%s' | grep -E '#[0-9]+' | while read -r line; do
        echo "• $line"
    done | sort -u)
else
    CHANGELOG=$(git log -n 3 --pretty=format:'• %s')
fi

# 4. 備援與發送
[ -z "$CHANGELOG" ] && CHANGELOG="• 本次建置無新增 Issue 紀錄"
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