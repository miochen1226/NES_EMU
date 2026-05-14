#!/bin/bash

# ============================================================
# 腳本位置：專案目錄/ci_scripts/ci_post_xcodebuild.sh
# 目的：回寫 Tag 並確保 Discord 通知 100% 發送成功
# ============================================================

# 1. 狀態檢查
[ -n "$CI_XCODEBUILD_EXIT_CODE" ] && [ "$CI_XCODEBUILD_EXIT_CODE" != "0" ] && exit 0

# 2. 定義基本變數 (確保不為空)
DISCORD_WEBHOOK="https://discord.com/api/webhooks/1504314067114790932/Y9pWPtitNsphk49rdbK8ooDlAMvsoND_iG290iJ6eh5zzLrmZS_24YC0DGERECkqjTMK"
MARKETING_VERSION="1.0.3"
BUILD_NUMBER=${CI_BUILD_NUMBER:-"0"}
TAG_NAME="${MARKETING_VERSION}(${BUILD_NUMBER})"
TITLE="處理中"
MSG="流程執行完畢"
COLOR=3447003

# 3. 執行 Git 推送
if [ -n "$GH_TOKEN" ]; then
    git config user.name "Xcode Cloud (Automated)"
    git config user.email "xcode-cloud@users.noreply.github.com"
    
    # 建立 Tag
    git tag -af "$TAG_NAME" "${CI_COMMIT:-HEAD}" -m "Xcode Cloud Release $TAG_NAME"
    REMOTE_URL="https://miochen1226:${GH_TOKEN}@github.com/miochen1226/NES_EMU.git"
    
    if git push "$REMOTE_URL" "refs/tags/$TAG_NAME" --force; then
        TITLE="✅ Tag 已同步回 GitHub 🚀"
        MSG="成功推送標籤：**${TAG_NAME}**"
        COLOR=3066993
    else
        TITLE="❌ Tag 推送失敗"
        MSG="請檢查 GitHub PAT 權限設定"
        COLOR=15158332
    fi
else
    TITLE="⚠️ 跳過 Tag 回寫"
    MSG="找不到 GH_TOKEN 環境變數"
    COLOR=15844367
fi

# 4. 準備 Changelog 並處理 JSON 轉義
CHANGELOG=$(cat ../changelog_temp.txt 2>/dev/null)
if [ -z "$CHANGELOG" ]; then CHANGELOG="無更新說明"; fi
CHANGELOG_ESCAPED=$(echo "$CHANGELOG" | sed 's/\\/\\\\/g; s/"/\\"/g' | awk '{printf "%s\\n", $0}' | sed 's/\\n$//')

# 5. 發送通知 (使用更穩固的 JSON 構建方式)
PAYLOAD=$(cat <<EOF
{
  "embeds": [{
    "title": "${TITLE}",
    "color": ${COLOR},
    "description": "${MSG}\n\n**更新內容：**\n${CHANGELOG_ESCAPED}"
  }]
}
EOF
)

# 使用 -d @- 確保複雜字串能正確傳遞
echo "$PAYLOAD" | curl -H "Content-Type: application/json" -X POST -d @- "$DISCORD_WEBHOOK"

echo "🎯 全部流程執行完畢。"