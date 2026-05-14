#!/bin/bash

# ============================================================
# 腳本位置：專案目錄/ci_scripts/ci_post_xcodebuild.sh
# ============================================================

DISCORD_WEBHOOK="https://discord.com/api/webhooks/1504314067114790932/Y9pWPtitNsphk49rdbK8ooDlAMvsoND_iG290iJ6eh5zzLrmZS_24YC0DGERECkqjTMK"

echo "🧩 Stage: POST-Xcode Build is activated .... "

# 1. 檢查 Build 狀態
if [ -n "$CI_XCODEBUILD_EXIT_CODE" ] && [ "$CI_XCODEBUILD_EXIT_CODE" != "0" ]; then
    echo "⚠️ Xcode build 未成功，略過 Tag 寫回。"
    exit 0
fi

# 2. 讀取版本資訊
APP_INFO_PLIST=$(find "$CI_ARCHIVE_PATH/Products/Applications" -path "*.app/Contents/Info.plist" -o -path "*.app/Info.plist" | head -n 1)
MARKETING_VERSION=$(/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" "$APP_INFO_PLIST")
BUILD_VERSION=$(/usr/libexec/PlistBuddy -c "Print :CFBundleVersion" "$APP_INFO_PLIST")
TAG_NAME="${MARKETING_VERSION}(${BUILD_VERSION})"

# 3. 讀取先前存下的 Changelog
CHANGELOG=$(cat ../changelog_temp.txt 2>/dev/null || echo "無更新說明")

# 4. Git Tag 回寫
git config user.name "Xcode Cloud"
git config user.email "xcode-cloud@users.noreply.github.com"
git tag -a "$TAG_NAME" "${CI_COMMIT:-HEAD}" -m "Xcode Cloud Release $TAG_NAME"
git push origin "refs/tags/$TAG_NAME"

# 5. 發送「打包完成」通知
PAYLOAD=$(cat <<EOF
{
  "embeds": [{
    "title": "✅ Xcode Cloud 打包完成 🚀",
    "color": 3066993,
    "description": "**版本號：** ${TAG_NAME}\n**Commit：** ${CI_COMMIT}\n\n**本版更新內容：**\n${CHANGELOG}"
  }]
}
EOF
)

curl -H "Content-Type: application/json" -X POST -d "$PAYLOAD" "$DISCORD_WEBHOOK"

echo "✅ 已完成 Tag 回寫與 Discord 通知發送。"
exit 0