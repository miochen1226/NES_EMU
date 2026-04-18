#!/bin/bash

# 1. 偵測路徑
PROJECT_PATH=$(find . -name "project.pbxproj" -depth 2 | head -n 1)
TARGET_NAME="NES_EMU (iOS)"

echo "🔍 正在透過結構化解析 (plutil + Python) 定位 Target: $TARGET_NAME"

# 2. 利用 plutil 將專案檔轉成 JSON 格式並交給 Python 處理
# Python 邏輯：
#   - 遍歷所有 objects
#   - 找到 isa 為 PBXNativeTarget 且 name 為目標名稱的 object
#   - 從該 target 找到 buildConfigurationList
#   - 進入該 list 找到第一個 buildConfiguration
#   - 提取其 buildSettings 中的 MARKETING_VERSION
VERSION=$(plutil -convert json -o - "$PROJECT_PATH" | python3 -c "
import json, sys

data = json.load(sys.stdin)
objects = data.get('objects', {})
target_name = '$TARGET_NAME'

# 1. 找出目標 Target 的 buildConfigurationList ID
config_list_id = None
for obj in objects.values():
    if obj.get('isa') == 'PBXNativeTarget' and obj.get('name') == target_name:
        config_list_id = obj.get('buildConfigurationList')
        break

if config_list_id:
    # 2. 找到對應的 buildConfigurations
    config_list = objects.get(config_list_id, {})
    configs = config_list.get('buildConfigurations', [])
    
    if configs:
        # 3. 抓取第一個 config (例如 Debug 或 Release) 的版本號
        first_config_id = configs[0]
        version = objects.get(first_config_id, {}).get('buildSettings', {}).get('MARKETING_VERSION')
        if version:
            print(version)
")

# 3. 檢查並執行
if [ -z "$VERSION" ]; then
    echo "❌ 錯誤：結構化解析失敗，找不到該 Target 的版本號。"
    exit 1
fi

TAG_NAME="${VERSION}"
echo "✅ 解析成功！$TARGET_NAME 版本為：$TAG_NAME"

# Git 動作
git push origin :refs/tags/$TAG_NAME 2>/dev/null
git tag -d $TAG_NAME 2>/dev/null
git tag $TAG_NAME
git push origin $TAG_NAME

echo "--------------------------------"
echo "🚀 結構化解析完成，Tag $TAG_NAME 已推送。"