#!/bin/bash

# ============================================================
# 腳本位置：專案目錄/ci_scripts/ci_post_clone.sh
# 目的：動態抓取專案資訊、精準比對 Git 區間並通知 Discord
# ============================================================

# 1. 配置 Webhook
DISCORD_WEBHOOK="https://discord.com/api/webhooks/1494864601500618783/ubSTg2Y_uS_pKvjTKSRHWm8vaBkO8Y4bvunh07l9EQUQqp_daQWX-CYtwaXGiQEru3ZF"

# 2. 處理 Xcode Cloud 的 Shallow Clone 問題
if [ -f "$(git rev-parse --git-dir)/shallow" ]; then
    echo "🏗️ 偵測到淺層複製，正在解開以獲取完整歷史..."
    git fetch --unshallow --tags
else
    echo "✅ 環境已具備完整歷史，僅同步最新 Tag。"
    git fetch --tags
fi

# 3. 獲取專案資訊 (動態從專案設定抓取)
# 這裡會自動找出你的 Product Name
DYNAMIC_PROJECT_NAME=$(xcodebuild -showBuildSettings | grep " PRODUCT_NAME " | head -1 | awk -F '=' '{print $2}' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
[ -z "$DYNAMIC_PROJECT_NAME" ] && DYNAMIC_PROJECT_NAME="iOS Project"

# 4. 獲取版本與 Git 區間資訊
CURRENT_TAG=$(git describe --tags --abbrev=0 2>/dev/null || echo "v0.0.0")
BASE_VERSION=$(echo "$CURRENT_TAG" | sed -E 's/Build_v//; s/v\.//; s/\(.*\)//')
BUILD_NUM=${CI_BUILD_NUMBER:-"Local"}
DISPLAY_VERSION="v${BASE_VERSION} (Build ${BUILD_NUM})"

# 決定比對區間：上一次建置的 Commit vs 本次建置的 Commit
START_COMMIT=${CI_PREVIOUS_COMMIT:-"${CURRENT_TAG}^"}
END_COMMIT=${CI_COMMIT:-"HEAD"}

# 擷取短 Commit ID 供 Discord 顯示
START_SHORT=$(git rev-parse --short $START_COMMIT 2>/dev/null || echo "N/A")
END_SHORT=$(git rev-parse --short $END_COMMIT 2>/dev/null || echo "HEAD")

# 5. 擷取 Changelog (只抓 Merge)
echo "--- 🔍 偵錯資訊開始 ---"
echo "比對起點 (Start): $START_COMMIT ($START_SHORT)"
echo "比對終點 (End): $END_COMMIT ($END_SHORT)"

RAW_LOGS=$(git log "${START_COMMIT}..${END_COMMIT}" --merges --pretty=format:'%s')

CHANGELOG=$(echo "$RAW_LOGS" | while read -r line; do
    [ -z "$line" ] && continue
    BRANCH=$(echo "$line" | sed -E "s/Merge branch '(.+)'($| into.*)/\1/; s/Merge pull request #[0-9]+ from .+\/(.+)/\1/")
    if [ "$BRANCH" != "$line" ]; then
        if [[ ! "$BRANCH" =~ ^(release|main|master|develop|Release)/ ]]; then
            echo "• $BRANCH"
        fi
    fi
done | grep "^•" | sort -u | paste -sd "\n" -)

if [ -z "$CHANGELOG" ]; then
    CHANGELOG="無合併更新說明 (本次可能為直接提交或針對同一 Commit 重複打包)"
fi

# 重要：將 Changelog 存入暫存檔，讓之後的 ci_post_xcodebuild.sh 能讀取
echo "$CHANGELOG" > /tmp/final_changelog.txt
echo "--- 🔍 偵錯資訊結束 ---"

# 6. 使用 Python 組裝 JSON (確保格式安全)
PAYLOAD_PATH="/tmp/discord_payload.json"

export PY_NAME="$DYNAMIC_PROJECT_NAME"
export PY_TAG="$CURRENT_TAG"
export PY_VERSION="$DISPLAY_VERSION"
export PY_RANGE="$START_SHORT...$END_SHORT"
export PY_LOGS="$CHANGELOG"

python3 -c "
import json, os

description = (
    f'**專案名稱：** {os.environ.get(\"PY_NAME\")}\n'
    f'**目前基準 Tag：** {os.environ.get(\"PY_TAG\")}\n'
    f'**預計版本：** {os.environ.get(\"PY_VERSION\")}\n'
    f'**Git 比對區間：** `{os.environ.get(\"PY_RANGE\")}`\n\n'
    f'**更新說明：**\n{os.environ.get(\"PY_LOGS\")}'
)

data = {
    'embeds': [{
        'title': '🍎 Xcode Cloud 流程啟動 — 準備打包 🏗️',
        'color': 3447003,
        'description': description
    }]
}

with open('$PAYLOAD_PATH', 'w', encoding='utf-8') as f:
    json.dump(data, f, ensure_ascii=False)
"

# 7. 發送通知
curl -s -H "Content-Type: application/json" -X POST -d @"$PAYLOAD_PATH" "$DISCORD_WEBHOOK"
rm -f "$PAYLOAD_PATH"