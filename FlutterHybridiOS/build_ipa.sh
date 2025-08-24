#!/bin/bash

# IPA 构建脚本 for Jenkins
# 使用方法: ./build_ipa.sh

# 设置环境变量（添加 Flutter 和 CocoaPods 的路径）
export PATH="$PATH:/usr/local/bin:/opt/homebrew/bin:/Users/mac/flutter/bin"

# 设置变量
PROJECT_NAME="FlutterHybridiOS"  # 你的项目名称
SCHEME_NAME="FlutterHybridiOS"   # 你的 scheme 名称
WORKSPACE_NAME="${PROJECT_NAME}.xcworkspace"
ARCHIVE_PATH="./${PROJECT_NAME}.xcarchive"
EXPORT_PATH="./ipa"
EXPORT_OPTIONS_PLIST="./ExportOptions.plist"
CONFIGURATION="Release"
SDK="iphoneos"

# 蒲公英上传参数
PGYER_API_KEY="7980ffc8e1bb5da1bdb584399cf416bc"
PGYER_USER_KEY="1a7c197d6f2b2e225ed9d0e124860057"

# 目录路径
CURRENT_DIR=$(pwd)
FLUTTER_DIR="../my_flutter"  # 同级目录下的 my_flutter 目录

echo "📦 项目名称: $PROJECT_NAME"
echo "🎯 Scheme: $SCHEME_NAME"
echo "🏗️  配置: $CONFIGURATION"
echo "📁 当前目录: $CURRENT_DIR"
echo "📁 Flutter 目录: $FLUTTER_DIR"

# 显示环境信息
echo "🔧 环境信息:"
echo "PATH: $PATH"
echo "Flutter 路径: $(which flutter || echo '未找到')"
echo "Pod 路径: $(which pod || echo '未找到')"
echo "Xcode 路径: $(xcode-select -p || echo '未找到')"

# 检查 Flutter 命令是否可用
if ! command -v flutter &> /dev/null; then
    echo "❌ Flutter 命令未找到，请检查 Flutter 安装和 PATH 配置"
    echo "尝试查找 Flutter:"
    find /usr/local -name "flutter" 2>/dev/null || true
    find /opt -name "flutter" 2>/dev/null || true
    find $HOME -name "flutter" 2>/dev/null | head -5
    exit 1
fi

# 检查 Pod 命令是否可用
if ! command -v pod &> /dev/null; then
    echo "❌ CocoaPods 命令未找到，请检查 CocoaPods 安装"
    exit 1
fi

# 检查 Flutter 目录是否存在
if [ ! -d "$FLUTTER_DIR" ]; then
    echo "❌ Flutter 目录不存在: $FLUTTER_DIR"
    echo "请确认目录结构:"
    echo "当前目录: $CURRENT_DIR"
    echo "期望的 Flutter 目录: $FLUTTER_DIR"
    ls -la ..
    exit 1
fi

# 检查工作空间是否存在
if [ ! -d "$WORKSPACE_NAME" ]; then
    echo "❌ 工作空间不存在: $WORKSPACE_NAME"
    ls -la
    exit 1
fi

# 清理之前的构建文件
echo "🧹 清理之前的构建文件..."
rm -rf "$ARCHIVE_PATH"
rm -rf "$EXPORT_PATH"

# 创建输出目录
mkdir -p "$EXPORT_PATH"

# 1. 切换到 Flutter 目录安装依赖
echo "🚀 切换到 Flutter 目录..."
cd "$FLUTTER_DIR"

if [ $? -ne 0 ]; then
    echo "❌ 无法切换到 Flutter 目录: $FLUTTER_DIR"
    exit 1
fi

echo "📁 当前 Flutter 目录: $(pwd)"
echo "🚀 开始安装 Flutter 依赖..."
echo "Flutter 版本: $(flutter --version)"

flutter pub get

if [ $? -ne 0 ]; then
    echo "❌ Flutter pub get 失败!"
    exit 1
fi
echo "✅ Flutter 依赖安装完成!"

# 2. 切换回项目目录安装 CocoaPods 依赖
echo "🚀 切换回项目目录..."
cd "$CURRENT_DIR"

if [ $? -ne 0 ]; then
    echo "❌ 无法切换回项目目录: $CURRENT_DIR"
    exit 1
fi

echo "📁 当前项目目录: $(pwd)"
echo "🚀 开始安装 CocoaPods 依赖..."
echo "CocoaPods 版本: $(pod --version)"

pod install

if [ $? -ne 0 ]; then
    echo "❌ pod install 失败!"
    exit 1
fi
echo "✅ CocoaPods 依赖安装完成!"

echo "🚀 开始构建项目..."

# 3. 归档项目
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

# 4. 导出 IPA
echo "📤 导出 IPA 文件..."
echo "⏳ 导出进度开始..."

# 使用 tee 命令实时显示导出进度
if [ -z "$EXPORT_OPTIONS_PLIST" ]; then
    # 不使用 plist 文件，让 Xcode 自动处理
    xcodebuild -exportArchive \
      -archivePath "$ARCHIVE_PATH" \
      -exportPath "$EXPORT_PATH" \
      -allowProvisioningUpdates 2>&1 | while read -r line; do
        echo "📋 $line"
        # 检测到进度信息时特别标注
        if [[ $line == *"Export"* ]] || [[ $line == *"progress"* ]]; then
            echo "⏩ $line"
        fi
    done
else
    # 使用指定的 plist 文件
    xcodebuild -exportArchive \
      -archivePath "$ARCHIVE_PATH" \
      -exportPath "$EXPORT_PATH" \
      -exportOptionsPlist "$EXPORT_OPTIONS_PLIST" \
      -allowProvisioningUpdates 2>&1 | while read -r line; do
        echo "📋 $line"
        # 检测到进度信息时特别标注
        if [[ $line == *"Export"* ]] || [[ $line == *"progress"* ]]; then
            echo "⏩ $line"
        fi
    done
fi

# 检查导出是否成功
if [ ${PIPESTATUS[0]} -ne 0 ]; then
    echo "❌ IPA 导出失败!"
    exit 1
fi

echo "✅ IPA 导出成功!"
echo "🎉 导出完成!"

# 显示生成的 IPA 文件
echo "📁 IPA 文件位置: $EXPORT_PATH"
echo "📋 生成的文件:"
ls -la "$EXPORT_PATH"

# 查找 IPA 文件
IPA_FILE=$(find "$EXPORT_PATH" -name "*.ipa" | head -n 1)
if [ -n "$IPA_FILE" ]; then
    echo "🎉 IPA 文件: $IPA_FILE"
    echo "IPA_PATH=$IPA_FILE" >> build_info.txt
    
    # 5. 上传到蒲公英
    echo "🚀 开始上传到蒲公英..."
    echo "📤 上传文件: $IPA_FILE"
    
    # 使用 curl 上传到蒲公英
    UPLOAD_RESPONSE=$(curl -F "file=@$IPA_FILE" \
        -F "_api_key=$PGYER_API_KEY" \
        -F "userKey=$PGYER_USER_KEY" \
        https://www.pgyer.com/apiv2/app/upload 2>/dev/null)
    
    # 检查上传结果
    if echo "$UPLOAD_RESPONSE" | grep -q '"code":0'; then
        echo "✅ 蒲公英上传成功!"
        
        # 解析返回的 JSON 获取下载链接
        APP_QRCODE_URL=$(echo "$UPLOAD_RESPONSE" | grep -o '"buildQRCodeURL":"[^"]*"' | cut -d'"' -f4)
        APP_DOWNLOAD_URL=$(echo "$UPLOAD_RESPONSE" | grep -o '"buildShortcutUrl":"[^"]*"' | cut -d'"' -f4)
        
        if [ -n "$APP_QRCODE_URL" ]; then
            echo "📱 下载二维码: $APP_QRCODE_URL"
        fi
        if [ -n "$APP_DOWNLOAD_URL" ]; then
            echo "🔗 下载链接: https://www.pgyer.com/$APP_DOWNLOAD_URL"
        fi
        
        # 保存上传信息到文件
        echo "PGYER_QRCODE_URL=$APP_QRCODE_URL" >> build_info.txt
        echo "PGYER_DOWNLOAD_URL=https://www.pgyer.com/$APP_DOWNLOAD_URL" >> build_info.txt
        
    else
        echo "❌ 蒲公英上传失败!"
        echo "响应: $UPLOAD_RESPONSE"
    fi
else
    echo "❌ 未找到 IPA 文件!"
    exit 1
fi

# 显示构建信息
echo "📊 构建信息:"
if [ -f "build_info.txt" ]; then
    cat build_info.txt
fi

# 完成消息
echo "🎉 所有流程完成!"
exit 0
