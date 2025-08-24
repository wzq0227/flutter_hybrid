#!/bin/bash

# IPA 构建脚本 for Jenkins
# 使用方法: ./build_ipa.sh

# 设置变量
PROJECT_NAME="FlutterHybridiOS"  # 你的项目名称
SCHEME_NAME="FlutterHybridiOS"   # 你的 scheme 名称
WORKSPACE_NAME="${PROJECT_NAME}.xcworkspace"
ARCHIVE_PATH="./${PROJECT_NAME}.xcarchive"
EXPORT_PATH="./ipa"
EXPORT_OPTIONS_PLIST="./ExportOptions.plist"
CONFIGURATION="Release"
SDK="iphoneos"

echo "📦 项目名称: $PROJECT_NAME"
echo "🎯 Scheme: $SCHEME_NAME"
echo "🏗️  配置: $CONFIGURATION"

# 检查工作空间是否存在
if [ ! -d "$WORKSPACE_NAME" ]; then
    echo "❌ 工作空间不存在: $WORKSPACE_NAME"
    exit 1
fi

# 清理之前的构建文件
echo "🧹 清理之前的构建文件..."
rm -rf "$ARCHIVE_PATH"
rm -rf "$EXPORT_PATH"

# 创建输出目录
mkdir -p "$EXPORT_PATH"

echo "🚀 开始构建项目..."

# 归档项目
echo "📦 归档项目..."
xcodebuild archive \
  -workspace "$WORKSPACE_NAME" \
  -scheme "$SCHEME_NAME" \
  -archivePath "$ARCHIVE_PATH" \
  -configuration "$CONFIGURATION" \
  -sdk "$SDK" \
  CODE_SIGN_STYLE="Automatic" \
  -allowProvisioningUpdates

# 检查归档是否成功
if [ $? -ne 0 ]; then
    echo "❌ 归档失败!"
    exit 1
fi

echo "✅ 归档成功!"

# 检查导出选项文件是否存在，如果不存在使用自动配置
if [ ! -f "$EXPORT_OPTIONS_PLIST" ]; then
    echo "⚠️  ExportOptions.plist 不存在，使用自动导出配置"
    EXPORT_OPTIONS_PLIST=""
fi

# 导出 IPA
echo "📤 导出 IPA 文件..."
if [ -z "$EXPORT_OPTIONS_PLIST" ]; then
    # 不使用 plist 文件，让 Xcode 自动处理
    xcodebuild -exportArchive \
      -archivePath "$ARCHIVE_PATH" \
      -exportPath "$EXPORT_PATH" \
      -allowProvisioningUpdates
else
    # 使用指定的 plist 文件
    xcodebuild -exportArchive \
      -archivePath "$ARCHIVE_PATH" \
      -exportPath "$EXPORT_PATH" \
      -exportOptionsPlist "$EXPORT_OPTIONS_PLIST" \
      -allowProvisioningUpdates
fi

# 检查导出是否成功
if [ $? -ne 0 ]; then
    echo "❌ IPA 导出失败!"
    exit 1
fi

echo "✅ IPA 导出成功!"

# 显示生成的 IPA 文件
echo "📁 IPA 文件位置: $EXPORT_PATH"
echo "📋 生成的文件:"
ls -la "$EXPORT_PATH"

# 查找 IPA 文件
IPA_FILE=$(find "$EXPORT_PATH" -name "*.ipa" | head -n 1)
if [ -n "$IPA_FILE" ]; then
    echo "🎉 IPA 文件: $IPA_FILE"
    echo "IPA_PATH=$IPA_FILE" >> build_info.txt
fi

# 完成消息
echo "🎉 构建完成!"
exit 0
