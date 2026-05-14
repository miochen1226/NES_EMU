#!/bin/bash

# ============================================================
# 腳本位置：專案目錄/ci_scripts/ci_post_xcodebuild.sh
# 目的：在 Xcode Cloud 成功後回寫 Tag (使用 PAT 驗證) 並發送 Discord 通知
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

if [ -z "$APP_INFO_PLIST" ]; then
    echo "⚠️ 找不到 Info.plist，無法取得版本號。"
    exit 0
fi

MARKETING_VERSION=$(/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" "$APP_INFO_PLIST")
BUILD_VERSION=$(/usr/libexec/PlistBuddy -c "Print :CFBundleVersion" "$APP_INFO_PLIST")
TAG_NAME="${MARKETING_VERSION}(${BUILD_VERSION})"

# 3. 處理 Changelog 轉義 (用於 Discord JSON)
CHANGELOG_RAW=$(cat ../changelog_temp.txt 2>/dev/null || echo "無更新說明")
CHANGELOG_ESCAPED=$(echo "$CHANGELOG_RAW" | sed 's/\\/\\\\/g' | sed 's/"/\\"/g' | awk '{printf "%s\\n", $0}' | sed 's/\\n$//')

# 4. 使用 PAT 強制回寫 Git Tag
if [ -z "$GH_TOKEN" ]; then
    echo "❌ 找不到 GH_TOKEN 環境變數，無法執行方法 C。"
    MSG="⚠️ 腳本嘗試回寫 Tag 失敗：找不到 GH_TOKEN 環境變數。"
    TITLE="❌ Xcode Cloud 打包完成但 Tag 失敗"
    COLOR=15158332
else
    echo "🚀 準備使用 PAT 推送 Tag: $TAG_NAME"
    
    # 配置 Git 使用者資訊
    git config user.name "Xcode Cloud (via PAT)"
    git config user.email "xcode-cloud@users.noreply.github.com"
    
    # 建立 Tag
    git tag -a "$TAG_NAME" "${CI_COMMIT:-HEAD}" -m "Xcode Cloud Release $TAG_NAME"
    
    # 使用 PAT 組合 URL 進行推送
    REMOTE_URL="https://miochen1226:${GH_TOKEN}@github.com/miochen1226/NES_EMU.git"
    
    # 執行推送並擷取錯誤 log
    git push "$REMOTE_URL" "refs/tags/$TAG_NAME" 2>&1 | tee /tmp/git_push_log.txt
    
    if [ ${PIPESTATUS[0]} -eq 0 ]; then
        echo "✅ Git Tag 推送成功！"
        MSG="**版本號：** ${TAG_NAME}\n**Commit：** ${CI_COMMIT}\n\n**本版更新內容：**\n${CHANGELOG_ESCAPED}"
        TITLE="✅ Xcode Cloud 打包完成且 Tag 已回寫 🚀"
        COLOR=3066993
    else
        echo "❌ Git Tag 推送失敗。"
        ERROR_DETAIL=$(cat /tmp/git_push_log.txt | sed 's/"/\\"/g' | awk '{printf "%s\\n", $0}' | sed 's/\\n$//')
        MSG="⚠️ Tag 回寫失敗！請檢查 PAT 權限。\n**錯誤詳情：**\n${ERROR_DETAIL}"
        TITLE="❌ Xcode Cloud 打包完成但 Tag 失敗"
        COLOR=15158332
    fi
fi

# 5. 發送最終 Discord 通知
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