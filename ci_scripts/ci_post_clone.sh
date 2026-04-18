#!/bin/bash

# 1. 進入專案根目錄 (Xcode Cloud 執行時通常已經在裡面，但保險起見)
cd ..

# 2. 解開淺層複製，抓取完整的歷史紀錄與 Tags
# 這是讓 git log 能運作的關鍵
git fetch --unshallow --tags

# 3. 執行你原本的 Git 邏輯
LAST_TAG=$(git describe --tags --abbrev=0 2>/dev/null)

if [ -z "$LAST_TAG" ]; then
    RANGE="HEAD"
else
    RANGE="$LAST_TAG..HEAD"
fi

# 產出 Changelog 並存成檔案供後續腳本使用
git log "$RANGE" --merges --pretty=format:'%s' | while read -r line; do
    BRANCH=$(echo "$line" | sed -E "s/Merge branch '(.+)' into.*/\1/; s/Merge pull request #[0-9]+ from .+\/(.+)/\1/")
    if [[ ! "$BRANCH" =~ ^(release|main|master|develop|Release)/ ]] && [[ "$BRANCH" != "$line" ]]; then
        echo "• $BRANCH"
    fi
done | sort -u > changelog.txt

echo "✅ Changelog 已產生，內容如下："
cat changelog.txt