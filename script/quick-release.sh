#!/bin/bash
set -e

echo "Helm Chart 快速发布"
echo "======================"

# 获取当前版本
CURRENT=$(grep '^version:' Chart.yaml | awk '{print $2}')
echo "当前版本: $CURRENT"

# 解析版本号的三个部分
IFS='.' read -r MAJOR MINOR PATCH <<< "$CURRENT"

# 自动计算新版本（修订号+1）
AUTO_NEW="$MAJOR.$MINOR.$((PATCH + 1))"
echo "建议的新版本: $AUTO_NEW"

# 询问用户确认
read -p "按回车使用建议版本 $AUTO_NEW，或输入新版本号: " USER_INPUT


if [[ -z "$USER_INPUT" ]]; then
    # 用户直接按回车，使用自动版本
    NEW=$AUTO_NEW
    echo "使用自动版本: $NEW"
elif [[ $USER_INPUT =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    # 用户输入了有效的版本号
    NEW=$USER_INPUT
    echo "使用自定义版本: $NEW"
else
    echo "错误: 版本号格式应为 X.Y.Z"
    exit 1
fi

# 更新版本
sed -i "s/version: $CURRENT/version: $NEW/" Chart.yaml
echo "更新 Chart.yaml"

# 打包
mkdir -p docs
helm package . --destination docs/
echo "打包完成: docs/big-data-platform-$NEW.tgz"

# 更新索引
cd docs
helm repo index . --url https://vwvm.github.io/helm-big-data-platform
cd ..
echo "更新仓库索引"

# 提交
git add .
git commit -m "Release v$NEW"
git push origin main

echo ""
echo "发布成功！"
echo "安装命令:"
echo "  helm repo update"
echo "  helm install my-hadoop vwvm/big-data-platform --version $NEW"