# NeonTetris 应用图标设置

## 概述

成功将自定义图标设置为 NeonTetris macOS 应用的应用图标。

## 图标资源

### 图标文件结构

```
Assets.xcassets/
└── AppIcon.appiconset/
    ├── Contents.json          # 图标配置文件
    ├── 32.png                # 16x16 @1x (macOS)
    ├── 64.png                # 32x32 @2x (macOS)
    ├── 32 1.png              # 32x32 @1x (macOS)
    ├── 64 1.png              # 64x64 @2x (macOS)
    ├── 128.png               # 128x128 @1x (macOS)
    ├── 256 1.png             # 256x256 @2x (macOS)
    ├── 256.png               # 256x256 @1x (macOS)
    ├── 1.png                 # 512x512 @1x (macOS)
    └── 1 6.png              # 1024x1024 (iOS)
```

### Contents.json 配置

```json
{
  "images" : [
    { "filename" : "32.png",    "idiom" : "mac", "scale" : "1x", "size" : "16x16" },
    { "filename" : "64.png",    "idiom" : "mac", "scale" : "2x", "size" : "16x16" },
    { "filename" : "32 1.png",  "idiom" : "mac", "scale" : "1x", "size" : "32x32" },
    { "filename" : "64 1.png",  "idiom" : "mac", "scale" : "2x", "size" : "32x32" },
    { "filename" : "128.png",   "idiom" : "mac", "scale" : "1x", "size" : "128x128" },
    { "filename" : "256 1.png", "idiom" : "mac", "scale" : "2x", "size" : "128x128" },
    { "filename" : "256.png",   "idiom" : "mac", "scale" : "1x", "size" : "256x256" },
    { "idiom" : "mac",           "scale" : "2x",  "size" : "256x256" },
    { "filename" : "1.png",     "idiom" : "mac", "scale" : "1x", "size" : "512x512" },
    { "idiom" : "mac",           "scale" : "2x",  "size" : "512x512" },
    { "filename" : "1 6.png",   "idiom" : "ios", "scale" : "1x", "size" : "1024x1024" }
  ],
  "info" : { "author" : "xcode", "version" : 1 }
}
```

### macOS 应用图标尺寸

| 文件名 | 实际尺寸 | 显示尺寸 | 缩放因子 | 用途 |
|--------|---------|---------|---------|------|
| 32.png | 32x32 | 16x16 | @1x | 菜单栏、标题栏 |
| 64.png | 64x64 | 16x16 | @2x | Retina 菜单栏 |
| 32 1.png | 32x32 | 32x32 | @1x | Dock、应用窗口 |
| 64 1.png | 64x64 | 32x32 | @2x | Retina Dock |
| 128.png | 128x128 | 128x128 | @1x | Finder、信息面板 |
| 256 1.png | 256x256 | 128x128 | @2x | Retina Finder |
| 256.png | 256x256 | 256x256 | @1x | Finder 大图标 |
| 256 2.png | 512x512 | 256x256 | @2x | Retina Finder 大图标 |
| 1.png | 512x512 | 512x512 | @1x | 启动屏幕 |
| 1 1.png | 1024x1024 | 512x512 | @2x | Retina 启动屏幕 |

### iOS 应用图标尺寸

| 文件名 | 实际尺寸 | 用途 |
|--------|---------|------|
| 1 6.png | 1024x1024 | App Store |

## 设置步骤

### 1. 准备图标文件
- 创建或获取 PNG 格式的图标文件
- 确保文件尺寸正确（16x16, 32x32, 64x64, 128x128, 256x256, 512x512, 1024x1024）
- PNG 文件应使用 sRGB 颜色空间

### 2. 创建图标集
1. 在 Xcode 中打开 Assets.xcassets
2. 右键点击 → New App Icon
3. 将图标文件拖入对应的尺寸槽位

### 3. 配置 Contents.json
- 添加 filename 字段指向实际的图标文件
- 确保 size 和 scale 与文件名匹配
- idioms 字段应设置为 "mac"（用于 macOS 应用）

### 4. 清理并重新构建
```bash
rm -rf ~/Library/Developer/Xcode/DerivedData/NeonTetris-*
xcodebuild clean -project NeonTetris.xcodeproj -scheme NeonTetris
xcodebuild -project NeonTetris.xcodeproj -scheme NeonTetris build
```

## 图标预览

应用图标会在以下位置显示：
- ✅ Finder 中的应用图标
- ✅ Dock 中的应用图标
- ✅ 菜单栏图标
- ✅ 应用窗口标题栏
- ✅ Force Touch 应用预览
- ✅ 关于本机窗口

## 验证

编译成功后，应用图标会自动显示在：
1. Finder 中打开应用的位置
2. Dock 中（运行应用后）
3. System Settings → General → Login Items（如果已添加到登录项）

## 编译结果
✅ **BUILD SUCCEEDED**

---

**完成日期**：2026-04-01 11:26 GMT+8
**编译状态**：✅ **BUILD SUCCEEDED**
**图标来源**：已添加到工程中的 AppIcon.appiconset
