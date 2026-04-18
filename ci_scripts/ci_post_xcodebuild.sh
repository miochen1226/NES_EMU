#!/bin/bash

# ============================================================
# 腳本位置：專案目錄/ci_scripts/ci_post_xcodebuild.sh
# 目的：打包完成後，從暫存檔讀取資訊並發送 Discord 最終通知
# ============================================================

# 1. 配置 Webhook
DISCORD_WEBHOOK="https://discord.com/api/webhooks/1494864601500618783/ubSTg2Y_uS_pKvjTKSRHWm8vaBkO8Y4bvunh07l9EQUQqp_daQWX-CYtwaXGiQEru3ZF"

echo "--- 📦 開始執行 ci_post_xcodebuild.sh ---"

# 2. 從 /tmp 讀取由 ci_post_clone.sh 傳遞過來的資訊
# 這樣可以確保兩則 Discord 訊息的專案名稱與 Git 區間 100% 一致
DYNAMIC_PROJECT_NAME=$(cat /tmp/ci_project_name.txt 2>/dev/null || echo "NES_EMU_IOS")
CURRENT_TAG=$(cat /tmp/ci_current_tag.txt 2>/dev/null || echo "N/A")
RANGE_TEXT=$(cat /tmp/ci_git_range.txt 2>/dev/null || echo "N/A")
CHANGELOG=$(cat /tmp/final_changelog.txt 2>/dev/null || echo "無更新說明")

# 3. 獲取 Xcode Cloud 的建置編號與版本
BUILD_NUM=${CI_BUILD_NUMBER:-"N/A"}
DISPLAY_VERSION="${CURRENT_TAG} (Build ${BUILD_NUM})"

# 4. 根據 Xcode Cloud 的建置結果決定顏色與狀態
# CI_XCODEBUILD_EXIT_CODE 為 0 代表打包成功
if [ "$CI_XCODEBUILD_EXIT_CODE" = "0" ]; then
    STATUS="✅ 建置成功 Success"
    COLOR=3066993  # 綠色
else
    STATUS="❌ 建置失敗 Failed"
    COLOR=1515833  # 紅色
fi

# 5. 使用 Python 組裝 JSON
# 採用單引號包裹 Python 指令，並透過 os.environ 讀取變數，徹底解決語法衝突問題
export PY_NAME="$DYNAMIC_PROJECT_NAME"
export PY_VER="$DISPLAY_VERSION"
export PY_STATUS="$STATUS"
export PY_LOGS="$CHANGELOG"
export PY_RANGE="$RANGE_TEXT"
export PY_COLOR="$COLOR"

PAYLOAD_PATH="/tmp/finish_payload.json"

python3 -c '
import json, os

p_name   = os.environ.get("PY_NAME", "Unknown")
p_ver    = os.environ.get("PY_VER", "N/A")
p_status = os.environ.get("PY_STATUS", "Unknown")
p_logs   = os.environ.get("PY_LOGS", "No logs")
p_range  = os.environ.get("PY_RANGE", "N/A")
p_color  = int(os.environ.get("PY_COLOR", 3447003))

description = (
    f"**專案名稱：** {p_name}\n"
    f"**建置版本：** {p_ver}\n"
    f"**建置結果：** {p_status}\n"
    f"**Git 區間：** `{p_range}`\n\n"
    f"**更新說明：**\n{p_logs}"
)

data = {
    "embeds": [{
        "title": "📦 Xcode Cloud 打包任務完成",
        "color": p_color,
        "description": description
    }]
}

with open("/tmp/finish_payload.json", "w", encoding="utf-8") as f:
    json.dump(data, f, ensure_ascii=False)
'

# 6. 發送通知到 Discord
if [ -f "$PAYLOAD_PATH" ]; then
    curl -s -H "Content-Type: application/json" -X POST -d @"$PAYLOAD_PATH" "$DISCORD_WEBHOOK"
    echo "✅ Discord 建置結果通知已發送"
else
    echo "❌ 錯誤：無法生成 Payload 檔案"
fi

echo "--- ✅ ci_post_xcodebuild.sh 執行完畢 ---"