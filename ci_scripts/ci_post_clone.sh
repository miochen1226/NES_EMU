#!/bin/bash

# ============================================================
# 腳本位置：專案目錄/ci_scripts/ci_post_clone.sh
# 目的：擷取 Git Log、整合 Xcode Cloud 建置編號並發送 Discord 通知
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

# 3. 獲取版本資訊 (整合 Xcode Cloud 建置編號)
# 取得最近的 Tag 名稱 (例如 v.1.0.3)
TAG_NAME=$(git describe --tags --abbrev=0 2>/dev/null || echo "Initial_Build")

# 格式化原始版本號 (去除可能存在的 Build_v 前綴)
BASE_VERSION=$(echo "$TAG_NAME" | sed -E 's/Build_v//; s/v\.//; s/\(.*\)//')

# 獲取 Xcode Cloud 的自動建置編號 (CI_BUILD_NUMBER)
# 如果在本地測試，則顯示為 Local
BUILD_NUM=${CI_BUILD_NUMBER:-"Local"}

# 最終顯示格式：v1.0.3 (Build 7)
DISPLAY_VERSION="v${BASE_VERSION} (Build ${BUILD_NUM})"

# 4. 擷取 Changelog (嚴格模式：只抓 Merge Commit 分支名)
echo "--- 🔍 偵錯資訊開始 ---"
RAW_LOGS=$(git log "$TAG_NAME..HEAD" --merges --pretty=format:'%s')

CHANGELOG=$(echo "$RAW_LOGS" | while read -r line; do
    [ -z "$line" ] && continue
    
    # 支援不同的 Merge 標題格式
    BRANCH=$(echo "$line" | sed -E "s/Merge branch '(.+)'($| into.*)/\1/; s/Merge pull request #[0-9]+ from .+\/(.+)/\1/")
    
    if [ "$BRANCH" != "$line" ]; then
        if [[ ! "$BRANCH" =~ ^(release|main|master|develop|Release)/ ]]; then
            echo "• $BRANCH"
        fi
    fi
done | grep "^•" | sort -u | paste -sd "\n" -)

if [ -z "$CHANGELOG" ]; then
    CHANGELOG="無合併更新說明 (本次可能為直接提交或 Fast-forward 合併)"
fi
echo "--- 🔍 偵錯資訊結束 ---"

# 5. 使用暫存檔模式組裝 JSON
COMMIT_ID="${CI_COMMIT:-"(本地測試)"}"
PAYLOAD_PATH="/tmp/discord_payload.json"

export PY_SCHEME="$SCHEME"
export PY_TAG="$TAG_NAME"
export PY_VERSION="$DISPLAY_VERSION"
export PY_COMMIT="$COMMIT_ID"
export PY_LOGS="$CHANGELOG"

python3 -c "
import json, os

description = (
    f'**專案名稱：** {os.environ.get(\"PY_SCHEME\")}\n'
    f'**目前基準 Tag：** {os.environ.get(\"PY_TAG\")}\n'
    f'**預計版本：** {os.environ.get(\"PY_VERSION\")}\n'
    f'**觸發 Commit：** {os.environ.get(\"PY_COMMIT\")}\n\n'
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
    echo "✅ Discord 通知發送成功。版本資訊：$DISPLAY_VERSION"
else
    echo "❌ 失敗，HTTP Code: $HTTP_CODE"
fi