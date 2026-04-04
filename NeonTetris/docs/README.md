# 🎮 NeonTetris — 项目文档

> macOS 俄罗斯方块游戏，具有霓虹粒子效果、烟花庆祝、排行榜和完整音效系统。

---

## 📦 项目概览

| 项目 | 说明 |
|------|------|
| **平台** | macOS 13.0+ |
| **语言** | Swift 5 / SwiftUI |
| **渲染** | Metal + SwiftUI Canvas |
| **音频** | AVFoundation（程序合成音效 + MP3 背景音乐）|
| **Bundle ID** | zhjw.NeonTetris |
| **数据存储** | `~/Library/Application Support/NeonTetris2/leaderboard.txt` |

---

## 🎮 游戏玩法

### 控制键

| 按键 | 功能 |
|------|------|
| `←` / `A` | 左移 |
| `→` / `D` | 右移 |
| `↑` / `W` | 旋转 |
| `↓` / `S` | 软降 |
| `Space` | 硬降（瞬间落底）|
| `C` | 暂存/交换方块 |
| `P` | 暂停/继续 |

### 游戏规则
- 标准俄罗斯方块规则，SRS 旋转系统
- 消除行数越多得分越高（1行→100分，4行→800分）
- 每升一级，方块下落速度加快
- 共 10 个难度等级

---

## ✨ 视觉效果

### 粒子系统（Metal 渲染）
- **8 种粒子类型**：移动、旋转、软降、硬降、锁定、消行、升级、游戏结束
- **方块拖尾**：每个方块自带离子拖尾效果
- **消行爆炸**：消除行时产生彩色粒子爆炸
- **粒子配色方案**：彩虹、霓虹、火焰、冰晶、金色、自定义

### 庆祝效果（游戏结束进入排行榜时触发）

#### 🧨 鞭炮（门神对联式）
- **左串**：屏幕左侧 8% 位置，30 个鞭炮从下往上依次爆炸
- **右串**：屏幕右侧 92% 位置，30 个鞭炮从下往上依次爆炸
- **横批**：屏幕顶部中间，从中间往两边炸
- 先显示悬挂的暗红色鞭炮串，0.8 秒后开始爆炸
- 每次爆炸产生核心粒子 + 碎片飞溅（受重力掉落）

#### 🎆 烟花（前三名专属）
- 从屏幕底部中间随机位置发射
- 飞行时产生尾迹粒子
- 到达中间偏上位置爆炸，60-80 个火花圆形炸开
- 火花受重力影响，带多层光晕效果
- 前三名共发射 6 个烟花（每秒一个）

#### 🎉 彩虹闪烁文字
- 显示"恭喜 [姓名]，获得 [排名] 的成绩！"
- 七彩颜色循环闪烁 3 次（0.4 秒/次）
- 闪烁完成后保持 2 秒

---

## 🔊 音频系统

### 游戏音效（程序合成，无需音频文件）

| 音效 | 触发时机 |
|------|---------|
| 移动 | 左右移动方块 |
| 旋转 | 旋转成功 |
| 旋转失败 | 旋转被阻挡 |
| 软降 | 按下软降键 |
| 硬降 | 瞬间落底 |
| 锁定 | 方块固定 |
| 消行 1-4 | 消除 1/2/3/4 行 |
| 暂存 | 暂存方块 |
| 升级 | 升级 |
| 游戏结束 | 游戏结束 |
| 撞墙 | 移动被阻挡 |

### 庆祝音效

| 音效 | 描述 |
|------|------|
| 鞭炮噼啪 | 高频噪声爆裂，50ms |
| 烟花升空 | 300Hz→2300Hz 扫频，400ms |
| 烟花爆炸 | 低频冲击 + 高频碎片，300ms |

### 背景音乐
- 默认：`Resources/Music/BGM.mp3`（《芒种》）
- 支持用户自选本地 MP3/WAV/AIFF 文件
- 独立音量控制，可开关

---

## 🎨 主题系统

### 预设主题
- **暗色**：深色背景，霓虹方块
- **亮色**：浅色背景，鲜艳方块

### 自定义主题
可自定义以下颜色：
- 背景色、面板色、文字色
- 网格线色、棋盘色
- 7 种方块颜色（I/O/T/S/Z/L/J）
- 粒子配色方案（彩虹/霓虹/火焰/冰晶/金色/自定义）

---

## 🏆 排行榜

- 最多保存 10 条记录
- 存储位置：`~/Library/Application Support/NeonTetris2/leaderboard.txt`
- 格式：`名称|分数|等级|行数|时间戳`
- 游戏结束后自动检测是否进榜，进榜则弹出输入姓名对话框

---

## 🗂️ 项目结构

```
NeonTetris/
├── App/
│   └── NeonTetris2App.swift       # 应用入口
├── Engine/
│   ├── GameEngine.swift           # 游戏核心逻辑
│   ├── GameSettings.swift         # 游戏设置
│   ├── ScoreSystem.swift          # 计分系统
│   └── TetrominoTypes.swift       # 方块类型定义
├── Metal/
│   ├── ParticleSystem.swift       # Metal 粒子系统
│   ├── ParticleTypes.swift        # 粒子类型定义
│   └── Shaders.metal              # Metal 着色器
├── Audio/
│   ├── SoundEngine.swift          # 音效引擎（程序合成）
│   └── MusicPlayer.swift          # 背景音乐播放器
├── Views/
│   ├── ContentView.swift          # 主界面布局
│   ├── GameBoardView.swift        # 游戏棋盘（键盘输入）
│   ├── OverlayView.swift          # 游戏状态覆盖层
│   ├── CelebrationOverlayView.swift # 全屏庆祝效果
│   ├── BlockButtonStyle.swift     # 俄罗斯方块按钮样式
│   ├── HoldPieceView.swift        # 暂存方块显示
│   ├── NextPiecesView.swift       # 下一个方块预览
│   └── ScorePanelView.swift       # 分数面板
├── Panels/
│   ├── GameSettingsPanel.swift    # 游戏设置面板
│   ├── AudioSettingsPanel.swift   # 音频设置面板
│   ├── ThemeSettingsPanel.swift   # 主题设置面板
│   └── LeaderboardPanel.swift     # 排行榜面板
├── Leaderboard/
│   ├── LeaderboardManager.swift   # 排行榜管理
│   └── LeaderboardEntry.swift     # 排行榜条目
├── Theme/
│   ├── AppTheme.swift             # 主题管理
│   └── ThemeConfig.swift          # 主题配置
├── Shared/
│   ├── Constants.swift            # 全局常量
│   ├── Extensions.swift           # Swift 扩展
│   └── LocalizationManager.swift  # 中英文切换
└── Resources/
    ├── Music/
    │   └── BGM.mp3                # 默认背景音乐
    └── Assets.xcassets            # 图片资源
```

---

## 🌐 多语言支持

使用 `LocalizationManager` 实现中英文切换：

```swift
localization.t("中文文本", "English Text")
```

点击界面右侧的语言切换按钮即可在中英文之间切换。

---

## 🔧 开发说明

### 编译要求
- Xcode 15.2+
- macOS 13.0+ SDK
- Swift 5.9+

### 排行榜数据清除
```bash
rm ~/Library/Application\ Support/NeonTetris2/leaderboard.txt
```

### 已知注意事项
- `ParticleType` 枚举在 Metal 模块中已定义，庆祝粒子使用 `CelebrationParticleType` 避免冲突
- SwiftUI struct 中 Timer 回调不能使用 `[weak self]`，使用 `[self]` 或局部变量
- 项目 Bundle ID 为 `zhjw.NeonTetris`，但数据目录为 `NeonTetris2`（Display Name 决定）

---

## 📝 更新日志

### 2026-04-04
- 🧨 重写鞭炮效果：门神对联式，左右各 30 个，从下往上依次爆炸
- 🎆 修复烟花效果：前三名从第 0 秒开始发射，共 6 个
- ⌨️ 新增方向键支持（← → ↑ ↓ 与 WASD 功能相同）
- 🎵 背景音乐默认改为 BGM.mp3（《芒种》）
- 🔊 新增庆祝音效：鞭炮噼啪、烟花升空、烟花爆炸

### 2026-04-03
- 🎉 新增全屏庆祝效果（烟花 + 鞭炮 + 彩虹闪烁文字）
- 🎮 所有按钮改为俄罗斯方块样式背景
- 🌐 完善中英文切换
- 🐛 修复颜色选择器共享状态问题
- 🐛 修复 macOS 部署目标（13.0）

### 2026-04-01 ~ 2026-04-02
- ✨ 初始版本完成
- 🎨 粒子系统（Metal 渲染）
- 🏆 排行榜系统
- 🎵 音效系统（程序合成）
- 🎨 主题系统
