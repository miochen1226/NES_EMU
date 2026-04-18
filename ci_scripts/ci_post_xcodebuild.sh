#!/bin/bash

# ============================================================
# 目的：直接讀取 post_clone 準備好的資訊，確保數據一致性
# ============================================================

DISCORD_WEBHOOK="https://discord.com/api/webhooks/1494864601500618783/ubSTg2Y_uS_pKvjTKSRHWm8vaBkO8Y4bvunh07l9EQUQqp_daQWX-CYtwaXGiQEru3ZF"

# 1. 從 /tmp 讀取傳遞過來的資訊
DYNAMIC_PROJECT_NAME=$(cat /tmp/ci_project_name.txt 2>/dev/null || echo "NES_EMU_IOS")
CURRENT_TAG=$(cat /tmp/ci_current_tag.txt 2>/dev/null || echo "N/A")
RANGE_TEXT=$(cat /tmp/ci_git_range.txt 2>/dev/null || echo "N/A")
CHANGELOG=$(cat /tmp/final_changelog.txt 2>/dev/null || echo "無更新說明")

# 2. 取得 Xcode Cloud 的 Build Number
BUILD_NUM=${CI_BUILD_NUMBER:-"N/A"}
DISPLAY_VERSION="${CURRENT_TAG} (Build ${BUILD_NUM})"

# 3. 根據建置結果決定顏色與文字
if [ "$CI_XCODEBUILD_EXIT_CODE" = "0" ]; then
    STATUS="✅ 建置成功 Success"
    COLOR=3066993
else
    STATUS="❌ 建置失敗 Failed"
    COLOR=1515833
fi

# 4. 使用 Python 發送 (解決引號與環境變數衝突問題)
export PY_NAME="$DYNAMIC_PROJECT_NAME"
export PY_VER="$DISPLAY_VERSION"
export PY_STATUS="$STATUS"
export PY_LOGS="$CHANGELOG"
export PY_RANGE="$RANGE_TEXT"
export PY_COLOR="$COLOR"

python3 -c '
import json, os

description = (
    f"**專案名稱：** {os.environ.get(\"PY_NAME\")}\n"
    f"**建置版本：** {os.environ.get(\"PY_VER\")}\n"
    f"**建置結果：** {os.environ.get(\"PY_STATUS\")}\n"
    f"**Git 區間：** `{os.environ.get(\"PY_RANGE\")}`\n\n"
    f"**更新說明：**\n{os.environ.get(\"PY_LOGS\")}"
)

data = {
    "embeds": [{
        "title": "📦 Xcode Cloud 打包任務完成",
        "color": int(os.environ.get("PY_COLOR")),
        "description": description
    }]
}

with open("/tmp/finish_payload.json", "w", encoding="utf-8") as f:
    json.dump(data, f, ensure_ascii=False)
'

curl -s -H "Content-Type: application/json" -X POST -d @"/tmp/finish_payload.json" "$DISCORD_WEBHOOK"