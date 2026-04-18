#!/bin/bash

# ============================================================
# 腳本位置：專案目錄/ci_scripts/ci_post_xcodebuild.sh
# 目的：回報最終打包結果，並附帶 Changelog
# ============================================================

DISCORD_WEBHOOK="https://discord.com/api/webhooks/1494864601500618783/ubSTg2Y_uS_pKvjTKSRHWm8vaBkO8Y4bvunh07l9EQUQqp_daQWX-CYtwaXGiQEru3ZF"

# 1. 判斷編譯結果
if [ "$CI_XCODEBUILD_EXIT_CODE" -eq 0 ]; then
    RESULT_TITLE="✅ Xcode Cloud 打包完成"
    RESULT_COLOR=3066993 # 綠色
else
    RESULT_TITLE="❌ Xcode Cloud 打包失敗"
    RESULT_COLOR=15158332 # 紅色
fi

# 2. 獲取版本資訊
CURRENT_TAG=$(git describe --tags --abbrev=0 2>/dev/null || echo "v0.0.0")
BASE_VERSION=$(echo "$CURRENT_TAG" | sed -E 's/Build_v//; s/v\.//; s/\(.*\)//')
BUILD_NUM=${CI_BUILD_NUMBER:-"Local"}
DISPLAY_VERSION="v${BASE_VERSION} (Build ${BUILD_NUM})"

# 3. 嘗試讀取在 post_clone 階段暫存的 Changelog
# 這裡需要你在 post_clone.sh 最後加一行把 CHANGELOG 存起來
CHANGELOG_FILE="/tmp/final_changelog.txt"
if [ -f "$CHANGELOG_FILE" ]; then
    CHANGELOG_CONTENT=$(cat "$CHANGELOG_FILE")
else
    # 如果檔案不存在 (可能是手動跑或沒存到)，就現場抓一次
    START_COMMIT=${CI_PREVIOUS_COMMIT:-"${CURRENT_TAG}^"}
    END_COMMIT=${CI_COMMIT:-"HEAD"}
    CHANGELOG_CONTENT=$(git log "${START_COMMIT}..${END_COMMIT}" --merges --pretty=format:'%s' | sed -E "s/Merge branch '(.+)'($| into.*)/• \1/; s/Merge pull request #[0-9]+ from .+\/(.+)/• \1/" | sort -u | paste -sd "\n" -)
fi

[ -z "$CHANGELOG_CONTENT" ] && CHANGELOG_CONTENT="無合併更新說明"

# 4. 組裝發送 JSON
PAYLOAD_PATH="/tmp/discord_final.json"

export PY_TITLE="$RESULT_TITLE"
export PY_COLOR="$RESULT_COLOR"
export PY_VERSION="$DISPLAY_VERSION"
export PY_LOGS="$CHANGELOG_CONTENT"

python3 -c "
import json, os

description = (
    f'**版本：** {os.environ.get(\"PY_VERSION\")}\n\n'
    f'**更新內容：**\n{os.environ.get(\"PY_LOGS\")}'
)

data = {
    'embeds': [{
        'title': os.environ.get('PY_TITLE'),
        'color': int(os.environ.get('PY_COLOR')),
        'description': description,
        'footer': { 'text': 'Xcode Cloud CI/CD' }
    }]
}

with open('$PAYLOAD_PATH', 'w', encoding='utf-8') as f:
    json.dump(data, f, ensure_ascii=False)
"

# 5. 發送並清理
curl -s -H "Content-Type: application/json" -X POST -d @"$PAYLOAD_PATH" "$DISCORD_WEBHOOK"
rm -f "$PAYLOAD_PATH"
