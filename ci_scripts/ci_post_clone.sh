#!/bin/bash

# ============================================================
# 腳本位置：專案目錄/ci_scripts/ci_post_clone.sh
# 目的：精準抓取「兩次打包之間」的差異，並整合自動編號
# ============================================================

# 1. 配置
DISCORD_WEBHOOK="https://discord.com/api/webhooks/1494864601500618783/ubSTg2Y_uS_pKvjTKSRHWm8vaBkO8Y4bvunh07l9EQUQqp_daQWX-CYtwaXGiQEru3ZF"
SCHEME="Recruit"

# 2. 處理 Xcode Cloud 的 Shallow Clone 問題
if [ -f "$(git rev-parse --git-dir)/shallow" ]; then
    echo "🏗️ 偵測到淺層複製，正在解開以獲取完整歷史..."
    git fetch --unshallow --tags
else
    echo "✅ 環境已具備完整歷史，僅同步最新 Tag。"
    git fetch --tags
fi

# 3. 獲取版本資訊
# 取得目前的 Tag (例如 v1.0.1)
CURRENT_TAG=$(git describe --tags --abbrev=0 2>/dev/null || echo "v0.0.0")

# 格式化顯示版本 (例如 v1.0.1 (Build 8))
BASE_VERSION=$(echo "$CURRENT_TAG" | sed -E 's/Build_v//; s/v\.//; s/\(.*\)//')
BUILD_NUM=${CI_BUILD_NUMBER:-"Local"}
DISPLAY_VERSION="v${BASE_VERSION} (Build ${BUILD_NUM})"

# 4. 擷取 Changelog (精準抓取兩次打包之間的差異)
echo "--- 🔍 偵錯資訊開始 ---"

# 決定比對的起點：
# 如果在 Xcode Cloud 環境，使用 CI_PREVIOUS_COMMIT (上一次建置的 Commit)
# 如果在本地，則保底使用 CURRENT_TAG 的上一個節點
START_COMMIT=${CI_PREVIOUS_COMMIT:-"${CURRENT_TAG}^"}
END_COMMIT=${CI_COMMIT:-"HEAD"}

echo "比對起點 (上一次建置): $START_COMMIT"
echo "比對終點 (本次建置): $END_COMMIT"

# 抓取這兩次動作之間的 Merge Commits
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
    CHANGELOG="無合併更新說明 (本次可能為直接提交、或針對同一 Commit 重複打包)"
fi

echo "最終擷取結果: $CHANGELOG"
echo "--- 🔍 偵錯資訊結束 ---"

# 5. 使用暫存檔模式組裝 JSON
PAYLOAD_PATH="/tmp/discord_payload.json"

export PY_SCHEME="$SCHEME"
export PY_TAG="$CURRENT_TAG"
export PY_VERSION="$DISPLAY_VERSION"
export PY_COMMIT="$END_COMMIT"
export PY_LOGS="$CHANGELOG"

python3 -c "
import json, os

description = (
    f'**專案名稱：** {os.environ.get(\"PY_SCHEME\")}\n'
    f'**目前基準 Tag：** {os.environ.get(\"PY_TAG\")}\n'
    f'**預計版本：** {os.environ.get(\"PY_VERSION\")}\n'
    f'**觸發 Commit：** {os.environ.get(\"PY_COMMIT\")[:7]}\n\n'
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

# 6. 發送通知
RESPONSE=$(curl -s -w "\n%{http_code}" \
    -H "Content-Type: application/json" \
    -X POST \
    -d @"$PAYLOAD_PATH" \
    "$DISCORD_WEBHOOK")

HTTP_CODE=$(echo "$RESPONSE" | tail -n 1)
rm -f "$PAYLOAD_PATH"

if [[ "$HTTP_CODE" =~ ^[0-9]+$ ]] && { [ "$HTTP_CODE" -eq 204 ] || [ "$HTTP_CODE" -eq 200 ]; }; then
    echo "✅ Discord 通知發送成功。目標版本：$DISPLAY_VERSION"
else
    echo "❌ 失敗，HTTP Code: $HTTP_CODE"
fi

echo "$CHANGELOG" > /tmp/final_changelog.txt