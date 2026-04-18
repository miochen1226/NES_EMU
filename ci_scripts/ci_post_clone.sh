#!/bin/bash

# --- 1. Git & 專案名稱解析 (結構化解析) ---
# (此處省略你已處理好的 unshallow 邏輯)
PROJECT_PATH=$(find .. -name "project.pbxproj" -depth 2 | head -n 1)
TARGET_NAME="NES_EMU (iOS)"

# 使用 plutil + Python 獲取名稱
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
[ -z "$DYNAMIC_PROJECT_NAME" ] && DYNAMIC_PROJECT_NAME="NES_EMU_IOS"

# --- 2. 獲取版本與區間 ---
CURRENT_TAG=$(git describe --tags --abbrev=0 2>/dev/null || echo "1.0.0")
START_COMMIT=${CI_PREVIOUS_COMMIT:-"${CURRENT_TAG}^"}
END_COMMIT=${CI_COMMIT:-"HEAD"}
START_SHORT=$(git rev-parse --short $START_COMMIT 2>/dev/null || echo "Start")
END_SHORT=$(git rev-parse --short $END_COMMIT 2>/dev/null || echo "End")
RANGE_TEXT="$START_SHORT...$END_SHORT"

# --- 3. 儲存所有資訊到暫存檔 ---
echo "$DYNAMIC_PROJECT_NAME" > /tmp/ci_project_name.txt
echo "$CURRENT_TAG" > /tmp/ci_current_tag.txt
echo "$RANGE_TEXT" > /tmp/ci_git_range.txt
# (Changelog 提取邏輯...)
echo "$CHANGELOG" > /tmp/final_changelog.txt

# --- 4. 發送啟動通知 (代碼略) ---