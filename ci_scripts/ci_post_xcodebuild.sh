#!/bin/bash

# ============================================================
# 腳本位置：專案目錄/ci_scripts/ci_post_xcodebuild.sh
# 目的：打包完成後，從暫存檔讀取資訊並發送 Discord 最終通知
# ============================================================

DISCORD_WEBHOOK="https://discord.com/api/webhooks/1494864601500618783/ubSTg2Y_uS_pKvjTKSRHWm8vaBkO8Y4bvunh07l9EQUQqp_daQWX-CYtwaXGiQEru3ZF"

# 1. 讀取由 ci_post_clone.sh 存儲的專案名稱與 Changelog
# 我們假設名稱存在 /tmp/project_name.txt (需確保 post_clone 有寫入)
# 如果沒有，則給予預設值
if [ -f "/tmp/project_name.txt" ]; then
    DYNAMIC_PROJECT_NAME=$(cat /tmp/project_name.txt)
else
    DYNAMIC_PROJECT_NAME=${CI_XCODE_SCHEME:-"NES_EMU"}
fi

if [ -f "/tmp/final_changelog.txt" ]; then
    CHANGELOG=$(cat /tmp/final_changelog.txt)
else
    CHANGELOG="無合併更新說明"
fi

# 2. 獲取版本與 Git 區間 (維持與 clone 腳本一致)
CURRENT_TAG=$(git describe --tags --abbrev=0 2>/dev/null || echo "1.0.0")
BUILD_NUM=${CI_BUILD_NUMBER:-"N/A"}
DISPLAY_VERSION="${CURRENT_TAG} (Build ${BUILD_NUM})"

START_COMMIT=${CI_PREVIOUS_COMMIT:-"${CURRENT_TAG}^"}
END_COMMIT=${CI_COMMIT:-"HEAD"}
START_SHORT=$(git rev-parse --short $START_COMMIT 2>/dev/null || echo "Start")
END_SHORT=$(git rev-parse --short $END_COMMIT 2>/dev/null || echo "End")
RANGE_TEXT="$START_SHORT...$END_SHORT"

# 3. 判斷建置狀態 (Xcode Cloud 自動注入此變數)
if [ "$CI_XCODEBUILD_EXIT_CODE" ="0" ]; then
    BUILD_STATUS="✅ 建置成功 Success"
    EMBED_COLOR=3066993 # 綠色
else
    BUILD_STATUS="❌ 建置失敗 Failed"
    EMBED_COLOR=1515833 # 紅色
fi

# 4. 使用 Python 組裝 JSON (修復 PY_RANGE 語法錯誤)
# 注意：這裡使用單引號包裹 Python 指令，避免 Shell 對引號的過度解析
PAYLOAD_PATH="/tmp/discord_finish_payload.json"

export PY_NAME="$DYNAMIC_PROJECT_NAME"
export PY_VER="$DISPLAY_VERSION"
export PY_STATUS="$BUILD_STATUS"
export PY_LOGS="$CHANGELOG"
export PY_RANGE="$RANGE_TEXT"
export PY_COLOR="$EMBED_COLOR"

python3 -c '
import json, os

name = os.environ.get("PY_NAME", "Unknown")
ver = os.environ.get("PY_VER", "N/A")
status = os.environ.get("PY_STATUS", "Unknown")
logs = os.environ.get("PY_LOGS", "No logs")
git_range = os.environ.get("PY_RANGE", "N/A")
color = int(os.environ.get("PY_COLOR", 3447003))

description = (
    f"**專案名稱：** {name}\n"
    f"**建置版本：** {ver}\n"
    f"**建置結果：** {status}\n"
    f"**Git 區間：** `{git_range}`\n\n"
    f"**更新說明：**\n{logs}"
)

data = {
    "embeds": [{
        "title": "📦 Xcode Cloud 打包任務完成",
        "color": color,
        "description": description
    }]
}

with open("/tmp/discord_finish_payload.json", "w", encoding="utf-8") as f:
    json.dump(data, f, ensure_ascii=False)
'

# 5. 發送通知
curl -s -H "Content-Type: application/json" -X POST -d @"$PAYLOAD_PATH" "$DISCORD_WEBHOOK"
rm -f "$PAYLOAD_PATH"