#!/bin/bash

# ReflectCam 应用 DMG 打包脚本
# 此脚本将构建应用并创建 DMG 安装包

set -e  # 遇到错误时退出

echo "📦 开始创建 DMG 安装包..."

# 配置变量
APP_NAME="ReflectCam"
DMG_NAME="ReflectCam-Installer"
VERSION="1.0"
DMG_FINAL_NAME="${DMG_NAME}-${VERSION}.dmg"
TEMP_DMG="temp_${DMG_NAME}.dmg"
VOLUME_NAME="ReflectCam Installer"
SOURCE_FOLDER="dmg_temp"
APP_PATH=""

# 清理之前的构建文件
echo "🧹 清理之前的构建文件..."
rm -rf "${SOURCE_FOLDER}"
rm -f "${TEMP_DMG}"
rm -f "${DMG_FINAL_NAME}"

# 构建应用
echo "🔨 构建应用..."
xcodebuild -project ReflectCam.xcodeproj -scheme ReflectCam -configuration Release clean build

if [ $? -ne 0 ]; then
    echo "❌ 构建失败"
    exit 1
fi

# 查找构建的应用
echo "🔍 查找构建的应用..."
APP_PATH=$(find ~/Library/Developer/Xcode/DerivedData -name "${APP_NAME}.app" -path "*/Release/*" | head -1)

if [ -z "$APP_PATH" ]; then
    echo "❌ 找不到构建的应用文件"
    exit 1
fi

echo "📱 找到应用: $APP_PATH"

# 创建临时文件夹结构
echo "📁 创建 DMG 内容文件夹..."
mkdir -p "${SOURCE_FOLDER}"

# 复制应用到临时文件夹
echo "📋 复制应用到 DMG 文件夹..."
cp -R "$APP_PATH" "${SOURCE_FOLDER}/"

# 创建应用程序文件夹的符号链接
echo "🔗 创建应用程序文件夹链接..."
ln -s /Applications "${SOURCE_FOLDER}/Applications"

# 创建 README 文件
echo "📝 创建安装说明..."
cat > "${SOURCE_FOLDER}/安装说明.txt" << EOF
ReflectCam 摄像头应用

安装方法：
1. 将 ReflectCam.app 拖拽到 Applications 文件夹
2. 首次运行时，请允许摄像头访问权限
3. 应用将在状态栏显示摄像头图标

功能特性：
• 圆形摄像头预览窗口
• 状态栏控制显示/隐藏
• 窗口大小调整 (200x200 ~ 500x500)
• 镜像反转功能
• 窗口拖动支持

系统要求：
• macOS 13.0 或更高版本
• 具有摄像头的 Mac 设备

版本：${VERSION}
EOF

# 计算 DMG 大小（应用大小 + 50MB 缓冲）
echo "📏 计算 DMG 大小..."
APP_SIZE=$(du -sm "$APP_PATH" | cut -f1)
DMG_SIZE=$((APP_SIZE + 50))
echo "DMG 大小: ${DMG_SIZE}MB"

# 创建临时 DMG
echo "💿 创建临时 DMG..."
hdiutil create -srcfolder "${SOURCE_FOLDER}" -volname "${VOLUME_NAME}" -fs HFS+ -fsargs "-c c=64,a=16,e=16" -format UDRW -size ${DMG_SIZE}m "${TEMP_DMG}"

# 挂载临时 DMG
echo "🔧 挂载 DMG 进行配置..."
DEVICE=$(hdiutil attach -readwrite -noverify -noautoopen "${TEMP_DMG}" | egrep '^/dev/' | sed 1q | awk '{print $1}')
VOLUME_PATH="/Volumes/${VOLUME_NAME}"

# 等待挂载完成
sleep 2

# 设置 DMG 外观（如果有 AppleScript 支持）
if command -v osascript >/dev/null 2>&1; then
    echo "🎨 设置 DMG 外观..."
    osascript << EOF
tell application "Finder"
    tell disk "${VOLUME_NAME}"
        open
        set current view of container window to icon view
        set toolbar visible of container window to false
        set statusbar visible of container window to false
        set the bounds of container window to {400, 100, 900, 400}
        set theViewOptions to the icon view options of container window
        set arrangement of theViewOptions to not arranged
        set icon size of theViewOptions to 128
        set position of item "${APP_NAME}.app" of container window to {150, 150}
        set position of item "Applications" of container window to {350, 150}
        set position of item "安装说明.txt" of container window to {250, 250}
        update without registering applications
        delay 2
        close
    end tell
end tell
EOF
fi

# 卸载临时 DMG
echo "📤 卸载临时 DMG..."
hdiutil detach "$DEVICE"

# 创建最终的压缩 DMG
echo "🗜️ 创建最终 DMG..."
hdiutil convert "${TEMP_DMG}" -format UDZO -imagekey zlib-level=9 -o "${DMG_FINAL_NAME}"

# 清理临时文件
echo "🧹 清理临时文件..."
rm -rf "${SOURCE_FOLDER}"
rm -f "${TEMP_DMG}"

# 验证 DMG
echo "✅ 验证 DMG..."
hdiutil verify "${DMG_FINAL_NAME}"

if [ $? -eq 0 ]; then
    echo "🎉 DMG 创建成功！"
    echo "📦 文件位置: $(pwd)/${DMG_FINAL_NAME}"
    echo "📊 文件大小: $(du -h "${DMG_FINAL_NAME}" | cut -f1)"
    
    # 显示安装包信息
    echo ""
    echo "📋 安装包信息:"
    echo "   名称: ${DMG_FINAL_NAME}"
    echo "   版本: ${VERSION}"
    echo "   卷标: ${VOLUME_NAME}"
    echo ""
    echo "💡 使用方法:"
    echo "   1. 双击 ${DMG_FINAL_NAME} 打开安装包"
    echo "   2. 将 ReflectCam.app 拖拽到 Applications 文件夹"
    echo "   3. 从 Applications 文件夹启动应用"
else
    echo "❌ DMG 验证失败"
    exit 1
fi