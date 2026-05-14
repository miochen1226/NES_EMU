#!/bin/bash

# ============================================================
# 腳本位置：專案目錄/ci_scripts/ci_post_xcodebuild.sh
# 目的：使用 PAT 回寫同步 TestFlight 版號的 Tag 並發送 Discord 通知
# ============================================================

DISCORD_WEBHOOK="https://discord.com/api/webhooks/1504314067114790932/Y9pWPtitNsphk49rdbK8ooDlAMvsoND_iG290iJ6eh5zzLrmZS_24YC0DGERECkqjTMK"

echo "🧩 Stage: POST-Xcode Build is activated .... "

# 1. 檢查 Build 狀態
if [ -n "$CI_XCODEBUILD_EXIT_CODE" ] && [ "$CI_XCODEBUILD_EXIT_CODE" != "0" ]; then
    echo "⚠️ Xcode build 未成功，略過 Tag 寫回。"
    exit 0
fi

# 2. 從 Info.plist 讀取與 TestFlight 同步的版本號 (方案二核心)
APP_INFO_PLIST=$(find "$CI_ARCHIVE_PATH/Products/Applications" -path "*.app/Contents/Info.plist" -o -path "*.app/Info.plist" | head -n 1)
MARKETING_VERSION=$(/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" "$APP_INFO_PLIST" 2>/dev/null)
BUILD_VERSION=$(/usr/libexec/PlistBuddy -c "Print :CFBundleVersion" "$APP_INFO_PLIST" 2>/dev/null)
TAG_NAME="${MARKETING_VERSION}(${BUILD_VERSION})"

# 3. 處理內容轉義
CHANGELOG_RAW=$(cat ../changelog_temp.txt 2>/dev/null || echo "無更新說明")
CHANGELOG_ESCAPED=$(echo "$CHANGELOG_RAW" | sed 's/\\/\\\\/g' | sed 's/"/\\"/g' | awk '{printf "%s\\n", $0}' | sed 's/\\n$//')

# 4. 使用 PAT 強制回寫 Tag (方法 C 核心)
if [ -z "$GH_TOKEN" ]; then
    TITLE="❌ Xcode Cloud 打包完成但 Tag 失敗"
    MSG="⚠️ 找不到 GH_TOKEN 環境變數，無法自動回寫 Tag。"
    COLOR=15158332
else
    git config user.name "Xcode Cloud (via PAT)"
    git config user.email "xcode-cloud@users.noreply.github.com"
    
    # 建立 Tag 並推送
    git tag -a "$TAG_NAME" "${CI_COMMIT:-HEAD}" -m "Xcode Cloud Release $TAG_NAME"
    REMOTE_URL="https://miochen1226:${GH_TOKEN}@github.com/miochen1226/NES_EMU.git"
    
    if git push "$REMOTE_URL" "refs/tags/$TAG_NAME" 2>&1; then
        TITLE="✅ Xcode Cloud 打包完成且 Tag 已同步 🚀"
        MSG="**版本號：** ${TAG_NAME}\n**Commit：** ${CI_COMMIT}\n\n**本版更新內容：**\n${CHANGELOG_ESCAPED}"
        COLOR=3066993
    else
        TITLE="❌ Xcode Cloud 打包完成但 Tag 失敗"
        MSG="⚠️ Git 推送失敗，請確認 PAT 權限。"
        COLOR=15158332
    fi
fi

# 5. 發送通知
PAYLOAD=$(cat <<EOF
{
  "embeds": [{
    "title": "${TITLE}",
    "color": ${COLOR},
    "description": "${MSG}"
  }]
}
EOF
)

curl -H "Content-Type: application/json" -X POST -d "$PAYLOAD" "$DISCORD_WEBHOOK"

echo "🎯 Stage: POST-Xcode Build is DONE .... "
exit 0