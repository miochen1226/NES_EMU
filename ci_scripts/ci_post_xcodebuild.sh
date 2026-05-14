#!/bin/bash

# ============================================================
# 腳本位置：專案目錄/ci_scripts/ci_post_xcodebuild.sh
# 功能：自動偵測版本並在建置成功後打 Tag
# ============================================================

# 1. 只有在建置成功時才執行
if [ "$CI_XCODE_CLOUD_FINISHED_HEURISTIC" == "success" ]; then

    # 2. 自動偵測 Xcode 專案中的版本號 (與 clone 腳本邏輯一致)
    PROJECT_FILE=$(find .. -name "project.pbxproj" | head -n 1)
    if [ -f "$PROJECT_FILE" ]; then
        DETECTED_VERSION=$(grep -m 1 "MARKETING_VERSION" "$PROJECT_FILE" | cut -d'=' -f2 | tr -d ' ;"' | xargs)
    fi
    MARKETING_VERSION=${DETECTED_VERSION:-"1.0.5"}

    # 3. 組合完整的 Tag 名稱 (例如 1.0.5(52))
    TARGET_TAG="${MARKETING_VERSION}(${CI_BUILD_NUMBER})"

    echo "===== 建置成功：準備標記 Tag ====="
    echo "偵測到版本: $MARKETING_VERSION"
    echo "準備打上 Tag: $TARGET_TAG"

    # 4. 配置 Git 並推送 Tag
    # 這裡建議使用你的 GitHub 帳號，或是 Xcode Cloud 預設配置
    git config user.name "Xcode Cloud"
    git config user.email "xcodecloud@apple.com"

    git tag "$TARGET_TAG"
    
    # 推送標籤回遠端 (確保 Xcode Cloud 有 Write 權限)
    git push origin "$TARGET_TAG"

    echo "Tag $TARGET_TAG 已成功推送到遠端。"
    echo "================================"
else
    echo "建置未成功或狀態不明，跳過打 Tag 步驟。"
fi
