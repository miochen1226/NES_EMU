#!/bin/bash

# 1. 配置
DISCORD_WEBHOOK="https://discord.com/api/webhooks/1494864601500618783/ubSTg2Y_uS_pKvjTKSRHWm8vaBkO8Y4bvunh07l9EQUQqp_daQWX-CYtwaXGiQEru3ZF"

# 2. 處理淺層複製
if [ -f "$(git rev-parse --git-dir)/shallow" ]; then
    git fetch --unshallow --tags
else
    git fetch --tags
fi

# 3. 獲取專案資訊 (優先使用 CI 內建變數，抓不到再用 xcodebuild)
# CI_XCODE_SCHEME 或 CI_XCODE_PROJECT 是 Xcode Cloud 必備的
DYNAMIC_PROJECT_NAME=${CI_XCODE_SCHEME:-${CI_XCODE_PROJECT:-"NES_EMU"}}

# 4. 獲取版本資訊
CURRENT_TAG=$(git describe --tags --abbrev=0 2>/dev/null || echo "v0.0.0")
BASE_VERSION=$(echo "$CURRENT_TAG" | sed -E 's/Build_v//; s/v\.//; s/\(.*\)//')
BUILD_NUM=${CI_BUILD_NUMBER:-"Local"}
DISPLAY_VERSION="v${BASE_VERSION} (Build ${BUILD_NUM})"

# 5. Git 比對區間 (強化版：增加保底顯示)
# 使用 CI_COMMIT 變數，這是 Xcode Cloud 保證提供的
START_COMMIT=${CI_PREVIOUS_COMMIT}
END_COMMIT=${CI_COMMIT:-"HEAD"}

# 擷取短雜湊，如果 START 為空則顯示 "First Build"
if [ -n "$START_COMMIT" ]; then
    START_SHORT=$(git rev-parse --short "$START_COMMIT" 2>/dev/null || echo "Start")
else
    START_SHORT="First"
fi
END_SHORT=$(git rev-parse --short "$END_COMMIT" 2>/dev/null || echo "HEAD")
RANGE_TEXT="$START_SHORT...$END_SHORT"

# 6. 擷取 Changelog
echo "--- 🔍 偵錯資訊 ---"
echo "Range: $RANGE_TEXT"

if [ -n "$START_COMMIT" ]; then
    RAW_LOGS=$(git log "${START_COMMIT}..${END_COMMIT}" --merges --pretty=format:'%s')
else
    # 第一次建置時抓最近 5 條 Merge
    RAW_LOGS=$(git log -n 5 --merges --pretty=format:'%s')
fi

CHANGELOG=$(echo "$RAW_LOGS" | while read -r line; do
    [ -z "$line" ] && continue
    BRANCH=$(echo "$line" | sed -E "s/Merge branch '(.+)'($| into.*)/\1/; s/Merge pull request #[0-9]+ from .+\/(.+)/\1/")
    if [ "$BRANCH" != "$line" ]; then
        if [[ ! "$BRANCH" =~ ^(release|main|master|develop|Release)/ ]]; then
            echo "• $BRANCH"
        fi
    fi
done | grep "^•" | sort -u | paste -sd "\n" -)

[ -z "$CHANGELOG" ] && CHANGELOG="無合併更新說明 (本次可能為直接提交或針對同一 Commit 重複打包)"

# 存入暫存檔給 post_xcodebuild 用
echo "$CHANGELOG" > /tmp/final_changelog.txt

# 7. 組裝並發送
export PY_NAME="$DYNAMIC_PROJECT_NAME"
export PY_TAG="$CURRENT_TAG"
export PY_VERSION="$DISPLAY_VERSION"
export PY_RANGE="$RANGE_TEXT"
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

with open('/tmp/payload.json', 'w', encoding='utf-8') as f:
    json.dump(data, f, ensure_ascii=False)
"

curl -s -H "Content-Type: application/json" -X POST -d @"/tmp/payload.json" "$DISCORD_WEBHOOK"
rm -f "/tmp/payload.json"

# 在 ci_post_clone.sh 獲取名稱後加上：
echo "$DYNAMIC_PROJECT_NAME" > /tmp/project_name.txt