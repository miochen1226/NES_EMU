#!/bin/bash

# 1. 檢查狀態
[ -n "$CI_XCODEBUILD_EXIT_CODE" ] && [ "$CI_XCODEBUILD_EXIT_CODE" != "0" ] && exit 0

# 2. 從產物讀取同步後的版號
APP_INFO_PLIST=$(find "$CI_ARCHIVE_PATH/Products/Applications" -path "*.app/Contents/Info.plist" -o -path "*.app/Info.plist" | head -n 1)
MARKETING_VERSION=$(/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" "$APP_INFO_PLIST" 2>/dev/null)
BUILD_VERSION=$(/usr/libexec/PlistBuddy -c "Print :CFBundleVersion" "$APP_INFO_PLIST" 2>/dev/null)
TAG_NAME="${MARKETING_VERSION}(${BUILD_VERSION})"

# 3. 處理 Discord 內容
CHANGELOG_RAW=$(cat ../changelog_temp.txt 2>/dev/null || echo "無更新說明")
CHANGELOG_ESCAPED=$(echo "$CHANGELOG_RAW" | sed 's/\\/\\\\/g; s/"/\\"/g' | awk '{printf "%s\\n", $0}' | sed 's/\\n$//')

# 4. 使用 GH_TOKEN 推送 (方法 C)
if [ -n "$GH_TOKEN" ]; then
    git config user.name "Xcode Cloud (via PAT)"
    git config user.email "xcode-cloud@users.noreply.github.com"
    git tag -a "$TAG_NAME" "${CI_COMMIT:-HEAD}" -m "Xcode Cloud Release $TAG_NAME"
    
    REMOTE_URL="https://miochen1226:${GH_TOKEN}@github.com/miochen1226/NES_EMU.git"
    if git push "$REMOTE_URL" "refs/tags/$TAG_NAME" 2>&1; then
        TITLE="✅ Xcode Cloud 打包完成且 Tag 已同步 🚀"
        COLOR=3066993
    else
        TITLE="❌ Xcode Cloud 打包完成但 Tag 回寫失敗"
        COLOR=15158332
    fi
fi

# 5. 發送完成通知
PAYLOAD=$(cat <<EOF
{
  "embeds": [{
    "title": "${TITLE}",
    "color": ${COLOR},
    "description": "**版本號：** ${TAG_NAME}\n\n**本版更新內容：**\n${CHANGELOG_ESCAPED}"
  }]
}
EOF
)
curl -H "Content-Type: application/json" -X POST -d "$PAYLOAD" "$DISCORD_WEBHOOK"