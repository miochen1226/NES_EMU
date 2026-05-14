#!/bin/bash

# 1. 狀態檢查
[ -n "$CI_XCODEBUILD_EXIT_CODE" ] && [ "$CI_XCODEBUILD_EXIT_CODE" != "0" ] && exit 0

# 2. 直接使用環境變數組合 Tag 名稱 (最準確)
MARKETING_VERSION="1.0.3"
TAG_NAME="${MARKETING_VERSION}(${CI_BUILD_NUMBER})"

echo "🚀 準備回寫同步後的 Tag: $TAG_NAME"

# 3. 使用 PAT 推送
if [ -n "$GH_TOKEN" ] && [ -n "$CI_BUILD_NUMBER" ]; then
    git config user.name "Xcode Cloud (Automated)"
    git config user.email "xcode-cloud@users.noreply.github.com"
    
    # 強制覆蓋已存在的本地 Tag (防止上一跑殘留)
    git tag -af "$TAG_NAME" "${CI_COMMIT:-HEAD}" -m "Xcode Cloud Release $TAG_NAME"
    
    REMOTE_URL="https://miochen1226:${GH_TOKEN}@github.com/miochen1226/NES_EMU.git"
    
    # 執行推送
    if git push "$REMOTE_URL" "refs/tags/$TAG_NAME" --force; then
        TITLE="✅ Tag 已同步回 GitHub 🚀"
        COLOR=3066993
        MSG="成功建立並推送 Tag: **${TAG_NAME}**"
    else
        TITLE="❌ Git Tag 推送失敗"
        COLOR=15158332
        MSG="無法推送 Tag 至 GitHub，請檢查 PAT 權限。"
    fi
fi

# 4. 發送 Discord 通知
CHANGELOG=$(cat ../changelog_temp.txt 2>/dev/null || echo "無更新說明")
CHANGELOG_ESCAPED=$(echo "$CHANGELOG" | sed 's/\\/\\\\/g; s/"/\\"/g' | awk '{printf "%s\\n", $0}' | sed 's/\\n$//')

PAYLOAD=$(cat <<EOF
{
  "embeds": [{
    "title": "${TITLE}",
    "color": ${COLOR},
    "description": "${MSG}\n\n**更新內容:**\n${CHANGELOG_ESCAPED}"
  }]
}
EOF
)
curl -H "Content-Type: application/json" -X POST -d "$PAYLOAD" "$DISCORD_WEBHOOK"