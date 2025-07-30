#!/bin/bash

# Mac 摄像头应用构建和运行脚本

echo "🔨 开始构建 ReflectCam 应用..."

# 构建项目
xcodebuild -project ReflectCam.xcodeproj -scheme ReflectCam -configuration Debug

if [ $? -eq 0 ]; then
    echo "✅ 构建成功！"
    echo "🚀 启动应用..."
    
    # 查找构建产物路径
    BUILD_PATH=$(find ~/Library/Developer/Xcode/DerivedData -name "ReflectCam.app" -path "*/Debug/*" | head -1)
    
    if [ -n "$BUILD_PATH" ]; then
        echo "📱 应用路径: $BUILD_PATH"
        open "$BUILD_PATH"
        echo "🎥 ReflectCam 应用已启动！"
        echo "💡 提示：首次运行时请允许摄像头访问权限"
    else
        echo "❌ 找不到构建的应用文件"
    fi
else
    echo "❌ 构建失败，请检查错误信息"
    exit 1
fi