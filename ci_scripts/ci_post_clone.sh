#!/bin/bash

# 1. 配置
DISCORD_WEBHOOK="https://discord.com/api/webhooks/1494864601500618783/ubSTg2Y_uS_pKvjTKSRHWm8vaBkO8Y4bvunh07l9EQUQqp_daQWX-CYtwaXGiQEru3ZF"
TARGET_NAME="NES_EMU (iOS)"

# 2. 自動偵測專案檔 (相容本地 ./ci_scripts 執行與 Xcode Cloud 執行)
if [ -f "../NES_EMU.xcodeproj/project.pbxproj" ]; then
    PROJECT_PATH="../NES_EMU.xcodeproj/project.pbxproj"
elif [ -f "./NES_EMU.xcodeproj/project.pbxproj" ]; then
    PROJECT_PATH="./NES_EMU.xcodeproj/project.pbxproj"
else
    # 如果都找不到，就用 find 找
    PROJECT_PATH=$(find .. -name "project.pbxproj" -depth 2 | head -n 1)
fi

echo "🔍 使用專案檔：$PROJECT_PATH"

# 3. 解析專案名稱 (XML/JSON 結構化解析)
if [ -f "$PROJECT_PATH" ]; then
    DYNAMIC_PROJECT_NAME=$(plutil -convert json -o - "$PROJECT_PATH" | python3 -c "
import json, sys
try:
    data = json.load(sys.stdin)
    objects = data.get('objects', {})
    for obj in objects.values():
        if obj.get('isa') == 'PBXNativeTarget' and obj.get('name') == '$TARGET_NAME':
            config_list_id = obj.get('buildConfigurationList')
            config_list = objects.get(config_list_id, {})
            first_config_id = config_list.get('buildConfigurations', [None])[0]
            print(objects.get(first_config_id, {}).get('buildSettings', {}).get('PRODUCT_NAME', '$TARGET_NAME'))
            break
except:
    print('$TARGET_NAME')
" 2>/dev/null)
fi

[ -z "$DYNAMIC_PROJECT_NAME" ] && DYNAMIC_PROJECT_NAME="NES_EMU_IOS"

# 4. Git 資訊
CURRENT_TAG=$(git describe --tags --abbrev=0 2>/dev/null || echo "1.0.0")
START_COMMIT=${CI_PREVIOUS_COMMIT:-"${CURRENT_TAG}^"}
END_COMMIT=${CI_COMMIT:-"HEAD"}
RANGE_TEXT="$(git rev-parse --short $START_COMMIT 2>/dev/null || echo "Start")...$(git rev-parse --short $END_COMMIT 2>/dev/null || echo "End")"

# 5. 存入暫存檔 (供 post_build 使用)
echo "$DYNAMIC_PROJECT_NAME" > /tmp/ci_project_name.txt
echo "$CURRENT_TAG" > /tmp/ci_current_tag.txt
echo "$RANGE_TEXT" > /tmp/ci_git_range.txt
echo "測試更新說明" > /tmp/final_changelog.txt

# 6. Python 組裝 JSON (使用絕對路徑)
PAYLOAD_FILE="/tmp/start_payload.json"

export PY_NAME="$DYNAMIC_PROJECT_NAME"
export PY_TAG="$CURRENT_TAG"
export PY_VER="${CURRENT_TAG} (Build ${CI_BUILD_NUMBER:-"Local"})"
export PY_RANGE="$RANGE_TEXT"
export PY_LOGS="測試更新"

python3 -c '
import json, os
p_name = os.environ.get("PY_NAME", "Unknown")
p_tag = os.environ.get("PY_TAG", "")
p_ver = os.environ.get("PY_VER", "")
p_range = os.environ.get("PY_RANGE", "")
p_logs = os.environ.get("PY_LOGS", "")

description = f"**專案名稱：** {p_name}\n**目前基準 Tag：** {p_tag}\n**預計版本：** {p_ver}\n**Git 比對區間：** `{p_range}`\n\n**更新說明：**\n{p_logs}"
data = {"embeds": [{"title": "🍎 Xcode Cloud 流程啟動 — 準備打包 🏗️", "color": 3447003, "description": description}]}

with open("/tmp/start_payload.json", "w", encoding="utf-8") as f:
    json.dump(data, f, ensure_ascii=False)
'

# 7. 發送 (確保檔案存在才發送)
if [ -f "$PAYLOAD_FILE" ]; then
    curl -s -H "Content-Type: application/json" -X POST -d @"$PAYLOAD_FILE" "$DISCORD_WEBHOOK"
    echo "✅ Discord 訊息已發送"
else
    echo "❌ 錯誤：找不到 $PAYLOAD_FILE"
fi