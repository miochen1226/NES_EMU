#!/bin/bash

# ============================================================
# 腳本位置：專案目錄/ci_scripts/ci_post_clone.sh
# 目的：以 Git Tag 為核心版本號，解析資訊並通知 Discord
# ============================================================

DISCORD_WEBHOOK="https://discord.com/api/webhooks/1494864601500618783/ubSTg2Y_uS_pKvjTKSRHWm8vaBkO8Y4bvunh07l9EQUQqp_daQWX-CYtwaXGiQEru3ZF"

# 1. 處理 Git 歷史 (確保能抓到 Tag)
if [ -f "$(git rev-parse --git-dir)/shallow" ]; then
    git fetch --unshallow --tags 2>/dev/null || git fetch --tags
else
    git fetch --tags
fi

# 2. 解析專案名稱 (維持結構化解析邏輯)
PROJECT_PATH=$(find .. -name "project.pbxproj" -depth 2 | head -n 1)
TARGET_NAME="NES_EMU (iOS)"

DYNAMIC_PROJECT_NAME=$(plutil -convert json -o - "$PROJECT_PATH" | python3 -c "
import json, sys
data = json.load(sys.stdin)
objects = data.get('objects', {})
for obj in objects.values():
    if obj.get('isa') == 'PBXNativeTarget' and obj.get('name') == '$TARGET_NAME':
        config_list_id = obj.get('buildConfigurationList')
        config_list = objects.get(config_list_id, {})
        first_config_id = config_list.get('buildConfigurations', [None])[0]
        print(objects.get(first_config_id, {}).get('buildSettings', {}).get('PRODUCT_NAME', '$TARGET_NAME'))
        break
" 2>/dev/null)
[ -z "$DYNAMIC_PROJECT_NAME" ] && DYNAMIC_PROJECT_NAME="NES_EMU"

# 3. 【核心修改】獲取最新 Tag
# 根據你的專案習慣，移除可能的 "v" 前綴以確保版號純淨
CURRENT_TAG=$(git describe --tags --abbrev=0 2>/dev/null | sed 's/^v//' || echo "1.0.0")

# 4. Git 區間與 Changelog
START_COMMIT=${CI_PREVIOUS_COMMIT:-"${CURRENT_TAG}^"}
END_COMMIT=${CI_COMMIT:-"HEAD"}
RANGE_TEXT="$(git rev-parse --short $START_COMMIT 2>/dev/null)...$(git rev-parse --short $END_COMMIT 2>/dev/null)"

# 【重點修改】過濾 Merge branch '...' 字眼，只保留分支名稱
CHANGELOG=$(git log "${START_COMMIT}..${END_COMMIT}" --merges --pretty=format:'%s' | \
            sed "s/Merge branch '\(.*\)'/\1/" | \
            sed 's/^/• /' | \
            paste -sd "\n" -)

# 如果過濾後為空（例如不是 Merge commit），則抓取最後一則 commit message 第一行
if [ -z "$CHANGELOG" ]; then
    CHANGELOG="• $(git log -1 --pretty=format:'%s')"
fi

# 5. 將所有資訊寫入暫存檔
echo "$DYNAMIC_PROJECT_NAME" > /tmp/ci_project_name.txt
echo "$CURRENT_TAG" > /tmp/ci_current_tag.txt
echo "$RANGE_TEXT" > /tmp/ci_git_range.txt
echo "$CHANGELOG" > /tmp/final_changelog.txt

# 6. 發送 Discord 啟動通知
export PY_NAME="$DYNAMIC_PROJECT_NAME"
export PY_TAG="$CURRENT_TAG"
export PY_VER="${CURRENT_TAG} (Build ${CI_BUILD_NUMBER:-"N/A"})"
export PY_RANGE="$RANGE_TEXT"
export PY_LOGS="$CHANGELOG"

python3 -c '
import json, os
p_name = os.environ.get("PY_NAME")
p_ver  = os.environ.get("PY_VER")
p_range = os.environ.get("PY_RANGE")
p_logs  = os.environ.get("PY_LOGS")

description = (
    f"**專案名稱：** {p_name}\n"
    f"**打包版本：** {p_ver}\n"
    f"**Git 比對區間：** `{p_range}`\n\n"
    f"**更新說明：**\n{p_logs}"
)
data = {"embeds": [{"title": "🍎 Xcode Cloud 流程啟動 — 準備打包 🏗️", "color": 3447003, "description": description}]}
with open("/tmp/start_payload.json", "w") as f: json.dump(data, f)
'

curl -s -H "Content-Type: application/json" -X POST -d @"/tmp/start_payload.json" "$DISCORD_WEBHOOK"