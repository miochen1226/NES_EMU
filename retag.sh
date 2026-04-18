#!/bin/bash

# ============================================================
# 目的：自動抓取專案 Marketing Version，刪除舊 Tag 並重新推送
# ============================================================

# 1. 自動從專案設定抓取 Marketing Version (例如 1.0.3)
# 我們抓取第一個找到的 MARKETING_VERSION
VERSION=$(xcodebuild -showBuildSettings 2>/dev/null | grep MARKETING_VERSION | head -1 | awk -F '=' '{print $2}' | tr -d ' ')

if [ -z "$VERSION" ]; then
    echo "❌ 錯誤：無法從專案設定中抓取到版本號。"
    exit 1
fi

# 補上 v 前綴 (例如 v1.0.3)
TAG_NAME="v${VERSION}"

echo "🚀 準備處理版本：$TAG_NAME"

# 2. 刪除遠端 GitHub 上的舊 Tag
echo "🗑️  正在刪除遠端 Tag: $TAG_NAME..."
git push origin :refs/tags/$TAG_NAME 2>/dev/null

# 3. 刪除本地的舊 Tag
echo "🗑️  正在刪除本地 Tag: $TAG_NAME..."
git tag -d $TAG_NAME 2>/dev/null

# 4. 在目前的 Commit 重新打上 Tag
echo "🏷️  正在重新建立 Tag: $TAG_NAME..."
git tag $TAG_NAME

# 5. 推送到遠端
echo "📤 正在推送 Tag 到 GitHub..."
git push origin $TAG_NAME

echo "--------------------------------"
echo "✅ 大功告成！Xcode Cloud 應該已經開始運作了。"
echo "目前版本：$TAG_NAME"
